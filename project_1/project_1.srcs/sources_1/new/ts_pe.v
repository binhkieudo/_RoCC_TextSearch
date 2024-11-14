`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2024 12:54:45 PM
// Design Name: 
// Module Name: ts_pe
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


module ts_pe#(
    parameter NCORES        = 4096,
    parameter BUS_WIDTH     = 64,
    parameter CHAR_LEN      = 8,
    parameter SEED_BUF      = 16,
    parameter CHANNEL       = 1,
    parameter ENTITY        = NCORES*CHAR_LEN/CHANNEL/BUS_WIDTH,
    parameter ADDR_WIDTH    = $clog2(ENTITY)
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
    input [CHANNEL*BUS_WIDTH-1:0]   iref,
    input [CHANNEL-1:0]             iref_valid,
    input [CHANNEL*ADDR_WIDTH-1:0]  iref_address,
    // Output
    output [NCORES-1:0]     oscore,
    output                  ovalid,
    output                  oready
);

    localparam ENTITY_WIDTH=NCORES*CHAR_LEN/CHANNEL;

    reg [NCORES-1:0] fscore;
    wire [NCORES-1:0] tscore;    
    
    reg [NCORES*CHAR_LEN-1:0] ref_cache;
    
// ============ CACHING =============================
    integer cindex, chindex;
    always @(posedge clk) begin
        for (chindex = 0; chindex < CHANNEL; chindex = chindex + 1) begin: channel    
            for (cindex = 0; cindex < ENTITY; cindex = cindex + 1) begin: assign_cache
                if (iref_valid[chindex] && (iref_address[(chindex+1)*ADDR_WIDTH-1-:ADDR_WIDTH] == cindex))
                    ref_cache[(chindex*ENTITY_WIDTH) + (cindex + 1)*BUS_WIDTH - 1 -: BUS_WIDTH] <= iref[(chindex+1)*BUS_WIDTH-1 -: BUS_WIDTH];
            end
        end
    end
    
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
            assign tscore[i] = (iseed == ref_cache[(i+1)*CHAR_LEN-1 -: CHAR_LEN]);
            
            always @(posedge clk) begin
                if (state == S_FIRST) fscore[i] <= tscore[i];
                else if (state == S_MATCH) begin
                    if (i == 0) begin
                        fscore[i] <= 1'b0;
                    end
                    else begin
                        if (iseed_valid) fscore[i] <= tscore[i] && fscore[i-1];
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
