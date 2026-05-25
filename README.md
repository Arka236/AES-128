

# 🚀 High-Speed AES-128 Hardware Accelerator on Zynq-7000 SoC

![Verilog](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)
![Standard](https://img.shields.io/badge/Standard-FIPS--197_Compliant-success.svg)

## 📌 Project Overview
This project implements a fully unrolled, 10-stage pipelined **AES-128 Cryptographic Accelerator** mapped to the Xilinx Zynq-7000 Programmable Logic (PL). To facilitate high-speed data transfer, the hardware core is wrapped in a custom **AXI4-Lite Slave Memory interface**, allowing the ARM Cortex-A9 Processing System (PS) to securely offload cryptographic workloads.

By leveraging a hardware/software co-design architecture, the system achieves massive throughput for standard ECB encryption in silicon, while utilizing the ARM processor (or testbench automation) to dynamically execute advanced stream cipher modes (CBC and CTR) without breaking the hardware pipeline.

## ⚡ Performance Metrics & Synthesis Results
The mathematical core was heavily optimized for single-cycle resolution per round (including Galois Field matrix multiplication for MixColumns), yielding exceptional static timing results.

* **Target Clock:** 10.0 ns (100 MHz)
* **Achieved WNS (Worst Negative Slack):** +5.8 ns
* **Maximum Operating Frequency ($F_{max}$):** 238 MHz
* **Pipeline Latency:** 11 Clock Cycles
* **Peak Internal Throughput:** **30.4 Gbps** *(Processing one 128-bit block per clock cycle once the pipeline is saturated)*

## 🧠 System Architecture

### 1. The Hardware Core (Programmable Logic)
* **Unrolled Pipeline:** Abandoned traditional iterative state machines in favor of 10 physically cascaded round blocks. 
* **Custom Memory-Mapped Registers (MMR):** Designed a 64-byte dual-ported AXI4-Lite memory map to decouple the ARM processor's 32-bit bus limit from the engine's 128-bit internal datapath.
* **Hardware Lockout Mechanism:** Implemented a strict Busy/Idle state machine. The AXI write channels for the Key and Plaintext registers are physically locked out at the silicon level while the `Busy` flag is high, preventing data corruption during execution.

### 2. The Software Driver (Processing System)
* **Bare-Metal C / RTL Control:** The AXI Master uses direct memory access (`Xil_Out32` / `Xil_In32`) to write the FIPS Key, load the Plaintext, and trigger the hardware.
* **Modes of Operation:** * **ECB (Electronic Codebook):** Natively executed in hardware for baseline verification.
  * **CBC (Cipher Block Chaining):** Software-driven XOR chaining utilizing the hardware as a coprocessor.
  * **CTR (Counter Mode):** Stream cipher implementation where the hardware encrypts a Nonce+Counter, completely masking data patterns while retaining high parallel throughput.

## 🗄️ Custom AXI4-Lite Register Map

| Offset | Register Name | Access | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | **Control** | W | Bit 0: Start Engine (Auto-clearing pulse) |
| `0x04` | **Status** | R | Bit 0: Busy, Bit 1: Idle, Bit 3: Done |
| `0x10 - 0x1C` | **Key [0:3]** | W | 128-bit Master AES Key |
| `0x20 - 0x2C` | **Plaintext [0:3]**| W | 128-bit Data Input (Locked when Busy) |
| `0x30 - 0x3C` | **Ciphertext [0:3]**| R | 128-bit Encrypted Output |

## 🧪 Verification & Security Testing
The hardware was rigorously tested against **FIPS-197 Standard Vectors**. 

Furthermore, the design's cryptographic diffusion was verified by triggering the **Avalanche Effect**. Modifying a single bit of the input plaintext results in a complete scrambling of the 128-bit ciphertext by Round 3, proving the mathematical integrity of the SubBytes (S-Box) and MixColumns stages. All Advanced Modes (CBC/CTR) were verified via a custom automated Verilog testbench suite.

## 🛠️ Tools Used
* **EDA Tool:** Xilinx Vivado 2018.3 (Synthesis, Implementation, Simulation)
* **Software IDE:** Xilinx SDK / Vitis (Bare-metal C driver development)
* **Target Hardware:** ZedBoard Zynq-7000 ARM/FPGA SoC Evaluation Board

## 🚀 How to Run the Project
1. Clone this repository.
2. Open Vivado and source the provided `.tcl` script to rebuild the Block Design.
3. Run the `tb_aes_axi_lite.v` behavioral simulation to view the FIPS-197 ECB, CBC, and CTR verification in the TCL console.
4. To deploy to hardware, generate the Bitstream, export the hardware to Xilinx SDK, and compile `helloworld.c` to execute the system on the ZedBoard ARM core.

---

## 1. The Problem Statement
In modern integrated sensing and communication systems, data security is mandatory. However, executing complex cryptographic algorithms like AES-128 purely in software on a general-purpose processor (like the ARM Cortex-A9) is highly inefficient. 

Software execution requires thousands of clock cycles to encrypt a single 16-byte block of data. This creates a massive data bottleneck, consumes excessive CPU overhead, and drains power. The problem is how to secure high-speed data streams without crippling the main processor's performance.

## 2. The Project Aim
The objective of this project was to offload the heavy mathematical workload of encryption from the processor into custom silicon. 

Specifically, the aim was to design, verify, and implement a **FIPS-197 compliant AES-128 hardware accelerator** from scratch using Verilog HDL. This custom IP core had to be successfully integrated into the Xilinx Zynq-7000 SoC architecture using a strict **AXI4-Lite Slave Memory interface**, allowing the ARM processor to easily write data, trigger the hardware, and read back the secured ciphertext.

---

## 3. The Verilog Modules (System Architecture)
Your design is modular and hierarchical. Here is exactly what every file in your project does, from the lowest mathematical functions to the highest system wrapper.

### A. The Cryptographic Primitives (The Math)
These modules are the foundational building blocks of the AES algorithm.
* **`sbox.v` (SubBytes):** This is a non-linear substitution step. It acts as a massive Look-Up Table (LUT). It takes an 8-bit input and replaces it with a specific 8-bit output based on Galois Field inverse mathematics. This module is responsible for the "confusion" in the cipher.
* **`shift_rows.v`:** This module performs a simple hardware routing trick. It shifts the bytes in the 4x4 data matrix by different offsets. Because it only requires rewiring (no actual logic gates), it executes in zero clock cycles.
* **`mix_columns_32bit.v`:** This is the most mathematically heavy module. It takes a 32-bit column of data and multiplies it against a fixed matrix in a Galois Field ($GF(2^8)$). This provides the "diffusion" (the Avalanche Effect), ensuring a 1-bit change in the input cascades across the entire block.
* **`key_expand_stage.v`:** AES-128 requires 11 different 128-bit keys (one for each round). This module takes the previous round's key and performs XOR and S-Box substitutions to generate the unique key for the next round on the fly.

### B. The Pipeline Architecture (The Engine)
These modules assemble the primitive math blocks into a functioning engine.
* **`aes_round.v`:** This module represents one standard AES round. It instantiates the SubBytes, ShiftRows, MixColumns, and AddRoundKey logic in sequence.
* **`aes_round_last.v`:** The AES standard dictates that the final round (Round 10) must *skip* the MixColumns step. This module is identical to `aes_round.v` but lacks the MixColumns instantiation to ensure strict FIPS compliance.
* **`aes_pipeline.v`:** This is the core engine. Instead of using a state machine to loop through one round ten times, this module **physically unrolls the loop**. It instantiates 9 standard rounds and 1 final round, wiring them together in a massive 10-stage pipeline. 

### C. The SoC Integration (The Wrapper)
* **`aes_axi_wrapper.v`:** This is the bridge between the ARM processor and your Verilog pipeline. It acts as an AXI4-Lite Slave Memory map. 
    * It provides specific memory addresses for the processor to write the Key (`0x10`) and Plaintext (`0x20`). 
    * It contains a hardware lockout mechanism (Status Register at `0x04`) that physically prevents the processor from corrupting the input data while the engine is busy.
    * It manages the 11-cycle latency state machine, capturing the ciphertext and raising a `Done` flag when finished.

### D. The Verification Suite
* **`tb_aes_axi_lite.v`:** The final testbench. Because you used AXI4-Lite, this testbench acts as a simulated ARM processor. It writes the FIPS-197 standard vectors into the memory map via AXI transactions. Furthermore, it contains custom Verilog tasks to emulate advanced streaming modes like **CBC (Cipher Block Chaining)** and **CTR (Counter Mode)**, proving the hardware can support advanced security protocols.

---

## 4. The Results & Achievements
The project was a complete success, yielding the following verified metrics:

* **Strict Standard Compliance:** The behavioral simulation perfectly matched the expected ciphertext of the official NIST FIPS-197 standard test vectors.
* **Timing Closure:** During synthesis targeting a 10.0 ns clock, the design achieved a Worst Negative Slack (WNS) of **+5.8 ns**, resulting in a maximum safe operating frequency ($F_{max}$) of **238 MHz**.
* **Massive Throughput:** Because the 10-stage pipeline is fully unrolled, it outputs a completed 128-bit block every single clock cycle once saturated. At 238 MHz, the core achieves a theoretical peak internal throughput of **30.4 Gbps**.
* **Architectural Success:** The hardware was successfully mapped to a custom Memory-Mapped Register (MMR) architecture, flawlessly complying with the AXI4-Lite interface specifications provided in the design rubric.
