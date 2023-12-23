//audio module

//Base features.
/*

	When a key is pressed, we'll play a sequence of notes to indicate tile placement.
	We could integrate this with the input module relatively easy; whenever
	the input receives a valid input, we'll play the sequence of notes to go along
	with the success message.
	
	For now, we'll write this module assuming a signal of KEY[1]. When KEY[1] is
	pressed, we'll play a sequence of notes over the course of 1 second ( i think
	this is long enough )
	
	We can achieve this through a counting state.
	
	
	Additional features.
	
	Integrate with the memory component to store an audio file to be played. This
	audio file could be played with a separate KEY if we were to blend all three
	modules.

*/

module audio (
	// Inputs
	CLOCK_50,
	KEY,
	LEDR,
	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	I2C_SCLK,
	SW
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
input		[3:0]	KEY;
input		[3:0]	SW;

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
output reg [9:0] LEDR;

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
		
					if (!KEY[1]) nState = counting;
					else nState = cState;
					
					end
					
		counting: begin
		
					if (timeCount == clockfreq) nState = waiting;
					else nState = cState;
					
					 end
	
	endcase

end

always @ (posedge CLOCK_50) begin //state flip floppers

	
	if (!KEY[0]) begin //audio reset
	
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

		if (!KEY[0]) begin
		
		timeCount <= 0;
		LEDR[9:0] <= 1111111111;
		LEDR[3] <= 1;
		LEDR[4] <= 1;
		LEDR[5] <= 1;
		
						end
		
		else if (currentlyWaiting) begin
		
		LEDR[9:0] <= 0000000001;
											end
		
		else if (currentlyCounting) begin
		
			LEDR[9:0] <= 1000000000;
		
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
		.reset						(~KEY[0]), //was ~KEY[0]

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
		.reset						(~KEY[0]) //was ~KEY[0]
	);

endmodule
