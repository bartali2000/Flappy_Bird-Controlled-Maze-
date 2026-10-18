module day_night_controller (
    input  logic        clk,
    input  logic        resetN,
    input  logic        frame_pulse,
    input  logic        next_level_pulse, 
    input  logic        game_init_pulse,  // <--- כניסה חדשה לאיפוס מצב הבוקר

    output logic [7:0]  sky_color,
    output logic [7:0]  celestial_color,
    output logic [10:0] celestial_x,
    output logic [10:0] celestial_y,
    output logic        is_night
);

    typedef enum logic [1:0] {
        ST_DAY    = 2'd0,
        ST_SUNSET = 2'd1,
        ST_NIGHT  = 2'd2
    } day_state_t;

    day_state_t current_state;
    logic [10:0] frame_counter;

    localparam [10:0] MAX_FRAMES = 11'd1024;

  always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            current_state <= ST_DAY;
            frame_counter <= 11'd0;
        end else if (game_init_pulse) begin // <--- מעבר סינכרוני למצב בוקר
            current_state <= ST_DAY;
            frame_counter <= 11'd0;
        end else if (frame_pulse) begin
            if (next_level_pulse || (frame_counter >= MAX_FRAMES - 1'b1)) begin
                frame_counter <= 11'd0;
                if (current_state == ST_DAY)
                    current_state <= ST_SUNSET;
                else if (current_state == ST_SUNSET)
                    current_state <= ST_NIGHT;
                else
                    current_state <= ST_DAY;
            end else begin
                frame_counter <= frame_counter + 1'b1;
            end
        end
    end

    // (שאר קוד ה-always_comb נשאר בדיוק כפי שהיה)
    always_comb begin
        case (current_state)
            ST_DAY: begin
                sky_color       = 8'h7B; 
                celestial_color = 8'hFC; 
                is_night        = 1'b0;
                celestial_x     = 11'd580 - (frame_counter >> 2);
                celestial_y     = 11'd70;
            end
            ST_SUNSET: begin
                is_night = 1'b0;
                celestial_x     = 11'd324 - (frame_counter >> 2);
                celestial_y     = 11'd70 + (frame_counter >> 2) + (frame_counter >> 4); 
                if (frame_counter < 11'd400) begin
                    sky_color       = 8'h7B; 
                    celestial_color = 8'hFC; 
                end else if (frame_counter < 11'd750) begin
                    sky_color       = 8'h2B; 
                    celestial_color = 8'hE0; 
                end else begin
                    sky_color       = 8'h02; 
                    celestial_color = 8'h00; 
                end
            end
            ST_NIGHT: begin
                sky_color       = 8'h01; 
                celestial_color = 8'hFF; 
                is_night        = 1'b1;
                celestial_x     = 11'd450;
                celestial_y     = 11'd65;
            end
            default: begin
                sky_color       = 8'h7B;
                celestial_color = 8'hFC;
                celestial_x     = 11'd320;
                celestial_y     = 11'd70;
                is_night        = 1'b0;
            end
        endcase
    end

endmodule