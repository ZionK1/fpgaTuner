module comparator
    (input clk_i
    ,input reset_i
    ,input db_valid_o
    ,input [17:0] counter_i
    ,input [35:0] delaybuff_o
    ,output [35:0] data_o
    );

    logic [35:0] max_accum;
    logic signed [31:0] abs_delaybuff_o;
    assign abs_delaybuff_o = delaybuff_o[31] ? -delaybuff_o[31:0] : delaybuff_o[31:0];

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            max_accum <= '0;
        end else begin
            if (counter_i == 65536) begin
                max_accum <= '0;
            end
            if (db_valid_o) begin
                if (abs_delaybuff_o > max_accum[31:0]) begin
                    max_accum <= {delaybuff_o[35:32], abs_delaybuff_o};
                end
            end
        end
    end

    assign data_o = max_accum;
endmodule