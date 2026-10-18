// PipeBitMap File 
// A one dimensional bitmap. dosplaying harts on the screen Feb 2025 



module	PipeBitmap(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic [10:0] gapSize,
					input logic [10:0] gapTopY,
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;
 

 
 
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 
localparam logic [10:0] CAP_HEIGHT = 11'd22;




logic [10:0] address;
logic [0:1][7:0] color;
 // ------------------------------------------------


logic [10:0] upperCapTopY;
logic [10:0] gapBottomY;
logic [10:0] lowerCapBottomY;

logic [10:0] upperCapOffsetY;
logic [10:0] lowerCapOffsetY;

assign upperCapOffsetY = offsetY - upperCapTopY;
assign lowerCapOffsetY = offsetY - gapBottomY;

assign upperCapTopY = gapTopY - CAP_HEIGHT;

assign gapBottomY = gapTopY + gapSize;

assign lowerCapBottomY = gapBottomY + CAP_HEIGHT;


logic [5:0] bitmapX;
logic [4:0] bitmapY;

assign bitmapX = offsetX[5:0];

always_comb begin //mirroring address logic for upper and lower pipe
    bitmapY = 5'd0;

    if (offsetY < upperCapTopY) begin
        // upper shaft - single row texture
        bitmapY = 5'd0;
    end

    else if (offsetY < gapTopY) begin
        // upper cap - mirrored vertically
        bitmapY = 5'd21 - upperCapOffsetY[4:0];
    end

    else if (offsetY < gapBottomY) begin
        // gap - address irrelevant
        bitmapY = 5'd0;
    end

    else if (offsetY < lowerCapBottomY) begin
        // lower cap - normal
        bitmapY = lowerCapOffsetY[4:0];
    end

    else begin
        // lower shaft - single row texture
        bitmapY = 5'd0;
    end

end

assign address = {bitmapY, bitmapX};
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 



lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(1408),
    .LPM_FILE("RTL/cap_64x22.mif"),
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
    .q(color[0])
);

 
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(6),
	 .LPM_NUMWORDS(64),
    .LPM_FILE("RTL/shaft_64x1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst2 (
    .address(bitmapX),
	 .inclock(clk),
	// .outclock(clk),
    .q(color[1])
); 

 

//==----------------------------------------------------------------------------------------------------------------=

always_ff @(posedge clk or negedge resetN)
begin
    if (!resetN) begin

        RGBout <= TRANSPARENT_ENCODING;

    end
    else begin

        RGBout <= TRANSPARENT_ENCODING;

        if (InsideRectangle == 1'b1) begin

            if (offsetY < upperCapTopY) begin
                // upper shaft
                RGBout <= color[1];
            end

            else if (offsetY < gapTopY) begin
                // upper cap
                RGBout <= color[0];
            end

            else if (offsetY < gapBottomY) begin
                // gap
                RGBout <= TRANSPARENT_ENCODING;
            end

            else if (offsetY < lowerCapBottomY) begin
                // lower cap
                RGBout <= color[0];
            end

            else begin
                // lower shaft
                RGBout <= color[1];
            end

        end
    end
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule

