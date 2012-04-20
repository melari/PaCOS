;void loader(void)
:loader 
    SET A, _.FS
    SET [_FS_DIR_START], A
    ADD A, 0x2000
    SET [_FS_DAT_START], A
    SET PC, POP
    
;A inode* mkdir(A string* name)
:mkdir
  SET PUSH, I
  SET PUSH, X
  
  SET I, [_FS_DIR_START]
  :_loop__mkdir
  SET X, [I]
  AND X, 0x8000           ; used bit
  IFE X, 0x8000
  SET PC, _found__mkdir
  ADD I, [_FS_DIR_SIZE]
  SET PC, _loop__mkdir
  
  :_found__mkdir
  SET [I], 0xD000
  SET A, 
  
  SET A, I    ;return inode address
  SET X, POP
  SET I, POP
  SET PC, POP
  
;void string_copy(A string* str1, B string* str2)
:string_copy
  IFE [A], 
  SET PC, POP


:_.FS_HEADER
    :_FS_DIR_SIZE  DAT 8
    :_FS_DAT_SIZE  DAT 32
    :_FS_DIR_COUNT DAT 1024  ; 0x2000 memory space
    :_FS_DAT_COUNT DAT 512   ; 0x4000 memory space
    :_FS_DIR_START DAT 0
    :_FS_DAT_START DAT 0
:_.FS
