bind rx rx_internal_sva rx_sva_i (
    .clk(clk),
    .rst(rst),
    .rx_en(rx_en),
    .clr(clr),
    .done(done),
    .data_valid(data_valid),
    .data_out(data_out),
    .state(state),
    .sample(sample),
    .index(index),
    .temp(temp)
);