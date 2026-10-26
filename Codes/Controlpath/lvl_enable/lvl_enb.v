module lvl_enb #(
  parameter ADDR_WIDTH = 12
)(
  input clk,
  input rstn,
  input [3:0] lvl,
  input [ADDR_WIDTH-1:0] buff_ram_wr_addr,
  output reg lvl_enb
);

// reg [ADDR_WIDTH-1:0] end_addr;

// always @(*) begin
//   if (lvl <= 4'd1) begin
//     end_addr = 12'd2047;
//   end else begin
//     end_addr = 12'd2047 - (12'd1 << (lvl - 4'd2));
//   end
// end

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