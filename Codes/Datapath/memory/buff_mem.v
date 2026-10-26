module buff #(
    parameter ADDR_WIDTH   = 12,
    parameter WORD_WIDTH   = 64,
    parameter FRACTIONAL_L = 14
)(
    input clk,
    input rstn,
    input buff_wr_enbl,
    input buff_rd_enbl,
    input [ADDR_WIDTH-1:0] buff_wr_addr,
    input [ADDR_WIDTH-1:0] buff_rd_addr,
    input [WORD_WIDTH-1:0] buff_wr_data,
    output reg [WORD_WIDTH-1:0] buff_rd_data
);

reg [WORD_WIDTH-1:0] memory_buff [0:(1 << ADDR_WIDTH)-1];
integer i;

// Synchronous Write / Memory Reset
// Only resets working data buffer (0 to 2047); twiddle table (2048 to 4095) is preserved
always @(posedge clk) begin
    if (!rstn) begin
        for (i = 0; i < (1 << (ADDR_WIDTH-1)); i = i + 1) begin
            memory_buff[i] <= {WORD_WIDTH{1'b0}};
        end
    end else if (buff_wr_enbl) begin
        memory_buff[buff_wr_addr] <= buff_wr_data;
    end
end

// Synchronous Read
always @(posedge clk) begin
    if (!rstn) begin
        buff_rd_data <= {WORD_WIDTH{1'b0}};
    end else if (buff_rd_enbl) begin
        buff_rd_data <= memory_buff[buff_rd_addr];
    end
end

// Preload Twiddle Factors directly from MATLAB-generated hex file
initial begin
    for (i = 0; i < (1 << (ADDR_WIDTH-1)); i = i + 1) begin
        memory_buff[i] = {WORD_WIDTH{1'b0}};
    end
    $readmemh("buff_mem_twiddles_all.hex", memory_buff);
end

endmodule