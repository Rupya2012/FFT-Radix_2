module sipo #(parameter DATA_WIDTH = 64)(
    input clk,
    input rstn,
    input en0_d,
    input en1_d,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout0,
    output reg [DATA_WIDTH-1:0] dout1
);

always @(posedge clk) begin
    if (!rstn) begin
        dout0 <= {DATA_WIDTH{1'b0}};
        dout1 <= {DATA_WIDTH{1'b0}};
    end else begin
        if (en1_d) dout1 <= dout0;
        if (en0_d) dout0 <= din;
    end
end

endmodule
