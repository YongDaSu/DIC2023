module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;


//FSM parameters define
localparam READY = 4'd0;
localparam SAVE_DATA = 4'd1;
localparam INFIX2POSTFIX = 4'd2;
localparam MEET_NUMBER = 4'd3;
localparam MEET_OPERATOR = 4'd4;
localparam POP_OPERATOR = 4'd5;
localparam SCRATCH = 4'd6;
localparam SCRATCH_MEET_NUMBER = 4'd7;
localparam SCRATCH_MEET_OPERATOR = 4'd8;
localparam SCRATCH_POP_OPERATOR = 4'd9;
localparam CALCULATION = 4'd10;
localparam OUTPUT_RESULT = 4'd11;
localparam REINITIALIZE = 4'd12;

//parameters define
reg valid;
reg [6:0] result;

reg [4:0] state, nextState;
reg [6:0] saved_data[0:15];      //array to save ascii_in;
reg [3:0] saved_index;           //index of saved_data;

reg [6:0] postfix_data[0:15];    //array to save output;
reg [3:0] postfix_index;         //index of postfix_data;

reg [6:0] operator_data[0:7];    //array to save operator_data;
reg [3:0] operator_index;        //index of operator_data;
reg [6:0] tmp_operator;

reg [6:0] scratch_operator_data[0:7];    //array to save operator_data;
reg [3:0] scratch_operator_index;        //index of operator_data;

reg [6:0] output_data[0:15];      //array to save ascii_in;
reg [3:0] output_index;           //index of saved_data;


integer i;
wire operator_index_minus_one = operator_index - 4'd1;
wire scratch_operator_index_minus_one = scratch_operator_index - 4'd1;
wire output_index_minus_one = output_index - 4'd1;
/***ascii transform table***/
/*
    ascii | number in program | Represent |
    48      0                   0
    49      1                   1
    50      2                   2
    51      3                   3
    52      4                   4
    53      5                   5
    54      6                   6
    55      7                   7
    56      8                   8
    57      9                   9
    97      10                  a
    98      11                  b
    99      12                  c    
    100     13                  d
    101     14                  e
    102     15                  f
    40      16                  (
    41      17                  )
    42      18                  *
    43      19                  +   
    45      20                  - 
    61      21                  =        
*/
//combinational circuit;
always@(*) begin
    case(state) 
        READY:  begin
            if(ready) nextState = SAVE_DATA;
            else nextState = READY;
        end
        SAVE_DATA: begin
            if(ascii_in != 8'd61) nextState = SAVE_DATA;
            else nextState = INFIX2POSTFIX;
        end 
        INFIX2POSTFIX: begin
            if((saved_data[saved_index] == 7'd21) && (operator_index == 4'd0)) nextState = CALCULATION;
            else if((saved_data[saved_index] == 7'd21) && (operator_index != 4'd0)) nextState = POP_OPERATOR;
            else if(saved_data[saved_index] == 7'd16) begin
                nextState = SCRATCH;    //meet '(', goto SCRATCH to deal with this situation;
            end
            else if(saved_data[saved_index] <= 7'd15 ) nextState = MEET_NUMBER; //meet number;
            else nextState = MEET_OPERATOR; //meet operator;
        end
        MEET_NUMBER: begin
            nextState <= INFIX2POSTFIX;
        end
        MEET_OPERATOR: begin
            if((saved_data[saved_index] == 7'd19 || saved_data[saved_index] == 7'd20)  && operator_data[operator_index_minus_one] == 7'd18) //遇到要pop到postfix_data的情況
                nextState <= POP_OPERATOR;
            else 
                nextState <= INFIX2POSTFIX;
        end
        POP_OPERATOR: begin
            if(operator_index != 4'd0) nextState = POP_OPERATOR;
            else nextState = INFIX2POSTFIX;
        end
        SCRATCH: begin
            if(saved_data[saved_index] == 7'd17) begin
                if(scratch_operator_index != 4'd0) nextState = SCRATCH_POP_OPERATOR;
                else nextState = INFIX2POSTFIX;
            end
            else if(saved_data[saved_index] <= 7'd15)
                nextState = SCRATCH_MEET_NUMBER; 
            else
                nextState = SCRATCH_MEET_OPERATOR;
        end
        SCRATCH_MEET_NUMBER: begin
            nextState = SCRATCH;
        end
        SCRATCH_MEET_OPERATOR: begin
            if((saved_data[saved_index] == 7'd19 || saved_data[saved_index] == 7'd20)  && scratch_operator_data[scratch_operator_index_minus_one] == 7'd18) //遇到要pop到postfix_data的情況
                nextState = SCRATCH_POP_OPERATOR;
            else 
                nextState = SCRATCH;
        end
        SCRATCH_POP_OPERATOR: begin
            if(scratch_operator_index != 4'd0) nextState = SCRATCH_POP_OPERATOR;
            else nextState = SCRATCH;
        end
        CALCULATION : begin
            if(postfix_data[postfix_index] != 7'd21) begin
                nextState = CALCULATION;
            end
            else nextState = OUTPUT_RESULT;
        end
        OUTPUT_RESULT: begin
            nextState = REINITIALIZE;
        end
        REINITIALIZE: begin
            nextState = READY;
        end

    endcase   

end
//sequential circuit;
always@(posedge clk) begin
    if (rst)
        state <= READY;
    else
        state <= nextState;
end
//other calculation circuit
always@(posedge clk or posedge rst)
    if(rst) begin
        //initial state
        for(i=0;i<16;i=i+1) begin
           saved_data[i] <= 7'd0;
           postfix_data[i] <= 7'd0; 
           output_data[i] <= 7'd0;
        end
        valid <= 1'b0;
        saved_index <= 4'd0;
        postfix_index <= 4'd0;
        operator_index <= 4'd0;
        tmp_operator <= 7'd0;
        output_index <= 4'd0;
    end
    else begin
        case(state)
            READY: begin
                if(ready) begin
                    case(ascii_in)
                            8'd48:saved_data[saved_index] <= 7'd0; //0
                            8'd49:saved_data[saved_index] <= 7'd1; //1
                            8'd50:saved_data[saved_index] <= 7'd2; //2
                            8'd51:saved_data[saved_index] <= 7'd3; //3 
                            8'd52:saved_data[saved_index] <= 7'd4; //4
                            8'd53:saved_data[saved_index] <= 7'd5; //5
                            8'd54:saved_data[saved_index] <= 7'd6; //6
                            8'd55:saved_data[saved_index] <= 7'd7; //7
                            8'd56:saved_data[saved_index] <= 7'd8; //8
                            8'd57:saved_data[saved_index] <= 7'd9; //9
                            8'd97:saved_data[saved_index] <= 7'd10; //a
                            8'd98:saved_data[saved_index] <= 7'd11; //b
                            8'd99:saved_data[saved_index] <= 7'd12; //c
                            8'd100:saved_data[saved_index] <= 7'd13; //d 
                            8'd101:saved_data[saved_index] <= 7'd14; //e
                            8'd102:saved_data[saved_index] <= 7'd15; //f
                            8'd40:saved_data[saved_index] <= 7'd16; //(
                            8'd41:saved_data[saved_index] <= 7'd17; //)
                            8'd42:saved_data[saved_index] <= 7'd18; //*
                            8'd43:saved_data[saved_index] <= 7'd19; //+
                            8'd45:saved_data[saved_index] <= 7'd20; //-
                            8'd61:saved_data[saved_index] <= 7'd21; //=
                    endcase
                    saved_index <= saved_index + 4'd1;
                end
            end
            SAVE_DATA: begin
                if(ascii_in != 8'd61) begin
                    case(ascii_in)
                        8'd48:saved_data[saved_index] <= 7'd0; //0
                        8'd49:saved_data[saved_index] <= 7'd1; //1
                        8'd50:saved_data[saved_index] <= 7'd2; //2
                        8'd51:saved_data[saved_index] <= 7'd3; //3 
                        8'd52:saved_data[saved_index] <= 7'd4; //4
                        8'd53:saved_data[saved_index] <= 7'd5; //5
                        8'd54:saved_data[saved_index] <= 7'd6; //6
                        8'd55:saved_data[saved_index] <= 7'd7; //7
                        8'd56:saved_data[saved_index] <= 7'd8; //8
                        8'd57:saved_data[saved_index] <= 7'd9; //9
                        8'd97:saved_data[saved_index] <= 7'd10; //a
                        8'd98:saved_data[saved_index] <= 7'd11; //b
                        8'd99:saved_data[saved_index] <= 7'd12; //c
                        8'd100:saved_data[saved_index] <=7'd13; //d 
                        8'd101:saved_data[saved_index] <= 7'd14; //e
                        8'd102:saved_data[saved_index] <= 7'd15; //f
                        8'd40:saved_data[saved_index] <= 7'd16; //(
                        8'd41:saved_data[saved_index] <= 7'd17; //)
                        8'd42:saved_data[saved_index] <= 7'd18; //*
                        8'd43:saved_data[saved_index] <= 7'd19; //+
                        8'd45:saved_data[saved_index] <= 7'd20; //-
                        8'd61:saved_data[saved_index] <= 7'd21; //=
                    endcase
                    saved_index <= saved_index + 4'd1;
                end
                else begin
                    saved_data[saved_index] <= 7'd21;
                    saved_index <= 4'd0;
                end
            end 
            INFIX2POSTFIX: begin
                if(saved_data[saved_index] == 7'd21 && operator_index == 0) begin
                    postfix_data[postfix_index] <= 7'd21;
                    postfix_index <= 4'd0;
                end
            end
            MEET_NUMBER: begin
                postfix_data[postfix_index] <= saved_data[saved_index];
                postfix_index <= postfix_index + 4'd1;
                saved_index <= saved_index + 4'd1;
            end
            MEET_OPERATOR: begin
                if((saved_data[saved_index] == 7'd19 || saved_data[saved_index] == 7'd20)  && operator_data[operator_index_minus_one] == 7'd18) begin//遇到要pop到postfix_data的情況
                    tmp_operator <= saved_data[saved_index];
                    saved_index <= saved_index + 4'd1;
                end
                else begin
                    operator_data[operator_index] <= saved_data[saved_index];
                    operator_index <= operator_index + 4'd1;
                    saved_index <= saved_index + 4'd1;
                end
            end
            POP_OPERATOR: begin
                if(operator_index_minus_one != 4'd0) begin
                    postfix_data[postfix_index] <= operator_data[operator_index_minus_one];
                    postfix_index <= postfix_index + 4'd1;
                    operator_index <= operator_index - 4'd1;
                end
                else begin      
                    postfix_data[postfix_index] <= operator_data[operator_index_minus_one];
                    postfix_index <= postfix_index + 4'd1;
                    operator_index <= 4'd0;
                end
            end
            SCRATCH_MEET_NUMBER: begin
                postfix_data[postfix_index] <= saved_data[saved_index];
                postfix_index <= postfix_index + 4'd1;
                saved_index <= saved_index + 4'd1;
            end
            SCRATCH_MEET_OPERATOR: begin
                if((saved_data[saved_index] == 7'd19 || saved_data[saved_index] == 7'd20)  && scratch_operator_data[scratch_operator_index_minus_one] == 7'd18) //遇到要pop到postfix_data的情況
                    tmp_operator <= saved_data[saved_index];
                else begin
                    scratch_operator_data[scratch_operator_index] <= saved_data[saved_index];
                    scratch_operator_index <= scratch_operator_index + 4'd1;
                    saved_index <= saved_index + 4'd1;
                end
            end
            SCRATCH_POP_OPERATOR: begin
                if(scratch_operator_index != 4'd0) begin
                    postfix_data[postfix_index] <= scratch_operator_data[scratch_operator_index];
                    postfix_index <= postfix_index + 4'd1;
                    scratch_operator_index <= scratch_operator_index - 4'd1;
                end
                else begin      
                    postfix_data[postfix_index] <= scratch_operator_data[scratch_operator_index];
                    postfix_index <= postfix_index + 4'd1;
                    scratch_operator_index <= 4'd0;
                end
            end
            CALCULATION : begin
                if(postfix_data[postfix_index] != 7'd21) begin
                    if(postfix_data[postfix_index] <= 7'd15) begin //if number
                        output_data[output_index] <= postfix_data[postfix_index];
			            postfix_index <= postfix_index + 4'd1;
                        output_index <= output_index + 4'd1;
                    end
                    else begin
                        output_data[output_index] <= postfix_data[postfix_index];
                        case(output_data[output_index])
                            8'd18: begin //*
                                output_data[output_index-4'd2] <= (output_data[output_index-4'd2] * output_data[output_index-4'd1]);
                                output_index <= output_index - 4'd1;
				                postfix_index <= postfix_index + 4'd1;
                            end
                            8'd19:begin
                                output_data[output_index-4'd2] <= (output_data[output_index-4'd2] + output_data[output_index-4'd1]);
                                output_index <= output_index - 4'd1;
				                postfix_index <= postfix_index + 4'd1;
                            end
                            8'd20:begin
                                output_data[output_index-4'd2] <= (output_data[output_index-4'd2] - output_data[output_index-4'd1]);
                                output_index <= output_index - 4'd1;
				                postfix_index <= postfix_index + 4'd1;
                            end
                        endcase
                        //output_index <= output_index + 4'd1;
                    end
                    
                end
            end
            OUTPUT_RESULT: begin
                result <= output_data[4'd0];
                valid <= 1'b1;
            end
            REINITIALIZE: begin
                for(i=0;i<16;i=i+1) begin
                    saved_data[i] <= 7'd0;
                    postfix_data[i] <= 7'd0; 
                    output_data[i] <= 7'd0;
                end
                valid <= 1'b0;
                saved_index <= 4'd0;
                postfix_index <= 4'd0;
                operator_index <= 4'd0;
                tmp_operator <= 7'd0;
                output_index <= 5'd0;
            end
        endcase
    end 

endmodule