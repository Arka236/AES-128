`timescale 1ns / 1ps

module tb_aes_system();

    // System Signals
    reg clk;
    reg resetn;

    // AXI-Lite Write Channels
    reg  [5:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    // AXI-Lite Read Channels
    reg  [5:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    // Instantiate the Device Under Test (DUT)
    aes_axi_wrapper dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (resetn),
        .S_AXI_AWADDR  (awaddr),  .S_AXI_AWVALID (awvalid), .S_AXI_AWREADY (awready),
        .S_AXI_WDATA   (wdata),   .S_AXI_WSTRB   (4'hF),    .S_AXI_WVALID  (wvalid),  .S_AXI_WREADY  (wready),
        .S_AXI_BRESP   (bresp),   .S_AXI_BVALID  (bvalid),  .S_AXI_BREADY  (bready),
        .S_AXI_ARADDR  (araddr),  .S_AXI_ARVALID (arvalid), .S_AXI_ARREADY (arready),
        .S_AXI_RDATA   (rdata),   .S_AXI_RRESP   (rresp),   .S_AXI_RVALID  (rvalid),  .S_AXI_RREADY  (rready)
    );

    // Clock Generation (100 MHz)
    always #5 clk = ~clk;

    // Variables for capturing read data
    reg [31:0] read_val;
    reg [127:0] final_ciphertext;

    // Official FIPS-197 Test Vectors
    // Key: 2b7e1516_28aed2a6_abf71588_09cf4f3c
    // Plaintext: 3243f6a8_885a308d_313198a2_e0370734
    // Expected Ciphertext: 3925841d_02dc09fb_dc118597_196a0b32

    initial begin
        // 1. Initialize System
        clk = 0;
        resetn = 0;
        awaddr = 0; awvalid = 0; wdata = 0; wvalid = 0; bready = 1; // Always ready for write response
        araddr = 0; arvalid = 0; rready = 1;                        // Always ready for read data
        
        #20 resetn = 1; // Release Reset
        #20;

        $display("--- STARTING AES AXI SIMULATION ---");

// 2. Write the 128-bit Key (Standard FIPS)
        $display("Writing Key...");
        axi_write(6'h10, 32'h2b7e1516); // Key Word 0
        axi_write(6'h14, 32'h28aed2a6); // Key Word 1
        axi_write(6'h18, 32'habf71588); // Key Word 2
        axi_write(6'h1C, 32'h09cf4f3c); // Key Word 3

        // 3. Write the 128-bit Plaintext (Standard FIPS)
        $display("Writing Plaintext...");
        axi_write(6'h20, 32'h3243f6a8); // PT Word 0
        axi_write(6'h24, 32'h885a308d); // PT Word 1
        axi_write(6'h28, 32'h313198a2); // PT Word 2
        axi_write(6'h2C, 32'he0370734); // PT Word 3

        // 4. Start the Engine
        $display("Sending Start Command...");
        axi_write(6'h00, 32'h00000001); // Write 1 to Control Register

        // 5. Poll the Status Register until "Done" bit is high
        $display("Polling Status Register for Done flag...");
        read_val = 0;
        while ((read_val & 32'h00000008) == 0) begin // Check bit 3 (Done)
            axi_read(6'h04, read_val);
            #10; // Wait a clock cycle before checking again
        end
        $display("DONE FLAG DETECTED! Engine took 11 cycles.");

        // 6. Read back the Ciphertext
        $display("Reading Ciphertext...");
        axi_read(6'h30, read_val); final_ciphertext[127:96] = read_val;
        axi_read(6'h34, read_val); final_ciphertext[95:64]  = read_val;
        axi_read(6'h38, read_val); final_ciphertext[63:32]  = read_val;
        axi_read(6'h3C, read_val); final_ciphertext[31:0]   = read_val;

        // 7. Verify against Standard
        $display("-------------------------------------------------");
        $display("Expected: 3925841d02dc09fbdc118597196a0b32");
        $display("Actual  : %h", final_ciphertext);
        if (final_ciphertext == 128'h3925841d02dc09fbdc118597196a0b32)
            $display("RESULT: SUCCESS! Pipeline is mathematically perfect.");
        else
            $display("RESULT: FAILED. Check wiring.");
        $display("-------------------------------------------------");

        #50 $finish; // End simulation
    end

// ---------------------------------------------------------
    // AXI-Lite Master Read/Write Tasks
    // ---------------------------------------------------------
    
    task axi_write;
        input [5:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk);
            #1; // <--- Added delay to fix race condition
            awaddr  = addr;
            wdata   = data;
            awvalid = 1;
            wvalid  = 1;
            
            // Wait for slave to accept address and data
            wait(awready && wready);
            
            @(posedge clk);
            #1; // <--- Added delay to fix race condition
            awvalid = 0;
            wvalid  = 0;
            
            // Wait for response OKAY
            wait(bvalid);
            @(posedge clk);
        end
    endtask

    task axi_read;
        input  [5:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            #1; // <--- Added delay to fix race condition
            araddr  = addr;
            arvalid = 1;
            
            // Wait for slave to accept address
            wait(arready);
            
            @(posedge clk);
            #1; // <--- Added delay to fix race condition
            arvalid = 0;
            
            // Wait for slave to provide data
            wait(rvalid);
            #1;
            data = rdata;
            @(posedge clk);
        end
    endtask

endmodule