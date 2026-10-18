// birdBitMap.sv - מודול הצגת הציפור מתוך קובץ ה-MIF
module birdBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,         // היסט X ביחס לפינה השמאלית-עליונה
    input  logic [10:0] offsetY,         // היסט Y ביחס לפינה השמאלית-עליונה
    input  logic        InsideRectangle, // דגל שמציין שהפיקסל נמצא בתוך שטח הריבוע

    output logic        drawingRequest,  // דגל: האם לצייר את הפיקסל (אינו שקוף)
    output logic [7:0]  RGBout           // ערך הצבע של הפיקסל
);

localparam int OBJECT_WIDTH_X  = 32;
localparam int OBJECT_HEIGHT_Y = 32;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'h00; // 00 הוא הרקע השקוף מקובץ ה-MIF

logic [9:0] address;
logic [7:0] color;

// חישוב כתובת בזיכרון (32 פיקסלים בשורה)
assign address = (offsetY * OBJECT_WIDTH_X) + offsetX;

// מודול ROM מובנה הקורא את קובץ ה-MIF של הציפור
// שים לב: הלוכסנים שונו ללוכסנים קדמיים (/) כדי למנוע שגיאות קידוד ב-Verilog
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),             // 2^10 = 1024 תאים (32x32)
    .LPM_NUMWORDS(1024),
    .LPM_FILE("C:/Users/barak/labs/lab1A/VGA/VGA_start_of_project/MVP/RTL/bird.mif"), 
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"),
    .LPM_OUTDATA("UNREGISTERED"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) rom_inst (
    .address(address),
    .inclock(clk),
    .q(color)
);

// סנכרון צינור (Pipeline) לעיכוב אות ה-InsideRectangle בשעון אחד
// זה חובה כדי להמתין לנתונים שיוצאים מה-ROM ומונע עיוותים בציור
logic InsideRectangle_d;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        InsideRectangle_d <= 1'b0;
    end else begin
        InsideRectangle_d <= InsideRectangle; 
    end
end

// קביעת צבע הפיקסל
always_comb begin
    RGBout = TRANSPARENT_ENCODING; // ברירת מחדל: שקוף
    if (InsideRectangle_d) begin
        RGBout = color;
    end
end

// פיקסל יצויר רק אם הוא נמצא בתוך הריבוע המעוכב ואינו שקוף
assign drawingRequest = (InsideRectangle_d && (RGBout != TRANSPARENT_ENCODING)) ? 1'b1 : 1'b0;

endmodule