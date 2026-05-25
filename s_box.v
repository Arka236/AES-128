`timescale 1ns / 1ps

module sbox (
    input  wire [7:0] in_byte,
    output reg  [7:0] out_byte
);

    always @(*) begin
        case (in_byte)
            8'h00: out_byte = 8'h63; 8'h01: out_byte = 8'h7C; 8'h02: out_byte = 8'h77; 8'h03: out_byte = 8'h7B;
            8'h04: out_byte = 8'hF2; 8'h05: out_byte = 8'h6B; 8'h06: out_byte = 8'h6F; 8'h07: out_byte = 8'hC5;
            8'h08: out_byte = 8'h30; 8'h09: out_byte = 8'h01; 8'h0A: out_byte = 8'h67; 8'h0B: out_byte = 8'h2B;
            8'h0C: out_byte = 8'hFE; 8'h0D: out_byte = 8'hD7; 8'h0E: out_byte = 8'hAB; 8'h0F: out_byte = 8'h76;
            
            8'h10: out_byte = 8'hCA; 8'h11: out_byte = 8'h82; 8'h12: out_byte = 8'hC9; 8'h13: out_byte = 8'h7D;
            8'h14: out_byte = 8'hFA; 8'h15: out_byte = 8'h59; 8'h16: out_byte = 8'h47; 8'h17: out_byte = 8'hF0;
            8'h18: out_byte = 8'hAD; 8'h19: out_byte = 8'hD4; 8'h1A: out_byte = 8'hA2; 8'h1B: out_byte = 8'hAF;
            8'h1C: out_byte = 8'h9C; 8'h1D: out_byte = 8'hA4; 8'h1E: out_byte = 8'h72; 8'h1F: out_byte = 8'hC0;
            
            8'h20: out_byte = 8'hB7; 8'h21: out_byte = 8'hFD; 8'h22: out_byte = 8'h93; 8'h23: out_byte = 8'h26;
            8'h24: out_byte = 8'h36; 8'h25: out_byte = 8'h3F; 8'h26: out_byte = 8'hF7; 8'h27: out_byte = 8'hCC;
            8'h28: out_byte = 8'h34; 8'h29: out_byte = 8'hA5; 8'h2A: out_byte = 8'hE5; 8'h2B: out_byte = 8'hF1;
            8'h2C: out_byte = 8'h71; 8'h2D: out_byte = 8'hD8; 8'h2E: out_byte = 8'h31; 8'h2F: out_byte = 8'h15;
            
            8'h30: out_byte = 8'h04; 8'h31: out_byte = 8'hC7; 8'h32: out_byte = 8'h23; 8'h33: out_byte = 8'hC3;
            8'h34: out_byte = 8'h18; 8'h35: out_byte = 8'h96; 8'h36: out_byte = 8'h05; 8'h37: out_byte = 8'h9A;
            8'h38: out_byte = 8'h07; 8'h39: out_byte = 8'h12; 8'h3A: out_byte = 8'h80; 8'h3B: out_byte = 8'hE2;
            8'h3C: out_byte = 8'hEB; 8'h3D: out_byte = 8'h27; 8'h3E: out_byte = 8'hB2; 8'h3F: out_byte = 8'h75;
            
            8'h40: out_byte = 8'h09; 8'h41: out_byte = 8'h83; 8'h42: out_byte = 8'h2C; 8'h43: out_byte = 8'h1A;
            8'h44: out_byte = 8'h1B; 8'h45: out_byte = 8'h6E; 8'h46: out_byte = 8'h5A; 8'h47: out_byte = 8'hA0;
            8'h48: out_byte = 8'h52; 8'h49: out_byte = 8'h3B; 8'h4A: out_byte = 8'hD6; 8'h4B: out_byte = 8'hB3;
            8'h4C: out_byte = 8'h29; 8'h4D: out_byte = 8'hE3; 8'h4E: out_byte = 8'h2F; 8'h4F: out_byte = 8'h84;
            
            8'h50: out_byte = 8'h53; 8'h51: out_byte = 8'hD1; 8'h52: out_byte = 8'h00; 8'h53: out_byte = 8'hED;
            8'h54: out_byte = 8'h20; 8'h55: out_byte = 8'hFC; 8'h56: out_byte = 8'hB1; 8'h57: out_byte = 8'h5B;
            8'h58: out_byte = 8'h6A; 8'h59: out_byte = 8'hCB; 8'h5A: out_byte = 8'hBE; 8'h5B: out_byte = 8'h39;
            8'h5C: out_byte = 8'h4A; 8'h5D: out_byte = 8'h4C; 8'h5E: out_byte = 8'h58; 8'h5F: out_byte = 8'hCF;
            
            8'h60: out_byte = 8'hD0; 8'h61: out_byte = 8'hEF; 8'h62: out_byte = 8'hAA; 8'h63: out_byte = 8'hFB;
            8'h64: out_byte = 8'h43; 8'h65: out_byte = 8'h4D; 8'h66: out_byte = 8'h33; 8'h67: out_byte = 8'h85;
            8'h68: out_byte = 8'h45; 8'h69: out_byte = 8'hF9; 8'h6A: out_byte = 8'h02; 8'h6B: out_byte = 8'h7F;
            8'h6C: out_byte = 8'h50; 8'h6D: out_byte = 8'h3C; 8'h6E: out_byte = 8'h9F; 8'h6F: out_byte = 8'hA8;
            
            8'h70: out_byte = 8'h51; 8'h71: out_byte = 8'hA3; 8'h72: out_byte = 8'h40; 8'h73: out_byte = 8'h8F;
            8'h74: out_byte = 8'h92; 8'h75: out_byte = 8'h9D; 8'h76: out_byte = 8'h38; 8'h77: out_byte = 8'hF5;
            8'h78: out_byte = 8'hBC; 8'h79: out_byte = 8'hB6; 8'h7A: out_byte = 8'hDA; 8'h7B: out_byte = 8'h21;
            8'h7C: out_byte = 8'h10; 8'h7D: out_byte = 8'hFF; 8'h7E: out_byte = 8'hF3; 8'h7F: out_byte = 8'hD2;
            
            8'h80: out_byte = 8'hCD; 8'h81: out_byte = 8'h0C; 8'h82: out_byte = 8'h13; 8'h83: out_byte = 8'hEC;
            8'h84: out_byte = 8'h5F; 8'h85: out_byte = 8'h97; 8'h86: out_byte = 8'h44; 8'h87: out_byte = 8'h17;
            8'h88: out_byte = 8'hC4; 8'h89: out_byte = 8'hA7; 8'h8A: out_byte = 8'h7E; 8'h8B: out_byte = 8'h3D;
            8'h8C: out_byte = 8'h64; 8'h8D: out_byte = 8'h5D; 8'h8E: out_byte = 8'h19; 8'h8F: out_byte = 8'h73;
            
            8'h90: out_byte = 8'h60; 8'h91: out_byte = 8'h81; 8'h92: out_byte = 8'h4F; 8'h93: out_byte = 8'hDC;
            8'h94: out_byte = 8'h22; 8'h95: out_byte = 8'h2A; 8'h96: out_byte = 8'h90; 8'h97: out_byte = 8'h88;
            8'h98: out_byte = 8'h46; 8'h99: out_byte = 8'hEE; 8'h9A: out_byte = 8'hB8; 8'h9B: out_byte = 8'h14;
            8'h9C: out_byte = 8'hDE; 8'h9D: out_byte = 8'h5E; 8'h9E: out_byte = 8'h0B; 8'h9F: out_byte = 8'hDB;
            
            8'hA0: out_byte = 8'hE0; 8'hA1: out_byte = 8'h32; 8'hA2: out_byte = 8'h3A; 8'hA3: out_byte = 8'h0A;
            8'hA4: out_byte = 8'h49; 8'hA5: out_byte = 8'h06; 8'hA6: out_byte = 8'h24; 8'hA7: out_byte = 8'h5C;
            8'hA8: out_byte = 8'hC2; 8'hA9: out_byte = 8'hD3; 8'hAA: out_byte = 8'hAC; 8'hAB: out_byte = 8'h62;
            8'hAC: out_byte = 8'h91; 8'hAD: out_byte = 8'h95; 8'hAE: out_byte = 8'hE4; 8'hAF: out_byte = 8'h79;
            
            8'hB0: out_byte = 8'hE7; 8'hB1: out_byte = 8'hC8; 8'hB2: out_byte = 8'h37; 8'hB3: out_byte = 8'h6D;
            8'hB4: out_byte = 8'h8D; 8'hB5: out_byte = 8'hD5; 8'hB6: out_byte = 8'h4E; 8'hB7: out_byte = 8'hA9;
            8'hB8: out_byte = 8'h6C; 8'hB9: out_byte = 8'h56; 8'hBA: out_byte = 8'hF4; 8'hBB: out_byte = 8'hEA;
            8'hBC: out_byte = 8'h65; 8'hBD: out_byte = 8'h7A; 8'hBE: out_byte = 8'hAE; 8'hBF: out_byte = 8'h08;
            
            8'hC0: out_byte = 8'hBA; 8'hC1: out_byte = 8'h78; 8'hC2: out_byte = 8'h25; 8'hC3: out_byte = 8'h2E;
            8'hC4: out_byte = 8'h1C; 8'hC5: out_byte = 8'hA6; 8'hC6: out_byte = 8'hB4; 8'hC7: out_byte = 8'hC6;
            8'hC8: out_byte = 8'hE8; 8'hC9: out_byte = 8'hDD; 8'hCA: out_byte = 8'h74; 8'hCB: out_byte = 8'h1F;
            8'hCC: out_byte = 8'h4B; 8'hCD: out_byte = 8'hBD; 8'hCE: out_byte = 8'h8B; 8'hCF: out_byte = 8'h8A;
            
            8'hD0: out_byte = 8'h70; 8'hD1: out_byte = 8'h3E; 8'hD2: out_byte = 8'hB5; 8'hD3: out_byte = 8'h66;
            8'hD4: out_byte = 8'h48; 8'hD5: out_byte = 8'h03; 8'hD6: out_byte = 8'hF6; 8'hD7: out_byte = 8'h0E;
            8'hD8: out_byte = 8'h61; 8'hD9: out_byte = 8'h35; 8'hDA: out_byte = 8'h57; 8'hDB: out_byte = 8'hB9;
            8'hDC: out_byte = 8'h86; 8'hDD: out_byte = 8'hC1; 8'hDE: out_byte = 8'h1D; 8'hDF: out_byte = 8'h9E;
            
            8'hE0: out_byte = 8'hE1; 8'hE1: out_byte = 8'hF8; 8'hE2: out_byte = 8'h98; 8'hE3: out_byte = 8'h11;
            8'hE4: out_byte = 8'h69; 8'hE5: out_byte = 8'hD9; 8'hE6: out_byte = 8'h8E; 8'hE7: out_byte = 8'h94;
            8'hE8: out_byte = 8'h9B; 8'hE9: out_byte = 8'h1E; 8'hEA: out_byte = 8'h87; 8'hEB: out_byte = 8'hE9;
            8'hEC: out_byte = 8'hCE; 8'hED: out_byte = 8'h55; 8'hEE: out_byte = 8'h28; 8'hEF: out_byte = 8'hDF;
            
            8'hF0: out_byte = 8'h8C; 8'hF1: out_byte = 8'hA1; 8'hF2: out_byte = 8'h89; 8'hF3: out_byte = 8'h0D;
            8'hF4: out_byte = 8'hBF; 8'hF5: out_byte = 8'hE6; 8'hF6: out_byte = 8'h42; 8'hF7: out_byte = 8'h68;
            8'hF8: out_byte = 8'h41; 8'hF9: out_byte = 8'h99; 8'hFA: out_byte = 8'h2D; 8'hFB: out_byte = 8'h0F;
            8'hFC: out_byte = 8'hB0; 8'hFD: out_byte = 8'h54; 8'hFE: out_byte = 8'hBB; 8'hFF: out_byte = 8'h16;
            
            default: out_byte = 8'h00; // Hardware safety catch
        endcase
    end
endmodule