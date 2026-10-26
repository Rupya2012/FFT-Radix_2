module counter #(
    parameter WIDTH = 10
)(
    input clk,
    input rstn,
    input en,
    output reg [WIDTH-1:0] count
);

    always @(posedge clk) begin
        if (!rstn) begin
            count <= {WIDTH{1'b0}};
        end else if (en) begin
            count <= count + 1'b1;
        end
    end

endmodule

module counter_10 #(parameter WIDTH = 10)(
    input clk,
    input rstn,
    input en,
    output [WIDTH-1:0] count
);
    counter #(.WIDTH(WIDTH)) u_cnt (.clk(clk), .rstn(rstn), .en(en), .count(count));
endmodule

module counter_11 (
    input clk,
    input rstn,
    input en,
    output [10:0] count
);
    counter #(.WIDTH(11)) u_cnt (.clk(clk), .rstn(rstn), .en(en), .count(count));
endmodule

module counter_9 (
    input clk,
    input rstn,
    input en,
    output [8:0] count
);
    counter #(.WIDTH(9)) u_cnt (.clk(clk), .rstn(rstn), .en(en), .count(count));
endmodule
