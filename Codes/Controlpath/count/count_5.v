module count_5 (
  input clk,
  input rstn,
  input lvl_enb,
  output reg [2:0] count_5
);

always @(posedge clk) begin
  if (!rstn) begin
    count_5 <= 3'd0;
  end
  else begin
    if (lvl_enb) begin
      count_5 <= 3'd0;
    end
    else if (count_5 == 3'd5) begin 
      count_5 <= 3'd1;
    end
    else begin 
      count_5 <= count_5 + 3'd1; 
    end
  end
end

endmodule
