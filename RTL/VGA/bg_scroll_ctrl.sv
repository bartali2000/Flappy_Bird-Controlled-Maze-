// bg_scroll_ctrl.sv - בקר גלילה לשתי שכבות עומק (Parallax)
module bg_scroll_ctrl (
    input  logic        clk,
    input  logic        resetN,
    input  logic        startOfFrame,
    input  logic [15:0] scrollSpeed,

    output logic [10:0] scrollOffset_fg, // קדמת הרקע (מהיר)
    output logic [10:0] scrollOffset_bg  // עומק הרקע (איטי פי 4)
);

    logic [21:0] scroll_sub_pixel;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            scroll_sub_pixel <= 22'd0;
        end
        else begin
            if (startOfFrame) begin
                scroll_sub_pixel <= scroll_sub_pixel + {6'd0, scrollSpeed};
            end
        end
    end

    // מהירות מלאה (שכבה קרובה)
    assign scrollOffset_fg = scroll_sub_pixel[16:6]; 

    // מהירות איטית פי 4 (שכבה רחוקה - מוזז ב-2 ביטים ימינה)
    assign scrollOffset_bg = scroll_sub_pixel[18:8];

endmodule