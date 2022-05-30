;
;		File: grupo47.asm
;		Authors: Gonçalo Bárias (ist1103124), Gustavo Diogo (ist199233), Raquel Braunschweig (ist1102624)
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.
;

;=================================================================
; NUMERIC CONSTANTS:
;-----------------------------------------------------------------

DISPLAYS   EQU 0A000H
KEYPAD_LIN EQU 0C000H
KEYPAD_COL EQU 0E000H
LIN_MASK   EQU 0010H

ENERGY_MOVEMENT_CONSUMPTION EQU 0FFFBH
ENERGY_MISSILE_CONSUMPTION  EQU 0FFFBH
ENERGY_GOOD_METEOR_INCREASE EQU 000AH
ENERGY_INVADER_INCREASE     EQU 0005H
ENERGY_HEX_MAX              EQU 0064H
ENERGY_HEX_MIN              EQU 0000H

HEXTODEC_MSD EQU 0064H
HEXTODEC_LSD EQU 000AH

TRUE      EQU 0001H
FALSE     EQU 0000H
NULL      EQU 0000H
NEXT_WORD EQU 0002H

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

PLACE 1000H

KEY_PRESSED:  WORD NULL
KEY_PRESSING: WORD NULL
KEY_UPDATE:   WORD FALSE

ENERGY_HEX: WORD ENERGY_HEX_MAX

KEY_LIST:
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
	WORD key_Action_Placeholder
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

;=================================================================
; INTERRUPTION TABLE:
;-----------------------------------------------------------------

;=================================================================
; STACK POINTER INITIALIZATION:
;-----------------------------------------------------------------

pile_init:
	TABLE 100H
SP_start:

;=================================================================
; MAIN: the starting point of the program.
;-----------------------------------------------------------------

PLACE 0000H

init:
	MOV  SP, SP_start
	CALL display_Reset

main:
	CALL key_Handling

	JMP  main

;=================================================================
; GAME STATES:
;-----------------------------------------------------------------

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
	JZ   key_Sweeper_Return

	MOVB [R0], R2
	MOVB R3, [R1]
	MOV  R1, 000FH
	AND  R3, R1
	MOV  R1, KEYPAD_COL
	CMP  R3, NULL
	JZ   key_Sweeper_Wait

key_Sweeper_Return:
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
	JZ   key_Convert_Return
	ADD  R3, 0001H
	JMP  key_Convert_Col

key_Convert_Return:
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

	MOV  R0, KEY_UPDATE
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

	MOV  R1, KEY_UPDATE
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

key_Action_Placeholder:
	RET

;=================================================================
; ROVER:
;-----------------------------------------------------------------

;=================================================================
; ENERGY OF THE ROVER:
;-----------------------------------------------------------------

key_Action_4:
	PUSH R0
	PUSH R1

	MOV  R0, KEY_UPDATE
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

	MOV  R0, KEY_UPDATE
	MOV  R1, [R0]
	CMP  R1, FALSE
	JZ   key_Action_5_Return

	MOV  R0, ENERGY_GOOD_METEOR_INCREASE
	CALL energy_Update

key_Action_5_Return:
	POP  R1
	POP  R0
	RET

display_Reset:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R1, ENERGY_HEX_MAX
	CALL hextodec_Convert
	MOV  R2, DISPLAYS
	MOV  [R2], R0

	POP  R2
	POP  R1
	POP  R0
	RET

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

	JMP  energy_Update_Return

energy_Update_MaxLim:
	MOV  R1, ENERGY_HEX_MAX
	JMP  energy_Update_Return

energy_Update_MinLim:
	MOV  R1, ENERGY_HEX_MIN

energy_Update_Return:
	MOV  [R2], R1

	CALL hextodec_Convert
	MOV  R2, DISPLAYS
	MOV  [R2], R0

	POP  R3
	POP  R2
	POP  R1
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

;=================================================================
; MISSILE:
;-----------------------------------------------------------------

;=================================================================
; METEOR:
;-----------------------------------------------------------------

;=================================================================
; INTERRUPTION HANDLING:
;-----------------------------------------------------------------
