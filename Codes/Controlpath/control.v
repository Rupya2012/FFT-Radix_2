module control #()(
input clk,
input rst,
output i_buff_read_sel,
output dff1_enb_d,
output dff2_enb_d,
output dff3_enb_t,
output mux_1x1_sel,
output mux_1x2_sel,
output mux_2x1_sel,
output mux_2x2_sel,
output mux_1w_sel,
output mux_2w_sel,
output wref_ff_enb,
output rd_enb,
output wr_enb,
output [11:0]rd_addr_i_ram,
output [12:0]rd_addr_buff_ram,
output [11:0]rd_addr_out_ram,
output [11:0]wr_addr_i_ram,
output [12:0]wr_addr_buff_ram,
output [11:0]wr_addr_out_ram,
);
wire [3:0]lvl;
wire rst_counter;
wire pc_enb;
wire [11:0]addr_0;
wire [11:0]addr_1;
wire [11:0]present_addr_0;
wire [11:0]present_addr_1;
wire [11:0]twiddle_addr;
wire [11:0]past_addr_0;
wire [11:0]past_addr_1;
wire mux_sel_1b;
wire [1:0]mux_sel_2b;
wire clock_count;
wire count_stage;

lvl_cnt lc(clk,rst,count,lvl,rst_counter);     //rst_counter is to reset counter to 0 after every level

counter ct(clk,rst,rst_count,);

update ud(clock_count,count_stage,pc_enb,mux_sel_2b,mux_sel_1b);

PC pc(clk,rst,pc_enb,addr_0,addr_1,twiddle_addr);

addr_map am(lvl,addr_0,addr_1,past_addr_0,past_addr_1);

mux_2 mx21 (mux_sel_1b,past_addr_0,past_addr_1,wr_addr);

mux4 mx41 (mux_sel_2b,present_addr_0,present_addr_1,twiddle_addr,rd_addr);

rd_wr_enb rwb(clk,rst,count,lvl,rd_enb,wr_enb);

mux_enb meb(clk,rst,i_buff_read_sel,dff1_enb_d,dff2_enb_d,dff3_enb_t,mux_1x1_sel,mux_1x2_sel,mux_2x1_sel,mux_2x2_sel,mux_1w_sel,mux_2w_sel,wref_ff_enb);

buff_addr_map bam(rst,pc_enb,rd_addr,wr_addr,rd_addr_buff_ram,wr_addr_buff_ram);

assign rd_addr_i_ram = rd_addr;
assign rd_addr_out_ram = rd_addr;
assign wr_addr_i_ram =wr_addr;
assign wr_addr_out_ram =wr_addr;

endmodule 