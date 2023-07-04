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
	input		[7:0]	res_di
	);

parameter IDLE = 0,
		  READ = 1,
		  READ_DATA = 2,
		  DATA_WRITE = 3,
		  WRITE_DONE = 4;

reg [ 4:0 ] cs,ns;
reg [3:0] cnt_delay;
//=========================================================================//
// comb. logic assignment
// forward min
	wire [7:0] for_NW;
	wire [7:0] for_N;
	wire [7:0] for_NE;
	wire [7:0] for_W;
	wire [7:0] for_comp1;
	wire [7:0] for_comp2;
	wire [7:0] for_min;
	assign for_comp1 = (for_NW <= for_N)? for_NW: for_N;
	assign for_comp2 = (for_NE <= for_W)? for_NE: for_W;
	assign for_min = (for_comp1 <= for_comp2)? for_comp1: for_comp2;
// backward min
	wire [7:0] back_center;
	wire [7:0] back_E;
	wire [7:0] back_SW;
	wire [7:0] back_S;
	wire [7:0] back_SE;
	wire [7:0] back_comp1;
	wire [7:0] back_comp2;
	wire [7:0] back_temp;
	wire [7:0] back_min;
	assign back_comp1 = (back_E <= back_SW)? back_E: back_SW;
	assign back_comp2 = (back_S <= back_SE)? back_S: back_SE;
	assign back_temp = (back_comp1 <= back_comp2)? (back_comp1 + 1'b1):(back_comp2 + 1'b1);
	assign back_min = (back_center <= back_temp)? (back_center): (back_temp);

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
			cs[WRITE_DONE]: ns[WRITE_DONE] = 1'b1;
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
				end
				cs[READ]:begin	
					sti_rd <= 1'b1;
					res_wr <= 1'b0;
					cnt <= 'd0;
					cnt_delay <='d0;
					res_addr_cnt <= res_addr_cnt;
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
				end
				cs[DATA_WRITE]:begin
					res_wr <= (cnt_delay == 4'd15)? 1'b0:1'b1;
					res_addr <= res_addr_cnt;
					res_do <= line_di[cnt_delay];
					cnt <= cnt + 1'b1;
					cnt_delay <= cnt;
					res_addr_cnt <= (cnt_delay == 4'd15)?(res_addr_cnt) :(res_addr_cnt+ 1'd1);
				end
				cs[WRITE_DONE]:begin
					res_wr <= 1'b0;
					done <= 1'b1;
				end
			endcase
		end
	end






//=========================================================================//

endmodule
