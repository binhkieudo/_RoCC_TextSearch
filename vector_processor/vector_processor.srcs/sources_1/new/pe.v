`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 01:44:14 AM
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pe(
        input        clk,
        input        enable,
        // Control signal
        input        a_update,
        input        b_src,
        input        b_update,
        input [1:0]  alu_src,
        input [1:0]  v_src,
        input [1:0]  v_update,
        input [1:0]  opt,
        // Input data
        input [7:0]  A_in,
        input [7:0]  B_in,
        input [7:0]  B_forward,
        input [31:0] result_forward,
        input [31:0] v0_in,
        input [31:0] v1_in,
        // Output data
        output [7:0]  B_out,
        output [31:0] result_n0,
        output [31:0] result_out,
        output [31:0] v0_out,
        output [31:0] v1_out        
    );
    
    localparam OPT_ADD = 2'b00,
               OPT_SUB = 2'b01,
               OPT_MULADD = 2'b10,
               OPT_MULSUB = 2'b11;
               
    reg [7:0] A_reg;
    reg [7:0] B_reg;
    reg [31:0] T_reg;
    
    reg [31:0] V0, V1, V3;
    reg [31:0] ALU_reg;
    
    wire [31:0] ALU_result;
    wire [31:0] operand_0;
    wire [31:0] operand_1;
    
    assign operand_0 = alu_src[0]? V0: T_reg;
    assign operand_1 = alu_src[1]? V1: result_forward;
    
    assign ALU_result = opt[0]? operand_0 - operand_1: 
                                operand_0 + operand_1;
    
    always @(posedge clk) begin
        if (a_update) A_reg <= A_in;
        
        if (b_update) B_reg <= b_src? B_forward: B_in;
        
        if (opt[1]) T_reg <= A_reg * B_reg;
        
        if (v_update[0]) V0 <= v_src[0]? v0_in: ALU_result;
        
        if (v_update[1]) V1 <= v_src[1]? v1_in: ALU_result;
        
        ALU_reg <= enable? ALU_result: ALU_reg;
    end
    
    assign B_out = B_reg;
    assign result_n0  = ALU_result;
    assign result_out = ALU_reg;
    assign v0_out = V0;
    assign v1_out = V1;
    
endmodule
