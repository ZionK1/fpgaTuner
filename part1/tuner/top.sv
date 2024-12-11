// Top-level design file for the icebreaker FPGA board
module top
  (input [0:0] clk_12mhz_i
  // n: Negative Polarity (0 when pressed, 1 otherwise)
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced
  ,input [0:0] reset_n_async_unsafe_i
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced
  ,input [3:1] button_async_unsafe_i

  // Line Out (Green)
  // Main clock (for synchronization)
  ,output tx_main_clk_o
  // Selects between L/R channels, but called a "clock"
  ,output tx_lr_clk_o
  // Data clock
  ,output tx_data_clk_o
  // Output Data
  ,output tx_data_o

  // Line In (Blue)
  // Main clock (for synchronization)
  ,output rx_main_clk_o
  // Selects between L/R channels, but called a "clock"
  ,output rx_lr_clk_o
  // Data clock
  ,output rx_data_clk_o
  // Input data
  ,input  rx_data_i

  ,output [7:0] ssd_o
  ,output [5:1] led_o);

   wire        clk_o;

   // These two D Flip Flops form what is known as a Synchronizer. We
   // will learn about these in Week 5, but you can see more here:
   // https://inst.eecs.berkeley.edu/~cs150/sp12/agenda/lec/lec16-synch.pdf
   wire reset_n_sync_r;
   wire reset_sync_r;
   wire reset_r; // Use this as your reset_signal

   dff
     #()
   sync_a
     (.clk_i(clk_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_n_async_unsafe_i)
     ,.q_o(reset_n_sync_r));

   inv
     #()
   inv
     (.a_i(reset_n_sync_r)
     ,.b_o(reset_sync_r));

   dff
     #()
   sync_b
     (.clk_i(clk_o)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_sync_r)
     ,.q_o(reset_r));
       
   wire [31:0] axis_tx_data;
   wire        axis_tx_valid;
   wire        axis_tx_ready;
   wire        axis_tx_last;
   
   wire [31:0] axis_rx_data;
   wire        axis_rx_valid;
   wire        axis_rx_ready;
   wire        axis_rx_last;

  (* blackbox *)
  // This is a PLL! You'll learn about these later...
  SB_PLL40_PAD 
    #(.FEEDBACK_PATH("SIMPLE")
     ,.PLLOUT_SELECT("GENCLK")
     ,.DIVR(4'b0000)
     ,.DIVF(7'd59)
     ,.DIVQ(3'd5)
     ,.FILTER_RANGE(3'b001)
     )
   pll_inst
     (.PACKAGEPIN(clk_12mhz_i)
     ,.PLLOUTCORE(clk_o)
     ,.RESETB(1'b1)
     ,.BYPASS(1'b0)
     );
  
   assign axis_clk = clk_o;

   assign axis_tx_data[31:24] = 8'b0;
   axis_i2s2 
     #()
   i2s2_inst
     (.axis_clk(axis_clk)
     ,.axis_resetn(~reset_r)
      
     ,.tx_axis_c_data(axis_tx_data)
     ,.tx_axis_c_valid(axis_tx_valid)
     ,.tx_axis_c_ready(axis_tx_ready)
     ,.tx_axis_c_last(axis_tx_last)
     
     ,.rx_axis_p_data(axis_rx_data)
     ,.rx_axis_p_valid(axis_rx_valid)
     ,.rx_axis_p_ready(axis_rx_ready)
     ,.rx_axis_p_last(axis_rx_last)
     
     ,.tx_mclk(tx_main_clk_o)
     ,.tx_lrck(tx_lr_clk_o)
     ,.tx_sclk(tx_data_clk_o)
     ,.tx_sdout(tx_data_o)
     ,.rx_mclk(rx_main_clk_o)
     ,.rx_lrck(rx_lr_clk_o)
     ,.rx_sclk(rx_data_clk_o)
     ,.rx_sdin(rx_data_i)
     );


/*   assign axis_tx_data = axis_rx_data;
   assign axis_tx_last = axis_rx_last;
   assign axis_tx_valid = axis_rx_valid;
   assign axis_rx_ready = axis_tx_ready;
   assign axis_tx_data = axis_rx_data;
*/
   // Input Interface (l for local)
   wire [0:0]        valid_li;
   wire [0:0]        ready_lo;

   wire [23:0] data_right_li;
   wire [23:0] data_left_li;

   // Output Interface (l for local)
   wire [0:0]        valid_lo;
   wire [0:0]        ready_li;        

   wire [23:0] data_right_lo;
   wire [23:0] data_left_lo;

   // Serial in, Parallel out
   sipo
    #()
   sipo_inst
     (.clk_i                            (clk_o)
     ,.reset_i                          (reset_r)
      // Outputs (Input Interface to your module)
     ,.\data_o[1]                       (data_right_li)
     ,.\data_o[0]                       (data_left_li)
     ,.v_o                              (valid_li)
     ,.ready_i                          (ready_lo & valid_li)
     // Inputs (Don't worry about these)
     ,.ready_and_o                      (axis_rx_ready)
     ,.data_i                           (axis_rx_data[23:0])
     ,.v_i                              (axis_rx_valid)
     );

   // Parallel in, Serial out
   piso
    #()
   piso_inst
     (.clk_i                            (clk_o)
     ,.reset_i                          (reset_r)
     // Outputs (Don't worry about these)
     // Use the low-order bit to signal last
     ,.data_o                           ({axis_tx_data[23:0], axis_tx_last})
     ,.valid_o                          (axis_tx_valid)
     ,.ready_i                          (axis_tx_ready)
     // Inputs (Output interface from your module)
     ,.\data_i[1]                       ({data_right_lo, 1'b1})
     ,.\data_i[0]                       ({data_left_lo, 1'b0})
     ,.valid_i                          (valid_lo)
     ,.ready_and_o                      (ready_li)
     );

   // Your code goes here

  // Sinusoids for all 11 notes --------------------------------------------------------------------------
  logic [11:0] sine_a;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(880)
  )
  sinusoid_inst1 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_a),
    .valid_o()
  );

  logic [11:0] sine_bflat;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(939)
  )
  sinusoid_inst2 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_bflat),
    .valid_o()
  );

  logic [11:0] sine_b;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(988)
  ) sinusoid_inst3 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_b),
    .valid_o()
  );

  logic [11:0] sine_c;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(523)
  ) sinusoid_inst4 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_c),
    .valid_o()
  );

  logic [11:0] sine_csharp;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(559)
  ) sinusoid_inst5 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_csharp),
    .valid_o()
  );

  logic [11:0] sine_d;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(589)
  ) sinusoid_inst6 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_d),
    .valid_o()
  );

  logic [11:0] sine_eflat;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(622.3)
  ) sinusoid_inst7 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_eflat),
    .valid_o()
  );

  logic [11:0] sine_f;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(701)
  ) sinusoid_inst8 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_f),
    .valid_o()
  );

  logic [11:0] sine_fsharp;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(748)
  ) sinusoid_inst9 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_fsharp),
    .valid_o()
  );

  logic [11:0] sine_g;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(784)
  ) sinusoid_inst10 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_g),
    .valid_o()
  );

  logic [11:0] sine_gsharp;
  sinusoid #(
    .sampling_freq_p(44.1 * 10 ** 3),
    .note_freq_p(833)
  ) sinusoid_inst11 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .ready_i(valid_li & ready_lo),    
    .data_o(sine_gsharp),
    .valid_o()
  );

  // test for audio from sinusoids
  /*
  assign valid_lo = valid_li;
  assign data_left_lo = {sine_curr, 12'b0};
  assign data_right_lo = data_left_lo; 
  */

  // sinusoid logic
  logic [11:0] sine_curr;
  logic [3:0] sine_counter; 
  logic [0:0] dup_valid_o, dup_ready_i; // output of duplicator

  // renamed counter due to naming conflict warning
  my_counter 
    #(.max_val_p(11)) // width_p becomes 4
  counter_inst1 (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .up_i(dup_valid_o & dup_ready_i),    // check if rv is from I2S2 or delaybuffer
    .down_i(1'b0),
    .count_o(sine_counter)
  );

  // mux for sinusoid input to mac
  always_comb begin
    sine_curr = '0;

    if (sine_counter == 0) begin      // A
      sine_curr = sine_a;
    end else if (sine_counter == 1) begin  // Bb
      sine_curr = sine_bflat;
    end else if (sine_counter == 2) begin  // B
      sine_curr = sine_b;
    end else if (sine_counter == 3) begin  // C
      sine_curr = sine_c;
    end else if (sine_counter == 4) begin  // C#
      sine_curr = sine_csharp;
    end else if (sine_counter == 5) begin  // D
      sine_curr = sine_d;
    end else if (sine_counter == 6) begin  // Eb
      sine_curr = sine_eflat;
    end else if (sine_counter == 7) begin  // F
      sine_curr = sine_f;
    end else if (sine_counter == 8) begin  // F#
      sine_curr = sine_fsharp;
    end else if (sine_counter == 9) begin // G
      sine_curr = sine_g;
    end else if (sine_counter == 10) begin // G#
      sine_curr = sine_gsharp;
    end
  end

  // Duplicator for I2S2
  logic [11:0] data_left_dup;
  duplicator # (
    .width_p(12),
    .duplications_p(11))  // Check this, want to duplicate 11 times for each note
  dup_inst (
    .clk_i(clk_o),
    .reset_i(reset_r),
    .data_i(data_left_li[23:12]),
    .valid_i(valid_li),
    .ready_o(ready_lo),
    .valid_o(dup_valid_o),
    .data_o(data_left_dup),
    .ready_i(dup_ready_i)
  );

  // mac ------------------------------------------------------------------------------------------------
  logic signed [31:0] mac_o, abs_delaybuff_o;
  logic signed [35:0] delaybuff_o;
  //logic [0:0] mac_valid_i, mac_ready_o;
  logic [16:0] counter_o;
  mac
    #(.int_in_lp(1),                  
      .frac_in_lp(11),
      .int_out_lp(10),
      .frac_out_lp(22))
  mac_inst (
    .clk_i(clk_o),
    .reset_i(reset_r | counter_o == 65536),     
    .a_i(sine_curr), 
    .b_i(data_left_dup), 
    .db_i(delaybuff_o[31:0]),  
    .data_o(mac_o)
  );

  delaybuffer #(
    .width_p(36),
    .delay_p(11))
  db_inst (
    .clk_i(clk_o),
    .reset_i(reset_r | counter_o == 65537),
    .data_i({sine_counter[3:0], mac_o}),         // append sine idx to mac_o
    .valid_i(dup_valid_o),
    .ready_o(dup_ready_i),
    .valid_o(db_valid_o),
    .data_o(delaybuff_o),
    .ready_i(1'b1)
  );
  
  // save and restart logic
  my_counter 
    #(.width_p(17)
     ,.max_val_p(17'd65538))
  counter_inst2(
    .clk_i(clk_o),
    .reset_i(reset_r),
    .up_i(valid_li & ready_lo),
    .down_i(1'b0),
    .count_o(counter_o)
  );

  logic [35:0] max_accum;
  assign abs_delaybuff_o = delaybuff_o[31] ? -delaybuff_o[31:0] : delaybuff_o[31:0];

  // comparator
  always_ff @(posedge clk_o) begin
    if (reset_r) begin
      max_accum <= '0;
    end else begin
      if (counter_o == 65536) begin
        max_accum <= '0;
      end
      if (db_valid_o) begin
        if (abs_delaybuff_o > max_accum[31:0]) begin
          max_accum <= {delaybuff_o[35:32], abs_delaybuff_o};
        end
      end
    end
  end

  // debugging with led
  assign led_o[1] = (sine_counter == delaybuff_o[35:32]);
  assign led_o[5:2] = max_accum[35:32];

  // for note
  hex2ssd ssd_inst1 (                  
    .hex_i(max_accum[35:32]),
    .ssd_o(ssd_o[6:0])
  );

endmodule
