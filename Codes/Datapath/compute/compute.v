module multiply_fixed_point#(parameter REAL_LENGTH=8,parameter FRACTIONAL_L=5)(
    input signed [REAL_LENGTH-1:0] w_r,
    input signed [REAL_LENGTH-1:0] w_i,
    input signed [REAL_LENGTH-1:0] x_r,
    input signed [REAL_LENGTH-1:0] x_i,
    output signed [REAL_LENGTH-1:0] y_r,
    output signed [REAL_LENGTH-1:0] y_i,
);

wire temp_1[REAL_LENGTH*2-1:0];
wire temp_2[REAL_LENGTH*2-1:0];
assign temp_1=(w_r * y_r) - (w_i * y_i);
assign temp_2=(w_r * y_i) + (w_i * y_r);
assign y_r = {temp_1[REAL_LENGTH*2-1],temp_1[REAL_LENGTH + FRACTIONAL_L -2:FRACTIONAL_L]};
assign y_i = {temp_2[REAL_LENGTH*2-1],temp_2[REAL_LENGTH + FRACTIONAL_L -2 :FRACTIONAL_L]};
endmodule

module compute#(parameter FIXEDPOINT=16,parameter FRACTIONAL_L=5,parameter REAL_LENGTH=8) (
    input [FIXEDPOINT-1:0] twiddle_factor,
    input [FIXEDPOINT-1:0] x_1,
    input [FIXEDPOINT-1:0] x_2,
    output [FIXEDPOINT-1:0] y_1,
    output  [FIXEDPOINT-1:0] y_2
);
wire x1_real = x_1[FIXEDPOINT-1:REAL_LENGTH];
wire x2_real = x_2[FIXEDPOINT-1:REAL_LENGTH];
wire twiddle_factor_real = twiddle_factor[FIXEDPOINT-1:REAL_LENGTH];
wire x2_imag = x_1[REAL_LENGTH-1:0];
wire x2_imag = x_2[REAL_LENGTH-1:0];
wire twiddle_factor_imag = twiddle_factor[REAL_LENGTH-1:0];
wire real_part_trunc,imag_part_trunc;
multiply_fixed_point(twiddle_factor_real,twiddle_factor_imag,x2_real,x2_imag,real_part_trunc,imag_part_trunc);
assign y_1[FIXEDPOINT-1:REAL_LENGTH] = x1_real + real_part_trunc;
assign y_1[REAL_LENGTH-1:0] = x1_imag+multiply_3 + imag_part_trunc;
assign y_2[FIXEDPOINT-1:REAL_LENGTH] = x1_real - real_part_trunc;
assign y_2[REAL_LENGTH-1:0] = x1_imag-multiply_3 - imag_part_trunc;
endmodule