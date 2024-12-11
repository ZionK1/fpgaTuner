module delaybuffer
  #(parameter [31:0] width_p = 8
   ,parameter [31:0] delay_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [width_p - 1:0] data_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,output [0:0] valid_o 
  ,output [width_p - 1:0] data_o 
  ,input [0:0] ready_i
  );

  logic [$clog2(delay_p):0] addr;
  logic [width_p-1:0] ram_data_out;

  // addr counter
  counter #(
    .max_val_p(delay_p - 1),
    .width_p($clog2(delay_p) + 1),
    .reset_val_p('0)
  ) addr_counter (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .up_i(ready_o & valid_i),
    .down_i(1'b0),
    .count_o(addr)
  );

  // RAM
  ram_1r1w_sync #(
    .width_p(width_p),
    .depth_p(delay_p + 1)
  ) ram_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .wr_valid_i(valid_i & ready_o),
    .wr_data_i(data_i),
    .wr_addr_i(addr),
    .rd_valid_i(valid_i & ready_o),
    .rd_addr_i(addr),
    .rd_data_o(ram_data_out)
  );

  logic [0:0] valid_r;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_r <= 1'b0;   
    end
    else begin   
      if (ready_o) // If ready_o == 1, update data_o
        valid_r <= ready_o & valid_i;
    end
  end


  assign ready_o =  ~valid_o || ready_i;
  assign valid_o = valid_r;
  assign data_o = ram_data_out;
endmodule