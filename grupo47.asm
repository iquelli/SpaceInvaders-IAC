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

DEF_LIN           EQU 600AH  ; endereço do comando para definir a linha
DEF_COL           EQU 600CH  ; endereço do comando para definir a coluna
DEF_PIXEL_WRITE   EQU 6012H  ; endereço do comando para escrever um pixel
DEF_PIXEL_READ    EQU 6014H
CLEAR_SCREEN      EQU 6002H
SELECT_BACKGROUND EQU 6042H

MAX_LIN                 EQU 001FH
MAX_LIN_METEOR          EQU 001BH
MIN_COL_ROVER           EQU 0000H
MAX_COL_ROVER           EQU 003BH
DELAY                   EQU 0FFFFH
ROVER_START_POSITION    EQU 201CH
ROVER_DIMENSIONS        EQU 0504H
ROVER_COLOR             EQU 0F0FFH
METEOR_START_POSITION   EQU 2C05H
METEOR_GIANT_DIMENSIONS EQU 0505H
BAD_METEOR_GIANT_COLOR  EQU 0FF00H

SOUND_CHANGE EQU 6048H

TRUE         EQU 0001H
FALSE        EQU 0000H
NULL         EQU 0000H
NEXT_WORD    EQU 0002H
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
	WORD BAD_METEOR_GIANT_COLOR
	WORD 8800H
	WORD 0A800H
	WORD 7000H
	WORD 0A800H
	WORD 8800H

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

	CALL game_Reset
	MOV  R0, 0
	MOV  [SELECT_BACKGROUND], R0

	MOV  R0, BAD_METEOR_GIANT
	CALL image_Draw
	MOV  R0, ROVER
	CALL image_Draw

	POP  R0
	RET

game_Reset:
	CALL var_Reset
	CALL meteor_Reset
	CALL rover_Reset
	MOV  [CLEAR_SCREEN], R0
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
	PUSH R1 ; X coordinate
	PUSH R2 ; Y coordinate
	PUSH R3 ; length
	PUSH R4 ; height
	PUSH R5 ; color to paint
	PUSH R6
	PUSH R7
	PUSH R8

	MOVB R1, [R0]
	ADD  R0, 0001H
	MOVB R2, [R0]
	ADD  R0, 0001H

	MOVB R3, [R0]
	ADD  R3, R1
	ADD  R0, 0001H
	MOVB R4, [R0]
	ADD  R4, R2
	ADD  R0, 0001H

	MOV  R5, [R0]
	ADD  R0, NEXT_WORD

	MOV  R6, R1
	MOV  R7, R2
	MOV  R8, [R0]

image_Draw_Loop:
	SHL  R8, 1
	CALL pixel_Draw
	ADD  R6, 0001H
	CMP  R6, R3
	JLT  image_Draw_Loop

	ADD  R7, 0001H
	ADD  R0, NEXT_WORD
	MOV  R8, [R0]
	MOV  R6, R1
	CMP  R7, R4
	JLT  image_Draw_Loop

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

	JNC  pixel_Draw_Return

	MOV  R0, DEF_COL
	MOV  [R0], R6
	MOV  R0, DEF_LIN
	MOV  [R0], R7
	MOV  R0, DEF_PIXEL_READ

	MOV  R1, [R0]
	CMP  R1, NULL
	MOV  R0, DEF_PIXEL_WRITE
	JNZ  pixel_Erase

pixel_Paint:
	MOV  [R0], R5
	JMP  pixel_Draw_Return

pixel_Erase:
	MOV  R1, NULL
	MOV  [R0], R1

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

	SHL  R2, 8
	CALL image_Draw
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
	ADD  R2, 1

	MOV  R3, MAX_LIN_METEOR
	CMP  R2, R3
	JGT  meteor_Draw_Return

	SUB  R0, 1
	CALL image_Draw
	MOV  R0, BAD_METEOR_GIANT
	MOV  R1, [R0]
	MOV  R3, 0FF00H
	AND  R1, R3
	OR   R1, R2
	MOV  [R0], R1

	CALL image_Draw
	MOV  R1, SOUND_CHANGE
	MOV  R2, 0
	MOV  [R1], R2

meteor_Draw_Return:
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
