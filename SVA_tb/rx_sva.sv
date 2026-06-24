module rx_internal_sva (
    input logic       clk,
    input logic       rst,
    input logic       rx_en,
    input logic       clr,
    input logic       done,
    input logic       data_valid,
    input logic [7:0] data_out,

    input logic [1:0] state,
    input logic [3:0] sample,
    input logic [3:0] index,
    input logic [8:0] temp
);

    localparam START   = 2'd0;
    localparam RECEIVE = 2'd1;
    localparam STOP    = 2'd2;

    wire parity;
    assign parity = ^temp[8:1];

    // 1. START -> RECEIVE when start detection completes
    property p_start_to_receive;
        @(posedge clk) disable iff(!rst)
        ($past(state) == START && $past(rx_en) && $past(sample) == 4'd15)
        |-> (state == RECEIVE);
    endproperty
    assert property (p_start_to_receive)
        else $error("RX SVA FAIL: START->RECEIVE transition missing");

    // 2. RECEIVE should continue unless last bit is completed
    property p_receive_hold;
        @(posedge clk) disable iff(!rst)
        ($past(state) == RECEIVE && $past(rx_en) &&
         !($past(sample) == 4'd15 && $past(index) == 4'd8))
        |-> (state == RECEIVE || state == STOP);
    endproperty
    assert property (p_receive_hold)
        else $error("RX SVA FAIL: RECEIVE state behavior incorrect");

    // 3. RECEIVE -> STOP when final receive bit completes
    property p_receive_to_stop;
        @(posedge clk) disable iff(!rst)
        ($past(state) == RECEIVE && $past(rx_en) &&
         $past(sample) == 4'd15 && $past(index) == 4'd8)
        |-> (state == STOP);
    endproperty
    assert property (p_receive_to_stop)
        else $error("RX SVA FAIL: RECEIVE->STOP transition missing");

    // 4. STOP -> START with done pulse at end of frame
    property p_stop_to_start_done;
        @(posedge clk) disable iff(!rst)
        ($past(state) == STOP && $past(rx_en) && $past(sample) == 4'd15)
        |-> (state == START && done);
    endproperty
    assert property (p_stop_to_start_done)
        else $error("RX SVA FAIL: STOP completion / done pulse incorrect");

    // 5. data_valid can only occur with done
    property p_valid_implies_done;
        @(posedge clk) disable iff(!rst)
        data_valid |-> done;
    endproperty
    assert property (p_valid_implies_done)
        else $error("RX SVA FAIL: data_valid without done");

    // 6. done should behave like a pulse unless clr overlaps
    property p_done_pulse;
        @(posedge clk) disable iff(!rst)
        done |=> (!done or clr);
    endproperty
    assert property (p_done_pulse)
        else $error("RX SVA FAIL: done not pulse-like");

    // 7. data_valid should be one-cycle pulse
    property p_valid_pulse;
        @(posedge clk) disable iff(!rst)
        data_valid |=> !data_valid;
    endproperty
    assert property (p_valid_pulse)
        else $error("RX SVA FAIL: data_valid not one-cycle pulse");

    // 8. clr should clear done by next cycle
    property p_clr_clears_done;
        @(posedge clk) disable iff(!rst)
        clr |=> !done;
    endproperty
    assert property (p_clr_clears_done)
        else $error("RX SVA FAIL: clr did not clear done");

    // 9. If data_valid is asserted, parity must match
    property p_valid_means_parity_ok;
        @(posedge clk) disable iff(!rst)
        data_valid |-> (parity == temp[0]);
    endproperty
    assert property (p_valid_means_parity_ok)
        else $error("RX SVA FAIL: data_valid asserted with parity mismatch");

    // 10. data_out should not be unknown when done occurs
    property p_done_known_data;
        @(posedge clk) disable iff(!rst)
        done |-> !$isunknown(data_out);
    endproperty
    assert property (p_done_known_data)
        else $error("RX SVA FAIL: data_out unknown at done");

endmodule