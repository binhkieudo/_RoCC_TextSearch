`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 02:26:27 AM
// Design Name: 
// Module Name: vector_unit
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


module vector_unit(
        // System
        input clk,
        input reset,
        // Input data
        input [63:0] iA,
        input        iA_valid,
        input [63:0] iB,
        input        iB_valid,
        input [1:0]  iDest,
        // Output data
        output [31:0] oResult0,
        output [31:0] oResult1,
        output [31:0] oResult2,
        output [31:0] oResult3,
        output [31:0] oResult4,
        output [31:0] oResult5,
        output [31:0] oResult6,
        output [31:0] oResult7
    );
   
    localparam OPT_ADD = 2'b00,
               OPT_SUB = 2'b01,
               OPT_MULADD = 2'b10,
               OPT_MULSUB = 2'b11;
                   
                   
    wire [7:0] B_forward [0:63];
    wire [31:0] result_forward [0:63];
    wire [31:0] v0 [0:63];
    wire [31:0] v1 [0:63];
    
    wire [7:0] B_out [0:63];
    wire [31:0] result_out [0:63];
    wire [31:0] result_n0 [0:63];  
    wire [31:0] v0_out [0:63];
    wire [31:0] v1_out [0:63];
    
    reg [7:0] enable_reg [1:0];
    reg [7:0] a_update_reg;
    reg [7:0] b_src_reg;
    reg [7:0] b_update_reg;
    reg [1:0] alu_src_reg;
    reg [1:0] v_src_reg;
    reg [1:0] v_update_reg;
    reg [1:0] opt_reg;
    
    reg [63:0] A_reg;
    reg [64:0] B_reg;
    
    reg [1:0] Dest_reg [0:1];
    reg       Dest_index;
    reg [1:0] dest;
    
    reg rfirst;
    reg rsecond;
    
    //========= FSM ==================
    localparam S_IDLE = 0,
                S_LOAD = 1,
                S_RUN  = 2,
                S_WAIT = 3;
                
    reg [1:0] state, nstate;
    reg [2:0] count;
    
    always @(posedge clk) begin
        if (reset) state <= S_IDLE;
        else state <= nstate;
        
        if (state == S_IDLE) count <= 3'd0;
        else count <= count + 1'b1;
    end
    
    always @(*) begin
        nstate = S_IDLE;
        case (state)
            S_IDLE: nstate = (iA_valid && iB_valid)? S_LOAD: S_IDLE;
            S_LOAD: nstate = &count? (iA_valid && iB_valid)? S_LOAD: S_RUN: S_LOAD;
            S_RUN:  nstate = &count? S_WAIT: S_RUN;
            S_WAIT: nstate = S_IDLE;
            default: nstate = S_IDLE;
        endcase
    end
    
    //========= Gen Control =============
    always @(posedge clk) begin
        A_reg <= iA_valid? iA: A_reg;
        B_reg <= iB_valid? iB: B_reg; 
        
        if ((state == S_LOAD) || (state == S_RUN)) Dest_index <= (count == 3'b000)? ~Dest_index: Dest_index;
        else Dest_index <= 1'b0;
        
        Dest_reg[0] <= {iA_valid && iB_valid}? iDest: Dest_reg[0];
        Dest_reg[1] <= Dest_reg[0];
        
        if (state == S_IDLE) dest <= {2{iA_valid && iB_valid}} & iDest;
        else if (state == S_WAIT) dest <= 2'b00;
        else if (count == 3'b000 && !rsecond) dest <= Dest_reg[1];
        
        if (state == S_IDLE) rfirst = 1'b1;
        else if (&count && rfirst) rfirst <= 1'b0;
        
        if (state == S_IDLE) rsecond = 1'b1;
        else if (&count && state == S_LOAD && !rfirst && rsecond) rsecond <= 1'b0;
        
        if (state == S_IDLE) enable_reg[0] <= {8'd0};
        else if (state == S_LOAD) enable_reg[0] <= {enable_reg[0][6:0], 1'b1};
        else if (state == S_RUN) enable_reg[0] <= {enable_reg[0][6:0], 1'b0};
        else enable_reg[0] <= enable_reg[0];
        
        enable_reg[1] <= enable_reg[0];
        
        if (state == S_IDLE) a_update_reg <= {7'd0, iA_valid && iB_valid};
        else if (state == S_LOAD) 
            a_update_reg <= &count? {7'd0, iA_valid && iB_valid}: 
                                    {a_update_reg[6:0], a_update_reg[7]};
        else a_update_reg <= 8'd0;
        
        if (state == S_IDLE) b_src_reg <= {7'b111_1111, !(iA_valid && iB_valid)};
        else if (state == S_LOAD) 
            b_src_reg <= &count? {7'b111_1111, !(iA_valid && iB_valid)}: 
                                 {b_src_reg[6:0], 1'b1};
        else b_src_reg <= 8'hff;
        
        if (state == S_IDLE) b_update_reg <= {7'd0, iA_valid && iB_valid};
        else if (state == S_LOAD) 
            b_update_reg <= &count? (iA_valid && iB_valid)? 8'hff: {b_update_reg[6:0], !(&count)}:
                                    {b_update_reg[6:0], !(&count)};                                 
        else if (state == S_RUN) b_update_reg <= {b_update_reg[6:0], 1'b0};
        else  b_update_reg <= 8'd0;
         
        alu_src_reg <= 2'b00;
        
        v_src_reg <= iDest;
        v_update_reg <= {2{(state != S_IDLE)}} & iDest;
        
        opt_reg <= OPT_MULADD;
    end
    
    //========= GEN PE ==================

    genvar row, col;
    generate
        for (row = 0; row < 8; row = row + 1) begin: gen_row
            for (col = 0; col < 8; col = col + 1) begin: gen_col
                
                assign B_forward[row*8+col] = B_out[((row+1)%8)*8+col];
                
                if (col == 0) assign result_forward[row*8+col] = 32'd0;
                else assign result_forward[row*8+col] = result_out[row*8+col-1];
                
                if (((7+row)%8) == col) begin
                    assign v0[row*8+col] = result_n0[row*8+7];
                    assign v1[row*8+col] = result_n0[row*8+7];
                end
                else begin
                    assign v0[row*8+col] = v0_out[row*8+((col+1)%8)];
                    assign v1[row*8+col] = v1_out[row*8+((col+1)%8)];
                end
                
                pe pe (
                    .clk            (clk                       ),
                    .enable         (enable_reg[1][col]        ),
                    // Control
                    .a_update       (a_update_reg[col]         ),
                    .b_src          (b_src_reg[col]            ),
                    .b_update       (b_update_reg[col]         ),
                    .alu_src        (alu_src_reg               ),
                    .v_src          (dest                      ),
                    .v_update       (dest                      ),
                    .opt            (opt_reg                   ),
                    // Input data
                    .A_in           (A_reg[(row+1)*8 - 1 -: 8] ),
                    .B_in           (B_reg[(row+1)*8 - 1 -: 8] ),
                    .B_forward      (B_forward[row*8+col]      ),
                    .result_forward (result_forward[row*8+col] ),
                    .v0_in          (v0[row*8+col]             ),
                    .v1_in          (v1[row*8+col]             ),
                    // Output data
                    .B_out          (B_out[row*8+col]          ),
                    .result_n0      (result_n0[row*8+col]      ),
                    .result_out     (result_out[row*8+col]     ),
                    .v0_out         (v0_out[row*8+col]         ),
                    .v1_out         (v1_out[row*8+col]         )
                );
            end
        end
    endgenerate
    
    assign oResult0 = v0_out[0];
    assign oResult1 = v0_out[8];
    assign oResult2 = v0_out[16];
    assign oResult3 = v0_out[24];
    assign oResult4 = v0_out[32];
    assign oResult5 = v0_out[40];
    assign oResult6 = v0_out[48];
    assign oResult7 = v0_out[56];
    
endmodule
