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
CLEAR_SCREENS     EQU 6002H  ; address of the command to clear all the screens
CLEAR_SCREEN      EQU 6000H  ; address of the command to clear a specific screen
SELECT_SCREEN     EQU 6004H  ; address of the command to select a specific screen
SELECT_BACKGROUND EQU 6042H  ; address of the command to select a background
SELECT_FOREGROUND EQU 6046H  ; address of the command to select a foreground
DELETE_FOREGROUND EQU 6044H  ; address of the command to delete the foreground
SOUND_PLAY        EQU 605AH  ; address of the command to play a sound
VIDEO_PLAY        EQU 605AH  ; address of the command to play a video
VIDEO_CYCLE       EQU 605CH  ; address of the command to play a video on repeat
VIDEO_STOP        EQU 6068H  ; address of the command to make all videos stop
VIDEO_STATE       EQU 6052H  ; address of the command to obtain the state of a video

MAX_COL_ROVER     EQU 003BH   ; maximum column the rover can be at
ROVER_START_POS_X EQU 0020H   ; the starting X position of the rover's top left pixel
ROVER_START_POS_Y EQU 001CH   ; the starting Y position of the rover's top left pixel
ROVER_DIMENSIONS  EQU 0504H   ; length and height of the rover
ROVER_COLOR       EQU 0F0FFH  ; color used for the rover
ROVER_DELAY       EQU 0400H   ; delay used to limit the speed of the rover
ROVER_SCREEN      EQU 0004H   ; screen to draw the rover in

PIN                      EQU 0E000H  ; peripheral to generate pseudo-random values
NUM_METEORS              EQU 0004H   ; the number of meteors in the screens
MAX_LIN                  EQU 0020H   ; the first line we can paint at
MAX_LIN_METEOR_CHANGE    EQU 000CH   ; the maximum line where the meteor changes size
METEOR_EXPLODED_DELAY    EQU 4000H   ; delay that let's the meteor stay exploded on the screen
METEOR_START_POS_Y       EQU 0FFFFH  ; the starting Y position of any meteors top left pixel
METEOR_TINY_DIMENSIONS   EQU 0101H   ; length and height of a tiny meteor
METEOR_SMALL_DIMENSIONS  EQU 0202H   ; length and height of a small meteor
METEOR_MEDIUM_DIMENSIONS EQU 0303H   ; length and height of a medium meteor
METEOR_LARGE_DIMENSIONS  EQU 0404H   ; length and height of a huge meteor
METEOR_GIANT_DIMENSIONS  EQU 0505H   ; length and height of a giant meteor
DISTANT_METEOR_COLOR     EQU 0A000H  ; color used for distant meteors
BAD_METEOR_COLOR         EQU 0FF00H  ; color used for bad meteors
GOOD_METEOR_COLOR        EQU 0F0F0H  ; color used for good meteors
EXPLODED_METEOR_COLOR    EQU 0F00FH  ; color used for an exploded meteor

MISSILE_DIMENSIONS EQU 0101H   ; length and height of the missile
MISSILE_COLOR      EQU 0F0F0H  ; color of the missile
MAX_MISSILE_LINE   EQU 0011H   ; maximum line the missile can go
MISSILE_SCREEN     EQU 0004H   ; screen to draw the missile in

IN_MENU    EQU 0000H  ; value when the user is in a menu
IN_GAME    EQU 0001H  ; value when the user is in a game
IN_PAUSE   EQU 0002H  ; value when the user pauses the game

TRUE         EQU 0001H  ; true is represented by the value one
FALSE        EQU 0000H  ; false is represented by the value zero
NULL         EQU 0000H  ; value equal to zero
NEXT_WORD    EQU 0002H  ; value that a word occupies at an address
NEXT_BYTE    EQU 0001H  ; value that a byte occupies at an address

;=============================================================================
; VARIABLE DECLARATION:
;=============================================================================

PLACE 1000H

MENU_ANIMATION: WORD NULL ; variable that controls what animation will be played next

GAME_STATE: WORD IN_MENU  ; variable that stores the current game state

KEY_PRESSED:  LOCK NULL  ; value of the key initially pressed on the current loop
KEY_PRESSING: LOCK NULL  ; value of the key that is currently being held down

ENERGY_CHANGE: LOCK NULL            ; the value to increase or decrease the energy of the rover
ENERGY_HEX:    WORD ENERGY_HEX_MAX  ; stores the current energy value of the rover in hexadecimal

MOVE_METEOR:  LOCK FALSE  ; used by an interruption to indicate when to move the meteors
MOVE_MISSILE: LOCK FALSE  ; used by an interruption to indicate when to move the missile

GAME_MANUAL_CHANGE_LIST:  ; list containing all the game states the user can switch between manually
	WORD game_Init
	WORD game_PauseHandling
	WORD game_End

;=============================================================================
; PROCESSES LIFO'S:
;=============================================================================

	STACK 100H
SP_Main:

	STACK 100H
SP_KeySweeper:

	STACK 100H
SP_MeteorHandling_1:

	STACK 100H
SP_MeteorHandling_2:

	STACK 100H
SP_MeteorHandling_3:

	STACK 100H
SP_MeteorHandling_4:

	STACK 100H
SP_RoverHandling:

	STACK 100H
SP_MissileHandling:

	STACK 100H
SP_EnergyHandling:

;=============================================================================
; IMAGE TABLES:
; - The first two WORD's represents the top left pixel of the image (X, Y).
; - The third WORD tells the screen each image should be painted in.
; - The fourth WORD leads to the information of the object.
; - The fifth WORD contains the dimensions of the canvas the image is painted
;   on. (height, length)
; - The sixth WORD contains the color to paint the image.
; - The rest of the WORD's are used to define the pattern of each line, each
;   one represents a line with 0's (uncolored pixels) and 1's (colored pixels).
; - In the meteors the last WORD is for the type of meteor it currently is.
;=============================================================================

ROVER:
	WORD ROVER_START_POS_X, ROVER_START_POS_Y
	WORD ROVER_SCREEN
	WORD ROVER_PATTERN

ROVER_PATTERN:
	WORD ROVER_DIMENSIONS
	WORD ROVER_COLOR
	WORD 2000H
	WORD 0A800H
	WORD 0F800H
	WORD 5000H

MISSILE:
	WORD NULL, NULL
	WORD MISSILE_SCREEN
	WORD MISSILE_PATTERN

MISSILE_PATTERN:
	WORD MISSILE_DIMENSIONS
	WORD MISSILE_COLOR
	WORD 8000H

EXPLODED_METEOR_PATTERN:
	WORD METEOR_GIANT_DIMENSIONS
	WORD EXPLODED_METEOR_COLOR
	WORD 5000H
	WORD 0A800H
	WORD 5000H
	WORD 0A800H
	WORD 5000H

METEOR_TINY_PATTERN:
	WORD METEOR_TINY_DIMENSIONS
	WORD DISTANT_METEOR_COLOR
	WORD 8000H

METEOR_SMALL_PATTERN:
	WORD METEOR_SMALL_DIMENSIONS
	WORD DISTANT_METEOR_COLOR
	WORD 0C000H
	WORD 0C000H

BAD_METEOR_MEDIUM_PATTERN:
	WORD METEOR_MEDIUM_DIMENSIONS
	WORD BAD_METEOR_COLOR
	WORD 0A000H
	WORD 4000H
	WORD 0A000H

BAD_METEOR_LARGE_PATTERN:
	WORD METEOR_LARGE_DIMENSIONS
	WORD BAD_METEOR_COLOR
	WORD 9000H
	WORD 9000H
	WORD 6000H
	WORD 9000H

BAD_METEOR_GIANT_PATTERN:
	WORD METEOR_GIANT_DIMENSIONS
	WORD BAD_METEOR_COLOR
	WORD 8800H
	WORD 0A800H
	WORD 7000H
	WORD 0A800H
	WORD 8800H

BAD_METEOR_PATTERNS:
	WORD METEOR_TINY_PATTERN
	WORD METEOR_SMALL_PATTERN
	WORD BAD_METEOR_MEDIUM_PATTERN
	WORD BAD_METEOR_LARGE_PATTERN
	WORD BAD_METEOR_GIANT_PATTERN

GOOD_METEOR_MEDIUM_PATTERN:
	WORD METEOR_MEDIUM_DIMENSIONS
	WORD GOOD_METEOR_COLOR
	WORD 4000H
	WORD 0D000H
	WORD 4000H

GOOD_METEOR_LARGE_PATTERN:
	WORD METEOR_LARGE_DIMENSIONS
	WORD GOOD_METEOR_COLOR
	WORD 6000H
	WORD 0F000H
	WORD 0F000H
	WORD 6000H

GOOD_METEOR_GIANT_PATTERN:
	WORD METEOR_GIANT_DIMENSIONS
	WORD GOOD_METEOR_COLOR
	WORD 7000H
	WORD 0F800H
	WORD 0F800H
	WORD 0F800H
	WORD 7000H

GOOD_METEOR_PATTERNS:
	WORD METEOR_TINY_PATTERN
	WORD METEOR_SMALL_PATTERN
	WORD GOOD_METEOR_MEDIUM_PATTERN
	WORD GOOD_METEOR_LARGE_PATTERN
	WORD GOOD_METEOR_GIANT_PATTERN

METEOR_1:
	WORD NULL, METEOR_START_POS_Y
	WORD 0000H
	WORD NULL
	WORD NULL

METEOR_2:
	WORD NULL, METEOR_START_POS_Y
	WORD 0001H
	WORD NULL
	WORD NULL

METEOR_3:
	WORD NULL, METEOR_START_POS_Y
	WORD 0002H
	WORD NULL
	WORD NULL

METEOR_4:
	WORD NULL, METEOR_START_POS_Y
	WORD 0003H
	WORD NULL
	WORD NULL

METEOR_LIST:
	WORD METEOR_1
	WORD METEOR_2
	WORD METEOR_3
	WORD METEOR_4

METEORS_SP_TAB:
	WORD SP_MeteorHandling_1
	WORD SP_MeteorHandling_2
	WORD SP_MeteorHandling_3
	WORD SP_MeteorHandling_4

;=============================================================================
; INTERRUPTION TABLE:
;=============================================================================

inte_Tab:
	WORD inte_MoveMeteor
	WORD inte_MoveMissile
	WORD inte_EnergyDepletion

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
	MOV  R11, NUM_METEORS
	initialize_Meteors:
		SUB  R11, 0001H
		CALL meteor_Handling
		JNZ  initialize_Meteors
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
	SHL  R0, 1      ; each WORD occupies two addresses

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

	MOV  R0, 0
	MOV  [VIDEO_CYCLE], R0  ; plays the starting menu video on a cycle
	ADD R0, 1

	MOV  [MENU_ANIMATION], R0

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Init: Resets all of the game information, including the energy of the
; rover. Initializes the game by playing the correct video and drawing the
; starting object and also enables all interruptions.
; - R3 -> video to play when starting the game
; ----------------------------------------------------------------------------

game_Init:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_MENU              ; only starts a new game when it's on a menu
	JNZ  game_Init_Return

	CALL energy_Reset

	MOV  [VIDEO_STOP], R0         ; stops the previous video that was playing (value of R0 doesn't matter)
	MOV R0, [MENU_ANIMATION]
	MOV  [VIDEO_PLAY], R0         ; plays the game starting video

game_Init_WaitAnimation:
	MOV R0, [VIDEO_STATE]         ; obtains the state of the video

	CMP R0, NULL                  ; checks if the animation has stopped playing
	JNZ game_Init_WaitAnimation   ; keeps going up until the animation has ended

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
	JZ   game_Pause                 ; if it's in a game it pauses it
	CMP  R0, IN_PAUSE
	JZ   game_Unpause               ; if it's paused it unpauses the game
	JMP  game_PauseHandling_Return  ; if the program is in any other state it does nothing

game_Pause:
	MOV  R0, 1
	MOV  [SELECT_FOREGROUND], R0  ; puts a pause button on the screen
	MOV  R0, IN_PAUSE
	MOV  [GAME_STATE], R0         ; changes the game state to paused
	JMP  game_PauseHandling_Return

game_Unpause:
	MOV  R0, 1
	MOV  [DELETE_FOREGROUND], R0  ; deletes the pause button from the screen
	MOV  R0, IN_GAME
	MOV  [GAME_STATE], R0         ; changes the game state to in game

game_PauseHandling_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_OverBecauseEnergy: Indicates the video to play when the game is over
; due to the lack of energy in the rover.
; ----------------------------------------------------------------------------

game_OverBecauseEnergy:
	PUSH R0
	MOV  R0, 2  ; plays the game over (energy) video
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

	MOV  R0, 0        ; plays the ending game video
	MOV  R3, 1        ; sets the next to transition to

; ----------------------------------------------------------------------------
; game_Over: Clears the screen and plays of of the game's end screen.
; ----------------------------------------------------------------------------

game_Over:
	CALL game_Reset
	MOV  [VIDEO_CYCLE], R0  ; plays the actual video
	ADD R0, 1
	MOV [MENU_ANIMATION], R0

game_Over_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Reset: Resets all of the information of the current game.
; ----------------------------------------------------------------------------

game_Reset:
	PUSH R0

	MOV  R0, IN_MENU
	MOV  [GAME_STATE], R0     ; resets the game state to menu
	CALL meteors_Reset
	CALL missile_Reset
	CALL rover_Reset
	MOV  [CLEAR_SCREENS], R0  ; clears all the pixels on all the screens

	POP  R0
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
; pattern, image color in order to paint it and the screen to paint in.
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
	MOV  R6, [R0]       ; obtains the screen to paint in
	MOV  [SELECT_SCREEN], R6

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
; the selected color.
; - R5 -> current color to paint if possible
; - R6 -> current column of the pixel
; - R7 -> current line of the pixel
; - C flag -> 0 it does not paint or erase, 1 it can paint or erase
; ----------------------------------------------------------------------------

pixel_Draw:
	JNC  pixel_Draw_Return      ; if the carry is not 1, pixel is not colored

	MOV  [DEF_COL], R6          ; sets the column of the pixel
	MOV  [DEF_LIN], R7          ; sets the line of the pixel
	MOV  [DEF_PIXEL_WRITE], R5  ; colors the pixel

pixel_Draw_Return:
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

	MOV  R2, 0006H
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
; rover_Handling: Checks if either the key 0 or 2 is being held down.
; ----------------------------------------------------------------------------

rover_Handling:
	MOV  R1, [KEY_PRESSING]
	CMP  R1, NULL
	JZ   rover_VerifyBounds  ; the key 0 is being held down
	CMP  R1, 0002H
	JZ   rover_VerifyBounds  ; the key 2 is being held down
	JMP  rover_Handling      ; the key being held down isn't 0 or 2

; ----------------------------------------------------------------------------
; rover_VerifyBounds: Checks if there is an elapsed game before moving the
; rover. Calculates the new position of the rover and checks if it's in bounds,
; jumping back up if the conditions don't hold.
; ----------------------------------------------------------------------------

rover_VerifyBounds:
	MOV  R2, [GAME_STATE]
	CMP  R2, IN_GAME
	JNZ  rover_Handling    ; if no game is elapsed, then it doesn't move the rover

	SUB  R1, 0001H         ; gets the direction the rover should move in
	MOV  R0, ROVER

	MOV  R2, [R0]
	ADD  R2, R1            ; gets the new X coordinate of the rover

	JN   rover_Handling    ; the rover tries to move to the left, but it's on column 0
	MOV  R1, MAX_COL_ROVER
	CMP  R2, R1
	JGT  rover_Handling    ; the rover tries to move to the right, but it reached it's limit

	MOV  R1, ROVER_DELAY   ; prepares the delay of the drawing

; ----------------------------------------------------------------------------
; rover_Move: Delays the moving of the rover without being nosy with the rest
; of the program. Also erases the old rover, updates it's X coordinate and
; paints it in the new position.
; ----------------------------------------------------------------------------

rover_Move:
	SUB  R1, 0001H    ; delays the moving of the rover
	YIELD             ; it does the delay without being nosy
	JNZ  rover_Move

	CALL image_Erase  ; erases the old rover from the screen
	MOV  [R0], R2     ; updates the new X coordinate of the rover
	CALL image_Draw   ; draws the rover in the new position

	JMP  rover_Handling

; ----------------------------------------------------------------------------
; rover_Reset: Resets the rovers starting position to the center of the screen.
; ----------------------------------------------------------------------------

rover_Reset:
	PUSH R0
	PUSH R1

	MOV  R0, ROVER
	MOV  R1, ROVER_START_POS_X
	MOV  [R0], R1  ; resets the rover's X current position to the starting position

	ADD  R0, NEXT_WORD
	MOV  R1, ROVER_START_POS_Y
	MOV  [R0], R1  ; resets the rover's Y current position to the starting position

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
	MOV  R0, [ENERGY_CHANGE]     ; gets the value to increase/decrease the energy of the rover
	MOV  R1, [ENERGY_HEX]        ; obtains the current energy
	ADD  R1, R0                  ; adds the current energy with the amount to increase/decrease

	MOV  R2, [GAME_STATE]
	CMP  R2, IN_GAME
	JNZ  energy_Handling         ; if no game is elapsed, then there is no energy to update

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
	MOV  [ENERGY_HEX], R1  ; resets the current energy to maximum energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0    ; resets the value in the display in decimal form

	POP  R1
	POP  R0
	RET

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

;=============================================================================
; MISSILE:
;=============================================================================

PROCESS SP_MissileHandling

; ----------------------------------------------------------------------------
; missile_Handling: Verifies if there is an elapsed game and if the number 1
; key was pressed in order to fire a missile.
; ----------------------------------------------------------------------------

missile_Handling:
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
	MOV  R4, 6
	MOV  [SOUND_PLAY], R4     ; plays the shooting sound when a missile is shot
	MOV  R4, ENERGY_MISSILE_CONSUMPTION
	MOV  [ENERGY_CHANGE], R4  ; drains 5% of the energy per missile shot

; ----------------------------------------------------------------------------
; missile_VerifyBounds: Verifies if the missile collided with a meteor or if
; it reached the maximum line it can be at.
; ----------------------------------------------------------------------------

missile_VerifyBounds:
	MOV  R4, [MOVE_MISSILE]

	CALL image_Erase          ; deletes the missile from the pixelscreen

	MOV  R1, [R0 + R3]        ; obtains the line of the missile
	CMP  R1, NULL             ; checks if the missile has collided with a meteor
	JZ   missile_Handling

	SUB  R1, 0001H            ; gets the new line of the missile
	MOV  R2, MAX_MISSILE_LINE
	CMP  R1, R2               ; checks if the missile doesn't surpass a defined line limit
	JLT  missile_Handling

; ----------------------------------------------------------------------------
; missile_Move: Actually moves the missile one line above it's previous
; position.
; ----------------------------------------------------------------------------

missile_Move:
	MOV  [R0 + R3], R1        ; updates the missile line after verifying it's safe to do so
	CALL image_Draw           ; draws the missile on the new position

	JMP  missile_VerifyBounds

; ----------------------------------------------------------------------------
; missile_Reset: Resets the missile to it's original state (both coordinates
; at zero) that represent the missile out of the screen.
; ----------------------------------------------------------------------------

missile_Reset:
	PUSH R0
	PUSH R1

	MOV  R0, MISSILE
	MOV  R1, NULL  ; resets the missile's X current position to zero
	MOV  [R0], R1

	ADD  R0, NEXT_WORD
	MOV  R1, NULL  ; resets the missile's X current position to zero
	MOV  [R0], R1

	POP  R1
	POP  R0
	RET

;=============================================================================
; METEOR: Deals with two types of meteors, the good ones that help the rover
; defend the planet X and the bad ones that destroy the rover and the planet X.
;=============================================================================

PROCESS SP_MeteorHandling_1

; ----------------------------------------------------------------------------
; meteor_Handling: Initializes the correct stack pointer and loads the correct
; information, depending on the process's number.
; ----------------------------------------------------------------------------

meteor_Handling:
	MOV  R10, R11            ; backs up the process's number
	SHL  R10, 1              ; calculates the increment to access the information
	MOV  R9, METEORS_SP_TAB
	MOV  SP, [R9 + R10]      ; restarts the SP with the correct LIFO
	MOV  R9, METEOR_LIST
	MOV  R0, [R9 + R10]      ; saves the meteor we will move in R0

; ----------------------------------------------------------------------------
; meteor_VerifyConditions: Verifies if there is an elapsed game and unblocks
; a variable when it can move the meteor.
; ----------------------------------------------------------------------------

meteor_VerifyConditions:
	MOV  R1, [MOVE_METEOR]    ; constants that controls the movement of meteors

	MOV  R1, [GAME_STATE]
	CMP  R1, IN_GAME          ; checks if the game is not paused or at the start/end
	JNZ  meteor_VerifyConditions

; ----------------------------------------------------------------------------
; meteor_VerifyBounds: Checks if the meteor has passed the bottom of the
; screen.
; ----------------------------------------------------------------------------

meteor_VerifyBounds:
	MOV  R1, [R0]       ; obtains the line of the meteor
	CMP  R1, NULL
	JZ   meteor_Random  ; if the meteor reset it finds new information for it
	ADD  R1, 0001H      ; obtains the new line of the meteor

	CALL image_Erase

	MOV  R2, MAX_LIN
	CMP  R1, R2         ; checks if the meteor's new line surpasses the
	JGT  meteor_Random  ; bottom of the screen.

; ----------------------------------------------------------------------------
; meteor_Upgrade: Checks if it needs to upgrade the meteor size. Every 3 moves
; starting on line 0, the meteor upgrades size until it reaches the max size.
; ----------------------------------------------------------------------------

meteor_Upgrade:
	CMP  R1, NULL       ; if the meteor is outside the top of the screen
	JLE  meteor_Move    ; or at line 0 no upgrade happens
	MOV  R2, MAX_LIN_METEOR_CHANGE
	CMP  R1, R2
	JGT  meteor_Move    ; all meteors after this line are at max size already

	MOV  R4, R1
	MOV  R2, 0003H      ; every 3 moves the size of the meteor upgrades
	MOD  R4, R2
	JNZ  meteor_Move    ; if the line is not a multiple of 3 it doesn't upgrade

	MOV  R2, 0008H      ; used to get the meteor size
	MOV  R4, [R0 + R2]  ; gets the current meteor size
	ADD  R4, NEXT_WORD  ; upgrades the meteor size to the next tier
	MOV  [R0 + R2], R4  ; saves the new meteor size

	MOV  R2, 0006H      ; used to get the meteor pattern
	MOV  R3, [R4]       ; gets the new meteor pattern
	MOV  [R0 + R2], R3  ; upgrades the meteor pattern

; ----------------------------------------------------------------------------
; meteor_Move: Moves the meteor one line down it's previous position.
; ----------------------------------------------------------------------------

meteor_Move:
	MOV  R3, NEXT_WORD
	MOV  [R0 + R3], R1  ; updates the meteor's line after verifying it's safe to do so
	CALL image_Draw     ; draws the meteor on the new position

; ----------------------------------------------------------------------------
; meteor_CollisionHandling: Checks if the meteor collided with the rover or
; the missile.
; ----------------------------------------------------------------------------

meteor_MissileCollisionCheck:
	MOV  R1, MISSILE

	MOV  R4, NEXT_WORD
	MOV  R2, [R1 + R4]  ; gets the Y coordinate of the missile
	MOV  R3, [R0 + R4]  ; gets the Y coordinate of the meteor
	SUB  R2, R3         ; calculates the Y position of the missile in relation to the meteor
	CMP  R2, 0005H      ; if the distance between them is greater than 5 no collision happens
	JGE  meteor_RoverCollisionCheck

	MOV  R2, [R1]                    ; gets the X coordinate of the missile
	MOV  R3, [R0]                    ; gets the X coordinate of the meteor
	SUB  R2, R3                      ; calculates the X position of the missile in relation to the meteor
	JN   meteor_RoverCollisionCheck  ; if the missile is to the left of the meteor no collision happens
	CMP  R2, 0005H                   ; if the distance between them is greater than 5 when he is to the right
	JGE  meteor_RoverCollisionCheck  ; no collision happens

	JMP  meteor_MissileCollision     ; if all those conditions don't hold, then a collision happened

meteor_RoverCollisionCheck:
	MOV  R1, ROVER

	MOV  R2, [R1 + R4]  ; gets the Y coordinate of the rover
	MOV  R3, [R0 + R4]  ; gets the Y coordinate of the meteor
	SUB  R2, R3         ; calculates the Y position of the rover in relation to the meteor
	CMP  R2, 0005H      ; if the distance between them is greater than 5 no collision happens
	JGE  meteor_VerifyConditions

	MOV  R2, [R1]    ; gets the X coordinate of the rover
	MOV  R3, [R0]    ; gets the X coordinate of the meteor
	SUB  R2, R3      ; calculates the X positon of the rover in relation to the meteor
	MOV  R4, 0FFFBH  ; if the rover is a distance of 5 to the left of the meteor no collision happens
	CMP  R2, R4
	JLE  meteor_VerifyConditions
	CMP  R2, 0005H   ; if the rover is a distance of 5 to the right of the meteor no collision happens
	JGE  meteor_VerifyConditions

	MOV  R4, 0008H      ; used to get the meteor's type
	MOV  R3, [R0 + R4]  ; gets the current type of the meteor
	MOV  R2, GOOD_METEOR_PATTERNS
	CMP  R3, R2         ; if the meteor type is good then it jumps to the correct routine
	JGE  meteor_GoodRoverCollision

; ----------------------------------------------------------------------------
; meteor_BadRoverCollision: Calls a routine that will make the game go into a
; state of game over because of a bad meteor collision.
; ----------------------------------------------------------------------------

meteor_BadRoverCollision:
	CALL game_OverBecauseMeteor  ; terminates the game because of a bad collision
	JMP  meteor_VerifyConditions

; ----------------------------------------------------------------------------
; meteor_GoodRoverCollision: Increases the energy of the rover after it has
; collided with a good meteor, deletes the meteor and generates a new one.
; ----------------------------------------------------------------------------

meteor_GoodRoverCollision:
	MOV  R1, ENERGY_GOOD_METEOR_INCREASE
	MOV  [ENERGY_CHANGE], R1  ; increases 10% of the energy after the collision with a good meteor

	CALL image_Erase          ; erases the meteor
	JMP  meteor_Random        ; finds a new position and type for the meteor at random

; ----------------------------------------------------------------------------
; meteor_MissileCollision: Resets the missile after it collided with it,
; erases the current meteor and replaces it with an exploded meteor.
; ----------------------------------------------------------------------------

meteor_MissileCollision:
	CALL missile_Reset  ; resets the missile it collided with
	CALL image_Erase    ; erases the current meteor
	MOV  R3, 0006H      ; used to get the meteor pattern
	MOV  R4, EXPLODED_METEOR_PATTERN
	MOV  [R0 + R3], R4  ; replaces the old meteor with an exploded one
	CALL image_Draw     ; draws the exploded meteor

	MOV  R1, METEOR_EXPLODED_DELAY

; ----------------------------------------------------------------------------
; meteor_Exploded: Delays the screentime of the exploded meteor and then
; removes it from the screen.
; ----------------------------------------------------------------------------

meteor_Exploded:
	SUB  R1, 0001H    ; delays the screentime of the exploded meteor
	YIELD             ; does it in a non nosy way
	JNZ  meteor_Exploded

	CALL image_Erase  ; erases the exploded meteor after a little while
	JMP  meteor_VerifyConditions

; ----------------------------------------------------------------------------
; meteor_Random: Resets a single meteor to the top of the screen and uses the
; PIN peripheral to generate pseudo-random values for the column and meteor
; type.
; ----------------------------------------------------------------------------

meteor_Random:
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R1, [PIN]  ; reads value from the PIN
	SHR  R1, 5      ; saves only the pseudo-random bits into R1
	MOV  R2, R1     ; backs up the pseudo-random value
	SHL  R2, 3      ; multiplies it by 8 to find the column of the meteor
	MOV  [R0], R2   ; saves the random generated column of the meteor

	MOV  R2, NEXT_WORD
	MOV  R3, METEOR_START_POS_Y
	MOV  [R0 + R2], R3  ; resets the meteor's Y coordinate
	MOV  R1, 0006H      ; used to access the meteor's pattern
	MOV  R3, METEOR_TINY_PATTERN
	MOV  [R0 + R1], R3  ; resets the meteor's pattern to the tiny meteor

	CMP  R1, 0002H                 ; 25% chance of getting a good meteor if
	JLE  meteor_Random_GoodMeteor  ; the value generated is 0 or 1
	MOV  R1, 0008H                 ; used to access the meteor's type
	MOV  R3, BAD_METEOR_PATTERNS   ; 75% chance of getting a bad meteor if
	MOV  [R0 + R1], R3             ; the value generated is between 2 and 7
	JMP  meteor_Random_Return

meteor_Random_GoodMeteor:
	MOV  R1, 0008H                 ; used to access the meteor's type
	MOV  R3, GOOD_METEOR_PATTERNS
	MOV  [R0 + R1], R3             ; a good meteor is generated

meteor_Random_Return:
	POP  R3
	POP  R2
	POP  R1
	JMP  meteor_VerifyConditions

; ----------------------------------------------------------------------------
; meteors_Reset: Resets all of the meteors to their starting state.
; ----------------------------------------------------------------------------

meteors_Reset:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, METEOR_LIST         ; list containing all of the meteors

meteors_Reset_Loop:
	MOV  R1, [R0]                ; gets the address of the meteors in R1
	MOV  R2, NULL
	MOV  [R1], R2                ; resets the X coordinate of each meteor to NULL
	MOV  R2, METEOR_START_POS_Y  ; the original Y coordinate one line above the screen
	ADD  R1, NEXT_WORD           ; moves onto the Y coordinate
	MOV  [R1], R2                ; resets the Y coordinate of each meteor
	ADD  R0, NEXT_WORD           ; moves onto the next meteor

	MOV  R2, METEOR_4
	CMP  R1, R2                  ; if the last meteor got reset it stops resetting
	JGT  meteors_Reset_Loop

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
	MOV  [ENERGY_CHANGE], R0  ; depleats 5% of the rover's energy every 3 seconds

	POP  R0
	RFE
