module iram (#parameter ADDR_WIDTH = 10, #parameter WORD_WIDTH = 64)(
    input clk,
    input rst,
    input iram_wr_enbl,
    input iram_rd_enbl, 
    input [ADDR_WIDTH-1:0] iram_wr_addr0,
    input [ADDR_WIDTH-1:0] iram_wr_addr1,
    input [ADDR_WIDTH-1:0] iram_rd_addr0,
    input [ADDR_WIDTH-1:0] iram_rd_addr1,
    input [WORD_WIDTH-1:0] iram_wr_data0,
    input [WORD_WIDTH-1:0] iram_wr_data1,
    output [WORD_WIDTH-1:0] iram_rd_data0,
    output [WORD_WIDTH-1:0] iram_rd_data1
);
//Need to think about clock cycles - How is it RAM a single clock cycle and change it 
reg [WORD_WIDTH-1:0] memory_iram [0:(1 << ADDR_WIDTH)-1];

assign iram_rd_data0 = iram_rd_enbl ? memory_iram[iram_rd_add0] : iram_rd_data0;
assign iram_rd_data1 = iram_rd_enbl ? memory_iram[iram_rd_add]1 : iram_rd_data1;

always @(posedge clk)
begin
    if(rst) 
    begin 
        for (i = 0; i < (1 << ADDR_WIDTH);i = i + 1) 
        begin
                    memory_iram[i] <={WORD_WIDTH{1'b0}};
        end
    end 
    else
    begin 
        if(iram_wr_enbl0) memory_iram[iram_wr_addr0] <= iram_wr_data0;
        if(iram_wr_enbl1) memory_iram[iram_wr_addr]1 <= iram_wr_data1;
    end
end

endmodule