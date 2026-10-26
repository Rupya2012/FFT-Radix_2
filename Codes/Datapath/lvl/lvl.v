module lvl (
    input clk,
    input rstn,
    input lvl_enb,
    output reg [3:0] lvl
);

always @(posedge clk) begin
    if (!rstn) begin
        lvl <= 4'd1;
    end
    else begin
        if (lvl_enb) begin
            if (lvl < 4'd12) begin
                lvl <= lvl + 4'd1;
            end
            else begin
                lvl <= 4'd12;
            end
        end
    end
end

endmodule