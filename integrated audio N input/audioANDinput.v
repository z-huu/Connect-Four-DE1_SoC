//input interface

/*desired experience

	activating a switch will turn on the corresponding LEDR
	
	pressing a certain KEY will load whichever switch is high as the column value to be placed
	
		connect 4 has 7 columns, so switches 7, 8, and 9 will be excluded. only 0-6 used for input
	
	if more than two switches are high when the column is loaded, we should throw some sort of error message
		
		the two outermost LEDRs should activate

*/

/* implementation plan

	design FSM + Datapath
	states:
	
		waiting for column loading
		
			in this state, LEDR should activate if corresponding switch is high. two outer switches&LEDs are ignored
			
			nState -> error checking
			
		error checking state
		
			should check if more than one switch is activated OR an invalid switch is activated when col is loaded
			
			if (invalid) nState --> error message state
			else nState --> loading column
			
		error message state
		
			all LEDS should deactivate momentarily and the two outer LEDs should activate. a flash would be cool
			
		loading column value
			
			pushing whichever switch value is high to output column. activation of all LEDs would be cool
			displaying of pushed column value on HEX display would also be cool
			
		KEY MAP
		0 - RESET
		1 - Unused
		2 - Unused
		3 - LOAD COLUMN VALUE

*/

module audioANDinput (

	input [9:0] SW,
	input [3:0] KEY, //KEY 0 IS RESET. KEY 3 IS LOAD 
	input CLOCK_50,
	output [9:0] LEDR,
	output [3:0] column,
	output [6:0] HEX0, //HEX or HEX0? not necessary but could be extra
	
	//Audio stuff
	
	input AUD_ADCDAT,
	
	inout	AUD_BCLK,
	inout	AUD_ADCLRCK,
	inout	AUD_DACLRCK,
	inout	I2C_SDAT,

	output AUD_XCK,
	output AUD_DACDAT,
	output I2C_SCLK

);

	//Control wires
	wire invalid, loadCol, pushedInvalid, waiting;
	
	wire [31:0] errorCounter; //control will increment / reset counter value, datapath will use it for LEDs
	wire [31:0] successCounter;
	
	hex_decoder AHH (.c(column), .display(HEX0));
	
	checkInput OHYEAH (.switch(SW), .invalid(invalid)); //continuously updating invalid value
	
	control YUPP (.invalid(invalid), .errorCounter(errorCounter), .successCounter(successCounter),
						.loadCol(loadCol), .pushedInvalid(pushedInvalid), .waiting(waiting), .clock(CLOCK_50),
						.reset(KEY[0]), .inLoad(~KEY[3]));
						
	datapath WOW (.invalid(invalid), .SW(SW), .LEDR(LEDR), .loadCol(loadCol),
						.pushedInvalid(pushedInvalid), .errorCounter(errorCounter), .successCounter(successCounter),
						.column(column), .clock(CLOCK_50), .waiting(waiting), .reset(KEY[0]));
						
	audio BOOM (CLOCK_50, loadCol, KEY[0], AUD_ADCDAT,	AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, I2C_SDAT, AUD_XCK,
					AUD_DACDAT, I2C_SCLK);

endmodule 

module datapath (

	input invalid, loadCol, pushedInvalid, clock, waiting, reset,
	input [9:0] SW,
	output reg [31:0] errorCounter, successCounter,
	output reg [9:0] LEDR, 
	output reg [3:0] column

);

	reg [4:0] tempColumn;
	reg sw1, sw0;
	reg [1:0] sw3, sw2;
	reg [2:0] sw6, sw5, sw4;
	
	parameter clockfreq = 50000000;
	
	always @ (*) begin
	
							if (SW[0]) sw0 = 1'd0;
								else sw0 = 1'b0;
							if (SW[1]) sw1 = 1'd1;
								else sw1 = 1'b0;
							if (SW[2]) sw2 = 2'd2;
								else sw2 = 2'b00;
							if (SW[3]) sw3 = 2'd3;
								else sw3 = 2'b00;
							if (SW[4]) sw4 = 3'd4;
								else sw4 = 3'b000;
							if (SW[5]) sw5 = 3'd5;
								else sw5 = 3'b000;
							if (SW[6]) sw6 = 3'd6;
								else sw6 = 3'b000;
			
							tempColumn = 0+sw0+sw1+sw2+sw3+sw4+sw5+sw6;
	
					end //end begin
	
	//push out results
	
	always @ (posedge clock) begin
	
		if (!reset) begin
		
			column <= 0;
			errorCounter <= 0;
			successCounter <=0;
			LEDR <= 0000000000;
		
		end
		
		else if (waiting) begin
		
			if (SW[0]) LEDR[0] <= 1;
			if (SW[1]) LEDR[1] <= 1;
			if (SW[2]) LEDR[2] <= 1;
			if (SW[3]) LEDR[3] <= 1;
			if (SW[4]) LEDR[4] <= 1;
			if (SW[5]) LEDR[5] <= 1;
			if (SW[6]) LEDR[6] <= 1;
			if (!SW[0]) LEDR[0] <= 0;
			if (!SW[1]) LEDR[1] <= 0;
			if (!SW[2]) LEDR[2] <= 0;
			if (!SW[3]) LEDR[3] <= 0;
			if (!SW[4]) LEDR[4] <= 0;
			if (!SW[5]) LEDR[5] <= 0;
			if (!SW[6]) LEDR[6] <= 0;
		
		end
		
	
		else if (pushedInvalid) begin
		
		//pulse all LEDs for error message?
		
		//upperBound of clock frequency corresponds to 1sec; maybe the error msg can be as follows
		// runs for 3 seconds, LED pulse every 0.5 s ? timing seems ok, duration is only thing questionable
		
			if (errorCounter < clockfreq*3) begin //still displaying error message
				
				if (errorCounter < (clockfreq/2)	) begin //first 0.5s
				
					LEDR <= 10'b1111111111;
				
				end
				
				else if ((errorCounter > (clockfreq/2))&&(errorCounter < clockfreq)) begin //0.5s to 1s
				
					LEDR <= 10'b0000000000;
				
				end
				
				else if ((errorCounter > clockfreq)&&(errorCounter < (clockfreq + (clockfreq/2)))) begin //1s to 1.5s
				
					LEDR <= 10'b1111111111;
				
				end
				
				
				else if ((errorCounter > (clockfreq + (clockfreq/2)))&&(errorCounter < (clockfreq*2))) begin //1.5s to 2s
				
					LEDR <= 10'b0000000000;
				
				end
				
				
				else if ((errorCounter > (clockfreq*2))&&(errorCounter < (	(clockfreq*2)+(clockfreq/2))	)) begin //2s to 2.5s
				
					LEDR <= 10'b1111111111;
				
				end
				
				
				else if ((errorCounter > ((clockfreq*2)+(clockfreq/2)))&&(errorCounter < (clockfreq*3))) begin //2.5s to 3s
				
					LEDR <= 10'b0000000000;
				
				end
				
				errorCounter <= errorCounter+1;
			
			end //end errorCounter < clockfreq*3
			
			else if (errorCounter == clockfreq*3) begin //error msg has finished displaying
			
				errorCounter <= 0;
			
			end
				
		end // end pushedInvalid
		
		else if (loadCol) begin
		
		// LEDs light up in sequential order for success?	
		
		// multiple if statements for different ranges of counter
		
		// let's make this go for 2 seconds.
		
			if (successCounter < clockfreq*2) begin
			
				if (successCounter < clockfreq/5) begin //clockfreq * 0.2
					
					LEDR <= 10'b1000000000;
				
				end
				
				else if ( (successCounter > (clockfreq/5)) && (successCounter < ((clockfreq*2)/5))) begin
					LEDR <= 10'b0100000000;
				end	
				
				else if ( (successCounter > ((clockfreq*2)/5)) && (successCounter < ((clockfreq*3)/5))) begin
					LEDR <= 10'b0010000000;
				end
				
				else if ( (successCounter > ((clockfreq*3)/5)) && (successCounter < ((clockfreq*4)/5))) begin
					LEDR <= 10'b0001000000;
				end	
				
				else if ( (successCounter > ((clockfreq*4)/5)) && (successCounter < (clockfreq))) begin
					LEDR <= 10'b0000100000;
				end	
				
				else if ( (successCounter > (clockfreq)) && (successCounter < ((clockfreq*6)/5))) begin
					LEDR <= 10'b0000010000;
				end	
				
				else if ( (successCounter > ((clockfreq*6)/5)) && (successCounter < ((clockfreq*7)/5))) begin
					LEDR <= 10'b0000001000;
				end	
				
				else if ( (successCounter > ((clockfreq*7)/5)) && (successCounter < ((clockfreq*8)/5))) begin
					LEDR <= 10'b0000000100;
				end	
				
				else if ( (successCounter > ((clockfreq*8)/5)) && (successCounter < ((clockfreq*9)/5))) begin
					LEDR <= 10'b0000000010;
				end	
				
				else if ( (successCounter > ((clockfreq*9)/5)) && (successCounter < (clockfreq*2)) ) begin
					LEDR <= 10'b0000000001;
				end	
			
				successCounter <= successCounter+1;
			
			end // end successCounter < clockfreq*2
		
			else if (successCounter == clockfreq*2) begin
				successCounter <= 0;
				column <= tempColumn;
			end
		
		end //end else if loadCol
	
	end
	

endmodule 


module control (

	input clock, reset, inLoad, invalid,
	input [31:0] errorCounter, successCounter,
	output reg loadCol, pushedInvalid, waiting

);



	reg [2:0] cState, nState;

	parameter loading_col = 2'd0,
				 error_check = 2'd1,
				 error_msg   = 2'd2,
				 push_column = 2'd3,
				 clockfreq = 50000000;
				 
	//State Transition Table
	
	always @ (*) begin
		case (cState)
		
			loading_col: begin
			
							if (inLoad) nState = error_check;
							else nState = cState;
			
							 end
							 
			 error_check: begin
			 
							if (invalid) nState = error_msg;
							else nState = push_column;
			 
							  end
							  
			 error_msg: begin
			 
							if (errorCounter < clockfreq*3) nState = cState;
							else nState = loading_col;
			 
						   end
							
			 push_column: begin
			 
							if (successCounter == clockfreq*2) nState = loading_col;
							else nState = cState;
			 
							  end
		
			default: nState = loading_col;
			
		endcase
	end //end always begin	
	
	
	//State flip flops
	
	always @ (posedge clock) begin
	
		if (!reset) begin //active low reset. when assigning to key, make sure to add ~ or !
		
			cState <= loading_col;

		end
		
		else cState <= nState;
	
	
	end
	
	//Control Signals (loadedCol)
	
	always @ (*) begin
	
		waiting = 1'b0;
		loadCol = 1'b0;
		pushedInvalid = 1'b0;
	
		case (cState)

			push_column: loadCol = 1'b1;
			loading_col: waiting = 1'b1;
			error_msg: pushedInvalid = 1'b1;
		
		endcase
	
	end
		
endmodule 

module checkInput (

	input [9:0] switch, // going to omit switches 9, 8, and 7. (switches 0 - 6 are used for input)
	output reg invalid

	);
	
	reg [4:0] colCount;
	reg sw6, sw5, sw4, sw3, sw2, sw1, sw0;
	reg [1:0] sw9, sw8, sw7;
	
	always @ (*) begin
	
		if (switch[0]) sw0 = 1'b1; //some big number so that we can error checking by seeing if colcount is too high
			else sw0 = 1'b0;
		if (switch[1]) sw1 = 1'b1;
			else sw1 = 1'b0;
		if (switch[2]) sw2 = 1'b1;
			else sw2 = 1'b0;
		if (switch[3]) sw3 = 1'b1;
			else sw3 = 1'b0;
		if (switch[4]) sw4 = 1'b1;
			else sw4 = 1'b0;
		if (switch[5]) sw5 = 1'b1;
			else sw5 = 1'b0;
		if (switch[6]) sw6 = 1'b1;
			else sw6 = 1'b0;
		if (switch[7]) sw7 = 2'b11;
			else sw7 = 2'b00;
		if (switch[8]) sw8 = 2'b11;
			else sw8 = 2'b00;
		if (switch[9]) sw9 = 2'b11;
			else sw9 = 2'b00;
	
		colCount = sw8+sw7+sw6+sw5+sw4+sw3+sw2+sw1+sw0+sw9;
		
		//give invalid output now
		
		if (colCount != 1) invalid = 1'b1; //catches the case of multiple switches and also an invalid switch, and also no switches pushed
		else invalid = 1'b0;
		
	end


endmodule 

module hex_decoder (c, display);

	input [3:0] c; //4 input bits
	output [6:0] display; //7 outputs
	
	//handle taking in inputs
	
	wire wire0, wire1, wire2, wire3, wire4, wire5, wire6, wire7, wire8, wire9, wireA, wireB, wireC, wireD, wireE, wireF;
	
	assign wire0 = ~c[3]&~c[2]&~c[1]&~c[0];//0000
	assign wire1 = ~c[3]&~c[2]&~c[1]&c[0]; //0001
	assign wire2 = ~c[3]&~c[2]&c[1]&~c[0]; //0010
	assign wire3 = ~c[3]&~c[2]&c[1]&c[0];  //0011    0
	assign wire4 = ~c[3]&c[2]&~c[1]&~c[0]; //0100    _ 
	assign wire5 = ~c[3]&c[2]&~c[1]&c[0];  //0101 5 | |  1
	assign wire6 = ~c[3]&c[2]&c[1]&~c[0];  //0110    - 6
	assign wire7 = ~c[3]&c[2]&c[1]&c[0];	//0111 4 | |  2
	assign wire8 = c[3]&~c[2]&~c[1]&~c[0]; //1000    -
	assign wire9 = c[3]&~c[2]&~c[1]&c[0];	//1001
	assign wireA = c[3]&~c[2]&c[1]&~c[0];	//1010    3
	assign wireB = c[3]&~c[2]&c[1]&c[0];	//1011
	assign wireC = c[3]&c[2]&~c[1]&~c[0];	//1100
	assign wireD = c[3]&c[2]&~c[1]&c[0];	//1101
	assign wireE = c[3]&c[2]&c[1]&~c[0];	//1110
	assign wireF = c[3]&c[2]&c[1]&c[0];		//1111
	
	assign display[0] = ~(wire0||wire2||wire3||wire5||wire6||wire7||wire8||wire9||wireA||wireC||wireE||wireF);
	assign display[1] = ~(wire0||wire1||wire2||wire3||wire4||wire7||wire8||wire9||wireA||wireD);
	assign display[2] = ~(wire0||wire1||wire3||wire4||wire5||wire6||wire7||wire8||wire9||wireA||wireB||wireD);
	assign display[3] = ~(wire0||wire2||wire3||wire5||wire6||wire8||wire9||wireB||wireC||wireD||wireE);
	assign display[4] = ~(wire0||wire2||wire6||wire8||wireA||wireB||wireC||wireD||wireE||wireF);
	assign display[5] = ~(wire0||wire4||wire5||wire6||wire8||wire9||wireA||wireB||wireC||wireE||wireF);
	assign display[6] = ~(wire2||wire3||wire4||wire5||wire6||wire8||wire9||wireA||wireB||wireD||wireE||wireF);
endmodule 


module audio (
	// Inputs
	CLOCK_50,
	playSound,
	reset,
	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	I2C_SCLK

);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
parameter clockfreq = 50000000;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;

input playSound, reset;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				I2C_SCLK;


/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [20:0] delay_cnt; 
reg [31:0] timeCount;
reg [20:0] delay;
reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

//control module begins
 reg [2:0] cState, nState;
 reg currentlyCounting;
 reg currentlyWaiting;
 //two states: waiting (waiting for signal), counting (playing sound)
 parameter waiting = 2'b0,
			  counting = 2'b1;
			  

always @ (*) begin //state transitionitis

	case (cState)
	
		waiting: begin
		
					if (playSound) nState = counting;
					else nState = cState;
					
					end
					
		counting: begin
		
					if (timeCount == clockfreq) nState = waiting;
					else nState = cState;
					
					 end
	
	endcase

end

always @ (posedge CLOCK_50) begin //state flip floppers

	
	if (!reset) begin //audio reset
	
		//change state
		cState <= waiting;
			
	end
	
	else cState <= nState;
	
end

//control signals
always @ (*) begin

	currentlyCounting = 1'b0;
	currentlyWaiting = 1'b0;
	
	case (cState)
	
		waiting: currentlyWaiting = 1'b1;
		
		counting: begin
		
					currentlyCounting = 1'b1;
		
					 end
	endcase

end
//control module ends

//datapath begins
always @ (posedge CLOCK_50) begin

		if (!reset) begin
		
		timeCount <= 0;
		
						end
		
		else if (currentlyCounting) begin
		
			
		
			if (timeCount < clockfreq) timeCount <= timeCount+1;
			else timeCount <= 0;
			
			// If statements for different ranges of timeCount. Each if statement
			// will set different delay and thus different note.
			
				//6 notes, dividing into 8 chunks.
				// 1 and 2- C5
				// 3 and 4 - F5
				// 5 - G5
				// 6 - A5
				// 7 - C6
				// 8 - F6
			
			if (	(timeCount > 0) && (timeCount < (	(clockfreq*2)/8	)	)	) delay <= 20'd95556; //C5
			else if ((timeCount > (	(clockfreq*2)/8	))&& (timeCount < ((clockfreq*4)/8))	) delay <= 20'd71586; //F5
			else if (	(timeCount>((clockfreq*4)/8))&&(timeCount<((clockfreq*5)/8))	) delay <= 20'd63776; //G5
			else if (	(timeCount>((clockfreq*5)/8))&&(timeCount<((clockfreq*6)/8))	) delay <= 20'd56818; //A5
			else if (	(timeCount>((clockfreq*6)/8))&&(timeCount<((clockfreq*7)/8))	) delay <= 20'd47778; //C6
			else if (	(timeCount>((clockfreq*7)/8))&&(timeCount<clockfreq)	) delay <= 20'd35793; //F6
		end

end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)

//maybe encapsulate this in a if (currentlyCounting) so that this is only counting
//when we are trying to play the song

	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// assign delay = {SW[3:0], 15'd3000}; old delay. new delay will be driven by
// clock based logic

wire [31:0] sound = snd ? 32'd10000000 : -32'd10000000;


assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= sound;
assign right_channel_audio_out	= sound;

assign write_audio_out			= audio_in_available & audio_out_allowed & currentlyCounting;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/
Audio_Controller Audio_Controller (
		// Inputs
		.CLOCK_50						(CLOCK_50),
		.reset						(~reset), //was ~KEY[0]

		.clear_audio_in_memory		(),
		.read_audio_in				(read_audio_in),
		
		.clear_audio_out_memory		(),
		.left_channel_audio_out		(left_channel_audio_out),
		.right_channel_audio_out	(right_channel_audio_out),
		.write_audio_out			(write_audio_out),

		.AUD_ADCDAT					(AUD_ADCDAT),

		// Bidirectionals
		.AUD_BCLK					(AUD_BCLK),
		.AUD_ADCLRCK				(AUD_ADCLRCK),
		.AUD_DACLRCK				(AUD_DACLRCK),


		// Outputs
		.audio_in_available			(audio_in_available),
		.left_channel_audio_in		(left_channel_audio_in),
		.right_channel_audio_in		(right_channel_audio_in),

		.audio_out_allowed			(audio_out_allowed),

		.AUD_XCK					(AUD_XCK),
		.AUD_DACDAT					(AUD_DACDAT)

	);

	avconf #(.USE_MIC_INPUT(1)) avc (
		.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
		.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
		.CLOCK_50					(CLOCK_50),
		.reset						(~reset) //was ~KEY[0]
	);

endmodule
