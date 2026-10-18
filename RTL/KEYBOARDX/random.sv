// (c) Technion IIT, Department of Electrical Engineering 2025

module random
(
    input  logic clk,
    input  logic resetN,
    input  logic rise,
    output logic unsigned [SIZE_BITS-1:0] dout
);

// Parameters
parameter SIZE_BITS = 8;
parameter unsigned [SIZE_BITS-1:0] MIN_VAL = 0;
parameter unsigned [SIZE_BITS-1:0] MAX_VAL = 255;

// 32-bit LFSR
logic [31:0] lfsr; //linear-feedback shift register

// Free-running counter for seed generation
logic [31:0] counter /* synthesis keep = 1 */;

// Rising edge detection
logic rise_d /* synthesis keep = 1 */;

// Seed generation
logic [31:0] mixed_seed;
logic [31:0] new_seed;

// Output range (extra bit prevents overflow)
localparam logic [SIZE_BITS:0] RANGE = {1'b0, MAX_VAL} - {1'b0, MIN_VAL} + 1'b1;

// Mix LFSR state with counter
assign mixed_seed = lfsr ^ counter;

// Prevent zero state in LFSR
assign new_seed = (mixed_seed == 32'd0) ? 32'd1 : mixed_seed;

always_ff @(posedge clk or negedge resetN) begin

    if (!resetN) begin

        lfsr <= 32'hA5C31F27;
        counter <= 32'd0;
        rise_d <= 1'b0;

        dout <= MIN_VAL + ((MAX_VAL - MIN_VAL) >> 1);

    end

    else begin

        // Free-running counter
        counter <= counter + 32'd1;

        // Rising edge detection
        rise_d <= rise;

        // Reseed when player presses a key
        if (rise && !rise_d) begin
            lfsr <= new_seed;
        end
        else begin
            // Normal LFSR operation
            lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        end

        // Update random output EVERY clock cycle
        dout <= MIN_VAL + SIZE_BITS'(lfsr % RANGE);

    end

end

endmodule