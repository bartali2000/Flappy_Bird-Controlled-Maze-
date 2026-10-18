//
// coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025
// generating a number bitmap 



module OverlayBitMap(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic startOfFrame,
					input 	logic	[0:4][3:0] score, // Score to display
					input		logic [2:0] overlaySelect, //there are 3 bits one for each type to allow Combining multiple Overlays at once
					input 	logic [0:4][3:0] highScore,
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0]	RGBout
);


// Score Region
localparam int SCORE_X = 544;
localparam int SCORE_Y = 16;

localparam int SCORE_WIDTH  = 5 * 16;
localparam int SCORE_HEIGHT = 32;

// Game Over Screen Regions

localparam int GAME_OVER_X = 176;
localparam int GAME_OVER_Y = 72;
localparam int GAME_OVER_WIDTH  = 9 * 32;
localparam int GAME_OVER_HEIGHT = 64;

localparam int HIGH_SCORE_X = 184;
localparam int HIGH_SCORE_Y = 200;
localparam int HIGH_SCORE_WIDTH  = 17 * 16;
localparam int HIGH_SCORE_HEIGHT = 32;

localparam int FINAL_SCORE_X = 224;
localparam int FINAL_SCORE_Y = 256;
localparam int FINAL_SCORE_WIDTH  = 12 * 16;
localparam int FINAL_SCORE_HEIGHT = 32;

localparam int RESTART_X = 88;
localparam int RESTART_Y = 400;
localparam int RESTART_WIDTH  = 29 * 16;
localparam int RESTART_HEIGHT = 32;


// Start Screen Region
localparam int START_X = 168;
localparam int START_Y = 224;
localparam int START_WIDTH  = 19 * 16;
localparam int START_HEIGHT = 32;

localparam logic [7:0] COLOR_BLACK  = 8'h00;
localparam logic [7:0] COLOR_WHITE  = 8'hFF;
localparam logic [7:0] COLOR_RED    = 8'h03;
localparam logic [7:0] COLOR_CYAN = 8'h1F;
localparam logic [7:0] COLOR_YELLOW   = 8'hFC;


logic [7:0] textColor;
logic [7:0] textColor_d;

always_comb begin
    textColor = COLOR_WHITE;

    if (inScoreRegion)
        textColor = COLOR_WHITE;

    else if (inGameOverRegion)
        textColor = COLOR_RED;

    else if (inHighScoreRegion)
			textColor = blinkYellow ? COLOR_YELLOW : COLOR_WHITE;

    else if (inFinalScoreRegion)
        textColor = COLOR_WHITE;

    else if (inRestartRegion)
        textColor = COLOR_CYAN;

    else if (inStartRegion)
        textColor = COLOR_WHITE;
end





logic inScoreRegion;
logic inGameOverRegion;
logic inHighScoreRegion;
logic inFinalScoreRegion;
logic inRestartRegion;
logic inStartRegion;


assign inScoreRegion = overlaySelect[0] && (offsetX >= SCORE_X) && (offsetX < SCORE_X + SCORE_WIDTH)&&
 (offsetY >= SCORE_Y) && (offsetY < SCORE_Y + SCORE_HEIGHT);

assign inGameOverRegion = overlaySelect[1] &&(offsetX >= GAME_OVER_X) &&(offsetX < GAME_OVER_X + GAME_OVER_WIDTH) &&
    (offsetY >= GAME_OVER_Y) && (offsetY < GAME_OVER_Y + GAME_OVER_HEIGHT);

assign inHighScoreRegion = overlaySelect[1] && (offsetX >= HIGH_SCORE_X) && (offsetX < HIGH_SCORE_X + HIGH_SCORE_WIDTH) &&
    (offsetY >= HIGH_SCORE_Y) && (offsetY < HIGH_SCORE_Y + HIGH_SCORE_HEIGHT);

assign inFinalScoreRegion = overlaySelect[1] && (offsetX >= FINAL_SCORE_X) && (offsetX < FINAL_SCORE_X + FINAL_SCORE_WIDTH) &&
    (offsetY >= FINAL_SCORE_Y) && (offsetY < FINAL_SCORE_Y + FINAL_SCORE_HEIGHT);

assign inRestartRegion = overlaySelect[1] && (offsetX >= RESTART_X) && (offsetX < RESTART_X + RESTART_WIDTH) &&
    (offsetY >= RESTART_Y) && (offsetY < RESTART_Y + RESTART_HEIGHT);
	
assign inStartRegion = overlaySelect[2] && (offsetX >= START_X) && (offsetX < START_X + START_WIDTH) &&
    (offsetY >= START_Y) && (offsetY < START_Y + START_HEIGHT);


logic [10:0] localX;
logic [10:0] localY;

logic regionScale2;
logic regionValid;


always_comb begin
    if (regionScale2) begin
        charIndex = localX >> 5; // because now each Index X will be mod 32
        charX     = localX[4:1];
        charY     = localY[5:1];
    end
    else begin
        charIndex = localX >> 4; // because now each Index X will be mod 16 which is normal
        charX     = localX[3:0];
        charY     = localY[4:0];
    end
end




always_comb begin
   localX       = 11'd0;
   localY       = 11'd0;
   regionScale2 = 1'b0;
   regionValid  = 1'b0;
	
	
	//Score Overlay start
   if (inScoreRegion) begin 
       localX       = offsetX - SCORE_X;
       localY       = offsetY - SCORE_Y;
       regionScale2 = 1'b0;
       regionValid  = 1'b1;
   end
	//Score Overlay end
   
	// GameOver Overlay start
	else if (inGameOverRegion) begin // Game Over Overlay
       localX       = offsetX - GAME_OVER_X;
       localY       = offsetY - GAME_OVER_Y;
       regionScale2 = 1'b1;
       regionValid  = 1'b1;
   end

   else if (inHighScoreRegion) begin
       localX       = offsetX - HIGH_SCORE_X;
       localY       = offsetY - HIGH_SCORE_Y;
       regionScale2 = 1'b0;
       regionValid  = 1'b1;
   end

   else if (inFinalScoreRegion) begin
       localX       = offsetX - FINAL_SCORE_X;
       localY       = offsetY - FINAL_SCORE_Y;
       regionScale2 = 1'b0;
       regionValid  = 1'b1;
   end

   else if (inRestartRegion) begin
       localX       = offsetX - RESTART_X;
       localY       = offsetY - RESTART_Y;
       regionScale2 = 1'b0;
       regionValid  = 1'b1;
   end
	
	
	else if (inStartRegion) begin
		 localX       = offsetX - START_X;
		 localY       = offsetY - START_Y;
		 regionScale2 = 1'b0;
		 regionValid  = 1'b1;
	end

end


logic [5:0] selected_char;


 
logic [5:0] charIndex;
logic [3:0] charX;
logic [4:0] charY;

logic [0:4] digit_visible;
logic [0:4] high_digit_visible;
logic selected_visible;

always_comb begin
    selected_char    = 6'd0;
    selected_visible = 1'b0;
	//=========================================================

    if (inScoreRegion && charIndex < 6'd5) begin
        selected_char    = 6'd16 + {2'b00, score[charIndex]};
        selected_visible = digit_visible[charIndex];
    end
	//=========================================================

    else if (inGameOverRegion) begin
        selected_visible = 1'b1;

        case (charIndex)
            6'd0: selected_char = 6'd39; // G
            6'd1: selected_char = 6'd33; // A
            6'd2: selected_char = 6'd45; // M
            6'd3: selected_char = 6'd37; // E
            6'd4: selected_char = 6'd0;  // Space
            6'd5: selected_char = 6'd47; // O
            6'd6: selected_char = 6'd54; // V
            6'd7: selected_char = 6'd37; // E
            6'd8: selected_char = 6'd50; // R

            default: selected_visible = 1'b0;
        endcase
    end
	//=========================================================
 
	else if (inHighScoreRegion) begin

		 if (charIndex < 6'd12) begin
			  selected_visible = 1'b1;

			  case (charIndex)
					6'd0:  selected_char = 6'd40; // H
					6'd1:  selected_char = 6'd41; // I
					6'd2:  selected_char = 6'd39; // G
					6'd3:  selected_char = 6'd40; // H
					6'd4:  selected_char = 6'd0;  // Space
					6'd5:  selected_char = 6'd51; // S
					6'd6:  selected_char = 6'd35; // C
					6'd7:  selected_char = 6'd47; // O
					6'd8:  selected_char = 6'd50; // R
					6'd9:  selected_char = 6'd37; // E
					6'd10: selected_char = 6'd26; // :
					6'd11: selected_char = 6'd0;  // Space

					default: selected_visible = 1'b0;
			  endcase
		 end

		 else if (charIndex < 6'd17) begin
			  selected_char = 6'd16 +
					{2'b00, highScore[charIndex - 6'd12]};

			  selected_visible =
					high_digit_visible[charIndex - 6'd12];
		 end
	end
	
	//=========================================================

	else if (inFinalScoreRegion) begin
		if (charIndex < 6'd7) begin
			  selected_visible = 1'b1;

			  case (charIndex)
					6'd0: selected_char = 6'd51; // S
					6'd1: selected_char = 6'd35; // C
					6'd2: selected_char = 6'd47; // O
					6'd3: selected_char = 6'd50; // R
					6'd4: selected_char = 6'd37; // E
					6'd5: selected_char = 6'd26; // :
					6'd6: selected_char = 6'd0;  // Space

					default: selected_visible = 1'b0;
			  endcase
		 end

		 else if (charIndex < 6'd12) begin
			  selected_char = 6'd16 +
					{2'b00, score[charIndex - 6'd7]};

			  selected_visible =
					digit_visible[charIndex - 6'd7];
		 end
	end
	//=========================================================
	else if (inRestartRegion) begin
		 selected_visible = 1'b1;

		 case (charIndex)
			  // PLEASE PRESS KEY2 FOR RESTART

			  6'd0:  selected_char = 6'd48; // P
			  6'd1:  selected_char = 6'd44; // L
			  6'd2:  selected_char = 6'd37; // E
			  6'd3:  selected_char = 6'd33; // A
			  6'd4:  selected_char = 6'd51; // S
			  6'd5:  selected_char = 6'd37; // E
			  6'd6:  selected_char = 6'd0;  // Space
			  6'd7:  selected_char = 6'd48; // P
			  6'd8:  selected_char = 6'd50; // R
			  6'd9:  selected_char = 6'd37; // E
			  6'd10: selected_char = 6'd51; // S
			  6'd11: selected_char = 6'd51; // S
			  6'd12: selected_char = 6'd0;  // Space
			  6'd13: selected_char = 6'd43; // K
			  6'd14: selected_char = 6'd37; // E
			  6'd15: selected_char = 6'd57; // Y
			  6'd16: selected_char = 6'd18; // 2
			  6'd17: selected_char = 6'd0;  // Space
			  6'd18: selected_char = 6'd38; // F
			  6'd19: selected_char = 6'd47; // O
			  6'd20: selected_char = 6'd50; // R
			  6'd21: selected_char = 6'd0;  // Space
			  6'd22: selected_char = 6'd50; // R
			  6'd23: selected_char = 6'd37; // E
			  6'd24: selected_char = 6'd51; // S
			  6'd25: selected_char = 6'd52; // T
			  6'd26: selected_char = 6'd33; // A
			  6'd27: selected_char = 6'd50; // R
			  6'd28: selected_char = 6'd52; // T

			  default: selected_visible = 1'b0;
		 endcase
	end
	//=========================================================
	else if (inStartRegion) begin
		 selected_visible = 1'b1;

		 case (charIndex)
			  // PRESS KEY2 TO START

			  6'd0:  selected_char = 6'd48; // P
			  6'd1:  selected_char = 6'd50; // R
			  6'd2:  selected_char = 6'd37; // E
			  6'd3:  selected_char = 6'd51; // S
			  6'd4:  selected_char = 6'd51; // S
			  6'd5:  selected_char = 6'd0;  // Space
			  6'd6:  selected_char = 6'd43; // K
			  6'd7:  selected_char = 6'd37; // E
			  6'd8:  selected_char = 6'd57; // Y
			  6'd9:  selected_char = 6'd18; // 2
			  6'd10: selected_char = 6'd0;  // Space
			  6'd11: selected_char = 6'd52; // T
			  6'd12: selected_char = 6'd47; // O
			  6'd13: selected_char = 6'd0;  // Space
			  6'd14: selected_char = 6'd51; // S
			  6'd15: selected_char = 6'd52; // T
			  6'd16: selected_char = 6'd33; // A
			  6'd17: selected_char = 6'd50; // R
			  6'd18: selected_char = 6'd52; // T

			  default: selected_visible = 1'b0;
		 endcase
	end
end



assign digit_visible[0] = (score[0] != 4'd0);

assign digit_visible[1] = digit_visible[0] ||
                          (score[1] != 4'd0);

assign digit_visible[2] = digit_visible[1] ||
                          (score[2] != 4'd0);

assign digit_visible[3] = digit_visible[2] ||
                          (score[3] != 4'd0);

assign digit_visible[4] = 1'b1;


assign high_digit_visible[0] = (highScore[0] != 4'd0);

assign high_digit_visible[1] = high_digit_visible[0] ||
                               (highScore[1] != 4'd0);

assign high_digit_visible[2] = high_digit_visible[1] ||
                               (highScore[2] != 4'd0);

assign high_digit_visible[3] = high_digit_visible[2] ||
                               (highScore[3] != 4'd0);

assign high_digit_visible[4] = 1'b1;


logic [14:0] address;
logic [1:0] color; 


logic [4:0] blinkFrameCount;
logic blinkYellow;


assign address = {selected_char, charY[4:0], charX[3:0]};

lpm_rom #(
    .LPM_WIDTH(2),
    .LPM_WIDTHAD(15),
	 .LPM_NUMWORDS(32768),
    .LPM_FILE("RTL/alphabet_16x32.mif"), // ASCII 32–95
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(color)
);

// pipeline (ff) to get the pixel color from the array 	 
logic pixel_enable_d;
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        drawingRequest  <= 1'b0;
        pixel_enable_d  <= 1'b0;
        RGBout          <= COLOR_BLACK;
        textColor_d     <= COLOR_WHITE;

        blinkFrameCount <= 5'd0;
        blinkYellow     <= 1'b1;
    end

    else begin

        // High Score blinking - every 30 frames
        if (!overlaySelect[1]) begin
            blinkFrameCount <= 5'd0;
            blinkYellow     <= 1'b1;
        end
        else if (startOfFrame) begin
            if (blinkFrameCount == 5'd29) begin
                blinkFrameCount <= 5'd0;
                blinkYellow     <= ~blinkYellow;
            end
            else begin
                blinkFrameCount <= blinkFrameCount + 5'd1;
            end
        end

        // Drawing pipeline
        pixel_enable_d <= regionValid && selected_visible;
        textColor_d    <= textColor;

        drawingRequest <= pixel_enable_d && (color != 2'b00);

        RGBout <= (color == 2'b01) ? COLOR_BLACK : textColor_d;
    end
end
endmodule