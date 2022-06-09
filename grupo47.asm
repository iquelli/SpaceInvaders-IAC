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

MIN_LIN                 EQU 0000H  ; the minimum line we can paint at
MAX_LIN                 EQU 0020H  ; the maximum line we can paint at
MAX_COL_ROVER           EQU 003BH  ; maximum column the rover can be at
ROVER_START_POS_X       EQU 0020H  ; the starting X position of the rover's top left pixel
ROVER_START_POS_Y       EQU 001CH  ; the starting Y position of the rover's top left pixel
ROVER_DIMENSIONS        EQU 0504H  ; length and height of the rover
ROVER_COLOR             EQU 0F0FFH ; color used for the rover
ROVER_DELAY             EQU 4000H  ; delay used to limit the speed of the rover
METEOR_START_POS_Y      EQU 0FFFBH  ; the starting Y position of any meteors top left pixel
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

;=============================================================================
; STACK POINTER:
;=============================================================================

pile_Init:
	STACK 100H
SP_Start:

;=============================================================================
; MAIN: The starting point of the program. Initializes the program and starts
; the main loop of the program.
;=============================================================================

PLACE 0000H

main:
	MOV  SP, SP_Start  ; initializes the stack pointer
	CALL game_Init
	JMP  key_Handling   ; starts the main loop and keeps waiting for new keys

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
; KEY HANDLING: Reads input from a keypad that the program uses to control the
; game.
;=============================================================================

key_Handling:
	CALL key_Sweeper
	CALL key_Convert
	CALL key_CheckChange
	CALL key_Actions

	JMP  key_Handling

; ----------------------------------------------------------------------------
; key_Sweeper: Does a full swipe on the keypad to check the key the user is
; pressing and saves it.
; ----------------------------------------------------------------------------

key_Sweeper:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R0, KEYPAD_LIN
	MOV  R2, LIN_MASK
	MOV  R3, NULL

key_Sweeper_Wait:
	MOV  R1, KEYPAD_COL
	MOVB [R0], R2         ; sends the value of the line currently being analysed to the line peripheral
	MOVB R3, [R1]         ; saves the value of the column from the peripheral
	MOV  R1, 000FH
	AND  R3, R1           ; obtains only the bits 0-3 from the column peripheral
	CMP  R3, NULL         ; keeps going up until a key is being pressed
	JNZ  key_Sweeper_Save

	SHR  R2, 1            ; moves on to the next line of the keypad
	JZ   key_Sweeper_Save ; it only swipes the keypad once

	JMP key_Sweeper_Wait

key_Sweeper_Save:
	SHL  R3, 8            ; makes up space to store the line
	OR   R3, R2           ; saves the line of the key being pressed
	MOV  [KEY_PRESSING], R3 ; updates the key that is being pressed with the representing bits

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Convert: Converts the arbitrary column and line values into the
; actual key the user is pressing. If no key is being pressed then it's as if
; the user is pressing a 17th imaginary key.
; ----------------------------------------------------------------------------

key_Convert:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R2, KEY_PRESSING
	MOVB R1, [R2]           ; obtains the 8 bits representing the column of the key
	ADD  R2, 0001H
	MOVB R0, [R2]           ; obtains the 8 bits representing the line of the key

	MOV  R2, 0000H          ; initializes the key counter at 0

	CMP  R0, NULL
	JNZ  key_Convert_Lin    ; if no key is being pressed it's as if the user
	MOV  R0, 0010H          ; is pressing a 17th imaginary key

key_Convert_Lin:
	SHR  R0, 1              ; obtains an actual number for the line of the key
	JZ   key_Convert_Col
	ADD  R2, 0004H          ; per line there are 4 keys
	JMP  key_Convert_Lin

key_Convert_Col:
	SHR  R1, 1              ; obtains an actual number for the column of the key
	JZ   key_Convert_Save
	ADD  R2, 0001H          ; when the line is fixed it just adds 1 to get to the right key
	JMP  key_Convert_Col

key_Convert_Save:
	MOV  [KEY_PRESSING], R2 ; saves the number of the key that is pressed (00H - 10H)

	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_CheckChange: Checks if the user is holding down a key or if it's a new
; key all together.
; ----------------------------------------------------------------------------

key_CheckChange:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R1, [KEY_PRESSED]  ; obtains the value of the key pressed before
	MOV  R2, [KEY_PRESSING] ; obtains the value of the key currently pressed

	MOV  R0, KEY_CHANGE
	CMP  R1, R2           ; compares both values
	JZ   key_CheckChange_NoChange
	MOV  R1, TRUE
	JMP  key_CheckChange_Save

key_CheckChange_NoChange:
	MOV  R1, FALSE        ; the keys stayed the same so no change happened

key_CheckChange_Save:
	MOV  [R0], R1         ; marks if there was a key change

	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_VerifyChange: Changes the Z flag to 0 if the user is pressing down the
; same key, else it sets it to 1. It's used to know if the user is holding down
; a key or not.
; ----------------------------------------------------------------------------

key_VerifyChange:
	PUSH R1

	MOV  R1, [KEY_CHANGE] ; obtains the value of key change (TRUE or FALSE)
	CMP  R1, FALSE        ; checks if there has been a key change

	POP  R1
	RET

; ----------------------------------------------------------------------------
; key_Actions: Executes a certain routine depending on the key that is
; currently being held down.
; ----------------------------------------------------------------------------

key_Actions:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, KEY_PRESSING
	MOV  R1, [R0]         ; obtains the value of the key currently pressed
	SHL  R1, 1            ; each WORD takes two addresses so it multiplies the key by 2
	MOV  R0, KEY_LIST
	MOV  R2, [R0 + R1]    ; obtains the address of the routine to call
	CALL R2

	CALL key_VerifyChange ; checks if there was no change in the keys
	JZ   key_Actions_Return

	MOV  R2, [KEY_PRESSING] ; gets the key being pressed in the current loop
	MOV  [KEY_PRESSED], R2  ; updates the value of the key pressed previously to the new one

key_Actions_Return:
	POP  R2
	POP  R1
	POP  R0
	RET

;=============================================================================
; KEY ACTIONS: Executes a command based on the key that is pressed.
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
; key_Action_Placeholder: Routine that blocks certain keys from doing anything.
; ----------------------------------------------------------------------------

key_Action_Placeholder:
	RET

; ----------------------------------------------------------------------------
; key_Action_3: Moves the meteor one unit down
; ----------------------------------------------------------------------------

key_Action_3:
	CALL key_VerifyChange
	JZ   key_Action_3_Return ; if the button is being held down it returns
	CALL meteor_Move

key_Action_3_Return:
	RET

; ----------------------------------------------------------------------------
; key_Action_4: Decreases the energy value in the display.
; ----------------------------------------------------------------------------

key_Action_4:
	CALL key_VerifyChange
	JZ   key_Action_4_Return ; if the button is being held down it returns
	MOV  R0, ENERGY_MOVEMENT_CONSUMPTION
	CALL energy_Update

key_Action_4_Return:
	RET

; ----------------------------------------------------------------------------
; key_Action_5: Increases the energy value in the display.
; ----------------------------------------------------------------------------

key_Action_5:
	CALL key_VerifyChange
	JZ   key_Action_5_Return ; if the button is being held down it returns
	MOV  R0, ENERGY_GOOD_METEOR_INCREASE
	CALL energy_Update

key_Action_5_Return:
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

image_Draw_VerifyBounds:
	MOV  R9, MIN_LIN
	CMP  R7, R9              ; checks if it's trying to paint a pixel
	JLT  image_Draw_NextLine ; outside the bottom of the screen
	MOV  R9, MAX_LIN
	CMP  R7, R9              ; checks if it's trying to paint a pixel
	JGE  image_Draw_Return   ; outside the top of the screen

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

	JNC  pixel_Draw_Return  ; if the carry is not 1, pixel is not colored

	MOV  [DEF_COL], R6      ; sets the column of the pixel
	MOV  [DEF_LIN], R7      ; sets the line of the pixel

	MOV  R1, [DEF_PIXEL_READ]  ; obtains the state of the pixel
	CMP  R1, NULL	           ; checks if it's not colored
	JNZ  pixel_Erase           ; if pixel is already colored, deletes it

pixel_Paint:
	MOV  [DEF_PIXEL_WRITE], R5 ; colors the pixel
	JMP  pixel_Draw_Return

pixel_Erase:
	MOV  R1, NULL              ; makes color value equal to null
	MOV  [DEF_PIXEL_WRITE], R1 ; deletes pixel

pixel_Draw_Return:
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
	PUSH R3

	MOV  R0, ROVER
	MOV  R2, [R0]       ; obtains the current column of the rover
	ADD  R2, R1         ; updates column value

	JN   rover_Move_Return ; if it tries to go left but it's on column 0, it exits
	MOV  R3, MAX_COL_ROVER ; obtains the maximum column the rover can be at
	CMP  R2, R3            ; compares updated column value with maximum column value
	JGT  rover_Move_Return ; if it tries to go right but it can't fit in the screen, it exits

	CALL delay_Drawing ; controls the speed at which the rover moves
	CALL image_Draw    ; it erases the current rover

	MOV  [R0], R2      ; updates the current position of the rover
	CALL image_Draw    ; paints new rover on the pixelscreen

rover_Move_Return:
	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

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

; ----------------------------------------------------------------------------
; energy_Reset: Resets the energy back to 100% when a new game begins.
; ----------------------------------------------------------------------------

energy_Reset:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R1, ENERGY_HEX_MAX
	MOV  [ENERGY_HEX], R1 ; resets the current energy to maximum energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0   ; resets the value in the display in decimal form

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
; meteor_Move: Moves the meteor one line for each press of a certain key
; ----------------------------------------------------------------------------

meteor_Move:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

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
	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; meteor_Reset: Resets the meteor's starting position.
; ----------------------------------------------------------------------------

meteor_Reset:
	PUSH R0

	MOV  R0, BAD_METEOR_GIANT
	MOV  R1, 002CH
	MOV  [R0], R1 ; resets a meteor's X current position to the starting position
	ADD  R0, NEXT_WORD
	MOV  R1, METEOR_START_POS_Y
	MOV  [R0], R1 ; resets a meteor's Y current position to the starting position

	POP  R0
	RET

;=============================================================================
; MISCELLANIOUS: various routines that don't fit a specific category.
;=============================================================================

; ----------------------------------------------------------------------------
; hextodec_Convert: Given any hexadecimal value it converts it into 12 bits,
; where each group of 4 bits represent the a digit of the decimal version.
; - R0 -> hexadecimal converted into decimal in the form of 12 bits
; - R1 -> hexadecimal number to convert
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
; INTERRUPTION HANDLING:
;=============================================================================
