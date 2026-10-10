module buff_mem (parameter ADDR_WIDTH = 12, #parameter WORD_WIDTH = 32)(
    input clk, 
    input rst,//active high 
    input rd_enbl,
    input wr_enbl,
    input [ADDR_WIDTH -1] wr_addr0,  
    input [ADDR_WIDTH -1] wr_addr1, 
    input [ADDR_WIDTH -1] rd_addr0,
    input [ADDR_WIDTH -1] rd_addr1,
    input [15:0] wr_data0,
    input [15:0] wr_data1,
    output [15:0] rd_data0,
    output [15:0] rd_data1
);

reg [WORD_WIDTH-1:0] memory [0:(1 << ADDR_WIDTH)-1];

assign rd_data0 = rd_enbl ? memory[rd_addr0][15:0] : rd_data0;
assign rd_data1 = rd_enbl ? memory[rd_addr1][15:0] : rd_data1;

always @(posedge clk)
 begin
    if(rst) 
    begin 
        for (i = 0; i < (1 << ADDR_WIDTH);i = i + 1) 
        begin
                    memory[i] <={WORD_WIDTH{1'b0}};
        end
    end 
    else if(wr_enbl) 
    begin 
       memory[wr_addr0][15:0] = wr_data0;
       memory[wr_addr1][15:0] = wr_data1;
    end
 end

endmodule