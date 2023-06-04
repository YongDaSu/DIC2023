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

// parameter dilation = 13'd2;
// parameter vertical = 13'd128;
integer k;

// wire cmp0, cmp1;
// assign cmp0 = conv_data[0] < conv_data[1];
// assign cmp1 = conv_data[2] < conv_data[3];

wire [12:0]lefttop = ((j - 2) << 6) + i - 2;
wire [12:0]top = ((j - 2) << 6) + i;
wire [12:0]righttop = ((j - 2) << 6) + i + 2;
wire [12:0]left = (j << 6) + i - 2;
wire [12:0]middle = (j << 6) + i;
wire [12:0]right = (j << 6) + i + 2;
wire [12:0]leftbottom = ((j + 2) << 6) + i - 2;
wire [12:0]bottom = ((j + 2) << 6) + i;
wire [12:0]rightbottom = ((j + 2) << 6) + i + 2;


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
				if(counter < 4'd9) nextState = GET_IMAGE_DATA;
				else nextState = CALCULATE_KERNEL;
			end
			CALCULATE_KERNEL: begin
				if(stage != 4'd1) nextState = CALCULATE_KERNEL;
				else nextState = WRITE2L0;
			end
			WRITE2L0: begin
				if(stage == 4'd1 && j == 0 && i == 0) nextState = MAXPOOL;
				else if(stage == 4'd1 && (j != 0 || i != 0)) nextState = GET_IMAGE_DATA;
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
					0, 1: begin
						case(i)
							13'd0, 13'd1: begin
								case(counter)
									4'd0: iaddr <= 0;
									4'd1: begin
										iaddr <= i;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= i + 2;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= middle - i;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= bottom - i;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= rightbottom;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
							13'd62, 13'd63: begin
								case(counter)
									4'd0: iaddr <= i - 2;
									4'd1: begin
										iaddr <= i;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= 63;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= middle + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= leftbottom;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= bottom + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
							default: begin
								case(counter)
									4'd0: iaddr <= i - 2;
									4'd1: begin
										iaddr <= i;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= i + 2;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= leftbottom;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= rightbottom;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
						endcase
					end
					62, 63: begin
						case(i)
							13'd0, 13'd1: begin
								case(counter)
									4'd0: iaddr <= (j - 2) << 6;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= righttop;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= j << 6;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= 4032;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= 4032 + i;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= 4032 + i + 2;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end	
							13'd62, 13'd63: begin
								case(counter)
									4'd0: iaddr <= lefttop;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= top + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= middle + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= left + ((63 - j) << 6);
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= middle + ((63 - j) << 6);
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= 4095;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
							default: begin
								case(counter)
									4'd0: iaddr <= lefttop;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= righttop;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= left + ((63 - j) << 6);
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= middle + ((63 - j) << 6);
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= right + ((63 - j) << 6);
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
						endcase
					end
					default: begin
						case(i)
							13'd0, 13'd1: begin
								case(counter)
									4'd0: iaddr <= top - i;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= righttop;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= middle - i;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= bottom - i;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= rightbottom;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
							13'd62, 13'd63: begin
								case(counter)
									4'd0: iaddr <= lefttop;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= top + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= middle + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= leftbottom;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= bottom + (63 - i);
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
							default: begin
								case(counter)
									4'd0: iaddr <= lefttop;
									4'd1: begin
										iaddr <= top;
										conv_data[conv_index] <= idata;
									end
									4'd2: begin
										iaddr <= righttop;
										conv_data[conv_index] <= idata;
									end
									4'd3: begin
										iaddr <= left;
										conv_data[conv_index] <= idata;
									end
									4'd4: begin
										iaddr <= middle;
										conv_data[conv_index] <= idata;
									end
									4'd5: begin
										iaddr <= right;
										conv_data[conv_index] <= idata;
									end
									4'd6: begin
										iaddr <= leftbottom;
										conv_data[conv_index] <= idata;
									end
									4'd7: begin
										iaddr <= bottom;
										conv_data[conv_index] <= idata;
									end
									4'd8: begin
										iaddr <= rightbottom;
										conv_data[conv_index] <= idata;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
									end
								endcase
							end
						endcase	
					end
				endcase
				counter <= counter_plus_one;
				if (counter != 4'd0) conv_index <= conv_index_plus_one;
				//if(counter != 4'd0 || counter != 4'd9) conv_index <= conv_index_plus_one;
				//else conv_index <= 4'd0;	
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
						counter <= 4'd0;
						conv_index <= 4'd0;
						csel <= 1'd0;
						caddr_wr <= middle;
						cdata_wr <= conv_data[0];
						cwr <= 1'd1;
						stage <= 4'd1;
						if(j != 63) begin
							if(i != 63) begin
								i <= i + 1;
							end
							else begin
								i <= 0;
								j <= j + 1;
							end
						end
						else begin
							if(i != 63) begin
								i <= i + 1;
							end
							else begin
								i <= 0;
								j <= 0;
							end
						end
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
					4'd6: begin
						for(k=0;k<4;k=k+1) begin
							if(conv_data[k][3:0] != 4'b0000) begin
								conv_data[k] <= conv_data[k] + 13'b10000;
								conv_data[k][3:0] <= 4'b0000;
							end 
						end
						stage <= 4'd7;
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