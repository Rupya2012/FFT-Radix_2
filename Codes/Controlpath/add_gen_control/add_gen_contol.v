module add_gen_contol (
  input clk,
  input rstn,
  input [3:0] lvl,
  input [2:0] count_5_init,
  input [2:0] count_5,
  output reg add_gen_en_l,
  output reg add_gen_en_s,
  output reg tw_count_en,
  output reg tw_en,
  output reg add_0_1_l,
  output reg add_0_1_s
);

always @(*) begin
  if (!rstn) begin
    add_gen_en_l = 1'b0;
    add_gen_en_s = 1'b0;
    tw_count_en  = 1'b0;
    tw_en        = 1'b0;
    add_0_1_l    = 1'b0;
    add_0_1_s    = 1'b0;
  end
  else begin
    case (count_5)
      3'd1: begin
        // Read Twiddle
        tw_en        = 1'b1;
        add_0_1_l    = 1'b0;
        add_gen_en_l = 1'b0;
        tw_count_en  = 1'b0;

        // Write Word 0 (BF0 output)
        add_0_1_s    = 1'b0;
        add_gen_en_s = 1'b0;
      end

      3'd2: begin
        // Read Word A
        tw_en        = 1'b0;
        add_0_1_l    = 1'b0;
        add_gen_en_l = 1'b0;
        tw_count_en  = 1'b0;

        // Write Word 1 (BF1 output) and increment store address counter
        add_0_1_s    = 1'b1;
        if (count_5_init == 3'd5) begin
          add_gen_en_s = 1'b1;
        end else begin
          add_gen_en_s = 1'b0;
        end
      end

      3'd3: begin
        // Read Word B and increment load address counter for next block
        tw_en        = 1'b0;
        add_0_1_l    = 1'b1;
        add_gen_en_l = 1'b1;
        tw_count_en  = 1'b0;

        // Store idle
        add_0_1_s    = 1'b0;
        add_gen_en_s = 1'b0;
      end

      3'd4: begin
        // Butterfly 0 compute
        tw_en        = 1'b0;
        add_0_1_l    = 1'b0;
        add_gen_en_l = 1'b0;
        tw_count_en  = 1'b0;

        add_0_1_s    = 1'b0;
        add_gen_en_s = 1'b0;
      end

      3'd5: begin
        // Butterfly 1 compute and increment twiddle counter
        tw_en        = 1'b0;
        add_0_1_l    = 1'b0;
        add_gen_en_l = 1'b0;
        tw_count_en  = 1'b1;

        add_0_1_s    = 1'b0;
        add_gen_en_s = 1'b0;
      end

      default: begin
        tw_en        = 1'b0;
        add_0_1_l    = 1'b0;
        add_gen_en_l = 1'b0;
        tw_count_en  = 1'b0;
        add_0_1_s    = 1'b0;
        add_gen_en_s = 1'b0;
      end
    endcase
  end
end

endmodule
