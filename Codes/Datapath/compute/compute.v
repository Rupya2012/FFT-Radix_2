module compute #(
    parameter DATA_WIDTH   = 32,
    parameter REAL_LENGTH  = 16,
    parameter FRACTIONAL_L = 14
)(
    input  [DATA_WIDTH-1:0] twiddle_factor,
    input  [DATA_WIDTH-1:0] x_1,
    input  [DATA_WIDTH-1:0] x_2,
    output [DATA_WIDTH-1:0] y_1,
    output [DATA_WIDTH-1:0] y_2
);

    wire signed [REAL_LENGTH-1:0] x1_real = x_1[REAL_LENGTH-1:0];
    wire signed [REAL_LENGTH-1:0] x1_imag = x_1[DATA_WIDTH-1:REAL_LENGTH];

    wire [DATA_WIDTH-1:0] mult_out;
    wire signed [REAL_LENGTH-1:0] mult_real = mult_out[REAL_LENGTH-1:0];
    wire signed [REAL_LENGTH-1:0] mult_imag = mult_out[DATA_WIDTH-1:REAL_LENGTH];

    multiplier #(
        .TOTAL_WIDTH(DATA_WIDTH),
        .REAL_LENGTH(REAL_LENGTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_mult (
        .w1(twiddle_factor),
        .w2(x_2),
        .y(mult_out)
    );

    wire signed [REAL_LENGTH:0] sum1_real  = {x1_real[REAL_LENGTH-1], x1_real} + {mult_real[REAL_LENGTH-1], mult_real};
    wire signed [REAL_LENGTH:0] sum1_imag  = {x1_imag[REAL_LENGTH-1], x1_imag} + {mult_imag[REAL_LENGTH-1], mult_imag};
    wire signed [REAL_LENGTH:0] diff2_real = {x1_real[REAL_LENGTH-1], x1_real} - {mult_real[REAL_LENGTH-1], mult_real};
    wire signed [REAL_LENGTH:0] diff2_imag = {x1_imag[REAL_LENGTH-1], x1_imag} - {mult_imag[REAL_LENGTH-1], mult_imag};

    assign y_1 = {sum1_imag[REAL_LENGTH:1], sum1_real[REAL_LENGTH:1]};
    assign y_2 = {diff2_imag[REAL_LENGTH:1], diff2_real[REAL_LENGTH:1]};

endmodule