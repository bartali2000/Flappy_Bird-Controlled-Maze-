
module	pipes_mux	(	
		   // pipes 0-3 
					input logic	[3:0][10:0] offsetX,// offset from top left  position 
					input logic	[3:0][10:0] offsetY,
					input	logic	[3:0]insideRectangle, //input that the pixel is within a bracket 
					input logic [3:0][10:0] gapSize,
					input logic [3:0][10:0] gapTopY,
					
					
				   output 	logic	[10:0] outOffsetX,// offset from top left  position 
					output 	logic	[10:0] outOffsetY,
					output	logic	insidePipeRectangle, //output that the pixel is within a pipe 
					output 	logic [10:0] outGapSize,
					output 	logic [10:0] outGapTopY
);

	always_comb begin
		outOffsetX     = 0;
		outOffsetY     = 0;
		outGapSize     = 0;
		outGapTopY     = 0;
		insidePipeRectangle = 0;
		if (insideRectangle[0] == 1'b1 ) begin 
			outGapSize = gapSize[0];  //first priority 
			outGapTopY= gapTopY[0];
			outOffsetX = offsetX[0];
			outOffsetY = offsetY[0];
			insidePipeRectangle = 1'b1;
			end
		else if (insideRectangle[1] == 1'b1) begin
			outGapSize = gapSize[1];  //first priority 
			outGapTopY= gapTopY[1];
			outOffsetX = offsetX[1];
			outOffsetY = offsetY[1];
			insidePipeRectangle = 1'b1;
		end
 		else if (insideRectangle[2] == 1'b1) begin
			outGapSize = gapSize[2];  //first priority 
			outGapTopY= gapTopY[2];
			outOffsetX = offsetX[2];
			outOffsetY = offsetY[2];
			insidePipeRectangle = 1'b1;
		end
		else if (insideRectangle[3] == 1'b1) begin
			outGapSize = gapSize[3];  //first priority 
			outGapTopY= gapTopY[3];
			outOffsetX = offsetX[3];
			outOffsetY = offsetY[3];
			insidePipeRectangle = 1'b1;
		end

	
	end

endmodule


