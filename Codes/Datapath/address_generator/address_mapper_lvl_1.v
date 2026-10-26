module address_mapper_lvl_1 #(
    parameter IN_WIDTH  = 12,
    parameter OUT_WIDTH = 11
)(
    input  wire [IN_WIDTH-1:0]  add_original,
    output wire [OUT_WIDTH-1:0] add
);

    integer i;
    reg [IN_WIDTH-1:0] reversed;

    always @(*) begin
        for (i = 0; i < IN_WIDTH; i = i + 1) begin
            reversed[i] = add_original[IN_WIDTH - 1 - i];
        end
    end

    assign add = reversed[IN_WIDTH-1 : IN_WIDTH - OUT_WIDTH];

endmodule
