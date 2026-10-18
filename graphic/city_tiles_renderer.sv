module city_tiles_renderer (
    input  logic        clk,
    input  logic        resetN,
    input  logic [9:0]  DrawX, DrawY,       // מיקום הפיקסל הנוכחי מסורק ה-VGA
    input  logic [9:0]  city_scroll_x,      // משתנה התנועה של שכבת העיר

    output logic [7:0]  city_pixel_data,    // אינדקס צבע או פלט RGB מה-MIF
    output logic        city_pixel_valid    // '1' כשהפיקסל שייך לבניין ולא שקוף
);

    localparam GROUND_Y          = 10'd420; // קו גובה האדמה במסך
    localparam TILE_HEIGHT       = 5'd16;   // גובה אריח הגג בפיקסלים
    localparam TRANSPARENT_COLOR = 8'hE0;   // צבע שקוף מוסכם

    // -------------------------------------------------------------------------
    // 1. חישוב קואורדינטות וירטואליות ואינדקס הבניין הנוכחי
    // -------------------------------------------------------------------------
    logic [10:0] virtual_x;
    assign virtual_x = {1'b0, DrawX} + {1'b0, city_scroll_x};

    // חילוק ב-32: לוקחים 5 ביטים (מאינדקס 5 עד 9) למחזוריות של 32 משבצות!
    logic [4:0] slot_idx;
    assign slot_idx = virtual_x[9:5];

    // מיקום ה-X הפנימי בתוך האריח (0 עד 31)
    logic [4:0] tile_x;
    assign tile_x = virtual_x[4:0];

    // -------------------------------------------------------------------------
    // 2. טבלת מקצבים וגבהים (Clusters & Gaps LUT)
    // 0 מציין רווח פתוח (אין בניין - רואים שמיים/עננים)
    // -------------------------------------------------------------------------
    logic [7:0] building_height;
    always_comb begin
        case (slot_idx)
            // מקצב 1: צמד בניינים גבוהים
            5'd0:  building_height = 8'd144;
            5'd1:  building_height = 8'd112;
            5'd2:  building_height = 8'd0;   // רווח
            
            // מקצב 2: שלישיית בניינים בגובה משתנה
            5'd3:  building_height = 8'd48;  // נמוך
            5'd4:  building_height = 8'd96;  // בינוני
            5'd5:  building_height = 8'd160; // מגדל גבוה
            5'd6:  building_height = 8'd0;   // רווח
            5'd7:  building_height = 8'd0;   // רווח כפול (מפתח רחב לשמיים ועננים)

            // מקצב 3: בניין בודד
            5'd8:  building_height = 8'd80;
            5'd9:  building_height = 8'd0;   // רווח

            // מקצב 4: קבוצה מדורגת יורדת
            5'd10: building_height = 8'd128;
            5'd11: building_height = 8'd80;
            5'd12: building_height = 8'd48;
            5'd13: building_height = 8'd0;   // רווח

            // מקצב 5: צמד נמוך-גבוה
            5'd14: building_height = 8'd32;
            5'd15: building_height = 8'd112;
            5'd16: building_height = 8'd0;   // רווח

            // מקצב 6: מגדל בודד מרשים
            5'd17: building_height = 8'd160;
            5'd18: building_height = 8'd0;   // רווח
            5'd19: building_height = 8'd0;   // רווח

            // מקצב 7: רביעיית מבנים צפופה
            5'd20: building_height = 8'd64;
            5'd21: building_height = 8'd96;
            5'd22: building_height = 8'd64;
            5'd23: building_height = 8'd128;
            5'd24: building_height = 8'd0;   // רווח

            // מקצב 8: סיום המחזור
            5'd25: building_height = 8'd48;
            5'd26: building_height = 8'd80;
            5'd27: building_height = 8'd0;   // רווח
            5'd28: building_height = 8'd144;
            5'd29: building_height = 8'd96;
            5'd30: building_height = 8'd0;   // רווח
            5'd31: building_height = 8'd0;   // רווח

            default: building_height = 8'd0;
        endcase
    end

    // -------------------------------------------------------------------------
    // 3. מיפוי גבהים וכתובות לקריאה מה-ROM
    // -------------------------------------------------------------------------
    logic [9:0] building_top_y;
    assign building_top_y = GROUND_Y - building_height;

    logic [9:0] offset_from_top;
    assign offset_from_top = DrawY - building_top_y;

    // דגלי אזורים: אם building_height == 0, אין בניין כלל
    logic in_building_zone;
    logic is_roof_zone;
    logic is_body_zone;

    always_comb begin
        in_building_zone = (building_height > 8'd0) && (DrawY >= building_top_y) && (DrawY < GROUND_Y);
        is_roof_zone     = in_building_zone && (offset_from_top < TILE_HEIGHT);
        is_body_zone     = in_building_zone && (offset_from_top >= TILE_HEIGHT);
    end

    // כתובות לאריחים
    logic [8:0] roof_rom_addr;
    assign roof_rom_addr = {offset_from_top[3:0], tile_x};

    logic [8:0] body_rom_addr;
    assign body_rom_addr = {offset_from_top[3:0], tile_x};

    // -------------------------------------------------------------------------
    // 4. מופעי רכיבי ה-ROM
    // -------------------------------------------------------------------------
    logic [7:0] roof_data_out;
    logic [7:0] body_data_out;

    roof_rom u_roof_rom (
        .clock   (clk),
        .address (roof_rom_addr),
        .q       (roof_data_out)
    );

    body_rom u_body_rom (
        .clock   (clk),
        .address (body_rom_addr),
        .q       (body_data_out)
    );

    // -------------------------------------------------------------------------
    // 5. סנכרון עיכוב (Pipeline Matching)
    // -------------------------------------------------------------------------
    logic is_roof_zone_d;
    logic is_body_zone_d;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            is_roof_zone_d <= 1'b0;
            is_body_zone_d <= 1'b0;
        end else begin
            is_roof_zone_d <= is_roof_zone;
            is_body_zone_d <= is_body_zone;
        end
    end

    // בחירת הפיקסל מתוך ה-ROM המתאים
    always_comb begin
        if (is_roof_zone_d) begin
            city_pixel_data  = roof_data_out;
            city_pixel_valid = (roof_data_out != TRANSPARENT_COLOR);
        end 
        else if (is_body_zone_d) begin
            city_pixel_data  = body_data_out;
            city_pixel_valid = (body_data_out != TRANSPARENT_COLOR);
        end 
        else begin
            city_pixel_data  = TRANSPARENT_COLOR;
            city_pixel_valid = 1'b0;
        end
    end

endmodule