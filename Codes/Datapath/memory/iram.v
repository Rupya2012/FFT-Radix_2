module iram #(parameter ADDR_WIDTH = 12, parameter WORD_WIDTH = 64)(
    input clk,
    input rstn,
    input iram_wr_enbl,
    input iram_rd_enbl,
    input [ADDR_WIDTH-1:0] iram_wr_addr,
    input [ADDR_WIDTH-1:0] iram_rd_addr,
    input [WORD_WIDTH-1:0] iram_wr_data,
    output reg [WORD_WIDTH-1:0] iram_rd_data
);

reg [WORD_WIDTH-1:0] memory_iram [0:(1 << ADDR_WIDTH)-1];

always @(posedge clk) begin
    if (iram_wr_enbl) begin
        memory_iram[iram_wr_addr] <= iram_wr_data;
    end
end

always @(posedge clk) begin
    if (!rstn) begin
        iram_rd_data <= {WORD_WIDTH{1'b0}};
    end else if (iram_rd_enbl) begin
        iram_rd_data <= memory_iram[iram_rd_addr];
    end
end

endmodule