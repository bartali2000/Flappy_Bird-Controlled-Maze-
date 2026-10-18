module background_movement (
    input  logic        clk,
    input  logic        resetN,
    input  logic        frame_pulse, // עולה ל-1 פעם בפריים (1/60 שנייה)
    
    output logic [9:0]  grass_scroll_x, // תנועה מהירה (עבור אריח הדשא)
    output logic [9:0]  city_scroll_x,  // תנועה בינונית (עבור בנייני העיר)
    output logic [9:0]  cloud_scroll_x  // תנועה איטית (עבור העננים)
);

    // מונה עזר כדי לחלק את קצב הפריימים
    logic [2:0] frame_divider;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            frame_divider  <= 3'd0;
            grass_scroll_x <= 10'd0;
            city_scroll_x  <= 10'd0;
            cloud_scroll_x <= 10'd0;
        end 
        else if (frame_pulse) begin
            // מקדמים את מונה הפריימים
            frame_divider <= frame_divider + 1'b1;

            // 1. שכבת הדשא: מתקדמת ב-1 פיקסל בכל פריים (הכי מהיר)
            grass_scroll_x <= grass_scroll_x + 1'b1;

            // 2. שכבת העיר: מתקדמת רק כאשר הביט התחתון הוא 0 (כל פריים שני)
            if (frame_divider[0] == 1'b0) begin
                city_scroll_x <= city_scroll_x + 1'b1;
            end

            // 3. שכבת העננים: מתקדמת רק כאשר שני הביטים התחתונים הם 0 (כל פריים רביעי)
            if (frame_divider[1:0] == 2'b00) begin
    if (cloud_scroll_x >= 10'd703)
        cloud_scroll_x <= 10'd0;
    else
        cloud_scroll_x <= cloud_scroll_x + 1'b1;
end
        end
    end

endmodule