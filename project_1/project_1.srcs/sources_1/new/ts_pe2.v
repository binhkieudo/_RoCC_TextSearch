`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2024 04:57:03 PM
// Design Name: 
// Module Name: ts_pe2
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


module ts_pe2#(
    parameter NCORES        = 4096,
    parameter CHAR_LEN      = 2,
    parameter SEED_BUF      = 16
)(
    input                   clk,
    input                   rst,
    input                   istart,
    // Seed input
    input [CHAR_LEN-1:0]    iseed,
    input                   iseed_valid,
    input                   iseed_last,
    output                  oseed_ready,
    // Ref input
    input [NCORES*CHAR_LEN-1:0] iref,
    input                       iref_valid,
    // Output
    output [NCORES-1:0]     oscore,
    output                  ovalid,
    output                  oready
);

    reg [NCORES-1:0] fscore;
    wire [NCORES-1:0] tscore;    
    
 // =========== MATCHING ============================
    localparam S_IDLE = 0, 
        S_FIRST = 1, 
        S_MATCH = 2, 
        S_FINAL = 3;
    
    reg [1:0] state, nstate;
    
    always @(posedge clk)
        if (rst) state <= S_IDLE;
        else state <= nstate;
        
    always @(*) begin
        nstate = S_IDLE;
        case (state)
            S_IDLE: begin
                if (istart) nstate = S_FIRST;
                else nstate = state;
            end
            S_FIRST: nstate = S_MATCH;
            S_MATCH: begin
                if (iseed_last) nstate = S_FINAL;
                else nstate = state;
            end
            S_FINAL: nstate = S_IDLE;
            default: nstate = S_IDLE;
        endcase
    end

    genvar i;
    generate
        for (i = 0; i < NCORES; i = i + 1) begin: gen_loop
            assign tscore[i] = (iseed == iref[(i+1)*CHAR_LEN-1 -: CHAR_LEN]);
            
            always @(posedge clk) begin
                if (state == S_FIRST) fscore[i] <= tscore[i];
                else if (state == S_MATCH) begin
                    if (i == 0) begin
                        fscore[i] <= 1'b0;
                    end
                    else begin
                        if (iseed_valid && iref_valid) fscore[i] <= tscore[i] && fscore[i-1];
                        else fscore[i] <= fscore[i];
                    end
                end
                else fscore[i] <= fscore[i];
            end
        end
    endgenerate

    assign oseed_ready = (state == S_FIRST) || (state == S_MATCH);
    
    assign oscore = fscore;
    assign ovalid = state == S_FINAL;
    assign oready = (state == S_IDLE) || ovalid;
endmodule
