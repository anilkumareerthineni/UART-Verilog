module tx (clk, write_en, tx_en, rst, 
           data_in, tx_out, busy, done);

input clk, write_en, tx_en, rst;
input [7:0] data_in;
output reg tx_out, done;
output busy;

parameter idle = 2'd0;
parameter start = 2'd1;
parameter transmission = 2'd2;
parameter stop = 2'd3;

reg [8:0] data;
reg [1:0] state;
reg [3:0] count;
reg write;
wire parity = ^data_in;

always @(posedge clk or negedge rst) begin
    if(rst == 1'b0) begin
        tx_out <= 1'b1;
        state <= idle;
        done <= 1'b0;
        count <= 4'd0;
        write <= 1'b0;
    end
    else 
        done <= 1'b0;
    
    if(state == stop && tx_en) 
        done <= 1'b1;

end

always @(posedge clk) begin
    if(write_en && !busy && !write) begin
        write <= 1'b1;
        data[8:1] <= data_in;
        data[0] <= parity;
    end
    else begin
        if(busy) 
            write <= 1'b0;
    end
end

assign busy = (state != idle);

always @(posedge tx_en) begin
    
    case(state)
    idle : begin
        if(write) begin
            state <= start;
            count <= 4'd0;
        end
        else
            state <= idle;
    end
    start : begin
            tx_out <= 1'b0;
            state <= transmission;

    end
    transmission : begin
            tx_out <= data[0];
            data <= data >> 1;
            count <= count + 4'd1;
            if (count == 4'd8)
              state <= stop;
    end
    stop : begin
            tx_out <= 1'b1;
            state <= idle;
    end
    default : begin
        state <= idle;
        tx_out <= 1'b1;
    end
    endcase 
end

endmodule