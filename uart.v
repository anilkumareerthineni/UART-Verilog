`include "baud_rate_generator.v"
`include "transmitter.v"
`include "receiver.v"

module uart(clk, rst, data_in, 
            write_en, busy, done_tx, clr, 
            data_out, data_valid, done_rx);

input clk, rst, write_en, clr;
input [7:0] data_in;
output [7:0] data_out;
output data_valid, done_tx, done_rx, busy;

wire rx_en, tx_en, tx_out;

Baud_Rate_Gen baud_gen1(.clk(clk),
                        .rst(rst),
                        .tx_en(tx_en),
                        .rx_en(rx_en)
                        );

tx tx1(.clk(clk),
       .write_en(write_en),
       .tx_en(tx_en),
       .rst(rst),
       .data_in(data_in),
       .tx_out(tx_out),
       .busy(busy),
       .done(done_tx)
       );

rx rx1(.clk(clk),
       .rst(rst),
       .rx_in(tx_out),
       .clr(clr),
       .rx_en(rx_en),
       .done(done_rx),
       .data_out(data_out),
       .data_valid(data_valid)
       );

endmodule