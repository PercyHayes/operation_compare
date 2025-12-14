`timescale 1ns / 1ps

module naive_dot #(
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

    // 1. 输入解包 + 乘法（组合逻辑）
    wire signed [WEIGHT_WIDTH-1:0] w_wire [0:N-1];
    wire signed [ACT_WIDTH-1:0]    a_wire [0:N-1];
    wire signed [7:0]             mul_wire [0:N-1];

    genvar i;
    generate
        for (i=0; i<N; i=i+1) begin : GEN_INPUT_MUL
            assign w_wire[i] = i_weights_flat[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];
            assign a_wire[i] = i_acts_flat[i*ACT_WIDTH +: ACT_WIDTH];
            assign mul_wire[i] = $signed(w_wire[i]) * $signed(a_wire[i]);
        end
    endgenerate

    // 2. 4级流水线寄存器定义（核心优化：拆分跨周期打拍）
    reg signed [8:0]  pipe1 [0:63];  // P1: 乘法+128→64 结果
    reg signed [10:0] pipe2 [0:15];  // P2: 64→32→16 结果
    reg signed [12:0] pipe3 [0:3];   // P3: 16→8→4 结果
    reg signed [14:0] pipe4;         // P4: 4→2→1 最终结果

    // 3. 流水线控制信号（匹配4级流水线，共4拍延迟）
    reg [3:0] valid_pipe;  // 原7位改为4位，匹配实际流水线级数

    // 4. 流水线时序逻辑（每级单独打拍，真正的流水线）
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            // 寄存器复位
            for (k=0; k<64; k=k+1) pipe1[k] <= 0;
            for (k=0; k<16; k=k+1) pipe2[k] <= 0;
            for (k=0; k<4; k=k+1)  pipe3[k] <= 0;
            pipe4 <= 0;
            valid_pipe <= 4'b0000;
            done <= 0;
            result <= 0;
        end else begin
            // --------------------------
            // P1级：乘法 + 128→64 加法（第1拍）
            // --------------------------
            for (k=0; k<64; k=k+1) begin
                pipe1[k] <= mul_wire[2*k] + mul_wire[2*k+1];
            end
            valid_pipe[0] <= start;  // start信号同步到P1

            // --------------------------
            // P2级：64→32 + 32→16 加法（第2拍）
            // --------------------------
            for (k=0; k<16; k=k+1) begin
                pipe2[k] <= (pipe1[4*k] + pipe1[4*k+1]) + (pipe1[4*k+2] + pipe1[4*k+3]);
            end
            valid_pipe[1] <= valid_pipe[0];  // 控制信号随流水线打拍

            // --------------------------
            // P3级：16→8 + 8→4 加法（第3拍）
            // --------------------------
            for (k=0; k<4; k=k+1) begin
                pipe3[k] <= (pipe2[4*k] + pipe2[4*k+1]) + (pipe2[4*k+2] + pipe2[4*k+3]);
            end
            valid_pipe[2] <= valid_pipe[1];

            // --------------------------
            // P4级：4→2 + 2→1 加法（第4拍）
            // --------------------------
            pipe4 <= ((pipe3[0] + pipe3[1]) + (pipe3[2] + pipe3[3]));
            valid_pipe[3] <= valid_pipe[2];

            // --------------------------
            // 结果输出 + done信号（流水线末尾）
            // --------------------------
            if (valid_pipe[3]) begin  // 4级流水线完成，触发done
                done <= 1'b1;
                result <= {pipe4[14], pipe4};  // 符号位扩展到16位
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
