module counter (
    input clk, 
    input rst, 
    input rst_clock_counter,
    input rst_count_stage,
    output reg [11:0]clock_count,
    output reg [2:0] count_stage
);

always@(posedge clk)begin
  if(!(rst || rst_counter))begin
     clock_count <= 0;    
     count_stage <=0; 
  end
  else begin
     clock_count <= clock_count + 1        //need to make rst_count_stage 0 for first clock cycle 
     if(!rst_count_stage)begin      
        count_stage <=0;
     end
     else count_stage <= count_stage + 1 ;
     end
end

endmodule