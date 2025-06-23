module morv_top (
    input logic clk,
    input logic rst_n,

    // Memory interface
    output logic [31:0] address,
    output logic [31:0] wdata,
    output logic write,
    output logic [3:0] wstrb,
    input logic [31:0] rdata,
    input logic ready
);
    import rv32_pkg::*;

    parameter [31:0] RESET_VECTOR = 32'b0;

    // Registers
    logic [31:0] pc;
    logic [31:0] ir;

    // PC logic
    wire mem_access_en;
    assign address = mem_access_en ? alu_result : pc;

    wire [31:0] next_pc;

    always_ff @(posedge clk) begin
        if (!rst_n)
            pc <= RESET_VECTOR;
        else
            pc <= next_pc;
    end

    // IR logic
    always_ff @(posedge clk) begin
        ir <= ready ? rdata : ir;
    end

    // read instruction logic
    assign write = 0;
    assign wstrb = 4'b0000;

    // Instruction decode
    wire [6:0] opcode = ir[6:0];
    wire [4:0] rd = ir[11:7];
    wire [2:0] funct3 = ir[14:12];
    wire [4:0] rs1 = ir[19:15];
    wire [4:0] rs2 = ir[24:20];
    wire [6:0] funct7 = ir[31:25];
    wire [31:0] imm;

    // imm assignement
    always_comb begin
        imm = 0;
        case (opcode)
            // U-type
            LUI,
            AUIPC:
                imm = {ir[31:12], 12'b0};
            
            // J-type
            JAL: begin
                imm[31:21] = {11{ir[31]}};
                imm[20] = ir[31];
                imm[19:12] = ir[19:12];
                imm[11] = ir[20];
                imm[10:1] = ir[30:21];
                imm[0] = 1'b0;
            end

            // I-type
            JALR,
            LW,
            I:
                imm = {{20{ir[31]}}, ir[31:20]};

            // B-type
            B: begin
                imm[31:13] = {20{ir[31]}};
                imm[12] = ir[31];
                imm[11] = ir[7];
                imm[10:5] = ir[30:25];
                imm[4:1] = ir[11:8];
                imm[0] = 1'b0;
            end

            // S-type
            SW: begin
                imm[31:12] = {20{ir[31]}};
                imm[11:5] = ir[31:25];
                imm[4:0] = ir[11:7];
            end

            default: imm = 0;
        endcase
    end

    // Register File
    logic [31:0] xreg [0:31];
    // Read ports
    wire [31:0] rs1_data;
    assign rs1_data = rs1 == 5'b0 ? 32'b0 : xreg[rs1];
    wire [31:0] rs2_data;
    assign rs2_data = rs2 == 5'b0 ? 32'b0 : xreg[rs2];
    // Write ports
    wire [31:0] xreg_wdata;
    wire [4:0] xreg_rd;
    wire xreg_wren;
    // Write logic
    always_ff @(posedge clk) begin
        if (!rst_n)
            for (int i = 0; i < 32; i++) begin
                xreg[i] <= 32'b0;
            end
        else if (rst_n && xreg_wren && (xreg_rd != 5'b0))
            xreg[xreg_rd] <= xreg_wdata;
    end

    // Execute stage
    // ALU
    wire [31:0] alu_a;
    wire alu_a_sel;
    assign alu_a = alu_a_sel ? rs1_data : pc;

    wire [31:0] alu_b;
    wire alu_b_sel;
    assign alu_b = alu_b_sel ? rs2_data : imm;

    alu_ops alu_op;
    wire [31:0] alu_result;

    // ALU operator selection
    always_comb begin
        alu_a_sel = 0;
        alu_b_sel = 0;
        alu_op = INVALID;

        case (opcode)
            // R-type
            R: begin
                alu_a_sel = 1;
                alu_b_sel = 1;
                case (funct3)
                    3'b000: begin
                        case (funct7)
                            7'b0: alu_op = ADD;
                            7'b0100000: alu_op = SUB;
                            default: alu_op = INVALID;
                        endcase
                    end
                    3'b001: alu_op = SLL;
                    3'b010: alu_op = SLT;
                    3'b011: alu_op = SLTU;
                    3'b100: alu_op = XOR;
                    3'b101: begin
                        case (funct7)
                            7'b0: alu_op = SRL;
                            7'b0100000: alu_op = SRA;
                            default: alu_op = INVALID;
                        endcase
                    end
                    3'b110: alu_op = OR;
                    3'b111: alu_op = AND;
                    default: alu_op = INVALID;
                endcase
            end

            // I-type
            I: begin
                alu_a_sel = 1;
                alu_b_sel = 0;
                case (funct3)
                    3'b000: alu_op = ADDI;
                    3'b010: alu_op = SLTI;
                    3'b011: alu_op = SLTIU;
                    3'b100: alu_op = XORI;
                    3'b110: alu_op = ORI;
                    3'b111: alu_op = ANDI;
                endcase
            end

            LW, SW: begin
                alu_a_sel = 1;
                alu_b_sel = 0;
                alu_op = ADD;
            end

            AUIPC: begin
                alu_a_sel = 0;
                alu_b_sel = 0;
                alu_op = ADD;
            end

            JAL, B: begin
                alu_a_sel = 0;
                alu_b_sel = 0;
                alu_op = ADD;
            end

            JALR: begin
                alu_a_sel = 1;
                alu_b_sel = 0;
                alu_op = JALR;
            end

            LUI: begin
                alu_a_sel = 0;
                alu_b_sel = 0;
                alu_op = BYPASS;
            end

            default: begin
                alu_a_sel = 0;
                alu_b_sel = 0;
                alu_op = INVALID;
            end
        endcase
    end

    always_comb begin
        alu_result = 0;
        case (alu_op)
            ADD, ADDI: alu_result = alu_a + alu_b;
            SUB: alu_result = alu_a - alu_b;
            SLL: alu_result = alu_a << alu_b;
            SLT, SLTI: alu_result = $signed(alu_a) < $signed(alu_b);
            SLTU, SLTIU: alu_result = alu_a < alu_b;
            XOR, XORI: alu_result = alu_a ^ alu_b;
            SRL: alu_result = alu_a >> alu_b;
            SRA: alu_result = alu_a >>> alu_b;
            OR, ORI: alu_result = alu_a | alu_b;
            AND, ANDI: alu_result = alu_a & alu_b;

            JALR: alu_result = (alu_a + alu_b) & ~(32'b1);
            BYPASS: alu_result = alu_b;

            default: alu_result = 0; // TODO error handling.
        endcase
    end

    // Write-back stage
    always_comb begin
        xreg_wren = 0;
        xreg_rd = rd;
        xreg_wdata = 0;
        case (opcode)
            R, I: begin
                xreg_wren = 1;
                xreg_wdata = alu_result;
            end

            LW: begin
                xreg_wren = 1;
                xreg_wdata = rdata;
            end

            LUI: begin
                xreg_wren = 1;
                xreg_wdata = alu_result;
            end

            AUIPC: begin
                xreg_wren = 1;
                xreg_wdata = alu_result;
            end

            JAL, JALR: begin
                xreg_wren = 1;
                xreg_wdata = pc + 4;
            end

            B, SW: xreg_wren = 0;
            default: xreg_wren = 0;
        endcase
    end

    // Memory Access stage
    always_comb begin
        mem_access_en = 0;
        write = 0;
        wdata = 0;
        wstrb = 0;
        case (opcode)
            LW: begin
                mem_access_en = 1;
                write = 0;
                wdata = 0; // doesn't matter
                wstrb = 0; // doesn't matter
            end

            SW: begin
                mem_access_en = 1;
                write = 1;
                wdata = rs2_data;
                wstrb = 4'b1111;
            end

            default: begin
                mem_access_en = 0;
                write = 0;
                wdata = 0; // doesn't matter
                wstrb = 0; // doesn't matter
            end
        endcase
    end

    // next_pc calculation
    always_comb begin
        next_pc = pc + 4
        case (opcode)
            JAL, JALR: next_pc = alu_result;
            B: begin
                case (funct3)
                    3'b000: begin // BEQ
                        if (rs1_data == rs2_data)
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end
                    3'b001: begin // BNE
                        if (rs1_data != rs2_data)
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end
                    3'b100: begin // BLT
                        if ($signed(rs1_data) < $signed(rs2_data))
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end
                    3'b101: begin // BGE
                        if ($signed(rs1_data) > $signed(rs2_data))
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end
                    3'b110: begin // BLTU
                        if (rs1_data < rs2_data)
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end
                    3'b111: begin // BGEU
                        if (rs1_data > rs2_data)
                            next_pc = alu_result;
                        else
                            next_pc = pc + 4;
                    end 
                endcase
            end
            default: next_pc = pc + 4;
        endcase
    end
endmodule
