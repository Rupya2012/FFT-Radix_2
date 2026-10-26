module count_5_init (
  input clk,
  input rstn,
  input lvl_enb,
  output reg [2:0] count_5_init,
  output reg lvl_change,
  output reg waste_cycle,
  output reg counter_rst_l,
  output reg counter_rst_s
);

always @(posedge clk) begin
  if (!rstn) begin
    count_5_init  <= 3'd0;
    lvl_change    <= 1'b1;
    counter_rst_l <= 1'b1;
    counter_rst_s <= 1'b1;
  end
  else begin
    if (lvl_enb) begin
      count_5_init  <= 3'd0;
      lvl_change    <= 1'b1;
      counter_rst_l <= 1'b1;
      counter_rst_s <= 1'b1;
    end
    else if (count_5_init != 3'd5) begin 
      count_5_init  <= count_5_init + 3'd1;
      lvl_change    <= 1'b0;
      counter_rst_l <= 1'b0;
      counter_rst_s <= 1'b0;
    end
    else begin
      lvl_change    <= 1'b0;
      counter_rst_l <= 1'b0;
      counter_rst_s <= 1'b0;
    end
  end
end

always @(*) begin
  waste_cycle = (count_5_init == 3'd1);
end

endmodule
