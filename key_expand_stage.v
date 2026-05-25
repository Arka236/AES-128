module key_expand_stage (
    input wire[127:0] key_in,
    input wire[7:0] rcon,
    output wire[127:0] key_out
);
wire [31:0] w0 = key_in[127:96];
wire [31:0] w1 = key_in[95:64];
wire [31:0] w2 = key_in[63:32];
wire [31:0] w3 = key_in[31:0];
//1.rotate
wire [31:0] rot_w3={w3[23:0],w3[31:24]};
//2.subword using sbox
wire [31:0] sub_w3;
genvar k;
generate
    for (k=0;k<4;k=k+1 ) begin:sub_gen
        sbox sub_w3_inst1(.in_byte(rot_w3[(k*8)+7:(k*8)]),.out_byte(sub_w3[(k*8)+7:(k*8)]));

        
    end
endgenerate
//3.rcon
wire[7:0]r_out=sub_w3[31:24]^rcon;
wire[31:0]g_w3={r_out,sub_w3[23:0]};


wire [31:0] w4 = w0 ^ g_w3;
wire [31:0] w5 = w1 ^ w4;
wire [31:0] w6 = w2 ^ w5;
wire [31:0] w7 = w3 ^ w6;

assign key_out={w4,w5,w6,w7};



endmodule