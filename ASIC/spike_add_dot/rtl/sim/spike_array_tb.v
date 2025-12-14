`timescale 1ns/1ps

module spike_array_tb;

    localparam N         = 128;
    localparam BITWIDTH  = 4;
    localparam BATCH_NUM = 1024; 

    reg clk;
    reg rst;
    reg start;
    wire done;           
    wire signed [15:0] result;

    reg signed [15:0] expected_result[0:BATCH_NUM-1];

    reg [N*4-1 : 0]        i_weights_flat;
    reg [N*BITWIDTH-1 : 0] i_acts_flat;
    
    reg [3:0]          tb_weight_mem [0 : N*BATCH_NUM - 1];
    reg [BITWIDTH-1:0] tb_act_mem    [0 : N*BATCH_NUM - 1];

    //reg done_dly;          // 延迟1拍的done信号
    //reg signed [15:0] result_dly; // 延迟1拍的result信号

    integer i, b;
    integer err_cnt;
    integer out_cnt;

    spike_array #(
        .N(N),
        .BITWIDTH(BITWIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .i_weights_flat(i_weights_flat),
        .i_acts_flat(i_acts_flat),
        .done(done),
        .result(result)
    );

    initial	begin
	  $fsdbDumpfile("tb.fsdb");	    
        $fsdbDumpvars;
    end

    initial clk = 0;
    always #1 clk = ~clk;

	/*always @(posedge clk) begin
        if (rst) begin
            done_dly <= 1'b0;
            result_dly <= 16'sd0;
        end else begin
            done_dly <= done;           // done延迟1拍
            result_dly <= result;       // result延迟1拍
        end
    end*/

    always @(posedge clk) begin
        if (rst) begin
            out_cnt = 0;
            err_cnt = 0;
        end else if (done) begin 
            if (result !== expected_result[out_cnt]) begin
                $display("[ERROR] Batch %0d: Exp=%d, Got=%d", out_cnt, expected_result[out_cnt], result);
                err_cnt = err_cnt + 1;
            end else begin
            end
            out_cnt = out_cnt + 1;
        end
    end


    initial begin
        $readmemh("./../rtl/sim/data/result.hex", expected_result);
        $readmemh("./../rtl/sim/data/weights.hex", tb_weight_mem);
        $readmemh("./../rtl/sim/data/data.hex", tb_act_mem);  

        rst   = 1;
        start = 0;
        i_weights_flat = 0;
        i_acts_flat = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("Starting simulation for %0d batches...", BATCH_NUM);

        for (b = 0; b < BATCH_NUM; b = b + 1) begin

            for (i = 0; i < N; i = i + 1) begin
                i_weights_flat[i*4 +: 4]            = tb_weight_mem[b*N + i];
                i_acts_flat[i*BITWIDTH +: BITWIDTH] = tb_act_mem[b*N + i];
            end
            
            start = 1; 
            @(posedge clk); 
        end

        start = 0;
        i_weights_flat = 0;
        i_acts_flat = 0;

        wait(out_cnt == BATCH_NUM);
        
        repeat(5) @(posedge clk);   

        if (err_cnt == 0) 
            $display("---------------- TEST PASSED ----------------");
        else 
            $display("---------------- TEST FAILED (Errors: %0d) ----------------", err_cnt);

        $finish;
    end

endmodule
