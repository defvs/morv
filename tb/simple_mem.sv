// simple_memory.sv
module simple_memory (
    input  logic        clk,
    input  logic        rst_n, // Not strictly needed for this simple memory, but good practice
    input  logic [31:0] address,
    input  logic [31:0] wdata,
    input  logic        write,
    input  logic [3:0]  wstrb,
    output logic [31:0] rdata,
    output logic        ready
);

    // Memory array: 256 words (1KB total), byte-addressable
    // Assuming word-aligned access for now, so address/4
    logic [31:0] mem [0:255];

    // Read Data Path
    logic [31:0] rdata_next; // Internal for pipelining/latency

    // Ready signal. Let's make it a 1-cycle latency memory.
    // Data is ready one cycle after address is presented.
    logic ready_q;
    assign ready = ready_q; // Output the latched ready

    // Read/Write Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ready_q <= 1'b0; // Memory not ready on reset
            rdata <= 32'b0; // Or 'x
        end else begin
            // Handle read request
            // If it's not a write, it's a read.
            // Latency: data available *next* cycle.
            if (!write) begin
                ready_q <= 1'b1; // Data will be ready next cycle
                rdata <= mem[address[9:2]]; // address[9:2] gives word address from byte address
            end else begin
                // Handle write request
                // In this simple model, writes are assumed to be synchronous and instantaneous
                // wstrb allows byte-level writes within a word
                for (int i = 0; i < 4; i++) begin
                    if (wstrb[i]) begin
                        mem[address[9:2]][(i*8)+:8] = wdata[(i*8)+:8];
                    end
                end
                ready_q <= 1'b1; // Memory is ready next cycle after write, too
                rdata <= 32'b0; // No valid read data during a write
            end
        end
    end

    // Initialization of memory content
    initial begin
        // Example instructions (replace with actual RISC-V opcodes later)
        mem[0] = 32'h00000013; // addi x0, x0, 0
        mem[1] = 32'h00100013; // addi x0, x0, 1
        mem[2] = 32'h00200013; // addi x0, x0, 2
        mem[3] = 32'h00300013; // addi x0, x0, 3
        mem[4] = 32'h00400013; // addi x0, x0, 4
        // Fill the rest with some recognizable pattern or zeros
        for (int i = 5; i < 256; i++) begin
            mem[i] = {24'hDEADBE, i[7:0]}; // recognizable dummy data
        end
    end

endmodule
