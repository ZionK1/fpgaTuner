module tuner
 #(parameter int_in_lp = 1
  ,parameter frac_in_lp = 11
  ) 
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [int_in_lp - 1 : -frac_in_lp] audio_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,output [7 : 0] ssd_o
  );

   assign ready_o = 1;
endmodule
