module ScoreCounter(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic score_clear,// synchronous score reset 
					input 	logic increase_score, 
					
					
					output logic [0:4][3:0] score
);
	logic [4:0] carry;
	up_counter LSD(
				.clk(clk),
				.resetN(resetN),
				.enable(1'b1),
				.loadN(!score_clear),
				.enable_cnt(increase_score),
				.init(4'h0),
				.count(score[4]),
				.inc(carry[0])
				);
	up_counter fourthNum(
				.clk(clk),
				.resetN(resetN),
				.enable(1'b1),
				.loadN(!score_clear),
				.enable_cnt(carry[0]),
				.init(4'h0),
				.count(score[3]),
				.inc(carry[1])
				);
	up_counter thirdNum(
				.clk(clk),
				.resetN(resetN),
				.enable(1'b1),
				.loadN(!score_clear),
				.enable_cnt(carry[1]),
				.init(4'h0),
				.count(score[2]),
				.inc(carry[2])
				);
	up_counter secondNum(
				.clk(clk),
				.resetN(resetN),
				.enable(1'b1),
				.loadN(!score_clear),
				.enable_cnt(carry[2]),
				.init(4'h0),
				.count(score[1]),
				.inc(carry[3])
				);
	up_counter MSNum(
				.clk(clk),
				.resetN(resetN),
				.enable(1'b1),
				.loadN(!score_clear),
				.enable_cnt(carry[3]),
				.init(4'h0),
				.count(score[0]),
				.inc(carry[4])
				);



endmodule
