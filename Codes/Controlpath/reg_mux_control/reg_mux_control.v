module reg_mux_control (
  input clk,
  input rstn,
  input [2:0] count_5,
  input [2:0] count_5_init,
  input [3:0] lvl,
  output reg i_buff_read_sel, // Selects IRAM (0) vs BUFF_MEM (1) read data
  output reg dFF1_enbl,        // Enable for SIPO Reg 0
  output reg dFF2_enbl,        // Enable for SIPO Reg 1
  output reg mux2x1_sel,       // Selects x1: Reg0 MSB32 (0) vs Reg1 LSB32 (1)
  output reg mux2x2_sel,       // Selects x2: Bypass MSB32 (0) vs Reg0 LSB32 (1)
  output reg dFFw_enbl,        // Enable for twiddle registers (MSB and LSB)
  output reg mux1w_sel,        // Selects twiddle: MSB32 (0) vs LSB32 (1)
  output reg wref_ff_enbl,     // Enable for reference twiddle register
  output reg mux2w_sel         // Selects Twiddle W: direct (0) vs multiplied (1)
);

always @(*) begin
  if (!rstn) begin 
    dFF1_enbl  = 1'b0;
    dFF2_enbl  = 1'b0;
    mux2x1_sel = 1'b0;
    mux2x2_sel = 1'b0;
    dFFw_enbl  = 1'b0;
    mux1w_sel  = 1'b0;
    mux2w_sel  = 1'b0;
  end
  else begin
    case (count_5)
      3'd1: begin
        dFF1_enbl  = 1'b0;
        dFF2_enbl  = 1'b0;
        dFFw_enbl  = 1'b0;
        mux2x1_sel = 1'b0;
        mux2x2_sel = 1'b0;
        mux1w_sel  = 1'b0;
        mux2w_sel  = 1'b0;
      end

      3'd2: begin
        dFF1_enbl  = 1'b0;
        dFF2_enbl  = 1'b0;
        dFFw_enbl  = (count_5_init == 3'd5); // Do not latch during init cycle 2 (reading reference twiddle)
        mux2x1_sel = 1'b0;
        mux2x2_sel = 1'b0;
        mux1w_sel  = 1'b0;
        mux2w_sel  = 1'b0;
      end

      3'd3: begin
        dFF1_enbl  = 1'b1; // Latches Word A read in cycle 2
        dFF2_enbl  = 1'b0;
        dFFw_enbl  = 1'b0;
        mux2x1_sel = 1'b0;
        mux2x2_sel = 1'b0;
        mux1w_sel  = 1'b0;
        mux2w_sel  = 1'b0;
      end

      3'd4: begin
        // Word B read in cycle 3 is on memory output
        // Compute Butterfly 0
        dFF1_enbl  = 1'b1; // Latches Word B into sipo_dout0
        dFF2_enbl  = 1'b1; // Shifts Word A into sipo_dout1
        dFFw_enbl  = 1'b0;
        mux2x1_sel = 1'b0;
        mux2x2_sel = 1'b0;
        mux1w_sel  = 1'b0;
        mux2w_sel  = 1'b0;
      end

      3'd5: begin
        // Compute Butterfly 1
        dFF1_enbl  = 1'b0;
        dFF2_enbl  = 1'b0;
        dFFw_enbl  = 1'b0;
        mux2x1_sel = 1'b1;
        mux2x2_sel = 1'b1;
        mux1w_sel  = 1'b1;
        mux2w_sel  = (lvl == 4'd1) ? 1'b0 : 1'b1;
      end

      default: begin
        dFF1_enbl  = 1'b0;
        dFF2_enbl  = 1'b0;
        dFFw_enbl  = 1'b0;
        mux2x1_sel = 1'b0;
        mux2x2_sel = 1'b0;
        mux1w_sel  = 1'b0;
        mux2w_sel  = 1'b0;
      end
    endcase
  end
end

always @(*) begin
  if (!rstn) begin
    wref_ff_enbl = 1'b0;
  end
  else begin 
    if (count_5_init == 3'd2) begin 
      wref_ff_enbl = 1'b1;
    end
    else begin 
      wref_ff_enbl = 1'b0;
    end
  end
end

always @(*) begin
  if (!rstn) begin
    i_buff_read_sel = 1'b0;
  end
  else if (lvl == 4'd1) begin 
    if (count_5 == 3'd2) begin 
      i_buff_read_sel = 1'b1; 
    end 
    else begin 
      i_buff_read_sel = 1'b0; 
    end
  end 
  else begin 
    i_buff_read_sel = 1'b1; 
  end
end

endmodule
