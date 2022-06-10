;
;		File: grupo47.asm
;		Authors:
;		        - Gonçalo Bárias (ist1103124), goncalo.barias@tecnico.ulisboa.pt
;		        - Gustavo Diogo (ist199233), gustavomanuel30@tecnico.ulisboa.pt
;		        - Raquel Braunschweig (ist1102624), raquel.braunschweig@tecnico.ulisboa.pt
;		Group: 47
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.
;		Date: 17-06-2022

;=============================================================================
; NUMERIC CONSTANTS:
;=============================================================================

KEYPAD_LIN EQU 0C000H ; peripheral address of the lines
KEYPAD_COL EQU 0E000H ; peripheral address of the columns
LIN_MASK   EQU 0008H  ; mask used to sweep through all the lines of the keypad

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

MAX_LIN                 EQU 0020H  ; the first line we can't paint at
MAX_COL_ROVER           EQU 003BH  ; maximum column the rover can be at
ROVER_START_POS_X       EQU 0020H  ; the starting X position of the rover's top left pixel
ROVER_START_POS_Y       EQU 001CH  ; the starting Y position of the rover's top left pixel
ROVER_DIMENSIONS        EQU 0504H  ; length and height of the rover
ROVER_COLOR             EQU 0F0FFH ; color used for the rover
ROVER_DELAY             EQU 4000H  ; delay used to limit the speed of the rover
METEOR_START_POS_Y      EQU 0FFFBH ; the starting Y position of any meteors top left pixel
METEOR_GIANT_DIMENSIONS EQU 0505H  ; length and height of the giant meteor
BAD_METEOR_COLOR        EQU 0FF00H ; color used for bad meteors

TRUE         EQU 0001H ; true is represented by the value one
FALSE        EQU 0000H ; false is represented by the value zero
NULL         EQU 0000H ; value equal to zero
NEXT_WORD    EQU 0002H ; value that a word occupies at an address
NEXT_BYTE    EQU 0001H ; value that a byte occupies at an address
VAR_LIST_LEN EQU 0003H ; the length of the variables list

;=============================================================================
; VARIABLE DECLARATION:
;=============================================================================

PLACE 1000H

KEY_PRESSED:  LOCK NULL  ; value of the key pressed on a previous loop
KEY_PRESSING: LOCK NULL  ; value of the key that is currently being pressed

ENERGY_HEX: WORD ENERGY_HEX_MAX ; stores the current energy value of the rover in hexadecimal

MOVE_METEOR:  LOCK FALSE
MOVE_MISSILE: LOCK FALSE
ENERGY_DRAIN: LOCK FALSE

VAR_LIST:             ; list containing the addresses
	WORD VAR_LIST_LEN ; to all the program variables
	WORD KEY_PRESSED
	WORD KEY_PRESSING

;=============================================================================
; IMAGE TABLES:
; - The first WORD represents the top left pixel of the image. (X, Y)
; - The second WORD contains the dimensions of the canvas the image is painted
;   on. (height, length)
; - The third WORD contains the color to paint the image.
; - The rest of the WORD's are used to define the pattern of each line, each
;   one represents a line with 0's (uncolored pixels) and 1's (colored pixels).
;=============================================================================

ROVER:
	WORD ROVER_START_POS_X, ROVER_START_POS_Y
	WORD ROVER_PATTERN

ROVER_PATTERN:
	WORD ROVER_DIMENSIONS
	WORD ROVER_COLOR
	WORD 2000H
	WORD 0A800H
	WORD 0F800H
	WORD 5000H

BAD_METEOR_GIANT:
	WORD 002CH, METEOR_START_POS_Y
	WORD BAD_METEOR_GIANT_PATTERN

BAD_METEOR_GIANT_PATTERN:
	WORD METEOR_GIANT_DIMENSIONS
	WORD BAD_METEOR_COLOR
	WORD 8800H
	WORD 0A800H
	WORD 7000H
	WORD 0A800H
	WORD 8800H

;=============================================================================
; INTERRUPTION TABLE:
;=============================================================================

inte_Tab:
	WORD inte_MoveMeteor
	WORD inte_MoveMissile
	WORD inte_EnergyDepletion

;=============================================================================
; PROCESSES FIFO'S:
;=============================================================================

main_FIFO:
	STACK 100H
SP_Main:

key_FIFO:
	STACK 100H
SP_Key:

;=============================================================================
; MAIN: The starting point of the program.
;=============================================================================

PLACE 0000H

; ----------------------------------------------------------------------------
; main: Initializes the program.
; ----------------------------------------------------------------------------

main:
	MOV  SP, SP_Main   ; initializes the stack pointer
	MOV  BTE, inte_Tab ; initializes the interruption table
	EI0
	EI1
	EI2
	EI

	CALL key_Sweeper

;=============================================================================
; KEY HANDLING: Reads input from a keypad that the program uses to control the
; game.
;=============================================================================

PROCESS SP_Key

; ----------------------------------------------------------------------------
; key_Sweeper: Does a full swipe on the keypad to check the key the user is
; pressing and saves it.
; ----------------------------------------------------------------------------

key_Sweeper:
	MOV  R0, KEYPAD_LIN
	MOV  R1, KEYPAD_COL
	MOV  R2, LIN_MASK
	MOV  R4, 000FH

key_Sweeper_Wait:
	WAIT

	MOVB [R0], R2         ; sends the value of the line currently being analysed to the line peripheral
	MOVB R3, [R1]         ; saves the value of the column from the peripheral
	AND  R3, R4           ; obtains only the bits 0-3 from the column peripheral
	JNZ  key_Convert

	SHR  R2, 1            ; moves on to the next line of the keypad
	JNZ  key_Sweeper_Wait ; it only swipes the keypad once
	MOV  R2, LIN_MASK
	JMP  key_Sweeper_Wait

; ----------------------------------------------------------------------------
; key_Convert: Converts the arbitrary column and line values into the
; actual key the user is pressing. If no key is being pressed then it's as if
; the user is pressing a 17th imaginary key.
; ----------------------------------------------------------------------------

key_Convert:
	MOV  R5, 0000H          ; initializes the key counter at 0
	MOV  R6, R2

key_Convert_Lin:
	SHR  R6, 1              ; obtains an actual number for the line of the key
	JZ   key_Convert_Col
	ADD  R5, 0004H          ; per line there are 4 keys
	JMP  key_Convert_Lin

key_Convert_Col:
	SHR  R3, 1              ; obtains an actual number for the column of the key
	JZ   key_Convert_Save
	ADD  R5, 0001H          ; when the line is fixed it just adds 1 to get to the right key
	JMP  key_Convert_Col

key_Convert_Save:
	MOV  [KEY_PRESSED], R5 ; saves the number of the key that is pressed (0H - FH)

; ----------------------------------------------------------------------------
; key_CheckChange: Checks if the user is holding down a key or if it's a new
; key all together.
; ----------------------------------------------------------------------------

key_CheckChange:
	YIELD

	MOV  [KEY_PRESSING], R5

	MOVB [R0], R2
	MOVB R3, [R1]
	AND  R3, R4
	JNZ  key_CheckChange

	JMP  key_Sweeper

;=============================================================================
; GAME STATES: Controls the current state of the game.
;=============================================================================

; ----------------------------------------------------------------------------
; game_Init: Initializes the game by resetting everything and drawing the
; starting objects.
; ----------------------------------------------------------------------------

game_Init:
	PUSH R0

	CALL game_Reset
	CALL energy_Reset
	MOV  R0, 0
	MOV  [SELECT_BACKGROUND], R0 ; selects the starting background

	MOV  R0, BAD_METEOR_GIANT
	CALL image_Draw           ; draws the starting meteor
	MOV  R0, ROVER
	CALL image_Draw           ; draws the starting rover

	POP  R0
	RET

;=============================================================================
; PIXEL SCREEN: Controls what gets pixelated onto the screen.
;=============================================================================

; ----------------------------------------------------------------------------
; image_Draw: Draws an image received as an argument into the pixelscreen.
; It knows the top left coordinate and the dimensions of the image in order to
; paint it.
; - R0 -> image table to draw
; ----------------------------------------------------------------------------

image_Draw:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8
	PUSH R9

	MOV  R1, [R0]      ; obtains the column of the object
	ADD  R0, NEXT_WORD
	MOV  R2, [R0]      ; obtains the line where the object currently is

	ADD  R0, NEXT_WORD
	MOV  R6, [R0]      ; obtains the address that stores the drawing information
	MOV  R0, R6

	MOVB R3, [R0]      ; obtains the length of the object
	ADD  R3, R1        ; calculates the first column to the right of the object that is free
	ADD  R0, NEXT_BYTE
	MOVB R4, [R0]      ; obtains the height of the object
	ADD  R4, R2        ; calculates the first line below the object that is free

	ADD  R0, NEXT_BYTE
	MOV  R5, [R0]      ; obtains the color of the object

	ADD  R0, NEXT_WORD
	MOV  R8, [R0]      ; obtains the color pattern for the first line of the object

	MOV  R6, R1        ; initializes the column counter
	MOV  R7, R2        ; initializes the line counter
	MOV  R9, MAX_LIN   ; stores the first line outside the bottom of the screen

image_Draw_VerifyBounds:
	CMP  R7, NULL            ; checks if it's trying to paint a pixel outside the top of the screen
	JLT  image_Draw_NextLine
	CMP  R7, R9              ; checks if it's trying to paint a pixel outside the bottom of the screen
	JGE  image_Draw_Return

image_Draw_Loop:
	SHL  R8, 1           ; checks if it needs to color the pixel by using the carry flag
	CALL pixel_Draw
	ADD  R6, 0001H       ; moves onto the next column
	CMP  R6, R3          ; compares the column with the value of column plus length
	JLT  image_Draw_Loop ; continues to draw up until all columns of the object are done

image_Draw_NextLine:
	ADD  R7, 0001H               ; moves onto the next line
	ADD  R0, NEXT_WORD
	MOV  R8, [R0]                ; obtains the color pattern for the new line
	MOV  R6, R1                  ; resets the value of the column
	CMP  R7, R4                  ; compares the line with the value of line plus height
	JLT  image_Draw_VerifyBounds ; continues to draw up until all lines of the object are done

image_Draw_Return:
	POP  R9
	POP  R8
	POP  R7
	POP  R6
	POP  R5
	POP  R4
	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; pixel_Draw: Either erases a pixel if the pixel state is not 0, draws a pixel
; if the pixel state is 0 or does nothing if the C flag is 0.
; - R5 -> current color to paint if possible
; - R6 -> current column of the pixel
; - R7 -> current line of the pixel
; - C flag -> 0 it does not paint or erase, 1 it can paint or erase
; ----------------------------------------------------------------------------

pixel_Draw:
	PUSH R1

	JNC  pixel_Draw_Paint  ; if the carry is not 1, pixel is not colored

	MOV  [DEF_COL], R6     ; sets the column of the pixel
	MOV  [DEF_LIN], R7     ; sets the line of the pixel

	MOV  R1, [DEF_PIXEL_READ]  ; obtains the state of the pixel
	CMP  R1, NULL	           ; checks if it's not colored

pixel_Draw_Paint:
	MOV  [DEF_PIXEL_WRITE], R5 ; colors the pixel
	POP  R1
	RET

;=============================================================================
; ROVER: Deals with the movement of the rover that defends planet X.
;=============================================================================

; ----------------------------------------------------------------------------
; rover_Move: Moves the rover continuously left to right.
; - R1 -> direction the rover is supposed to go
; ----------------------------------------------------------------------------

rover_Move:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, ROVER
	MOV  R2, [R0]       ; obtains the current column of the rover
	ADD  R2, R1         ; updates column value

	JN   rover_Move_Return ; if it tries to go left but it's on column 0, it exits
	MOV  R1, MAX_COL_ROVER ; obtains the maximum column the rover can be at
	CMP  R2, R1            ; compares updated column value with maximum column value
	JGT  rover_Move_Return ; if it tries to go right but it can't fit in the screen, it exits

	CALL delay_Drawing ; controls the speed at which the rover moves
	CALL image_Draw    ; it erases the current rover

	MOV  [R0], R2      ; updates the current position of the rover
	CALL image_Draw    ; paints new rover on the pixelscreen

rover_Move_Return:
	POP  R2
	POP  R1
	POP  R0
	RET

;=============================================================================
; ENERGY OF THE ROVER: The rover isn't immune and therefore has internal
; energy that can decrease with time, but also increase with certain actions.
;=============================================================================

; ----------------------------------------------------------------------------
; energy_Update: It updates the energy and the displays with the new value it
; calculates.
; - R0 -> value (%) to increase/decrease the energy percentage
; ----------------------------------------------------------------------------

energy_Update:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R1, [ENERGY_HEX] ; obtains the current energy
	ADD  R1, R0           ; adds the current energy with the amount to increase/decrease

	JN   energy_Update_MinLim ; if the energy becomes negative it becomes stuck at 0
	MOV  R2, ENERGY_HEX_MAX   ; obtains the maximum value of energy
	CMP  R1, R2               ; compares current energy value with maximum energy value
	JGT  energy_Update_MaxLim ; when the energy exceeds the limit it also becomes stuck at the maximum

	JMP  energy_Update_Display

energy_Update_MaxLim:
	MOV  R1, ENERGY_HEX_MAX ; makes the value of the energy stuck at the maximum
	JMP  energy_Update_Display

energy_Update_MinLim:
	MOV  R1, ENERGY_HEX_MIN ; makes the value of the energy stuck at the minimum

energy_Update_Display:
	MOV  [ENERGY_HEX], R1 ; updates the new value of the energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0   ; updates the value in the displays

	POP  R2
	POP  R1
	POP  R0
	RET

;=============================================================================
; MISSILE:
;=============================================================================

;=============================================================================
; METEOR: Deals with two types of meteors, the good ones that help the rover
; defend the planet X and the bad ones that destroy the rover and the planet X.
;=============================================================================

; ----------------------------------------------------------------------------
; key_Action_0: Moves the rover to the left.
; ----------------------------------------------------------------------------

key_Action_0:
	PUSH R1

	MOV  R1, -1     ; subtracts one from the column of the rover,
	CALL rover_Move ; moving it to the left

	POP  R1
	RET

; ----------------------------------------------------------------------------
; key_Action_2: Moves the rover to the right.
; ----------------------------------------------------------------------------

key_Action_2:
	PUSH R1

	MOV  R1, 1      ; adds one to the column of the rover,
	CALL rover_Move ; moving it to the right

	POP  R1
	RET
; ----------------------------------------------------------------------------
; meteor_Move: Moves the meteor one line for each press of a certain key
; ----------------------------------------------------------------------------

meteor_Move_:
	MOV  R0, BAD_METEOR_GIANT
	MOV  R1, R0
	ADD  R1, NEXT_WORD
	MOV  R2, [R1]        ; obtains the current line of the meteor
	ADD  R2, 0001H       ; obtains the new line

	MOV  R3, MAX_LIN
	CMP  R2, R3          ; compares new line with maximum amount of lines
	JGT  meteor_Move_Return

	CALL image_Draw      ; erases the old meteor

	MOV  [R1], R2        ; actually updates the new line after verifying it's safe to do so
	CALL image_Draw      ; draws the meteor in the new position

meteor_Move_Return:

;=============================================================================
; MISCELLANIOUS: various routines that don't fit a specific category.
;=============================================================================

; ----------------------------------------------------------------------------
; hextodec_Convert: Given any hexadecimal value it converts it into 12 bits,
; where each group of 4 bits represent the a digit of the decimal version.
; - R1 -> hexadecimal number to convert
; - R0 -> hexadecimal converted into decimal in the form of 12 bits
; ----------------------------------------------------------------------------

hextodec_Convert:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4

	MOV  R0, R1          ; obtains the value to convert
	MOV  R3, HEXTODEC_MSD
	MOV  R4, HEXTODEC_LSD

	DIV  R0, R3          ; obtains the first digit
	MOD  R1, R3          ; takes out the first digit

	MOV  R2, R1          ; moves the remaning value to a new register
	DIV  R2, R4          ; gets the second digit
	SHL  R0, 4           ; isolates the first digit
	OR   R0, R2          ; adds the second one

	MOD  R1, R4          ; obtains the third digit
	SHL  R0, 4           ; isolates the first and second digit
	OR   R0, R1          ; adds the third digit

	POP  R4
	POP  R3
	POP  R2
	POP  R1
	RET

; ----------------------------------------------------------------------------
; delay_Drawing; Controls the rate at which the program draws an image
; ----------------------------------------------------------------------------

delay_Drawing:
	PUSH R0              ; value of the delay
	MOV  R0, ROVER_DELAY ; obtains the value of the delay

delay_Drawing_Loop:
	SUB  R0, 1              ; subtracts one from the delay
	JNZ  delay_Drawing_Loop ; continues until delay is zero

	POP  R0
	RET

;=============================================================================
; RESET FUNCTIONS:
;=============================================================================

; ----------------------------------------------------------------------------
; rover_Reset: Resets the rovers starting position to the center of the screen.
; ----------------------------------------------------------------------------

rover_Reset:
	PUSH R0
	PUSH R1

	MOV  R0, ROVER
	MOV  R1, ROVER_START_POS_X
	MOV  [R0], R1 ; resets the rover's X current position to the starting position

	ADD  R0, NEXT_WORD
	MOV  R1, ROVER_START_POS_Y
	MOV  [R0], R1 ; resets the rover's Y current position to the starting position

	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; energy_Reset: Resets the energy back to 100% when a new game begins.
; ----------------------------------------------------------------------------

energy_Reset:
	PUSH R0
	PUSH R1

	MOV  R1, ENERGY_HEX_MAX
	MOV  [ENERGY_HEX], R1 ; resets the current energy to maximum energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0   ; resets the value in the display in decimal form

	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; meteor_Reset: Resets the meteor's starting position.
; ----------------------------------------------------------------------------

meteor_Reset:
	PUSH R0
	PUSH R1

	MOV  R0, BAD_METEOR_GIANT
	MOV  R1, 002CH
	MOV  [R0], R1 ; resets a meteor's X current position to the starting position
	ADD  R0, NEXT_WORD
	MOV  R1, METEOR_START_POS_Y
	MOV  [R0], R1 ; resets a meteor's Y current position to the starting position

	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; var_Reset: It looks at all the program variables and resets them to 0
; (NULL or FALSE).
; ----------------------------------------------------------------------------

var_Reset:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R1, VAR_LIST
	MOV  R3, [R1]        ; obtains the length of the variables list
	MOV  R2, 0

var_Reset_Loop:
	ADD  R1, NEXT_WORD   ; obtains the next element on the list, which is an address variable
	MOV  R0, [R1]        ; stores the address variable in another register
	MOV  [R0], R2        ; resets the content of the address

	SUB  R3, 0001H       ; keeps going up until all program variables have been reseted
	JNZ  var_Reset_Loop

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Reset: Resets all of the information of the current game.
; ----------------------------------------------------------------------------

game_Reset:
	CALL var_Reset
	CALL meteor_Reset
	CALL rover_Reset
	MOV  [CLEAR_SCREEN], R0 ; clears all the pixels on the screen
	RET

;=============================================================================
; INTERRUPTION HANDLING:
;=============================================================================

inte_MoveMeteor:
	MOV [MOVE_METEOR], R0
	RFE

inte_MoveMissile:
	MOV [MOVE_MISSILE], R0
	RFE

inte_EnergyDepletion:
	MOV [ENERGY_DRAIN], R0
	RFE
