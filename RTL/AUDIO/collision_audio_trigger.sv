module collision_audio_trigger (
    input  logic       clk,
    input  logic       resetN,
    input  logic       collision_pulse, // מגיע מ-game_controller (SingleHitPulseBird)

    output logic [3:0] melodySelect,    // תמיד שיר 0 (ראש בקיר)
    output logic       startMelody      // פולס הפעלה לנגן
);

    assign melodySelect = 4'h0; // תמיד שיר 0

    logic pulse_d;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pulse_d     <= 1'b0;
            startMelody <= 1'b0;
        end
        else begin
            pulse_d <= collision_pulse;
            // מזהה עליית אות של ההתנגשות ומפיק פולס בודד של מחזור שעון אחד
            if (collision_pulse && !pulse_d) begin
                startMelody <= 1'b1;
            end
            else begin
                startMelody <= 1'b0;
            end
        end
    end

endmodule