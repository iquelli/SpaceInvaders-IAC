;
;		File: grupo47.asm
;		Authors: Gonçalo Bárias (ist1103124), Gustavo Diogo (ist199233), Raquel Braunschweig (ist1102624)
;		Course: Computer Science and Engineering (Alameda) - IST
;		Description: Space Invaders game in PEPE Assembly.
;

;=================================================================
; NUMERIC CONSTANTS
;-----------------------------------------------------------------

DISPLAYS   EQU 0A000H
KEYPAD_LIN EQU 0C000H
KEYPAD_COL EQU 0E000H
LIN_MASK   EQU 0010H

TRUE       EQU 0001H
FALSE      EQU 0000H
NULL       EQU 0000H

;=================================================================
; VARIABLE DECLARATION
;-----------------------------------------------------------------

KEY_PRESSED:  WORD NULL
KEY_PRESSING: WORD NULL

;=================================================================
; THE CODE
;-----------------------------------------------------------------

key_Handling:
	CALL key_Sweeper
	CALL key_Convert
	CALL key_Update
	CALL key_Actions
	RET

key_Sweeper:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

    MOV R0, KEYPAD_LIN
    MOV R1, KEYPAD_COL
    MOV R2, LIN_MASK
	MOV R3, NULL

key_Sweeper_Wait:
	ROR   R2,  1
	MOVB [R0], R2
	MOVB  R3, [R1]
	MOV   R1,  000FH
	AND   R3,  R1
	CMP   R3,  NULL
	MOV   R1,  KEYPAD_COL
	JZ    key_Sweeper_Wait

key_Sweeper_Save:
	SHL  R3,  4
	OR   R3,  R2
	MOV  R0,  KEY_PRESSED
	MOV [R0], R3

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

key_Convert:

key_Convert_Lin:

key_Convert_Col:

Key_Convert_Return:
	RET

key_CheckUpdate:

key_CheckUpdate_Return:
	RET

key_Actions:
	RET
