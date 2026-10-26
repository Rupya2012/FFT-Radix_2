module siso_64 (
    input clk,
    input rstn,
    input en,
    input [63:0] din,
    output reg [63:0] dout
);

always @(posedge clk) begin
    if (!rstn) begin
        dout <= 64'd0;
    end else if (en) begin
        dout <= din;
    end
end

endmodule

module siso_32 (
    input clk,
    input rstn,
    input en,
    input [31:0] din,
    output reg [31:0] dout
);

always @(posedge clk) begin
    if (!rstn) begin
        dout <= 32'h00004000; // Reset to Q1.14 representation of 1.0 (real=16384, imag=0)
    end else if (en) begin
        dout <= din;
    end
end

endmodule
