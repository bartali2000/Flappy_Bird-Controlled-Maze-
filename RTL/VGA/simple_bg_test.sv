module simple_bg_test (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    output logic [7:0]  RGBIn
);

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            RGBIn <= 8'h00;
        end else begin
            // חלוקת המסך לאזורי צבע לבדיקה
            if (pixelY > 11'd400) begin
                RGBIn <= 8'b111_000_00; // אדום למטה (רצפה)
            end else if (pixelY < 11'd100) begin
                RGBIn <= 8'b000_111_00; // ירוק למעלה (שמיים)
            end else begin
                // מעבר צבעים אופקי באמצע
                RGBIn <= {pixelX[7:5], pixelX[4:2], 2'b11}; 
            end
        end
    end

endmodule