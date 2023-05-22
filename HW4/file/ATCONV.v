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
	output  reg [12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

//=================================================
//            write your design below
//=================================================
parameter WAIT = 4'd0;
parameter SET_ADDR = 4'd1;
parameter GET_IMAGE_DATA = 4'd3;
parameter CALCULATE_KERNEL = 4'd4;
parameter READY2WR = 4'd10;
parameter WRITE2L0 = 4'd5;
parameter MAXPOOL = 4'd6;
parameter FILTER = 4'd7;
parameter WRITE2L1 = 4'd8;
parameter END_PROGRAM = 4'd9;

reg	[5:0] i; //temp index for iaddr;
reg [5:0] j; //temp index for a loop;
reg [11:0] tmp_L1; //temp addr for L1;
reg [3:0] conv_index;	//conv_data index;
reg signed [12:0] conv_data [8:0]; //saved data from reading image, total 9 datas;
reg [3:0] state,nextState;

// parameter dilation = 13'd2;
// parameter vertical = 13'd128;
integer k;

wire [12:0] cmp0, cmp1, cmp2;
assign cmp0 = conv_data[0] < conv_data[1]? conv_data[1]:conv_data[0];
assign cmp1 = conv_data[2] < conv_data[3]? conv_data[3]:conv_data[2];
assign cmp2 = cmp0<cmp1? cmp1:cmp0;

wire [12:0] lefttop = ((j - 2) << 6) + i - 2;
wire [12:0] top = ((j - 2) << 6) + i;
wire [12:0] righttop = ((j - 2) << 6) + i + 2;
wire [12:0] left = (j << 6) + i - 2;
wire [12:0] middle = (j << 6) + i;
wire [12:0] right = (j << 6) + i + 2;
wire [12:0] leftbottom = ((j + 2) << 6) + i - 2;
wire [12:0] bottom = ((j + 2) << 6) + i;
wire [12:0] rightbottom = ((j + 2) << 6) + i + 2;
wire [12:0] bias = (63 - i);

wire [12:0]L1 = ((j << 7) + (i << 1));
wire [12:0]L2 = L1 + 13'd1;
wire [12:0]R1 = L1 + 13'd64;
wire [12:0]R2 = L1 + 13'd65;

wire [3:0]conv_index_plus_one = conv_index + 4'd1;


always @(*) begin
	if(reset) begin
		nextState = WAIT;
	end
	else begin
		case(state)
			WAIT: begin
					if(!busy) nextState = WAIT;
					else nextState = SET_ADDR;
			end
			SET_ADDR:begin
				nextState = GET_IMAGE_DATA;
			end
			GET_IMAGE_DATA:begin
				if(conv_index == 9) nextState = CALCULATE_KERNEL;
				else nextState = GET_IMAGE_DATA;
			end
			CALCULATE_KERNEL:begin
				nextState = READY2WR;
			end
			READY2WR:begin
				nextState = WRITE2L0;
			end
			WRITE2L0:begin
				if(tmp_L1 == 4095) nextState = MAXPOOL;
				else	nextState = SET_ADDR;
			end
			MAXPOOL: begin
				nextState = FILTER;
			end
			FILTER: begin
				if(conv_index == 4) nextState = WRITE2L1;
				else nextState = FILTER;
			end
			WRITE2L1:begin
				if(tmp_L1 == 1023) nextState = END_PROGRAM;
				else nextState = MAXPOOL;
			end
			END_PROGRAM:begin
				nextState = WAIT;
			end
		endcase
	end
end

always @(posedge clk or posedge reset) begin
    if(reset) state <= WAIT;
    else state <= nextState;
end
//==FSM=================================

always @(posedge clk) begin
	if(reset) begin
		conv_index <= 4'd0;
		i <= 6'd0;
		j <= 6'd0;
		tmp_L1 <= 11'd0;
		busy <= 1'd0;
		for(k=0; k<9; k = k+1) begin
			conv_data[k] <= 13'd0; 
		end
	end
	else begin
		case (state)
			WAIT:begin//RstEverything
				if(ready) begin
					busy <= 1'd1;
				end						
			end
			SET_ADDR:begin
				case (j)
					0,1:begin
						case (i)
							0,1:begin
								conv_data[0]<=0;
								conv_data[2]<=i + 2;
								conv_data[3]<=middle-i;
								conv_data[5]<=right;
								conv_data[6]<=bottom-i;
								conv_data[8]<=rightbottom;																
							end
							62,63:begin
								conv_data[0]<=i - 2;
								conv_data[2]<=63;
								conv_data[3]<=left;
								conv_data[5]<=middle + bias;
								conv_data[6]<=leftbottom;
								conv_data[8]<=bottom + bias;
							end						
							default:begin
								conv_data[0]<=i - 2;
								conv_data[2]<=i + 2;
								conv_data[3]<=left;
								conv_data[5]<=right;
								conv_data[6]<=leftbottom;
								conv_data[8]<=rightbottom;
							end 
						endcase	
						conv_data[1]<=i;
						conv_data[7]<=bottom;				
					end
					62,63:begin
						case (i)
							0,1:begin
								conv_data[0]<=top - i;
								conv_data[2]<=righttop;
								conv_data[3]<=middle - i;
								conv_data[5]<=right;
								conv_data[6]<=4032;
								conv_data[8]<=4034+i;																
							end
							62,63:begin
								conv_data[0]<=lefttop;
								conv_data[2]<=top + bias;
								conv_data[3]<=left;
								conv_data[5]<=middle + bias;
								conv_data[6]<=4030+i;
								conv_data[8]<=4095;
							end						
							default:begin
								conv_data[0]<=lefttop;
								conv_data[2]<=righttop;
								conv_data[3]<=left;
								conv_data[5]<=right;
								conv_data[6]<=4030+i;
								conv_data[8]<=4034+i;
							end 
						endcase	
						conv_data[1]<=top;
						conv_data[7]<=i+4032;	
					end 
					default:begin
						case (i)
							0,1:begin
								conv_data[0]<=top-i;
								conv_data[2]<=righttop;
								conv_data[3]<=middle-i;
								conv_data[5]<=right;
								conv_data[6]<=bottom-i;
								conv_data[8]<=rightbottom;																
							end
							62,63:begin
								conv_data[0]<=lefttop;
								conv_data[2]<=top + bias;
								conv_data[3]<=left;
								conv_data[5]<=middle + bias;
								conv_data[6]<=leftbottom;
								conv_data[8]<=bottom + bias;							
							end						
							default:begin
								conv_data[0] <= lefttop;
								conv_data[2] <= righttop;
								conv_data[3] <= left;
								conv_data[5] <= right;
								conv_data[6] <= leftbottom;
								conv_data[8] <= rightbottom;							
							end 
						endcase	
						conv_data[1] <= top;
						conv_data[7] <= bottom;
					end 
				endcase	
				conv_data[4] <= middle;
			end
			GET_IMAGE_DATA:begin
				case(conv_index)
					4'd0: begin
						iaddr <= conv_data[conv_index];
						conv_index <= conv_index_plus_one;
					end
					4'd1: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd2: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd3: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd4: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd5: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd6: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd7: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd8: begin
						iaddr <= conv_data[conv_index];
						conv_data[conv_index - 1] <= idata;
						conv_index <= conv_index_plus_one;
					end
					4'd9: begin
						conv_data[conv_index - 1] <= idata;
						conv_index <= 4'd0;	
					end	
				endcase
			end
			CALCULATE_KERNEL:begin
				cdata_wr <= ~((conv_data[0][12:4] + conv_data[1][12:3] + conv_data[2][12:4] + conv_data[3][12:2] + conv_data[5][12:2] + conv_data[6][12:4] + conv_data[7][12:3] + conv_data[8][12:4]) + 13'b1100) + conv_data[4] + 13'b1;
			end
			READY2WR:begin
				if (cdata_wr[12]) begin
					cdata_wr <= 0;
				end
				cwr <= 1;
				csel <= 0;
				caddr_wr <= tmp_L1;
			end
			WRITE2L0: begin
				cwr <= 0;
				tmp_L1 <= tmp_L1 + 1;
				conv_index <= 0;
				i <= i + 1;
				if(i == 63) j <= j + 1;
			end
			MAXPOOL:begin
				cwr<=0;
				conv_data[0] <= L1;
				conv_data[1] <= L2;
				conv_data[2] <= R1;
				conv_data[3] <= R2;
				//if(tmp_L1 == 4095) tmp_L1 <= 0;
			end
			FILTER:begin
				crd <= 1;
				csel <= 0;
				caddr_rd <= conv_data[conv_index];
				if (conv_index) begin
					conv_data[conv_index - 1] <= cdata_rd;
				end
				conv_index <= conv_index + 1;
			end
			WRITE2L1:begin
				cwr <= 1;
				crd <= 0;
				csel <= 1;
				caddr_wr <= tmp_L1;
				tmp_L1 <= tmp_L1 + 1;
				conv_index <= 0;
				
				if(i == 31)begin
					i <= 0;
					j <= j + 1;
				end 
				else begin
					i <= i + 1;
				end				

				if (cmp2[3:0]) begin
					cdata_wr <= (cmp2 + 13'b10000) & 13'h1ff0 ;
				end
				else cdata_wr <= cmp2 & 13'h1ff0;
			end
			END_PROGRAM:begin
				busy<=0;
			end
		endcase
	end
end
endmodule