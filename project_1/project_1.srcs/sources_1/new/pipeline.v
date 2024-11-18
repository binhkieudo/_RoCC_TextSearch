`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2024 01:20:30 AM
// Design Name: 
// Module Name: pipeline
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


module pipeline#(
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
    
    reg [NROW-1:0]     load_reg = 8'd0;
    reg [NROW-1:0]     preload_reg = 8'd0;
    reg [NROW-1:0]     en_reg = 8'd0;
    
    reg [63:0]  a_reg;
    reg [63:0]  b_reg;
    
    wire [NROW-1:0]     load_wire;
    wire [NROW-1:0]     preload_wire;
    wire [NROW-1:0]     en_wire;
    
    reg [3:0] count;
     
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
            S_LOAD: nstate = count[3]? S_RUN: S_LOAD;
            S_RUN:  begin
                if (count[2:0] == 3'b000) 
                    nstate = (iavalid || ibvalid)? S_RUN: S_WAIT;
                else 
                    nstate = S_RUN;
            end
            S_WAIT: nstate = (count[2:0] == 3'b000)? S_IDLE: S_WAIT;
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
        end
        else begin
            if (state == S_IDLE) begin
                preload_reg <= 8'd0;
                load_reg <= {7'd0, iavalid && ibvalid};
                en_reg   <= 8'd0;
                if (iavalid && ibvalid) begin
                    a_reg <= ibvalid? ia: a_reg;
                    b_reg <= ibvalid? ib: b_reg;
                end
            end
            else if (state == S_LOAD) begin
                en_reg      <= (iavalid && ibvalid)? {en_reg[6:0], 1'b1} : en_reg;
                load_reg    <= (iavalid && ibvalid)? {load_reg[6:0], load_reg[7]} : load_reg;
                preload_reg <= (iavalid && ibvalid)? {preload_reg[6:0], !(&count[2:0])} : preload_reg;  
                a_reg <= ibvalid? ia: a_reg;
                b_reg <= ibvalid? ib: b_reg;
            end
            else begin
                en_reg      <= (iavalid && ibvalid)? {en_reg[6:0], 1'b1} : en_reg;
                load_reg    <= (iavalid && ibvalid)? {load_reg[6:0], load_reg[7]} : load_reg;
                preload_reg <= (iavalid && ibvalid)? {preload_reg[6:0], preload_reg[7]} : preload_reg;
                a_reg <= ibvalid? ia: a_reg;
                b_reg <= ibvalid? ib: b_reg;
            end
            
            if ((state == S_LOAD) || (state == S_RUN) || (state == S_WAIT)) begin
                if (iavalid && ibvalid)
                    count <= count + 1;
                else begin
                    if (((state == S_RUN) || (state == S_LOAD)) && (&count[2:0]))
                        count <= count + 1;
                    else
                        count <= count;
                end
            end
            else count <= 4'd0;
        end
    end
      
    assign load_wire = load_reg & {8{iavalid && ibvalid && (state != S_IDLE)}};
    
    assign preload_wire = (state == S_LOAD)? preload_reg & {8{iavalid && ibvalid}}:
                          (state == S_RUN)? (((count[2:0] == 3'b000) && !(iavalid || ibvalid))? 8'hff: (count[2:0] == 3'b111)? 8'hff: preload_reg & {8{iavalid && ibvalid}}):
                          (state == S_WAIT)? (count[2:0] == 3'b000)? 8'h00: 8'hff: 8'h00;
    
    
    assign en_wire = (state == S_LOAD)? en_reg & {8{iavalid && ibvalid}}:
                     (state == S_RUN)? (((count[2:0] == 3'b000) && !(iavalid || ibvalid))? 8'hff: (count[2:0] == 3'b111)? 8'hff: en_reg & {8{iavalid && ibvalid}}):
                     (state == S_WAIT)? (count[2:0] == 3'b000)? 8'h00: 8'hff: 8'h00;
    
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
                    .clk        (clk                                ),
                    .en         (en_wire[col]                       ),
                    .load       (load_wire[col]                     ),
                    .preload    (preload_wire[col]                  ),
                    .a          (a_reg[(row+1)*SIZEIN-1 -: SIZEIN]  ),
                    .b          (b_reg[(row+1)*SIZEIN-1 -: SIZEIN]  ),
                    .b_in       (b_in                               ),
                    .b_out      (b_out[row*NCOL + col]              ),
                    .accum_in   (accum_in                           ),
                    .accum_out  (accum_out[row*NCOL + col]          )
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
