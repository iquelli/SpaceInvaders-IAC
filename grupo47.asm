;
;		File: grupo47.asm
;		Authors: Gonçalo Bárias (ist1103124), Gustavo Diogo (ist199233), Raquel Braunschweig (ist1102624)
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.
;

;=================================================================
; NUMERIC CONSTANTS:
;-----------------------------------------------------------------

KEYPAD_LIN EQU 0C000H
KEYPAD_COL EQU 0E000H
LIN_MASK   EQU 0010H

DISPLAYS                    EQU 0A000H
ENERGY_MOVEMENT_CONSUMPTION EQU 0FFFBH
ENERGY_MISSILE_CONSUMPTION  EQU 0FFFBH
ENERGY_GOOD_METEOR_INCREASE EQU 000AH
ENERGY_INVADER_INCREASE     EQU 0005H
ENERGY_HEX_MAX              EQU 0064H
ENERGY_HEX_MIN              EQU 0000H

HEXTODEC_MSD EQU 0064H
HEXTODEC_LSD EQU 000AH

DEF_LIN           EQU 600AH  ; address of the command to define a line
DEF_COL           EQU 600CH  ; address of the command to define a collumn
DEF_PIXEL_WRITE   EQU 6012H  ; address of the command to write a pixel
DEF_PIXEL_READ    EQU 6014H  ; address of the command to read a pixel's state
CLEAR_SCREEN      EQU 6002H  ; address of the command to clear the screen
SELECT_BACKGROUND EQU 6042H  ; address of the command to select a backround
SOUND_PLAY        EQU 6048H  ; address of the command to play the sound

MAX_LIN                 EQU 001FH ;
MAX_LIN_METEOR          EQU 001BH ;
MIN_COL_ROVER           EQU 0000H ; minimum collumn where the rover can be at
MAX_COL_ROVER           EQU 003BH ; maximum collumn the rover can be at
DELAY                   EQU 4000H ; delay to limit the speed of the rover
ROVER_START_POSITION    EQU 201CH ; the start position of the rover
ROVER_DIMENSIONS        EQU 0504H ; length and height of the rover
ROVER_COLOR             EQU 0F0FFH ; color of the rover
METEOR_START_POSITION   EQU 2C05H ; the start position of the meteor
METEOR_GIANT_DIMENSIONS EQU 0505H ; length and height of the bad giant meteor
BAD_METEOR_GIANT_COLOR  EQU 0FF00H ; color of the bad giant meteor

TRUE         EQU 0001H      ; value equal to one
FALSE        EQU 0000H      ; value equal to zero
NULL         EQU 0000H      ; value equal to zero
NEXT_WORD    EQU 0002H      ; value that a word occupies at an address
VAR_LIST_END EQU 100EH

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

PLACE 1000H

KEY_PRESSED:  WORD NULL
KEY_PRESSING: WORD NULL
KEY_CHANGE:   WORD FALSE

ENERGY_HEX: WORD ENERGY_HEX_MAX

VAR_LIST:
	WORD KEY_PRESSED
	WORD KEY_PRESSING
	WORD KEY_CHANGE
	WORD VAR_LIST_END

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
;-----------------------------------------------------------------

ROVER:
	WORD ROVER_START_POSITION ; rover's starting position
	WORD ROVER_DIMENSIONS     ; rover's height and length
	WORD ROVER_COLOR          ; rover's coler
	WORD 2000H                ; rover's color scheme of the first line (counting from the top)
	WORD 0A800H               ; rover's color scheme of the second line
	WORD 0F800H               ; rover's color scheme of the third line
	WORD 5000H                ; rover's color scheme of the fourth line

BAD_METEOR_GIANT:
	WORD METEOR_START_POSITION   ; meteor's starting position
	WORD METEOR_GIANT_DIMENSIONS ; meteor's height and length
	WORD BAD_METEOR_GIANT_COLOR  ; meteor's color
	WORD 8800H                   ; meteor's color scheme of the first line (counting from the top)
	WORD 0A800H                  ; meteor's color scheme of the second line
	WORD 7000H                   ; meteor's color scheme of the third line
	WORD 0A800H                  ; meteor's color scheme of the fourth line
	WORD 8800H                   ; meteor's color scheme of the fifth line

;=================================================================
; INTERRUPTION TABLE:
;-----------------------------------------------------------------

;=================================================================
; STACK POINTER INITIALIZATION:
;-----------------------------------------------------------------

pile_Init:
	TABLE 100H
SP_Start:

;=================================================================
; MAIN: the starting point of the program.
;-----------------------------------------------------------------

PLACE 0000H

init:
	MOV  SP, SP_Start
	CALL display_Reset
	CALL game_Init

main:
	CALL key_Handling

	JMP  main

;=================================================================
; GAME STATES:
;-----------------------------------------------------------------

game_Init:
	PUSH R0
	PUSH R1

	CALL game_Reset
	MOV  R0, 0
	MOV  R1, SELECT_BACKGROUND
	MOV  [R1], R0

	MOV  R0, BAD_METEOR_GIANT
	CALL image_Draw
	MOV  R0, ROVER
	CALL image_Draw

	POP  R1
	POP  R0
	RET

game_Reset:
	PUSH R1

	CALL var_Reset
	CALL meteor_Reset
	CALL rover_Reset
	MOV  R1, CLEAR_SCREEN
	MOV  [R1], R0

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
    MOV  R1, KEYPAD_COL
    MOV  R2, LIN_MASK
	MOV  R3, NULL

key_Sweeper_Wait:
	SHR  R2, 1
	JZ   key_Sweeper_Save

	MOVB [R0], R2
	MOVB R3, [R1]
	MOV  R1, 000FH
	AND  R3, R1
	MOV  R1, KEYPAD_COL
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
	PUSH R3

	MOV  R2, KEY_PRESSING
	MOVB R1, [R2]
	ADD  R2, 0001H
	MOVB R0, [R2]

	MOV  R2, 0000H
	MOV  R3, 0000H

	CMP  R0, NULL
	JNZ  key_Convert_Lin
	MOV  R0, 0010H

key_Convert_Lin:
	SHR  R0, 1
	JZ   key_Convert_Col
	ADD  R2, 0001H
	JMP  key_Convert_Lin

key_Convert_Col:
	SHR  R1, 1
	JZ   key_Convert_Save
	ADD  R3, 0001H
	JMP  key_Convert_Col

key_Convert_Save:
	MOV  R1, 0004H
	MUL  R2, R1
	ADD  R2, R3
	MOV  R1, KEY_PRESSING
	MOV  [R1], R2

	POP  R3
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

key_Action_0:
	PUSH R1

	MOV  R1, -1
	CALL rover_Move

	POP  R1
	RET

key_Action_2:
	PUSH R1

	MOV  R1, 1
	CALL rover_Move

	POP  R1
	RET

key_Action_Placeholder:
	RET

key_Action_3:
	PUSH R0
	PUSH R1

	MOV  R0, KEY_CHANGE
	MOV  R1, [R0]
	CMP  R1, FALSE
	JZ   key_Action_3_Return

	CALL meteor_Move

key_Action_3_Return:
	POP  R1
	POP  R0
	RET

key_Action_4:
	PUSH R0
	PUSH R1

	MOV  R0, KEY_CHANGE
	MOV  R1, [R0]
	CMP  R1, FALSE
	JZ   key_Action_4_Return

	MOV  R0, ENERGY_MOVEMENT_CONSUMPTION
	CALL energy_Update

key_Action_4_Return:
	POP  R1
	POP  R0
	RET

key_Action_5:
	PUSH R0
	PUSH R1

	MOV  R0, KEY_CHANGE
	MOV  R1, [R0]
	CMP  R1, FALSE
	JZ   key_Action_5_Return

	MOV  R0, ENERGY_GOOD_METEOR_INCREASE
	CALL energy_Update

key_Action_5_Return:
	POP  R1
	POP  R0
	RET

;=================================================================
; PIXEL SCREEN:
;-----------------------------------------------------------------

image_Draw:
	PUSH R1            ; collumn where the object currently is
	PUSH R2            ; line where the object currently is
	PUSH R3            ; length of the object plus collumn
	PUSH R4            ; height of the object plus line
	PUSH R5            ; color of the object
	PUSH R6            ; line of the pixel
	PUSH R7            ; collumn of the pixel
	PUSH R8            ; color pattern of the object

	MOVB R1, [R0]      ; obtains the collumn of the object
	ADD  R0, 0001H     ; obtains the address of the line of the object
	MOVB R2, [R0]      ; obtains the line of the object
	ADD  R0, 0001H     ; obtains the address of the length of the object

	MOVB R3, [R0]      ; obtains the length of the object
	ADD  R3, R1        ; adds the length of the object plus the collumn
	ADD  R0, 0001H     ; obtains the address of the height of the object
	MOVB R4, [R0]      ; obtains the height of the object
	ADD  R4, R2        ; adds the height of the object with the line
	ADD  R0, 0001H     ; obtains the address of the color of the object

	MOV  R5, [R0]      ; obtains the color of the object
	ADD  R0, NEXT_WORD ; obtains the address of the color pattern of the object

	MOV  R6, R1        ; copies the collumn of the pixel
	MOV  R7, R2        ; copies the line of the pixel
	MOV  R8, [R0]      ; obtains the color pattern of first line the object


image_Draw_Loop:
	SHL  R8, 1         ; obtains the carry
	CALL pixel_Draw
	ADD  R6, 0001H     ; moves on to the next collumn
	CMP  R6, R3        ; compares the collumn with the value of collumn plus length
	JLT  image_Draw_Loop ; continues to draw up until all collumns of the object are done

	ADD  R7, 0001H     ; moves on to the next line
	ADD  R0, NEXT_WORD ; obtains the address of the next line's color pattern
	MOV  R8, [R0]      ; obtains the line's color pattern
	MOV  R6, R1        ; resets the value of the collumn
	CMP  R7, R4        ; compares the line with the value of collumn plus length
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
	PUSH R0             ; address of the collumn of the pixel
	PUSH R1		    ; address of the line of the pixel

	JNC  pixel_Draw_Return ; if the carry is not 1, pixel is not colored

	MOV  R0, DEF_COL    ; obtains the address of the collumn of the pixel
	MOV  [R0], R6       ; collumn of the pixel
	MOV  R0, DEF_LIN    ; obtains the address of the line of the pixel
	MOV  [R0], R7       ; line of the pixel
	MOV  R0, DEF_PIXEL_READ ; address of the state of the pixel

	MOV  R1, [R0]	    ; state of the pixel
	CMP  R1, NULL	    ; checks if it's not colored
	MOV  R0, DEF_PIXEL_WRITE ; address to color the pixel
	JNZ  pixel_Erase    ; if pixel is already colored, deletes it

	pixel_Paint:
	MOV  [R0], R5       ; colors the pixel
	JMP  pixel_Draw_Return

pixel_Erase:
	MOV  R1, NULL       ; makes color value equal to null
	MOV  [R0], R1       ; deletes pixel

pixel_Draw_Return:
	POP  R1
	POP  R0
	RET

;=================================================================
; ROVER:
;-----------------------------------------------------------------

rover_Move:
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R0, ROVER
	MOVB R2, [R0]
	ADD  R2, R1

	JN   rover_Draw_Return
	MOV  R3, MAX_COL_ROVER
	CMP  R2, R3
	JGT  rover_Draw_Return

	CALL image_Draw

	SHL  R2, 8
	MOV  R0, ROVER
	MOV  R1, [R0]
	MOV  R3, 00FFH
	AND  R1, R3
	OR   R1, R2
	MOV  [R0], R1
	CALL image_Draw

rover_Draw_Return:
	POP  R3
	POP  R2
	POP  R1
	RET

rover_Reset:
	PUSH R0
	PUSH R1

	MOV  R1, ROVER_START_POSITION
	MOV  R0, ROVER
	MOV  [R0], R1

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

	MOV  R2, ENERGY_HEX
	MOV  R1, [R2]
	ADD  R1, R0

	MOV  R3, ENERGY_HEX_MAX
	CMP  R1, R3
	JGE  energy_Update_MaxLim

	MOV  R3, ENERGY_HEX_MIN
	CMP  R1, R3
	JLE  energy_Update_MinLim

	JMP  energy_Update_Display

energy_Update_MaxLim:
	MOV  R1, ENERGY_HEX_MAX
	JMP  energy_Update_Display

energy_Update_MinLim:
	MOV  R1, ENERGY_HEX_MIN

energy_Update_Display:
	MOV  [R2], R1

	CALL hextodec_Convert
	MOV  R2, DISPLAYS
	MOV  [R2], R0

	POP  R3
	POP  R2
	POP  R1
	RET

;=================================================================
; MISSILE:
;-----------------------------------------------------------------

;=================================================================
; METEOR:
;-----------------------------------------------------------------

meteor_Move:
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R0, BAD_METEOR_GIANT
	ADD  R0, 1
	MOVB R2, [R0]
	SUB  R0, 1
	ADD  R2, 1

	MOV  R3, MAX_LIN_METEOR
	CMP  R2, R3
	JGT  meteor_Move_Return

	CALL image_Draw
	MOV  R0, BAD_METEOR_GIANT
	MOV  R1, [R0]
	MOV  R3, 0FF00H
	AND  R1, R3
	OR   R1, R2
	MOV  [R0], R1

	CALL image_Draw
	MOV  R1, SOUND_PLAY
	MOV  R2, 0
	MOV  [R1], R2

meteor_Move_Return:
	POP  R3
	POP  R2
	POP  R1
	RET

meteor_Reset:
	PUSH R0
	PUSH R1

	MOV  R1, METEOR_START_POSITION
	MOV  R0, BAD_METEOR_GIANT
	MOV  [R0], R1
	MOV  R1, METEOR_GIANT_DIMENSIONS
	ADD  R0, NEXT_WORD
	MOV  [R0], R1

	POP  R1
	POP  R0
	RET

;=================================================================
; MISCELLANIOUS:
;-----------------------------------------------------------------

display_Reset:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R2, ENERGY_HEX
	MOV  R1, ENERGY_HEX_MAX
	MOV  [R2], R1

	CALL hextodec_Convert
	MOV  R2, DISPLAYS
	MOV  [R2], R0

	POP  R2
	POP  R1
	POP  R0
	RET

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

	MOV  R1, VAR_LIST

var_Reset_Loop:
	MOV  R2, 0
	MOV  R0, [R1]
	MOV  [R0], R2

	ADD  R1, NEXT_WORD
	MOV  R0, [R1]
	MOV  R2, VAR_LIST_END
	CMP  R0, R2
	JNZ  var_Reset_Loop

	POP  R2
	POP  R1
	POP  R0
	RET

delay_Drawing:
	PUSH R0
	MOV  R0, DELAY

delay_Drawing_Cycle:
	SUB  R0, 1
	JNZ  delay_Drawing_Cycle

	POP  R0
	RET

;=================================================================
; INTERRUPTION HANDLING:
;-----------------------------------------------------------------
