module mux4 #(parameter DATA_WIDTH = 8) (
    input [DATA_WIDTH-1:0] in0, in1, in2, in3,
    input [1:0] sel,
    output [DATA_WIDTH-1:0] out
);
    wire [DATA_WIDTH-1 : 0] mux_low, mux_high;

    mux2 #(.DATA_WIDTH(DATA_WIDTH)) mux_upper 
    (   .in0(in0),
        .in1(in1),
        .sel(sel[0]),
        .out(mux_high)
    );

    mux2 #(.DATA_WIDTH(DATA_WIDTH)) mux_lower 
    (
        .in0(in2),
        .in1(in3),
        .sel(sel[0]),
        .out(mux_low)
    );

    mux2 #(.DATA_WIDTH(DATA_WIDTH)) mux_final 
    (
        .in0(mux_high),
        .in1(mux_low),
        .sel(sel[1]),
        .out(out)
    );
endmodule