`timescale 1ns / 1ps

module native_synth #(
    parameter N = 128,
    parameter WEIGHT_WIDTH = 4,
    parameter ACT_WIDTH = 4
)(
    input                        clk,
    input                        rst,
    input                        start,
    input [N*WEIGHT_WIDTH-1 : 0] i_weights_flat, 
    input [N*ACT_WIDTH-1 : 0]    i_acts_flat,
    
    output reg                   done,
    output reg [15:0]            result
);

    reg signed [WEIGHT_WIDTH-1:0] w_reg [0:N-1];
    reg signed [ACT_WIDTH-1:0]    a_reg [0:N-1];

    reg signed [15:0] mul_stage [0:N-1];
    reg signed [15:0] add_stage1 [0:63];
    reg signed [15:0] add_stage2 [0:31];
    reg signed [15:0] add_stage3 [0:15];
    reg signed [15:0] add_stage4 [0:7];
    reg signed [15:0] add_stage5 [0:3];
    reg signed [15:0] add_stage6 [0:1];
    reg signed [15:0] add_stage7;

    reg [8:0] valid_pipe; 
    
    integer i;


    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= 0;
            done <= 0;
            result <= 0;
            for (i=0; i<N; i=i+1) begin
                w_reg[i] <= 0;
                a_reg[i] <= 0;
            end
        end else begin
            valid_pipe <= {valid_pipe[7:0], start};

            if (start) begin
                for (i=0; i<N; i=i+1) begin

                    w_reg[i] <= i_weights_flat[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];
                    a_reg[i] <= i_acts_flat[i*ACT_WIDTH +: ACT_WIDTH];
                end
            end

            if (valid_pipe[8]) begin
                done <= 1;
                result <= add_stage7;
            end else begin
                done <= 0;
            end
        end
    end


    always @(posedge clk) begin
        // Stage 0: Multiplication
        for (i=0; i<N; i=i+1) begin
            mul_stage[i] <= $signed(w_reg[i]) * $signed(a_reg[i]);
        end

        // Stage 1: 128 -> 64
        for (i=0; i<64; i=i+1) add_stage1[i] <= mul_stage[2*i] + mul_stage[2*i+1];

        // Stage 2: 64 -> 32
        for (i=0; i<32; i=i+1) add_stage2[i] <= add_stage1[2*i] + add_stage1[2*i+1];

        // Stage 3: 32 -> 16
        for (i=0; i<16; i=i+1) add_stage3[i] <= add_stage2[2*i] + add_stage2[2*i+1];

        // Stage 4: 16 -> 8
        for (i=0; i<8; i=i+1)  add_stage4[i] <= add_stage3[2*i] + add_stage3[2*i+1];

        // Stage 5: 8 -> 4
        for (i=0; i<4; i=i+1)  add_stage5[i] <= add_stage4[2*i] + add_stage4[2*i+1];

        // Stage 6: 4 -> 2
        for (i=0; i<2; i=i+1)  add_stage6[i] <= add_stage5[2*i] + add_stage5[2*i+1];

        // Stage 7: 2 -> 1
        add_stage7 <= add_stage6[0] + add_stage6[1];
    end

endmodule