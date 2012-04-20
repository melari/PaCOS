JSR loader
SET A, bin
JSR mkdir
SET A, usr
JSR mkdir
SET A, executable
JSR mkdir

:crash SET PC, crash

:bin DAT "bin", 0x0000
:usr DAT "usr", 0x0000
:executable DAT "executable", 0x0000



;void loader(void)
; PaCOS_FS Initilizations...
:loader 
    SET A, _.FS
    SET [_FS_DIR_START], A
    ADD A, 0x2000
    SET [_FS_DAT_START], A
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
  
  
  
  
  
  
:_.FS_HEADER
    :_FS_DIR_SIZE  DAT 8
    :_FS_DAT_SIZE  DAT 32
    :_FS_DIR_COUNT DAT 1024  ; 0x2000 memory space
    :_FS_DAT_COUNT DAT 512   ; 0x4000 memory space
    :_FS_DIR_START DAT 0
    :_FS_DAT_START DAT 0
:_.FS
