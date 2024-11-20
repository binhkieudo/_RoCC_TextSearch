`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2024 01:01:14 AM
// Design Name: 
// Module Name: tb
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


module tb(

    );
    
        // System
        reg clk = 1'b0;
        reg reset = 1'b0;
        // Input data
        reg [63:0] iA;
        reg        iA_valid = 1'b0;
        reg [63:0] iB;
        reg        iB_valid = 1'b0;
        reg [1:0]  iDest = 2'b01;
        // Output data
        wire [31:0] oResult0;
        wire [31:0] oResult1;
        wire [31:0] oResult2;
        wire [31:0] oResult3;
        wire [31:0] oResult4;
        wire [31:0] oResult5;
        wire [31:0] oResult6;
        wire [31:0] oResult7;
        
        vector_unit udt (.*);
        
        always #5 clk = ~clk;
        
        initial begin
            #5 @(posedge clk);
            #5 reset = 1'b1;
            #10 reset = 1'b0;
            #10;
            iA = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
            iB = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
            iA_valid = 1'b1;
            iB_valid = 1'b1;
            #80;
            iDest = 2'b10;
            iA = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
            iB = {8'd16, 8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9}; 
            #80;
            iDest = 2'b01;
            iA = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
            iB = {8'd16, 8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9};          
            #70;
            iA_valid = 1'b0;
            iB_valid = 1'b0;                        
            #90;
            #100 $stop;
        end
        
endmodule
