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
DEF_PIXEL         EQU 6012H  ; endereço do comando para escrever um pixel
DELETE_WARNING    EQU 6040H
CLEAR_SCREEN      EQU 6002H
SELECT_BACKGROUND EQU 6042H
MIN_LIN           EQU 0
MIN_COL           EQU 0
MAX_LIN           EQU 31     ; line of the rover
MAX_COL           EQU 63     ; collum of the rover

TRUE      EQU 0001H
FALSE     EQU 0000H
NULL      EQU 0000H
NEXT_WORD EQU 0002H
LIST_END  EQU 0FFFFH

;=================================================================
; VARIABLE DECLARATION:
;-----------------------------------------------------------------

PLACE 1000H

KEY_PRESSED:  WORD NULL
KEY_PRESSING: WORD NULL
KEY_UPDATE:   WORD FALSE

ENERGY_HEX: WORD ENERGY_HEX_MAX

VAR_LIST:
	WORD KEY_PRESSED
	WORD KEY_PRESSING
	WORD KEY_UPDATE
	WORD LIST_END

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

ROVER:
	WORD 1C20H
	WORD 0504H
	WORD 0F0FFH
	WORD 20H
	WORD A8H
	WORD F8H
	WORD 50H

BAD_METEOR_GIANT:
	WORD 2C05H
	WORD 0505H
	WORD 0FF00H
	WORD 88H
	WORD A8H
	WORD 70H
	WORD A8H
	WORD 88H

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
	MOV  [DELETE_WARNING], R0
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

key_Action_Placeholder:
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

	MOVB R2, [R0]
	ADD  R0, 0001H
	MOVB R1, [R0]
	ADD  R0, 0001H

	MOVB R3, [R0]
	ADD  R0, 0001H
	ADD  R3, R1
	MOVB R4, [R0]
	ADD  R0, 0001H
	ADD  R4, R2

	MOV  R5, [R0]
	ADD  R0, NEXT_WORD

	MOV  R6, R1
	MOV  R7, R2

image_Draw_Cyclic:
	SHL  R8, 1
	JC   pixel_Draw
	ADD  R6, 0001H
	CMP  R6, R3
	JLT  image_Draw_Cyclic

	ADD  R7, 0001H
	MOV  R6, R1
	ADD  R0, NEXT_WORD
	MOV  R8, [R0]
	CMP  R7, R4
	JLT  image_Draw_Cyclic

image_Draw_Return:
	POP  R8
	POP  R7
	POP  R6
	POP  R5
	POP  R4
	POP  R3
	POP  R2
	POP  R1

pixel_Draw:


;=================================================================
; ROVER:
;-----------------------------------------------------------------

draw_Rover:
	MOV R4, DEF_BONECO      ; obtains the adress of the line of the rover
	MOV R1, [R4]            ; obtains the line where the rover is
	ADD R4, 2		; obtains the address of the collum
	MOV R2, [R4]		; obtains the collum of the rover
	ADD R4, 2		; obtains the address of the color of the pixel
   	MOV R3, [R4]	        ; obtains the color of the pixel
   	CALL updates_Values
	CALL collum135
	RET

updates_Values:
	MOV R7, R1              ; saves the line
   	MOV R5, R2              ; saves the collum
	MOV R6, 3		; number of collums to draw firstly
	MOV R8, 2               ; number of pixels to draw per collum
	RET

collum135:
	SUB R7, 1
	MOV  [DEF_LIN], R7	; selects the line
	MOV  [DEF_COL], R5	; selects the collum
	MOV  [DEF_PIXEL], R3	; alters the color of the pixel in the selected line and collum
   	SUB R8, 1		; condition to see if it has already altered the color of the two pixels
   	JNZ  collum135          ; continues until the collum is fully collored
   	MOV R7, R1		; resets the line
   	MOV R8, 2               ; saves the number of pixels to draw per collum
   	ADD R5, 2               ; goes on to the next collum
   	SUB R6, 1               ; updates the number of collums to draw
   	JNZ collum135		; when it's zero all of the collums 1,3 and 5 are already complete
   	CALL updates_Values     ; updates the values of R7 and R5 so they match the line and the collum
	ADD R5, 1                ; updates the collum to collum 2
	SUB R6, 1               ; number of collums to draw is now 2 instead of 3
	CALL collum24
	RET

collum24:
	MOV  [DEF_LIN], R7	; selects the line
	MOV  [DEF_COL], R5	; selects the collum
	MOV  [DEF_PIXEL], R3	; alters the color of the pixel in the selected line and collum
   	SUB R7, 1               ; updates the value of the line
   	SUB R8, 1		; condition to see if it has already altered the color of the two pixels
   	JNZ collum24            ; continues until the collum is fully collored
   	ADD R5, 2               ; goes on to the next collum
   	MOV R7, R1		; resets the line
   	MOV R8, 2               ; saves the number of pixels to draw per collum
   	SUB R6, 1               ; updates the number of collums to draw
   	JNZ collum24		; when it's zero all of the collums 2 and 4 are already complete
	CALL last_Pixel
	RET

last_Pixel:
   	CALL updates_Values
   	SUB R7, 3
   	ADD R5, 2
   	MOV  [DEF_LIN], R7	; selects the line
	MOV  [DEF_COL], R5	; selects the collum
	MOV  [DEF_PIXEL], R3	; alters the color of the pixel in the selected line and collum
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

;=================================================================
; MISSILE:
;-----------------------------------------------------------------

;=================================================================
; METEOR:
;-----------------------------------------------------------------

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

	MOV  R1, [R2]
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

var_Reset_Cyclic:
	MOV  R2, 0
	MOV  R0, [R1]
	MOV  [R0], R2

	ADD  R1, NEXT_WORD
	MOV  R0, [R1]
	MOV  R2, LIST_END
	CMP  R0, R2
	JNZ  var_Reset_Cyclic

	POP  R2
	POP  R1
	POP  R0

;=================================================================
; INTERRUPTION HANDLING:
;-----------------------------------------------------------------
