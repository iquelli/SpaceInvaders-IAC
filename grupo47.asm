;
;		File: grupo47.asm
;		Authors:
;               Gonçalo Bárias (ist1103124), goncalo.barias@tecnico.ulisboa.pt
;               Gustavo Diogo (ist199233), gustavomanuel30@tecnico.ulisboa.pt
;		        Raquel Braunschweig (ist1102624), raquel.braunschweig@tecnico.ulisboa.pt
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.

;=================================================================
; NUMERIC CONSTANTS:
;-----------------------------------------------------------------

KEYPAD_LIN EQU 0C000H ; peripheral address of the lines
KEYPAD_COL EQU 0E000H ; peripheral address of the columns
LIN_MASK   EQU 0010H  ; mask used to sweep through all the lines of the keypad

DISPLAYS                    EQU 0A000H ; address used to access the displays
ENERGY_MOVEMENT_CONSUMPTION EQU 0FFFBH ; energy depleted when the rover moves (-5%)
ENERGY_MISSILE_CONSUMPTION  EQU 0FFFBH ; energy depleted when the rover shoots a missile (-5%)
ENERGY_GOOD_METEOR_INCREASE EQU 000AH  ; energy gained when the rover hits a good meteor (+10%)
ENERGY_INVADER_INCREASE     EQU 0005H  ; energy gained per each invader the rover destroys (+5%)
ENERGY_HEX_MAX              EQU 0064H  ; the maximum energy value in hexadecimal
ENERGY_HEX_MIN              EQU 0000H  ; the minimum energy value in hexadecimal

HEXTODEC_MSD EQU 0064H ; value used to get the most significant digit from a number in decimal form
HEXTODEC_LSD EQU 000AH ; value used to get the least significant digit

DEF_LIN           EQU 600AH ; address of the command to define a line
DEF_COL           EQU 600CH ; address of the command to define a column
DEF_PIXEL_WRITE   EQU 6012H ; address of the command to write a pixel
DEF_PIXEL_READ    EQU 6014H ; address of the command to read a pixel's state
CLEAR_SCREEN      EQU 6002H ; address of the command to clear the screen
SELECT_BACKGROUND EQU 6042H ; address of the command to select a backround
SOUND_PLAY        EQU 605AH ; address of the command to play the sound

MAX_LIN                 EQU 0020H  ; the number of lines
MAX_COL_ROVER           EQU 003BH  ; maximum column the rover can be at
ROVER_DELAY             EQU 4000H  ; delay used to limit the speed of the rover
ROVER_START_POSITION    EQU 201CH  ; the starting position of the rover's top left pixel
ROVER_DIMENSIONS        EQU 0504H  ; length and height of the rover
ROVER_COLOR             EQU 0F0FFH ; color used for the rover
METEOR_START_POSITION   EQU 2C05H  ; the starting position of any meteors top left pixel
METEOR_GIANT_DIMENSIONS EQU 0505H  ; length and height of the giant meteor
BAD_METEOR_COLOR        EQU 0FF00H ; color used for bad meteors

TRUE         EQU 0001H ; true is represented by the value one
FALSE        EQU 0000H ; false is represented by the value zero
NULL         EQU 0000H ; value equal to zero
NEXT_WORD    EQU 0002H ; value that a word occupies at an address
VAR_LIST_LEN EQU 0003H ; the length of the variables list

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

PLACE 1000H

KEY_PRESSED:  WORD NULL  ; value of the key pressed on a previous loop
KEY_PRESSING: WORD NULL  ; value of the key that is currently being pressed
KEY_CHANGE:   WORD FALSE ; used to verify if the pressed key changed or not (TRUE or FALSE)

ENERGY_HEX: WORD ENERGY_HEX_MAX ; stores the current energy value of the rover in hexadecimal

VAR_LIST:             ; list containing the addresses
	WORD VAR_LIST_LEN ; to all the program variables
	WORD KEY_PRESSED
	WORD KEY_PRESSING
	WORD KEY_CHANGE

KEY_LIST:
	WORD key_Action_0
	WORD key_Action_Placeholder
	WORD key_Action_2
	WORD key_Action_3
	WORD key_Action_4
	WORD key_Action_5
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder

;=================================================================
; IMAGE TABLES:
; The first WORD represents the top left pixel of the image.
; The second WORD contains the dimensions (height and length) of
; canvas the image is painted on.
; The third WORD contains the color to paint the image.
; The rest of the WORD's are used to define the pattern of each
; line, each one represents a line with 0's (uncolored pixels) and
; 1's (colored pixels).
;-----------------------------------------------------------------

ROVER:
	WORD ROVER_START_POSITION
	WORD ROVER_DIMENSIONS
	WORD ROVER_COLOR
	WORD 2000H
	WORD 0A800H
	WORD 0F800H
	WORD 5000H

BAD_METEOR_GIANT:
	WORD METEOR_START_POSITION
	WORD METEOR_GIANT_DIMENSIONS
	WORD BAD_METEOR_COLOR
	WORD 8800H
	WORD 0A800H
	WORD 7000H
	WORD 0A800H
	WORD 8800H

;=================================================================
; INTERRUPTION TABLE:
;-----------------------------------------------------------------

;=================================================================
; STACK POINTER:
;-----------------------------------------------------------------

pile_Init:
	TABLE 100H
SP_Start:

;=================================================================
; MAIN: The starting point of the program.
;-----------------------------------------------------------------

PLACE 0000H

; initializes the program
init:
	MOV  SP, SP_Start  ; initializes the stack pointer
	CALL game_Init

; starts the main loop of the program
main:
	CALL key_Handling

	JMP  main

;=================================================================
; GAME STATES: Controls the current state of the game.
;-----------------------------------------------------------------

; initializes the game by resetting everything and drawing
; the starting objects
game_Init:
	PUSH R0
	PUSH R1

	CALL game_Reset
	CALL energy_Reset
	MOV  R0, 0
	MOV  R1, SELECT_BACKGROUND
	MOV  [R1], R0              ; selects the starting background

	MOV  R0, BAD_METEOR_GIANT
	CALL image_Draw           ; draws the starting meteor
	MOV  R0, ROVER
	CALL image_Draw           ; draws the starting rover

	POP  R1
	POP  R0
	RET

; resets all of the information from the current game
game_Reset:
	PUSH R1

	CALL var_Reset
	CALL meteor_Reset
	CALL rover_Reset
	MOV  R1, CLEAR_SCREEN
	MOV  [R1], R0         ; clears all the pixels on the screen

	POP  R1
	RET

;=================================================================
; KEY HANDLING:
;-----------------------------------------------------------------

key_Handling:
	CALL key_Sweeper
	CALL key_Convert
	CALL key_CheckUpdate
	CALL key_Actions
	RET

key_Sweeper:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

    MOV  R0, KEYPAD_LIN
    MOV  R2, LIN_MASK
	MOV  R3, NULL

key_Sweeper_Wait:
	SHR  R2, 1
	JZ   key_Sweeper_Save

    MOV  R1, KEYPAD_COL
	MOVB [R0], R2
	MOVB R3, [R1]
	MOV  R1, 000FH
	AND  R3, R1
	CMP  R3, NULL
	JZ   key_Sweeper_Wait

key_Sweeper_Save:
	SHL  R3, 8
	OR   R3, R2
	MOV  R0, KEY_PRESSING
	MOV  [R0], R3

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

key_Convert:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R2, KEY_PRESSING
	MOVB R1, [R2]
	ADD  R2, 0001H
	MOVB R0, [R2]

	MOV  R2, 0000H

	CMP  R0, NULL
	JNZ  key_Convert_Lin
	MOV  R0, 0010H

key_Convert_Lin:
	SHR  R0, 1
	JZ   key_Convert_Col
	ADD  R2, 0004H
	JMP  key_Convert_Lin

key_Convert_Col:
	SHR  R1, 1
	JZ   key_Convert_Save
	ADD  R2, 0001H
	JMP  key_Convert_Col

key_Convert_Save:
	MOV  R1, KEY_PRESSING
	MOV  [R1], R2

	POP  R2
	POP  R1
	POP  R0
	RET

key_CheckUpdate:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, KEY_PRESSED
	MOV  R1, [R0]
	MOV  R0, KEY_PRESSING
	MOV  R2, [R0]
	CMP  R1, R2
	JZ   key_CheckUpdate_Return

	MOV  R0, KEY_CHANGE
	MOV  R1, TRUE
	MOV  [R0], R1

key_CheckUpdate_Return:
	POP  R2
	POP  R1
	POP  R0
	RET

key_Actions:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, KEY_PRESSING
	MOV  R1, [R0]
	SHL  R1, 1
	MOV  R0, KEY_LIST
	MOV  R2, [R0 + R1]
	CALL R2

	MOV  R1, KEY_CHANGE
	MOV  R2, [R1]
	CMP  R2, FALSE
	JZ   key_Actions_Return

	MOV  R0, FALSE
	MOV  [R1], R0

	MOV  R1, KEY_PRESSING
	MOV  R2, [R1]
	MOV  R1, KEY_PRESSED
	MOV  [R1], R2

key_Actions_Return:
	POP  R2
	POP  R1
	POP  R0
	RET

key_VerifyChange:
	PUSH R0
	PUSH R1

	MOV  R0, KEY_CHANGE
	MOV  R1, [R0]
	CMP  R1, FALSE

	POP  R1
	POP  R0
	RET

;=================================================================
; KEY ACTIONS:
;-----------------------------------------------------------------

key_Action_0:
	PUSH R1

	MOV  R1, -1     ; subtracts one from the column of the rover,
	CALL rover_Move ; moving it to the left

	POP  R1
	RET

key_Action_2:
	PUSH R1

	MOV  R1, 1      ; adds one to the column of the rover,
	CALL rover_Move ; moving it to the right

	POP  R1
	RET

key_Action_Placeholder:
	RET

key_Action_3:
	CALL key_VerifyChange
	JZ   key_Action_3_Return
	CALL meteor_Move

key_Action_3_Return:
	RET

key_Action_4:
	CALL key_VerifyChange
	JZ   key_Action_4_Return
	MOV  R0, ENERGY_MOVEMENT_CONSUMPTION
	CALL energy_Update

key_Action_4_Return:
	RET

key_Action_5:
	CALL key_VerifyChange
	JZ   key_Action_5_Return
	MOV  R0, ENERGY_GOOD_METEOR_INCREASE
	CALL energy_Update

key_Action_5_Return:
	RET

;=================================================================
; PIXEL SCREEN:
;-----------------------------------------------------------------

image_Draw:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8

	MOVB R1, [R0]      ; obtains the column of the object
	ADD  R0, 0001H
	MOVB R2, [R0]      ; obtains the line where the object currently is
	ADD  R0, 0001H

	MOVB R3, [R0]      ; obtains the length of the object
	ADD  R3, R1        ; calculates the first column to the right of the object that is free
	ADD  R0, 0001H
	MOVB R4, [R0]      ; obtains the height of the object
	ADD  R4, R2        ; calculates the first line below the object that is free

	ADD  R0, 0001H
	MOV  R5, [R0]      ; obtains the color of the object

	MOV  R6, R1        ; initializes the column counter
	MOV  R7, R2        ; initializes the line counter

	ADD  R0, NEXT_WORD
	MOV  R8, [R0]      ; obtains the color pattern for the first line of the object


image_Draw_Loop:
	SHL  R8, 1           ; checks if it needs to color the pixel by using the carry flag
	CALL pixel_Draw
	ADD  R6, 0001H       ; moves onto the next column
	CMP  R6, R3          ; compares the column with the value of column plus length
	JLT  image_Draw_Loop ; continues to draw up until all columns of the object are done

	ADD  R7, 0001H       ; moves onto the next line
	ADD  R0, NEXT_WORD
	MOV  R8, [R0]        ; obtains the color pattern for the new line
	MOV  R6, R1          ; resets the value of the column
	CMP  R7, R4          ; compares the line with the value of line plus height
	JLT  image_Draw_Loop ; continues to draw up until all lines of the object are done

image_Draw_Return:
	POP  R8
	POP  R7
	POP  R6
	POP  R5
	POP  R4
	POP  R3
	POP  R2
	POP  R1
	RET

pixel_Draw:
	PUSH R0
	PUSH R1

	JNC  pixel_Draw_Return  ; if the carry is not 1, pixel is not colored
	MOV  R0, MAX_LIN
	CMP  R7, R0             ; checks if it's trying to paint a pixel
	JGE  pixel_Draw_Return  ; outside the bottom of the screen

	MOV  R0, DEF_COL
	MOV  [R0], R6    ; sets the column of the pixel
	MOV  R0, DEF_LIN
	MOV  [R0], R7    ; sets the line of the pixel

	MOV  R0, DEF_PIXEL_READ
	MOV  R1, [R0]	         ; obtains the state of the pixel
	CMP  R1, NULL	         ; checks if it's not colored
	MOV  R0, DEF_PIXEL_WRITE
	JNZ  pixel_Erase         ; if pixel is already colored, deletes it

pixel_Paint:
	MOV  [R0], R5          ; colors the pixel
	JMP  pixel_Draw_Return

pixel_Erase:
	MOV  R1, NULL ; makes color value equal to null
	MOV  [R0], R1 ; deletes pixel

pixel_Draw_Return:
	POP  R1
	POP  R0
	RET

;=================================================================
; ROVER:
;-----------------------------------------------------------------

rover_Move:
	PUSH R0
	PUSH R2             ; current column of the rover
	PUSH R3             ; maximum column the rover can be at

	MOV  R0, ROVER      ; obtains the address of the rover
	MOVB R2, [R0]       ; obtains the value of the current column of the rover
	ADD  R2, R1         ; updates column value

	JN   rover_Draw_Return
	MOV  R3, MAX_COL_ROVER ; obtains the value of the maximum column the rover can be at
	CMP  R2, R3            ; compares updated column value with maximum column value
	JGT  rover_Draw_Return

	CALL delay_Drawing ; controls the speed at which the rover moves
	CALL image_Draw

	SHL  R2, 8           ; so R2 has 16 bits
	MOV  R0, ROVER       ; obtains the address of the rover
	MOV  R1, [R0]        ; obtains the current position of the rover
	MOV  R3, 00FFH       ; variable to obtain the only the line of the rover
	AND  R1, R3          ; clears column from position
	OR   R1, R2          ; adds new column
	MOV  [R0], R1        ; updates the current position of the rover
	CALL image_Draw

rover_Draw_Return:
	POP  R3
	POP  R2
	POP  R0
	RET

rover_Reset:
	PUSH R0              ; rover's address
	PUSH R1              ; rover's position

	MOV  R0, ROVER        ; obtains the address of the rover
	MOV  R1, ROVER_START_POSITION ; obtains the rover's default starting position
	MOV  [R0], R1        ; updates the rover's current position to the starting position

	POP  R1
	POP  R0
	RET

;=================================================================
; ENERGY OF THE ROVER:
;-----------------------------------------------------------------

energy_Update:
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R2, ENERGY_HEX  ; obtains the address of the current energy 
	MOV  R1, [R2]        ; obtains the current energy
	ADD  R1, R0          ; adds the current energy with the amount to increase/decrease 

	JN   energy_Update_MinLim
	MOV  R3, ENERGY_HEX_MAX ; obtains the maximum value of energy
	CMP  R1, R3          ; compares maximum value with current energy value
	JGE  energy_Update_MaxLim

	JMP  energy_Update_Display

energy_Update_MaxLim:
	MOV  R1, ENERGY_HEX_MAX ; makes the value of energy equal to the maximum value of energy
	JMP  energy_Update_Display

energy_Update_MinLim:
	MOV  R1, ENERGY_HEX_MIN ; makes the value of energy equal to the minimum value of energy

energy_Update_Display:
	MOV  [R2], R1         ; updates the value of energy

	CALL hextodec_Convert
	MOV  R2, DISPLAYS     ; obtains the address of the display
	MOV  [R2], R0         ; updates the value in the display

	POP  R3
	POP  R2
	POP  R1
	RET

energy_Reset:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R2, ENERGY_HEX  ; obtains the address of the current energy 
	MOV  R1, ENERGY_HEX_MAX ; obtains the maximum energy
	MOV  [R2], R1        ; updates the current energy to maximum energy

	CALL hextodec_Convert
	MOV  R2, DISPLAYS     ; obtains the address of the display
	MOV  [R2], R0         ; updates the value in the display

	POP  R2
	POP  R1
	POP  R0
	RET

;=================================================================
; MISSILE:
;-----------------------------------------------------------------

;=================================================================
; METEOR:
;-----------------------------------------------------------------

meteor_Move:
	PUSH R1              ; meteor's new position
	PUSH R2              ; column of the bad giant meteor
	PUSH R3              ; maximum line the meteor can be at

	MOV  R0, BAD_METEOR_GIANT ; obtains the address of the giant meteor
	ADD  R0, 1           ; obtains the address of the the meteor's position
	MOVB R2, [R0]        ; obtains the line of the meteor
	SUB  R0, 1           ; obtains the address of the giant meteor
	ADD  R2, 1           ; uptates the line

	CALL image_Draw

	MOV  R3, MAX_LIN     ; obtains the value of the maximum line the meteor can be at
	CMP  R2, R3          ; compares new line with maximum line
	JGT  meteor_Move_Return

	MOV  R0, BAD_METEOR_GIANT ; obtains the address of the giant meteor
	MOV  R2, [R0]        ; obtains meteor's current position
	ADD  R2, 0001H
	MOV  [R0], R2
	CALL image_Draw

	MOV  R4, SOUND_PLAY  ; obtains the address to the command that makes sound play
	MOV  R2, 0
	MOV  [R4], R2        ; makes the sound 0 play

meteor_Move_Return:
	POP  R3
	POP  R2
	POP  R1
	RET

meteor_Reset:
	PUSH R0              ; address of the bad giant meteor
	PUSH R1              ; starting position of the meteor

	MOV  R0, BAD_METEOR_GIANT      ; obtains the address of the meteor
	MOV  R1, METEOR_START_POSITION ; obtains the meteor's starting position
	MOV  [R0], R1                  ; resets position

	POP  R1
	POP  R0
	RET

;=================================================================
; MISCELLANIOUS:
;-----------------------------------------------------------------

hextodec_Convert:
	PUSH R2
	PUSH R3
	PUSH R4

	MOV  R0, R1
	MOV  R3, HEXTODEC_MSD
	MOV  R4, HEXTODEC_LSD

	DIV  R0, R3
	MOD  R1, R3

	MOV  R2, R1
	DIV  R2, R4
	SHL  R0, 4
	OR   R0, R2

	MOD  R1, R4
	SHL  R0, 4
	OR   R0, R1

	POP  R4
	POP  R3
	POP  R2
	RET

var_Reset:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R1, VAR_LIST
	MOV  R3, [R1]
	MOV  R2, 0

var_Reset_Loop:
	ADD  R1, NEXT_WORD
	MOV  R0, [R1]
	MOV  [R0], R2

	SUB  R3, 0001H
	JNZ  var_Reset_Loop

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

delay_Drawing:
	PUSH R0              ; value of the delay
	MOV  R0, ROVER_DELAY       ; obtains the value of the delay

delay_Drawing_Loop:
	SUB  R0, 1           ; subtracts one from the delay
	JNZ  delay_Drawing_Loop ; continues until delay is zero

	POP  R0
	RET

;=================================================================
; INTERRUPTION HANDLING:
;-----------------------------------------------------------------
