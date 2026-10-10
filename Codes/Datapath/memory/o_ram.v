module o_ram (#parameter ADDR_WIDTH = 10, #parameter WORD_WIDTH = 64)(
    input clk,
    input rst, 
    input oram_wr_enbl,
    input oram_rd_enbl
    input [ADDR_WIDTH-1:0] oram_wr_addr,
    input [ADDR_WIDTH-1:0] oram_rd_addr,
    input [WORD_WIDTH-1:0] oram_wr_data,
    output [WORD_WIDTH-1:0] oram_rd_data
);

reg [WORD_WIDTH-1:0] memory_oram [0:(1 << ADDR_WIDTH)-1];

assign oram_rd_data = oram_rd_enbl ? memory_oram[oram_rd_addr] : oram_rd_data;

always @(posedge clk)
begin
    if(rst) 
    begin 
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) 
        begin
            memory_oram[i] <={WORD_WIDTH{1'b0}};
        end
    end 
    else
    begin 
        if(oram_wr_enbl) memory_oram[oram_wr_addr] <= oram_wr_data;
    end
end

endmodule