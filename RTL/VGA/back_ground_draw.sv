module back_ground_draw (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    output logic [7:0]  BG_RGB,
    output logic        boardersDrawReq
);

// מיפוי מתוקן: [7:5]=Blue, [4:2]=Green, [1:0]=Red
//localparam logic [7:0] COLOR_SKY    = 8'b111_110_00; // תכלת שמיים קלאסי
//localparam logic [7:0] COLOR_GRASS  = 8'b000_111_00; // ירוק דשא
//localparam logic [7:0] COLOR_DIRT   = 8'b000_010_11; // חום אדמה
//localparam logic [7:0] COLOR_CLOUD  = 8'b111_111_11; // לבן עננים

// מיפוי תואם בפועל ללוח: [7:5]=Red, [4:2]=Green, [1:0]=Blue
localparam logic [7:0] COLOR_SKY    = 8'b000_110_11; // תכלת שמיים (ללא אדום, ירוק בהיר, כחול מקסימלי)
localparam logic [7:0] COLOR_GRASS  = 8'b000_111_00; // ירוק דשא
localparam logic [7:0] COLOR_DIRT   = 8'b110_010_00; // חום אדמה (אדום גבוה, מעט ירוק, ללא כחול)
localparam logic [7:0] COLOR_CLOUD  = 8'b111_111_11; // לבן עננים

logic is_cloud1, is_cloud2;

always_comb begin
    // ענן שמאלי
    is_cloud1 = (pixelY >= 50 && pixelY <= 85 && pixelX >= 140 && pixelX <= 270) ||
                (pixelY >= 60 && pixelY <= 95 && pixelX >= 120 && pixelX <= 290);

    // ענן ימני
    is_cloud2 = (pixelY >= 90 && pixelY <= 115 && pixelX >= 420 && pixelX <= 510) ||
                (pixelY >= 98 && pixelY <= 122 && pixelX >= 405 && pixelX <= 525);
end

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        BG_RGB          <= 8'h00;
        boardersDrawReq <= 1'b0;
    end
    else begin
        boardersDrawReq <= 1'b1;

        if (is_cloud1 || is_cloud2) begin
            BG_RGB <= COLOR_CLOUD;
        end
        else if (pixelY >= 430) begin
            BG_RGB <= COLOR_DIRT;
        end
        else if (pixelY >= 415 && pixelY < 430) begin
            BG_RGB <= COLOR_GRASS;
        end
        else begin
            BG_RGB <= COLOR_SKY;
        end
    end
end

endmodule