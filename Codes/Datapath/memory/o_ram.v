module oram #(parameter ADDR_WIDTH = 12, parameter WORD_WIDTH = 64)(
    input clk,
    input rstn,
    input oram_wr_enbl,
    input oram_rd_enbl,
    input [ADDR_WIDTH-1:0] oram_wr_addr,
    input [ADDR_WIDTH-1:0] oram_rd_addr,
    input [WORD_WIDTH-1:0] oram_wr_data,
    output reg [WORD_WIDTH-1:0] oram_rd_data
);

reg [WORD_WIDTH-1:0] memory_oram [0:(1 << ADDR_WIDTH)-1];
integer i;

always @(posedge clk) begin
    if (!rstn) begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            memory_oram[i] <= {WORD_WIDTH{1'b0}};
        end
    end else if (oram_wr_enbl) begin
        memory_oram[oram_wr_addr] <= oram_wr_data;
    end
end

always @(posedge clk) begin
    if (!rstn) begin
        oram_rd_data <= {WORD_WIDTH{1'b0}};
    end else if (oram_rd_enbl) begin
        oram_rd_data <= memory_oram[oram_rd_addr];
    end
end

endmodule