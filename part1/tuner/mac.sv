`timescale 1ns/1ps
module mac
 #(parameter int_in_lp = 1
  ,parameter frac_in_lp = 11
  ,parameter int_out_lp = 10
  ,parameter frac_out_lp = 22
  ) 
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input signed [int_in_lp - 1 : -frac_in_lp] a_i
  ,input signed [int_in_lp - 1 : -frac_in_lp] b_i
  ,input signed [int_out_lp - 1 : -frac_out_lp] db_i
  ,output signed [int_out_lp - 1 : -frac_out_lp] data_o
  );

  /*
  logic [0:0] valid_r;

  // Ready-valid handshake logic
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_r <= 1'b0;
    end
    else begin
      if (ready_o) begin
        valid_r <= ready_o && valid_i;
      end
    end
  end 

  assign ready_o = !valid_r || ready_i;
  assign valid_o = valid_r; */

  /*
  DSP48A1 #(
    .A0REG(1'b0),
    .A1REG(1'b0),
    .B0REG(1'b0),
    .B1REG(1'b0),
    .CREG(1'b0),
    .DREG(1'b0),
    .MREG(1'b0),
    .PREG(1'b1), // disable all registers except for PREG
    .CARRYINREG(1'b0),
    .CARRYOUTREG(1'b0),
    .OPMODEREG(1'b0)
  ) DSP_inst (
    .D('0),
    .A({{(18-int_in_lp-frac_in_lp){a_i[int_in_lp-1]}}, a_i}),
    .B({{(18-int_in_lp-frac_in_lp){b_i[int_in_lp-1]}}, b_i}),
    //.A(a_i),
    //.B(b_i),
    .C('0),
    .OPMODE(8'b00001001), // Use P output for accumulator and add to multiplier product
    .CLK(clk_i),
    .RSTP(reset_i),
    .CEP(ready_o && valid_i),
    .P(data_o) // No lint error finally, able to pass to c_o directly
  ); */

  logic signed [(int_in_lp * 2)-1: -(frac_in_lp * 2)] prod;

  always_comb begin
    prod = a_i * b_i;
  end

  generate
      if ((int_in_lp*2) == int_out_lp) begin : gen_accum
        assign data_o = prod + db_i;
      end else begin : gen_accum2
        assign data_o = {{{(int_out_lp-(int_in_lp*2)){prod[int_in_lp-1]}}}, prod} + db_i;
      end
  endgenerate

endmodule