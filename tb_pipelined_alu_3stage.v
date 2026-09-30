`timescale 1ns/1ps

// ============================================================
// Testbench for the complete 16-bit 3-stage pipelined ALU
// ============================================================
module tb_pipelined_alu_3stage;

    reg clk;
    reg reset;
    reg instr_valid;
    reg [15:0] instr_in;

    wire        wb_valid;
    wire [2:0]  wb_rd;
    wire [15:0] wb_result;
    wire        wb_Z;
    wire        wb_C;
    wire        wb_V;
    wire        wb_N;

    // --------------------------------------------------------
    // Instantiate complete processor
    // --------------------------------------------------------
    pipelined_alu_3stage DUT (
        .clk(clk),
        .reset(reset),
        .instr_valid(instr_valid),
        .instr_in(instr_in),

        .wb_valid(wb_valid),
        .wb_rd(wb_rd),
        .wb_result(wb_result),
        .wb_Z(wb_Z),
        .wb_C(wb_C),
        .wb_V(wb_V),
        .wb_N(wb_N)
    );

    // --------------------------------------------------------
    // 10 ns clock
    // --------------------------------------------------------
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Instruction encoder
    // --------------------------------------------------------
    function [15:0] make_instr;
        input [3:0] op;
        input [2:0] rs1;
        input [2:0] rs2;
        input [2:0] rd;

        begin
            make_instr = {op,rs1,rs2,rd,3'b000};
        end
    endfunction

    // --------------------------------------------------------
    // Send one instruction.
    // Instruction is changed on falling edge so it is stable
    // before the next rising edge.
    // --------------------------------------------------------
    task send_instr;
        input [15:0] instruction;

        begin
            @(negedge clk);
            instr_valid = 1'b1;
            instr_in    = instruction;
        end
    endtask

    // --------------------------------------------------------
    // Main test
    // --------------------------------------------------------
    initial begin

        clk         = 1'b0;
        reset       = 1'b1;
        instr_valid = 1'b0;
        instr_in    = 16'b0;

        // Reset for two clock cycles
        repeat (2) @(posedge clk);
        reset = 1'b0;

        // ====================================================
        // TEST 1
        // ADD R1 = R2 + R3
        // R2 = 10, R3 = 20
        // Expected R1 = 30
        // ====================================================
        send_instr(make_instr(4'b0000,3'd2,3'd3,3'd1));

        // ====================================================
        // TEST 2
        // SUB R4 = R1 - R2
        // Expected R4 = 30 - 10 = 20
        //
        // This is intentionally back-to-back with ADD.
        // The design must use forwarding from EX/WB.
        // ====================================================
        send_instr(make_instr(4'b0001,3'd1,3'd2,3'd4));

        // ====================================================
        // TEST 3
        // AND R5 = R1 & R3
        // 30 & 20 = 20
        // ====================================================
        send_instr(make_instr(4'b0010,3'd1,3'd3,3'd5));

        // ====================================================
        // TEST 4
        // OR R6 = R1 | R2
        // 30 | 10 = 30
        // ====================================================
        send_instr(make_instr(4'b0011,3'd1,3'd2,3'd6));

        // ====================================================
        // TEST 5
        // XOR R7 = R1 ^ R2
        // 30 ^ 10 = 20
        // ====================================================
        send_instr(make_instr(4'b0100,3'd1,3'd2,3'd7));

        // Stop sending instructions
        @(negedge clk);
        instr_valid = 1'b0;
        instr_in    = 16'b0;

        // Allow pipeline to drain
        repeat (5) @(posedge clk);

        // Display final register-file contents
        $display("");
        $display("========================================");
        $display("FINAL REGISTER RESULTS");
        $display("========================================");

        $display("R1 = %d  (Expected 30)", DUT.registers[1]);
        $display("R4 = %d  (Expected 20)", DUT.registers[4]);
        $display("R5 = %d  (Expected 20)", DUT.registers[5]);
        $display("R6 = %d  (Expected 30)", DUT.registers[6]);
        $display("R7 = %d  (Expected 20)", DUT.registers[7]);

        if ((DUT.registers[1] == 16'd30) &&
            (DUT.registers[4] == 16'd20) &&
            (DUT.registers[5] == 16'd20) &&
            (DUT.registers[6] == 16'd30) &&
            (DUT.registers[7] == 16'd20))
            $display("PASS: Complete 3-stage pipeline verified.");
        else
            $display("FAIL: Check pipeline or forwarding logic.");

        $finish;
    end

    // --------------------------------------------------------
    // Monitor every valid Writeback
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (wb_valid) begin
            $display("WB: time=%0t  Rd=R%0d  Result=%0d  Z=%b C=%b V=%b N=%b",
                     $time, wb_rd, wb_result,
                     wb_Z, wb_C, wb_V, wb_N);
        end
    end

    // --------------------------------------------------------
    // Waveform generation for EPWave
    // --------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0,tb_pipelined_alu_3stage);
    end

endmodule