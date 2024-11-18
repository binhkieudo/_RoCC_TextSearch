`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2024 12:43:05 AM
// Design Name: 
// Module Name: tb_mat_single
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


module tb_mat_single(

    );
    
    parameter NROW = 8;
    parameter NCOL = 8;
    parameter SIZEIN = 8; 
    parameter SIZEOUT = 24;
    
    reg clk = 1'b0;
    reg reset = 1'b0;
    reg [63:0]  ia = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
    reg         iavalid = 1'b0;
    reg [63:0]  ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
    reg         ibvalid = 1'b0;
    reg  [1:0]  ifunct = 2'b00;
    
    wire [SIZEOUT-1:0] odata0;
    wire [SIZEOUT-1:0] odata1;
    wire [SIZEOUT-1:0] odata2;
    wire [SIZEOUT-1:0] odata3;
    wire [SIZEOUT-1:0] odata4;
    wire [SIZEOUT-1:0] odata5;
    wire [SIZEOUT-1:0] odata6;
    wire [SIZEOUT-1:0] odata7;
    wire ovalid;
    
    matmul64 udt(.*);
    
    reg [SIZEOUT-1:0] mem0 [0:7];
    reg [SIZEOUT-1:0] mem1 [0:7];
    
    always @(posedge clk) begin
        if (ovalid) begin
            mem0[0] <= mem0[1];
            mem0[1] <= mem0[2];
            mem0[2] <= mem0[3];
            mem0[3] <= mem0[4];
            mem0[4] <= mem0[5];
            mem0[5] <= mem0[6];
            mem0[6] <= mem0[7];
            mem0[7] <= odata0;
            
            mem1[0] <= odata1;
            mem1[1] <= mem1[2];
            mem1[2] <= mem1[3];
            mem1[3] <= mem1[4];
            mem1[4] <= mem1[5];
            mem1[5] <= mem1[6];
            mem1[6] <= mem1[7];
            mem1[7] <= mem1[0];
        end
    end
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk);
        reset = 1'b1;
        #10 reset = 1'b0;
        #9 @(posedge clk);
        #5; 
        iavalid = 1'b1;
        ibvalid = 1'b1;
        #10 
        ia = (ia >> 8) | (8'd9 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
//        #10 
//        iavalid = 1'b0;
//        ibvalid = 1'b0;
//        ia = ia;
//        ib = {8{8'd0}};
        #10  
        iavalid = 1'b1;
        ibvalid = 1'b1;        
        ia = (ia >> 8) | (8'd10 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        #10  
        ia = (ia >> 8) | (8'd11 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        #10 
        ia = (ia >> 8) | (8'd12 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        #10            
        ia = (ia >> 8) | (8'd13 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        #10         
        ia = (ia >> 8) | (8'd14 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        #10 
        ia = (ia >> 8) | (8'd15 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        #10
        iavalid = 1'b0;
        ibvalid = 1'b0;                             
        #1000;
        $stop; 
    end
    
endmodule
