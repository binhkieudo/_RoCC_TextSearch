`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2024 03:17:09 PM
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
    
    parameter NCORES = 32;
    parameter CHAR_LEN = 2;
    parameter SEED_BUF = 16;
    
    reg                         clk = 0;
    reg                         rst;
    reg                         istart = 'b0;
    // Seed
    reg [CHAR_LEN-1:0]          iseed = 'd0;
    reg                         iseed_valid = 'b0;
    reg                         iseed_last = 'b0;
    wire                        oseed_ready;
    // Reference
    reg [NCORES*CHAR_LEN-1:0]   iref = 'b0;
    reg                         iref_valid = 'b0;
    // Output
    
    wire [NCORES-1:0]           oscore;
    wire                        ovalid;
    wire                        oready;
    
    ts_pe2 udt(.*);
    
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk);
        #10 rst = 1;
        #20 rst = 0;
        #10 iref = {
                2'b10, 2'b01, 2'b11, 2'b11, // Matched
                2'b00, 2'b01, 2'b10, 2'b11,           
                2'b10, 2'b01, 2'b11, 2'b11, // Matched
                2'b00, 2'b01, 2'b10, 2'b11,
                2'b10, 2'b01, 2'b11, 2'b11, // Matched
                2'b00, 2'b01, 2'b10, 2'b11,
                2'b10, 2'b01, 2'b11, 2'b11, // Matched
                2'b00, 2'b01, 2'b10, 2'b11
        };
        iref_valid = 1'b1;
        iseed = 2'b11;
        iseed_valid = 1'b1;
        istart = 'b1;
        #10 istart = 1'b0;
        #10 iseed = 2'b11;
        #10 iseed = 2'b01;
        #10 iseed = 2'b10;
        iseed_last = 1'b1;
        #10 iseed_valid = 1'b0;
        iseed_last = 1'b0;
        #100;
    end
    
    
endmodule
