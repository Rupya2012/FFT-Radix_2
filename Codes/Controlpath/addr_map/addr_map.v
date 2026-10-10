module addr_map #(ADDR_WIDTH = 12)(
  input [3:0] lvl, //current level (0 - 11)
  input [ADDR_WIDTH-1:0] addr_in0, //addr of PC
  input [ADDR_WIDTH-1:0] addr_in1, //addr of PC + 1
  output reg [ADDR_WIDTH-1:0] addr_out0, //addr of in0
  output reg [ADDR_WIDTH-1:0] addr_out1 //addr of in1
);

always @(*)
begin
  if(lvl == 4'h0 | lvl == 4'hB) //when at lvl 0 or 11 complete address is flipped
  begin
      addr_out0 = addr_in0[0:ADDR_WIDTH-1]>>2;
      addr_out1 = addr_in1[0:ADDR_WIDTH-1]>>2;
  end

  else if(lvl < 4'hB) // LSB lvl + 1 bits are flipped based on the current level
  begin
      addr_out0 = {addr_in0[ADDR_WIDTH-1:lvl + 1'b1], addr_in0[0:lvl]}>>2;
      addr_out1 = {addr_in1[ADDR_WIDTH-1:lvl + 1'b1], addr_in1[0:lvl]}>>2;
  end
end
endmodule