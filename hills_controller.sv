module hills_controller (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic [10:0] scrollOffset_bg, 
    output logic [7:0]  RGBIn
);

    // חישוב מיקום האריח ברשת הגבעות (32x32 פיקסלים)
    logic [12:0] virtX_hills;
    assign virtX_hills = {2'b00, pixelX} + {2'b00, scrollOffset_bg};

    logic [4:0] hill_tile_x;
    logic [4:0] hill_tile_y;
    logic [9:0] hill_rom_addr;

    assign hill_tile_x   = virtX_hills[4:0];         // % 32
    assign hill_tile_y   = (pixelY - 11'd352) % 32;  // מיקום אנכי על המסך (למשל מתחיל ב-352 עד 384)
    assign hill_rom_addr = {hill_tile_y, hill_tile_x};

    // קריאה מזיכרון ה-ROM של הגבעות
    logic [7:0] hill_pixel_data;

    simple_rom #(
        .WIDTH(8),
        .DEPTH(1024),
        .MIF_FILE("pic_for_mif/output_grass_20261015_150310/grass.mif")
		) u_hills_rom( 
        .clk(clk),
        .address(hill_rom_addr),
        .q(hill_pixel_data)
    );
localparam logic [7:0] SKY_BLUE = 8'b010_101_11; // צבע תכלת במקום ירוק
    localparam logic [7:0] DIRT_BRN = 8'b110_100_00; // חום אדמה

    // תצוגה על המסך
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            RGBIn <= 8'h00;
        end else begin
            if (pixelY >= 11'd352 && pixelY < 11'd384) begin
                // אם הפיקסל ב-MIF הוא חלל ריק (FF), נשים שמיים כחולים
                if (hill_pixel_data > 8'hE0) begin
                    RGBIn <= SKY_BLUE; 
                end else begin
                    RGBIn <= hill_pixel_data; // מצייר את האריח
                end
            end 
            else if (pixelY >= 11'd384) begin
                RGBIn <= DIRT_BRN; // רצפה חומה למטה
            end 
            else begin
                RGBIn <= SKY_BLUE; // שמיים כחולים למעלה
            end
        end
    end

endmodule