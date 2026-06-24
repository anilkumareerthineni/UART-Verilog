module uart (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    input  wire       write_en,
    input  wire       clr,
    output wire       busy,
    output wire       done_tx,
    output wire       done_rx,
    output wire [7:0] data_out,
    output wire       data_valid
);

wire tx_en, rx_en;
wire tx_out;

baud_rate_gen baud_gen1 (
    .clk   (clk),
    .rst   (rst),
    .tx_en (tx_en),
    .rx_en (rx_en)
);

tx tx1 (
    .clk      (clk),
    .rst      (rst),
    .write_en (write_en),
    .tx_en    (tx_en),
    .data_in  (data_in),
    .tx_out   (tx_out),
    .busy     (busy),
    .done     (done_tx)
);

rx rx1 (
    .clk       (clk),
    .rst       (rst),
    .rx_in     (tx_out),   // loopback
    .clr       (clr),
    .rx_en     (rx_en),
    .done      (done_rx),
    .data_out  (data_out),
    .data_valid(data_valid)
);

endmodule