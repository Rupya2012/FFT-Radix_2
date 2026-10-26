module mux_ctrl_strl (
    input clk,
    input rstn,
    input [2:0] count_5,
    input [2:0] count_5_init,
    output reg dFF1_enbl_s_raw,
    output reg dFF2_enbl_s_raw,
    output reg mux1s_sel_raw,
    output reg mux2s_sel_raw
);

always @(*) begin
    if (!rstn) begin
        dFF1_enbl_s_raw = 1'b0;
        dFF2_enbl_s_raw = 1'b0;
        mux1s_sel_raw   = 1'b0;
        mux2s_sel_raw   = 1'b0;
    end
    else begin
        case (count_5)
            3'd1: begin
                // Write Word 0: select y1 outputs
                dFF1_enbl_s_raw = 1'b0;
                dFF2_enbl_s_raw = 1'b0;
                mux1s_sel_raw   = 1'b0;
                mux2s_sel_raw   = 1'b0;
            end

            3'd2: begin
                // Write Word 1: select y2 outputs
                dFF1_enbl_s_raw = 1'b0;
                dFF2_enbl_s_raw = 1'b0;
                mux1s_sel_raw   = 1'b1;
                mux2s_sel_raw   = 1'b1;
            end

            3'd3: begin
                dFF1_enbl_s_raw = 1'b0;
                dFF2_enbl_s_raw = 1'b0;
                mux1s_sel_raw   = 1'b0;
                mux2s_sel_raw   = 1'b0;
            end

            3'd4: begin
                // Latch Butterfly 0 output {y1[0], y2[0]} into sipo_y0_s at end of cycle 4
                dFF1_enbl_s_raw = 1'b1;
                dFF2_enbl_s_raw = 1'b0;
                mux1s_sel_raw   = 1'b0;
                mux2s_sel_raw   = 1'b0;
            end

            3'd5: begin
                // Shift Butterfly 0 into sipo_y1_s and latch Butterfly 1 into sipo_y0_s at end of cycle 5
                dFF1_enbl_s_raw = 1'b1;
                dFF2_enbl_s_raw = 1'b1;
                mux1s_sel_raw   = 1'b0;
                mux2s_sel_raw   = 1'b0;
            end

            default: begin
                dFF1_enbl_s_raw = 1'b0;
                dFF2_enbl_s_raw = 1'b0;
                mux1s_sel_raw   = 1'b0;
                mux2s_sel_raw   = 1'b0;
            end
        endcase
    end
end

endmodule

module mux_ctrl_str (
    input clk,
    input rstn,
    input [2:0] count_5,
    input [2:0] count_5_init,
    output dFF1_enbl_s_raw,
    output dFF2_enbl_s_raw,
    output mux1s_sel_raw,
    output mux2s_sel_raw
);
    mux_ctrl_strl u_strl (
        .clk(clk),
        .rstn(rstn),
        .count_5(count_5),
        .count_5_init(count_5_init),
        .dFF1_enbl_s_raw(dFF1_enbl_s_raw),
        .dFF2_enbl_s_raw(dFF2_enbl_s_raw),
        .mux1s_sel_raw(mux1s_sel_raw),
        .mux2s_sel_raw(mux2s_sel_raw)
    );
endmodule
