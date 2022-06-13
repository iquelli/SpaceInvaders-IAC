;
;		File: grupo47.asm
;		Authors:
;		        - Gonçalo Bárias (ist1103124), goncalo.barias@tecnico.ulisboa.pt
;		        - Raquel Braunschweig (ist1102624), raquel.braunschweig@tecnico.ulisboa.pt
;		        - Gustavo Diogo (ist199233), gustavomanuel30@tecnico.ulisboa.pt
;		Group: 47
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.
;		Date: 17-06-2022

;=============================================================================
; NUMERIC CONSTANTS:
;=============================================================================

KEYPAD_LIN EQU 0C000H  ; peripheral address of the lines
KEYPAD_COL EQU 0E000H  ; peripheral address of the columns
LIN_MASK   EQU 0008H   ; mask used to sweep through all the lines of the keypad

DISPLAYS                    EQU 0A000H  ; address used to access the displays
ENERGY_MOVEMENT_CONSUMPTION EQU 0FFFBH  ; energy depleted when the rover moves (-5%)
ENERGY_MISSILE_CONSUMPTION  EQU 0FFFBH  ; energy depleted when the rover shoots a missile (-5%)
ENERGY_GOOD_METEOR_INCREASE EQU 000AH   ; energy gained when the rover hits a good meteor (+10%)
ENERGY_INVADER_INCREASE     EQU 0005H   ; energy gained per each invader the rover destroys (+5%)
ENERGY_HEX_MAX              EQU 0064H   ; the maximum energy value in hexadecimal
ENERGY_HEX_MIN              EQU 0000H   ; the minimum energy value in hexadecimal

HEXTODEC_MSD EQU 0064H  ; value used to get the most significant digit from a number in decimal form
HEXTODEC_LSD EQU 000AH  ; value used to get the least significant digit

DEF_LIN           EQU 600AH  ; address of the command to define a line
DEF_COL           EQU 600CH  ; address of the command to define a column
DEF_PIXEL_WRITE   EQU 6012H  ; address of the command to write a pixel
DEF_PIXEL_READ    EQU 6014H  ; address of the command to read a pixel's state
OBTAIN_COLOR      EQU 6010H  ; address of the command to obtain the current color of a pixel
CLEAR_SCREEN      EQU 6002H  ; address of the command to clear the screen
SELECT_BACKGROUND EQU 6042H  ; address of the command to select a background
SELECT_FOREGROUND EQU 6046H  ; address of the command to select a foreground
DELETE_FOREGROUND EQU 6044H  ; address of the command to delete the foreground
SOUND_PLAY        EQU 605AH  ; address of the command to play a sound
VIDEO_PLAY        EQU 605AH  ; address of the command to play a video
VIDEO_CYCLE       EQU 605CH  ; address of the command to play a video on repeat
VIDEO_STOP        EQU 6068H  ; address of the command to make all videos stop
VIDEO_STATE       EQU 6052H  ; address of the command to obtain the state of a video

MAX_LIN                 EQU 0020H   ; the first line we can't paint at
MAX_COL_ROVER           EQU 003BH   ; maximum column the rover can be at
ROVER_START_POS_X       EQU 0020H   ; the starting X position of the rover's top left pixel
ROVER_START_POS_Y       EQU 001CH   ; the starting Y position of the rover's top left pixel
ROVER_DIMENSIONS        EQU 0504H   ; length and height of the rover
ROVER_COLOR             EQU 0F0FFH  ; color used for the rover
ROVER_DELAY             EQU 4000H   ; delay used to limit the speed of the rover
METEOR_START_POS_Y      EQU 0FFFBH  ; the starting Y position of any meteors top left pixel
METEOR_GIANT_DIMENSIONS EQU 0505H   ; length and height of the giant meteor
BAD_METEOR_COLOR        EQU 0FF00H  ; color used for bad meteors
MISSILE_DIMENSIONS      EQU 0101H   ; length and height of the missile
MISSILE_COLOR           EQU 0F0F0H  ; color of the missile
MAX_MISSILE_LINE        EQU 0011H   ; maximum line the missile can go

IN_MENU    EQU 0000H  ; value when the user is in a menu
IN_GAME    EQU 0001H  ; value when the user is in a game
IN_PAUSE   EQU 0002H  ; value when the user pauses the game

TRUE         EQU 0001H  ; true is represented by the value one
FALSE        EQU 0000H  ; false is represented by the value zero
NULL         EQU 0000H  ; value equal to zero
NEXT_WORD    EQU 0002H  ; value that a word occupies at an address
NEXT_BYTE    EQU 0001H  ; value that a byte occupies at an address
VAR_LIST_LEN EQU 0003H  ; the length of the variables list

;=============================================================================
; VARIABLE DECLARATION:
;=============================================================================

PLACE 1000H

GAME_STATE: WORD IN_MENU  ; variable that stores the current game state

KEY_PRESSED:  LOCK NULL  ; value of the key initially pressed on the current loop
KEY_PRESSING: LOCK NULL  ; value of the key that is currently being held down

ENERGY_CHANGE: LOCK NULL            ; the value to increase or decrease the energy of the rover
ENERGY_HEX:    WORD ENERGY_HEX_MAX  ; stores the current energy value of the rover in hexadecimal

MOVE_METEOR:  LOCK FALSE  ; used by an interruption to indicate when to move the meteors
MOVE_MISSILE: LOCK FALSE  ; used by an interruption to indicate when to move the missile
ENERGY_DRAIN: LOCK NULL   ; used by an interruption to indicate the amount of energy to decrease periodically

PIXEL_OVERLAP: WORD FALSE  ; variable used to detect overlap of different color pixels

VAR_LIST:  ; list containing the addresses to all the program variables
	WORD VAR_LIST_LEN
	WORD GAME_STATE
	WORD KEY_PRESSED
	WORD KEY_PRESSING
	WORD MOVE_METEOR
	WORD MOVE_MISSILE
	WORD ENERGY_DRAIN

GAME_MANUAL_CHANGE_LIST:  ; list containing all the game states the user can switch between
	WORD game_Init
	WORD game_PauseHandling
	WORD game_End

;=============================================================================
; IMAGE TABLES:
; - The first two WORD's represents the top left pixel of the image. (X, Y)
; - The third WORD leads to the information of the object.
; - The fourth WORD contains the dimensions of the canvas the image is painted
;   on. (height, length)
; - The fifth WORD contains the color to paint the image.
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

MISSILE:
	WORD NULL, NULL
	WORD MISSILE_PATTERN

MISSILE_PATTERN:
	WORD MISSILE_DIMENSIONS
	WORD MISSILE_COLOR
	WORD 8000H

;=============================================================================
; INTERRUPTION TABLE:
;=============================================================================

inte_Tab:
	WORD inte_MoveMeteor
	WORD inte_MoveMissile
	WORD inte_EnergyDepletion

;=============================================================================
; PROCESSES LIFO'S:
;=============================================================================

	STACK 100H
SP_Main:

	STACK 100H
SP_KeySweeper:

	STACK 100H
SP_MeteorHandling:

	STACK 100H
SP_RoverHandling:

	STACK 100H
SP_MissileHandling:

	STACK 100H
SP_EnergyHandling:

;=============================================================================
; MAIN: The starting point of the program.
;=============================================================================

PLACE 0000H

; ----------------------------------------------------------------------------
; init: Initializes the program and the processes and starts the initial menu.
; ----------------------------------------------------------------------------

init:
	MOV  SP, SP_Main    ; initializes the stack pointer
	MOV  BTE, inte_Tab  ; initializes the interruption table

	CALL game_Menu

	EI0
	EI1
	EI2
	EI

	CALL key_Sweeper
	CALL meteor_Handling
	CALL rover_Handling
	CALL missile_Handling
	CALL energy_Handling

; ----------------------------------------------------------------------------
; main: Starts the main loop of the program.
; ----------------------------------------------------------------------------

main:
	YIELD

;=============================================================================
; GAME STATES: Controls the current state of the game.
;=============================================================================

; ----------------------------------------------------------------------------
; game_Handling: Handles the manual changes in the game states performed by
; the user during the program runtime.
; ----------------------------------------------------------------------------

game_Handling:
	MOV  R0, [KEY_PRESSED]  ; locks the process until a key is pressed

	MOV  R1, 000CH
	SUB  R0, R1     ; gets the key position relative to the C key
	JN   main       ; if the key is before C it does nothing
	CMP  R0, 0002H
	JGT  main       ; if the key is after E it does nothing

	MOV  R1, GAME_MANUAL_CHANGE_LIST
	MOV  R2, [R1 + R0]  ; gets the right routine to call
	CALL R2             ; calls the routine needed for the change in the game state
	JMP  main

; ----------------------------------------------------------------------------
; game_Menu: Resets the information about previous games and shows the
; starting menu video.
; ----------------------------------------------------------------------------

game_Menu:
	PUSH R0

	CALL game_Reset

	MOV  R0, 1
	MOV  [VIDEO_CYCLE], R0  ; plays the starting menu video on a cycle

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Init: Resets all of the game information, including the energy of the
; rover. Initializes the game by playing the correct video and drawing the
; starting object and also enables all interruptions.
; ----------------------------------------------------------------------------

game_Init:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_MENU              ; only starts a new game when it's on a menu
	JNZ  game_Init_Return

	CALL game_Reset
	CALL energy_Reset

	MOV  [VIDEO_STOP], R0         ; stops the previous video that was playing (value of R0 doesn't matter)
	MOV  R0, 2
	MOV  [VIDEO_PLAY], R0         ; plays the game starting video

game_Init_WaitAnimation:
	MOV R0, [VIDEO_STATE]          ; obtains the state of the video

	CMP R0, NULL                   ; checks if the animation has stopped playing
	JNZ wait_AnimationCycle        ; keeps going up until the animation has ended

game_Init_Draw:
	MOV  R0, 0
	MOV  [SELECT_BACKGROUND], R0  ; selects the starting background
	MOV  R0, ROVER
	CALL image_Draw               ; draws the starting rover

	MOV  R0, IN_GAME              ; changes the current game state to in game
	MOV  [GAME_STATE], R0         ; because a new game is about to begin

game_Init_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_PauseHandling: Pauses the game, by putting a pause button on the
; foreground and pausing all interruptions. If the game is paused, then it
; unpauses it by resuming interruptions and removing the pause button.
; ----------------------------------------------------------------------------

game_PauseHandling:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JZ   game_Pause         ; if it's in a game it pauses it
	CMP  R0, IN_PAUSE
	JZ   game_Unpause       ; if it's paused it unpauses the game
	JMP  game_Pause_Return  ; if the program is in any other state it does nothing

game_Pause:
	MOV  R0, 1
	MOV  [SELECT_FOREGROUND], R0  ; puts a pause button on the screen
	MOV  R0, IN_PAUSE             ; changes the game state to paused
	JMP  game_Pause_Return

game_Unpause:
	MOV  R0, 1
	MOV  [DELETE_FOREGROUND], R0  ; deletes the pause button from the screen
	MOV  R0, IN_GAME              ; changes the game state to in game

game_Pause_Return:
	MOV  [GAME_STATE], R0  ; saves the current state or changes the state of the game
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_OverBecauseEnergy: Indicates the video to play when the game is over
; due to the lack of energy in the rover.
; ----------------------------------------------------------------------------

game_OverBecauseEnergy:
	PUSH R0
	MOV  R0, 3  ; plays the game over (energy) video
	JMP  game_Over

; ----------------------------------------------------------------------------
; game_OverBecauseMeteor: Indicates the video to play when the game is over
; due to a meteor crash.
; ----------------------------------------------------------------------------

game_OverBecauseMeteor:
	PUSH R0
	MOV  R0, 4  ; plays the game over (meteor) video
	JMP  game_Over

; ----------------------------------------------------------------------------
; game_End: Indicates the video to play when the user terminates the game
; manually.
; ----------------------------------------------------------------------------

game_End:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_MENU  ; only if the program is in a menu it doesn't end a game
	JZ   game_Over_Return

	MOV  R0, 5        ; plays the ending game video

; ----------------------------------------------------------------------------
; game_Over: Clears the screen and plays of of the game's end screen.
; ----------------------------------------------------------------------------

game_Over:
	CALL game_Reset

	MOV  [VIDEO_CYCLE], R0  ; plays the actual video
	MOV  R0, IN_MENU        ; changes the current game state to in menu
	MOV  [GAME_STATE], R0   ; because the user ended/lost the game

game_Over_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Reset: Resets all of the information of the current game.
; ----------------------------------------------------------------------------

game_Reset:
	CALL var_Reset
	CALL meteor_Reset
	CALL missile_Reset
	CALL rover_Reset
	MOV  [CLEAR_SCREEN], R0 ; clears all the pixels on the screen
	RET

;=============================================================================
; KEY HANDLING: Reads input from a keypad that the program uses to control the
; game.
;=============================================================================

PROCESS SP_KeySweeper

; ----------------------------------------------------------------------------
; key_Sweeper: Swipes the keypad waiting for the user to press a key. When it
; happens it exits with the line and column of the key stored.
; R2 -> line of the key being pressed
; R3 -> column of the key being pressed
; ----------------------------------------------------------------------------

key_Sweeper:
	MOV  R0, KEYPAD_LIN
	MOV  R1, KEYPAD_COL
	MOV  R2, LIN_MASK
	MOV  R4, 000FH

key_Sweeper_Wait:
	WAIT                   ; makes the processor sleep if all the other processes are locked

	MOVB [R0], R2          ; sends the value of the line currently being analysed to the line peripheral
	MOVB R3, [R1]          ; saves the value of the column from the peripheral
	AND  R3, R4            ; obtains only the bits 0-3 from the column peripheral
	JNZ  key_Convert       ; if the key is pressed it continues down the process

	SHR  R2, 1             ; moves onto the next line of the keypad
	JNZ  key_Sweeper_Wait
	MOV  R2, LIN_MASK      ; when one sweep is done it resets the line with
	JMP  key_Sweeper_Wait  ; the line mask and jumps to the beginning

; ----------------------------------------------------------------------------
; key_Convert: Converts the arbitrary column and line values into the
; actual key the user is pressing.
; R5 -> key that is being pressed, now converted into hexadecimal
; ----------------------------------------------------------------------------

key_Convert:
	MOV  R5, 0000H          ; initializes the key counter at 0
	MOV  R6, R2             ; backs up the value of the line into R6

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
	MOV  [KEY_PRESSED], R5  ; indicates the number of the key that is pressed (00H - 0FH)

; ----------------------------------------------------------------------------
; key_CheckChange: Waits until no key is being held down, meanwhile it
; indicates the key that is being held down.
; ----------------------------------------------------------------------------

key_CheckChange:
	YIELD

	MOV  [KEY_PRESSING], R5  ; indicates the number of the key that is being held down (00H - 0FH)

	MOVB [R0], R2            ; looks at the line that was pressed previously
	MOVB R3, [R1]            ; reads the state of key
	AND  R3, R4              ; if the state is 0, then it's no longer being held down

	JNZ  key_CheckChange
	JMP  key_Sweeper

;=============================================================================
; PIXEL SCREEN: Controls what gets pixelated onto the screen.
;=============================================================================

; ----------------------------------------------------------------------------
; image_Draw: Draws an image received as an argument into the pixelscreen.
; It knows the top left coordinate, the dimensions of the image, the image
; pattern and image color in order to paint it.
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

	MOV  R1, [R0]       ; obtains the column of the object
	ADD  R0, NEXT_WORD
	MOV  R2, [R0]       ; obtains the line where the object currently is

	ADD  R0, NEXT_WORD
	MOV  R6, [R0]       ; obtains the address that stores the drawing information
	MOV  R0, R6

	MOVB R3, [R0]       ; obtains the length of the object
	ADD  R3, R1         ; calculates the first column to the right of the object that is free
	ADD  R0, NEXT_BYTE
	MOVB R4, [R0]       ; obtains the height of the object
	ADD  R4, R2         ; calculates the first line below the object that is free

	ADD  R0, NEXT_BYTE
	MOV  R5, [R0]       ; obtains the color of the object

	ADD  R0, NEXT_WORD
	MOV  R8, [R0]       ; obtains the color pattern for the first line of the object

	MOV  R6, R1         ; initializes the column counter
	MOV  R7, R2         ; initializes the line counter
	MOV  R9, MAX_LIN    ; stores the first line outside the bottom of the screen

image_Draw_VerifyBounds:
	CMP  R7, NULL             ; checks if it's trying to paint a pixel outside the top of the screen
	JLT  image_Draw_NextLine
	CMP  R7, R9               ; checks if it's trying to paint a pixel outside the bottom of the screen
	JGE  image_Draw_Return

image_Draw_Loop:
	SHL  R8, 1                ; checks if it needs to color the pixel by using the carry flag
	CALL pixel_Draw
	ADD  R6, 0001H            ; moves onto the next column
	CMP  R6, R3               ; compares the column with the value of column plus length
	JLT  image_Draw_Loop      ; continues to draw up until all columns of the object are done

image_Draw_NextLine:
	ADD  R7, 0001H                ; moves onto the next line
	ADD  R0, NEXT_WORD
	MOV  R8, [R0]                 ; obtains the color pattern for the new line
	MOV  R6, R1                   ; resets the value of the column
	CMP  R7, R4                   ; compares the line with the value of line plus height
	JLT  image_Draw_VerifyBounds  ; continues to draw up until all lines of the object are done

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
; pixel_Draw: Either does nothing if the C flag is 0 or draws a pixel with
; the selected color. Detects if there was an overlap in pixels of different
; colors.
; - R5 -> current color to paint if possible
; - R6 -> current column of the pixel
; - R7 -> current line of the pixel
; - C flag -> 0 it does not paint or erase, 1 it can paint or erase
; ----------------------------------------------------------------------------

pixel_Draw:
	PUSH R1

	JNC  pixel_Draw_Return      ; if the carry is not 1, pixel is not colored

	MOV  [DEF_COL], R6          ; sets the column of the pixel
	MOV  [DEF_LIN], R7          ; sets the line of the pixel

	CMP  R5, NULL
	JZ   pixel_Draw_Paint       ; if we are trying to erase the pixel no overlap happens

	MOV  R1, [OBTAIN_COLOR]     ; gets the color of the current pixel before painting
	CMP  R1, NULL
	JZ   pixel_Draw_Paint       ; if the pixel we are trying to paint is empty no overlap happens

	CMP  R1, R5                 ; if they are the same color no overlap happens
	JZ   pixel_Draw_Paint       ; because we are repainting

	MOV  R2, TRUE
	MOV  [PIXEL_OVERLAP], R2    ; if those conditions don't verify, then a pixel overlap happened

pixel_Draw_Paint:
	MOV  [DEF_PIXEL_WRITE], R5  ; colors the pixel

pixel_Draw_Return:
	POP  R1
	RET

; ----------------------------------------------------------------------------
; image_Erase: Erases an image received as an argument from the pixelscreen.
; It sets the color of the image to NULL, draws it and then resets the color.
; - R0 -> image table to erase
; ----------------------------------------------------------------------------

image_Erase:
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R2, 0004H
	MOV  R1, [R0 + R2]  ; obtains the pattern information of the object

	ADD  R1, NEXT_WORD
	MOV  R2, [R1]       ; backs up the original color into R2

	MOV  R3, NULL
	MOV  [R1], R3       ; sets the color of the image to NULL in order to erase it
	CALL image_Draw     ; actually erases the image
	MOV  [R1], R2       ; resets the color to the original

	POP  R3
	POP  R2
	POP  R1
	RET

;=============================================================================
; ROVER: Deals with the movement of the rover that defends planet X.
;=============================================================================

PROCESS SP_RoverHandling

; ----------------------------------------------------------------------------
; rover_Handling:
; ----------------------------------------------------------------------------

rover_Handling:
	WAIT

	MOV  R1, [KEY_PRESSING]
	CMP  R1, NULL
	JZ   rover_VerifyBounds
	CMP  R1, 0002H
	JZ   rover_VerifyBounds
	JMP  rover_Handling

	MOV  R2, [GAME_STATE]
	CMP  R2, IN_GAME
	JNZ  rover_Handling

; ----------------------------------------------------------------------------
; rover_VerifyBounds:
; ----------------------------------------------------------------------------

rover_VerifyBounds:
	SUB  R1, 0001H
	MOV  R0, ROVER

	MOV  R2, [R0]
	ADD  R2, R1

	JN   rover_Handling
	MOV  R1, MAX_COL_ROVER
	CMP  R2, R1
	JGT  rover_Handling

	MOV  R1, ROVER_DELAY

; ----------------------------------------------------------------------------
; rover_Move:
; ----------------------------------------------------------------------------

rover_Move:
	WAIT

	SUB  R1, 0001H
	JNZ rover_Move

	CALL image_Erase
	MOV  [R0], R2
	CALL image_Draw

	MOV  R1, [PIXEL_OVERLAP]
	CMP  R1, TRUE
	JNZ  rover_Handling

; ----------------------------------------------------------------------------
; rover_CollisionHandling:
; ----------------------------------------------------------------------------

rover_CollisionHandling:

; ----------------------------------------------------------------------------
; rover_GoodCollision:
; ----------------------------------------------------------------------------

rover_GoodCollision:
	CALL image_Erase

	MOV  R0, ROVER
	CALL image_Draw

	MOV  R0, ENERGY_GOOD_METEOR_INCREASE
	MOV  [ENERGY_CHANGE], R0
	MOV  R0, 1
	MOV  [SOUND_PLAY], R0

	JMP  rover_Handling

; ----------------------------------------------------------------------------
; rover_BadCollision:
; ----------------------------------------------------------------------------

rover_BadCollision:
	CALL game_OverBecauseMeteor
	JMP  rover_Handling

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

PROCESS SP_EnergyHandling

; ----------------------------------------------------------------------------
; energy_Handling: It updates the energy and the displays with the new value it
; calculates.
; - R0 -> value (%) to increase/decrease the energy percentage
; ----------------------------------------------------------------------------

energy_Handling:
	WAIT

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JNZ  energy_Handling         ; if there is no elapsed game it doesn't update the energy

	MOV  R0, [ENERGY_CHANGE]     ; gets the value to increase/decrease the energy of the rover
	MOV  R1, [ENERGY_HEX]        ; obtains the current energy
	ADD  R1, R0                  ; adds the current energy with the amount to increase/decrease

	CMP  R1, NULL
	JLE  energy_Handling_MinLim  ; if the energy becomes negative it becomes stuck at 0
	MOV  R2, ENERGY_HEX_MAX      ; obtains the maximum value of energy
	CMP  R1, R2                  ; compares current energy value with maximum energy value
	JGT  energy_Handling_MaxLim  ; when the energy exceeds the limit it also becomes stuck at the maximum

	JMP  energy_Handling_Display

energy_Handling_MaxLim:
	MOV  R1, ENERGY_HEX_MAX      ; makes the value of the energy stuck at the maximum
	JMP  energy_Handling_Display

energy_Handling_MinLim:
	CALL game_OverBecauseEnergy  ; the rover reached the end of it's time
	MOV  R1, ENERGY_HEX_MIN      ; makes the value of the energy stuck at the minimum

energy_Handling_Display:
	MOV  [ENERGY_HEX], R1        ; updates the new value of the energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0          ; updates the value in the displays
	JMP  energy_Handling

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

;=============================================================================
; MISSILE:
;=============================================================================

PROCESS SP_MissileHandling

; ----------------------------------------------------------------------------
; missile_Handling: Verifies if there is an elapsed game and if the number 1
; key was pressed in order to fire a missile.
; ----------------------------------------------------------------------------

missile_Handling:
	WAIT

	MOV  R0, [KEY_PRESSED]
	CMP  R0, 0001H            ; checks if the key currently being pressed is key 1
	JNZ  missile_Handling

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME          ; checks if the game is not paused or at the start/end
	JNZ  missile_Handling

; ----------------------------------------------------------------------------
; missile_InitDraw: Draws the initial the missile above the rover.
; ----------------------------------------------------------------------------

missile_InitDraw:
	MOV  R0, MISSILE
	MOV  R1, ROVER

	MOV  R2, [R1]             ; obtains the current column of the rover
	ADD  R2, 0002H            ; obtains the column the missile will be drawn on
	MOV  [R0], R2             ; uptades the value of the missile's column

	MOV  R3, NEXT_WORD        ; used to obtain the address of the missile's line
	ADD  R1, NEXT_WORD        ; obtains the address of the line of the rover

	MOV  R2, [R1]             ; obtains the current line of the rover
	SUB  R2, 0001H            ; obtains the line the missile will be drawn on
	MOV  [R0 + R3], R2        ; updates the value of the pixel's line

	CALL image_Draw           ; draws the initial missile on the screen
	MOV  R4, 0
	MOV  [SOUND_PLAY], R4     ; plays the shooting sound when a missile is shot
	MOV  R4, ENERGY_MISSILE_CONSUMPTION
	MOV  [ENERGY_CHANGE], R4  ; drains 5% of the energy per missile shot

; ----------------------------------------------------------------------------
; missile_VerifyBounds: Verifies if the missile collided with a meteor or if
; it reached the maximum line it can be at.
; ----------------------------------------------------------------------------

missile_VerifyBounds:
	MOV  R4, [MOVE_MISSILE]

	MOV  R1, [R0 + R3]        ; obtains the line of the missile
	CMP  R1, NULL             ; checks if the missile has collided with a meteor
	JZ   missile_Handling

	CALL image_Erase          ; deletes the missile from the pixelscreen

	SUB  R1, 0001H            ; gets the new line of the missile
	MOV  R2, MAX_MISSILE_LINE
	CMP  R1, R2               ; checks if the missile doesn't surpass a defined line limit
	JLT  missile_Handling

; ----------------------------------------------------------------------------
; missile_Move: Actually moves the meteor one line above it's previous position.
; ----------------------------------------------------------------------------

missile_Move:
	MOV  [R0 + R3], R1        ; updates the missile line after verifying it's safe to do so
	CALL image_Draw           ; draws the missile on the new position

	JMP  missile_VerifyBounds

; ----------------------------------------------------------------------------
; missile_Reset: Resets the missile to it's original state (both coordinates
; at zero) that represents the missile out of the screen.
; ----------------------------------------------------------------------------

missile_Reset:
	PUSH R0
	PUSh R1

	MOV  R0, MISSILE
	MOV  R1, NULL
	MOV  [R0], R1
	ADD  R0, NEXT_WORD
	MOV  R1, NULL
	MOV  [R0], R1

	POP  R1
	POP  R0
	RET

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
	ADD  R1, NEXT_BYTE
	MOVB R2, [R1]        ; obtains the current line of the meteor
	ADD  R2, 0001H       ; obtains the new line

	CALL image_Erase     ; erases the old meteor

	MOV  R3, MAX_LIN
	CMP  R2, R3          ; compares new line with maximum amount of lines
	JGT  meteor_Move_Return

	MOV  R2, [R0]        ; obtains meteor's current position
	ADD  R2, 0001H       ; actually updates the new line after verifying it's safe to do so
	MOV  [R0], R2
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

;=============================================================================
; INTERRUPTION HANDLING:
;=============================================================================

; ----------------------------------------------------------------------------
; inte_MoveMeteor: Interruption that indicates when the meteors should move
; (400 milliseconds).
; ----------------------------------------------------------------------------

inte_MoveMeteor:
	MOV [MOVE_METEOR], R0
	RFE

; ----------------------------------------------------------------------------
; inte_MoveMissile: Interruption that indicates when the missile should move
; (200 milliseconds).
; ----------------------------------------------------------------------------

inte_MoveMissile:
	MOV [MOVE_MISSILE], R0
	RFE

; ----------------------------------------------------------------------------
; inte_EnergyDepletion: Interruption that indicates when the rover should lose
; 5% of it's energy by moving around (3 seconds).
; ----------------------------------------------------------------------------

inte_EnergyDepletion:
	PUSH R0

	MOV  R0, ENERGY_MOVEMENT_CONSUMPTION
	MOV  [ENERGY_CHANGE], R0 ; depleats 5% of the rover's energy every 3 seconds

	POP  R0
	RFE
