; PaC OS
; Very simple OS for DCPU-16.
; Not yet completed obviously, need to add support for more generic commands to allow for program installation.

; A: argument[0]/return destructable
; B: free
; C: free
; X: free
; Y: free
; Z: reserved (cursor location)
; I: free
; J: free

; 0xA000 to 0xA0FF: reserved command input buffer.

jsr loader

:PACOS_main_loop
JSR PACOS_command_scan
SET A, 0xA000
JSR runCommand
SET PC, PACOS_main_loop



:END
  SET A, PACOS_end
    JSR printLine
:HLT SET PC, HLT

:root DAT "root", 0x0000

;void loader(void)
:loader    
    SET Z, 0x8000               ; SETUP MONITOR I/O
    SET A, PACOS_welcome
    JSR printLine

    SET A, _.FS                 ; SETUP FILE SYSTEM
    SET [_FS_DIR_START], A
    ADD A, 0x2000
    SET [_FS_DAT_START], A
    
    SET A, root                 ; CREATE ROOT DIRECTORY AND SET CD
    JSR mkdir
    SET [CD], A
    
    SET PC, POP

;void PACOS_command_scan(void)
:PACOS_command_scan
    SET X, 0xA000							; Reset command buffer
    SET Y, [PACOS_key_pointer]				; Load up key pointer
    
    SET [VAR_PRINT_COL], 0x9000				; Text output to blue
    
    SET A, [CD]                             ; Display current directory
    ADD A, 1
    SET B, 10
    JSR printDChar
        
    SET A, PACOS_prompt						; Display the command prompt
    JSR print    
    
    SET [VAR_PRINT_COL], 0xF000				; Text output back to white
    
    :_wait__PACOS_command_scan
    IFE [Y], 0x000							; Wait for a key press (ie a change from NULL)
    SET PC, _wait__PACOS_command_scan
    SET [X], [Y]							; When found, move the key into the command buffer
    SET [Y], 0x0000							; Clear the input buffer position

	; SPECIAL CHARACTERS
    
    ;CASE: ENTER
    IFN [X], 0x000A
    SET PC, _next1__PACOS_command_scan
    SET [VAR_PRINT_COL], 0xF000				; Reset text output to white
    JSR newLine								; Move to next line (for command output)    
    SET [X], 0x0000
    
    ADD Y, 1								; Function return (store key_pointer back to memory)
    IFG Y, 0x900F
    SET Y, 0x9000
    SET [PACOS_key_pointer], Y
    SET PC, POP
    SET PC, _next0__PACOS_command_scan ;unreachable switch return

	; CASE: BACKSPACE
    :_next1__PACOS_command_scan
    IFN [X], 0x0008
    SET PC, _next2__PACOS_command_scan
    SUB Z, 1								; Move cursor back one
    SET A, 0x0020							; Clear this position
    JSR printChar
    SUB Z, 1								; Move cursor back one again
    SUB X, 2								; Remove backspace and prev character from command buffer
    SET PC, _next0__PACOS_command_scan
    
    ; DEFAULT:
    :_next2__PACOS_command_scan
    SET A, [X]								
    JSR printChar

    :_next0__PACOS_command_scan
    ADD X, 1								; Move to next buffer positions
    IFG X, 0xA0FF							; Make sure not to overflow command buffer!
    SET PC, _commandOverflow__PACOS_command_scan
    SET PC, _done__PACOS_command_scan
    :_commandOverflow__PACOS_command_scan
    SUB X, 1
    SUB Z, 1
    SET A, 0x0020
    JSR printChar
    SUB Z, 1
    
    :_done__PACOS_command_scan
    ADD Y, 1
    IFG Y, 0x900F							; Make sure to loop input buffer.
    SET Y, 0x9000
    SET PC, _wait__PACOS_command_scan

    SET PC, POP ; unreachable end
    

;void runCommand(A string* command)
; Runs a single command
:runCommand
	SET PUSH, X
    SET X, A
    
    
    ;CASE: "exit"	
    SET B, PACOScom_exit
    SET C, 0x0000
    JSR compareString
    IFE A, 0x0000
    SET PC, _next2__runCommand
    SET PC, END    
    
    ;CASE: "help"
    :_next2__runCommand
    SET A, X
    SET B, PACOScom_help
    SET C, 0x0000
    JSR compareString
    IFE A, 0x0000
    SET PC, _next1__runCommand
    JSR com_help
    SET PC, _done__runCommand
    
    ;CASE: "echo [text]"
    :_next1__runCommand
    SET A, X
    SET B, PACOScom_echo
    SET C, 0x0020
    JSR compareString    
    IFE A, 0x0000
    SET PC, _next0__runCommand
    JSR com_echo
    SET PC, _done__runCommand    
    
    ;DEFAULT:
    :_next0__runCommand
    SET A, PACOS_invalid
    JSR printLine
    
    :_done__runCommand
    SET X, POP
	SET PC, POP

;void print(A string* message)
; Prints a string to the console
:print
	SET PUSH, X
    SET PUSH, I
    SET I, A
    
    ;check for color bit
    SET X, [VAR_PRINT_COL]
    IFN [I], 0xFFFF
    SET PC, _loop__print
    ADD I, 1
    SET [VAR_PRINT_COL], [I]
    ADD I, 1
    
    :_loop__print
    SET A, [I]
    IFE A, 0x0000
    SET PC, _done__print
    JSR printChar
    ADD I, 1
    SET PC, _loop__print

    :_done__print
    SET [VAR_PRINT_COL], X
    SET I, POP
    SET X, POP    
    SET PC, POP


;void printLine(A string* message)
; Prints a string to the console followed by a newline.
:printLine
    JSR print
    JSR newLine
    SET PC, POP


;void printChar(A char character)
; Print a single character to the console.
:printChar
	IFE A, 0x000A
    SET PC, _newline__printChar
    
    AND A, 0x00FF
    BOR A, [VAR_PRINT_COL]
    SET [Z], A
    ADD Z, 1
    IFG Z, 0x817F ;Passed end of console output
    JSR newLine
    SET PC, POP
    
    :_newline__printChar
    JSR newLine
    SET PC, POP
    

;void printBool(A bool value)
; Prints T if value is 0x0001 and F is value is 0x0000
:printBool
	IFE A, 0x0001
	SET PC, _showTrue__printBool

	SET A, 0x0046
	JSR printChar
	SET PC, POP

	:_showTrue__printBool
	SET A, 0x0054
	JSR printChar
    SET PC, POP
    
    
;A dchar* stringToDChar(A string* target, B out dchar* location)
; Compress a standard string into dchar format
:stringToDChar
    SET PUSH, A
    SET PUSH, B
    SET PUSH, X
    SET PUSH, Y
    SET PUSH, Z

    SET Z, B
    SET B, A
    ADD B, 1    
    
    :_loop__stringToDChar
    SET X, [A]
    SET Y, [B]
    SHL X, 8        ; shift char value to high byte
    AND X, 0xFF00   ; clear bottom byte
    AND Y, 0x00FF   ; clear top byte
    
    IFE X, 0x0000
      SET PC, _done__stringToDChar
    IFE Y , 0x0000
      SET PC, _shortFinish__stringToDChar

    BOR X, Y        ; combine two halfs
    SET [Z], X      ; save compressed word.
    
    ADD A, 2
    ADD B, 2
    ADD Z, 1
    SET PC, _loop__stringToDChar
    
    :_shortFinish__stringToDChar
    SET [Z], X
    SET PC, _return__stringToDChar
    
    :_done__stringToDChar
    SET [Z], 0x0000
    
    :_return__stringToDChar
    SET Z, POP
    SET Y, POP
    SET X, POP
    SET B, POP
    SET A, POP
    SET PC, POP
    
    
;void pringDChar(A dchar* message, B uint maxLength)
; prints the dchar pointed to by message. Additionally, specify a max length that
; printing will stop after even if no NULL character is reached.
:printDChar
    SET PUSH, I
    SET I, A
    
    :_loop__printDChar
    SET A, [I]          
    SHR A, 8    
    IFE A, 0x0000                     ; High character
    SET PC, _done__printDChar
    JSR printChar
    
    SUB B, 1                          ; check if maxLength reached
    IFE B, 0x0000
    SET PC, _done__printDChar
    
    SET A, [I]
    AND A, 0x00FF
    IFE A, 0x0000                     ; Low character
    SET PC, _done__printDChar
    JSR printChar
    
    SUB B, 1                          ; check if maxLength reached
    IFE B, 0x0000
    SET PC, _done__printDChar
    
    ADD I, 1
    SET PC, _loop__printDChar

    :_done__printDChar
    SET I, POP    
    SET PC, POP


;void clr(void)
; clears all terminal values.
:clr
    SET Z, 0x8000
    :_loop__clr
    SET [Z], 0x0000
    ADD Z, 1
    IFN Z, 0x81FF
    SET PC, _loop__clr
    SET Z, 0x8000
    SET PC, POP


;void newLine(void)
; Move to next line
:newLine
    SET A, Z
    MOD A, 0x0020
    IFG A, 0x000F
    SET PC, _second__newLine
    ADD Z, 0x0020
    SET PC, _done__newLine
    :_second__newLine
    ADD Z, 0x0010
    :_done__newLine
    AND Z, 0x81F0
    IFG Z, 0x817F
    SET PC, _offscreen__newLine
    SET PC, POP
    
    :_offscreen__newLine
    SET Z, 0x8160
    JSR shiftView
    SET PC, POP
    
    
;void shiftView(void)
; Moves all characters up one line
:shiftView
	SET PUSH, X
    SET PUSH, Y
    
    SET X, 0x8000
    :_loop__shiftView			; Move all rows upwards (except last)
    SET Y, X
    ADD Y, 0x0020
    SET [X], [Y]
    ADD X, 1
    IFG X, 0x815F
    SET PC, _next__shiftView
    SET PC, _loop__shiftView
    
    :_next__shiftView			; Clear bottom row
    SET [X], 0x0020
    ADD X, 1
    IFG X, 0x817F
    SET PC, _end__shiftView
    SET PC, _next__shiftView
    
 	:_end__shiftView
    SET Y, POP
    SET X, POP
	SET PC, POP

    
;A bool compareString(A string* string1, B string* string2, C char delim)
; Checks if string1 and string2 are the same. delim is used as the string terminator.
; Returns 0x0001 if they are and 0x0000 if not.
:compareString	
	:_loop_compareString    
	IFN [A], [B]					; Current character != -> false.
    SET PC, _false_compareString
    
    IFE [A], C   					; Last characters are NULL and match -> true.
    SET PC, _true_compareString
    
    ADD A, 1						; Use recursion if string is longer.
    ADD B, 1
    JSR compareString
    SET PC, POP
    
    :_true_compareString
    SET A, 0x0001
    SET PC, POP
    
    :_false_compareString
    SET A, 0x0000
    SET PC, POP


    
;A inode* mkdir(A string* name)
; Create a new inode in the first available slot in the dir sector.
:mkdir
    SET PUSH, I
    SET PUSH, X

    SET I, [_FS_DIR_START]
    :_loop__mkdir
    SET X, [I]
    AND X, 0x8000           ; used bit
    IFE X, 0x0000
    SET PC, _found__mkdir
    ADD I, [_FS_DIR_SIZE]
    SET PC, _loop__mkdir

    :_found__mkdir
    SET [I], 0xD000    ;Set status word
    SET B, I
    ADD B, 1
    JSR stringToDChar  ; Convert and copy name
    ADD B, 5
    SET [B], 0x0000     ; Clear both data words.
    ADD B, 1
    SET [B], 0x0000


    SET A, I           ;return inode address
    SET X, POP
    SET I, POP
    SET PC, POP
    
    
    
    
;void com_echo(void)
; Parses the current command buffer assuming echo command format.
:com_echo
	SET A, 0xA005
   	JSR printLine
	SET PC, POP

;void com_help(void)
; Displays the help file.
:com_help
	SET A, PACOS_help
    JSR printLine
	SET PC, POP

:_.DATA

:VAR_PRINT_COL dat 0xF000

:PACOS_help dat "PAC OS help file", 0x000A
			dat "Available Commands:", 0x000A
            dat "help, echo [text], exit", 0x0000
            
:PACOS_prompt dat 0xFFFF, 0x9000, "$ ", 0x0000
:PACOS_welcome dat 0xFFFF, 0xA000, "PaC OS Ready.", 0x000A
               dat "Type help for a list of commands", 0x0000
:PACOS_invalid dat 0xFFFF, 0xC000, "Unknown Command", 0x0000
:PACOS_end dat 0xFFFF, 0xC000, "System Shutdown", 0x0000
:PACOS_key_pointer dat 0x9000

:_.COMMANDS
:PACOScom_exit dat "EXIT", 0x0000
:PACOScom_echo dat "ECHO", 0x0020
:PACOScom_help dat "HELP", 0x0000
:_.END_COMMANDS dat 0xFFFE


:_.FS_HEADER
    :CD            DAT 0     ; current directory inode pointer
    :_FS_DIR_SIZE  DAT 8
    :_FS_DAT_SIZE  DAT 32
    :_FS_DIR_COUNT DAT 1024  ; 0x2000 memory space
    :_FS_DAT_COUNT DAT 512   ; 0x4000 memory space
    :_FS_DIR_START DAT 0
    :_FS_DAT_START DAT 0
:_.FS