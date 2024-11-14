`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2024 10:01:17 PM
// Design Name: 
// Module Name: matmul64
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


module matmul64 #(
    parameter NROW = 8,
    parameter NCOL = 8,
    parameter SIZEIN = 8, 
    parameter SIZEOUT = 24
)(
    input clk,
    input reset,
    input iactive,
    input [63:0]  ia,
    input [63:0]  ib,
    input [7:0]   en, load, preload,
    output [SIZEOUT-1:0] odata0,
    output [SIZEOUT-1:0] odata1,
    output [SIZEOUT-1:0] odata2,
    output [SIZEOUT-1:0] odata3,
    output [SIZEOUT-1:0] odata4,
    output [SIZEOUT-1:0] odata5,
    output [SIZEOUT-1:0] odata6,
    output [SIZEOUT-1:0] odata7
);
    
    wire [SIZEOUT-1:0]  accum_out [NROW*NCOL-1:0];
    wire [SIZEIN-1:0]   b_out [NROW*NCOL-1:0];
    
    reg [NROW-1:0]     load_reg;
    reg [NROW-1:0]     preload_reg;
    reg [NROW-1:0]     en_reg;
    reg [3:0] count;
     
    localparam S_IDLE = 0, S_LOAD = 1, S_RUN = 2, S_FIN = 3;
    
    reg [1:0] state, nstate;
    
    always @(posedge clk) begin
        if (reset) state <= S_IDLE;
        else state <= nstate;
    end
    
    always @(*) begin
        nstate = S_IDLE;
        case (state)
            S_IDLE: nstate = iactive? S_LOAD: S_IDLE;
            S_LOAD: nstate = count[3]? S_RUN: S_LOAD;
            S_RUN:  nstate = ~count[3]? S_FIN: S_RUN;
            default: nstate = S_IDLE;
        endcase
    end
    
    always @(posedge clk) begin
        if (state == S_IDLE) begin
            preload_reg <= 8'd0000_0000;
            load_reg <= {7'd0, iactive};
        end
        else if (state == S_LOAD) begin
            preload_reg <= {preload_reg[7:1], 1'b1};
            load_reg <= {load_reg[7:1], 1'b0};
        end
        else begin
            preload_reg <= 8'd0000_0000;
            load_reg <= 8'd0000_0000;
        end
        
        if ((state == S_LOAD) || (state == S_RUN)) count <= count + 1'b1;
        else count <= 4'd0;
        
        en_reg <= preload_reg;
    end
    
    genvar row, col;
    generate
        for (row = 0; row < NROW; row = row + 1) begin: gen_row
            for (col = 0; col < NCOL; col = col + 1) begin: gen_col
                wire [SIZEOUT-1:0] accum_in;
                wire [SIZEIN-1:0]  b_in;
                
                if (col == 0) 
                    assign accum_in = 'b0;
                else 
                    assign accum_in = accum_out[row*NCOL + col - 1];
                
                if (row == NROW-1) 
                    assign b_in = b_out[col];
                else 
                    assign b_in = b_out[(row+1)*NCOL + col];
            
                mac #(SIZEIN, SIZEOUT) mac_unit (
                    .clk        (clk                            ),
                    .en         (en[col]                        ),
                    .load       (load[col]                      ),
                    .preload    (preload[col]                   ),
                    .a          (ia[(row+1)*SIZEIN-1 -: SIZEIN] ),
                    .b          (ib[(row+1)*SIZEIN-1 -: SIZEIN] ),
                    .b_in       (b_in                           ),
                    .b_out      (b_out[row*NCOL + col]          ),
                    .accum_in   (accum_in                       ),
                    .accum_out  (accum_out[row*NCOL + col]      )
                );  
            end
            

            
          
        end
    endgenerate
    
    assign odata0 = accum_out[7];
    assign odata1 = accum_out[15];
    assign odata2 = accum_out[23];
    assign odata3 = accum_out[31];
    assign odata4 = accum_out[39];
    assign odata5 = accum_out[47];
    assign odata6 = accum_out[55];
    assign odata7 = accum_out[63];
    
endmodule
