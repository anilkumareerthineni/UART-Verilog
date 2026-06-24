module rx (
    input  wire       clk,
    input  wire       rst,       // active low
    input  wire       rx_in,
    input  wire       clr,
    input  wire       rx_en,     // oversampling tick
    output reg        done,
    output reg [7:0]  data_out,
    output reg        data_valid
);

localparam START   = 2'd0;
localparam RECEIVE = 2'd1;
localparam STOP    = 2'd2;

reg [1:0] state;
reg [3:0] sample;
reg [3:0] index;
reg [8:0] temp;   // temp[8:1] = data, temp[0] = parity

wire parity;
assign parity = ^temp[8:1];

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state      <= START;
        sample     <= 4'd0;
        index      <= 4'd0;
        temp       <= 9'd0;
        data_out   <= 8'd0;
        done       <= 1'b0;
        data_valid <= 1'b0;
    end else begin
        if (clr)
            done <= 1'b0;

        data_valid <= 1'b0;   // pulse

        if (rx_en) begin
            case (state)
                START: begin
                    // wait for line low for 16 ticks
                    if (rx_in == 1'b0) begin
                        if (sample == 4'd15) begin
                            sample <= 4'd0;
                            index  <= 4'd0;
                            temp   <= 9'd0;
                            state  <= RECEIVE;
                        end else begin
                            sample <= sample + 4'd1;
                        end
                    end else begin
                        sample <= 4'd0;
                    end
                end

                RECEIVE: begin
                    if (sample == 4'd8) begin
                        temp[index] <= rx_in;
                    end

                    if (sample == 4'd15) begin
                        sample <= 4'd0;
                        if (index == 4'd8) begin
                            state <= STOP;
                        end else begin
                            index <= index + 4'd1;
                        end
                    end else begin
                        sample <= sample + 4'd1;
                    end
                end

                STOP: begin
                    if (sample == 4'd15) begin
                        state    <= START;
                        sample   <= 4'd0;
                        done     <= 1'b1;
                        data_out <= temp[8:1];
                        if (parity == temp[0])
                            data_valid <= 1'b1;
                    end else begin
                        sample <= sample + 4'd1;
                    end
                end

                default: begin
                    state      <= START;
                    sample     <= 4'd0;
                    index      <= 4'd0;
                    temp       <= 9'd0;
                    data_valid <= 1'b0;
                end
            endcase
        end
    end
end

endmodule