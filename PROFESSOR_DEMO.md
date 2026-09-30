# Professor demonstration checklist

## 1. Start with architecture

Show:

Decode -> ID/EX -> Execute -> EX/WB -> Writeback

Explain that the goal is to overlap instruction stages.

## 2. Show Stage 1

Use:

```text
ADD R1,R2,R3
```

Explain:
- opcode is decoded
- rs1 and rs2 identify source registers
- rd identifies destination
- operands are placed into the ID/EX pipeline register

## 3. Show Stage 2

Explain that the ALU performs:
ADD, SUB, AND, OR, XOR, NOT, SHL, SHR and CMP.

Mention:
Z = zero, C = carry/shift-out, V = signed overflow, N = negative/sign bit.

## 4. Show Stage 3

Explain:

```text
EX/WB result -> destination register
```

## 5. Demonstrate RAW forwarding

Show:

```text
ADD R1,R2,R3
SUB R4,R1,R2
```

The second instruction needs R1 immediately. Explain that the current design forwards the recent ALU result to the decode operand path.

## 6. Show verification

Run the testbench and show:

```text
R1 = 30
R4 = 20
R5 = 20
R6 = 30
R7 = 20
PASS: Complete 3-stage pipeline verified.
```

Then open EPWave and point to clock, pipeline-valid signals and writeback result.

## 7. Be precise about performance

Say:

> "For the five-instruction demonstration, the analytical pipeline schedule uses seven cycles versus fifteen cycles for a simple non-overlapped three-cycle-per-instruction baseline. This gives a 2.14x cycle-count reduction for this sequence. It is not yet an FPGA speedup measurement."

## 8. Future work

- complete hazard/stall logic
- branch/flush support
- instruction memory and PC
- FPGA synthesis
- frequency/area/power measurements
- larger instruction set / processor integration
