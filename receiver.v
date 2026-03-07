module rx (clk, rst, rx_in, clr, rx_en, 
                done, data_out, data_valid);

input clk, rst, clr, rx_in, rx_en;
output reg [7:0] data_out;
output reg done, data_valid;

parameter start = 2'b00;
parameter receive = 2'b01;
parameter stop = 2'b10;


reg [3:0] sample = 4'd0, index;
reg [8:0] temp;
reg [1:0] state;
wire parity;

assign parity = ^data_out;

always @(posedge clk or negedge rst) begin
    if(rst == 1'b0) begin
        state <= start;
        sample <= 0;
        index <= 0;
        done <= 0;
        data_valid <= 0;
    end
end

always @(posedge clk) begin
    if(clr) begin
        done <= 1'b0;
    end

    if(state == stop && parity == temp[0]) begin
        data_valid <= 1'b1;
    end
    else
        data_valid <= 1'b0;

end


always @(posedge rx_en) begin
    
    case(state)
    start : begin
        if(sample == 4'd15) begin
            sample <= 4'd0;
            index <= 4'd0;
            temp <= 9'd0;
            state <= receive;
        end
        else begin
            if(rx_in == 1'b0) 
                sample <= sample + 1;
        end
        end
    receive : begin
        sample <= sample + 4'd1;
        if(sample == 4'd8) begin
            temp[index] <= rx_in;
            index <= index + 4'd1;
        end
        if(sample == 4'd15 && index == 4'd9) begin
            state <= stop;
        end
        end
    stop : begin
        if(sample == 4'd15) begin
            state <= start;
            done <= 1'b1;
            sample <= 4'd0;
            data_out <= temp[8:1];
        end
        else
            sample <= sample + 4'd1;
        end
    default : begin
        state <= start;
        data_out <= 8'd0;
        done <= 1'b0;
    end
    endcase
    
end

endmodule