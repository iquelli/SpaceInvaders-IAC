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

TRUE       EQU 0001H
FALSE      EQU 0000H
NULL       EQU 0000H
NEXT_WORD  EQU 0002H

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

PLACE 1000H

KEY_PRESSED:   WORD NULL
KEY_PRESSING:  WORD NULL
KEY_UPDATE:    WORD FALSE

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

;
;
;
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
	ROR  R2, 1
	MOVB [R0], R2
	MOVB R3, [R1]
	MOV  R1, 000FH
	AND  R3, R1
	MOV  R1, KEYPAD_COL
	CMP  R3, NULL
	JZ   key_Sweeper_Wait

key_Sweeper_Save:
	SHL  R3, 4
	OR   R3, R2
	MOV  R0, KEY_PRESSING
	MOV  [R0], R3

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

;
;
;
key_Convert:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R2, KEY_PRESSING
	MOV  R3, [R2]
	MOV  R0, 000FH
	AND  R0, R3
	MOV  R1, 00F0H
	AND  R1, R3
	SHR  R1, 4

	MOV  R2, 0000H
	MOV  R3, 0000H

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

;
;
;
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

;
;
;
key_Actions:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV  R0, FALSE
	MOV  R1, KEY_UPDATE
	MOV  R2, [R1]
	CMP  R2, R0
	JZ key_Actions_Return

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

;=================================================================
; ROVER:
;-----------------------------------------------------------------

;=================================================================
; ENERGY OF THE ROVER:
;-----------------------------------------------------------------

;=================================================================
; MISSILE:
;-----------------------------------------------------------------

;=================================================================
; METEOR:
;-----------------------------------------------------------------

;=================================================================
; INTERRUPTION HANDLING:
;-----------------------------------------------------------------
