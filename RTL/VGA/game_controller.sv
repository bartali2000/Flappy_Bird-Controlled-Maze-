
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 60Hz 
			

//---------------------#1- Pipes
		
			input  logic [3:0] activePipe,
			input  logic [3:0] passedBirdPulse,

		

//---------------------#1-end 

//---------------------#2-add  drawing requests

			input	logic pipeDrawingRequest,
			input logic birdDrawingRequest,
			input logic [0:4][3:0] score,
			input logic gameStartRestartN,

//---------------------#2-end drawing request of hart		

			
			output logic collision, // active in case of collision between two objects
			
			output logic SingleHitPulseBird, // critical code, generating A single pulse in a frame  also be connected to freeze game
			
			
			

//---------------------#3-pipes Output Pipes   -------------------------------------
			output logic [3:0] dispatchPipe,
			output logic signed [15:0] pipeXSpeed,
			output logic [10:0] gapSize,
			output logic increase_score,
			output logic score_clear,
			output logic restartPipes,
			output logic [2:0] overlaySelect,
			output logic [0:4][3:0] highScore

//---------------------#3-Game State	--------------------------------------

);

logic [9:0] frameCounter; // for setting speeds i can have the the speed for pipe to  12 seconds the screen 
logic [1:0] nextPipe;
logic [9:0] spawnInterval; // number of frames between pipe dispatches (note that the game is 60FPS)
  // 0-7 the higher the difficulty the more difficult it is 
logic firstDispatch;


logic [15:0] pipeSpeed; // pipe speed in px/frame .. or 60px/second because 60FPS
logic [15:0] targetPipeSpeed; // keep it maximum  of 250 and if want bigger change the random so it wont clip out
logic [10:0] targetGapSize;

logic [9:0] targetSpawnInterval;

logic [1:0] transitionCounter;

localparam logic [15:0] SPEED_STEP = 16'd3;
localparam logic [10:0] GAP_STEP = 11'd2;
localparam logic [9:0] SPAWN_STEP = 10'd2;


// states for the game
typedef enum logic [1:0] {
    WAIT_START,
    INIT_GAME,
    PLAYING,
    GAME_OVER
} game_state_t;

game_state_t game_state;


localparam int TRANSITION_EVERY = 4; // gradual change every x Frames  until we get to the final desired speed




assign collision = (birdDrawingRequest && pipeDrawingRequest);


logic [2:0] difficulty;
always_comb begin
    if      (score >= 20'h00045) difficulty = 3'd7;
    else if (score >= 20'h00030) difficulty = 3'd6;
    else if (score >= 20'h00025) difficulty = 3'd5;
    else if (score >= 20'h00020) difficulty = 3'd4;
    else if (score >= 20'h00015) difficulty = 3'd3;
    else if (score >= 20'h00010) difficulty = 3'd2;
    else if (score >= 20'h00005) difficulty = 3'd1;
    else                         difficulty = 3'd0;
end

always_comb begin

    case (difficulty)

        3'd0: begin
            targetPipeSpeed     = 16'd192; // 1.5 px/frame
            targetSpawnInterval = 10'd171;
				targetGapSize       = 11'd250;
        end

        3'd1: begin
            targetPipeSpeed     = 16'd256; // 2 px/frame
            targetSpawnInterval = 10'd128;
				targetGapSize       = 11'd225;
        end

        3'd2: begin
            targetPipeSpeed     = 16'd320; // 2.5 px/frame
            targetSpawnInterval = 10'd103;
				targetGapSize       = 11'd200;
        end

        3'd3: begin
            targetPipeSpeed     = 16'd384; // 3 px/frame
            targetSpawnInterval = 10'd86;
				targetGapSize       = 11'd175;
				
        end

        3'd4: begin
            targetPipeSpeed     = 16'd512; // 4 px/frame
            targetSpawnInterval = 10'd64;
				targetGapSize       = 11'd160;
        end

        3'd5: begin
            targetPipeSpeed     = 16'd640; // 5 px/frame
            targetSpawnInterval = 10'd52;
				targetGapSize       = 11'd150;
        end

        3'd6: begin
            targetPipeSpeed     = 16'd704; // 5.5 px/frame
            targetSpawnInterval = 10'd47;
				targetGapSize       = 11'd140;
        end

        3'd7: begin
            targetPipeSpeed     = 16'd832; // 6.5 px/frame
            targetSpawnInterval = 10'd40; 
				targetGapSize       = 11'd130;
        end

        default: begin
            targetPipeSpeed     = 16'd192;
            targetSpawnInterval = 10'd171;
				targetGapSize       = 11'd200;
        end

    endcase

end



assign pipeXSpeed = -$signed(pipeSpeed);
assign score_clear    = (game_state == INIT_GAME);
assign restartPipes   = (game_state == INIT_GAME);
assign increase_score =(game_state == PLAYING) && !startRestartPulse && !collision && (|passedBirdPulse);


logic gameStartRestartN_D;
logic startRestartPulse;

assign startRestartPulse = gameStartRestartN_D && !gameStartRestartN;

always_comb begin
    case (game_state)
        WAIT_START: overlaySelect = 3'b101;
        INIT_GAME:  overlaySelect = 3'b000;
        PLAYING:    overlaySelect = 3'b001;
        GAME_OVER:  overlaySelect = 3'b010;
        default:    overlaySelect = 3'b000;
    endcase
end



always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		game_state <= WAIT_START;
		gameStartRestartN_D <= 1'b1;
		firstDispatch <= 1'b1;
		SingleHitPulseBird <= 1'b0 ;
		pipeSpeed <= 16'd192;
		//difficulty <= 3'd0;
	   frameCounter <= 10'd0;
		nextPipe <= 2'd0;
		dispatchPipe <= 4'b0000;
		gapSize <= 11'd250;
		spawnInterval <= 10'd171;	
		transitionCounter <= 2'd0;
		highScore <= '0;
		
		
	end 
	
	else begin 
	
			if (game_state == GAME_OVER && score > highScore)
				highScore <= score;
			
			SingleHitPulseBird <= 1'b0 ; // default 
			dispatchPipe <= 4'b0000;
			gameStartRestartN_D <= gameStartRestartN;
			case (game_state)

				 WAIT_START: begin
					  if (startRestartPulse)
							game_state <= INIT_GAME;
				 end

				 INIT_GAME: begin
					  firstDispatch     <= 1'b1;
					  frameCounter      <= 10'd0;
					  nextPipe          <= 2'd0;
					  pipeSpeed         <= 16'd192;
					  gapSize           <= 11'd250;
					  spawnInterval     <= 10'd171;
					  transitionCounter <= 2'd0;

					  game_state <= PLAYING;
				 end

				 PLAYING: begin

					  if (startRestartPulse) begin
							game_state <= INIT_GAME;
					  end
					  else if (collision) begin
							SingleHitPulseBird <= 1'b1;
							game_state <= GAME_OVER;
					  end
					  else if (startOfFrame) begin
			
				if (firstDispatch) begin

					 if (!activePipe[0]) begin

						  dispatchPipe[0] <= 1'b1;

						  firstDispatch <= 1'b0;
						  nextPipe <= 2'd1;
						  frameCounter <= 10'd0;

					 end

				end
				else if (frameCounter >= spawnInterval - 1'b1) begin

					 if (!activePipe[nextPipe]) begin

						  dispatchPipe[nextPipe] <= 1'b1;

						  nextPipe <= nextPipe + 2'd1;
						  frameCounter <= 10'd0;

					 end

				end

				else begin

					 frameCounter <= frameCounter + 1'b1;

			end

			// ===== Smooth Transition Start ====================

			if ((pipeSpeed == targetPipeSpeed) && (gapSize == targetGapSize) && (spawnInterval == targetSpawnInterval)) begin

				 transitionCounter <= 2'd0;

			end

			else if (transitionCounter == TRANSITION_EVERY - 1) begin

				 transitionCounter <= 2'd0;

				 // ==========================================
				 // Pipe Speed Transition
				 // ==========================================

				 if (pipeSpeed < targetPipeSpeed) begin

					  if (pipeSpeed + SPEED_STEP > targetPipeSpeed)
							pipeSpeed <= targetPipeSpeed;
					  else
							pipeSpeed <= pipeSpeed + SPEED_STEP;

				 end

				 else if (pipeSpeed > targetPipeSpeed) begin

					  if (pipeSpeed - SPEED_STEP < targetPipeSpeed)
							pipeSpeed <= targetPipeSpeed;
					  else
							pipeSpeed <= pipeSpeed - SPEED_STEP;

				 end


				 // ==========================================
				 // Gap Size Transition
				 // ==========================================

				 if (gapSize < targetGapSize) begin

					  if (gapSize + GAP_STEP > targetGapSize)
							gapSize <= targetGapSize;
					  else
							gapSize <= gapSize + GAP_STEP;

				 end

				 else if (gapSize > targetGapSize) begin

					  if (gapSize - GAP_STEP < targetGapSize)
							gapSize <= targetGapSize;
					  else
							gapSize <= gapSize - GAP_STEP;

				 end


				 // ==========================================
				 // Spawn Interval Transition
				 // ==========================================

				 if (spawnInterval < targetSpawnInterval) begin

					  if (spawnInterval + SPAWN_STEP >= targetSpawnInterval)
							spawnInterval <= targetSpawnInterval;
					  else
							spawnInterval <= spawnInterval + SPAWN_STEP;

				 end

				 else if (spawnInterval > targetSpawnInterval) begin

					  if (spawnInterval <= targetSpawnInterval + SPAWN_STEP)
							spawnInterval <= targetSpawnInterval;
					  else
							spawnInterval <= spawnInterval - SPAWN_STEP;

				 end

			end

			else begin

				 transitionCounter <= transitionCounter + 1'b1;

			end

			// ===== Smooth Transition End ======================
		end

				  
	end

				 GAME_OVER: begin
					  if (startRestartPulse)
							game_state <= INIT_GAME;
				 end

				 default: begin
					  game_state <= WAIT_START;
				 end

			endcase
			
			
			

	end
	 
end

endmodule
