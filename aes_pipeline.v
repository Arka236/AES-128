`timescale 1ns / 1ps

module aes_pipeline (
    input  wire         clk,
    input  wire [127:0] plaintext,
    input  wire [127:0] key_0,    
    output wire [127:0] ciphertext
);

    reg  [127:0] state_0;
    wire [127:0] state_1; wire [127:0] state_2; wire [127:0] state_3;
    wire [127:0] state_4; wire [127:0] state_5; wire [127:0] state_6;
    wire [127:0] state_7; wire [127:0] state_8; wire [127:0] state_9;

    wire [127:0] next_key_1, next_key_2, next_key_3, next_key_4, next_key_5;
    wire [127:0] next_key_6, next_key_7, next_key_8, next_key_9, next_key_10;
    
    reg  [127:0] reg_key_1, reg_key_2, reg_key_3, reg_key_4, reg_key_5;
    reg  [127:0] reg_key_6, reg_key_7, reg_key_8, reg_key_9, reg_key_10;
   
    key_expand_stage k1  ( .key_in(key_0),      .rcon(8'h01), .key_out(next_key_1) );
    key_expand_stage k2  ( .key_in(reg_key_1),  .rcon(8'h02), .key_out(next_key_2) );
    key_expand_stage k3  ( .key_in(reg_key_2),  .rcon(8'h04), .key_out(next_key_3) );
    key_expand_stage k4  ( .key_in(reg_key_3),  .rcon(8'h08), .key_out(next_key_4) );
    key_expand_stage k5  ( .key_in(reg_key_4),  .rcon(8'h10), .key_out(next_key_5) );
    key_expand_stage k6  ( .key_in(reg_key_5),  .rcon(8'h20), .key_out(next_key_6) );
    key_expand_stage k7  ( .key_in(reg_key_6),  .rcon(8'h40), .key_out(next_key_7) );
    key_expand_stage k8  ( .key_in(reg_key_7),  .rcon(8'h80), .key_out(next_key_8) );
    key_expand_stage k9  ( .key_in(reg_key_8),  .rcon(8'h1B), .key_out(next_key_9) );
    key_expand_stage k10 ( .key_in(reg_key_9),  .rcon(8'h36), .key_out(next_key_10) );

    // Initial AddRoundKey (Registered for pipeline timing)
    always @(posedge clk) begin
        state_0 <= plaintext ^ key_0;
        reg_key_1<=next_key_1;
        reg_key_2<=next_key_2;
        reg_key_3<=next_key_3;
        reg_key_4<=next_key_4;
        reg_key_5<=next_key_5;
        reg_key_6<=next_key_6;
        reg_key_7<=next_key_7;
        reg_key_8<=next_key_8;
        reg_key_9<=next_key_9;
        reg_key_10<=next_key_10;
    end

    // The 9 Standard Rounds
    aes_round r1 ( .clk(clk), .state_in(state_0), .round_key_in(reg_key_1), .state_out(state_1) );
    aes_round r2 ( .clk(clk), .state_in(state_1), .round_key_in(reg_key_2), .state_out(state_2) );
    aes_round r3 ( .clk(clk), .state_in(state_2), .round_key_in(reg_key_3), .state_out(state_3) );
    aes_round r4 ( .clk(clk), .state_in(state_3), .round_key_in(reg_key_4), .state_out(state_4) );
    aes_round r5 ( .clk(clk), .state_in(state_4), .round_key_in(reg_key_5), .state_out(state_5) );
    aes_round r6 ( .clk(clk), .state_in(state_5), .round_key_in(reg_key_6), .state_out(state_6) );
    aes_round r7 ( .clk(clk), .state_in(state_6), .round_key_in(reg_key_7), .state_out(state_7) );
    aes_round r8 ( .clk(clk), .state_in(state_7), .round_key_in(reg_key_8), .state_out(state_8) );
    aes_round r9 ( .clk(clk), .state_in(state_8), .round_key_in(reg_key_9), .state_out(state_9) );

    // The Final Round
    aes_round_last r10 ( .clk(clk), .state_in(state_9), .round_key_in(reg_key_10), .state_out(ciphertext) );

endmodule