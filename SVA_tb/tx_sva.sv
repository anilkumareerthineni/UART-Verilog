module tx_internal_sva (
    input logic       clk,
    input logic       rst,
    input logic       write_en,
    input logic       tx_en,
    input logic       tx_out,
    input logic       busy,
    input logic       done,

    input logic [1:0] state,
    input logic [3:0] bit_count
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    // 1. Idle line must stay high
    property p_idle_high;
        @(posedge clk) disable iff(!rst)
        (state == IDLE) |-> (tx_out == 1'b1);
    endproperty
    assert property (p_idle_high)
        else $error("TX SVA FAIL: tx_out not high in IDLE");

    // 2. If write_en is accepted in IDLE, next cycle state should be START
    property p_write_to_start;
        @(posedge clk) disable iff(!rst)
        (state == IDLE && write_en) |=> (state == START);
    endproperty
    assert property (p_write_to_start)
        else $error("TX SVA FAIL: write_en in IDLE did not move to START");

    // 3. If START sees tx_en, next cycle tx_out must be 0 and state must go DATA
    property p_start_bit_low;
        @(posedge clk) disable iff(!rst)
        ($past(state) == START && $past(tx_en)) |-> (tx_out == 1'b0 && state == DATA);
    endproperty
    assert property (p_start_bit_low)
        else $error("TX SVA FAIL: START bit/state transition incorrect");

    // 4. While in DATA with tx_en and bit_count < 8, TX must remain in DATA next cycle
    property p_data_stays_data;
        @(posedge clk) disable iff(!rst)
        ($past(state) == DATA && $past(tx_en) && $past(bit_count) < 4'd8)
        |-> (state == DATA);
    endproperty
    assert property (p_data_stays_data)
        else $error("TX SVA FAIL: DATA state exited too early");

    // 5. When DATA sees tx_en with bit_count == 8, next cycle must go to STOP
    property p_data_to_stop;
        @(posedge clk) disable iff(!rst)
        ($past(state) == DATA && $past(tx_en) && $past(bit_count) == 4'd8)
        |-> (state == STOP);
    endproperty
    assert property (p_data_to_stop)
        else $error("TX SVA FAIL: DATA->STOP transition missing at final bit");

    // 6. While state != IDLE, busy must be 1
    property p_busy_when_active;
        @(posedge clk) disable iff(!rst)
        (state != IDLE) |-> busy;
    endproperty
    assert property (p_busy_when_active)
        else $error("TX SVA FAIL: busy low while TX active");

    // 7. If STOP sees tx_en, next cycle:
    //    done must pulse, tx_out must be high, state must go IDLE
    property p_stop_to_idle_done;
        @(posedge clk) disable iff(!rst)
        ($past(state) == STOP && $past(tx_en))
        |-> (done && tx_out == 1'b1 && state == IDLE);
    endproperty
    assert property (p_stop_to_idle_done)
        else $error("TX SVA FAIL: STOP completion incorrect");

    // 8. done must be one-cycle pulse
    property p_done_one_cycle;
        @(posedge clk) disable iff(!rst)
        done |=> !done;
    endproperty
    assert property (p_done_one_cycle)
        else $error("TX SVA FAIL: done not one-cycle pulse");

    // 9. If done is high, tx_out must be high
    property p_done_stop_high;
        @(posedge clk) disable iff(!rst)
        done |-> (tx_out == 1'b1);
    endproperty
    assert property (p_done_stop_high)
        else $error("TX SVA FAIL: tx_out not high when done asserted");

endmodule
