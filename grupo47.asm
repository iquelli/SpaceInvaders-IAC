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

;=================================================================
; STACK POINTER INITIALIZATION:
;-----------------------------------------------------------------

PLACE 1000H

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

KEY_PRESSED:   WORD NULL
KEY_CONVERTED: WORD NULL
KEY_PRESSING:  WORD FALSE

;=================================================================
; MAIN: the starting point of the program.
;-----------------------------------------------------------------

PLACE 0000H

main:
	JMP main

;=================================================================
; KEY HANDLING:
;-----------------------------------------------------------------

key_Handling:
	CALL key_Sweeper
	CALL key_Convert
	CALL key_CheckUpdate
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
	MOV   R1,  KEYPAD_COL
	CMP   R3,  NULL
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
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R2,  KEY_PRESSED
	MOVB R0, [R2]
	SHR  R2,  0004H
	MOVB R1, [R2]

	MOV  R2,  0000H
	MOV  R3,  0000H

key_Convert_Lin:
	SHR  R0,  1
	JZ   key_Convert_Col
	ADD  R2,  0001H
	JMP  key_Convert_Lin

key_Convert_Col:
	SHR  R1,  1
	JZ   key_Convert_Return
	ADD  R3,  0001H
	JMP  key_Convert_Col

key_Convert_Return:
	MOV  R1,  0004H
	MUL  R2,  R1
	ADD  R2,  R3
	MOV  R1,  KEY_CONVERTED
	MOV [R1], R2

	POP  R3
	POP  R2
	POP  R1
	POP  R0
	RET

key_CheckUpdate:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV  R2,  KEY_PRESSED
	MOVB R0, [R2]
	MOV  R2,  KEYPAD_LIN
	MOV  R3,  KEYPAD_COL

key_CheckUpdate_Return:
	CALL key_Actions
	MOVB [R2], R0
	MOVB  R1, [R3]
	MOV   R3,  000FH
	AND   R1,  R3
	CMP   R1,  NULL
	MOV   R3,  KEY_PRESSING
	MOV  [R3], TRUE
	MOV   R3,  KEYPAD_COL
	JNZ   key_CheckUpdate_Return

	MOV   R3,  KEY_PRESSING
	MOV  [R3], FALSE

	POP   R3
	POP   R2
	POP   R1
	POP   R0
	RET

key_Actions:
	PUSH R0
	PUSH R1

	MOV  R0,  KEY_PRESSING
	MOV  R1,  KEY_CONVERTED

key_Actions_Repeatable:
	CMP [R1], 0000H
	JZ   key_Action_0
	CMP [R1], 0002H
	JZ   key_Action_2
	CMP [R1], 0001H
	JZ   key_Action_1

	CMP [R0], TRUE
	JZ   key_Actions_Return

key_Actions_Unrepeatable:
	CMP [R1], 000CH
	JZ   key_Action_C
	CMP [R1], 000DH
	JZ   key_Action_D
	CMP [R1], 000EH
	JZ   key_Action_E

	JMP  key_Actions_Return

key_Action_0:
	JMP key_Actions_Return

key_Action_2:
	JMP key_Actions_Return

key_Action_1:
	JMP key_Actions_Return

key_Action_C:
	JMP key_Actions_Return

key_Action_D:
	JMP key_Actions_Return

key_Action_E:
	JMP key_Actions_Return

key_Actions_Return:
	POP R1
	POP R0
	RET
