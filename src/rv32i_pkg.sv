package rv32i_pkg;
    typedef enum logic [6:0] {
        // U-Type
        LUI     = 7'b0110111,
        AUIPC   = 7'b0010111,
        // J-type
        JAL     = 7'b1101111,
        // B-type
        B       = 7'b1100011,
        // I-type
        LW      = 7'b0000011,
        JALR    = 7'b1100111,
        I       = 7'b0010011,
        // S-type
        SW      = 7'b0100011,
        // R-type
        R       = 7'b0110011,
        // system-type
        SYSTEM  = 7'b1110011
    } rv32i_opcode;

    typedef enum logic [5:0] {
        ADD,
        SUB,
        SLL,
        SLT,
        SLTU,
        XOR,
        SRL,
        SRA,
        OR,
        AND,
        
        ADDI,
        SLTI,
        SLTIU,
        XORI,
        ORI,
        ANDI,

        BYPASS,
        ALU_JALR,
        NOP,
        INVALID
    } alu_ops;
endpackage
