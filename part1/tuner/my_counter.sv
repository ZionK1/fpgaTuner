module my_counter
  #(parameter [31:0] max_val_p = 15
   ,parameter width_p = $clog2(max_val_p)  
    /* verilator lint_off WIDTHTRUNC */
   ,parameter [width_p-1:0] reset_val_p = '0
    )
    /* verilator lint_on WIDTHTRUNC */
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] up_i
   ,input [0:0] down_i
   ,output [width_p-1:0] count_o);

  localparam [width_p-1:0] max_val_lp = max_val_p[width_p-1:0];

   // Your code here:
  logic [width_p-1:0] temp_o;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin // If reset_i, set reset_val_p
      temp_o <= reset_val_p;
    end else if (up_i && !down_i) begin // If up_i == 1, count up
      if (temp_o == max_val_lp) begin
        temp_o <= '0;
      end else begin
        temp_o <= temp_o + 1'b1;
      end
    end else if (down_i && !up_i) begin // If down_i == 1, count down
      if (temp_o == 0) begin
        temp_o <= max_val_lp;
      end else begin
        temp_o <= temp_o - 1'b1;
      end
    end // Otherwise do nothing
  end

  assign count_o = temp_o;

endmodule