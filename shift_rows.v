`timescale 1ns / 1ps

module shift_rows (
    input  wire [127:0] in_data,
    output wire [127:0] out_data
);
    // Row 0: No shift (Bytes 0, 4, 8, 12)
    assign out_data[127:120] = in_data[127:120]; 
    assign out_data[95:88]   = in_data[95:88];
    assign out_data[63:56]   = in_data[63:56];
    assign out_data[31:24]   = in_data[31:24];

    // Row 1: Shift left by 1 (Bytes 1, 5, 9, 13)
    assign out_data[119:112] = in_data[87:80];   
    assign out_data[87:80]   = in_data[55:48];   
    assign out_data[55:48]   = in_data[23:16];   
    assign out_data[23:16]   = in_data[119:112]; 

    // Row 2: Shift left by 2 (Bytes 2, 6, 10, 14)
    assign out_data[111:104] = in_data[47:40];
    assign out_data[79:72]   = in_data[15:8];
    assign out_data[47:40]   = in_data[111:104];
    assign out_data[15:8]    = in_data[79:72];

    // Row 3: Shift left by 3 (Bytes 3, 7, 11, 15)
    assign out_data[103:96]  = in_data[7:0];
    assign out_data[71:64]   = in_data[103:96];
    assign out_data[39:32]   = in_data[71:64];
    assign out_data[7:0]     = in_data[39:32];

endmodule