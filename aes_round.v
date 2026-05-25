`timescale 1ns/1ps
module aes_round (
    input clk,
    input wire [127:0]state_in,
    input wire [127:0]round_key_in,
    output reg [127:0]state_out
);

wire [127:0]sub_bytes_out ;
wire [127:0]shift_rows_out;
wire [127:0]mix_columns_out;
wire [127:0]add_key_out;
//subBytes
genvar i;
generate
    for (i =0 ;i<16 ;i=i+1 ) begin:sbox_gen
        sbox sbox_inst(.in_byte(state_in[(i*8)+7:(i*8)]),.out_byte(sub_bytes_out[(i*8)+7:(i*8)]));
        
    end
endgenerate   
//shiftRows
shift_rows sr_inst(
    .in_data(sub_bytes_out[127:0]),
    .out_data(shift_rows_out[127:0])
);
//MixColumns
genvar j;
generate
    for (j=0;j<4 ;j=j+1 ) begin:mixcol_gen
        mix_columns_32bit mc_inst(
            .in_col(shift_rows_out[(j*32)+31:(j*32)]),
            .out_col(mix_columns_out[(j*32)+31:(j*32)])
        ); 
        
    end
endgenerate
//AddRoundKey
assign add_key_out=mix_columns_out ^ round_key_in;

always @(posedge clk ) begin
    state_out<=add_key_out;
    
end


endmodule