module storing_add #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 12
)(
    input clk,
    input rstn,
    input add_gen_en_s,       
    input [3:0] lvl,
    input add_0_1_s,          
    input counter_rst_s,
    output reg [ADDR_WIDTH-1:0] addr
);

    wire [ADDR_WIDTH-2:0] count_addr; 
    wire [ADDR_WIDTH-2:0] count_addr_lvl_1; 

    
    counter #(.WIDTH(ADDR_WIDTH-1)) u_counter_11 (
        .clk(clk),
        .rstn(rstn && !counter_rst_s),
        .en(add_gen_en_s),
        .count(count_addr)
    );
    
    wire [ADDR_WIDTH-1:0] full_addr_s = {count_addr, add_0_1_s};

    address_mapper_lvl_1 #(
        .IN_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(ADDR_WIDTH-1)
    ) br (
        .add_original(full_addr_s),
        .add(count_addr_lvl_1)
    );

    always @(*) begin
        case (lvl)
            4'd12: addr = {1'b0, add_0_1_s, count_addr[9:0]};
            4'd11: addr = {1'b0, count_addr[9], add_0_1_s, count_addr[8:0]};
            4'd10: addr = {1'b0, count_addr[9:8], add_0_1_s, count_addr[7:0]};
            4'd9:  addr = {1'b0, count_addr[9:7], add_0_1_s, count_addr[6:0]};
            4'd8:  addr = {1'b0, count_addr[9:6], add_0_1_s, count_addr[5:0]};
            4'd7:  addr = {1'b0, count_addr[9:5], add_0_1_s, count_addr[4:0]};
            4'd6:  addr = {1'b0, count_addr[9:4], add_0_1_s, count_addr[3:0]};
            4'd5:  addr = {1'b0, count_addr[9:3], add_0_1_s, count_addr[2:0]};
            4'd4:  addr = {1'b0, count_addr[9:2], add_0_1_s, count_addr[1:0]};
            4'd3:  addr = {1'b0, count_addr[9:1], add_0_1_s, count_addr[0]};
            4'd2:  addr = {1'b0, count_addr[9:0], add_0_1_s};
            4'd1:  addr = {1'b0, add_0_1_s, count_addr[9:0]};
            default: addr = {1'b0, count_addr[9:0], add_0_1_s};
        endcase
    end

endmodule