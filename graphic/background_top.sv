module background_top (
    input  logic        clk,
    input  logic        resetN,
    input  logic        frame_pulse,
    input  logic        next_level_pulse, // יתחבר בהמשך לבקר המשחק (כרגע לאדמה)
    input  logic [10:0] PixelX, PixelY,
    
    output logic [7:0]  RGB_out
);

    localparam TRANSPARENT_COLOR = 8'hE0; // צבע שקוף מוסכם ב-MIF
    localparam [7:0] DIRT_COLOR  = 8'hD6; // חול/אדמה

    // -------------------------------------------------------------------------
    // 1. מחולל התנועה (Parallax Scrolling Engine)
    // -------------------------------------------------------------------------
    logic [9:0] grass_scroll_x;
    logic [9:0] city_scroll_x;
    logic [9:0] cloud_scroll_x;

    background_movement u_movement (
        .clk            (clk),
        .resetN         (resetN),
        .frame_pulse    (frame_pulse),
        .grass_scroll_x (grass_scroll_x),
        .city_scroll_x  (city_scroll_x),
        .cloud_scroll_x (cloud_scroll_x)
    );

    // -------------------------------------------------------------------------
    // 2. בקר מחזור יום-שקיעה-לילה (ניהול זמן וצבעי שמיים/שמש)
    // -------------------------------------------------------------------------
    logic [7:0]  current_sky_color;
    logic [7:0]  celestial_color;
    logic [10:0] celestial_x;
    logic [10:0] celestial_y;
    logic        is_night;

    day_night_controller u_time_manager (
        .clk              (clk),
        .resetN           (resetN),
        .frame_pulse      (frame_pulse),
        .next_level_pulse (next_level_pulse),
        .sky_color        (current_sky_color),
        .celestial_color  (celestial_color),
        .celestial_x      (celestial_x),
        .celestial_y      (celestial_y),
        .is_night         (is_night)
    );
// -------------------------------------------------------------------------
    // 3. חישוב אלגוריתמי: שמש, ירח סהר (בננה) וכוכבים (אופטימיזציית Fitter מוחלטת)
    // -------------------------------------------------------------------------
    
    // משתנים קטנים ויעילים (Unsigned בלבד, ללא המרות Signed כבדות!)
    logic [10:0] c_abs_dx, c_abs_dy;
    logic [10:0] c_cut_x, c_cut_y;
    logic [10:0] c_abs_dx_cut, c_abs_dy_cut;

    logic        in_celestial_base;
    logic        in_moon_cutout;
    logic        in_celestial;
    logic        is_star;

    // כוכבים במתמטיקה מוקטנת (רוחב פס של 6 ביטים בלבד במקום 12!)
    logic [5:0]  px_mod;
    logic [4:0]  py_mod;
    logic [5:0]  abs_star_dx;
    logic [4:0]  abs_star_dy;

    // Hash ללא כפל
    logic [10:0] star_hash;
    assign star_hash = PixelX ^ {PixelY[6:0], 4'b0000} ^ {3'b000, PixelX[10:3]} ^ PixelY;

    always_comb begin
        // --- ערכי ברירת מחדל (מניעת Latches) ---
        in_celestial_base = 1'b0;
        in_moon_cutout    = 1'b0;
        in_celestial      = 1'b0;
        is_star           = 1'b0;
        c_abs_dx          = 11'd0;
        c_abs_dy          = 11'd0;
        c_abs_dx_cut      = 11'd0;
        c_abs_dy_cut      = 11'd0;
        abs_star_dx       = 6'd0;
        abs_star_dy       = 5'd0;

        // --- 1. חישוב מרחקים בערך מוחלט (Unsigned ישיר, חוסך שרשראות נשא ארוכות בחומרה) ---
        c_abs_dx = (PixelX >= celestial_x) ? (PixelX - celestial_x) : (celestial_x - PixelX);
        c_abs_dy = (PixelY >= celestial_y) ? (PixelY - celestial_y) : (celestial_y - PixelY);
        
        c_cut_x = celestial_x + 11'd5;
        c_cut_y = celestial_y - 11'd3;

        c_abs_dx_cut = (PixelX >= c_cut_x) ? (PixelX - c_cut_x) : (c_cut_x - PixelX);
        c_abs_dy_cut = (PixelY >= c_cut_y) ? (PixelY - c_cut_y) : (c_cut_y - PixelY);

        // --- 2. קירוב אוקטגון ---
        in_celestial_base = (c_abs_dx <= 11'd15) && (c_abs_dy <= 11'd15) && ((c_abs_dx + c_abs_dy) <= 11'd21);
        in_moon_cutout    = (c_abs_dx_cut <= 11'd15) && (c_abs_dy_cut <= 11'd15) && ((c_abs_dx_cut + c_abs_dy_cut) <= 11'd21);

        // --- 3. צורה סופית ---
        if (is_night) begin
            in_celestial = in_celestial_base && !in_moon_cutout;
        end else begin
            in_celestial = in_celestial_base;
        end

        // --- 4. כוכבים - אופטימיזציה פסיכית לרוחב פס ---
        // לקיחת ביטים תחתונים בלבד שקולה למודולו, ומוזילה את החומרה דרמטית
        px_mod = PixelX[5:0]; // טווח 0 עד 63
        py_mod = PixelY[4:0]; // טווח 0 עד 31

        abs_star_dx = (px_mod >= 6'd32) ? (px_mod - 6'd32) : (6'd32 - px_mod);
        abs_star_dy = (py_mod >= 5'd16) ? (py_mod - 5'd16) : (5'd16 - py_mod);

        if ((PixelY < 11'd150) && (star_hash[10:4] == 7'd0)) begin
            // חיבור של 6 ביטים בלבד במקום 12
            if (({1'b0, abs_star_dx} + {2'b00, abs_star_dy}) <= 7'd2) begin
                is_star = 1'b1;
            end
        end
    end
    // -------------------------------------------------------------------------
    // 4. שכבת העיר (City Layer - Roof & Body ROMs)
    // -------------------------------------------------------------------------
    logic [7:0] city_pixel_data;
    logic       city_pixel_valid;

    city_tiles_renderer u_city (
        .clk              (clk),
        .resetN           (resetN),
        .DrawX            (PixelX[9:0]),
        .DrawY            (PixelY[9:0]),
        .city_scroll_x    (city_scroll_x),
        .city_pixel_data  (city_pixel_data),
        .city_pixel_valid (city_pixel_valid)
    );

    // -------------------------------------------------------------------------
    // 5. שכבת העננים המשודרגת: 64x32 פיקסלים, נקי וללא כפל
    // -------------------------------------------------------------------------
    localparam CLOUD_W = 11'd64;
    localparam CLOUD_H = 11'd32;
    localparam VIRT_W  = 12'd704; // 640 מסך + 64 רוחב ענן ליציאה חלקה

    // גבהים שונים ל-3 עננים
    logic [10:0] cloud1_y, cloud2_y, cloud3_y;
    assign cloud1_y = 11'd30;
    assign cloud2_y = 11'd80;
    assign cloud3_y = 11'd50;

    // הגבלת משתנה התנועה למודולו 704
    logic [11:0] scroll_mod;
    always_comb begin
        if ({2'b00, cloud_scroll_x} >= VIRT_W)
            scroll_mod = {2'b00, cloud_scroll_x} - VIRT_W;
        else
            scroll_mod = {2'b00, cloud_scroll_x};
    end

    // מיקומי X בטוחים (מניעת Underflow ויציאה חלקה)
    logic [12:0] base1, base2, base3;
    assign base1 = 13'd40  + (VIRT_W * 2) - scroll_mod;
    assign base2 = 13'd280 + (VIRT_W * 2) - scroll_mod;
    assign base3 = 13'd520 + (VIRT_W * 2) - scroll_mod;

    logic [11:0] virt_c1_x, virt_c2_x, virt_c3_x;
    assign virt_c1_x = (base1 >= (VIRT_W * 2)) ? (base1 - (VIRT_W * 2)) : (base1 - VIRT_W);
    assign virt_c2_x = (base2 >= (VIRT_W * 2)) ? (base2 - (VIRT_W * 2)) : (base2 - VIRT_W);
    assign virt_c3_x = (base3 >= (VIRT_W * 2)) ? (base3 - (VIRT_W * 2)) : (base3 - VIRT_W);

    // זיהוי אם הפיקסל נמצא בתוך אחד העננים
    logic in_cloud1, in_cloud2, in_cloud3;
    assign in_cloud1 = (virt_c1_x < 12'd640) && (PixelX >= virt_c1_x[10:0]) && (PixelX < virt_c1_x[10:0] + CLOUD_W) &&
                       (PixelY >= cloud1_y)  && (PixelY < cloud1_y + CLOUD_H);

    assign in_cloud2 = (virt_c2_x < 12'd640) && (PixelX >= virt_c2_x[10:0]) && (PixelX < virt_c2_x[10:0] + CLOUD_W) &&
                       (PixelY >= cloud2_y)  && (PixelY < cloud2_y + CLOUD_H);

    assign in_cloud3 = (virt_c3_x < 12'd640) && (PixelX >= virt_c3_x[10:0]) && (PixelX < virt_c3_x[10:0] + CLOUD_W) &&
                       (PixelY >= cloud3_y)  && (PixelY < cloud3_y + CLOUD_H);

    // קואורדינטות פנימיות ובחירת סוג ענן (0 = ענן 1, 1 = ענן 2)
    logic [5:0] c_local_x;
    logic [4:0] c_local_y;
    logic       cloud_type_sel;
    logic       in_any_cloud;

    always_comb begin
        if (in_cloud1) begin
            c_local_x      = PixelX[5:0] - virt_c1_x[5:0];
            c_local_y      = PixelY[4:0] - cloud1_y[4:0];
            cloud_type_sel = 1'b0; // ענן 1: עגול קלאסי
            in_any_cloud   = 1'b1;
        end else if (in_cloud2) begin
            c_local_x      = PixelX[5:0] - virt_c2_x[5:0];
            c_local_y      = PixelY[4:0] - cloud2_y[4:0];
            cloud_type_sel = 1'b1; // ענן 2: מאורך ומדורג
            in_any_cloud   = 1'b1;
        end else if (in_cloud3) begin
            c_local_x      = PixelX[5:0] - virt_c3_x[5:0];
            c_local_y      = PixelY[4:0] - cloud3_y[4:0];
            cloud_type_sel = 1'b0; // ענן 3: עגול קלאסי
            in_any_cloud   = 1'b1;
        end else begin
            c_local_x      = 6'd0;
            c_local_y      = 5'd0;
            cloud_type_sel = 1'b0;
            in_any_cloud   = 1'b0;
        end
    end

    // כתובת ל-ROM: שרשור חוטים ישיר (12 ביט סה"כ)
    logic [11:0] cloud_rom_addr;
    assign cloud_rom_addr = {cloud_type_sel, c_local_y, c_local_x};

    logic [7:0] cloud_pixel_data;
    cloud_rom u_cloud_rom (
        .clock   (clk),
        .address (cloud_rom_addr),
        .q       (cloud_pixel_data)
    );

    // -------------------------------------------------------------------------
    // 6. שכבת הדשא והאדמה (Ground Layer - 16x16 ROM + Solid Dirt)
    // -------------------------------------------------------------------------
    localparam [10:0] GROUND_Y = 11'd420;

    logic in_grass_zone;
    logic in_dirt_zone;
    assign in_grass_zone = (PixelY >= GROUND_Y) && (PixelY < GROUND_Y + 11'd16);
    assign in_dirt_zone  = (PixelY >= GROUND_Y + 11'd16);

    // חישוב כתובת הדשא: 4 הסיביות התחתונות (מודולו 16 טבעי ללא חילוק)
    logic [3:0] grass_tile_x;
    logic [3:0] grass_tile_y;
    assign grass_tile_x = PixelX[3:0] + grass_scroll_x[3:0];
    assign grass_tile_y = PixelY[3:0] - GROUND_Y[3:0];

    logic [7:0] grass_rom_addr;
    assign grass_rom_addr = {grass_tile_y, grass_tile_x}; // 16x16 = 256 מילים

    logic [7:0] grass_pixel_data;
    grass_rom u_grass_rom (
        .clock   (clk),
        .address (grass_rom_addr),
        .q       (grass_pixel_data)
    );

// -------------------------------------------------------------------------
    // 7. סנכרון עיכובים (Pipeline Alignment)
    // -------------------------------------------------------------------------
    logic in_grass_zone_d;
    logic in_dirt_zone_d;
    logic in_any_cloud_d;
    logic in_celestial_d;
    logic in_star_d; // <-- דוגמים גם את הכוכב

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            in_grass_zone_d <= 1'b0;
            in_dirt_zone_d  <= 1'b0;
            in_any_cloud_d  <= 1'b0;
            in_celestial_d  <= 1'b0;
            in_star_d       <= 1'b0;
        end else begin
            in_grass_zone_d <= in_grass_zone;
            in_dirt_zone_d  <= in_dirt_zone;
            in_any_cloud_d  <= in_any_cloud;
            in_celestial_d  <= in_celestial;
            in_star_d       <= is_star; // סנכרון הכוכב
        end
    end

// -------------------------------------------------------------------------
    // 8. מרבב סדר העדיפויות (Priority Multiplexer: Z-Ordering)
    // -------------------------------------------------------------------------
    always_comb begin
        // עדיפות 1: אדמה תחתונה
        if (in_dirt_zone_d) begin
            RGB_out = DIRT_COLOR;
        end
        // עדיפות 2: אריח דשא
        else if (in_grass_zone_d && (grass_pixel_data != TRANSPARENT_COLOR)) begin
            RGB_out = grass_pixel_data;
        end
        // עדיפות 3: עיר ובניינים
        else if (city_pixel_valid) begin
            RGB_out = city_pixel_data;
        end
        // עדיפות 4: ירח בננה או שמש (מופיעים מעל הכל)
        else if (in_celestial_d) begin
            RGB_out = celestial_color; 
        end
        // עדיפות 5: עננים - יופיעו אך ורק אם *לא* לילה! (בלילה העננים נעלמים)
        else if (!is_night && in_any_cloud_d && (cloud_pixel_data != TRANSPARENT_COLOR)) begin
            RGB_out = cloud_pixel_data;
        end
        // עדיפות 6: כוכבים (יופיעו רק בלילה ובחלק העליון של המסך)
        else if (is_night && in_star_d) begin
            RGB_out = 8'hFC; // כוכבי מעויין בצהוב בהיר ובוהק
        end
        // עדיפות 7: רקע השמיים הכללי (תכלת ביום, שחור בלילה)
        else begin
            RGB_out = current_sky_color; 
        end
    end

endmodule