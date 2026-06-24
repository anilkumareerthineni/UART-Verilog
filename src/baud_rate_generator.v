module baud_rate_gen (
    input  wire clk,
    input  wire rst,        // active low reset
    output reg  tx_en,
    output reg  rx_en
);

reg [12:0] tx_count;
reg [8:0]  rx_count;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        tx_count <= 13'd0;
        tx_en    <= 1'b0;
    end else begin
        tx_en <= 1'b0;
        if (tx_count == 13'd5207) begin
            tx_count <= 13'd0;
            tx_en    <= 1'b1;
        end else begin
            tx_count <= tx_count + 13'd1;
        end
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rx_count <= 9'd0;
        rx_en    <= 1'b0;
    end else begin
        rx_en <= 1'b0;
        if (rx_count == 9'd324) begin
            rx_count <= 9'd0;
            rx_en    <= 1'b1;
        end else begin
            rx_count <= rx_count + 9'd1;
        end
    end
end

endmodule