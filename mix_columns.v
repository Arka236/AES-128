`timescale 1ns / 1ps

module mix_columns_32bit (
    input  wire [31:0] in_col,
    output wire [31:0] out_col
);

    wire [7:0] b0 = in_col[31:24];
    wire [7:0] b1 = in_col[23:16];
    wire [7:0] b2 = in_col[15:8];
    wire [7:0] b3 = in_col[7:0];

    // Hardware function for GF(2^8) multiply by 2
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = x[7] ? ((x << 1) ^ 8'h1B) : (x << 1);
        end
    endfunction

    // Matrix multiplication using the xtime function and XORs
    assign out_col[31:24] = xtime(b0) ^ (xtime(b1) ^ b1) ^ b2 ^ b3;
    assign out_col[23:16] = b0 ^ xtime(b1) ^ (xtime(b2) ^ b2) ^ b3;
    assign out_col[15:8]  = b0 ^ b1 ^ xtime(b2) ^ (xtime(b3) ^ b3);
    assign out_col[7:0]   = (xtime(b0) ^ b0) ^ b1 ^ b2 ^ xtime(b3);

endmodule