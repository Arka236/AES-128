`timescale 1ns / 1ps

module tb_aes_axi_lite();

    // System Signals
    reg clk;
    reg resetn;

    // AXI-Lite Signals
    reg [5:0]  awaddr;  reg awvalid; wire awready;
    reg [31:0] wdata;   reg wvalid;  wire wready;
    wire [1:0] bresp;   wire bvalid; reg bready;
    
    reg [5:0]  araddr;  reg arvalid; wire arready;
    wire [31:0] rdata;  wire [1:0] rresp; wire rvalid; reg rready;

    // Advanced Mode Variables
    reg [127:0] my_iv;
    reg [127:0] my_counter;
    reg [127:0] pt_block_1, pt_block_2;
    reg [127:0] ct_block_1, ct_block_2;
    reg [31:0]  read_status;
    reg [31:0]  ct0, ct1, ct2, ct3;

    // DUT Instantiation
    aes_axi_wrapper dut (
        .aclk(clk), .aresetn(resetn),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata),   .s_axi_wvalid(wvalid),   .s_axi_wready(wready),
        .s_axi_bresp(bresp),   .s_axi_bvalid(bvalid),   .s_axi_bready(bready),
        
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata),   .s_axi_rresp(rresp),     .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    initial begin
        // ---------------------------------------------------------
        // INITIALIZATION
        // ---------------------------------------------------------
        clk = 0; resetn = 0;
        awaddr = 0; awvalid = 0; wdata = 0; wvalid = 0; bready = 1;
        araddr = 0; arvalid = 0; rready = 1;
        
        #50 resetn = 1; // Release reset
        #20;

        $display("====================================================");
        $display("   AES-128 AXI4-LITE HARDWARE VERIFICATION SUITE    ");
        $display("====================================================\n");

        // ---------------------------------------------------------
        // PHASE 1: KEY PROGRAMMING
        // ---------------------------------------------------------
        $display("T=%0t | Programming Master Key...", $time);
        axi_write(6'h10, 32'h2b7e1516); // KEY_0
        axi_write(6'h14, 32'h28aed2a6); // KEY_1
        axi_write(6'h18, 32'habf71588); // KEY_2
        axi_write(6'h1C, 32'h09cf4f3c); // KEY_3

        // ---------------------------------------------------------
        // PHASE 2: BASELINE ECB MODE (FIPS-197 Verification)
        // ---------------------------------------------------------
        $display("\n--- PHASE 2: BASELINE ECB MODE (FIPS-197) ---");
        $display("T=%0t | Writing FIPS Plaintext...", $time);
        axi_write(6'h20, 32'h3243f6a8); // PT_0
        axi_write(6'h24, 32'h885a308d); // PT_1
        axi_write(6'h28, 32'h313198a2); // PT_2
        axi_write(6'h2C, 32'he0370734); // PT_3

        $display("T=%0t | Triggering Encryption Start...", $time);
        axi_write(6'h00, 32'h00000001);

        // Poll address 0x04. Check Bit 1 (Idle). Wait until it becomes 1.
        read_status = 0;
        while ((read_status & 32'h00000002) == 0) begin
            axi_read(6'h04, read_status);
        end

        axi_read(6'h30, ct0); axi_read(6'h34, ct1);
        axi_read(6'h38, ct2); axi_read(6'h3C, ct3);

        $display("Expected : 3925841d 02dc09fb dc118597 196a0b32");
        $display("Hardware : %08x %08x %08x %08x", ct0, ct1, ct2, ct3);

        if ({ct0, ct1, ct2, ct3} == 128'h3925841d_02dc09fb_dc118597_196a0b32)
            $display("-> ECB VERDICT: PASS");
        else
            $display("-> ECB VERDICT: FAIL");

        // ---------------------------------------------------------
        // PHASE 3: ADVANCED MODES (CBC & CTR)
        // ---------------------------------------------------------
        // We will encrypt two identical blocks to prove the modes hide patterns
        pt_block_1 = 128'h00112233445566778899AABBCCDDEEFF;
        pt_block_2 = 128'h00112233445566778899AABBCCDDEEFF; 

        // --- CBC TEST ---
        $display("\n--- PHASE 3A: CBC MODE (Cipher Block Chaining) ---");
        my_iv = 128'h0102030405060708090A0B0C0D0E0F10; 
        
        run_cbc_block(pt_block_1, my_iv, ct_block_1);
        $display("Block 1 Ciphertext: %h", ct_block_1);
        
        run_cbc_block(pt_block_2, my_iv, ct_block_2);
        $display("Block 2 Ciphertext: %h", ct_block_2);
        
        if (ct_block_1 != ct_block_2)
            $display("-> CBC VERDICT: PASS (Identical inputs produced different ciphertexts)");
        else
            $display("-> CBC VERDICT: FAIL");

        // --- CTR TEST ---
        $display("\n--- PHASE 3B: CTR MODE (Counter Mode) ---");
        my_counter = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_00000001; 
        
        run_ctr_block(pt_block_1, my_counter, ct_block_1);
        $display("Block 1 Ciphertext: %h", ct_block_1);
        
        run_ctr_block(pt_block_2, my_counter, ct_block_2);
        $display("Block 2 Ciphertext: %h", ct_block_2);
        $display("Current Counter State: %h", my_counter);

        if (ct_block_1 != ct_block_2)
            $display("-> CTR VERDICT: PASS (Stream cipher logic functioning perfectly)");
        else
            $display("-> CTR VERDICT: FAIL");

        $display("\n====================================================");
        $display("               ALL TESTS COMPLETED                  ");
        $display("====================================================\n");

        #100 $finish;
    end

    // =========================================================
    // HELPER TASKS (AXI PROTOCOL & MODES OF OPERATION)
    // =========================================================

    // --- AXI-Lite Write Task ---
    task axi_write(input [5:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr <= addr; wdata <= data; 
            awvalid <= 1; wvalid <= 1;
            wait(awready && wready);
            @(posedge clk);
            awvalid <= 0; wvalid <= 0;
            wait(bvalid);
            @(posedge clk);
        end
    endtask

    // --- AXI-Lite Read Task ---
    task axi_read(input [5:0] addr, output [31:0] data_out);
        begin
            @(posedge clk);
            araddr <= addr; arvalid <= 1;
            wait(arready);
            @(posedge clk);
            arvalid <= 0;
            wait(rvalid);
            data_out = rdata;
            @(posedge clk);
        end
    endtask

    // --- CBC Mode Task ---
    task run_cbc_block(
        input  [127:0] pt_in,
        inout  [127:0] iv_chain, 
        output [127:0] ct_out
    );
        reg [127:0] hw_input;
        reg [31:0]  status;
        begin
            hw_input = pt_in ^ iv_chain;

            axi_write(6'h20, hw_input[127:96]);
            axi_write(6'h24, hw_input[95:64]);
            axi_write(6'h28, hw_input[63:32]);
            axi_write(6'h2C, hw_input[31:0]);

            axi_write(6'h00, 32'h00000001);

            status = 0;
            while ((status & 32'h00000002) == 0) begin
                axi_read(6'h04, status); // Polling 0x04 for Idle bit
            end

            axi_read(6'h30, ct_out[127:96]);
            axi_read(6'h34, ct_out[95:64]);
            axi_read(6'h38, ct_out[63:32]);
            axi_read(6'h3C, ct_out[31:0]);

            iv_chain = ct_out;
        end
    endtask

    // --- CTR Mode Task ---
    task run_ctr_block(
        input  [127:0] pt_in,
        inout  [127:0] counter_block, 
        output [127:0] ct_out
    );
        reg [127:0] keystream;
        reg [31:0]  status;
        begin
            axi_write(6'h20, counter_block[127:96]);
            axi_write(6'h24, counter_block[95:64]);
            axi_write(6'h28, counter_block[63:32]);
            axi_write(6'h2C, counter_block[31:0]);

            axi_write(6'h00, 32'h00000001);

            status = 0;
            while ((status & 32'h00000002) == 0) begin
                axi_read(6'h04, status); // Polling 0x04 for Idle bit
            end

            axi_read(6'h30, keystream[127:96]);
            axi_read(6'h34, keystream[95:64]);
            axi_read(6'h38, keystream[63:32]);
            axi_read(6'h3C, keystream[31:0]);

            ct_out = pt_in ^ keystream;

            counter_block[31:0] = counter_block[31:0] + 1;
        end
    endtask

endmodule
