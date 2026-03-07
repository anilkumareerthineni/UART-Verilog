`include "uart.v"

`timescale 1ns/1ns

module uart_tb();

reg clk, rst, write_en, clr;
reg [7:0] data_in;
wire [7:0] data_out;
wire data_valid, done_tx, done_rx, busy;

uart uart1(.clk(clk),
           .rst(rst),
           .data_in(data_in),
           .write_en(write_en),
           .busy(busy),
           .done_tx(done_tx),
           .clr(clr),
           .data_out(data_out),
           .data_valid(data_valid),
           .done_rx(done_rx)
           );

always #1 clk = ~clk;


task transmitt(input [7:0] data);
begin
    @(negedge clk);
    data_in = data;
    write_en = 1'b1;

    @(negedge clk);
    write_en = 1'b0;
end
endtask

task clear_rx();
begin
    @(negedge clk);
    clr = 1'b1;
    
    @(negedge clk);
    clr = 1'b0;
end
endtask

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0,uart_tb);

    clk = 1'b0;
    rst = 1'b0; 
    write_en = 1'b0; 
    clr = 1'b0;
    data_in = 8'd0;
    @(negedge clk);
    rst = 1'b1;

    transmitt(8'd10);
    @(posedge busy);
    @(negedge busy);
    wait(done_rx);
    clear_rx();
    $display("completed");

    #100;

    $finish;
end
endmodule