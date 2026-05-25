# 🚀 High-Speed AES-128 Cryptographic IP Core (AXI4-Lite)

![RTL Design](https://img.shields.io/badge/Design-Verilog_HDL-blue.svg)
![Verification](https://img.shields.io/badge/Verification-Automated_Testbench-purple.svg)
![Interface](https://img.shields.io/badge/Interface-AXI4--Lite-orange.svg)
![Standard](https://img.shields.io/badge/Standard-FIPS--197_Compliant-success.svg)

## 📌 Project Overview
This project implements a fully unrolled, 10-stage pipelined **AES-128 Cryptographic IP Core** designed entirely in Verilog HDL. To ensure seamless integration into modern System-on-Chip (SoC) architectures, the cryptographic engine is wrapped in a custom, dual-ported **AXI4-Lite Slave Memory interface**.

By leveraging a pure hardware architecture, the system achieves massive mathematical throughput for standard ECB encryption in silicon. The accompanying automated Verilog AXI-Master testbench acts as the system controller, dynamically executing advanced stream cipher modes (CBC and CTR) by driving the AXI interface, proving the IP's versatility without altering the underlying FIPS-compliant pipeline.

## ⚡ Synthesis Metrics & The I/O Bottleneck
The mathematical core was heavily optimized for single-cycle resolution per round (including Galois Field matrix multiplication for MixColumns), yielding exceptional static timing results during synthesis targeting a generic 100 MHz clock. However, system-level architecture dictates a clear distinction between internal processing power and interface limitations:

* **Target Clock:** 10.0 ns (100 MHz)
* **Achieved WNS (Worst Negative Slack):** +5.8 ns
* **Maximum Operating Frequency (Fmax):** 238 MHz
* **Pipeline Latency:** 11 Clock Cycles

### Throughput Analysis
* **Peak Internal Engine Throughput: 30.4 Gbps** *(Calculated via the 128-bit internal hardware datapath processing one block per clock cycle at 238 MHz internal saturation).*
* **Theoretical Interface Throughput: 7.6 Gbps** *(Calculated via the 32-bit AXI4-Lite external bus limit: 32 bits × 238 MHz).*
* **Real-World System Bottleneck:** Because AXI4-Lite requires a multi-cycle handshaking protocol for every 32-bit read/write transaction, the true system-level throughput is heavily bound by the AXI Master's transmission speed. The cryptographic engine is vastly faster than its I/O interface, a classic SoC architectural constraint.

## 🧠 System Architecture

### 1. The RTL IP Core (Datapath & Control)
* **Unrolled Pipeline:** Abandoned traditional iterative state machines in favor of 10 physically cascaded round blocks to maximize raw silicon speed and allow continuous data streaming. 
* **Custom Memory-Mapped Registers (MMR):** Designed a 64-byte AXI4-Lite memory map to decouple the external 32-bit SoC bus limit from the engine's 128-bit internal datapath.
* **Hardware Lockout Mechanism:** Implemented a strict Busy/Idle state machine. The AXI write channels for the Key and Plaintext registers are physically locked out at the RTL level while the `Busy` flag is high, preventing data corruption during execution.

### 2. Design Verification (AXI Master Testbench)
* **Automated RTL Control:** A custom Verilog testbench simulates a generic SoC AXI Master, utilizing specific read/write tasks to program the FIPS Key, load the Plaintext, and trigger the hardware engine via the memory map.
* **Modes of Operation Verification:** * **ECB (Electronic Codebook):** Natively executed in hardware for baseline FIPS verification.
  * **CBC (Cipher Block Chaining):** Testbench-driven XOR chaining utilizing the RTL core as a coprocessor.
  * **CTR (Counter Mode):** Stream cipher implementation where the testbench encrypts a Nonce+Counter, completely masking data patterns while retaining high parallel throughput.

## 🗄️ Custom AXI4-Lite Register Map

| Offset | Register Name | Access | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | **Control** | W | Bit 0: Start Engine (Auto-clearing pulse) |
| `0x04` | **Status** | R | Bit 0: Busy, Bit 1: Idle, Bit 3: Done |
| `0x10 - 0x1C` | **Key [0:3]** | W | 128-bit Master AES Key |
| `0x20 - 0x2C` | **Plaintext [0:3]**| W | 128-bit Data Input (Locked when Busy) |
| `0x30 - 0x3C` | **Ciphertext [0:3]**| R | 128-bit Encrypted Output |

## 🧪 Security Testing & Verification
The hardware was rigorously tested against **FIPS-197 Standard Vectors**. 

Furthermore, the design's cryptographic diffusion was visually verified by triggering the **Avalanche Effect** in simulation. Modifying a single bit of the input plaintext results in a complete scrambling of the 128-bit ciphertext by Round 3, proving the mathematical integrity of the SubBytes (S-Box) and MixColumns stages. All Advanced Modes (CBC/CTR) were exhaustively verified via the automated behavioral simulation suite.

## 🛠️ Tools Used
* **EDA Tool:** Xilinx Vivado 2018.3 (Synthesis & Behavioral Simulation)
* **Language:** Verilog-2001

## 🚀 How to Run the Behavioral Simulation
1. Clone this repository.
2. Open Xilinx Vivado and create a new RTL project.
3. Add the Verilog files to your project hierarchy.
4. Set `tb_aes_axi_lite.v` as the top module for simulation.
5. Launch the Behavioral Simulation.
6. In the TCL Console, observe the automated execution and verification of the FIPS-197 ECB baseline, followed by the CBC and CTR advanced mode tests. Expand the wave viewer to observe the AXI handshaking.

---

## 1. The Problem Statement
In modern integrated sensing and communication systems, data security is mandatory. However, executing complex cryptographic algorithms like AES-128 purely in software on a general-purpose processor is highly inefficient. 

Software execution requires thousands of clock cycles to encrypt a single 16-byte block of data. This creates a massive data bottleneck, consumes excessive CPU overhead, and drains power. The problem is how to secure high-speed data streams without crippling the main processor's performance.

## 2. The Project Aim
The objective of this project was to offload the heavy mathematical workload of encryption into a dedicated hardware IP block. 

Specifically, the aim was to design, verify, and implement a **FIPS-197 compliant AES-128 hardware accelerator** from scratch strictly using Verilog HDL. This custom IP core had to be easily integrated into modern SoC architectures using a strict **AXI4-Lite Slave Memory interface**, allowing an AXI Master to write data, trigger the hardware, and read back the secured ciphertext with minimal overhead.

---

## 3. The Verilog Modules (System Architecture)
The design is modular and hierarchical. Here is exactly what every file in the project does, from the lowest mathematical functions to the highest system wrapper.

### A. The Cryptographic Primitives (The Math)
These modules are the foundational building blocks of the AES algorithm.
* **`sbox.v` (SubBytes):** This is a non-linear substitution step. It acts as a massive Look-Up Table (LUT). It takes an 8-bit input and replaces it with a specific 8-bit output based on Galois Field inverse mathematics. This module is responsible for the "confusion" in the cipher.
* **`shift_rows.v`:** This module performs a simple hardware routing trick. It shifts the bytes in the 4x4 data matrix by different offsets. Because it only requires rewiring (no actual logic gates), it executes in zero clock cycles.
* **`mix_columns_32bit.v`:** This is the most mathematically heavy module. It takes a 32-bit column of data and multiplies it against a fixed matrix in a Galois Field (GF(2^8)). This provides the "diffusion" (the Avalanche Effect), ensuring a 1-bit change in the input cascades across the entire block.
* **`key_expand_stage.v`:** AES-128 requires 11 different 128-bit keys (one for each round). This module takes the previous round's key and performs XOR and S-Box substitutions to generate the unique key for the next round on the fly.

### B. The Pipeline Architecture (The Engine)
These modules assemble the primitive math blocks into a functioning engine.
* **`aes_round.v`:** This module represents one standard AES round. It instantiates the SubBytes, ShiftRows, MixColumns, and AddRoundKey logic in sequence.
* **`aes_round_last.v`:** The AES standard dictates that the final round (Round 10) must *skip* the MixColumns step. This module is identical to `aes_round.v` but lacks the MixColumns instantiation to ensure strict FIPS compliance.
* **`aes_pipeline.v`:** This is the core engine. Instead of using a state machine to loop through one round ten times, this module **physically unrolls the loop**. It instantiates 9 standard rounds and 1 final round, wiring them together in a massive 10-stage pipeline entirely in RTL. 

### C. The SoC Integration (The Wrapper)
* **`aes_axi_wrapper.v`:** This is the bridge between the AXI Master and the Verilog pipeline. It acts as an AXI4-Lite Slave Memory map. 
    * It provides specific memory addresses to write the Key (`0x10`) and Plaintext (`0x20`). 
    * It contains a hardware lockout mechanism (Status Register at `0x04`) that physically prevents the input data from being corrupted while the engine is busy.
    * It manages the 11-cycle latency state machine, capturing the ciphertext and raising a `Done` flag when finished.

### D. The Verification Suite
* **`tb_aes_axi_lite.v`:** The final verification testbench. Because the design uses AXI4-Lite, this testbench acts as a simulated AXI Master. It writes the FIPS-197 standard vectors into the memory map via AXI transactions. Furthermore, it contains custom Verilog tasks to emulate advanced streaming modes like **CBC (Cipher Block Chaining)** and **CTR (Counter Mode)**, proving the IP core can support advanced security protocols entirely within the simulation environment.

---

## 4. The Results & Achievements
The project was a complete success, yielding the following verified metrics:

* **Strict Standard Compliance:** The behavioral simulation perfectly matched the expected ciphertext of the official NIST FIPS-197 standard test vectors.
* **Timing Closure:** During synthesis targeting a 10.0 ns clock, the design achieved a Worst Negative Slack (WNS) of **+5.8 ns**, resulting in a maximum safe operating frequency (Fmax) of **238 MHz**.
* **Massive Throughput:** Because the 10-stage pipeline is fully unrolled, it outputs a completed 128-bit block every single clock cycle once saturated. At 238 MHz, the core achieves a theoretical peak internal throughput of **30.4 Gbps**, heavily optimizing the mathematical execution prior to external AXI routing.
* **Architectural Success:** The hardware was successfully mapped to a custom Memory-Mapped Register (MMR) architecture, flawlessly complying with the AXI4-Lite interface specifications.
