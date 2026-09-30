`timescale 1ns/1ps

// ============================================================
// 16-bit 3-Stage Pipelined ALU
// Stage 1 : DECODE
// Stage 2 : EXECUTE
// Stage 3 : WRITEBACK
//
// Instruction format:
// [15:12] = opcode
// [11:9]  = rs1
// [8:6]   = rs2
// [5:3]   = rd
// [2:0]   = reserved
// ============================================================

module pipelined_alu_3stage (
    input        clk,
    input        reset,

    // Instruction interface
    input        instr_valid,
    input [15:0] instr_in,

    // Observation of writeback
    output reg        wb_valid,
    output reg [2:0]  wb_rd,
    output reg [15:0] wb_result,
    output reg        wb_Z,
    output reg        wb_C,
    output reg        wb_V,
    output reg        wb_N
);

    // -----------------------------
    // Opcode definitions
    // -----------------------------
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_NOT = 4'b0101;
    localparam OP_SHL = 4'b0110;
    localparam OP_SHR = 4'b0111;
    localparam OP_CMP = 4'b1000;
    localparam OP_NOP = 4'b1111;

    // -----------------------------
    // Register file: 8 registers x 16 bits
    // -----------------------------
    reg [15:0] registers [0:7];

    // -----------------------------
    // Stage 1 -> Stage 2 (ID/EX)
    // -----------------------------
    reg        idex_valid;
    reg [3:0]  idex_opcode;
    reg [2:0]  idex_rd;
    reg [15:0] idex_A;
    reg [15:0] idex_B;

    // -----------------------------
    // Stage 2 -> Stage 3 (EX/WB)
    // -----------------------------
    reg        exwb_valid;
    reg [2:0]  exwb_rd;
    reg [15:0] exwb_result;
    reg        exwb_Z;
    reg        exwb_C;
    reg        exwb_V;
    reg        exwb_N;

    // -----------------------------
    // Fields decoded from input instruction
    // -----------------------------
    wire [3:0] instr_opcode = instr_in[15:12];
    wire [2:0] instr_rs1    = instr_in[11:9];
    wire [2:0] instr_rs2    = instr_in[8:6];
    wire [2:0] instr_rd     = instr_in[5:3];

    // -----------------------------
    // Register-file read values
    // -----------------------------
    wire [15:0] rs1_value = registers[instr_rs1];
    wire [15:0] rs2_value = registers[instr_rs2];

    // -----------------------------
    // Simple forwarding for RAW hazards
    // If the previous instruction is in EX/WB,
    // use its result instead of the old register value.
    // -----------------------------
    // Forward from the instruction currently in Execute first.
    // This removes the one-cycle RAW hazard for back-to-back instructions.
    wire [15:0] decode_A =
        (idex_valid && (idex_rd == instr_rs1))
        ? alu_result :
        ((exwb_valid && (exwb_rd == instr_rs1))
        ? exwb_result : rs1_value);

    // Apply the same forwarding rule to source operand B.
    wire [15:0] decode_B =
        (idex_valid && (idex_rd == instr_rs2))
        ? alu_result :
        ((exwb_valid && (exwb_rd == instr_rs2))
        ? exwb_result : rs2_value);

    // -----------------------------
    // Stage 2 ALU signals
    // -----------------------------
    reg [15:0] alu_result;
    reg        alu_Z;
    reg        alu_C;
    reg        alu_V;
    reg        alu_N;
    reg [16:0] alu_temp;

    // -----------------------------
    // Stage 2: Execute
    // -----------------------------
    always @(*) begin
        alu_result = 16'b0;
        alu_Z      = 1'b0;
        alu_C      = 1'b0;
        alu_V      = 1'b0;
        alu_N      = 1'b0;
        alu_temp   = 17'b0;

        case (idex_opcode)

            OP_ADD: begin
                alu_temp   = {1'b0,idex_A} + {1'b0,idex_B};
                alu_result = alu_temp[15:0];
                alu_C      = alu_temp[16];
                alu_V      = (~(idex_A[15] ^ idex_B[15])) &
                             (alu_result[15] ^ idex_A[15]);
            end

            OP_SUB: begin
                alu_result = idex_A - idex_B;
                alu_C      = (idex_A >= idex_B);
                alu_V      = (idex_A[15] ^ idex_B[15]) &
                             (alu_result[15] ^ idex_A[15]);
            end

            OP_AND: begin
                alu_result = idex_A & idex_B;
            end

            OP_OR: begin
                alu_result = idex_A | idex_B;
            end

            OP_XOR: begin
                alu_result = idex_A ^ idex_B;
            end

            OP_NOT: begin
                alu_result = ~idex_A;
            end

            OP_SHL: begin
                alu_result = idex_A << 1;
                alu_C      = idex_A[15];
            end

            OP_SHR: begin
                alu_result = idex_A >> 1;
                alu_C      = idex_A[0];
            end

            OP_CMP: begin
                alu_result = idex_A - idex_B;
                alu_C      = (idex_A >= idex_B);
                alu_V      = (idex_A[15] ^ idex_B[15]) &
                             (alu_result[15] ^ idex_A[15]);
            end

            default: begin
                alu_result = 16'b0;
            end

        endcase

        alu_Z = (alu_result == 16'b0);
        alu_N = alu_result[15];
    end

    // ========================================================
    // Pipeline registers
    // ========================================================
    always @(posedge clk) begin

        if (reset) begin

            // Clear Stage 1 -> Stage 2 registers
            idex_valid  <= 1'b0;
            idex_opcode <= OP_NOP;
            idex_rd     <= 3'b0;
            idex_A      <= 16'b0;
            idex_B      <= 16'b0;

            // Clear Stage 2 -> Stage 3 registers
            exwb_valid  <= 1'b0;
            exwb_rd     <= 3'b0;
            exwb_result <= 16'b0;
            exwb_Z      <= 1'b0;
            exwb_C      <= 1'b0;
            exwb_V      <= 1'b0;
            exwb_N      <= 1'b0;

            // Clear Writeback outputs
            wb_valid  <= 1'b0;
            wb_rd     <= 3'b0;
            wb_result <= 16'b0;
            wb_Z      <= 1'b0;
            wb_C      <= 1'b0;
            wb_V      <= 1'b0;
            wb_N      <= 1'b0;

            // Initial values for demonstration
            registers[0] <= 16'd0;
            registers[1] <= 16'd0;
            registers[2] <= 16'd10;
            registers[3] <= 16'd20;
            registers[4] <= 16'd0;
            registers[5] <= 16'd0;
            registers[6] <= 16'd0;
            registers[7] <= 16'd0;

        end else begin

            // =================================================
            // STAGE 3: WRITEBACK
            // Commit the previous Execute result to register file
            // =================================================
            wb_valid  <= exwb_valid;
            wb_rd     <= exwb_rd;
            wb_result <= exwb_result;
            wb_Z      <= exwb_Z;
            wb_C      <= exwb_C;
            wb_V      <= exwb_V;
            wb_N      <= exwb_N;

            if (exwb_valid && (exwb_rd != 3'b000))
                registers[exwb_rd] <= exwb_result;

            // =================================================
            // STAGE 2: EXECUTE -> EX/WB
            // =================================================
            exwb_valid  <= idex_valid;
            exwb_rd     <= idex_rd;
            exwb_result <= alu_result;
            exwb_Z      <= alu_Z;
            exwb_C      <= alu_C;
            exwb_V      <= alu_V;
            exwb_N      <= alu_N;

            // =================================================
            // STAGE 1: DECODE -> ID/EX
            // =================================================
            idex_valid  <= instr_valid;
            idex_opcode <= instr_opcode;
            idex_rd     <= instr_rd;
            idex_A      <= decode_A;
            idex_B      <= decode_B;

        end
    end

endmodule
