module morv_standalone_tb;
    logic clk;
    logic rst_n;

    logic [31:0] address;
    logic [31:0] wdata;
    logic write;
    logic [3:0] wstrb;
    logic [31:0] rdata;
    logic ready;
    logic exception;

    // Clock/Reset
    initial clk = 1;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #15;
        rst_n = 1;
        #1000;
        $finish;
    end

    // Top level instance
    morv_top morv_cpu_inst (.*);

    // Memory model
    simple_memory mem_inst (.*);

    // Signal monitor
    always @(posedge clk) begin
        if (rst_n) begin
            $display("Time: %0t, PC: %h, Address: %h, Rdata: %h, IR: %h, Ready: %b",
                     $time, morv_cpu_inst.pc, address, rdata, morv_cpu_inst.ir, ready);
        end
    end


endmodule
