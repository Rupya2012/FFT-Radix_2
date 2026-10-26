module tw_init_cycle #(
    parameter ADDR_WIDTH = 12
)(
    input clk,
    input rstn,
    input [3:0] lvl,
    input waste_cycle,
    output [ADDR_WIDTH-1:0] addr_tw_init
);

    assign addr_tw_init = 12'd3072 + (lvl - 4'd1);
  
endmodule
