`timescale 1ns/1ps

module tb_native_synth;

    localparam N            = 128;
    localparam WEIGHT_WIDTH = 4;
    localparam ACT_WIDTH    = 4;
    localparam BATCH_NUM    = 1024;

    reg clk;
    reg rst;
    reg start;
    wire done;             
    wire signed [15:0] result;

    reg signed [15:0] expected_result[0:BATCH_NUM-1];

    reg [N*WEIGHT_WIDTH-1 : 0] i_weights_flat;
    reg [N*ACT_WIDTH-1 : 0]    i_acts_flat;
    

    reg [WEIGHT_WIDTH-1:0] tb_weight_mem [0 : N*BATCH_NUM - 1];
    reg [ACT_WIDTH-1:0]    tb_act_mem    [0 : N*BATCH_NUM - 1];


    integer i, b;
    integer err_cnt;
    integer out_cnt;


    native_synth #(
        .N(N),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACT_WIDTH(ACT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .i_weights_flat(i_weights_flat),
        .i_acts_flat(i_acts_flat),
        .done(done),
        .result(result)
    );


    initial clk = 0;
    always #2.5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            out_cnt = 0;
            err_cnt = 0;
        end else if (done) begin 
            if (result !== expected_result[out_cnt]) begin
                $display("[ERROR] Batch %0d: Exp=%d, Got=%d", out_cnt, expected_result[out_cnt], result);
                err_cnt = err_cnt + 1;
            end 
            out_cnt = out_cnt + 1;
        end
    end


    initial begin

        $readmemh("result.hex", expected_result);
        $readmemh("weights.hex", tb_weight_mem);
        $readmemh("data.hex", tb_act_mem);


        rst   = 1;
        start = 0;
        i_weights_flat = 0;
        i_acts_flat = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("--------------------------------------------------");
        $display("[INFO] Starting NATIVE simulation for %0d batches...", BATCH_NUM);
        $display("--------------------------------------------------");

        for (b = 0; b < BATCH_NUM; b = b + 1) begin
            
            for (i = 0; i < N; i = i + 1) begin
                i_weights_flat[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = tb_weight_mem[b*N + i];
                i_acts_flat[i*ACT_WIDTH +: ACT_WIDTH]          = tb_act_mem[b*N + i];
            end
            start = 1;   
            @(posedge clk);
        end

        start = 0;
        i_weights_flat = 0;
        i_acts_flat = 0;


        wait(out_cnt == BATCH_NUM);
        
        repeat(10) @(posedge clk);   

        if (err_cnt == 0) begin
            $display("--------------------------------------------------");
            $display("          TEST PASSED (Native Module)             ");
            $display("--------------------------------------------------");
        end else begin
            $display("--------------------------------------------------");
            $display("      TEST FAILED (Total Errors: %0d)             ", err_cnt);
            $display("--------------------------------------------------");
        end

        $finish;
    end

endmodule
           