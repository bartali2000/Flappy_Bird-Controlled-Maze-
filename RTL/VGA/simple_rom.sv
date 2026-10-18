module simple_rom #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 2048,
    parameter string MIF_FILE = "" // שם קובץ ה-MIF שנטען לזיכרון
)(
    input  logic                   clk,
    input  logic [10:0]            address, // כתובת הפיקסל בזיכרון
    output logic [WIDTH-1:0]       q        // נתוני הצבע שחוזרים מהזיכרון
);

    // הגדרת מערך הזיכרון
    (* ram_init_file = MIF_FILE *) logic [WIDTH-1:0] mem [0:DEPTH-1];

    // קריאה סינכרונית מהזיכרון (מתמפה באופן אוטומטי לבלוקי M9K בחומרה)
    always_ff @(posedge clk) begin
        q <= mem[address];
    end

endmodule