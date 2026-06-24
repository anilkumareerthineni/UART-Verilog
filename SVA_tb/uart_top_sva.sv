module uart_top_sva_monitor (
    input logic       clk,
    input logic       rst,         // active low
    input logic       write_en,
    input logic [7:0] data_in,
    input logic       busy,
    input logic       done_tx,
    input logic       done_rx,
    input logic [7:0] data_out,
    input logic       data_valid
);

    logic [7:0] last_tx_data;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            last_tx_data <= 8'd0;
        else if (!busy && write_en)
            last_tx_data <= data_in;
    end

    // No new write while busy
    property p_no_write_while_busy;
        @(posedge clk) disable iff(!rst)
        busy |-> !write_en;
    endproperty
    assert property (p_no_write_while_busy)
        else $error("UART TOP ASSERTION FAILED: write_en asserted while busy");

    // Accepted write should eventually lead to TX completion
    property p_request_to_done_tx;
        @(posedge clk) disable iff(!rst)
        (!busy && write_en) |-> ##[1:1000000] done_tx;
    endproperty
    assert property (p_request_to_done_tx)
        else $error("UART TOP ASSERTION FAILED: accepted write did not lead to done_tx");

    // TX completion should eventually lead to RX completion
    property p_tx_to_rx_eventually;
        @(posedge clk) disable iff(!rst)
        done_tx |-> ##[1:1000000] done_rx;
    endproperty
    assert property (p_tx_to_rx_eventually)
        else $error("UART TOP ASSERTION FAILED: RX did not complete after TX done");

    // Valid received data must match last transmitted byte
    property p_loopback_data_match;
        @(posedge clk) disable iff(!rst)
        (data_valid && done_rx) |-> (data_out == last_tx_data);
    endproperty
    assert property (p_loopback_data_match)
        else $error("UART TOP ASSERTION FAILED: loopback data mismatch");

endmodule