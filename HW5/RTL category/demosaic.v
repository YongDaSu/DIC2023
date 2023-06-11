module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

localparam  BUFFER = 0,
            GET_DATA = 1,
            INTERPOLATION = 2,
            WRITE2MEM = 3,
            DONE = 4;

reg [3:0] state, nextState;
reg [13:0] center; //[13:7]row [6:0]column
//reg [9:0] addr_buffer [8:0];
reg [9:0] data_buffer [8:0];
reg [1:0] stage;
reg [3:0] counter;

integer i;

wire [13:0] lefttop, top, righttop, left, right, leftbottom, bottom, rightbottom;
assign lefttop = {(center[13:7] - 7'd1) , (center[6:0] - 7'd1)};
assign top = {(center[13:7] - 7'd1) , center[6:0]};
assign righttop = {(center[13:7] - 7'd1) , (center[6:0] + 7'd1)};
assign left = {center[13:7] , (center[6:0] - 7'd1)};
assign right = {center[13:7] , (center[6:0] + 7'd1)};
assign leftbottom = {(center[13:7] + 7'd1) , (center[6:0] - 7'd1)};
assign bottom = {(center[13:7] + 7'd1) , center[6:0]};
assign rightbottom = {(center[13:7] + 7'd1) , (center[6:0] + 7'd1)};

//initial done <= 1'b0;


always @(*) begin
    case(state)
        BUFFER: begin
            if(center == 16383) nextState = GET_DATA;
            else nextState = BUFFER;
        end
        GET_DATA: begin
            if((center[13:7] != 7'b0 && center[13:7] != 7'b1111111) && (center[6:0] != 7'b0 && center[6:0] != 7'b1111111)) begin
                if(counter == 9) nextState = INTERPOLATION;
                else nextState = GET_DATA;
            end
            else if(center == 16383) nextState = DONE;
            else nextState = GET_DATA;
        end
        INTERPOLATION: begin
            nextState = WRITE2MEM;
        end
        WRITE2MEM: begin
            nextState = (stage == 3)? GET_DATA : WRITE2MEM;
        end
        DONE: begin
            nextState = DONE;
        end
        default: nextState = BUFFER;
    endcase
end

always @(posedge clk or posedge reset) begin
    if(reset) state <= BUFFER;
    else state <= nextState;
end

always @(posedge clk) begin
    if(reset) begin
        //state <= BUFFER;
        center <= 14'd0;
        stage <= 2'd0;
        counter <= 4'd0;
        done <= 1'b0;
        for(i = 0;i < 9;i = i + 1) begin
            data_buffer[i] <= 10'd0;
        end
    end
    else begin
        case(state)
            BUFFER: begin
                if(in_en) begin
                    case({center[7],center[0]})
                            2'b00: begin //center = green
                                wr_g <= 1'b1;
                                wdata_g <= data_in;
                                addr_g <= center;
                                wr_b <= 1'b0;
                                wr_r <= 1'b0;
                            end
                            2'b01: begin //center = red
                                wr_r <= 1'b1;
                                wdata_r <= data_in;
                                addr_r <= center;
                                wr_b <= 1'b0;
                                wr_g <= 1'b0;
                            end
                            2'b10: begin //center = blue
                                wr_b <= 1'b1;
                                wdata_b <= data_in;
                                addr_b <= center;
                                wr_g <= 1'b0;
                                wr_r <= 1'b0;
                            end
                            2'b11: begin //center = green
                                wr_g <= 1'b1;
                                wdata_g <= data_in;
                                addr_g <= center;
                                wr_b <= 1'b0;
                                wr_r <= 1'b0;
                            end
                    endcase
                    center <= center + 1;
                end
            end
            GET_DATA: begin
                wr_g <= 1'b0;
                wr_b <= 1'b0;
                wr_r <= 1'b0;
                if((center[13:7] != 7'b0 && center[13:7] != 7'b1111111) && (center[6:0] != 7'b0 && center[6:0] != 7'b1111111)) begin
                    case({center[7],center[0]})
                        2'b00: begin //center = green
                            case(counter)
                                0: begin
                                    addr_g <= lefttop;
                                end
                                1: begin
                                    data_buffer[0] <= rdata_g;
                                    addr_b <= top;
                                end
                                2: begin
                                    data_buffer[1] <= rdata_b;
                                    addr_g <= righttop;
                                end
                                3: begin
                                    data_buffer[2] <= rdata_g;
                                    addr_r <= left;
                                end
                                4: begin
                                    data_buffer[3] <= rdata_r;
                                    addr_g <= center;
                                end
                                5: begin
                                    data_buffer[4] <= rdata_g;
                                    addr_r <= right;
                                end
                                6: begin
                                    data_buffer[5] <= rdata_r;
                                    addr_g <= leftbottom;
                                end
                                7: begin
                                    data_buffer[6] <= rdata_g;
                                    addr_b <= bottom;
                                end
                                8: begin
                                    data_buffer[7] <= rdata_b;
                                    addr_g <= rightbottom;
                                end
                                9: begin
                                    data_buffer[8] <= rdata_g;
                                end
                            endcase
                            counter <= counter + 1;
                        end
                        2'b01: begin //center = red
                            case(counter)
                                0: begin
                                    addr_b <= lefttop;
                                end
                                1: begin
                                    data_buffer[0] <= rdata_b;
                                    addr_g <= top;
                                end
                                2: begin
                                    data_buffer[1] <= rdata_g;
                                    addr_b <= righttop;
                                end
                                3: begin
                                    data_buffer[2] <= rdata_b;
                                    addr_g <= left;
                                end
                                4: begin
                                    data_buffer[3] <= rdata_g;
                                    addr_r <= center;
                                end
                                5: begin
                                    data_buffer[4] <= rdata_r;
                                    addr_g <= right;
                                end
                                6: begin
                                    data_buffer[5] <= rdata_g;
                                    addr_b <= leftbottom;
                                end
                                7: begin
                                    data_buffer[6] <= rdata_b;
                                    addr_g <= bottom;
                                end
                                8: begin
                                    data_buffer[7] <= rdata_g;
                                    addr_b <= rightbottom;
                                end
                                9: begin
                                    data_buffer[8] <= rdata_b;
                                end
                            endcase
                            counter <= counter + 1;
                        end
                        2'b10: begin //center = blue
                            case(counter)
                                0: begin
                                    addr_r <= lefttop;
                                end
                                1: begin
                                    data_buffer[0] <= rdata_r;
                                    addr_g <= top;
                                end
                                2: begin
                                    data_buffer[1] <= rdata_g;
                                    addr_r <= righttop;
                                end
                                3: begin
                                    data_buffer[2] <= rdata_r;
                                    addr_g <= left;
                                end
                                4: begin
                                    data_buffer[3] <= rdata_g;
                                    addr_b <= center;
                                end
                                5: begin
                                    data_buffer[4] <= rdata_b;
                                    addr_g <= right;
                                end
                                6: begin
                                    data_buffer[5] <= rdata_g;
                                    addr_r <= leftbottom;
                                end
                                7: begin
                                    data_buffer[6] <= rdata_r;
                                    addr_g <= bottom;
                                end
                                8: begin
                                    data_buffer[7] <= rdata_g;
                                    addr_r <= rightbottom;
                                end
                                9: begin
                                    data_buffer[8] <= rdata_r;
                                end
                            endcase
                            counter <= counter + 1;
                        end
                        2'b11: begin //center = green
                            case(counter)
                                0: begin
                                    addr_g <= lefttop;
                                end
                                1: begin
                                    data_buffer[0] <= rdata_g;
                                    addr_r <= top;
                                end
                                2: begin
                                    data_buffer[1] <= rdata_r;
                                    addr_g <= righttop;
                                end
                                3: begin
                                    data_buffer[2] <= rdata_g;
                                    addr_b <= left;
                                end
                                4: begin
                                    data_buffer[3] <= rdata_b;
                                    addr_g <= center;
                                end
                                5: begin
                                    data_buffer[4] <= rdata_g;
                                    addr_b <= right;
                                end
                                6: begin
                                    data_buffer[5] <= rdata_b;
                                    addr_g <= leftbottom;
                                end
                                7: begin
                                    data_buffer[6] <= rdata_g;
                                    addr_r <= bottom;
                                end
                                8: begin
                                    data_buffer[7] <= rdata_r;
                                    addr_g <= rightbottom;
                                end
                                9: begin
                                    data_buffer[8] <= rdata_g;
                                end
                            endcase
                            counter <= counter + 1;
                        end
                    endcase
                end
                else center <= center + 1; //boundary
            end
            INTERPOLATION: begin
                counter <= 0;
                case({center[7],center[0]})
                    2'b00: begin //center = green
                        wdata_r <= (data_buffer[3] + data_buffer[5]) >> 1;
                        wdata_g <= data_buffer[4];
                        wdata_b <= (data_buffer[1] + data_buffer[7]) >> 1;
                    end
                    2'b01: begin //center = red
                        wdata_r <= data_buffer[4];
                        wdata_g <= (data_buffer[3] + data_buffer[5] + data_buffer[1] + data_buffer[7]) >> 2;
                        wdata_b <= (data_buffer[0] + data_buffer[2] + data_buffer[6] + data_buffer[8]) >> 2;
                    end
                    2'b10: begin //center = blue
                        wdata_r <= (data_buffer[0] + data_buffer[2] + data_buffer[6] + data_buffer[8]) >> 2;
                        wdata_g <= (data_buffer[3] + data_buffer[5] + data_buffer[1] + data_buffer[7]) >> 2;
                        wdata_b <= data_buffer[4];
                    end
                    2'b11: begin //center = green
                        wdata_r <= (data_buffer[1] + data_buffer[7]) >> 1;
                        wdata_g <= data_buffer[4];
                        wdata_b <= (data_buffer[3] + data_buffer[5]) >> 1;
                    end
                endcase
            end
            WRITE2MEM: begin
                case(stage)
                    0: begin
                        addr_r <= center;
                        wr_r <= 1;
                        stage <= 1;
                    end
                    1: begin
                        wr_r <= 0;
                        addr_g <= center;
                        wr_g <= 1;
                        stage <= 2;
                    end
                    2: begin
                        wr_g <= 0;
                        addr_b <= center;
                        wr_b <= 1;
                        stage <= 3;
                    end
                    3: begin
                        wr_b <= 0;
                        center <= center + 1;
                        stage <= 0;
                    end
                endcase
            end
            DONE: begin
                done <= 1;
            end
        endcase
    end
end
endmodule
