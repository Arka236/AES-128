`timescale 1ns / 1ps

module aes_axi_wrapper (
    // System Signals
    input wire aclk,
    input wire aresetn,

    // AXI4-Lite Slave Interface
    input  wire [5:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    input  wire [5:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // =========================================================
    // 1. EXPLICIT REGISTER MAP
    // =========================================================
    // 0x00: Control Register (Bit 0: Start, Bit 1: Stop)
    // 0x04: Status Register  (Bit 0: Busy, Bit 1: Idle, Bit 2: Error, Bit 3: Done)
    // 0x10 - 0x1C: Key Registers [127:0]
    // 0x20 - 0x2C: Plaintext Registers [127:0]
    // 0x30 - 0x3C: Ciphertext Registers [127:0]

    reg [31:0] control_reg;
    
    // Status Flags
    reg status_busy;
    reg status_idle;
    reg status_error;
    reg status_done; 
    
    // Data Storage
    reg [31:0] key_reg [0:3];
    reg [31:0] pt_reg  [0:3];
    reg [31:0] ct_reg  [0:3];

    // =========================================================
    // 2. AXI-LITE WRITE LOGIC (Testbench -> Hardware)
    // =========================================================
    reg aw_en;
    always @(posedge aclk) begin
        if (~aresetn) begin
            s_axi_awready <= 1'b0; s_axi_wready  <= 1'b0; 
            s_axi_bvalid  <= 1'b0; aw_en <= 1'b1;
            
            control_reg <= 0;
            key_reg[0] <= 0; key_reg[1] <= 0; key_reg[2] <= 0; key_reg[3] <= 0;
            pt_reg[0] <= 0;  pt_reg[1] <= 0;  pt_reg[2] <= 0;  pt_reg[3] <= 0;
        end else begin
            // Address Handshake
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1; aw_en <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_awready <= 1'b0; aw_en <= 1'b1;
            end else s_axi_awready <= 1'b0;
            
            // Data Handshake & Register Routing
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
                
                case (s_axi_awaddr)
                    6'h00: control_reg <= s_axi_wdata; // Write Control
                    
                    // Hardware Lockout: Only allow writing Key and PT if IDLE
                    6'h10: if (status_idle) key_reg[0] <= s_axi_wdata;
                    6'h14: if (status_idle) key_reg[1] <= s_axi_wdata;
                    6'h18: if (status_idle) key_reg[2] <= s_axi_wdata;
                    6'h1C: if (status_idle) key_reg[3] <= s_axi_wdata;
                    
                    6'h20: if (status_idle) pt_reg[0] <= s_axi_wdata;
                    6'h24: if (status_idle) pt_reg[1] <= s_axi_wdata;
                    6'h28: if (status_idle) pt_reg[2] <= s_axi_wdata;
                    6'h2C: if (status_idle) pt_reg[3] <= s_axi_wdata;
                    default: ; // Do nothing for invalid addresses
                endcase
            end else begin 
                s_axi_wready <= 1'b0;
                // Auto-clear the Start and Stop bits so they act like pulses
                control_reg[0] <= 1'b0; 
                control_reg[1] <= 1'b0;
            end
            
            // Write Response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1; s_axi_bresp <= 2'b00; // OKAY
            end else if (s_axi_bready && s_axi_bvalid) s_axi_bvalid <= 1'b0;
        end
    end

    // =========================================================
    // 3. AXI-LITE READ LOGIC (Hardware -> Testbench)
    // =========================================================
    always @(posedge aclk) begin
        if (~aresetn) begin
            s_axi_arready <= 1'b0; s_axi_rvalid <= 1'b0;
        end else begin
            // Read Address Handshake
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else s_axi_arready <= 1'b0;
            
            // Read Data Routing
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                
                case (s_axi_araddr)
                    6'h00: s_axi_rdata <= control_reg;
                    // Dynamically assemble the Status Register
                    6'h04: s_axi_rdata <= {28'd0, status_done, status_error, status_idle, status_busy};
                    
                    6'h10: s_axi_rdata <= key_reg[0];
                    6'h14: s_axi_rdata <= key_reg[1];
                    6'h18: s_axi_rdata <= key_reg[2];
                    6'h1C: s_axi_rdata <= key_reg[3];
                    
                    6'h20: s_axi_rdata <= pt_reg[0];
                    6'h24: s_axi_rdata <= pt_reg[1];
                    6'h28: s_axi_rdata <= pt_reg[2];
                    6'h2C: s_axi_rdata <= pt_reg[3];
                    
                    6'h30: s_axi_rdata <= ct_reg[0];
                    6'h34: s_axi_rdata <= ct_reg[1];
                    6'h38: s_axi_rdata <= ct_reg[2];
                    6'h3C: s_axi_rdata <= ct_reg[3];
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // =========================================================
    // 4. AES HARDWARE PIPELINE
    // =========================================================
    wire [127:0] internal_key = {key_reg[0], key_reg[1], key_reg[2], key_reg[3]};
    wire [127:0] internal_pt  = {pt_reg[0],  pt_reg[1],  pt_reg[2],  pt_reg[3]};
    wire [127:0] internal_ct;
    
    // Explicit Key Interface Signal
    wire key_valid = status_busy; 
    
    aes_pipeline my_aes_core (
        .clk        (aclk),
        .en         (status_busy), 
        .plaintext  (internal_pt),
        .key_0      (internal_key),
        .ciphertext (internal_ct)
    );

    // =========================================================
    // 5. STATUS STATE MACHINE 
    // =========================================================
    reg [3:0] cycle_counter;

    always @(posedge aclk) begin
        if (~aresetn) begin
            status_busy  <= 1'b0;
            status_idle  <= 1'b1;
            status_error <= 1'b0; 
            status_done  <= 1'b0;
            cycle_counter <= 0;
            
            ct_reg[0] <= 0; ct_reg[1] <= 0; ct_reg[2] <= 0; ct_reg[3] <= 0;
        end else begin
            // Default: Clear the 1-cycle Done pulse
            status_done <= 1'b0; 

            // Start Condition 
            if (control_reg[0] == 1'b1 && status_idle) begin
                status_busy <= 1'b1;
                status_idle <= 1'b0;
                cycle_counter <= 0;
            end 
            // Stop Condition 
            else if (control_reg[1] == 1'b1) begin
                status_busy <= 1'b0;
                status_idle <= 1'b1;
                cycle_counter <= 0;
            end
            
            // Processing Pipeline
            if (status_busy) begin
                if (cycle_counter == 11) begin
                    status_busy <= 1'b0; 
                    status_idle <= 1'b1;
                    status_done <= 1'b1; 
                    cycle_counter <= 0;
                    
                    // Latch ciphertext safely
                    ct_reg[0] <= internal_ct[127:96];
                    ct_reg[1] <= internal_ct[95:64];
                    ct_reg[2] <= internal_ct[63:32];
                    ct_reg[3] <= internal_ct[31:0];
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end
            end
        end
    end

endmodule
