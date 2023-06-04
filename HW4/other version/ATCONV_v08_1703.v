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
parameter SET_ADDRESS = 3'd1;
parameter GET_IMAGE_DATA = 3'd2;
parameter CALCULATE_KERNEL = 3'd3;
parameter WRITE2L0 = 3'd4;
parameter MAXPOOL = 3'd5;
parameter END_PROGRAM = 3'd6;


reg [2:0] state, nextState;
reg [3:0] stage;  
reg signed [12:0] conv_data [0:8]; //saved data from reading image, total 9 datas;
reg [3:0] conv_index;	//conv_data index;
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
			SET_ADDRESS: begin
				nextState = GET_IMAGE_DATA;
			end
			GET_IMAGE_DATA: begin
				if(conv_index <= 4'd8) nextState = GET_IMAGE_DATA;
				else nextState = CALCULATE_KERNEL;
			end
			CALCULATE_KERNEL: begin
				if(stage != 4'd1) nextState = CALCULATE_KERNEL;
				else nextState = WRITE2L0;
			end
			WRITE2L0: begin
				if(stage == 4'd1 && i == 4096) nextState = MAXPOOL;
				else if(stage == 4'd1 && i != 4096) nextState = SET_ADDRESS;
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
			SET_ADDRESS: begin
				case(j)
					6'd0: begin //first column
						if(i == 0 || i == 64) begin
							conv_data[0] <= 13'd0;
							conv_data[1] <= 13'd0;
							conv_data[2] <= 13'd2;
						end
						else begin
							conv_data[0] <= top;
							conv_data[1] <= top;
							conv_data[2] <= righttop;
						end
						conv_data[3] <= i;
						//conv_data[4] <= i;
						conv_data[5] <= right;
						if(i == 3968 || i == 4032) begin
							conv_data[6] <= 4032;
							conv_data[7] <= 4032;
							conv_data[8] <= 4034;
						end
						else begin
							conv_data[6] <= bottom;
							conv_data[7] <= bottom;
							conv_data[8] <= rightbottom;
						end
					end
					6'd1: begin
						if(i == 1 || i == 65) begin
							conv_data[0] <= 13'd0;
							conv_data[1] <= 13'd1;
							conv_data[2] <= 13'd3;
						end
						else begin
							conv_data[0] <= i - vertical - 13'd1;
							conv_data[1] <= top;
							conv_data[2] <= righttop;
						end
						conv_data[3] <= i - 13'd1;
						//conv_data[4] <= i;
						conv_data[5] <= right;
						if(i == 3969 || i == 4033) begin
							conv_data[6] <= 4032;
							conv_data[7] <= 4033;
							conv_data[8] <= 4035;
						end
						else begin
							conv_data[6] <= i + vertical - 13'd1;
							conv_data[7] <= bottom;
							conv_data[8] <= rightbottom;
						end
					end
					6'd62: begin
						if(i == 62 || i == 126) begin
							conv_data[0] <= 13'd60;
							conv_data[1] <= 13'd62;
							conv_data[2] <= 13'd63;
						end
						else begin
							conv_data[0] <= lefttop;
							conv_data[1] <= top;
							conv_data[2] <= i - vertical + 13'd1;
						end
						conv_data[3] <= left;
						//conv_data[4] <= i;
						conv_data[5] <= i + 13'd1;
						if(i == 4030 || i == 4094) begin
							conv_data[6] <= 4092;
							conv_data[7] <= 4094;
							conv_data[8] <= 4095;
						end
						else begin
							conv_data[6] <= leftbottom;
							conv_data[7] <= bottom;
							conv_data[8] <= i + vertical + 13'd1;
						end
					end
					6'd63: begin
						if(i == 63 || i == 127) begin
							conv_data[0] <= 13'd61;
							conv_data[1] <= 13'd63;
							conv_data[2] <= 13'd63;
						end
						else begin
							conv_data[0] <= lefttop;
							conv_data[1] <= top;
							conv_data[2] <= top;
						end
						conv_data[3] <= left;
						//conv_data[4] <= i;
						conv_data[5] <= i;
						if(i == 4031 || i == 4095) begin
							conv_data[6] <= 4093;
							conv_data[7] <= 4095;
							conv_data[8] <= 4095;
						end
						else begin
							conv_data[6] <= leftbottom;
							conv_data[7] <= bottom;
							conv_data[8] <= bottom;
						end
					end
					default: begin
						if(i <= 13'd61 && i >= 13'd2) begin
							conv_data[0] <= left;
							conv_data[1] <= i;
							conv_data[2] <= right;
						end
						else if (i <= 13'd125 && i >= 13'd66) begin
							conv_data[0] <= i - 13'd66;
							conv_data[1] <= i - 13'd64;
							conv_data[2] <= i - 13'd62;
						end
						else begin
							conv_data[0] <= lefttop;
							conv_data[1] <= top;
							conv_data[2] <= righttop;
						end
						conv_data[3] <= left;									
						//conv_data[4] <= i;									
						conv_data[5] <= right;
						if(i >= 13'd3970 && i <= 13'd4029) begin
							conv_data[6] <= i + 13'd62;
							conv_data[7] <= i + 13'd64;
							conv_data[8] <= i + 13'd66;
						end
						else if(i >= 13'd4034 && i <= 13'd4093) begin
							conv_data[6] <= left;										
							conv_data[7] <= i;
							conv_data[8] <= right;
						end
						else begin
							conv_data[6] <= leftbottom;
							conv_data[7] <= bottom;
							conv_data[8] <= rightbottom;
						end	
					end
				endcase
				conv_data[4] <= i;
			end
			GET_IMAGE_DATA: begin
				case(stage)
					4'd0: begin
						iaddr <= conv_data[conv_index];
						stage <= 4'd1;
					end
					4'd1: begin
						conv_data[conv_index] <= idata;
						iaddr <= conv_data[conv_index_plus_one];
						conv_index <= conv_index_plus_one;
					end
				endcase
				if(conv_index == 9) begin
					conv_index <= 4'd0;
					stage <= 4'd0;
				end
			end
			CALCULATE_KERNEL: begin
				case(stage)
					4'd0: begin
						conv_data[0] <= ~((conv_data[0][12:4] + conv_data[1][12:3] + conv_data[2][12:4] + conv_data[3][12:2] + conv_data[5][12:2] + conv_data[6][12:4] + conv_data[7][12:3] + conv_data[8][12:4]) + 13'b1100) + conv_data[4] + 13'b1;
						stage <= 4'd1;
					end
					4'd1: begin //ReLU
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
						//counter <= 4'd0;
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
						conv_data[conv_index] <= i;
						conv_data[conv_index + 1] <= L2;
						conv_data[conv_index + 2] <= R1;
						conv_data[conv_index + 3] <= R2;
						stage <= 4'd2;
					end
					4'd2: begin
						crd <= 1'd1;
						csel <= 1'd0;
						caddr_rd <= conv_data[conv_index];
						stage <= 4'd3;
					end
					4'd3: begin
						conv_data[conv_index] <= cdata_rd;
						caddr_rd <= conv_data[conv_index_plus_one];
						conv_index <= conv_index_plus_one;
						if(conv_index == 3) begin
							conv_index <= 4'd0;
							stage <= 4'd6;
						end
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