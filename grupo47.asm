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
SELECT_BACKGROUND EQU 6042H ; address of the command to select a background
SELECT_FOREGROUND EQU 6046H ; address of the command to select a foreground
DELETE_FOREGROUND EQU 6044H ; address of the command to delete the foreground
SOUND_PLAY        EQU 605AH ; address of the command to play a sound
VIDEO_PLAY        EQU 605AH ; address of the command to play a video
VIDEO_CYCLE       EQU 605CH ; address of the command to play a video on repeat
VIDEO_STOP        EQU 6066H ; address of the command to make a video stop

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

IN_MENU          EQU 0000H ; value when the user is in the menu
IN_GAME          EQU 0002H ; value when the user is in a game
IN_PAUSE         EQU 0004H ; value when the user pauses the game
PAUSE_RESUME     EQU 0006H ; value when the user unpauses the game
GAME_OVER_ENERGY EQU 0008H ; value when the game ends because of low energy
GAME_OVER_METEOR EQU 000AH ; value when the game ends because of a bad meteor collision
GAME_END         EQU 000CH ; value when the user ends the game
GAME_RESTART     EQU 000EH ; value when the user restarts the game

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

GAME_LOCK:  LOCK IN_MENU ; variable that locks/unlocks the game states for the game handling
GAME_STATE: WORD IN_MENU ; variable that stores the current game state

KEY_PRESSED:  LOCK NULL  ; value of the key initially pressed on the current loop
KEY_PRESSING: LOCK NULL  ; value of the key that is currently being held down

ROVER_DIRECTION: LOCK NULL ; direction the rover is going to move in

SHOOT_MISSILE: LOCK FALSE ; variable that unlocks the routine to shoot a missile

ENERGY_CHANGE: LOCK NULL           ; the value to increase or decrease the energy of the rover
ENERGY_HEX:    WORD ENERGY_HEX_MAX ; stores the current energy value of the rover in hexadecimal

MOVE_METEOR:  LOCK FALSE ; used by an interruption to indicate when to move the meteors
MOVE_MISSILE: LOCK FALSE ; used by an interruption to indicate when to move the missile
ENERGY_DRAIN: LOCK NULL  ; used by an interruption to indicate the amount of energy to decrease periodically

VAR_LIST: ; list containing the addresses to all the program variables
	WORD VAR_LIST_LEN
	WORD GAME_LOCK
	WORD GAME_STATE
	WORD KEY_PRESSED
	WORD KEY_PRESSING
	WORD ROVER_DIRECTION
	WORD SHOOT_MISSILE
	WORD MOVE_METEOR
	WORD MOVE_MISSILE
	WORD ENERGY_DRAIN

GAME_STATE_LIST: ; list containing all the possible game states
	WORD game_Menu
	WORD game_Init
	WORD game_Pause
	WORD game_InitFromPause
	WORD game_OverBecauseEnergy
	WORD game_OverBecauseMeteor
	WORD game_End

KEY_LIST: ; list containing all the key actions of the game
	WORD key_Action_0
	WORD key_Action_1
	WORD key_Action_2
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_PlaceHolder
	WORD key_Action_C
	WORD key_Action_D
	WORD key_Action_E
	WORD key_Action_PlaceHolder

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

main_LIFO:
	STACK 100H
SP_Main:

key_Sweeper_LIFO:
	STACK 100H
SP_KeySweeper:

key_ActionsSingle_LIFO:
	STACK 100H
SP_KeyActionsSingle:

key_ActionsContinuous_LIFO:
	STACK 100H
SP_KeyActionsContinuous:

meteor_Handling_LIFO:
	STACK 100H
SP_MeteorHandling:

rover_Handling_LIFO:
	STACK 100H
SP_RoverHandling:

missile_Handling_LIFO:
	STACK 100H
SP_MissileHandling:

energy_Handling_LIFO:
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
	MOV  SP, SP_Main   ; initializes the stack pointer
	MOV  BTE, inte_Tab ; initializes the interruption table

	CALL game_Menu

	EI0
	EI1
	EI2
	EI

	CALL key_Sweeper
	CALL key_ActionsSingle
	CALL key_ActionsContinuous
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
; game_Handling: Reads from a locked variable the state of a game and when it
; changes it calls the correct routine.
; ----------------------------------------------------------------------------

game_Handling:
	MOV  R0, [GAME_LOCK]     ; locks the process until the game state changes
	MOV  R1, GAME_STATE_LIST
	MOV  R2, [R1 + R0]       ; gets the right routine to call
	CALL R2                  ; calls the routine needed for the change in the game state
	JMP  main                ; waits for another change in the game state change

; ----------------------------------------------------------------------------
; game_Menu: Resets the information about previous games and shows the
; starting menu video.
; ----------------------------------------------------------------------------

game_Menu:
	PUSH R0

	CALL game_Reset

	MOV  R0, 1
	MOV  [VIDEO_CYCLE], R0 ; plays the starting menu video on a cycle

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Init: Initializes the game by playing the correct video and drawing the
; starting object.
; ----------------------------------------------------------------------------

game_Init:
	PUSH R0

	CALL game_Reset
	CALL energy_Reset

	MOV  R0, 1
	MOV  [VIDEO_STOP], R0        ; stops the previous video that was playing
	MOV  R0, 2
	MOV  [VIDEO_PLAY], R0        ; plays the game starting video
	MOV  R0, 0
	MOV  [SELECT_BACKGROUND], R0 ; selects the starting background

	MOV  R0, ROVER
	CALL image_Draw              ; draws the starting rover

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Pause: Pauses the game.
; ----------------------------------------------------------------------------

game_Pause:
	PUSH R0
	DI

	MOV  R0, 1
	MOV  [SELECT_FOREGROUND], R0  ; puts a pause button in the screen

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_InitFromPause: Resumes the game.
; ----------------------------------------------------------------------------

game_InitFromPause:
	PUSH R0

	MOV  R0, 1
	MOV  [DELETE_FOREGROUND], R0  ; deletes the pause button from the screen

	POP  R0

	EI
	RET

; ----------------------------------------------------------------------------
; game_OverBecauseEnergy: Clears the screen and plays a video that indicates
; that the game is over due to the lack of energy of the rover.
; ----------------------------------------------------------------------------

game_OverBecauseEnergy:
	PUSH R0
	DI

	MOV  R0, 3           
	MOV [VIDEO_PLAY], R0        ; plays the game over (energy) video

	POP R0
	RET

; ----------------------------------------------------------------------------
; game_OverBecauseMeteor: Clears the screen and plays a video that indicates
; that the game is over due to a meteor crash.
; ----------------------------------------------------------------------------

game_OverBecauseMeteor:
	PUSH R0
	DI
	
	MOV  R0, 4           
	MOV [VIDEO_PLAY], R0        ; plays the game over (meteor) video

	POP R0
	RET
	

; ----------------------------------------------------------------------------
; game_End: Plays the end screen of the game.
; ----------------------------------------------------------------------------

game_End:
	PUSH R0
	DI
	MOV  R0, 5 ; plays the ending game video
	JMP game_End_PlayVideo

game_End_PlayVideo:
	CALL game_Reset

	MOV  [VIDEO_CYCLE], R0       ; plays the actual video
	MOV  R0, IN_MENU
	MOV  [GAME_STATE], R0

	POP  R0
	RET

; ----------------------------------------------------------------------------
; game_Restart: Plays a video that indicates that the game is restarting
; ----------------------------------------------------------------------------

game_Restart:
	PUSH R0
	
	MOV R0, 6
	MOV [VIDEO_PLAY], R0          ; plays the restart animation
	
	POP R0
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
	WAIT                  ; makes the processor sleep if all the other processes are locked

	MOVB [R0], R2         ; sends the value of the line currently being analysed to the line peripheral
	MOVB R3, [R1]         ; saves the value of the column from the peripheral
	AND  R3, R4           ; obtains only the bits 0-3 from the column peripheral
	JNZ  key_Convert      ; if the key is pressed it continues down the process

	SHR  R2, 1            ; moves onto the next line of the keypad
	JNZ  key_Sweeper_Wait
	MOV  R2, LIN_MASK     ; when one sweep is done it resets the line with
	JMP  key_Sweeper_Wait ; the line mask and jumps to the beginning

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

	MOVB [R0], R2           ; looks at the line that was pressed previously
	MOVB R3, [R1]           ; reads the state of key
	AND  R3, R4             ; if the state is 0, then it's no longer being held down

	MOV  [KEY_PRESSING], R5 ; indicates the number of the key that is being held down (00H - 0FH)

	JNZ  key_CheckChange
	JMP  key_Sweeper

;=============================================================================
; KEY ACTIONS: Executes a command based on the key that is pressed.
;=============================================================================

; ----------------------------------------------------------------------------
; key_ActionsSingle: Executes a single key action per key press, and so it
; does nothing when the key is being held down.
; ----------------------------------------------------------------------------

PROCESS SP_KeyActionsSingle
key_ActionsSingle:
	MOV  R0, [KEY_PRESSED] ; waits for a key
	CALL key_Actions
	JMP  key_ActionsSingle

; ----------------------------------------------------------------------------
; key_ActionsContinuous: Executes a single key action continuously, and so it
; keeps executing it when the key is being held down.
; ----------------------------------------------------------------------------

PROCESS SP_KeyActionsContinuous
key_ActionsContinuous:
	MOV  R0, [KEY_PRESSING] ; waits for a key
	CALL key_Actions
	JMP  key_ActionsContinuous

; ----------------------------------------------------------------------------
; key_Actions: Executes a certain routine depending on the key that is
; currently being held down.
; ----------------------------------------------------------------------------

key_Actions:
	PUSH R0
	PUSH R1
	PUSH R2

	SHL  R0, 1            ; each WORD takes two addresses so it multiplies the key by 2
	MOV  R1, KEY_LIST
	MOV  R2, [R1 + R0]    ; obtains the address of the routine to call
	CALL R2

	POP  R2
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_0: Moves the rover to the left.
; ----------------------------------------------------------------------------

key_Action_0:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JNZ  key_Action_0_Return ; only moves the rover when it's in game

	MOV  R0, -1              ; moves to the left
	MOV  [ROVER_DIRECTION], R0

key_Action_0_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_1: Unlocks the variable that shoots a missile.
; ----------------------------------------------------------------------------

key_Action_1:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JNZ  key_Action_0_Return ; only shoot a missile when it's in game

	MOV  [SHOOT_MISSILE], R0 ; shoots a missile (value of R0 doesn't matter)

key_Action_1_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_2: Moves the rover to the right.
; ----------------------------------------------------------------------------

key_Action_2:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JNZ  key_Action_0_Return ; only moves the rover when it's in game

	MOV  R0, 1               ; moves to the right
	MOV  [ROVER_DIRECTION], R0

key_Action_2_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_C: Starts a new game.
; ----------------------------------------------------------------------------

key_Action_C:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_MENU
	JNZ  key_Action_C_Return ; only starts a new game when it's on a menu

	MOV  R0, IN_GAME
	MOV  [GAME_LOCK], R0
	MOV  [GAME_STATE], R0
	CALL game_Init

key_Action_C_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_D: Pauses or unpauses the current game.
; ----------------------------------------------------------------------------

key_Action_D:
	PUSH R0
	PUSH R1

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_GAME
	JZ   key_Action_D_Pause   ; if it's in a game it pauses it
	CMP  R0, IN_PAUSE
	JZ   key_Action_D_Unpause ; if it's paused it unpauses the game
	JMP  key_Action_D_Return  ; if the program is in any other state it does nothing

key_Action_D_Pause:
	MOV  R0, IN_PAUSE
	MOV  [GAME_LOCK], R0
	MOV  [GAME_STATE], R0
	CALL game_InitFromPause
	JMP  key_Action_D_Return

key_Action_D_Unpause:
	MOV  R1, PAUSE_RESUME
	MOV  R0, IN_GAME
	MOV  [GAME_LOCK], R1
	MOV  [GAME_STATE], R0

key_Action_D_Return:
	POP  R1
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_E: Ends the current game.
; ----------------------------------------------------------------------------

key_Action_E:
	PUSH R0

	MOV  R0, [GAME_STATE]
	CMP  R0, IN_MENU
	JZ   key_Action_E_Return ; only if it's in a menu it doesn't end a game

	MOV  R0, GAME_END
	MOV  [GAME_LOCK], R0
	MOV  [GAME_STATE], R0
	CALL game_End

key_Action_E_Return:
	POP  R0
	RET

; ----------------------------------------------------------------------------
; key_Action_Placeholder: Routine that blocks certain keys from doing anything.
; ----------------------------------------------------------------------------

key_Action_PlaceHolder:
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

	JNC  pixel_Draw_Paint      ; if the carry is not 1, pixel is not colored

	MOV  [DEF_COL], R6         ; sets the column of the pixel
	MOV  [DEF_LIN], R7         ; sets the line of the pixel

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
	MOV  R2, [R0]               ; obtains the current column of the rover
	ADD  R2, R1                 ; updates column value

	JN   rover_Move_Return  ; if it tries to go left but it's on column 0, it exits
	MOV  R1, MAX_COL_ROVER  ; obtains the maximum column the rover can be at
	CMP  R2, R1             ; compares updated column value with maximum column value
	JGT  rover_Move_Return  ; if it tries to go right but it can't fit in the screen, it exits

	CALL delay_Drawing           ; controls the speed at which the rover moves
	CALL image_Draw              ; it erases the current rover

	MOV  [R0], R2                ; updates the current position of the rover
	CALL image_Draw              ; paints new rover on the pixelscreen

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

PROCESS SP_EnergyHandling
energy_Handling:
	MOV  R0, [ENERGY_CHANGE] ; gets the value to increase/decrease the energy of the rover
	MOV  R1, [ENERGY_HEX]    ; obtains the current energy
	ADD  R1, R0              ; adds the current energy with the amount to increase/decrease

	JN   energy_Handling_MinLim ; if the energy becomes negative it becomes stuck at 0
	MOV  R2, ENERGY_HEX_MAX     ; obtains the maximum value of energy
	CMP  R1, R2                 ; compares current energy value with maximum energy value
	JGT  energy_Handling_MaxLim ; when the energy exceeds the limit it also becomes stuck at the maximum

	JMP  energy_Handling_Display

energy_Handling_MaxLim:
	MOV  R1, ENERGY_HEX_MAX   ; makes the value of the energy stuck at the maximum
	JMP  energy_Handling_Display

energy_Handling_MinLim:
	MOV  R2, GAME_OVER_ENERGY ; the rover reached the end of it's time
	MOV  [GAME_LOCK], R2
	MOV  [GAME_STATE], R2
	MOV  R1, ENERGY_HEX_MIN   ; makes the value of the energy stuck at the minimum

energy_Handling_Display:
	MOV  [ENERGY_HEX], R1     ; updates the new value of the energy

	CALL hextodec_Convert
	MOV  [DISPLAYS], R0       ; updates the value in the displays
	JMP  energy_Handling

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
	ADD  R1, NEXT_BYTE
	MOVB R2, [R1]        ; obtains the current line of the meteor
	ADD  R2, 0001H       ; obtains the new line

	CALL image_Draw      ; erases the old meteor

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
