module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	output  reg  fwpass_finish,
	input		[7:0]	res_di
	);
	//fwpass_finish need to be rm after checking FWP;

parameter IDLE = 0,
		  READ = 1,
		  READ_DATA = 2,
		  DATA_WRITE = 3,
		  WRITE_DONE = 4,
		  ADR_CTR = 5,
		  GET_CTR = 6,
		  GET_NW = 7,
		  GET_N = 8,
		  GET_NE = 9,
		  GET_W = 10,
		  CAL_FWP = 11,
		  WRTIE_FWP = 12,
		  WAIT_FWP = 13,
		  FWP_DONE = 14,
		  BWP_ADR_CTR = 15,
		  BWP_GET_CTR = 16,
		  BWP_GET_E = 17,
		  BWP_GET_SW = 18,
		  BWP_GET_S = 19,
		  BWP_GET_SE = 20,
		  CAL_BWP = 21,
		  WRTIE_BWP = 22,
		  WAIT_BWP = 23,
		  DONE = 24;
		  

reg [ 24:0 ] cs,ns;
reg [3:0] cnt_delay;
//=========================================================================//
// comb. logic assignment
// forward min
	reg [7:0] for_NW; // same as E
	reg [7:0] for_N; // same as SW
	reg [7:0] for_NE; // same as S
	reg [7:0] for_W; // same as for_W
	reg [7:0] for_ctr; // same as for_ctr
	wire [7:0] for_comp1;
	wire [7:0] for_comp2;
	wire [7:0] for_min;
	assign for_comp1 = (for_NW <= for_N)? for_NW: for_N;
	assign for_comp2 = (for_NE <= for_W)? for_NE: for_W;
	assign for_min = (for_comp1 <= for_comp2)? (for_comp1 + 1'd1): (for_comp2 + 1'd1);
	
// backward min
/*	reg [7:0] for_ctr;
	reg [7:0] for_NW;
	reg [7:0] for_N;
	reg [7:0] for_NE;
	reg [7:0] for_W;
*/
	wire [7:0] back_comp1;
	wire [7:0] back_comp2;
	wire [7:0] back_temp;
	wire [7:0] back_min;
	assign back_comp1 = (for_NW <= for_N)? for_NW: for_N;
	assign back_comp2 = (for_NE <= for_W)? for_NE: for_W;
	assign back_temp = (back_comp1 <= back_comp2)? (back_comp1 + 1'b1):(back_comp2 + 1'b1);
	assign back_min = (for_ctr <= back_temp)? (for_ctr): (back_temp);

// position assignment
	wire [13:0] ker_NW;
	wire [13:0] ker_N;
	wire [13:0] ker_NE;
	wire [13:0] ker_W;
	wire [13:0] ker_E;
	wire [13:0] ker_SW;
	wire [13:0] ker_S;
	wire [13:0] ker_SE;
	reg [13:0] ker_ctr; // kernel center;
	assign ker_NW = ker_ctr - 14'd129;
	assign ker_N = ker_ctr - 14'd128;
	assign ker_NE = ker_ctr - 14'd127;
	assign ker_W = ker_ctr - 14'd1;
	assign ker_E = ker_ctr + 14'd1;
	assign ker_SW = ker_ctr + 14'd127;
	assign ker_S = ker_ctr + 14'd128;
	assign ker_SE = ker_ctr + 14'd129;
///
//FSM here
	always@(posedge clk or negedge reset) begin
		if(!reset) begin
			cs <= 'd0;
			cs[IDLE] <= 1'b1;
		end
		else cs <= ns;
	end

	always@(*)begin
		ns = 'd0;
		case(1'b1)
			cs[IDLE]: ns[READ] = 1'b1;
			cs[READ]: ns[READ_DATA] = 1'b1;
			cs[READ_DATA]: ns[DATA_WRITE] = 1'b1;
			cs[DATA_WRITE]:begin
				if( (res_addr == 14'd16383)) ns[WRITE_DONE] = 1'b1;
				else if(cnt_delay == 4'd15) ns[READ] = 1'b1;
				else ns[DATA_WRITE] = 1'b1;
			end
			cs[WRITE_DONE]: ns[ADR_CTR] = 1'b1;
			cs[ADR_CTR]: ns[GET_CTR] = 1'b1;
			cs[GET_CTR]: ns[GET_NW] = 1'b1;
			cs[GET_NW]: ns[GET_N] = 1'b1;
			cs[GET_N]: ns[GET_NE] = 1'b1;
			cs[GET_NE]: ns[GET_W] = 1'b1;
			cs[GET_W]: ns[CAL_FWP] = 1'b1;
			cs[CAL_FWP]: ns[WRTIE_FWP] = 1'b1;
			cs[WRTIE_FWP]: ns[WAIT_FWP] = 1'b1;
			cs[WAIT_FWP]: begin
				if(ker_ctr == 14'd16254) ns[FWP_DONE] = 1'b1;
				else ns[ADR_CTR] = 1'b1;
			end
			cs[FWP_DONE]: ns[BWP_ADR_CTR] = 1'b1;
			cs[BWP_ADR_CTR]: ns[BWP_GET_CTR] = 1'b1;
			cs[BWP_GET_CTR]: ns[BWP_GET_E] = 1'b1;
			cs[BWP_GET_E]: ns[BWP_GET_SW] = 1'b1;
			cs[BWP_GET_SW]: ns[BWP_GET_S] = 1'b1;
			cs[BWP_GET_S]: ns[BWP_GET_SE] = 1'b1;
			cs[BWP_GET_SE]: ns[CAL_BWP] = 1'b1;
			cs[CAL_BWP]: ns[WRTIE_BWP] = 1'b1;
			cs[WRTIE_BWP]: ns[WAIT_BWP] = 1'b1;
			cs[WAIT_BWP]:begin
				if(ker_ctr == 14'd129) ns[DONE] = 1'b1;
				else ns[BWP_ADR_CTR] = 1'b1;
			end
			cs[DONE]: ns[DONE] = 1'b1;
			default: ns[IDLE] = 1'b1;
		endcase
	end
	
	//registered output logic
	reg [15:0] line_di;
	reg [3:0] cnt;
	reg [13:0] res_addr_cnt;

	always@(posedge clk or negedge reset)begin
		if(!reset)begin
			done <= 'd0; 
			sti_rd <= 1'b0;
			sti_addr <= 'd0;
			res_wr <= 'd0;
			res_rd <= 'd0;
			res_addr <= 'd0;
			res_do <= 'd0;
			line_di <= 'd0;
			cnt <= 'd0;
			cnt_delay <= 'd0;
			res_addr_cnt <= 'd0;
			ker_ctr <= 14'd129;
			for_NW <= 'd0;
			for_N <= 'd0;
			for_NE <= 'd0;
			for_W <= 'd0;
			for_ctr <= 'd0;
			ker_ctr <= 14'd129;
			fwpass_finish <= 'd0;
			//fwpass bad bad
		end
		else begin
			case(1'b1)
				cs[IDLE]:begin
				done <= 'd0; 
				sti_rd <= 1'b0;
				sti_addr <= 'd0;
				res_wr <= 'd0;
				res_rd <= 'd0;
				res_addr <= 'd0;
				res_do <= 'd0;
				line_di <= 'd0;
				cnt <= 'd0;
				cnt_delay <= 'd0;
				res_addr_cnt <= 'd0;
				for_ctr <= 'd0;
				for_NW <= 'd0;
				for_N <= 'd0;
				for_NE <= 'd0;
				for_W <= 'd0;
				fwpass_finish <= 'd0;
				end
				cs[READ]:begin	
					sti_rd <= 1'b1;
					res_wr <= 1'b0;
					cnt <= 'd0;
					cnt_delay <='d0;
				end
				cs[READ_DATA]:begin
					sti_rd <= 1'b0;
					sti_addr <= sti_addr + 1'b1;
					line_di [0] <= sti_di[15];
					line_di [1] <= sti_di[14];
                    line_di [2] <= sti_di[13];
                    line_di [3] <= sti_di[12];
                    line_di [4] <= sti_di[11];
                    line_di [5] <= sti_di[10];
                    line_di [6] <= sti_di[9];
                    line_di [7] <= sti_di[8];
                    line_di [8] <= sti_di[7];
                    line_di [9] <= sti_di[6];
                    line_di [10] <= sti_di[5];
                    line_di [11] <= sti_di[4];
                    line_di [12] <= sti_di[3];
                    line_di [13] <= sti_di[2];
                    line_di [14] <= sti_di[1];
                    line_di [15] <= sti_di[0];
					res_do <= line_di[0];
				end
				cs[DATA_WRITE]:begin
					res_wr <= (cnt_delay == 4'd15)? 1'b0:1'b1;
					res_addr <= res_addr_cnt;
					res_do <= line_di[cnt];
					cnt <= cnt + 1'b1;
					cnt_delay <= cnt;
					res_addr_cnt <= (cnt_delay == 4'd15)?(res_addr_cnt) :(res_addr_cnt+ 1'd1);
				end
				cs[WRITE_DONE]:begin 
					sti_rd <= 'd0;
					sti_addr <= 'd0;
					res_wr <= 'd0;
					res_rd <= 'd1;
					res_addr <= 14'd129;
					res_do <= 'd0;
					line_di <= 'd0;
					cnt <= 'd0;
					cnt_delay <= 'd0;
					res_addr_cnt <= 'd0;
					done <= 1'b0;
					ker_ctr <= 14'd129;
				end
				cs[ADR_CTR]:begin
					res_rd <= 1'd1;
					res_wr <= 1'd0;
					res_addr <= ker_ctr;
				end
				cs[GET_CTR]:begin
					res_addr <= ker_NW;
					for_ctr <= res_di;
				end
				cs[GET_NW]:begin
					res_addr <= ker_N;
					for_NW <= res_di;
				end
				cs[GET_N]:begin
					res_addr <= ker_NE;
					for_N <= res_di; 
				end
				cs[GET_NE]:begin
					res_addr <= ker_W;
					for_NE <= res_di;
				end
				cs[GET_W]:begin
					res_addr <= ker_ctr;
					res_rd <= 1'd0;
					for_W <= res_di;
				end
				cs[CAL_FWP]:begin
					res_do <= (for_ctr == 8'd0)? 8'd0 : for_min;
				end
				cs[WRTIE_FWP]:begin
					res_wr <= 1'b1;
					res_addr_cnt <= res_addr_cnt + 1'd1;
				end
				cs[WAIT_FWP]:begin
					res_wr <= 1'b0;
					if(res_addr_cnt == 14'd126)begin
						res_addr_cnt <= 'd0;
						ker_ctr <= ker_ctr + 14'd3;
					end
					else begin
						ker_ctr <= ker_ctr + 1'd1; 
					end
				end
				cs[FWP_DONE]:begin
					sti_rd <= 'd0;
					sti_addr <= 'd0;
					res_wr <= 'd0;
					res_rd <= 'd1;
					res_addr <= 14'd16254;
					res_do <= 'd0;
					line_di <= 'd0;
					cnt <= 'd0;
					cnt_delay <= 'd0;
					res_addr_cnt <= 'd0;
					done <= 1'b0;
					ker_ctr <= 14'd16254;
					fwpass_finish <= 1'd1;
				end
				cs[BWP_ADR_CTR]:begin
					res_rd <= 1'd1;
					res_wr <= 1'd0;
					res_addr <= ker_ctr;
				end
				cs[BWP_GET_CTR]:begin
					res_addr <= ker_E;
					for_ctr <= res_di;
				end
				cs[BWP_GET_E]:begin
					res_addr <= ker_SW;
					for_NW <= res_di;
				end
				cs[BWP_GET_SW]:begin
					res_addr <= ker_S;
					for_N <= res_di; 
				end
				cs[BWP_GET_S]:begin
					res_addr <= ker_SE;
					for_NE <= res_di;
				end
				cs[BWP_GET_SE]:begin
					res_addr <= ker_ctr;
					res_rd <= 1'd0;
					for_W <= res_di;
				end
				cs[CAL_BWP]:begin
					res_do <= (for_ctr == 8'd0)? 8'd0 : back_min;
				end
				cs[WRTIE_BWP]:begin
					res_wr <= 1'b1;
					res_addr_cnt <= res_addr_cnt + 1'd1;
				end
				cs[WAIT_BWP]:begin
					res_wr <= 1'b0;
					if(res_addr_cnt == 14'd126)begin
						res_addr_cnt <= 'd0;
						ker_ctr <= ker_ctr - 14'd3;
					end
					else begin
						ker_ctr <= ker_ctr - 1'd1; 
					end
				end
				cs[DONE]:begin
					res_wr <= 1'd0;
					res_rd <= 1'd0;
					done <= 1'd1;
				end
			endcase
		end
	end






//=========================================================================//

endmodule
