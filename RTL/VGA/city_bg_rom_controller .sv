// מודול בקר רקע מודולרי מבוסס אריח 32x32 (מכיל 4 אריחים של 16x16 ברשת 2x2)
module city_bg_modular_controller (
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

    // 1. מונה יום ולילה
    logic [11:0] tod_counter;
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            tod_counter <= 12'd0;
        end else if (startOfFrame) begin
            tod_counter <= tod_counter + 12'd1;
        end
    end

    logic is_night;
    assign is_night = tod_counter[11];

    // 2. חישוב רשת הבניינים
    logic [12:0] virtX_bldg;
    assign virtX_bldg = {2'b00, pixelX} + {2'b00, scrollOffset_bg};

    logic [6:0] col_fg;
    logic [4:0] row_fg;
    logic [3:0] in_tile_x;
    logic [3:0] in_tile_y;

    assign col_fg    = virtX_bldg[10:4];
    assign row_fg    = pixelY[8:4];
    assign in_tile_x = virtX_bldg[3:0];
    assign in_tile_y = pixelY[3:0];

    logic [4:0] bldg_id;
    assign bldg_id = col_fg[6:2];

    // הגרלת גובה ורווחים
    logic [3:0] rand_hash;
    logic       is_gap;
    logic [4:0] bldg_top_row;
    logic [1:0] tile_type;
    logic       bldg_pixel_active;

    always_comb begin
        rand_hash    = (bldg_id[3:0] ^ {bldg_id[1:0], bldg_id[3:2]}) + {1'b0, bldg_id[4:2]};
        is_gap       = (rand_hash[3:2] == 2'b11);
        bldg_top_row = 5'd10 + {2'b00, rand_hash[2:0]};

        if (is_gap || (row_fg < bldg_top_row) || (row_fg >= 5'd26)) begin
            bldg_pixel_active = 1'b0;
            tile_type         = 2'd0;
        end
        else if (row_fg == bldg_top_row) begin
            bldg_pixel_active = 1'b1;
            tile_type         = 2'd0; // גג: שמאל-עליון (X:0, Y:0)
        end
        else if (is_night ? ((col_fg[0] ^ row_fg[0]) == 1'b1) : (rand_hash[0] ^ col_fg[0])) begin
            bldg_pixel_active = 1'b1;
            tile_type         = 2'd1; // חלון דולק: ימין-עליון (X:1, Y:0)
        end
        else begin
            bldg_pixel_active = 1'b1;
            tile_type         = 2'd2; // חלון כבוי: שמאל-תחתון (X:0, Y:1)
        end
    end

    // מיפוי כתובת לתמונת 32x32:
    // tile_type[0] קובע היסט X של 16 פיקסלים
    // tile_type[1] קובע היסט Y של 16 פיקסלים
    logic [4:0] rom_x;
    logic [4:0] rom_y;
    assign rom_x = {tile_type[0], in_tile_x};
    assign rom_y = {tile_type[1], in_tile_y};

    logic [9:0] bldg_rom_addr;
    assign bldg_rom_addr = {rom_y, rom_x}; // 32x32 = 1024 פיקסלים

    // 3. חישוב רצפה 32x32
    logic [4:0] floor_tile_x;
    logic [4:0] floor_tile_y;
    logic [9:0] floor_rom_addr;

    assign floor_tile_x   = (pixelX + scrollOffset_fg) % 11'd32;
    assign floor_tile_y   = (pixelY - 11'd416) % 11'd32;
    assign floor_rom_addr = {floor_tile_y, floor_tile_x};

    // 4. קריאות מהזיכרון
    logic [7:0] bldg_pixel_data;
    logic [7:0] floor_pixel_data;

    simple_rom #(
        .WIDTH(8),
        .DEPTH(1024),
        .MIF_FILE("pic_for_mif/output_windows3232_20261015_140709/windows3232.mif")
    ) u_bldg_rom (
        .clk(clk),
        .address(bldg_rom_addr),
        .q(bldg_pixel_data)
    );

    simple_rom #(
        .WIDTH(8),
        .DEPTH(1024),
        .MIF_FILE("pic_for_mif/output_floor_20261015_130227/floor.mif")
    ) u_floor_rom (
        .clk(clk),
        .address(floor_rom_addr),
        .q(floor_pixel_data)
    );

    // 5. סנכרון והחלטת צבע סופי
    logic [10:0] pixelY_d;
    logic        bldg_active_d;
    logic        is_night_d;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pixelY_d      <= 11'd0;
            bldg_active_d <= 1'b0;
            is_night_d    <= 1'b0;
        end else begin
            pixelY_d      <= pixelY;
            bldg_active_d <= bldg_pixel_active;
            is_night_d    <= is_night;
        end
    end

    localparam logic [7:0] COL_SKY_DAY   = 8'b001_011_11;
    localparam logic [7:0] COL_SKY_NIGHT = 8'b000_001_01;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            BG_RGB          <= 8'h00;
            boardersDrawReq <= 1'b0;
        end else begin
            boardersDrawReq <= 1'b1;

            if (pixelY_d >= 11'd416) begin
                BG_RGB <= floor_pixel_data;
            end
            else if (bldg_active_d) begin
                BG_RGB <= bldg_pixel_data;
            end
            else begin
                BG_RGB <= is_night_d ? COL_SKY_NIGHT : COL_SKY_DAY;
            end
        end
    end

endmodule