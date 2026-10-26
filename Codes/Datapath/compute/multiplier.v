module multiplier #(
    parameter TOTAL_WIDTH  = 32,
    parameter REAL_LENGTH  = 16,
    parameter FRACTIONAL_L = 14
)(
    input  [TOTAL_WIDTH-1:0] w1,
    input  [TOTAL_WIDTH-1:0] w2,
    output [TOTAL_WIDTH-1:0] y
);

    wire signed [REAL_LENGTH-1:0] w_r = w1[REAL_LENGTH-1 : 0];
    wire signed [REAL_LENGTH-1:0] w_i = w1[TOTAL_WIDTH-1 : REAL_LENGTH];

    wire signed [REAL_LENGTH-1:0] x_r = w2[REAL_LENGTH-1 : 0];
    wire signed [REAL_LENGTH-1:0] x_i = w2[TOTAL_WIDTH-1 : REAL_LENGTH];

    wire signed [REAL_LENGTH-1:0] y_r;
    wire signed [REAL_LENGTH-1:0] y_i;

    wire signed [(2*REAL_LENGTH)-1:0] temp_1;
    wire signed [(2*REAL_LENGTH)-1:0] temp_2;

    assign temp_1 = (w_r * x_r) - (w_i * x_i);
    assign temp_2 = (w_r * x_i) + (w_i * x_r);

    assign y_r = {temp_1[(2*REAL_LENGTH)-1], temp_1[REAL_LENGTH + FRACTIONAL_L - 2 : FRACTIONAL_L]};
    assign y_i = {temp_2[(2*REAL_LENGTH)-1], temp_2[REAL_LENGTH + FRACTIONAL_L - 2 : FRACTIONAL_L]};

    assign y = {y_i, y_r};

endmodule
