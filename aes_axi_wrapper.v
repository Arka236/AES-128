`timescale 1ns / 1ps

module aes_axi_wrapper (
    // System Signals
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [5:0]  S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]  S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [5:0]  S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,

    // AXI4-Lite Read Data Channel
    output reg  [31:0] S_AXI_RDATA,
    output reg  [1:0]  S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);

    // ------------------------------------------------------------------
    // 1. REGISTER DECLARATIONS (The Mailboxes)
    // ------------------------------------------------------------------
    reg [31:0] reg_ctrl;     // 0x00
    
    reg [31:0] reg_key_0;    // 0x10
    reg [31:0] reg_key_1;    // 0x14
    reg [31:0] reg_key_2;    // 0x18
    reg [31:0] reg_key_3;    // 0x1C
    
    reg [31:0] reg_pt_0;     // 0x20
    reg [31:0] reg_pt_1;     // 0x24
    reg [31:0] reg_pt_2;     // 0x28
    reg [31:0] reg_pt_3;     // 0x2C

    // ------------------------------------------------------------------
    // 2. AXI WRITE LOGIC (Processor writes to IP)
    // ------------------------------------------------------------------
    reg aw_en; // Write enable flag
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            aw_en         <= 1'b1;
            // Reset all registers
            reg_ctrl <= 0; reg_key_0 <= 0; reg_key_1 <= 0; reg_key_2 <= 0; reg_key_3 <= 0;
            reg_pt_0 <= 0; reg_pt_1 <= 0; reg_pt_2 <= 0; reg_pt_3 <= 0;
        end else begin
            // Handshake: Accept Address
            if (~S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                S_AXI_AWREADY <= 1'b1;
                aw_en         <= 1'b0;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_AWREADY <= 1'b0;
                aw_en         <= 1'b1;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end

            // Handshake: Accept Data and Route to exact Register
            if (~S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                S_AXI_WREADY <= 1'b1;
                // Address Decoding
                case (S_AXI_AWADDR[5:2])
                    4'h0: reg_ctrl  <= S_AXI_WDATA; // 0x00
                    4'h4: reg_key_0 <= S_AXI_WDATA; // 0x10
                    4'h5: reg_key_1 <= S_AXI_WDATA; // 0x14
                    4'h6: reg_key_2 <= S_AXI_WDATA; // 0x18
                    4'h7: reg_key_3 <= S_AXI_WDATA; // 0x1C
                    4'h8: reg_pt_0  <= S_AXI_WDATA; // 0x20
                    4'h9: reg_pt_1  <= S_AXI_WDATA; // 0x24
                    4'hA: reg_pt_2  <= S_AXI_WDATA; // 0x28
                    4'hB: reg_pt_3  <= S_AXI_WDATA; // 0x2C
                endcase
            end else begin
                S_AXI_WREADY <= 1'b0;
                // Auto-clear the start bit so it doesn't stay high forever
                if (reg_ctrl[0] == 1'b1) reg_ctrl[0] <= 1'b0; 
            end

            // Handshake: Send Write Response (OKAY)
            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00; // 'OKAY' response
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // 3. AES STATUS STATE MACHINE (11-Cycle Tracker)
    // ------------------------------------------------------------------
    reg [3:0] latency_counter;
    reg status_busy;
    reg status_idle;
    reg status_done;
    wire status_error = 1'b0; // Hardcoded to 0 for now
    
    wire start_pulse = reg_ctrl[0];

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            latency_counter <= 0;
            status_busy <= 0;
            status_idle <= 1;
            status_done <= 0;
        end else begin
            // Default state for done (asserted for only one cycle)
            status_done <= 1'b0;

            if (start_pulse && status_idle) begin
                // Turn engine ON
                status_idle <= 0;
                status_busy <= 1;
                latency_counter <= 1;
            end else if (status_busy) begin
                // Count the 11 pipeline stages
                if (latency_counter == 11) begin
                    status_busy <= 0;
                    status_done <= 1; // Asserted for one cycle [cite: 103]
                    status_idle <= 1;
                    latency_counter <= 0;
                end else begin
                    latency_counter <= latency_counter + 1;
                end
            end
        end
    end

    // Pack status flags into the 32-bit Status Register format
    wire [31:0] wire_status_reg = {28'h0, status_done, status_error, status_idle, status_busy};

    // ------------------------------------------------------------------
    // 4. INSTANTIATE THE 128-BIT AES PIPELINE
    // ------------------------------------------------------------------
    wire [127:0] packed_key = {reg_key_0, reg_key_1, reg_key_2, reg_key_3};
    wire [127:0] packed_pt  = {reg_pt_0, reg_pt_1, reg_pt_2, reg_pt_3};
    wire [127:0] packed_ct;

    aes_pipeline my_aes_core (
        .clk        (S_AXI_ACLK),
        .plaintext  (packed_pt),
        .key_0      (packed_key),
        .ciphertext (packed_ct)
    );

    // ------------------------------------------------------------------
    // 5. AXI READ LOGIC (Processor reads from IP)
    // ------------------------------------------------------------------
    reg [5:0] axi_araddr_reg;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
        end else begin
            // Handshake: Accept Read Address
            if (~S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY  <= 1'b1;
                axi_araddr_reg <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end

            // Handshake: Output Read Data
            if (S_AXI_ARREADY && S_AXI_ARVALID && ~S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00; // 'OKAY'
                // Address Decoding for Output
                case (axi_araddr_reg[5:2])
                    4'h1: S_AXI_RDATA <= wire_status_reg;      // 0x04 Status
                    4'hC: S_AXI_RDATA <= packed_ct[127:96];    // 0x30 CT Word 0
                    4'hD: S_AXI_RDATA <= packed_ct[95:64];     // 0x34 CT Word 1
                    4'hE: S_AXI_RDATA <= packed_ct[63:32];     // 0x38 CT Word 2
                    4'hF: S_AXI_RDATA <= packed_ct[31:0];      // 0x3C CT Word 3
                    default: S_AXI_RDATA <= 32'h0;
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule