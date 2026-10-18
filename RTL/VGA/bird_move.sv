module bird_move (
    input  logic              clk,
    input  logic              resetN,
    input  logic              startOfFrame,
    input  logic              collision,    // אות התנגשות מבקר המשחק
    input  logic [2:0]        overlaySelect, // <-- חדש: מצב המשחק מה-Game Controller

    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY
);

// קבועים ומיקומים
localparam int FIXED_X   = 120;
localparam int INITIAL_Y = 220; 

// פיזיקה מעודנת 
localparam int FIXED_POINT_MULTIPLIER = 64; 
localparam int GRAVITY                = 5;    // כוח משיכה עדין
localparam int JUMP_SPEED             = -160; // קפיצה חלקה
localparam int DEATH_JUMP_SPEED       = -100; // מכת מוות קטנה
localparam int MAX_Y_SPEED            = 300;  // מהירות נפילה מקסימלית

localparam int GROUND_Y               = 388; // גובה העצירה על הדשא

// אזורי טייס אוטומטי (Auto-Pilot)
localparam int ZONE_TOP               = 100; 
localparam int ZONE_BOTTOM            = 280; 

// מצבי המשחק (מתורגם מ-overlaySelect)
localparam logic [2:0] STATE_WAIT_START = 3'b101;
localparam logic [2:0] STATE_PLAYING    = 3'b001;
localparam logic [2:0] STATE_GAME_OVER  = 3'b010;
// Note: INIT_GAME is 3'b000 but it typically lasts 1 clock cycle before becoming PLAYING.

// משתני מצב לפיזיקה
int Yposition;
int Yspeed;

// דגלי פסילה
logic is_dead;
logic is_dead_prev;

// --- מלכודת התנגשות (Latch) ומנגנון Reset לפי מצב המשחק ---
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        is_dead <= 1'b0;
    end 
    // כשהמשחק חוזר להתחלה, אנחנו קמים לתחייה!
    else if (overlaySelect == STATE_WAIT_START || overlaySelect == 3'b000) begin
        is_dead <= 1'b0; 
    end
    else if (collision) begin
        is_dead <= 1'b1; // ננעל במצב מוות
    end
end

// --- מחולל קפיצות ---
logic [7:0] random_jump_val;
random #(
    .SIZE_BITS(8),
    .MIN_VAL(8'd0),
    .MAX_VAL(8'd95) // RANGE = 96
) rand_jump_gen (
    .clk(clk),
    .resetN(resetN),
    .rise(1'b0),
    .dout(random_jump_val)
);

assign topLeftX = FIXED_X;

// המרה חזרה מ-Fixed Point לפיקסלים
int topLeftY_tmp;
assign topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER;
assign topLeftY = topLeftY_tmp[10:0];

// --- מנוע הפיזיקה והתנועה ---
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        Yposition    <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
        Yspeed       <= 0;
        is_dead_prev <= 1'b0;
    end 
    else if (startOfFrame) begin
        
        is_dead_prev <= is_dead;
        
        // --- מצב 1: מסך התחלה (Wait Start) ---
        // הציפור מרחפת במקום (קפואה) ולא נופלת!
        if (overlaySelect == STATE_WAIT_START || overlaySelect == 3'b000) begin
            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
            Yspeed    <= 0;
        end
        
        // --- מצב 2: פסילה ומוות (Game Over או תהליך צניחה) ---
        else if (is_dead || overlaySelect == STATE_GAME_OVER) begin
            if (!is_dead_prev) begin
                Yspeed    <= DEATH_JUMP_SPEED; // מכת מוות
                Yposition <= Yposition + DEATH_JUMP_SPEED;
            end
            else if (topLeftY_tmp < GROUND_Y) begin
                // נופלת לאדמה
                if (Yspeed < MAX_Y_SPEED) Yspeed <= Yspeed + GRAVITY;
                Yposition <= Yposition + Yspeed;
            end
            else begin
                // פגעה בדשא - עצירה מוחלטת
                Yposition <= GROUND_Y * FIXED_POINT_MULTIPLIER;
                Yspeed    <= 0;
            end
        end
        
        // --- מצב 3: משחק פעיל (Playing + Auto-Pilot) ---
        else begin
            logic do_jump;
            do_jump = 1'b0;
            
            // בקרת גבולות חכמה
            if (topLeftY_tmp > ZONE_BOTTOM) begin
                do_jump = 1'b1; 
            end 
            else if (topLeftY_tmp < ZONE_TOP) begin
                do_jump = 1'b0; 
            end 
            else begin
                if (random_jump_val == 8'd0) begin
                    do_jump = 1'b1;
                end
            end

            // תנועה
            if (do_jump) begin
                Yspeed <= JUMP_SPEED;
            end
            else if (Yspeed < MAX_Y_SPEED) begin
                Yspeed <= Yspeed + GRAVITY;
            end
            
            Yposition <= Yposition + Yspeed;
        end
        
    end
end

endmodule