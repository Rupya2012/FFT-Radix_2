module r_w_enb (
  input clk,
  input rstn,
  input [3:0] lvl,
  input [2:0] count_5_init,
  input [2:0] count_5,
  output reg iram_rd_enbl,
  output iram_wr_enbl,
  output reg buff_rd_enbl,
  output reg buff_wr_enbl,
  output oram_rd_enbl,
  output reg oram_wr_enbl
);
  
assign iram_wr_enbl = 1'b0;
assign oram_rd_enbl = 1'b0;

always @(*) begin
  if (!rstn) begin
    buff_rd_enbl = 1'b0;
    iram_rd_enbl = 1'b0;
    buff_wr_enbl = 1'b0;
    oram_wr_enbl = 1'b0;
  end
  else begin
    buff_rd_enbl = 1'b1;
    if (lvl == 4'd1) begin
      if (count_5 == 3'd2 || count_5 == 3'd3) begin
        iram_rd_enbl = 1'b1;
      end else begin
        iram_rd_enbl = 1'b0;
      end
    end else begin
      iram_rd_enbl = 1'b0;
    end

    // Write enables: active during Cycle 1 and Cycle 2 (after count_5_init == 5)
    if (count_5_init == 3'd5 && (count_5 == 3'd1 || count_5 == 3'd2)) begin
      if (lvl == 4'd12) begin
        buff_wr_enbl = 1'b0;
        oram_wr_enbl = 1'b1;
      end else begin
        buff_wr_enbl = 1'b1;
        oram_wr_enbl = 1'b0;
      end
    end else begin
      buff_wr_enbl = 1'b0;
      oram_wr_enbl = 1'b0;
    end
  end
end

endmodule
