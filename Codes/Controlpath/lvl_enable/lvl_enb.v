module lvl_enb #(
  parameter ADDR_WIDTH = 12
)(
  input clk,
  input rstn,
  input [3:0] lvl,
  input [ADDR_WIDTH-1:0] buff_ram_wr_addr,
  output reg lvl_enb
);


always @(posedge clk) begin 
  if (!rstn) begin
    lvl_enb <= 1'b0;
  end
  else if (buff_ram_wr_addr == 12'd2047) begin 
    lvl_enb <= 1'b1;
  end
  else begin 
    lvl_enb <= 1'b0; 
  end
end 

endmodule