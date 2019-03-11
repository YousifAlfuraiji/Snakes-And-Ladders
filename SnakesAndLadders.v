

module SnakesAndLadders(
	input [2:0]KEY,
	input CLOCK_50,
	output [6:0]HEX0,
	output [6:0]HEX1,
	output [6:0]HEX2,
	output [6:0]HEX3,
	output [6:0]HEX4,
	output [6:0]HEX5,
	output VGA_CLK, output VGA_HS, output VGA_VS, output VGA_BLANK_N, output VGA_SYNC_N,
	output [9:0]VGA_R, output [9:0]VGA_G, output [9:0]VGA_B);


	wire [2:0]diceVal;

	wire play = ~KEY[0];
	wire quit = ~KEY[1];
	wire start = ~KEY[2];
	
	wire ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, ld_begin_game_P1, ld_begin_game_P2, 
				ld_background, ld_startScreen, enable, ld_dice;

	wire [6:0] positionP1;
	wire [6:0] positionP2;

	wire [8:0] xlocP1, xCoordP1, xlocP2, xCoordP2;
	wire [7:0] ylocP1, yCoordP1, ylocP2, yCoordP2;

	getCoordinates c4(positionP1, xlocP1, ylocP1);
	getCoordinates c523(positionP2, xlocP2, ylocP2);

	
	wire CLOCK_1;
	wire [16:0]screenCounter;
	slowerCLOCK u1(CLOCK_50, CLOCK_1, screenCounter);
	
	wire [8:0]boardColour;
	boardROM u2(screenCounter, CLOCK_50, boardColour);
	
	wire [8:0]startScreenColour;
	startScreenROM u3(screenCounter, CLOCK_50, startScreenColour);
	
	
	wire [12:0]diceCounter;
	wire dice_Counter_reset;
	diceDisplayCount u4(CLOCK_50, dice_Counter_reset, diceCounter);
	
	wire [8:0]dice1Colour;
	dice1ROM u5(diceCounter, CLOCK_50, dice1Colour);
	
	wire [8:0]dice2Colour;
	dice2ROM u6(diceCounter, CLOCK_50, dice2Colour);
	
	wire [8:0]dice3Colour;
	dice3ROM u7(diceCounter, CLOCK_50, dice3Colour);

	wire [8:0]dice4Colour;
	dice4ROM u8(diceCounter, CLOCK_50, dice4Colour);

	wire [8:0]dice5Colour;
	dice5ROM u9(diceCounter, CLOCK_50, dice5Colour);
	
	wire [8:0]dice6Colour;
	dice6ROM u10(diceCounter, CLOCK_50, dice6Colour);
	
	wire CLOCK_4perSecond;
	diceCLOCK u11(CLOCK_50, CLOCK_4perSecond);

	wire [8:0]diceColour;
	diceSwitcher u12(CLOCK_50, CLOCK_4perSecond, 
								dice1Colour, dice2Colour, dice3Colour,
								dice4Colour, dice5Colour, dice6Colour,
								diceColour);
	
	
	wire [8:0]colour;
	wire [8:0]Xout;
	wire [7:0]Yout;

	screenXandYcounter u13(CLOCK_50, ld_background, ld_draw_P1, ld_startScreen, 
					ld_dice, play, screenCounter, diceCounter, 
					startScreenColour, boardColour, diceColour,
					diceVal,
					dice1Colour, dice2Colour, dice3Colour,
					dice4Colour, dice5Colour, dice6Colour,
					xlocP1, xCoordP1, ylocP1, yCoordP1,
					xlocP2, xCoordP2, ylocP2, yCoordP2,
					Xout, Yout, colour);

	
	vga_adapter VGA(.resetn(!quit), .clock(CLOCK_50),
		.colour(colour), .x(Xout), .y(Yout), .plot(enable && (ld_background || quit || !(Xout > 241 && (Yout < 163 || Yout > 237)))),
		.VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N), .VGA_SYNC(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
		
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
	defparam VGA.BACKGROUND_IMAGE = "startScreen.mif";

	dice d14(quit, CLOCK_50, play, diceVal);


	wire [5:0]counter16;
	sixteeenCycleCounter u325433243(CLOCK_50, counter16);

	control c1(play, quit, start, CLOCK_1,
					ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, ld_begin_game_P1, ld_begin_game_P2, 
					ld_background, ld_startScreen, enable, ld_dice, dice_Counter_reset);
	
	dataPath d1(diceVal, play, quit, CLOCK_1, CLOCK_50, counter16,
					ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, 
					ld_begin_game_P1, ld_begin_game_P2,
					positionP1, xCoordP1, yCoordP1,
					positionP2, xCoordP2, yCoordP2);


	hex_decoder H0(positionP1 % 7'd10, HEX0);
	hex_decoder H1(positionP1 / 7'd10, HEX1);
	hex_decoder H2(positionP1 / 7'd100, HEX2);
	
	hex_decoder H3(positionP2 % 7'd10 , HEX3);
	hex_decoder H4(positionP2 / 7'd10 , HEX4);
	hex_decoder H5(positionP2 / 7'd100 , HEX5);

 
endmodule



module control(play, reset, start, CLOCK_1, 
			ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, ld_begin_game_P1, ld_begin_game_P2, 
			ld_background, ld_startScreen, enable, ld_dice, dice_Counter_reset);

	input play, reset, start, CLOCK_1;
	
	output reg ld_P1, ld_draw_P1, ld_P2, ld_draw_P2, ld_begin_game_P1, ld_begin_game_P2, 
					ld_background, ld_startScreen, enable, ld_dice, dice_Counter_reset;
					
	reg [4:0]currentState, nextState;
	
	localparam 		S_beforeStart					= 5'd0,
						S_startScreen  				= 5'd1,
						S_startScreenWait				= 5'd2,
						S_beginGameP1BG				= 5'd3,
						S_beginGameP1 					= 5'd4,
						S_beginGameDrawP1  			= 5'd5,
						S_beginGameP2BG				= 5'd6,
						S_beginGameP2 					= 5'd7,
						S_beginGameDrawP2   			= 5'd8,
						S_P2_beforeDice				= 5'd9,
						S_P2_Dice						= 5'd10,
						S_P2_afterDice					= 5'd11,
						S_P1            				= 5'd12,
						S_P1_Wait   					= 5'd13,
						S_P1_Load     					= 5'd14,
						S_P1_DrawP1    				= 5'd15,
						S_P1_DrawP2						= 5'd16,
						S_P1_beforeDice				= 5'd17,
						S_P1_Dice						= 5'd18,
						S_P1_afterDice					= 5'd19,
						S_P2            				= 5'd20,
						S_P2_Wait   					= 5'd21,
						S_P2_Load     					= 5'd22,
						S_P2_DrawP1    				= 5'd23,
						S_P2_DrawP2						= 5'd24;

	always@(posedge CLOCK_1)
	begin
	case(currentState)
	S_beforeStart:				nextState = S_startScreen; 
	S_startScreen:    		nextState = start ? S_startScreenWait : S_startScreen;
	S_startScreenWait:		nextState = start ? S_startScreenWait : S_beginGameP1BG;
	S_beginGameP1BG:			nextState = S_beginGameP1;
	S_beginGameP1:         	nextState = S_beginGameDrawP1;
	S_beginGameDrawP1:   	nextState = S_beginGameP2BG;
	S_beginGameP2BG:			nextState = S_beginGameP2;
	S_beginGameP2:     		nextState = S_beginGameDrawP2;
	S_beginGameDrawP2:	   nextState = S_P2_beforeDice;
	S_P2_beforeDice:			nextState = S_P2_Dice;
	S_P2_Dice:					nextState = S_P2_afterDice ;
	S_P2_afterDice:			nextState = S_P1;
	S_P1:                   nextState = play ? S_P1_Wait : S_P1;
	S_P1_Wait:          		nextState = play ? S_P1_Wait : S_P1_Load;
	S_P1_Load:             	nextState = S_P1_DrawP1;
	S_P1_DrawP1:				nextState = S_P1_DrawP2;
	S_P1_DrawP2:				nextState = S_P1_beforeDice;
	S_P1_beforeDice:			nextState = S_P1_Dice;
	S_P1_Dice:					nextState = S_P1_afterDice;
	S_P1_afterDice:			nextState = S_P2;
	S_P2:                   nextState = play ? S_P2_Wait : S_P2;
	S_P2_Wait:          		nextState = play ? S_P2_Wait : S_P2_Load;
	S_P2_Load:            	nextState = S_P2_DrawP1;
	S_P2_DrawP1:				nextState = S_P2_DrawP2;
	S_P2_DrawP2:				nextState = S_P2_beforeDice;
	default:                nextState = S_beforeStart;
	endcase

	ld_begin_game_P1 				= 1'b0;
	ld_begin_game_P2 				= 1'b0;
	ld_P1         					= 1'b0;
	ld_draw_P1         			= 1'b0;
	ld_P2         					= 1'b0;
	ld_draw_P2       			  	= 1'b0;
	enable      					= 1'b0;
	ld_background					= 1'b0;
	ld_startScreen					= 1'b0;
	ld_dice							= 1'b0;
	dice_Counter_reset			= 1'b0;
	
	case(currentState)
	

	S_beforeStart: begin
		ld_startScreen				= 1'b1;
		enable						= 1'b1;
	end
	
	S_beginGameP1BG:begin
		ld_background				= 1'b1;
		enable						= 1'b1;
	end
	
	S_beginGameP1: begin
		ld_begin_game_P1 			= 1'b1;
	end

	S_beginGameDrawP1: begin
		ld_draw_P1    			  	= 1'b1;
		enable   					= 1'b1;
	end
	
	S_beginGameP2BG: begin
		enable						= 1'b1;
	end
	
	S_beginGameP2: begin
		ld_begin_game_P2 			= 1'b1;
	end

	S_beginGameDrawP2: begin
		ld_draw_P2      			= 1'b1;
		enable   					= 1'b1;
	end
	
	S_P2_Dice: begin
		ld_dice						= 1'b1;
		enable						= 1'b1;
	end
	
	S_P1_Wait: begin
		enable						= 1'b1;
	end

	S_P1_Load: begin
		ld_P1         				= 1'b1;
		ld_background				= 1'b1;
		enable						= 1'b1;
	end

	S_P1_DrawP1: begin
		ld_draw_P1    	  			= 1'b1;
		enable   					= 1'b1;
	end
	
	S_P1_DrawP2: begin
		ld_draw_P2					= 1'b1;
		enable						= 1'b1;
	end
	
	S_P1_beforeDice: dice_Counter_reset = 1'b1;
	
	S_P2_beforeDice: dice_Counter_reset = 1'b1;
	
	S_P1_Dice: begin
		ld_dice						= 1'b1;
		enable						= 1'b1;
	end
	
	S_P2_Wait: begin
		enable						= 1'b1;
	end
	
	S_P2_Load: begin
		ld_P2         				= 1'b1;
		ld_background				= 1'b1;
		enable						= 1'b1;
	end
	
	S_P2_DrawP1: begin
		ld_draw_P1         		= 1'b1;
		enable   					= 1'b1;
	end
	
	S_P2_DrawP2: begin
		ld_draw_P2         		= 1'b1;
		enable   					= 1'b1;
	end
	endcase

	if(reset)
		currentState <= S_beforeStart;
	else
		currentState <= nextState;
	end
endmodule

module dataPath(diceVal, play, reset, CLOCK_1, CLOCK_50, counter16,
    ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, 
	 ld_begin_game_P1, ld_begin_game_P2,
    positionP1, xCoordP1, yCoordP1,
    positionP2, xCoordP2, yCoordP2);
	
	
	input [2:0]diceVal;
	input play, reset, CLOCK_1, CLOCK_50;
	input [5:0]counter16;
	input ld_P1, ld_P2, ld_draw_P1, ld_draw_P2, ld_begin_game_P1, ld_begin_game_P2;
 
	output reg [6:0]positionP1, positionP2;
	output reg [8:0]xCoordP1, xCoordP2;
	output reg [7:0]yCoordP1, yCoordP2;

	always@(posedge CLOCK_1)
	begin

    	if(ld_begin_game_P1)
	
        	positionP1 <= 7'd1;
 
		else if(ld_begin_game_P2)
    
			positionP2 <= 7'd1;
		
		else if(ld_P1 && positionP1 + diceVal == 7'd8)   // ladders->P1
				positionP1 <= 7'd14;
		else if(ld_P1 && positionP1 + diceVal == 7'd21) // ladders->P1
				positionP1 <= 7'd40;
		else if(ld_P1 && positionP1 + diceVal == 7'd26) // ladders->P1
				positionP1 <= 7'd35;
		else if(ld_P1 && positionP1 + diceVal == 7'd42) // ladders->P1
				positionP1 <= 7'd62;
		else if(ld_P1 && positionP1 + diceVal == 7'd43) // ladders->P1
				positionP1 <= 7'd44;
		else if(ld_P1 && positionP1 + diceVal == 7'd47) // ladders->P1
				positionP1 <= 7'd67;
		else if(ld_P1 && positionP1 + diceVal == 7'd48) // ladders->P1
				positionP1 <= 7'd49;
		else if(ld_P1 && positionP1 + diceVal == 7'd51) // ladders->P1
				positionP1 <= 7'd71;
		else if(ld_P1 && positionP1 + diceVal == 7'd53) // ladders->P1
				positionP1 <= 7'd54;
		else if(ld_P1 && positionP1 + diceVal == 7'd58) // ladders->P1
				positionP1 <= 7'd59;
		else if(ld_P1 && positionP1 + diceVal == 7'd63) // ladders->P1
				positionP1 <= 7'd64;
		else if(ld_P1 && positionP1 + diceVal == 7'd68) // ladders->P1
				positionP1 <= 7'd69;
		else if(ld_P1 && positionP1 + diceVal == 7'd74) // ladders->P1
				positionP1 <= 7'd86;
		else if(ld_P1 && positionP1 + diceVal == 7'd87) // ladders->P1
				positionP1 <= 7'd94;
		
				
		else if(ld_P1 && positionP1 + diceVal == 7'd18) // snakes->P1
				positionP1 <= 7'd6;
		else if(ld_P1 && positionP1 + diceVal == 7'd24) // snakes->P1
				positionP1 <= 7'd19;
		else if(ld_P1 && positionP1 + diceVal == 7'd34) // snakes->P1
				positionP1 <= 7'd11;
		else if(ld_P1 && positionP1 + diceVal == 7'd66) // snakes->P1
				positionP1 <= 7'd46;
		else if(ld_P1 && positionP1 + diceVal == 7'd93) // snakes->P1
				positionP1 <= 7'd73;
		else if(ld_P1 && positionP1 + diceVal == 7'd97) // snakes->P1
				positionP1 <= 7'd86;
		else if(ld_P1 && positionP1 + diceVal == 7'd99) // snakes->P1
				positionP1 <= 7'd61;

		else if(ld_P2 && positionP2 + diceVal == 7'd8)   // ladders->P2
				positionP2 <= 7'd14;
		else if(ld_P2 && positionP2 + diceVal == 7'd21) // ladders->P2
				positionP2 <= 7'd40;
		else if(ld_P2 && positionP2 + diceVal == 7'd26) // ladders->P2
				positionP2 <= 7'd35;
		else if(ld_P2 && positionP2 + diceVal == 7'd42) // ladders->P2
				positionP2 <= 7'd62;
		else if(ld_P2 && positionP2 + diceVal == 7'd43) // ladders->P2
				positionP2 <= 7'd44;
		else if(ld_P2 && positionP2 + diceVal == 7'd47) // ladders->P2
				positionP2 <= 7'd67;
		else if(ld_P2 && positionP2 + diceVal == 7'd48) // ladders->P2
				positionP2 <= 7'd49;
		else if(ld_P2 && positionP2 + diceVal == 7'd51) // ladders->P2
				positionP2 <= 7'd71;
		else if(ld_P2 && positionP2 + diceVal == 7'd53) // ladders->P2
				positionP2 <= 7'd54;
		else if(ld_P2 && positionP2 + diceVal == 7'd58) // ladders->P2
				positionP2 <= 7'd59;
		else if(ld_P2 && positionP2 + diceVal == 7'd63) // ladders->P2
				positionP2 <= 7'd64;
		else if(ld_P2 && positionP2 + diceVal == 7'd68) // ladders->P2
				positionP2 <= 7'd69;
		else if(ld_P2 && positionP2 + diceVal == 7'd74) // ladders->P2
				positionP2 <= 7'd86;
		else if(ld_P2 && positionP2 + diceVal == 7'd87) // ladders->P2
				positionP2 <= 7'd94;
	
		else if(ld_P2 && positionP2 + diceVal == 7'd18) // snakes->P2
				positionP2 <= 7'd6;
		else if(ld_P2 && positionP2 + diceVal == 7'd24) // snakes->P2
				positionP2 <= 7'd19;
		else if(ld_P2 && positionP2 + diceVal == 7'd34) // snakes->P2
				positionP2 <= 7'd11;
		else if(ld_P2 && positionP2 + diceVal == 7'd66) // snakes->P2
				positionP2 <= 7'd46;
		else if(ld_P2 && positionP2 + diceVal == 7'd93) // snakes->P2
				positionP2 <= 7'd73;
		else if(ld_P2 && positionP2 + diceVal == 7'd97) // snakes->P2
				positionP2 <= 7'd86;
		else if(ld_P2 && positionP2 + diceVal == 7'd99) // snakes->P2
				positionP2 <= 7'd61;
		
		else if(ld_P1 && positionP1 + diceVal<=100)
        	
			positionP1 <= positionP1 + diceVal;
    	
		else if(ld_P2 && positionP2 + diceVal<=100)
      
			positionP2 <= positionP2 + diceVal;
	
	end
	
	always@(negedge CLOCK_50)
	begin
		if(ld_begin_game_P1)
		begin
			xCoordP1 <= counter16[2:0];
        	yCoordP1 <= counter16[5:3];
		end
	
		else if(ld_begin_game_P2)
		begin
			xCoordP2 <= counter16[2:0];
			yCoordP2 <= counter16[5:3];
		end
 
    	else if(ld_draw_P1)
    	begin
        	xCoordP1 <= counter16[2:0];
        	yCoordP1 <= counter16[5:3];
    	end
	
		else if(ld_draw_P2)
    	begin
        	xCoordP2 <= counter16[2:0];
        	yCoordP2 <= counter16[5:3];
    	end
 
	end
    	
endmodule

module dice(input reset, input clock, input readIn, output reg[2:0]roll);
	
	reg [2:0]count = 3'd1;
	always @(posedge clock)
	begin

	if(count >= 3'd6)
    	count <= 3'd1;
	else
    	count <= count + 3'd1;
	end

	always @(posedge readIn, posedge reset)
	begin
		if(reset)
			roll <= 3'd0;
		else
			roll <= count;
	end
endmodule

module hex_decoder(hex_digit, segments);
	input [3:0] hex_digit;
	output reg [6:0] segments;
 
	always @(*)
    	case (hex_digit)
        	4'h0: segments = 7'b100_0000;
        	4'h1: segments = 7'b111_1001;
        	4'h2: segments = 7'b010_0100;
        	4'h3: segments = 7'b011_0000;
        	4'h4: segments = 7'b001_1001;
        	4'h5: segments = 7'b001_0010;
        	4'h6: segments = 7'b000_0010;
        	4'h7: segments = 7'b111_1000;
        	4'h8: segments = 7'b000_0000;
        	4'h9: segments = 7'b001_1000;
        	4'hA: segments = 7'b100_0000;
        	4'hB: segments = 7'b111_1001;
        	4'hC: segments = 7'b010_0100;
        	4'hD: segments = 7'b011_0000;
        	4'hE: segments = 7'b001_1001;
        	4'hF: segments = 7'b001_0010;
        	default: segments = 7'b0000000;
    	endcase
endmodule

module getCoordinates(
	input [6:0]position,
	output [3:0]x,
	output [3:0]y);
	reg [3:0]xReg;
	reg [3:0]yReg;
	
	always @(*)
	begin
 
  if((position >= 7'd1  && position <= 7'd9 ) ||
   (position >= 7'd21 && position <= 7'd29) ||
   (position >= 7'd41 && position <= 7'd49) ||
   (position >= 7'd61 && position <= 7'd69) ||
   (position >= 7'd81 && position <= 7'd89))
   begin
		xReg <= position%7'd10-7'd1;
		yReg <= 7'd9-position/7'd10;
   end
	
  else if((position >= 7'd11 && position <= 7'd19) ||
  	(position >= 7'd31 && position <= 7'd39) ||
  	(position >= 7'd51 && position <= 7'd59) ||
  	(position >= 7'd71 && position <= 7'd79) ||
  	(position >= 7'd91 && position <= 7'd99))
  	begin
   	xReg <= 7'd9-(position%7'd10-7'd1);
   	yReg <= 7'd9-position/7'd10;
  	end
	
  else if(position == 7'd20 ||
  	position == 7'd40 ||
  	position == 7'd60 ||
  	position == 7'd80 ||
  	position == 7'd100)
  	begin
		xReg <= 7'd0;
		yReg <= 7'd10 - position/7'd10;
	end
	
  else if(position == 7'd10 ||
	position == 7'd30 ||
	position == 7'd50 ||
	position == 7'd70 ||
	position == 7'd90)
	begin
		xReg <= 7'd9;
		yReg <= 7'd10 - position/7'd10;
	end	
 end
	assign x = xReg;
	assign y = yReg;
endmodule

module slowerCLOCK(CLOCK_50, CLOCK_1, screenCounter);

	input CLOCK_50;
 
 
	output reg CLOCK_1;
	output reg [16:0]screenCounter;
	
	always@(posedge CLOCK_50)
	begin
    	if(screenCounter == 17'd76799)
       begin
        	screenCounter <= 17'b0;
        	CLOCK_1 <= 1'b1;
      end
    	else
    	begin
        	screenCounter <= screenCounter + 17'b1;
        	CLOCK_1 <= 1'b0;
    	end
	end

endmodule

module diceCLOCK(CLOCK_50, CLOCK_4perSecond);

	input CLOCK_50;
	
	output reg CLOCK_4perSecond;
	
	reg [23:0]diceSwitchCounter;

	always@(posedge CLOCK_50)
	begin
		if(diceSwitchCounter == 24'b101111101011110000100000)
		begin
			diceSwitchCounter <= 24'b000000000000000000000000;
			CLOCK_4perSecond <= 1'b1;
		end
		else
		begin
			diceSwitchCounter <= diceSwitchCounter + 24'b1;
			CLOCK_4perSecond <= 1'b0;
		end
	end
endmodule

module diceSwitcher(CLOCK_50, CLOCK_4perSecond, 
							dice1Colour, dice2Colour, dice3Colour,
							dice4Colour, dice5Colour, dice6Colour,
							diceColour);
	
	input CLOCK_50, CLOCK_4perSecond;
	input [8:0]dice1Colour, dice2Colour, dice3Colour;
	input [8:0]dice4Colour, dice5Colour, dice6Colour;
	
	output reg[8:0]diceColour;
	
	reg [2:0]scroll;
	
	always@(posedge CLOCK_4perSecond)
	begin
		if(scroll == 3'd5)
			scroll <= 3'd0;
		else 
			scroll <= scroll + 3'd1;
	end
	
	always@(posedge CLOCK_50)
	begin
		if(scroll == 3'd0)
			diceColour <= dice1Colour;
		else if(scroll == 3'd1)
			diceColour <= dice3Colour;
		else if(scroll == 3'd2)
			diceColour <= dice6Colour;
		else if(scroll == 3'd3)
			diceColour <= dice5Colour;
		else if(scroll == 3'd4)
			diceColour <= dice2Colour;
		else 
			diceColour <= dice4Colour;
	end
	
endmodule
		

module diceDisplayCount(CLOCK_50, reset, diceCounter);

	input CLOCK_50, reset;
	
	output reg [12:0]diceCounter;
	
	always@(posedge CLOCK_50)
	begin
		if (reset)
			diceCounter <= 0;
		else if(diceCounter == 13'd5624)
			diceCounter <= 13'b0;
		else
			diceCounter <= diceCounter + 13'b1;
	end
endmodule
		

module sixteeenCycleCounter(CLOCK_50, counter16);
	input CLOCK_50;
	output reg [5:0]counter16;
	
	always@(posedge CLOCK_50)
	begin
    	if(counter16 == 6'd63)
        	counter16 <= 6'd0;
    	else
        	counter16 <= counter16 + 6'd1;
	end
endmodule


module screenXandYcounter(CLOCK_50, ld_background, ld_draw_P1, ld_startScreen, 
					ld_dice, play, screenCounter, diceCounter,
					startScreenColour, boardColour, diceColour,
					diceVal,
					dice1Colour, dice2Colour, dice3Colour,
					dice4Colour, dice5Colour, dice6Colour,
					xlocP1, xCoordP1, ylocP1, yCoordP1,
					xlocP2, xCoordP2, ylocP2, yCoordP2,
					Xout, Yout, colour);
		
		input CLOCK_50, ld_background, ld_draw_P1, ld_startScreen, ld_dice, play;
		input [16:0]screenCounter;
		input [12:0]diceCounter;
		input [8:0]startScreenColour, boardColour, diceColour;
		input [2:0]diceVal;
		input [8:0]dice1Colour, dice2Colour, dice3Colour,
						dice4Colour, dice5Colour, dice6Colour;
		input [8:0]xlocP1, xCoordP1, xlocP2, xCoordP2;
		input [7:0]ylocP1, yCoordP1, ylocP2, yCoordP2;
		
		output reg [8:0]Xout;
		output reg [7:0]Yout;
		output reg [8:0]colour;
		
		
		
		always@(posedge CLOCK_50)
		begin
			if(ld_startScreen)
			begin
				if(screenCounter == 17'd0)
				begin
					colour <= startScreenColour;
					Xout <= 9'd0;
					Yout <= 8'd0;
				end
				else if(screenCounter % 9'd320 == 0)
				begin
					colour <= startScreenColour;
					Xout <= 9'd0;
					Yout <= Yout + 8'd1;
				end
				else
				begin
					colour <= startScreenColour;
					Xout <= Xout + 9'd1;
					Yout <= Yout;
				end
			end
			
			else if(ld_background)
			begin
				if(screenCounter == 17'd0)
				begin
					colour <= boardColour;
					Xout <= 9'd0;
					Yout <= 8'd0;
				end
				else if(screenCounter % 9'd320 == 0)
				begin
					colour <= boardColour;
					Xout <= 9'd0;
					Yout <= Yout + 8'd1;
				end
				else
				begin
					colour <= boardColour;
					Xout <= Xout + 9'd1;
					Yout <= Yout;
				end
			end
			
			else if(play)
			begin
				if(diceCounter == 13'd0)
				begin
					colour <= diceColour;
					Xout <= 9'd243;
					Yout <= 8'd163;
				end
				else if(diceCounter % 13'd75 == 0)
				begin
					colour <= diceColour;
					Xout <= 9'd243;
					Yout <= Yout + 8'd1;
				end
				else
				begin
					colour <= diceColour;
					Xout <= Xout + 9'd1;
					Yout <= Yout;
				end
			end
			
			
			else if(ld_dice && diceVal >= 3'd1 && diceVal <= 3'd7)
			begin
				if(diceCounter == 13'd0)
				begin
					Xout <= 9'd243;
					Yout <= 8'd163;
				end
				else if(diceCounter % 13'd75 == 0)
				begin
					Xout <= 9'd243;
					Yout <= Yout + 8'd1;
				end
				else //if(Yout >= 8'd163 || Yout <= 8'd238)
				begin
					Xout <= Xout + 9'd1;
					Yout <= Yout;
				end
				
				if(diceVal == 3'd1)
					colour <= dice1Colour;
				else if(diceVal == 3'd2)
					colour <= dice2Colour;
				else if(diceVal == 3'd3)
					colour <= dice3Colour;
				else if(diceVal == 3'd4)
					colour <= dice4Colour;
				else if(diceVal == 3'd5)
					colour <= dice5Colour;
				else if(diceVal == 3'd6)
					colour <= dice6Colour;
			end
				
			else if(ld_draw_P1)
			begin
				colour <= 9'b111_001_101; //9'b000000111;
				Xout <= 5'd24*xlocP1 + xCoordP1 + 5'd3;
				Yout <= 5'd24*ylocP1 + yCoordP1 + 5'd3;
			end
			
			else
			begin
				colour <= 9'b111_001_000;
				Xout <= 5'd24*xlocP2 + xCoordP2 + 5'd15;
				Yout <= 5'd24*ylocP2 + yCoordP2 + 5'd15;
			end
			
		end
endmodule






