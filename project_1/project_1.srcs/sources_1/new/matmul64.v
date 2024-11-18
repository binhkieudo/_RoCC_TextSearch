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
    input [63:0]  ia,
    input         iavalid,
    input [63:0]  ib,
    input         ibvalid,
    input  [1:0]  ifunct,
    input         iwritedest,
    output [SIZEOUT-1:0] odata0,
    output [SIZEOUT-1:0] odata1,
    output [SIZEOUT-1:0] odata2,
    output [SIZEOUT-1:0] odata3,
    output [SIZEOUT-1:0] odata4,
    output [SIZEOUT-1:0] odata5,
    output [SIZEOUT-1:0] odata6,
    output [SIZEOUT-1:0] odata7,
    output               ovalid
);
    
    localparam MAT_MUL      = 0,
               MAT_ADD      = 1,
               MAT_SUB      = 2,
               POINT_MUL    = 3,
               POINT_MAC    = 4,
               WRITE_BACK   = 5;
    
    localparam VEC_0 = 0,
               VEC_1 = 1;
               
    wire [SIZEOUT-1:0]  accum_out [NROW*NCOL-1:0];
    wire [SIZEIN-1:0]   b_out [NROW*NCOL-1:0];
    
    reg [NROW-1:0]     load_reg = 8'd0;
    reg [NROW-1:0]     preload_reg = 8'd0;
    reg [NROW-1:0]     en_reg = 8'd0;
    
    reg [63:0]  a_reg;
    reg [63:0]  b_reg;
 
    reg [3:0] count;
     
    reg rvalid;
    
    reg [SIZEOUT-1:0] vec0_0 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_1 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_2 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_3 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_4 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_5 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_6 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec0_7 [NCOL-1:0];

    reg [SIZEOUT-1:0] vec1_0 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_1 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_2 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_3 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_4 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_5 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_6 [NCOL-1:0];
    reg [SIZEOUT-1:0] vec1_7 [NCOL-1:0];
        
    localparam S_IDLE = 0, S_LOAD = 1, S_RUN = 2, S_WAIT = 3;
    
    reg [1:0] state = S_IDLE, nstate = S_IDLE;
    
    always @(posedge clk) begin
        if (reset) state <= S_IDLE;
        else state <= nstate;
    end
    
    always @(*) begin
        nstate = S_IDLE;
        case (state)
            S_IDLE: nstate = (iavalid && ibvalid)? S_LOAD: S_IDLE;
            S_LOAD: nstate = &count[2:0]? S_RUN: S_LOAD;
            S_RUN:  nstate = &count[2:0]? S_WAIT: S_RUN;
            S_WAIT: nstate = S_IDLE;
            default: nstate = S_IDLE;
        endcase
    end
    
    always @(posedge clk) begin
        if (reset) begin
            preload_reg <= 8'd0;
            load_reg <= 8'd0;
            en_reg   <= 8'd0;
            count    <= 4'd0;
            a_reg    <= 64'd0;
            b_reg    <= 64'd0;
            rvalid   <= 1'b0;
        end
        else begin
            a_reg <= ibvalid? ia: a_reg;
            b_reg <= ibvalid? ib: b_reg;
                        
            if (state == S_IDLE) begin
                rvalid <= 1'b0;
                preload_reg <= 8'd0;
                load_reg <= {7'd0, iavalid && ibvalid};
                en_reg   <= 8'd0;
            end
            else if ((state == S_LOAD) || (state == S_RUN)) begin
                rvalid <= 1'b0;
                en_reg      <= {en_reg[6:0], 1'b1};
                load_reg    <= {load_reg[6:0], 1'b0};
                preload_reg <= {preload_reg[6:0], 1'b1};
                rvalid <= ((state == S_RUN) && count[0])? 1'b1: rvalid;  
            end
            else begin
                en_reg      <= 8'd0;
                load_reg    <= 8'd0;
                preload_reg <= 8'd0;
            end
            
            if ((state == S_LOAD) || (state == S_RUN)) begin
                count <= count + 1'b1;
            end
            else count <= 4'd0;
        end
    end
        
    genvar row, col;
    generate
        for (row = 0; row < NROW; row = row + 1) begin: gen_row
            for (col = 0; col < NCOL; col = col + 1) begin: gen_col
                wire [SIZEOUT-1:0] accum_in;
                wire [SIZEIN-1:0]  b_in;
                
                wire [SIZEIN-1:0]  a_win;
                wire [SIZEIN-1:0]  b_win;
                
                if (ifunct == MAT_ADD) begin
                    if (row == 0) assign accum_in = vec_0[col];
                    else if (row == 1) assign accum_in = vec_1[col];
                    else if (row == 2) assign accum_in = vec_2[col];
                    else if (row == 3) assign accum_in = vec_3[col];
                    else if (row == 4) assign accum_in = vec_4[col];
                    else if (row == 5) assign accum_in = vec_5[col];
                    else if (row == 6) assign accum_in = vec_6[col];
                    else assign accum_in = vec_7[col];
                end
                else begin    
                    if (col == 0) 
                        assign accum_in = 'b0;
                    else
                        assign accum_in = accum_out[row*NCOL + col - 1];
                end
                
                
                if (row == NROW-1) 
                    assign b_in = b_out[col];
                else 
                    assign b_in = b_out[(row+1)*NCOL + col];
                
                mac #(SIZEIN, SIZEOUT) mac_unit (
                    .clk        (clk                                ),
                    .en         (en_reg[col]                       ),
                    .load       (load_reg[col]                     ),
                    .preload    (preload_reg[col]                  ),
                    .a          (a_reg[(row+1)*SIZEIN-1 -: SIZEIN]  ),
                    .b          (b_reg[(row+1)*SIZEIN-1 -: SIZEIN]  ),
                    .b_in       (b_in                               ),
                    .b_out      (b_out[row*NCOL + col]              ),
                    .mult_in    ( ),
                    .accum_in   (accum_in                           ),
                    .accum_out  (accum_out[row*NCOL + col]          )
                );  
            end
        end
    endgenerate
    
    always @(posedge clk) begin
        if (ifunct == MAT_MUL) begin
            if (rvalid) begin
                if (iwritedest == VEC_0) begin
                    vec0_0[0] <= vec0_0[1];
                    vec0_0[1] <= vec0_0[2];
                    vec0_0[2] <= vec0_0[3];
                    vec0_0[3] <= vec0_0[4];
                    vec0_0[4] <= vec0_0[5];
                    vec0_0[5] <= vec0_0[6];
                    vec0_0[6] <= vec0_0[7];
                    vec0_0[7] <= accum_out[7];
                    
                    vec0_1[0] <= accum_out[15];
                    vec0_1[1] <= vec0_1[2];
                    vec0_1[2] <= vec0_1[3];
                    vec0_1[3] <= vec0_1[4];
                    vec0_1[4] <= vec0_1[5];
                    vec0_1[5] <= vec0_1[6];
                    vec0_1[6] <= vec0_1[7];
                    vec0_1[7] <= vec0_1[0];                
    
                    vec0_2[0] <= vec0_2[1];
                    vec0_2[1] <= accum_out[23];
                    vec0_2[2] <= vec0_2[3];
                    vec0_2[3] <= vec0_2[4];
                    vec0_2[4] <= vec0_2[5];
                    vec0_2[5] <= vec0_2[6];
                    vec0_2[6] <= vec0_2[7];
                    vec0_2[7] <= vec0_2[0];
                    
                    vec0_3[0] <= vec0_3[1];
                    vec0_3[1] <= vec0_3[2];
                    vec0_3[2] <= accum_out[31];
                    vec0_3[3] <= vec0_3[4];
                    vec0_3[4] <= vec0_3[5];
                    vec0_3[5] <= vec0_3[6];
                    vec0_3[6] <= vec0_3[7];
                    vec0_3[7] <= vec0_3[0];
                    
                    vec0_4[0] <= vec0_4[1];
                    vec0_4[1] <= vec0_4[2];
                    vec0_4[2] <= vec0_4[3];
                    vec0_4[3] <= accum_out[39];
                    vec0_4[4] <= vec0_4[5];
                    vec0_4[5] <= vec0_4[6];
                    vec0_4[6] <= vec0_4[7];
                    vec0_4[7] <= vec0_4[0];
                    
                    vec0_5[0] <= vec0_5[1];
                    vec0_5[1] <= vec0_5[2];
                    vec0_5[2] <= vec0_5[3];
                    vec0_5[3] <= vec0_5[4];
                    vec0_5[4] <= accum_out[47];
                    vec0_5[5] <= vec0_5[6];
                    vec0_5[6] <= vec0_5[7];
                    vec0_5[7] <= vec0_5[0];
                    
                    vec0_6[0] <= vec0_6[1];
                    vec0_6[1] <= vec0_6[2];
                    vec0_6[2] <= vec0_6[3];
                    vec0_6[3] <= vec0_6[4];
                    vec0_6[4] <= vec0_6[5];
                    vec0_6[5] <= accum_out[55];
                    vec0_6[6] <= vec0_6[7];
                    vec0_6[7] <= vec0_6[0];
                    
                    vec0_7[0] <= vec0_7[1];
                    vec0_7[1] <= vec0_7[2];
                    vec0_7[2] <= vec0_7[3];
                    vec0_7[3] <= vec0_7[4];
                    vec0_7[4] <= vec0_7[5];
                    vec0_7[5] <= vec0_7[6];
                    vec0_7[6] <= accum_out[63];
                    vec0_7[7] <= vec0_7[0];   
                end
                else begin
                    vec1_0[0] <= vec1_0[1];
                    vec1_0[1] <= vec1_0[2];
                    vec1_0[2] <= vec1_0[3];
                    vec1_0[3] <= vec1_0[4];
                    vec1_0[4] <= vec1_0[5];
                    vec1_0[5] <= vec1_0[6];
                    vec1_0[6] <= vec1_0[7];
                    vec1_0[7] <= accum_out[7];
                    
                    vec1_1[0] <= accum_out[15];
                    vec1_1[1] <= vec1_1[2];
                    vec1_1[2] <= vec1_1[3];
                    vec1_1[3] <= vec1_1[4];
                    vec1_1[4] <= vec1_1[5];
                    vec1_1[5] <= vec1_1[6];
                    vec1_1[6] <= vec1_1[7];
                    vec1_1[7] <= vec1_1[0];                
    
                    vec1_2[0] <= vec1_2[1];
                    vec1_2[1] <= accum_out[23];
                    vec1_2[2] <= vec1_2[3];
                    vec1_2[3] <= vec1_2[4];
                    vec1_2[4] <= vec1_2[5];
                    vec1_2[5] <= vec1_2[6];
                    vec1_2[6] <= vec1_2[7];
                    vec1_2[7] <= vec1_2[0];
                    
                    vec1_3[0] <= vec1_3[1];
                    vec1_3[1] <= vec1_3[2];
                    vec1_3[2] <= accum_out[31];
                    vec1_3[3] <= vec1_3[4];
                    vec1_3[4] <= vec1_3[5];
                    vec1_3[5] <= vec1_3[6];
                    vec1_3[6] <= vec1_3[7];
                    vec1_3[7] <= vec1_3[0];
                    
                    vec1_4[0] <= vec1_4[1];
                    vec1_4[1] <= vec1_4[2];
                    vec1_4[2] <= vec1_4[3];
                    vec1_4[3] <= accum_out[39];
                    vec1_4[4] <= vec1_4[5];
                    vec1_4[5] <= vec1_4[6];
                    vec1_4[6] <= vec1_4[7];
                    vec1_4[7] <= vec1_4[0];
                    
                    vec1_5[0] <= vec1_5[1];
                    vec1_5[1] <= vec1_5[2];
                    vec1_5[2] <= vec1_5[3];
                    vec1_5[3] <= vec1_5[4];
                    vec1_5[4] <= accum_out[47];
                    vec1_5[5] <= vec1_5[6];
                    vec1_5[6] <= vec1_5[7];
                    vec1_5[7] <= vec1_5[0];
                    
                    vec1_6[0] <= vec1_6[1];
                    vec1_6[1] <= vec1_6[2];
                    vec1_6[2] <= vec1_6[3];
                    vec1_6[3] <= vec1_6[4];
                    vec1_6[4] <= vec1_6[5];
                    vec1_6[5] <= accum_out[55];
                    vec1_6[6] <= vec1_6[7];
                    vec1_6[7] <= vec1_6[0];
                    
                    vec1_7[0] <= vec1_7[1];
                    vec1_7[1] <= vec1_7[2];
                    vec1_7[2] <= vec1_7[3];
                    vec1_7[3] <= vec1_7[4];
                    vec1_7[4] <= vec1_7[5];
                    vec1_7[5] <= vec1_7[6];
                    vec1_7[6] <= accum_out[63];
                    vec1_7[7] <= vec1_7[0];
                end                                                           
            end
        end
    end
    
    assign odata0 = accum_out[7];
    assign odata1 = accum_out[15];
    assign odata2 = accum_out[23];
    assign odata3 = accum_out[31];
    assign odata4 = accum_out[39];
    assign odata5 = accum_out[47];
    assign odata6 = accum_out[55];
    assign odata7 = accum_out[63];
    assign ovalid = rvalid;
endmodule
