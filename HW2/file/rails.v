module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output reg   valid;
output reg   result;

//reg valid; reg result;

reg [1:0] step; assign step =0;
//step=0:collect data
//step=1:calculate result
//step=2:reset all value
reg [3:0] DD[0:10];		//Departure Data
reg [3:0] AD[0:10];		//Arriving Data
reg [3:0] station[0:10];	//empty stack, train station
reg [3:0] sp;			//stack pointer
reg [3:0] lengthofdata;
reg [3:0] count; 
reg [3:0] AD_count;
reg [3:0] DD_count; 


always@(posedge clk) begin
	
	if(reset) begin
		count <= 0;
		AD_count <= 0;
		DD_count <= 0;
		lengthofdata <= 0;
		sp <= 0;
	end
	else begin
		case(step)
		0: begin
			if(count == 0) begin
				lengthofdata = data;

			end
			else begin
				DD[count-1] = data;
				AD[count-1] = count;
			end
			count = count+1;
			if(count == (lengthofdata+1)) begin 						//when all data is conserved, go case1
				step = 1;
			end
		end
		1: begin
	
			if((AD_count != lengthofdata) || (DD[DD_count] == station[sp-1])) begin		//check the result is valid
				if(DD[DD_count] == AD[AD_count]) begin					// if the departing = arriving, pop out directly
					DD_count = DD_count+1;
					AD_count = AD_count+1;
				end
				else if (DD[DD_count] == station[sp-1]) begin				// else if the departing = station head, pop out
					DD_count = DD_count+1;					
					sp = sp-1;
					if(DD_count == lengthofdata) begin				// valid condition
						valid = 1;
						result = 1;
						step = 2;
					end
				end
				else begin
					station[sp] = AD[AD_count];					// if the DD != AD, put it into station array
					sp = sp+1;
					AD_count = AD_count+1;
				end
			end
			else if(AD_count == lengthofdata && DD_count == lengthofdata) begin		// valid condition
				valid = 1;
				result = 1;
				step = 2;
			end
			else begin									// if the AD is empty and the DD is not empty, failed
				valid = 1;
				result = 0;
				step = 2;
			end
		end
		2: begin										//re-initialize the parameters
			valid = 0;
			result = 0;
			step = 0;
			count = 0;
			AD_count = 0;
			DD_count = 0;
			lengthofdata = 0;
			sp = 0;
		end
		endcase
	end
end
endmodule