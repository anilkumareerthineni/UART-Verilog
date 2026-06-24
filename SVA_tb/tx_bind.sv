bind tx tx_internal_sva tx_sva_i (
    .clk(clk),
    .rst(rst),
    .write_en(write_en),
    .tx_en(tx_en),
    .tx_out(tx_out),
    .busy(busy),
    .done(done),
    .state(state),
    .bit_count(bit_count)
);