// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024   
// good practice code - Dudy MAR 2025  ert
 
module pipe_move (

    input logic clk,
    input logic resetN,
    input logic startOfFrame,

    input logic Y_up_key,
    input logic Y_down_key,

    input logic freezeGame,

    input logic dispatchPipe,
    input logic [10:0] gapSize,
    input logic signed [15:0] pipeXSpeed,
	 input logic [9:0] random,
	 input logic restartPipes,
    output logic signed [10:0] topLeftX,
    output logic [10:0] gapTopY,
	 
	 output logic [10:0] currentGapSize,
    output logic activePipe,
    output logic passedBirdPulse

);
 int 	 topLeftX_tmp; // output the top left corner 
 int   gapTopY_tmp;  // can be negative , if the object is partliy outside 
 logic passedBirdSent;
// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 640;
logic [9:0] INITIAL_Y; // initial gapTopY 
parameter int Y_ACCEL = 0;
parameter int PIPE_Y_SPEED = 650;
parameter int BIRD_X_POS = 150;



const int MAX_Y_SPEED = 1000;
//const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 11'd128; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/128 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


/// Limits and constants
localparam int SafetyMargin = 1;
localparam int CAP_SIZE_H = 22;
localparam int MAX_GAP_SIZE = 250;
localparam int SCREEN_HEIGHT = 480;

localparam int MIN_GAP_TOP_Y = CAP_SIZE_H + SafetyMargin;

// Random initial Y calculation
logic [10:0] effectiveGapSize;
logic [8:0] initialRange;
logic [8:0] rand1;
logic [8:0] rand2;

always_comb begin

    // Limit gap size to 250 pixels
    effectiveGapSize = (gapSize > 11'd250) ? 11'd250 : gapSize;
	 
    // Number of legal initial Y positions
    initialRange = 9'd435 - effectiveGapSize[8:0];

    // First conditional subtraction
    rand1 = (random[8:0] >= initialRange) ? random[8:0] - initialRange : random[8:0];

    // Second conditional subtraction
    rand2 = (rand1 >= initialRange) ? rand1 - initialRange : rand1;

    // Initial top Y of the gap
    INITIAL_Y = 10'd50 + {1'b0, rand2};

end


localparam int PIPE_WIDTH = 64;


const int Y_FRAME_TOP = (CAP_SIZE_H + SafetyMargin) * FIXED_POINT_MULTIPLIER;
int Y_FRAME_BOTTOM;
always_comb begin
    Y_FRAME_BOTTOM = (SCREEN_HEIGHT - SafetyMargin - int'(currentGapSize) - CAP_SIZE_H) * FIXED_POINT_MULTIPLIER;
end


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST,  // check if inside the frame  
						 FROZEN_ST
						}  SM_Motion ;

int Yspeed  ; 
int Xposition ; //position   
int GapYposition ;  

 

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Yspeed <= 0  ; 
		activePipe <= 1'b0;
		passedBirdPulse <= 1'b0;
		passedBirdSent <= 1'b0;
		currentGapSize <= 11'd200;
//		Xposition <= 0  ; 
//		GapYposition <= 0   ; 

	Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER  ; 
	GapYposition <= 140 *FIXED_POINT_MULTIPLIER   ; 
	
	end
	
	else if (restartPipes) begin

    SM_Motion       <= IDLE_ST;

    Xposition       <= INITIAL_X * FIXED_POINT_MULTIPLIER;
    GapYposition    <= 140 * FIXED_POINT_MULTIPLIER;
    Yspeed          <= 0;

    activePipe      <= 1'b0;
    passedBirdPulse <= 1'b0;
    passedBirdSent  <= 1'b0;
    currentGapSize  <= 11'd200;

	end
	
	else begin
	
	   passedBirdPulse <= 1'b0;
		if (freezeGame) begin

			SM_Motion <= FROZEN_ST;
         Yspeed <= 0;

		end
	else begin

	
	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		

				Yspeed <= 0;
				activePipe <= 1'b0;

				if (dispatchPipe) begin
				
					currentGapSize <= effectiveGapSize;
					Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
					GapYposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
					
					Yspeed <= 0;
					
					passedBirdSent <= 1'b0;
					activePipe <= 1'b1;

					SM_Motion <= MOVE_ST;

    end

end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------
		// keys direction change

				if (Y_up_key && !Y_down_key) begin

					if (GapYposition > Y_FRAME_TOP)
						Yspeed <= -PIPE_Y_SPEED;
					else
						Yspeed <= 0;

				end

				else if (Y_down_key && !Y_up_key) begin

					if (GapYposition < Y_FRAME_BOTTOM)
						Yspeed <= PIPE_Y_SPEED;
					else
						Yspeed <= 0;

					end

				else begin

					Yspeed <= 0;

				end
				
				if (startOfFrame )
					SM_Motion <= START_OF_FRAME_ST ; 
					
					
				
		end 
		
		//------------
			START_OF_FRAME_ST:  begin      //check if any colisin was detected 
		//------------

			SM_Motion <= POSITION_CHANGE_ST ; 
		end 

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + pipeXSpeed; 
				GapYposition <= GapYposition + Yspeed ;
			 
				// accelerate 
			/*
				if (Yspeed < MAX_Y_SPEED ) //  limit the speed while going down 
   				Yspeed <= Yspeed - Y_ACCEL ; // deAccelerate : slow the speed down every clock tick 
	
			*/	
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------

			if (GapYposition < Y_FRAME_TOP) begin
					GapYposition <= Y_FRAME_TOP ;
					Yspeed <= 0;
			end	
			if (GapYposition > Y_FRAME_BOTTOM) begin
					GapYposition <= Y_FRAME_BOTTOM ; 
					Yspeed <= 0;
			end
			
			//---- after Y  limits
			if (!passedBirdSent && (Xposition + (PIPE_WIDTH >> 1) * FIXED_POINT_MULTIPLIER <= BIRD_X_POS * FIXED_POINT_MULTIPLIER)) begin
				passedBirdPulse <= 1'b1;
				passedBirdSent <= 1'b1;

			end
			// bird Passed
			    // Pipe completely left the screen
			if (Xposition <= - PIPE_WIDTH * FIXED_POINT_MULTIPLIER)
			begin
				Yspeed <= 0;
				activePipe <= 1'b0;
				SM_Motion <= IDLE_ST;

			end
			else begin
				SM_Motion <= MOVE_ST;
			end
		end
			
		FROZEN_ST: begin

			Yspeed <= 0; // positions are NOT changed
			SM_Motion <= FROZEN_ST;
			
		end
		
		endcase  // case 

		
		end 
	end
end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	gapTopY_tmp = GapYposition / FIXED_POINT_MULTIPLIER ;    

assign 	topLeftX = {topLeftX_tmp[10:0]} ;   // note it must be 2^n 
assign 	gapTopY = {gapTopY_tmp[10:0]} ;    	

endmodule	
//---------------
