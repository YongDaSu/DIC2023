module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output reg [7:0] result;


wire [7:0]out_1, out_2; 

MMS_4num four1(.result(out_1), .select(select), .number0(number0), .number1(number1), .number2(number2), .number3(number3));
MMS_4num four2(.result(out_2), .select(select), .number0(number4), .number1(number5), .number2(number6), .number3(number7));

always@(select or number0 or number1 or number2 or number3 or number4 or number5 or number6 or number7 or out_1 or out_2)
begin
	if (select)
		begin
			if (out_1 < out_2)
				result = out_1;
			else
				result = out_2;	
		end
	else
		begin
			if (out_1 < out_2)
				result = out_2;
			else
				result = out_1;	
		end
	
end
endmodule