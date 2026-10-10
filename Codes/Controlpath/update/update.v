module update #()(
input [11:0] clock_count,
input [2:0]  count_stage,
output reg pc_enb, //active high
output reg [1:0]mux_sel_2b,
output reg mux_sel_1b
);
[]
always@(*)begin 
if(!clock_count) begin 
   pc_enb <=0;
end
else if(count_stage == 0) begin pc_enb <= 0 ; end
else pc_enb <=1;
end

always@(*)begin 
if(clock_count && (count_stage == 3)) begin mux_sel_1b <=0 ;end
else mux_sel_1b <=1;
end

always@(*)begin 
if(clock_count && (count_stage == 0)) begin mux_sel_2b <= 2'b10 ; end
else if (clock_count && ((count_stage == 1) || (count_stage == 3) ))begin mux_sel_2b = 2'b00; end 
else begin mux_sel_2b = 2'b01; end 
end

endmodule