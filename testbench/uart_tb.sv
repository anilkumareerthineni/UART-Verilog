`timescale 1ns/1ps

module uart_tb;

reg clk;
reg rst;
reg write_en;
reg clr;
reg [7:0] data_in;

wire busy;
wire done_tx;
wire done_rx;
wire [7:0] data_out;
wire data_valid;

uart dut (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .write_en(write_en),
    .clr(clr),
    .busy(busy),
    .done_tx(done_tx),
    .done_rx(done_rx),
    .data_out(data_out),
    .data_valid(data_valid)
);

initial clk = 1'b0;
always #5 clk = ~clk;

task send_byte;
    input [7:0] din;
    begin
        @(posedge clk);
        while (busy)
            @(posedge clk);

        data_in   <= din;
        write_en  <= 1'b1;
        @(posedge clk);
        write_en  <= 1'b0;

        $display("[%0t] SENT = %02h", $time, din);

        wait(done_tx == 1'b1);
        $display("[%0t] TX DONE for %02h", $time, din);

        wait(done_rx == 1'b1);
        $display("[%0t] RX DONE, data_out = %02h, data_valid = %0b", $time, data_out, data_valid);

        if (data_valid && data_out == din)
            $display("PASS: expected=%02h received=%02h", din, data_out);
        else
            $display("FAIL: expected=%02h received=%02h valid=%0b", din, data_out, data_valid);

        clr <= 1'b1;
        @(posedge clk);
        clr <= 1'b0;
    end
endtask

initial begin
    rst      = 1'b0;
    write_en = 1'b0;
    clr      = 1'b0;
    data_in  = 8'd0;

    repeat(5) @(posedge clk);
    rst = 1'b1;

    send_byte(8'h55);
    send_byte(8'hA3);
    send_byte(8'h00);
    send_byte(8'hFF);

    #1000;
    $finish;
end

endmodule
