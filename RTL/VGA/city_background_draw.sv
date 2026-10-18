// city_background_draw.sv - גרסה סופית, חסינת שגיאות סינתזה ומוכחת: שמיים, כוכבים, עננים, שמש, ירח ו-Parallax
module city_background_draw (
    input  logic        clk,
    input  logic        resetN,
    input  logic        startOfFrame,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic [10:0] scrollOffset_fg,
    input  logic [10:0] scrollOffset_bg,

    output logic [7:0]  BG_RGB,
    output logic        boardersDrawReq
);

    // -------------------------------------------------------------
    // 1. פלטת צבעים [7:5]=R, [4:2]=G, [1:0]=B
    // -------------------------------------------------------------
    // יום
    localparam logic [7:0] COL_SKY_DAY_TOP   = 8'b001_011_11; // תכלת עמוק למעלה
    localparam logic [7:0] COL_SKY_DAY_BOT   = 8'b010_100_11; // תכלת בהיר רך
    localparam logic [7:0] COL_FAR_DAY       = 8'b010_011_10; // צללית רחוקה ביום

    // שקיעה
    localparam logic [7:0] COL_SKY_SET_TOP   = 8'b011_010_10; // סגול-דמדומים למעלה
    localparam logic [7:0] COL_SKY_SET_BOT   = 8'b110_011_01; // כתום-אפרסק זוהר למטה
    localparam logic [7:0] COL_FAR_SET       = 8'b011_001_01; // צללית עיר בשקיעה

    // לילה
    localparam logic [7:0] COL_SKY_NIGHT_TOP = 8'b000_001_01; // שחור-כחול עמוק
    localparam logic [7:0] COL_SKY_NIGHT_BOT = 8'b001_010_10; // כחול-אפור לילי
    localparam logic [7:0] COL_FAR_NIGHT     = 8'b000_010_01; // צללית לילה כהה

    // גרמי שמיים
    localparam logic [7:0] COL_SUN_DAY_C     = 8'b111_111_00; // שמש יום מרכז
    localparam logic [7:0] COL_SUN_DAY_G     = 8'b111_110_01; // שמש יום הילה
    localparam logic [7:0] COL_SUN_SET_C     = 8'b111_010_00; // שמש שקיעה כתומה
    localparam logic [7:0] COL_SUN_SET_G     = 8'b110_001_00; // הילה שקיעתית אדומה
    localparam logic [7:0] COL_MOON          = 8'b111_111_10; // ירח לבן-קרמי
    localparam logic [7:0] COL_STAR          = 8'b111_111_11; // כוכב לבן מנצנץ

    // עננים, בניינים וקרקע
    localparam logic [7:0] COL_CLOUD_DAY     = 8'b111_111_11;
    localparam logic [7:0] COL_CLOUD_SHD_DAY = 8'b110_110_11;
    localparam logic [7:0] COL_CLOUD_NIGHT   = 8'b010_010_10;
    localparam logic [7:0] COL_WALL          = 8'b011_011_10;
    localparam logic [7:0] COL_ROOF_TRIM     = 8'b001_010_01;
    localparam logic [7:0] COL_WIN_ON        = 8'b111_110_00;
    localparam logic [7:0] COL_WIN_OFF       = 8'b001_010_10;
    localparam logic [7:0] COL_GRASS         = 8'b001_100_01;
    localparam logic [7:0] COL_DIRT          = 8'b011_010_00;

    // -------------------------------------------------------------
    // 2. מונה מחזור יום-שקיעה-לילה (60 פריימים בשניה)
    // -------------------------------------------------------------
    logic [11:0] tod_counter;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            tod_counter <= 12'd0;
        end
        else if (startOfFrame) begin
            tod_counter <= tod_counter + 12'd1;
        end
    end

    logic [1:0] time_phase;
    assign time_phase = tod_counter[11:10]; // 0: יום, 1: שקיעה, 2: דמדומים, 3: לילה

    // מסכת Dithering (שתי וערב) למעברי צבע שקופים ורכים
    logic dither_bit;
    assign dither_bit = pixelX[0] ^ pixelY[0];

    // -------------------------------------------------------------
    // 3. שמיים חלקים (מעבר רך ללא קו פיצול חד)
    // -------------------------------------------------------------
    logic [7:0] current_sky_color;
    logic [7:0] current_far_bldg_color;

    always_comb begin
        case (time_phase)
            2'd0: begin // יום
                if (pixelY < 11'd130)
                    current_sky_color = COL_SKY_DAY_TOP;
                else if (pixelY < 11'd190)
                    current_sky_color = dither_bit ? COL_SKY_DAY_TOP : COL_SKY_DAY_BOT; // שילוב מרוכך
                else
                    current_sky_color = COL_SKY_DAY_BOT;
                current_far_bldg_color = COL_FAR_DAY;
            end

            2'd1: begin // שקיעה
                if (pixelY < 11'd120)
                    current_sky_color = COL_SKY_SET_TOP;
                else if (pixelY < 11'd180)
                    current_sky_color = dither_bit ? COL_SKY_SET_TOP : COL_SKY_SET_BOT;
                else
                    current_sky_color = COL_SKY_SET_BOT;
                current_far_bldg_color = COL_FAR_SET;
            end

            2'd2: begin // דמדומים
                if (pixelY < 11'd140)
                    current_sky_color = COL_SKY_SET_TOP;
                else if (pixelY < 11'd200)
                    current_sky_color = dither_bit ? COL_SKY_SET_TOP : COL_SKY_NIGHT_BOT;
                else
                    current_sky_color = COL_SKY_NIGHT_BOT;
                current_far_bldg_color = COL_FAR_SET;
            end

            default: begin // לילה מלא
                if (pixelY < 11'd140)
                    current_sky_color = COL_SKY_NIGHT_TOP;
                else if (pixelY < 11'd200)
                    current_sky_color = dither_bit ? COL_SKY_NIGHT_TOP : COL_SKY_NIGHT_BOT;
                else
                    current_sky_color = COL_SKY_NIGHT_BOT;
                current_far_bldg_color = COL_FAR_NIGHT;
            end
        endcase
    end

    // -------------------------------------------------------------
    // 4. כוכבים מנצנצים בלילה (Starfield)
    // -------------------------------------------------------------
    logic star_active;
    logic [7:0] star_hash;

    always_comb begin
        star_active = 1'b0;
        star_hash   = (pixelX[7:0] ^ {pixelY[6:0], 1'b0}) + pixelX[10:8];
        // כוכבים מופיעים רק בלילה ובדמדומים, בחצי העליון של השמיים
        if ((time_phase >= 2'd2) && (pixelY < 11'd190)) begin
            // נקודת כוכב נבחרת לפי תבנית ספציפית
            if ((star_hash[6:0] == 7'b1010101) && (pixelX[1:0] == 2'b11) && (pixelY[1:0] == 2'b01)) begin
                // ניצנוץ: חלק דולקים קבוע וחלק מהבהבים עם השעון
                star_active = star_hash[7] ? 1'b1 : tod_counter[3];
            end
        end
    end

    // -------------------------------------------------------------
    // 5. מסלול שמש רחב + ירח
    // -------------------------------------------------------------
    logic [8:0] sunset_progress;
    assign sunset_progress = tod_counter[9:1];

    logic [10:0] sun_center_x, sun_center_y;
    logic [7:0]  sun_core_col, sun_glow_col;
    logic        sun_visible;

    always_comb begin
        sun_visible  = 1'b1;
        sun_core_col = COL_SUN_DAY_C;
        sun_glow_col = COL_SUN_DAY_G;
        sun_center_x = 11'd540;
        sun_center_y = 11'd75;

        case (time_phase)
            2'd0: begin
                sun_center_x = 11'd540;
                sun_center_y = 11'd75;
                sun_core_col = COL_SUN_DAY_C;
                sun_glow_col = COL_SUN_DAY_G;
                sun_visible  = 1'b1;
            end

            2'd1: begin
                sun_center_x = 11'd540 - {2'b00, sunset_progress};
                sun_center_y = 11'd75  + {3'b000, sunset_progress[8:1]};
                sun_core_col = COL_SUN_SET_C;
                sun_glow_col = COL_SUN_SET_G;
                sun_visible  = 1'b1;
            end

            2'd2: begin
                sun_center_x = 11'd280 - {3'b000, sunset_progress[8:1]};
                sun_center_y = 11'd203 + {3'b000, sunset_progress[8:1]};
                sun_core_col = COL_SUN_SET_C;
                sun_glow_col = COL_SUN_SET_G;
                sun_visible  = (sunset_progress < 9'd380);
            end

            default: begin
                sun_visible = 1'b0;
            end
        endcase
    end

    logic signed [11:0] dx_sun, dy_sun;
    logic [23:0]        dist_sq_sun;
    logic               sun_core_active, sun_glow_active;

    always_comb begin
        dx_sun          = $signed({1'b0, pixelX}) - $signed({1'b0, sun_center_x});
        dy_sun          = $signed({1'b0, pixelY}) - $signed({1'b0, sun_center_y});
        dist_sq_sun     = (dx_sun * dx_sun) + (dy_sun * dy_sun);
        sun_core_active = sun_visible && (dist_sq_sun <= 24'd529);  // R = 23px
        sun_glow_active = sun_visible && (dist_sq_sun <= 24'd1089); // R = 33px
    end

    // ירח
    logic signed [11:0] dx_moon, dy_moon;
    logic [23:0]        dist_sq_moon;
    logic               moon_active;

    always_comb begin
        dx_moon     = $signed({1'b0, pixelX}) - $signed(12'd520);
        dy_moon     = $signed({1'b0, pixelY}) - $signed(12'd85);
        dist_sq_moon= (dx_moon * dx_moon) + (dy_moon * dy_moon);
        moon_active = (time_phase == 2'd3) && (dist_sq_moon <= 24'd324); // R = 18px
    end

    // -------------------------------------------------------------
    // 6. עננים רב-צורתיים 
    // -------------------------------------------------------------
    logic [12:0] virtX_fg, virtX_bg;
    assign virtX_fg = {2'b00, pixelX} + {2'b00, scrollOffset_fg};
    assign virtX_bg = {2'b00, pixelX} + {2'b00, scrollOffset_bg};

    logic [4:0]  cloud_id;
    logic [7:0]  in_cloud_x;
    assign cloud_id   = virtX_fg[12:8];
    assign in_cloud_x = virtX_fg[7:0];

    logic [5:0]  hash_a, hash_b;
    logic [10:0] cloud_base_y;
    logic [1:0]  cloud_type;
    logic [7:0]  cloud_x_shift;

    always_comb begin
        hash_a = (cloud_id * 6'd13) ^ {cloud_id[1:0], cloud_id[4:2], 1'b1};
        hash_b = (cloud_id * 6'd29) ^ {cloud_id[3:0], cloud_id[4:3]};

        cloud_type    = hash_a[5:4];
        cloud_base_y  = 11'd60 + {5'd0, hash_a[3:0], 2'b00};
        cloud_x_shift = {2'b00, hash_b[3:0], 2'b00};
    end

    logic cloud_body_active, cloud_shade_active;
    logic [7:0] cx;
    logic [6:0] cy;

    always_comb begin
        // ערכי ברירת מחדל מוחלטים - מונע לחלוטין כל Latch של קוורטוס
        cloud_body_active  = 1'b0;
        cloud_shade_active = 1'b0;
        cy                 = 7'd0;
        cx                 = in_cloud_x - cloud_x_shift;

        // חישוב עוטף של תת-הקואורדינטה האנכית
        if ((pixelY <= cloud_base_y + 11'd4) && (pixelY >= cloud_base_y - 11'd30)) begin
            cy = 7'( (cloud_base_y + 11'd4) - pixelY );

            case (cloud_type)
                2'd0: begin // ענן קומולוס ענק
                    if (cx >= 8'd20 && cx <= 8'd100) begin
                        if (cy <= 7'd3) cloud_shade_active = 1'b1;
                        else if (cy <= 7'd12) begin
                            if (cx >= 8'd23 && cx <= 8'd97) cloud_body_active = 1'b1;
                        end
                        else if (cy <= 7'd22 && cx >= 8'd30 && cx <= 8'd53) begin
                            if (!((cx <= 8'd33 || cx >= 8'd50) && cy >= 7'd19)) cloud_body_active = 1'b1;
                        end
                        else if (cy <= 7'd30 && cx >= 8'd47 && cx <= 8'd81) begin
                            if (!((cx <= 8'd51 || cx >= 8'd77) && cy >= 7'd26)) cloud_body_active = 1'b1;
                        end
                        else if (cy <= 7'd18 && cx >= 8'd73 && cx <= 8'd95) begin
                            if (!((cx <= 8'd76 || cx >= 8'd92) && cy >= 7'd16)) cloud_body_active = 1'b1;
                        end
                    end
                end
                2'd1: begin // ענן קטן
                    if (cx >= 8'd40 && cx <= 8'd85) begin
                        if (cy <= 7'd3) cloud_shade_active = 1'b1;
                        else if (cy <= 7'd9) begin
                            if (cx >= 8'd43 && cx <= 8'd82) cloud_body_active = 1'b1;
                        end
                        else if (cy <= 7'd16 && cx >= 8'd48 && cx <= 8'd64) cloud_body_active = 1'b1;
                        else if (cy <= 7'd14 && cx >= 8'd62 && cx <= 8'd78) cloud_body_active = 1'b1;
                    end
                end
                2'd2: begin // ענן שכבתי
                    if (cx >= 8'd15 && cx <= 8'd85) begin
                        if (cy <= 7'd3) cloud_shade_active = 1'b1;
                        else if (cy <= 7'd10) begin
                            if (cx >= 8'd18 && cx <= 8'd82) cloud_body_active = 1'b1;
                        end
                        else if (cy <= 7'd15 && cx >= 8'd32 && cx <= 8'd68) cloud_body_active = 1'b1;
                    end
                end
                default: begin
                    cloud_body_active  = 1'b0;
                    cloud_shade_active = 1'b0;
                end
            endcase
        end
    end

    // -------------------------------------------------------------
    // 7. בניינים קדמיים
    // -------------------------------------------------------------
    logic [6:0] col_fg;
    logic [4:0] row_fg;
    logic [3:0] in_tile_x, in_tile_y;

    assign col_fg    = virtX_fg[10:4];
    assign row_fg    = pixelY[8:4];
    assign in_tile_x = virtX_fg[3:0];
    assign in_tile_y = pixelY[3:0];

    logic [4:0] bldg_id_fg;
    assign bldg_id_fg = col_fg[6:2];

    logic [2:0]  tile_type;
    logic [4:0]  bldg_top_row;
    logic [7:0]  fg_tile_color;
    logic        fg_pixel_active;
    logic        is_bldg_gap;

    logic [3:0] rand_hash_fg;
    always_comb begin
        rand_hash_fg = (bldg_id_fg[3:0] ^ {bldg_id_fg[1:0], bldg_id_fg[3:2]}) + {1'b0, bldg_id_fg[4:2]};
        is_bldg_gap  = (rand_hash_fg[3:2] == 2'b11);
        bldg_top_row = 5'd14 + {2'b00, rand_hash_fg[1:0], 1'b0};

        if (is_bldg_gap || (row_fg < bldg_top_row) || (row_fg >= 5'd26)) begin
            tile_type = 3'd0;
        end
        else if (row_fg == bldg_top_row) begin
            tile_type = 3'd1;
        end
        else if ((time_phase >= 2'd2) ? ((col_fg[0] ^ row_fg[0]) == 1'b1) : ((col_fg[1:0] ^ row_fg[1:0] ^ rand_hash_fg[1:0]) == 2'b01)) begin
            tile_type = 3'd2;
        end
        else begin
            tile_type = 3'd3;
        end
    end

    logic is_window_box;
    assign is_window_box = (in_tile_x >= 4'd5) && (in_tile_x <= 4'd10) && 
                           (in_tile_y >= 4'd5) && (in_tile_y <= 4'd10);

    always_comb begin
        fg_pixel_active = 1'b1;
        fg_tile_color   = COL_WALL;

        case (tile_type)
            3'd1: begin
                if (in_tile_y < 4'd4) begin
                    if ((in_tile_x == 4'd7) || (in_tile_x == 4'd8)) begin
                        fg_tile_color   = COL_ROOF_TRIM;
                        fg_pixel_active = 1'b1;
                    end
                    else begin
                        fg_tile_color   = current_sky_color;
                        fg_pixel_active = 1'b0;
                    end
                end
                else if (in_tile_y < 4'd6) begin
                    fg_tile_color   = COL_ROOF_TRIM;
                    fg_pixel_active = 1'b1;
                end
                else begin
                    fg_tile_color   = COL_WALL;
                    fg_pixel_active = 1'b1;
                end
            end

            3'd2: begin
                if (is_window_box)
                    fg_tile_color = COL_WIN_ON;
                else
                    fg_tile_color = COL_WALL;
                fg_pixel_active = 1'b1;
            end

            3'd3: begin
                if (is_window_box)
                    fg_tile_color = COL_WIN_OFF;
                else
                    fg_tile_color = COL_WALL;
                fg_pixel_active = 1'b1;
            end

            default: begin
                fg_tile_color   = current_sky_color;
                fg_pixel_active = 1'b0;
            end
        endcase
    end

    // -------------------------------------------------------------
    // 8. צללית רקע רחוקה (Parallax) - גבוהה, שקופה-למחצה ועם רווחים
    // -------------------------------------------------------------
    logic [4:0]  bldg_id_bg;
    assign bldg_id_bg = virtX_bg[11:7]; // רוחב 128px לכל בניין רחוק

    logic        far_bldg_active;
    logic [10:0] far_height;
    logic [3:0]  rand_hash_bg;
    logic        is_bg_gap;

    always_comb begin
        rand_hash_bg = bldg_id_bg[3:0] ^ {bldg_id_bg[1:0], bldg_id_bg[3:2]};
        is_bg_gap    = (rand_hash_bg[3:2] == 2'b11);

        // גובה מוגבה
        far_height   = 11'd150 + {3'b000, rand_hash_bg[2:0], 4'b0000};

        // שקיפות מדומה: dither_bit גורם לפיקסלים לסירוגין להיות שקופים
        if (!is_bg_gap && (pixelY >= far_height) && (pixelY < 11'd415)) begin
            far_bldg_active = dither_bit;
        end
        else begin
            far_bldg_active = 1'b0;
        end
    end

    // -------------------------------------------------------------
    // 9. פסיקת צבע סופי לפי שכבות עומק
    // -------------------------------------------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            BG_RGB          <= 8'h00;
            boardersDrawReq <= 1'b0;
        end
        else begin
            boardersDrawReq <= 1'b1;

            if (pixelY >= 11'd430) begin
                BG_RGB <= COL_DIRT;
            end
            else if ((pixelY >= 11'd415) && (pixelY < 11'd430)) begin
                BG_RGB <= COL_GRASS;
            end
            else if (fg_pixel_active) begin
                BG_RGB <= fg_tile_color;
            end
            else if (far_bldg_active) begin
                BG_RGB <= current_far_bldg_color;
            end
            else if (sun_core_active) begin
                BG_RGB <= sun_core_col;
            end
            else if (sun_glow_active) begin
                BG_RGB <= sun_glow_col;
            end
            else if (moon_active) begin
                BG_RGB <= COL_MOON;
            end
            else if (star_active) begin
                BG_RGB <= COL_STAR;
            end
            else if (cloud_body_active) begin
                BG_RGB <= (time_phase >= 2'd2) ? COL_CLOUD_NIGHT : COL_CLOUD_DAY;
            end
            else if (cloud_shade_active) begin
                BG_RGB <= (time_phase >= 2'd2) ? COL_CLOUD_NIGHT : COL_CLOUD_SHD_DAY;
            end
            else begin
                BG_RGB <= current_sky_color;
            end
        end
    end

endmodule