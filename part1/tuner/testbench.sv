`timescale 1ns/1ps
`define START_TESTBENCH error_o = 0; pass_o = 0; #10;
`define FINISH_WITH_FAIL error_o = 1; pass_o = 0; #10; $finish();
`define FINISH_WITH_PASS pass_o = 1; error_o = 0; #10; $finish();
module testbench
  // You don't usually have ports in a testbench, but we need these to
  // signal to cocotb/gradescope that the testbench has passed, or failed.
  (output logic error_o = 0
  ,output logic pass_o = 0);

   // You can use this 
   logic [0:0] error;
   
   wire        clk_i;
   wire        reset_i;

   nonsynth_clock_gen
     #(.cycle_time_p(10))
   cg
     (.clk_o(clk_i));

   nonsynth_reset_gen
     #(.reset_cycles_lo_p(10)
      ,.reset_cycles_hi_p(10))
   rg
     (.clk_i(clk_i)
     ,.async_reset_o(reset_i));

  logic [0:0] db_valid_o;
  logic [16:0] counter_i;
  logic [35:0] delaybuff_o, data_o, data_ol;

   // DUT
   comparator
      #()
   dut
      (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.db_valid_o(db_valid_o)
      ,.counter_i(counter_i)
      ,.delaybuff_o(delaybuff_o) // input here
      ,.data_o(data_o)
      );

   // Behavioral model
   logic [35:0] max_accum;
   logic signed [31:0] abs_delaybuff_ol;

   assign abs_delaybuff_ol = delaybuff_o[31] ? -delaybuff_o[31:0] : delaybuff_o[31:0];

   always_ff @(posedge clk_i) begin
      if (reset_i) begin
         max_accum <= '0;
      end else begin
         if (counter_i == 65536) begin
               max_accum <= '0;
         end
         if (db_valid_o) begin
               if (abs_delaybuff_ol > max_accum[31:0]) begin
                  max_accum <= {delaybuff_o[35:32], abs_delaybuff_ol};
               end
         end
      end
   end

   assign data_ol = max_accum;
   
   // Checker
   always_ff @(posedge clk_i) begin
      if ((data_ol !== data_o)) begin                                       
        error = 1;
        $display("Error! Expected: %b, Got: %b", data_ol, data_o); 
      end
   end

   initial begin
      // Call this to set pass_o and error_o to 0.
      `START_TESTBENCH

      error = 0;
      db_valid_o = 0;
      counter_i = 0;
      delaybuff_o = 0;
      
      // Put your testbench code here. Print all of the test cases and
      // their correctness.
      @(negedge reset_i);
      for (int i = 0; i < 17'd65800; i += 4) begin
        @(negedge clk_i);

        if (i == 264) begin
          db_valid_o = 0;
        end else begin
          db_valid_o = 1;
        end

        counter_i = i;
        delaybuff_o = ~i;
      end

      db_valid_o = 0;
      @(negedge clk_i);

      // Use FINISH_WITH_FAIL to end the testbench and cause the FAIL message, and signal fail to cocotb
      // Use FINISH_WITH_PASS to end the testbench and cause the PASS message, and signal pass to cocotb
      // Calling neither will cause the UNKNOWN message, and cause issues in Cocotb.
      if (error == 1) begin
        $display("Test Failed!");
        `FINISH_WITH_FAIL;
      end
      $display("\n\nSuccessfully tested comparator!\n\n");
      `FINISH_WITH_PASS;
   end

   // This block executes after $finish() has been called.
   final begin
      $display("Simulation time is %t", $time);
      if(error_o === 1) begin
	 $display("\033[0;31m    ______                    \033[0m");
	 $display("\033[0;31m   / ____/_____________  _____\033[0m");
	 $display("\033[0;31m  / __/ / ___/ ___/ __ \\/ ___/\033[0m");
	 $display("\033[0;31m / /___/ /  / /  / /_/ / /    \033[0m");
	 $display("\033[0;31m/_____/_/  /_/   \\____/_/     \033[0m");
	 $display("Simulation Failed");
     end else if (pass_o === 1) begin
	 $display("\033[0;32m    ____  ___   __________\033[0m");
	 $display("\033[0;32m   / __ \\/   | / ___/ ___/\033[0m");
	 $display("\033[0;32m  / /_/ / /| | \\__ \\\__ \ \033[0m");
	 $display("\033[0;32m / ____/ ___ |___/ /__/ / \033[0m");
	 $display("\033[0;32m/_/   /_/  |_/____/____/  \033[0m");
	 $display();
	 $display("Simulation Succeeded!");
     end else begin
        $display("   __  ___   ____ __ _   ______ _       ___   __");
        $display("  / / / / | / / //_// | / / __ \\ |     / / | / /");
        $display(" / / / /  |/ / ,<  /  |/ / / / / | /| / /  |/ / ");
        $display("/ /_/ / /|  / /| |/ /|  / /_/ /| |/ |/ / /|  /  ");
        $display("\\____/_/ |_/_/ |_/_/ |_/\\____/ |__/|__/_/ |_/   ");
	$display("Please set error_o or pass_o!");
     end
   end

endmodule
