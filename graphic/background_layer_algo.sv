module background_layer_algo (
    input  logic [9:0] DrawX, DrawY,      // קואורדינטות הפיקסל הנוכחי מה-VGA
    input  logic [9:0] city_scroll_x,     // משתנה התנועה משלב 1
    
    output logic [7:0] bg_R, bg_G, bg_B,  // פלט הצבע (24-bit כדוגמה)
    output logic       is_city_pixel      // דגל שיעזור לנו בשלב ה-MUX הסופי
);

    // קבועים (פרמטרים) למיקומים במסך
    localparam GROUND_Y = 10'd420; // קו האדמה מתחיל בפיקסל 420
    
    // -----------------------------------------------------------
    // 1. חישוב נתוני העיר (City Skyline)
    // -----------------------------------------------------------
    
    // קואורדינטת X וירטואלית (עד 1663, לכן 11 ביטים)
    logic [10:0] virtual_x;
    assign virtual_x = {1'b0, DrawX} + {1'b0, city_scroll_x};
    
    // חילוק ב-32 כדי לקבל את מספר הבניין (32 = 2^5, אז לוקחים מביט 5 ומעלה)
    // ניקח רק 4 ביטים כדי לקבל רצף שחוזר על עצמו של 16 בניינים
    logic [3:0] building_index;
    assign building_index = virtual_x[8:5]; 
    
    // טבלת גבהים לבניינים (Look-Up Table)
    logic [7:0] current_building_height;
    
    always_comb begin
        case (building_index)
            4'h0: current_building_height = 8'd60;
            4'h1: current_building_height = 8'd100;
            4'h2: current_building_height = 8'd40;
            4'h3: current_building_height = 8'd120;
            4'h4: current_building_height = 8'd80;
            4'h5: current_building_height = 8'd50;
            4'h6: current_building_height = 8'd110;
            4'h7: current_building_height = 8'd70;
            4'h8: current_building_height = 8'd130;
            4'h9: current_building_height = 8'd90;
            4'hA: current_building_height = 8'd45;
            4'hB: current_building_height = 8'd105;
            4'hC: current_building_height = 8'd65;
            4'hD: current_building_height = 8'd115;
            4'hE: current_building_height = 8'd75;
            4'hF: current_building_height = 8'd85;
            default: current_building_height = 8'd50;
        endcase
    end

    // -----------------------------------------------------------
    // 2. צביעת הפיקסלים (Rendering Z-Index)
    // -----------------------------------------------------------
    always_comb begin
        // ברירת מחדל: שמיים תכלת ויציאת דגל '0' (אינו עיר)
        bg_R = 8'h7B; bg_G = 8'hC4; bg_B = 8'hE3; 
        is_city_pixel = 1'b0;

        // שכבת האדמה (הכי קרובה ולכן התנאי הראשון / העליון ביותר בעדיפות אם נהפוך סדר)
        // כאן נבדוק מהכי נמוך (Y גדול) להכי גבוה (Y קטן)
        if (DrawY >= GROUND_Y) begin
            // צבע חום אדמה
            bg_R = 8'hDE; bg_G = 8'hD8; bg_B = 8'h95; 
        end
        // שכבת העיר - הבניין יצויר רק אם אנחנו מעל האדמה ומתחת לגג הבניין
        else if (DrawY >= (GROUND_Y - current_building_height)) begin
            is_city_pixel = 1'b1; // מסמנים שהפיקסל שייך לעיר
            
            // טריק קטן לגרפיקה: יצירת "קו גבול" שחור בין בניינים
            // אם אנחנו ב-2 הפיקסלים הראשונים של הבניין, נצבע כהה יותר
            if (virtual_x[4:0] < 5'd2) begin
                bg_R = 8'h30; bg_G = 8'h40; bg_B = 8'h50; // קו מתאר (Outline)
            end else begin
                bg_R = 8'h60; bg_G = 8'h7B; bg_B = 8'h8B; // כחול-אפרפר של בניין
            end
        end
        // אם אף תנאי לא התקיים - הצבע נשאר השמיים (ברירת המחדל)
    end

endmodule