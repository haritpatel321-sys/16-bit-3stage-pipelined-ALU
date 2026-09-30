# 16-bit 3-Stage Pipelined ALU

A Verilog HDL implementation of a **16-bit, 3-stage pipelined ALU datapath** developed as an academic RTL/processor-design project.

## Project status

| Stage | Function | Status |
|---|---|---|
| Stage 1 | Decode + register-file operand read | Implemented |
| Stage 2 | 16-bit ALU Execute + flags | Implemented |
| Stage 3 | Writeback to register file | Implemented |
| Hazard handling | Basic RAW forwarding | Implemented |
| Verification | Self-checking Verilog testbench + VCD | Implemented |
| Report | IEEE-style report | Included |
| Presentation | Stage-wise presentation | Included |

## Architecture

```text
             16-bit instruction
                    |
                    v
          +--------------------+
          | Stage 1: DECODE    |
          | opcode, rs1, rs2   |
          | rd, operand A/B     |
          +---------+----------+
                    |
                  ID/EX
                    |
                    v
          +--------------------+
          | Stage 2: EXECUTE   |
          | 16-bit ALU         |
          | ADD/SUB/AND/OR     |
          | XOR/NOT/SHL/SHR    |
          | CMP + Z/C/V/N      |
          +---------+----------+
                    |
                  EX/WB
                    |
                    v
          +--------------------+
          | Stage 3: WRITEBACK |
          | result -> register  |
          +--------------------+
```

The datapath uses an **8 × 16-bit register file**.

## Instruction format

```text
15            12 11       9 8        6 5       3 2       0
+---------------+-----------+----------+---------+---------+
|    opcode     |    rs1    |   rs2    |   rd    | reserved|
+---------------+-----------+----------+---------+---------+
```

## Supported operations

| Opcode | Operation |
|---|---|
| `0000` | ADD |
| `0001` | SUB |
| `0010` | AND |
| `0011` | OR |
| `0100` | XOR |
| `0101` | NOT |
| `0110` | SHL |
| `0111` | SHR |
| `1000` | CMP |
| `1111` | NOP/default |

The ALU generates:
- `Z`: Zero
- `C`: Carry / shift-out
- `V`: Signed overflow
- `N`: Negative/sign bit

## RAW forwarding

A dependent instruction such as:

```text
ADD R1,R2,R3
SUB R4,R1,R2
```

can use the recently generated `R1` result through forwarding instead of waiting for the normal register-file writeback.

## Verification sequence

The supplied testbench initializes:

```text
R2 = 10
R3 = 20
```

and executes:

```text
ADD R1,R2,R3
SUB R4,R1,R2
AND R5,R1,R3
OR  R6,R1,R2
XOR R7,R1,R2
```

Expected final values:

```text
R1 = 30
R4 = 20
R5 = 20
R6 = 30
R7 = 20
```

The testbench prints a PASS/FAIL message and generates `dump.vcd` for waveform viewing.

## Run with Icarus Verilog

Install Icarus Verilog, then from the repository root:

```bash
iverilog -o sim rtl/pipelined_alu_3stage.v tb/tb_pipelined_alu_3stage.v
vvp sim
```

You should see writeback messages followed by:

```text
PASS: Complete 3-stage pipeline verified.
```

To view the waveform, open `dump.vcd` in GTKWave.

## Run in EDA Playground

1. Put `rtl/pipelined_alu_3stage.v` in the Design window.
2. Put `tb/tb_pipelined_alu_3stage.v` in the Testbench window.
3. Select **Icarus Verilog 12.0**.
4. Set the top module to:
   `tb_pipelined_alu_3stage`
5. Enable EPWave / VCD waveform output.
6. Click **Run**.

## Results

For the five-instruction demonstration, the pipeline schedule completes in 7 cycles after overlap, while a simple non-overlapped 3-cycle-per-instruction baseline requires 15 cycles.

```text
Analytical cycle-count ratio = 15 / 7 = 2.14x
```

This is an **analytical cycle-count comparison for the demonstration sequence**, not a measured FPGA speedup. FPGA frequency, area and power should only be reported after synthesis/implementation.

## Repository contents

```text
16-bit-3stage-pipelined-ALU/
├── README.md
├── .gitignore
├── LICENSE
├── rtl/
│   └── pipelined_alu_3stage.v
├── tb/
│   └── tb_pipelined_alu_3stage.v
├── docs/
│   ├── Complete_Project_Guide.pdf
│   ├── Presentation.pptx
│   └── Stagewise_Progress.pdf
├── report/
│   └── IEEE_Report.pdf
├── figures/
│   ├── fig1_architecture.png
│   ├── fig2_pipeline_timing.png
│   ├── fig3_functional_results.png
│   └── fig4_cycle_count.png
└── papers/
    └── paper_list.md
```

## Future work

1. Add a proper instruction memory and program counter.
2. Add complete hazard detection and stall/flush logic.
3. Extend forwarding for all required pipeline dependencies.
4. Add branch/control-flow support if the project is extended to a processor.
5. Synthesize on an FPGA and report maximum clock frequency, resource utilization and power.
6. Compare the pipelined design with a non-pipelined RTL baseline using measured synthesis results.

## Author

**Harit Patel**  
Electronics & Communication Engineering
