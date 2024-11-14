`timescale 1ns / 1ps

module mac# (
    parameter SIZEIN = 8, 
    parameter SIZEOUT = 24
)(
    input clk, en, load, preload,
    input signed  [SIZEIN-1:0]  a, b,
    input signed  [SIZEIN-1:0]  b_in,  
    output signed [SIZEIN-1:0]  b_out,
    input signed  [SIZEOUT-1:0] accum_in,
    output signed [SIZEOUT-1:0] accum_out
);

    // Declare registers for intermediate values
    reg signed [SIZEIN-1:0]  a_reg, b_reg;
    reg signed [2*SIZEIN:0]  mult_reg;
    reg signed [SIZEOUT-1:0] adder_out;


    always @(posedge clk) begin
        if (load) begin
            a_reg <= a;
            b_reg <= b;
        end
        else if (preload) b_reg <= b_in;
     
        if (en) begin
            mult_reg <= a_reg * b_reg;

            adder_out <= accum_in + mult_reg;
        end
    end
    
    // Output accumulation result
    assign b_out     = b_reg;
    assign accum_out = adder_out;

endmodule
