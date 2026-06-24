module tx (
    input  wire       clk,
    input  wire       rst,       // active low
    input  wire       write_en,
    input  wire       tx_en,     // baud tick enable
    input  wire [7:0] data_in,
    output reg        tx_out,
    output wire       busy,
    output reg        done
);

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0] state;
reg [8:0] shift_reg;     // [7:0] data + parity
reg [3:0] bit_count;     // 0..8 => 8 data + 1 parity

wire parity;
assign parity = ^data_in;
assign busy   = (state != IDLE);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state     <= IDLE;
        shift_reg <= 9'd0;
        bit_count <= 4'd0;
        tx_out    <= 1'b1;
        done      <= 1'b0;
    end else begin
        done <= 1'b0;   // one-cycle pulse

        case (state)
            IDLE: begin
                tx_out <= 1'b1;
                if (write_en) begin
                    shift_reg <= {data_in, parity};  // parity transmitted after 8 data bits because LSB shifts out first
                    bit_count <= 4'd0;
                    state     <= START;
                end
            end

            START: begin
                if (tx_en) begin
                    tx_out <= 1'b0;   // start bit
                    state  <= DATA;
                end
            end

            DATA: begin
                if (tx_en) begin
                    tx_out    <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    if (bit_count == 4'd8) begin
                        state <= STOP;
                    end
                    bit_count <= bit_count + 4'd1;
                end
            end

            STOP: begin
                if (tx_en) begin
                    tx_out <= 1'b1;   // stop bit
                    done   <= 1'b1;
                    state  <= IDLE;
                end
            end

            default: begin
                state  <= IDLE;
                tx_out <= 1'b1;
                done   <= 1'b0;
            end
        endcase
    end
end

endmodule