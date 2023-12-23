An implementation of a 7x7 Connect Four game on the Altera DE1_SoC board. This project
was originally created for ECE 241, a Digital Systems course at the University of
Toronto that focused on implementations on the DE1_SoC board without the use of its
ARM microprocessor.

As such, this project will contain solely Quartus project + Verilog HDL files for
running it on the FPGA.


### Intended user experience

This implementation revolves around taking in user input via the DE1_SoC switches &
keys and outputting the game board on a VGA display. Users can select a column using
switches and push it to the system via a key press. 

### Progress

1. User input **Completed!**
    - [x] Switch input
        - [x] Error checking
    - [x] LED output
        - [x] Error & success messages
    
    Players will input a column for tile placement using the board's rightmost
    switches. There is some error-checking logic that will flash blinking LEDs
    following a key press with more than one switch high or an out of bounds column.

2. Audio output 
    - [x] Audio played following a successful column push from the user
    - [ ] Audio played following an invalid column push from the user

    A small sequence of notes will be played following a key press by a user. Two
    different sequences will be played depending on if it is a valid or an invalid
    combination of switches.

3. VGA output
    - [ ] Display title screen to VGA
    - [ ] Hold game board in memory
    - [ ] Check for winners / match ends 
    - [ ] Update game board in memory given column press
    - [ ] Display game board to VGA
    - [ ] Display winner, if any