// division with power to two every level.

module datapath (#parameter ADDR_WIDTH = 12, parameter WORD_WIDTH = 16, parameter BUFF_RAM_WORD_WIDTH = 32, parameter IRAM_LOG_BLOCK_SIZE = 2, parameter FRACTIONAL_L = 5, REAL_LENGTH = 8, FIXEDPOINT = 16)(
    input clk, 
    input rst, 

    //signals to iram module
    output iram_wr_addr0 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output iram_wr_addr1 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output addr_map_addr_out0 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output addr_map_addr_out1 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output [WORD_WIDTH-1:0] iram_wr_data0, 
    output [WORD_WIDTH-1:0] iram_wr_data1, 
    input [WORD_WIDTH-1:0] iram_rd_data0, ////////////////////////////////////
    input [WORD_WIDTH-1:0] iram_rd_data1 ////////////////////////////////////

    //signals to oram module
    output oram_wr_addr0 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output oram_wr_addr1 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output oram_rd_addr0 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output oram_rd_addr1 [ADDR_WIDTH-1:IRAM_LOG_BLOCK_SIZE],
    output compute_out0,
    output compute_out1,
    input [WORD_WIDTH-1:0] oram_rd_data0, ////////////////////////////////////
    input [WORD_WIDTH-1:0] oram_rd_data1 ////////////////////////////////////

    //Signals from Control Unit
    
    //pc_cnt
    input pc_enbl;

    //lvl_cnt
    input lvl_cnt_clr
    input lvl_cnt_enbl 

    //buff_mem
    input buff_mem_rd_enbl,
    input buff_mem_wr_enbl,

    //buff iram data mux control
    input buff_to_reg,
);

//wires and reg for pc_counter
wire [ADDR_WIDTH-1:0] pc_addr_out0;
wire [ADDR_WIDTH-1:0] pc_addr_out1;
reg [ADDR_WIDTH-1:0] delayed_pc_addr_out0;
reg [ADDR_WIDTH-1:0] delayed_pc_addr_out1;


//Instantiating PC counter
pc_cnt #(ADDR_WIDTH.(ADDR_WIDTH)) pc_counter (
    clk.(clk),
    rst.(rst),// is it synchornous or asynchornous ??
    pc_enbl.(pc_enbl),
    pc_addr_out0.(pc_addr_out0),
    pc_addr_out1.(pc_addr_out1)
);

//wires for level counter
wire [3:0] lvl;

//Instantiating level Counter
lvl_cnt (
    clk.(clk), 
    rst.(rst),
    lvl_cnt_clr.(lvl_cnt_clr), 
    lvl_cnt_enbl.(lvl_cnt_enbl),
    lvl.(lvl)
);

//wires for addr mapper
wire [ADDR_WIDTH-1:0] addr_out0.(addr_map_addr_out0);
wire [ADDR_WIDTH-1:0] addr_out1.(addr_map_addr_out1);

//Instantiating addr mapper
addr_map #(ADDR_WIDTH.(ADDR_WIDTH)) addr_mapper(
  lvl.(lvl), 
  addr_in0.(pc_addr_in0),
  addr_in1.(pc_addr_in1), 
  addr_out0.(addr_map_addr_out0),
  addr_out1.(addr_map_addr_out1) 
);

//wires for iram data mapping
wire [WORD_WIDTH-1:0] iram_to_reg_data0;
wire [WORD_WIDTH-1:0] iram_to_reg_data1;

//IRAM data mapping
mux4 #(DATA_WIDTH.(WORD_WIDTH)) iram_data0_mux4 (
    in0.(iram_rd_data0[WORD_WIDTH-1:0]),
    in1.(iram_rd_data0[(WORD_WIDTH << 1)-1:WORD_WIDTH]),
    in2.(iram_rd_data0[(WORD_WIDTH << 1)+WORD_WIDTH-1 : (WORD_WIDTH << 1) ]),
    in3.(iram_rd_data0[(WORD_WIDTH << 2)-1:(WORD_WIDTH << 1)+WORD_WIDTH]),
    sel.(addr_map_addr_out0[IRAM_LOG_BLOCK_SIZE-1:0]),
    out.(iram_to_mux_data0)
);

//IRAM data mapping
mux4 #(DATA_WIDTH.(WORD_WIDTH)) iram_data1_mux4 (
    in0.(iram_rd_data1[WORD_WIDTH-1:0]),
    in1.(iram_rd_data1[(WORD_WIDTH << 1)-1:WORD_WIDTH]),
    in2.(iram_rd_data1[(WORD_WIDTH << 1)+WORD_WIDTH-1 : (WORD_WIDTH << 1) ]),
    in3.(iram_rd_data1[(WORD_WIDTH << 2)-1:(WORD_WIDTH << 1)+WORD_WIDTH]),
    sel.(addr_map_addr_out1[IRAM_LOG_BLOCK_SIZE-1:0]),
    out.(iram_to_mux_data1)
);

//wires for buff_ram module
wire [WORD_WIDTH-1:0] buff_mem_rd_data0;
wire [WORD_WIDTH-1:0] buff_mem_rd_data1;

//Instantiating buff_ram module
buff_mem (ADDR_WIDTH.(ADDR_WIDTH), WORD_WIDTH.(BUFF_RAM_WORD_WIDTH)) buff_memory(
    clk.(clk), 
    rst.(rst),//active high 
    rd_enbl.(buff_mem_rd_enbl),
    wr_enbl.(buff_mem_wr_enbl),
    wr_addr0.(delayed_pc_addr_out0),  
    wr_addr1.(delayed_pc_addr_out1), 
    rd_addr0.(pc_addr_out0),
    rd_addr1.(pc_addr_out1),
    wr_data0.(compute_out0),
    wr_data1.(compute_out1),
    rd_data0.(buff_mem_rd_data0),
    rd_data1.(buff_mem_rd_data1)
);

//wires for iram and buff ram mux
wire [WORD_WIDTH-1:0] buff_iram_mux_data0_out;
wire [WORD_WIDTH-1:0] buff_iram_mux_data1_out;

//Data mapping between iram and buff ram
mux2 #(DATA_WIDTH.(WORD_WIDTH)) buff_iram_data0_mux(
    in0.(iram_to_mux_data0),
    in1.(buff_mem_rd_data0),
    sel.(buff_to_reg),
    out.(buff_iram_mux_data0_out)
);

mux2 #(DATA_WIDTH.(WORD_WIDTH)) buff_iram_data1_mux(
    in0.(iram_to_mux_data1),
    in1.(buff_mem_rd_data1),
    sel.(buff_to_reg),
    out.(buff_iram_mux_data1_out)
);

//register file to store the compute in0 and in1
reg [WORD_WIDTH-1:0] compute_in0;
reg [WORD_WIDTH-1:0] compute in1;

always @(posedge clk)
begin
    if(rst)
    begin
        compute_in0 <= {WORD_WIDTH{1'b0}};
        compute_in1 <= {WORD_WIDTH{1'b0}};
    end
    else
    begin
        compute_in0 <= buff_iram_mux_data0_out;
        compute_in1 <= buff_iram_mux_data1_out;
    end
end

//wires for compute module
wire [WORD_WIDTH] compute_out0;
wire [WORD_WIDTH] compute_out1;

compute #(FIXEDPOINT.(FIXEDPOINT),FRACTIONAL_L.(FRACTIONAL_L),REAL_LENGTH.(REAL_LENGTH)) compute_module (
    twiddle_factor.(twiddle_factor),
    x_1.(compute_in0),
    x_2.(compute_in1),
    y_1.(compute_out0),
    y_2.(compute_out1)
);



endmodule 
