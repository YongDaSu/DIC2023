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
reg [2:0] stage;  
reg signed [12:0] conv_data [0:8]; //saved data from reading image, total 9 datas;
reg [3:0] conv_index;	//conv_data index;
reg [3:0] counter;	//counter for read/write image case;
reg	[12:0] i; //temp index for iaddr;
reg [5:0] j; //temp index for a loop;
reg[10:0] tmp_L1; //temp addr for L1;

parameter dilation = 13'd2;
parameter vertical = 13'd128;
integer k;

wire cmp0, cmp1;
assign cmp0 = conv_data[0] < conv_data[1];
assign cmp1 = conv_data[2] < conv_data[3];

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

// wire [12:0]carry01 = conv_data[0] + 13'b10000;
// wire [12:0]carry02 = conv_data[1] + 13'b10000;
// wire [12:0]carry03 = conv_data[2] + 13'b10000;
// wire [12:0]carry04 = conv_data[3] + 13'b10000;



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
				if(stage != 2'd1) nextState = CALCULATE_KERNEL;
				else nextState = WRITE2L0;
			end
			WRITE2L0: begin
				if(stage == 3'd1 && i == 4096) nextState = MAXPOOL;
				else if(stage == 3'd1 && i != 4096) nextState = GET_IMAGE_DATA;
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
		stage <= 2'd0;
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
						case(i)
							13'd0: begin //addr = 0;
								case(counter)
									4'd0: iaddr <= 13'd0;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd0;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd2;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd0;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd0;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd2;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd128;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd128;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd130;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;	
							end
							13'd64: begin //addr = 64
								case(counter)
									4'd0: iaddr <= 13'd0;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd0;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd2;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd64;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd64;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd66;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd192;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd192;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd194;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd3968: begin //addr = 3968
								case(counter)
									4'd0: iaddr <= 13'd3840;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3840;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3842;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3968;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3968;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3970;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4034;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4032: begin
								case(counter)
									4'd0: iaddr <= 13'd3904;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3904;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3906;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4034;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4034;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							default: begin //other first column
								case(counter)
									4'd0: iaddr <= top;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= top;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= righttop;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= right;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= bottom;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= bottom;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= rightbottom;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
						endcase
						
					end
					6'd1: begin
						case(i)
							13'd1: begin
								case(counter)
									4'd0: iaddr <= 13'd0;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd1;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd0;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd1;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd128;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd129;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd131;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd65: begin
								case(counter)
									4'd0: iaddr <= 13'd0;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd1;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd64;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd65;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd67;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd192;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd193;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd195;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd3969: begin
								case(counter)
									4'd0: iaddr <= 13'd3840;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3841;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3843;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3968;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3969;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3971;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4033;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4035;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4033: begin
								case(counter)
									4'd0: iaddr <= 13'd3904;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3905;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3907;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4033;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4035;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4032;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4033;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4035;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							default: begin
								case(counter)
									4'd0: iaddr <= i - vertical - 13'd1;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical + dilation;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - 13'd1;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical - 13'd1;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical + dilation;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
						endcase
					end
					6'd62: begin
						case(i)
							13'd62: begin
								case(counter)
									4'd0: iaddr <= 13'd60;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd62;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd60;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd62;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd188;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd190;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd191;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd126: begin
								case(counter)
									4'd0: iaddr <= 13'd60;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd62;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd124;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd126;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd127;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd252;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd254;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd255;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4030: begin
								case(counter)
									4'd0: iaddr <= 13'd3900;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3902;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3903;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4028;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4030;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4031;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4092;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4094;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4094: begin
								case(counter)
									4'd0: iaddr <= 13'd3964;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3966;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3967;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4092;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4094;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4092;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4094;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							default: begin
								case(counter)
									4'd0: iaddr <=  i - vertical - dilation;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical + 13'd1;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + 13'd1;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical - dilation;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical + 13'd1;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
						endcase
					end
					6'd63: begin
						case(i)
							13'd63: begin
								case(counter)
									4'd0: iaddr <= 13'd61;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd61;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd189;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd191;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd191;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd127: begin
								case(counter)
									4'd0: iaddr <= 13'd61;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd63;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd125;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd127;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd127;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd253;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd255;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd255;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4031: begin
								case(counter)
									4'd0: iaddr <= 13'd3901;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3903;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3903;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4029;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4031;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4031;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4093;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							13'd4095: begin
								case(counter)
									4'd0: iaddr <= 13'd3965;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3967;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd3967;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4093;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4093;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= 13'd4095;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
							default: begin
								case(counter)
									4'd0: iaddr <= i - vertical - dilation;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical - dilation;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
							end
						endcase
					end
					default: begin
						if(i <= 13'd61 && i >= 13'd2) begin
							case(counter)
									4'd0: iaddr <= i - dilation;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical - dilation;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical + dilation;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
						end
						else if(i <= 13'd125 && i >= 13'd66 ) begin
							case(counter)
									4'd0: iaddr <= i - 13'd66;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - 13'd64;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - 13'd62;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical - dilation;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + vertical + dilation;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
						end
						else if(i >= 13'd3970 && i <= 13'd4029) begin
							case(counter)
									4'd0: iaddr <= i - vertical - dilation;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical + dilation;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + 13'd62;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + 13'd64;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + 13'd66;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
						end
						else if(i >= 13'd4034 && i <= 13'd4093) begin
							case(counter)
									4'd0: iaddr <= i - vertical - dilation;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - vertical + dilation;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i - dilation;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i + dilation;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
						end
						else begin  //normal situation
							case(counter)
									4'd0: iaddr <= lefttop;
									4'd1: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= top;
									end
									4'd2: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= righttop;
									end
									4'd3: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= left;
									end
									4'd4: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= i;
									end
									4'd5: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= right;
									end
									4'd6: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= leftbottom;
									end
									4'd7: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= bottom;
									end
									4'd8: begin
										conv_data[conv_index] <= idata;
										conv_index <= conv_index_plus_one;
										iaddr <= rightbottom;
									end
									4'd9: begin
										conv_data[conv_index] <= idata;
										conv_index <= 4'd0;
									end
								endcase
								counter <= counter_plus_one;
						end
					end
				endcase
			end
			CALCULATE_KERNEL: begin
				case(stage)
					3'd0: begin
						conv_data[0] <= ~((conv_data[0][12:4] + conv_data[1][12:3] + conv_data[2][12:4] + conv_data[3][12:2] + conv_data[5][12:2] + conv_data[6][12:4] + conv_data[7][12:3] + conv_data[8][12:4]) + 13'b1100) + conv_data[4] + 13'b1;
						stage <= 3'd1;
					end
					3'd1: begin //ReLU
						//if((conv_data[0] >> 12) && 13'd1 == 1) conv_data[0] <= 13'd0;
						if(conv_data[0][12] == 1'b1) conv_data[0] <= 13'd0;
						stage <= 3'd0;
						
					end
				endcase
			end
			WRITE2L0: begin
				case(stage) 
					3'd0: begin
						if(j < 63) j <= j + 1;
						else j <= 0;
						counter <= 4'd0;
						i <= i + 13'd1;
						conv_index <= 4'd0;
						csel <= 1'd0;
						caddr_wr <= i;
						cdata_wr <= conv_data[0];
						cwr <= 1'd1;
						stage <= 3'd1;
					end
					3'd1: begin
						cwr <= 1'd0;
						stage <= 3'd0;
						//caddr_wr <= 13'd0;
						//display("first pixel : %h.", conv_data[0]);
					end
				endcase
			end
			MAXPOOL: begin
			 	case(stage)
			 		3'd0: begin
			 			i <= 13'd0;
			 			j <= 6'd0;
			 			counter <= 4'd0;
			 			conv_index <= 4'd0;
			 			stage <= 3'd1;
			 			//csel <= 1'd0; //select L0
			 			//for(k=0; k<9; k = k+1) begin
			 			//	conv_data[k] <= 13'd0; 
			 			//end
			 		end
			 		3'd1: begin
			 			case(counter)
			 				4'd0: begin
								crd <= 1'd1;
								csel <= 1'd0;
			 					caddr_rd <= i;
			 					counter <= counter_plus_one;
			 				end
			 				4'd1: begin
			 					conv_data[conv_index] <= cdata_rd;
			 					caddr_rd <= L2;
			 					conv_index <= conv_index_plus_one;
			 					counter <= counter_plus_one;
			 				end
			 				4'd2: begin
			 					conv_data[conv_index] <= cdata_rd;
			 					caddr_rd <= R1;
			 					conv_index <= conv_index_plus_one;
			 					counter <= counter_plus_one;
			 				end
			 				4'd3: begin
			 					conv_data[conv_index] <= cdata_rd;
			 					caddr_rd <= R2;
			 					conv_index <= conv_index_plus_one;
			 					counter <= counter_plus_one;
			 				end
			 				4'd4: begin
			 					conv_data[conv_index] <= cdata_rd;
			 					conv_index <= 4'd0;
								counter <= 4'd0;
			 					stage <= 3'd2;
			 					//i <= i + 13'd1;
								crd <= 1'd0;
			 				end
			 				default: stage <= 2'd2;
			 			endcase
			 		end
					3'd2: begin
						for(k=0;k<4;k=k+1) begin
							if(conv_data[k][3:0] != 4'b0000) begin
								conv_data[k] <= conv_data[k] + 13'b10000;
								conv_data[k][3:0] <= 4'b0000;
							end 
						end
						stage <= 3'd3;

						// if (conv_data[0][3:0] != 4'b0000) begin
						// 	conv_data[0] <= carry01;
						// 	conv_data[0][3:0] <= 4'b0000;
						// end
						// if (conv_data[1][3:0] != 4'b0000) begin
						// 	conv_data[1] <= carry02;
						// 	conv_data[1][3:0] <= 4'b0000;
						// end
						// if (conv_data[2][3:0] != 4'b0000) begin
						// 	conv_data[2] <= carry03;
						// 	conv_data[2][3:0] <= 4'b0000;
						// end
						// if (conv_data[3][3:0] != 4'b0000) begin
						// 	conv_data[3] <= carry04;
						// 	conv_data[3][3:0] <= 4'b0000;
						// end

						// if(conv_index <= 3) begin
						// 	if(conv_data[conv_index][3:0] != 4'b0000) begin
						// 		conv_data[conv_index] <= conv_data[conv_index] + 13'b10000;
						// 		conv_data[conv_index][3:0] <= 4'b0000;
						// 	end
						// 	conv_index <= conv_index_plus_one;
						// end
						// else begin
						// 	conv_index <= 4'd0;
						//  	stage <= 3'd3;
						// end
					end
			 		3'd3: begin
						if(conv_data[0] < conv_data[1]) conv_data[0] = conv_data[1];
							if(conv_data[2] < conv_data[3]) conv_data[2] = conv_data[3];
								if(conv_data[0] < conv_data[2]) conv_data[0] = conv_data[2];
						else 
							if(conv_data[2] < conv_data[3]) conv_data[2] = conv_data[3];
								if(conv_data[0] < conv_data[2]) conv_data[0] = conv_data[2];

						// if(conv_data[0] < conv_data[1]) begin
						// 	conv_data[0] <= conv_data[1];
						// end
						// if(conv_data[2] < conv_data[3]) begin
						// 	conv_data[2] <= conv_data[3];
						// end

			 			// case(cmp0)
			 			// 	1'd0: conv_data[0] <= conv_data[0];
			 			// 	1'd1: conv_data[0] <= conv_data[1]; 
			 			// endcase
			 			// case(cmp1)
			 			// 	1'd0: conv_data[2] <= conv_data[2];
			 			// 	1'd1: conv_data[2] <= conv_data[3]; 
			 			// endcase
			 			stage <= 3'd5;
			 		end
			 		// 3'd4: begin
			 		// 	if(conv_data[0] < conv_data[2]) conv_data[0] <= conv_data[2];
			 		// 	//else conv_data[0] <= conv_data[0];
			 		// 	stage <= 3'd5;
			 		// end
			 		3'd5: begin
			 			csel <= 1'd1;
			 			caddr_wr <= tmp_L1;
			 			cdata_wr <= conv_data[0];
			 			cwr <= 1'd1;
			 			stage <= 3'd6;
			 		end
			 		3'd6: begin
						csel <= 1'd0;
			 			cwr <= 1'd0;
			 			stage <= 3'd1;
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