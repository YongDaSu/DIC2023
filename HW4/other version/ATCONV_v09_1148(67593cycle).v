`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

//=================================================
//            write your design below
//=================================================
parameter WAIT = 3'd0;
parameter GET_IMAGE_DATA = 3'd1;
parameter CALCULATE_KERNEL = 3'd2;
parameter WRITE2L0 = 3'd3;
parameter MAXPOOL = 3'd4;
parameter END_PROGRAM = 3'd5;

reg [2:0] state, nextState;
reg [3:0] stage;  
reg signed [12:0] conv_data [0:8]; //saved data from reading image, total 9 datas;
reg [3:0] conv_index;	//conv_data index;
reg [3:0] counter;	//counter for read/write image case;
reg	[12:0] i; //temp index for iaddr;
reg [5:0] j; //temp index for a loop;
reg[10:0] tmp_L1; //temp addr for L1;

parameter dilation = 13'd2;
parameter vertical = 13'd128;
integer k;

wire [12:0]lefttop = i - vertical - dilation;
wire [12:0]top = i - vertical;
wire [12:0]righttop = i - vertical + dilation;
wire [12:0]left = i - dilation;
wire [12:0]right = i + dilation;
wire [12:0]leftbottom = i + vertical - dilation;
wire [12:0]bottom = i + vertical;
wire [12:0]rightbottom = i + vertical + dilation;


wire [12:0]L2 = i + 13'd1;
wire [12:0]R1 = i + 13'd64;
wire [12:0]R2 = i + 13'd65;

wire [3:0]counter_plus_one = counter + 4'd1;
wire [3:0]conv_index_plus_one = conv_index + 4'd1;


always@(*) begin
	if(reset) begin
		nextState = WAIT;
	end
	else begin
		case(state)
			WAIT: begin
				if(!busy) nextState = WAIT;
				else nextState = GET_IMAGE_DATA;
			end
			GET_IMAGE_DATA: begin
				if(counter <= 4'd8) nextState = GET_IMAGE_DATA;
				else nextState = CALCULATE_KERNEL;
			end
			CALCULATE_KERNEL: begin
				if(stage != 4'd1) nextState = CALCULATE_KERNEL;
				else nextState = WRITE2L0;
			end
			WRITE2L0: begin
				if(stage == 4'd1 && i == 4096) nextState = MAXPOOL;
				else if(stage == 4'd1 && i != 4096) nextState = GET_IMAGE_DATA;
				else nextState = WRITE2L0;
			end
			MAXPOOL: begin
				if(tmp_L1 <= 11'd1023) nextState = MAXPOOL;
				else nextState = END_PROGRAM;
			end
			END_PROGRAM: begin
				nextState <= WAIT;
			end
		endcase
	end
end

always@(posedge clk) begin
	state <= nextState;
end

always@(posedge clk) begin
	if(reset) begin
		stage <= 4'd0;
		conv_index <= 4'd0; 
		counter <= 4'd0;
		i <= 13'd0;
		j <= 6'd0;
		tmp_L1 <= 11'd0;
		busy <= 1'd0;
		for(k=0; k<9; k = k+1) begin
			conv_data[k] <= 13'd0; 
		end
	end
	else begin
		case(state)
			WAIT: begin
				if(ready) begin
					busy <= 1'd1;
				end
			end
			GET_IMAGE_DATA: begin
				case(j)
					6'd0: begin //first column
						case(counter)
							4'd0: begin
								if(i == 0 || i == 64) iaddr <= 0;
								else iaddr <= top;
							end
							4'd1: begin
								conv_data[conv_index] <= idata;										
								if(i == 0 || i == 64) iaddr <= 0;
								else iaddr <= top;
							end
							4'd2: begin
								conv_data[conv_index] <= idata;
								if(i == 0 || i == 64) iaddr <= 2;
								else iaddr <= righttop;
							end
							4'd3: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd4: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd5: begin
								conv_data[conv_index] <= idata;										
								iaddr <= right;
							end
							4'd6: begin
								conv_data[conv_index] <= idata;
								if(i == 3968 || i == 4032) iaddr <= 4032;
								else iaddr <= bottom;
							end
							4'd7: begin
								conv_data[conv_index] <= idata;										
								if(i == 3968 || i == 4032) iaddr <= 4032;
								else iaddr <= bottom;
							end
							4'd8: begin
								conv_data[conv_index] <= idata;
								if(i == 3968 || i == 4032) iaddr <= 4034;
								else iaddr <= rightbottom;
							end
							4'd9: begin
								conv_data[conv_index] <= idata;
								conv_index <= 4'd0;
							end
						endcase
					end
					6'd1: begin
						case(counter)
							4'd0: begin
								if(i == 1 || i == 65) iaddr <= 0;
								else iaddr <= i - vertical - 13'd1;
							end
							4'd1: begin
								conv_data[conv_index] <= idata;
								if(i == 1 || i == 65) iaddr <= 1;
								else iaddr <= top;
							end
							4'd2: begin
								conv_data[conv_index] <= idata;
								if(i == 1 || i == 65) iaddr <= 3;
								else iaddr <= righttop;
							end
							4'd3: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i - 13'd1;
							end
							4'd4: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd5: begin
								conv_data[conv_index] <= idata;										
								iaddr <= right;
							end
							4'd6: begin
								conv_data[conv_index] <= idata;
								if(i == 3969 || i == 4033) iaddr <= 4032;
								else iaddr <= i + vertical - 13'd1;
							end
							4'd7: begin
								conv_data[conv_index] <= idata;
								if(i == 3969 || i == 4033) iaddr <= 4033;									
								else iaddr <= bottom;
							end
							4'd8: begin
								conv_data[conv_index] <= idata;	
								if(i == 3969 || i == 4033) iaddr <= 4035;									
								else iaddr <= rightbottom;
							end
							4'd9: begin
								conv_data[conv_index] <= idata;
								conv_index <= 4'd0;
							end
						endcase
					end
					6'd62: begin
						case(counter)
							4'd0: begin
								if(i == 62 || i == 126) iaddr <= 60;
								else iaddr <=  lefttop;
							end
							4'd1: begin
								conv_data[conv_index] <= idata;
								if(i == 62 || i == 126) iaddr <= 62;									
								else iaddr <= top;
							end
							4'd2: begin
								conv_data[conv_index] <= idata;
								if(i == 62 || i == 126) iaddr <= 63;								
								else iaddr <= i - vertical + 13'd1;
							end
							4'd3: begin
								conv_data[conv_index] <= idata;									
								iaddr <= left;
							end
							4'd4: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd5: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i + 13'd1;
							end
							4'd6: begin
								conv_data[conv_index] <= idata;
								if(i == 4030 || i == 4094)	iaddr <= 4092;								
								else iaddr <= leftbottom;
							end
							4'd7: begin
								conv_data[conv_index] <= idata;
								if(i == 4030 || i == 4094)	iaddr <= 4094;											
								else iaddr <= bottom;
							end
							4'd8: begin
								conv_data[conv_index] <= idata;
								if(i == 4030 || i == 4094)	iaddr <= 4095;									
								else iaddr <= i + vertical + 13'd1;
							end
							4'd9: begin
								conv_data[conv_index] <= idata;
								conv_index <= 4'd0;
							end
						endcase
					end
					6'd63: begin
						case(counter)
							4'd0: begin
								if(i == 63 || i == 127) iaddr <= 61;
								else iaddr <= lefttop;
							end
							4'd1: begin
								conv_data[conv_index] <= idata;
								if(i == 63 || i == 127) iaddr <= 63;									
								else iaddr <= top;
							end
							4'd2: begin
								conv_data[conv_index] <= idata;
								if(i == 63 || i == 127) iaddr <= 63;									
								else iaddr <= top;
							end
							4'd3: begin
								conv_data[conv_index] <= idata;										
								iaddr <= left;
							end
							4'd4: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd5: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd6: begin
								conv_data[conv_index] <= idata;
								if(i == 4031 || i == 4095) iaddr <= 4093;									
								else iaddr <= leftbottom;
							end
							4'd7: begin
								conv_data[conv_index] <= idata;
								if(i == 4031 || i == 4095) iaddr <= 4095;										
								else iaddr <= bottom;
							end
							4'd8: begin
								conv_data[conv_index] <= idata;
								if(i == 4031 || i == 4095)	iaddr <= 4095;										
								else iaddr <= bottom;
							end
							4'd9: begin
								conv_data[conv_index] <= idata;
								conv_index <= 4'd0;
							end
						endcase
					end
					default: begin
						case(counter)
							4'd0: begin
								if(i <= 13'd61 && i >= 13'd2) iaddr <= left;
								else if(i <= 13'd125 && i >= 13'd66) iaddr <= i - 13'd66;
								else iaddr <= lefttop;
							end
							4'd1: begin
								conv_data[conv_index] <= idata;		
								if(i <= 13'd61 && i >= 13'd2) iaddr <= i;
								else if(i <= 13'd125 && i >= 13'd66) iaddr <= i - 13'd64;
								else iaddr <= top;			
							end
							4'd2: begin
								conv_data[conv_index] <= idata;
								if(i <= 13'd61 && i >= 13'd2) iaddr <= right;
								else if (i <= 13'd125 && i >= 13'd66) iaddr <= i - 13'd62;
								else iaddr <= righttop;						
							end
							4'd3: begin
								conv_data[conv_index] <= idata;										
								iaddr <= left;
							end
							4'd4: begin
								conv_data[conv_index] <= idata;										
								iaddr <= i;
							end
							4'd5: begin
								conv_data[conv_index] <= idata;										
								iaddr <= right;
							end
							4'd6: begin
								conv_data[conv_index] <= idata;
								if(i >= 13'd3970 && i <= 13'd4029) iaddr <= i + 13'd62;
								else if(i >= 13'd4034 && i <= 13'd4093) iaddr <= left;										
								else iaddr <= leftbottom;
							end
							4'd7: begin
								conv_data[conv_index] <= idata;
								if(i >= 13'd3970 && i <= 13'd4029)	iaddr <= i + 13'd64;
								else if(i >= 13'd4034 && i <= 13'd4093) iaddr <= i;									
								else iaddr <= bottom;
							end
							4'd8: begin
								conv_data[conv_index] <= idata;
								if(i >= 13'd3970 && i <= 13'd4029) iaddr <= i + 13'd66;
								else if(i >= 13'd4034 && i <= 13'd4093) iaddr <= right;									
								else iaddr <= rightbottom;
							end
							4'd9: begin
								conv_data[conv_index] <= idata;										
								conv_index <= 4'd0;
							end
						endcase
					end
				endcase
				counter <= counter_plus_one;
				if(counter != 4'd0 && counter != 4'd9) conv_index <= conv_index_plus_one;
			end
			CALCULATE_KERNEL: begin
				case(stage)
					4'd0: begin
						conv_data[0] <= ~((conv_data[0][12:4] + conv_data[1][12:3] + conv_data[2][12:4] + conv_data[3][12:2] + conv_data[5][12:2] + conv_data[6][12:4] + conv_data[7][12:3] + conv_data[8][12:4]) + 13'b1100) + conv_data[4] + 13'b1;
						stage <= 4'd1;
					end
					4'd1: begin //ReLU
						//if((conv_data[0] >> 12) && 13'd1 == 1) conv_data[0] <= 13'd0;
						if(conv_data[0][12] == 1'b1) conv_data[0] <= 13'd0;
						stage <= 4'd0;	
					end
				endcase
			end
			WRITE2L0: begin
				case(stage) 
					4'd0: begin
						if(j < 63) j <= j + 1;
						else j <= 0;
						counter <= 4'd0;
						i <= i + 13'd1;
						conv_index <= 4'd0;
						csel <= 1'd0;
						caddr_wr <= i;
						cdata_wr <= conv_data[0];
						cwr <= 1'd1;
						stage <= 4'd1;
					end
					4'd1: begin
						cwr <= 1'd0;
						stage <= 4'd0;
					end
				endcase
			end
			MAXPOOL: begin
			 	case(stage)
			 		4'd0: begin
			 			i <= 13'd0;
			 			j <= 6'd0;
			 			conv_index <= 4'd0;
			 			stage <= 4'd1;
			 		end
					4'd1: begin
						crd <= 1'd1;
						csel <= 1'd0;
						caddr_rd <= i;
						stage <= 4'd2;
					end
					4'd2: begin
						conv_data[conv_index] <= cdata_rd;
						caddr_rd <= L2;
						conv_index <= conv_index_plus_one;
						stage <= 4'd3;
					end
					4'd3: begin
						conv_data[conv_index] <= cdata_rd;
						caddr_rd <= R1;
						conv_index <= conv_index_plus_one;
						stage <= 4'd4;
					end
					4'd4: begin
						conv_data[conv_index] <= cdata_rd;
						caddr_rd <= R2;
						conv_index <= conv_index_plus_one;
						stage <= 4'd5;
					end
					4'd5: begin
						conv_data[conv_index] <= cdata_rd;
						conv_index <= 4'd0;
						stage <= 4'd6;
						crd <= 1'd0;
					end
					3'd6: begin
						for(k=0;k<4;k=k+1) begin
							if(conv_data[k][3:0] != 4'b0000) begin
								conv_data[k] <= conv_data[k] + 13'b10000;
								conv_data[k][3:0] <= 4'b0000;
							end 
						end
						stage <= 3'd7;
					end
			 		4'd7: begin
						if(conv_data[0] < conv_data[1]) begin
							conv_data[0] <= conv_data[1];
						end
						if(conv_data[2] < conv_data[3]) begin
							conv_data[2] <= conv_data[3];
						end
			 			stage <= 4'd8;
			 		end
			 		4'd8: begin
			 			if(conv_data[0] < conv_data[2]) conv_data[0] <= conv_data[2];
			 			//else conv_data[0] <= conv_data[0];
			 			stage <= 4'd9;
			 		end
			 		4'd9: begin
			 			csel <= 1'd1;
			 			caddr_wr <= tmp_L1;
			 			cdata_wr <= conv_data[0];
			 			cwr <= 1'd1;
			 			stage <= 4'd10;
			 		end
			 		4'd10: begin
						csel <= 1'd0;
			 			cwr <= 1'd0;
			 			stage <= 4'd1;
			 			tmp_L1 <= tmp_L1 + 11'd1;
			 			if(j == 6'd31) begin
			 				j <= 6'd0;
			 				i <= i + 13'd66;
			 			end
			 			else begin
							i <= i + 13'd2;
							j <= j + 6'd1;
						end
					end
			 	endcase
			end
			END_PROGRAM: begin
				busy <= 1'd0;
			end
		endcase
	end
end
endmodule