`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2024 01:08:12 AM
// Design Name: 
// Module Name: tb_mat
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


module tb_mat(

    );
    
    parameter NROW = 8;
    parameter NCOL = 8;
    parameter SIZEIN = 8; 
    parameter SIZEOUT = 24;
    
    reg clk = 1'b0;
    reg reset = 1'b0;
    reg iactive = 1'b0;
    reg [63:0]  ia = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
    reg [63:0]  ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
    reg [7:0]   en = 8'b0000_0000; 
    reg [7:0]   load = 8'b0000_0000; 
    reg [7:0]   preload = 8'b0000_0000;
    
    wire [SIZEOUT-1:0] odata0;
    wire [SIZEOUT-1:0] odata1;
    wire [SIZEOUT-1:0] odata2;
    wire [SIZEOUT-1:0] odata3;
    wire [SIZEOUT-1:0] odata4;
    wire [SIZEOUT-1:0] odata5;
    wire [SIZEOUT-1:0] odata6;
    wire [SIZEOUT-1:0] odata7;
    
    matmul64 udt(.*);
    
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk);
        reset = 1'b1;
        #10 reset = 1'b0;
        #10 load = 8'b0000_0001;
        #10 
        ia = (ia >> 8) | (8'd9 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        load = 8'b0000_0010;
        preload = 8'b0000_0001;
        en = 8'b0000_0001;
        #10 
        ia = (ia >> 8) | (8'd10 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        load = 8'b0000_0100;
        preload = 8'b0000_0011;
        en = 8'b0000_0011;
        #10 
        ia = (ia >> 8) | (8'd11 << 56);
        ib = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        load = 8'b0000_1000;
        preload = 8'b0000_0111;
        en = 8'b0000_0111;
        #10 
        ia = (ia >> 8) | (8'd12 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        load = 8'b0001_0000;
        preload = 8'b0000_1111;
        en = 8'b0000_1111;
        #10
        ia = (ia >> 8) | (8'd13 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        load = 8'b0010_0000;
        preload = 8'b0001_1111;
        en = 8'b0001_1111;
        #10 
        ia = (ia >> 8) | (8'd14 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2};
        load = 8'b0100_0000;
        preload = 8'b0011_1111;
        en = 8'b0011_1111; 
        #10
        ia = (ia >> 8) | (8'd15 << 56);
        ib = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2}; 
        load = 8'b1000_0000;
        preload = 8'b0111_1111;
        en = 8'b0111_1111;
//        #10 
//        load = 8'b0000_0000;
//        preload = 8'b1111_1111;
//        en = 8'b1111_1111; 
        // Second phase
        #10
        load = 8'b0000_0001;
        preload = 8'b1111_1110;
        en = 8'b1111_1111;
        ia = {8{8'd1}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};
        #10
        load = 8'b0000_0010;
        preload = 8'b1111_1101;
        en = 8'b1111_1111;
        ia = {8{8'd3}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};        
        #10
        load = 8'b0000_0100;
        preload = 8'b1111_1011;
        en = 8'b1111_1111;
        ia = {8{8'd5}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2}; 
        #10
        load = 8'b0000_1000;
        preload = 8'b1111_0111;
        en = 8'b1111_1111;
        ia = {8{8'd7}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2}; 
        #10
        load = 8'b0001_0000;
        preload = 8'b1110_1111;
        en = 8'b1111_1111;
        ia = {8{8'd9}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};
        #10
        load = 8'b0010_0000;
        preload = 8'b1101_1111;
        en = 8'b1111_1111;
        ia = {8{8'd11}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};
        #10
        load = 8'b0100_0000;
        preload = 8'b1011_1111;
        en = 8'b1111_1111;
        ia = {8{8'd13}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};
        #10
        load = 8'b1000_0000;
        preload = 8'b0111_1111;
        en = 8'b1111_1111;
        ia = {8{8'd15}};
        ib = {8'd16, 8'd14, 8'd12, 8'd10, 8'd8, 8'd6, 8'd4, 8'd2};
        #10
        load = 8'b0000_0000;
        preload = 8'b1111_1111;
        en = 8'b1111_1111;        
        #90
        preload = 8'b0000_0000;
        en = 8'b0000_0000;      
        #1000;
        $stop; 
    end
    
endmodule
