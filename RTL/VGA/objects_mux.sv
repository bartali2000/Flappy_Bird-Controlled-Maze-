// (c) Technion IIT, Department of Electrical Engineering 2026
// Flappy Bird - Objects Multiplexer (Priority Arbiter)

module objects_mux (
    // Clock & Reset
    input  logic       clk,
    input  logic       resetN,

    // Layer 1 (Top Priority): HUD & Score Overlay
    input  logic       OverlayDrawingRequest,
    input  logic [7:0] OverlayRGB,

    // Layer 2: Bird Sprite
    input  logic       birdDrawingRequest,
    input  logic [7:0] birdRGB,

    // Layer 3: Moving Pipes / Obstacles
    input  logic       pipeDrawingRequest,
    input  logic [7:0] pipeRGB,

    // Layer 4 (Bottom / Default): Algorithmic Background
    input  logic       BGDrawingRequest,
    input  logic [7:0] backGroundRGB,

    // Final Output to VGA Controller
    output logic [7:0] RGBOut
);

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        RGBOut <= 8'h00;
    end
    else begin
        // 1. Overlay / Score (שכבה עליונה ביותר)
        if (OverlayDrawingRequest == 1'b1) begin
            RGBOut <= OverlayRGB;
        end
        // 2. Bird (הציפור מעל המכשולים והרקע)
        else if (birdDrawingRequest == 1'b1) begin
            RGBOut <= birdRGB;
        end
        // 3. Pipes (הצינורות מעל הרקע)
        else if (pipeDrawingRequest == 1'b1) begin
            RGBOut <= pipeRGB;
        end
        // 4. Background (שכבת הבסיס - שמיים, ענן, דשא, אדמה)
        else if (BGDrawingRequest == 1'b1) begin
            RGBOut <= backGroundRGB;
        end
        // ברירת מחדל אם שום מודול לא ביקש לצייר
        else begin
            RGBOut <= backGroundRGB;
        end
    end
end

endmodule