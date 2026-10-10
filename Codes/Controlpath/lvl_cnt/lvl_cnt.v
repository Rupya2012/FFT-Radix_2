module lvl_cnt (
    input clk, 
    input rst, 
    input [11:0] clock_count,
    output reg [3:0] lvl,
    output reg rst_clock_counter
);

always @(posedge clk)
begin
    if(!rst) begin
        lvl <= 4'h0;
        rst_counter <= 1;
    end
    else if(count == 12'h400) begin 
        lvl <= lvl + 1;
        rst_counter <=0;
    end
    else begin rst_counter <=1; end
end
endmodule