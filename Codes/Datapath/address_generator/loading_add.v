module loading_add #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 12
)(
    input clk,
    input rstn,
    input add_gen_en_l,       // control
    input [3:0] lvl,          // datapath
    input add_0_1_l,          // control
    input tw_count_en,              // control
    input counter_rst_l,
    output count_addr_0,
    output reg [ADDR_WIDTH-1:0] data_addr,
    output reg [ADDR_WIDTH-1:0] tw_addr
);

    wire [ADDR_WIDTH-2:0] count_addr; 
    wire [8:0] tw_cnt = count_addr[9:1];    
    wire [ADDR_WIDTH-2:0] lvl1_add;            

    assign count_addr_0 = count_addr[0];

    counter #(.WIDTH(ADDR_WIDTH-1)) u_counter_11(
        .clk(clk),
        .rstn(rstn && !counter_rst_l),
        .en(add_gen_en_l),
        .count(count_addr)
    );

    wire [ADDR_WIDTH-1:0] full_addr_lvl1 = {count_addr, add_0_1_l};

    address_mapper_lvl_1 #(
        .IN_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(ADDR_WIDTH-1)
    ) br (
        .add_original(full_addr_lvl1),
        .add(lvl1_add)
    );

    always @(*) begin
        case (lvl)
            4'd12: data_addr = {1'b0, add_0_1_l, count_addr[9:0]};
            4'd11: data_addr = {1'b0, count_addr[9], add_0_1_l, count_addr[8:0]};
            4'd10: data_addr = {1'b0, count_addr[9:8], add_0_1_l, count_addr[7:0]};
            4'd9:  data_addr = {1'b0, count_addr[9:7], add_0_1_l, count_addr[6:0]};
            4'd8:  data_addr = {1'b0, count_addr[9:6], add_0_1_l, count_addr[5:0]};
            4'd7:  data_addr = {1'b0, count_addr[9:5], add_0_1_l, count_addr[4:0]};
            4'd6:  data_addr = {1'b0, count_addr[9:4], add_0_1_l, count_addr[3:0]};
            4'd5:  data_addr = {1'b0, count_addr[9:3], add_0_1_l, count_addr[2:0]};
            4'd4:  data_addr = {1'b0, count_addr[9:2], add_0_1_l, count_addr[1:0]};
            4'd3:  data_addr = {1'b0, count_addr[9:1], add_0_1_l, count_addr[0]};
            4'd2:  data_addr = {1'b0, count_addr[9:0], add_0_1_l};
            4'd1:  data_addr = {1'b0, lvl1_add[ADDR_WIDTH-2:0]};
            default: data_addr = {1'b0, count_addr[9:0], add_0_1_l};
        endcase
    end

    always @(*) begin
        case (lvl)
            4'd12: tw_addr = {1'b1, 1'b0, 1'b0, tw_cnt[8:0]};
            4'd11: tw_addr = {1'b1, 1'b0, 1'b1, 1'b0, tw_cnt[7:0]};
            4'd10: tw_addr = {1'b1, 1'b0, 2'b11, 1'b0, tw_cnt[6:0]};
            4'd9:  tw_addr = {1'b1, 1'b0, 3'b111, 1'b0, tw_cnt[5:0]};
            4'd8:  tw_addr = {1'b1, 1'b0, 4'b1111, 1'b0, tw_cnt[4:0]};
            4'd7:  tw_addr = {1'b1, 1'b0, 5'b11111, 1'b0, tw_cnt[3:0]};
            4'd6:  tw_addr = {1'b1, 1'b0, 6'b111111, 1'b0, tw_cnt[2:0]};
            4'd5:  tw_addr = {1'b1, 1'b0, 7'b1111111, 1'b0, tw_cnt[1:0]};
            4'd4:  tw_addr = {1'b1, 1'b0, 8'b11111111, 1'b0, tw_cnt[0]};
            4'd3:  tw_addr = {1'b1, 1'b0, 9'b111111111, 1'b0};
            4'd2:  tw_addr = {1'b1, 1'b0, 10'b1111111111};
            4'd1:  tw_addr = {1'b1, 1'b1, 10'b1111111111};
            default: tw_addr = {ADDR_WIDTH{1'b1}};
        endcase
    end

endmodule
