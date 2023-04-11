module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output reg [7:0] result; 

reg [7:0]out_01, out_23; 

always@(number0 or number1 or number2 or number3 or select)
begin
	if(select)
		begin
			if(number0 < number1)
				out_01 = number0;
			else
				out_01 = number1;
			if(number2 < number3)
				out_23 = number2;
			else 
				out_23 = number3;
			if(out_01 < out_23)
				result = out_01;
			else
				result = out_23;
		end
	
	else
		begin
			if(number0 < number1)
				out_01 = number1;
			else
				out_01 = number0;
			if(number2 < number3)
				out_23 = number3;
			else 
				out_23 = number2;
			if(out_01 < out_23)
				result = out_23;
			else
				result = out_01;
		end
end
endmodule