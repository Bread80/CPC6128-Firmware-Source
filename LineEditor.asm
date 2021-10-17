;; BASIC line editor
;;=====================================================================
;; EDIT
;; HL = address of buffer

EDIT:                             ;{{Addr=$2c02 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2C02:c5}} 
        push    de                ;{{2C03:d5}} 
        push    hl                ;{{2C04:e5}} 
        call    initialise_relative_copy_cursor_position_to_origin;{{2C05:cdf22d}}  reset relative cursor pos
        ld      bc,$00ff          ;{{2C08:01ff00}} ##LIT##;WARNING: Code area used as literal
; B = position in edit buffer
; C = number of characters remaining in buffer

;; if there is a number at the start of the line then skip it
_edit_5:                          ;{{Addr=$2c0b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2C0B:7e}} 
        cp      $30               ;{{2C0C:fe30}}  '0'
        jr      c,_edit_11        ;{{2C0E:3807}}  (+&07)
        cp      $3a               ;{{2C10:fe3a}}  '9'+1
        call    c,_edit_39        ;{{2C12:dc422c}} 
        jr      c,_edit_5         ;{{2C15:38f4}} 

;;--------------------------------------------------------------------
;; all other characters
_edit_11:                         ;{{Addr=$2c17 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{2C17:78}} 
        or      a                 ;{{2C18:b7}} 
;; zero flag set if start of buffer, zero flag clear if not start of buffer

        ld      a,(hl)            ;{{2C19:7e}} 
        call    nz,_edit_39       ;{{2C1A:c4422c}} 

        push    hl                ;{{2C1D:e5}} 
_edit_16:                         ;{{Addr=$2c1e Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{2C1E:0c}} 
        ld      a,(hl)            ;{{2C1F:7e}} 
        inc     hl                ;{{2C20:23}} 
        or      a                 ;{{2C21:b7}} 
        jr      nz,_edit_16       ;{{2C22:20fa}}  (-&06)

        ld      (insert_overwrite_mode_flag),a;{{2C24:3215b1}}  insert/overwrite mode
        pop     hl                ;{{2C27:e1}} 
        call    x2EE4_code        ;{{2C28:cde42e}} 


_edit_24:                         ;{{Addr=$2c2b Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2C2B:c5}} 
        push    hl                ;{{2C2C:e5}} 
        call    x2F56_code        ;{{2C2D:cd562f}} 
        pop     hl                ;{{2C30:e1}} 
        pop     bc                ;{{2C31:c1}} 
        call    _edit_43          ;{{2C32:cd482c}}  process key
        jr      nc,_edit_24       ;{{2C35:30f4}}  (-&0c)

        push    af                ;{{2C37:f5}} 
        call    _shift_key__left_cursor_pressed_23;{{2C38:cd4f2e}} 
        pop     af                ;{{2C3B:f1}} 
        pop     hl                ;{{2C3C:e1}} 
        pop     de                ;{{2C3D:d1}} 
        pop     bc                ;{{2C3E:c1}} 
        cp      $fc               ;{{2C3F:fefc}} 
        ret                       ;{{2C41:c9}} 

;;--------------------------------------------------------------------
;; used to skip characters in input buffer

_edit_39:                         ;{{Addr=$2c42 Code Calls/jump count: 2 Data use count: 0}}
        inc     c                 ;{{2C42:0c}} 
        inc     b                 ;{{2C43:04}}  increment pos
        inc     hl                ;{{2C44:23}}  increment position in buffer
        jp      x2F25_code        ;{{2C45:c3252f}} 

;;--------------------------------------------------------------------

_edit_43:                         ;{{Addr=$2c48 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{2C48:e5}} 
        ld      hl,keys_for_editing_an_existing_line;{{2C49:21722c}} 
        ld      e,a               ;{{2C4C:5f}} 
        ld      a,b               ;{{2C4D:78}} 
        or      c                 ;{{2C4E:b1}} 
        ld      a,e               ;{{2C4F:7b}} 
        jr      nz,_edit_55       ;{{2C50:200b}}  (+&0b)

        cp      $f0               ;{{2C52:fef0}} 
        jr      c,_edit_55        ;{{2C54:3807}}  (+&07)
        cp      $f4               ;{{2C56:fef4}} 
        jr      nc,_edit_55       ;{{2C58:3003}}  (+&03)

;; cursor keys
        ld      hl,keys_for_moving_cursor;{{2C5A:21ae2c}} 

;;--------------------------------------------------------------------
_edit_55:                         ;{{Addr=$2c5d Code Calls/jump count: 3 Data use count: 0}}
        ld      d,(hl)            ;{{2C5D:56}} 
        inc     hl                ;{{2C5E:23}} 
        push    hl                ;{{2C5F:e5}} 
_edit_58:                         ;{{Addr=$2c60 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{2C60:23}} 
        inc     hl                ;{{2C61:23}} 
        cp      (hl)              ;{{2C62:be}} 
        inc     hl                ;{{2C63:23}} 
        jr      z,_edit_66        ;{{2C64:2804}}  (+&04)
        dec     d                 ;{{2C66:15}} 
        jr      nz,_edit_58       ;{{2C67:20f7}}  (-&09)
        ex      (sp),hl           ;{{2C69:e3}} 
_edit_66:                         ;{{Addr=$2c6a Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{2C6A:f1}} 
        ld      a,(hl)            ;{{2C6B:7e}} 
        inc     hl                ;{{2C6C:23}} 
        ld      h,(hl)            ;{{2C6D:66}} 
        ld      l,a               ;{{2C6E:6f}} 
        ld      a,e               ;{{2C6F:7b}} 
        ex      (sp),hl           ;{{2C70:e3}} 
        ret                       ;{{2C71:c9}} 

;;+-----------------
;; keys for editing an existing line
keys_for_editing_an_existing_line:;{{Addr=$2c72 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $13                  
        defw edit_for_key_13      ;##LABEL##
        defb $fc                  ; ESC key
        defw edit_for_key_fc_ESC  ;##LABEL##								
        defb $ef                  
        defw edit_for_key_ef      ;##LABEL##
        defb $0d                  ; RETURN key
        defw _break_message_1     ;##LABEL##
        defb $f0                  ; up cursor key
        defw up_cursor_key_pressed_B;##LABEL##
        defb $f1                  ; down cursor key
        defw down_cursor_key_pressed_B;##LABEL##
        defb $f2                  ; left cursor key
        defw left_cursor_key_pressed_B;##LABEL##
        defb $f3                  ; right cursor key
        defw right_cursor_key_pressed_B;##LABEL##
        defb $f8                  ; CTRL key + up cursor key
        defw CTRL_key__up_cursor_key_pressed;##LABEL##
        defb $f9                  ; CTRL key + down cursor key
        defw CTRL_key__down_cursor_key_pressed;##LABEL##
        defb $fa                  ; CTRL key + left cursor key
        defw CTRL_key__left_cursor_key_pressed;##LABEL##
        defb $fb                  ; CTRL key + right cursor key
        defw CTRL_key__right_cursor_key_pressed;##LABEL##
        defb $f4                  ; SHIFT key + up cursor key
        defw SHIFT_key__up_cursor_pressed;##LABEL##
        defb $f5                  ; SHIFT key + down cursor key
        defw SHIFT_key__left_cursor_pressed;##LABEL##
        defb $f6                  ; SHIFT key + left cursor key
        defw SHIFT_key__right_cursor_pressed;##LABEL##
        defb $f7                  ; SHIFT key + right cursor key
        defw SHIFT_key__left_cursor_key;##LABEL##
        defb $e0                  ; COPY key
        defw COPY_key_pressed     ;##LABEL##
        defb $7f                  ; ESC key
        defw ESC_key_pressed      ;##LABEL##
        defb $10                  ; CLR key
        defw CLR_key_pressed      ;##LABEL##
        defb $e1                  ; CTRL key+TAB key (toggle insert/overwrite)
        defw CTRL_key__TAB_key    ;##LABEL##

;;+--------------------------------------------------------------------
;; keys for moving cursor
keys_for_moving_cursor:           ;{{Addr=$2cae Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $04                  
        defw edit_sound_bleeper   ; Sound bleeper  ##LABEL##
        defb $f0                  ; up cursor key
        defw up_cursor_key_pressed; Move cursor up a line  ##LABEL##
        defb $f1                  ; down cursor key
        defw down_cursor_key_pressed; Move cursor down a line  ##LABEL##
        defb $f2                  ; left cursor key
        defw left_cursor_key_pressed; Move cursor back one character  ##LABEL##
        defb $f3                  ; right cursor key
        defw right_cursor_key_pressed; Move cursor forward one character  ##LABEL##

;;+--------------------------------------------------------------------
;; up cursor key pressed
up_cursor_key_pressed:            ;{{Addr=$2cbd Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$0b             ;{{2CBD:3e0b}}  VT (Move cursor up a line)
        jr      _left_cursor_key_pressed_1;{{2CBF:180a}}  

;;+--------------------------------------------------------------------
;; down cursor key pressed
down_cursor_key_pressed:          ;{{Addr=$2cc1 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,$0a             ;{{2CC1:3e0a}}  LF (Move cursor down a line)
        jr      _left_cursor_key_pressed_1;{{2CC3:1806}} 

;;+--------------------------------------------------------------------
;; right cursor key pressed
right_cursor_key_pressed:         ;{{Addr=$2cc5 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$09             ;{{2CC5:3e09}}  TAB (Move cursor forward one character)
        jr      _left_cursor_key_pressed_1;{{2CC7:1802}}  

;;+--------------------------------------------------------------------
;; left cursor key pressed
left_cursor_key_pressed:          ;{{Addr=$2cc9 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$08             ;{{2CC9:3e08}}  BS (Move character back one character)

;;--------------------------------------------------------------------

_left_cursor_key_pressed_1:       ;{{Addr=$2ccb Code Calls/jump count: 4 Data use count: 0}}
        call    TXT_OUTPUT        ;{{2CCB:cdfe13}}  TXT OUTPUT

;;===========================================================================================
;;edit for key ef
edit_for_key_ef:                  ;{{Addr=$2cce Code Calls/jump count: 0 Data use count: 1}}
        or      a                 ;{{2CCE:b7}} 
        ret                       ;{{2CCF:c9}} 

;;===========================================================================================
;;edit for key fc ESC
edit_for_key_fc_ESC:              ;{{Addr=$2cd0 Code Calls/jump count: 0 Data use count: 1}}
        call    _break_message_1  ;{{2CD0:cdf22c}}  display message
        push    af                ;{{2CD3:f5}} 
        ld      hl,Break_message  ;{{2CD4:21ea2c}}  "*Break*"
        call    _break_message_1  ;{{2CD7:cdf22c}}  display message

        call    TXT_GET_CURSOR    ;{{2CDA:cd7c11}}  TXT GET CURSOR
        dec     h                 ;{{2CDD:25}} 
        jr      z,_edit_for_key_fc_esc_10;{{2CDE:2808}} 

;; go to next line
        ld      a,$0d             ;{{2CE0:3e0d}}  CR (Move cursor to left edge of window on current line)
        call    TXT_OUTPUT        ;{{2CE2:cdfe13}}  TXT OUTPUT
        call    down_cursor_key_pressed;{{2CE5:cdc12c}}  Move cursor down a line

_edit_for_key_fc_esc_10:          ;{{Addr=$2ce8 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{2CE8:f1}} 
        ret                       ;{{2CE9:c9}} 

;;+--------------------------------------------------------------------
;;Break message
Break_message:                    ;{{Addr=$2cea Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "*Break*",0          

;;--------------------------------------------------------------------
;; display 0 terminated string

_break_message_1:                 ;{{Addr=$2cf2 Code Calls/jump count: 2 Data use count: 1}}
        push af                   ;{{2CF2:f5}} 
_break_message_2:                 ;{{Addr=$2cf3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2CF3:7e}}  get character
        inc     hl                ;{{2CF4:23}} 
        or      a                 ;{{2CF5:b7}}  end of string marker?
        call    nz,x2F25_code     ;{{2CF6:c4252f}}  display character
        jr      nz,_break_message_2;{{2CF9:20f8}}  loop for next character
        pop     af                ;{{2CFB:f1}} 
        scf                       ;{{2CFC:37}} 
        ret                       ;{{2CFD:c9}} 

;;===========================================================================
;;edit sound bleeper
edit_sound_bleeper:               ;{{Addr=$2cfe Code Calls/jump count: 8 Data use count: 1}}
        ld      a,$07             ;{{2CFE:3e07}}  BEL (Sound bleeper)
        jr      _left_cursor_key_pressed_1;{{2D00:18c9}} 

;;===========================================================================
;; right cursor key pressed
right_cursor_key_pressed_B:       ;{{Addr=$2d02 Code Calls/jump count: 0 Data use count: 1}}
        ld      d,$01             ;{{2D02:1601}} 
        call    _ctrl_key__down_cursor_key_pressed_1;{{2D04:cd1e2d}} 
        jr      z,edit_sound_bleeper;{{2D07:28f5}}  (-&0b)
        ret                       ;{{2D09:c9}} 

;;===========================================================================
;; down cursor key pressed

down_cursor_key_pressed_B:        ;{{Addr=$2d0a Code Calls/jump count: 0 Data use count: 1}}
        call    x2D73_code        ;{{2D0A:cd732d}} 
        ld      a,c               ;{{2D0D:79}} 
        sub     b                 ;{{2D0E:90}} 
        cp      d                 ;{{2D0F:ba}} 
        jr      c,edit_sound_bleeper;{{2D10:38ec}}  (-&14)
        jr      _ctrl_key__down_cursor_key_pressed_1;{{2D12:180a}}  (+&0a)

;;===========================================================================================
;; CTRL key + right cursor key pressed
;; 
;; go to end of current line
CTRL_key__right_cursor_key_pressed:;{{Addr=$2d14 Code Calls/jump count: 0 Data use count: 1}}
        call    x2D73_code        ;{{2D14:cd732d}} 
        ld      a,d               ;{{2D17:7a}} 
        sub     e                 ;{{2D18:93}} 
        ret     z                 ;{{2D19:c8}} 

        ld      d,a               ;{{2D1A:57}} 
        jr      _ctrl_key__down_cursor_key_pressed_1;{{2D1B:1801}}  (+&01)

;;===========================================================================================
;; CTRL key + down cursor key pressed
;;
;; go to end of text 

CTRL_key__down_cursor_key_pressed:;{{Addr=$2d1d Code Calls/jump count: 0 Data use count: 1}}
        ld      d,c               ;{{2D1D:51}} 

;;--------------------------------------------------------------------

_ctrl_key__down_cursor_key_pressed_1:;{{Addr=$2d1e Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{2D1E:78}} 
        cp      c                 ;{{2D1F:b9}} 
        ret     z                 ;{{2D20:c8}} 

        push    de                ;{{2D21:d5}} 
        call    try_to_move_cursor_right;{{2D22:cdcd2e}} 
        ld      a,(hl)            ;{{2D25:7e}} 
        call    nc,x2F25_code     ;{{2D26:d4252f}} 
        inc     b                 ;{{2D29:04}} 
        inc     hl                ;{{2D2A:23}} 
        call    nc,x2EE4_code     ;{{2D2B:d4e42e}} 
        pop     de                ;{{2D2E:d1}} 
        dec     d                 ;{{2D2F:15}} 
        jr      nz,_ctrl_key__down_cursor_key_pressed_1;{{2D30:20ec}}  (-&14)
        jr      x2D70_code        ;{{2D32:183c}}  (+&3c)

;;===========================================================================
;; left cursor key pressed
left_cursor_key_pressed_B:        ;{{Addr=$2d34 Code Calls/jump count: 0 Data use count: 1}}
        ld      d,$01             ;{{2D34:1601}} 
        call    _ctrl_key__up_cursor_key_pressed_1;{{2D36:cd502d}} 
        jr      z,edit_sound_bleeper;{{2D39:28c3}}  (-&3d)
        ret                       ;{{2D3B:c9}} 


;;===========================================================================
;; up cursor key pressed
up_cursor_key_pressed_B:          ;{{Addr=$2d3c Code Calls/jump count: 0 Data use count: 1}}
        call    x2D73_code        ;{{2D3C:cd732d}} 
        ld      a,b               ;{{2D3F:78}} 
        cp      d                 ;{{2D40:ba}} 
        jr      c,edit_sound_bleeper;{{2D41:38bb}}  (-&45)
        jr      _ctrl_key__up_cursor_key_pressed_1;{{2D43:180b}}  (+&0b)


;;===========================================================================
;; CTRL key + left cursor key pressed
;;
;; go to start of current line

CTRL_key__left_cursor_key_pressed:;{{Addr=$2d45 Code Calls/jump count: 0 Data use count: 1}}
        call    x2D73_code        ;{{2D45:cd732d}} 
        ld      a,e               ;{{2D48:7b}} 
        sub     $01               ;{{2D49:d601}} 
        ret     z                 ;{{2D4B:c8}} 

        ld      d,a               ;{{2D4C:57}} 
        jr      _ctrl_key__up_cursor_key_pressed_1;{{2D4D:1801}}  (+&01)

;;===========================================================================
;; CTRL key + up cursor key pressed

;; go to start of text

CTRL_key__up_cursor_key_pressed:  ;{{Addr=$2d4f Code Calls/jump count: 0 Data use count: 1}}
        ld      d,c               ;{{2D4F:51}} 

_ctrl_key__up_cursor_key_pressed_1:;{{Addr=$2d50 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{2D50:78}} 
        or      a                 ;{{2D51:b7}} 
        ret     z                 ;{{2D52:c8}} 

        call    try_to_move_cursor_left;{{2D53:cdc72e}} 
        jr      nc,x2D5F_code     ;{{2D56:3007}}  (+&07)
        dec     b                 ;{{2D58:05}} 
        dec     hl                ;{{2D59:2b}} 
        dec     d                 ;{{2D5A:15}} 
        jr      nz,_ctrl_key__up_cursor_key_pressed_1;{{2D5B:20f3}}  (-&0d)
        jr      x2D70_code        ;{{2D5D:1811}}  (+&11)

;;===========================================================================
x2D5F_code:                       ;{{Addr=$2d5f Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{2D5F:78}} 
        or      a                 ;{{2D60:b7}} 
        jr      z,x2D6D_code      ;{{2D61:280a}}  (+&0a)
        dec     b                 ;{{2D63:05}} 
        dec     hl                ;{{2D64:2b}} 
        push    de                ;{{2D65:d5}} 
        call    _copy_key_pressed_29;{{2D66:cda22e}} 
        pop     de                ;{{2D69:d1}} 
        dec     d                 ;{{2D6A:15}} 
        jr      nz,x2D5F_code     ;{{2D6B:20f2}}  (-&0e)
x2D6D_code:                       ;{{Addr=$2d6d Code Calls/jump count: 1 Data use count: 0}}
        call    x2EE4_code        ;{{2D6D:cde42e}} 
x2D70_code:                       ;{{Addr=$2d70 Code Calls/jump count: 2 Data use count: 0}}
        or      $ff               ;{{2D70:f6ff}} 
        ret                       ;{{2D72:c9}} 

;;--------------------------------------------------------------------
x2D73_code:                       ;{{Addr=$2d73 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{2D73:e5}} 
        call    TXT_GET_WINDOW    ;{{2D74:cd5212}}  TXT GET WINDOW
        ld      a,d               ;{{2D77:7a}} 
        sub     h                 ;{{2D78:94}} 
        inc     a                 ;{{2D79:3c}} 
        ld      d,a               ;{{2D7A:57}} 
        call    TXT_GET_CURSOR    ;{{2D7B:cd7c11}}  TXT GET CURSOR
        ld      e,h               ;{{2D7E:5c}} 
        pop     hl                ;{{2D7F:e1}} 
        ret                       ;{{2D80:c9}} 
;;===========================================================================================
;; CTRL key + TAB key
;; 
;; toggle insert/overwrite mode
CTRL_key__TAB_key:                ;{{Addr=$2d81 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(insert_overwrite_mode_flag);{{2D81:3a15b1}}  insert/overwrite mode
        cpl                       ;{{2D84:2f}} 
        ld      (insert_overwrite_mode_flag),a;{{2D85:3215b1}} 
        or      a                 ;{{2D88:b7}} 
        ret                       ;{{2D89:c9}} 

;;===========================================================================================
;;edit for key 13
edit_for_key_13:                  ;{{Addr=$2d8a Code Calls/jump count: 1 Data use count: 1}}
        or      a                 ;{{2D8A:b7}} 
        ret     z                 ;{{2D8B:c8}} 

        ld      e,a               ;{{2D8C:5f}} 
        ld      a,(insert_overwrite_mode_flag);{{2D8D:3a15b1}}  insert/overwrite mode
        or      a                 ;{{2D90:b7}} 
        ld      a,c               ;{{2D91:79}} 
        jr      z,_edit_for_key_13_15;{{2D92:280b}}  (+&0b)
        cp      b                 ;{{2D94:b8}} 
        jr      z,_edit_for_key_13_15;{{2D95:2808}}  (+&08)
        ld      (hl),e            ;{{2D97:73}} 
        inc     hl                ;{{2D98:23}} 
        inc     b                 ;{{2D99:04}} 
        or      a                 ;{{2D9A:b7}} 
_edit_for_key_13_13:              ;{{Addr=$2d9b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{2D9B:7b}} 
        jp      x2F25_code        ;{{2D9C:c3252f}} 

_edit_for_key_13_15:              ;{{Addr=$2d9f Code Calls/jump count: 2 Data use count: 0}}
        cp      $ff               ;{{2D9F:feff}} 
        jp      z,edit_sound_bleeper;{{2DA1:cafe2c}} 
        xor     a                 ;{{2DA4:af}} 
        ld      (RAM_b114),a      ;{{2DA5:3214b1}} 
        call    _edit_for_key_13_13;{{2DA8:cd9b2d}} 
        inc     c                 ;{{2DAB:0c}} 
        push    hl                ;{{2DAC:e5}} 
_edit_for_key_13_22:              ;{{Addr=$2dad Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2DAD:7e}} 
        ld      (hl),e            ;{{2DAE:73}} 
        ld      e,a               ;{{2DAF:5f}} 
        inc     hl                ;{{2DB0:23}} 
        or      a                 ;{{2DB1:b7}} 
        jr      nz,_edit_for_key_13_22;{{2DB2:20f9}}  (-&07)
        ld      (hl),a            ;{{2DB4:77}} 
        pop     hl                ;{{2DB5:e1}} 
        inc     b                 ;{{2DB6:04}} 
        inc     hl                ;{{2DB7:23}} 
        call    x2EE4_code        ;{{2DB8:cde42e}} 
        ld      a,(RAM_b114)      ;{{2DBB:3a14b1}} 
        or      a                 ;{{2DBE:b7}} 
        call    nz,_copy_key_pressed_29;{{2DBF:c4a22e}} 
        ret                       ;{{2DC2:c9}} 

;;===========================================================================================
;; ESC key pressed
ESC_key_pressed:                  ;{{Addr=$2dc3 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,b               ;{{2DC3:78}} 
        or      a                 ;{{2DC4:b7}} 
        call    nz,try_to_move_cursor_left;{{2DC5:c4c72e}} 
        jp      nc,edit_sound_bleeper;{{2DC8:d2fe2c}} 
        dec     b                 ;{{2DCB:05}} 
        dec     hl                ;{{2DCC:2b}} 

;;===========================================================================================
;; CLR key pressed
CLR_key_pressed:                  ;{{Addr=$2dcd Code Calls/jump count: 0 Data use count: 1}}
        ld      a,b               ;{{2DCD:78}} 
        cp      c                 ;{{2DCE:b9}} 
        jp      z,edit_sound_bleeper;{{2DCF:cafe2c}} 
        push    hl                ;{{2DD2:e5}} 
_clr_key_pressed_4:               ;{{Addr=$2dd3 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{2DD3:23}} 
        ld      a,(hl)            ;{{2DD4:7e}} 
        dec     hl                ;{{2DD5:2b}} 
        ld      (hl),a            ;{{2DD6:77}} 
        inc     hl                ;{{2DD7:23}} 
        or      a                 ;{{2DD8:b7}} 
        jr      nz,_clr_key_pressed_4;{{2DD9:20f8}}  (-&08)
        dec     hl                ;{{2DDB:2b}} 
        ld      (hl),$20          ;{{2DDC:3620}} 
        ld      (RAM_b114),a      ;{{2DDE:3214b1}} 
        ex      (sp),hl           ;{{2DE1:e3}} 
        call    x2EE4_code        ;{{2DE2:cde42e}} 
        ex      (sp),hl           ;{{2DE5:e3}} 
        ld      (hl),$00          ;{{2DE6:3600}} 
        pop     hl                ;{{2DE8:e1}} 
        dec     c                 ;{{2DE9:0d}} 
        ld      a,(RAM_b114)      ;{{2DEA:3a14b1}} 
        or      a                 ;{{2DED:b7}} 
        call    nz,_copy_key_pressed_31;{{2DEE:c4a62e}} 
        ret                       ;{{2DF1:c9}} 


;;===========================================================================================
;; initialise relative copy cursor position to origin
initialise_relative_copy_cursor_position_to_origin:;{{Addr=$2df2 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{2DF2:af}} 
        ld      (copy_cursor_rel_to_origin),a;{{2DF3:3216b1}} 
        ld      (copy_cursor_Y_rel_to_origin_),a;{{2DF6:3217b1}} 
        ret                       ;{{2DF9:c9}} 

;;===========================================================================================
;; compare copy cursor relative position
;; HL = cursor position
compare_copy_cursor_relative_position:;{{Addr=$2dfa Code Calls/jump count: 2 Data use count: 0}}
        ld      de,(copy_cursor_rel_to_origin);{{2DFA:ed5b16b1}} 
        ld      a,h               ;{{2DFE:7c}} 
        xor     d                 ;{{2DFF:aa}} 
        ret     nz                ;{{2E00:c0}} 
        ld      a,l               ;{{2E01:7d}} 
        xor     e                 ;{{2E02:ab}} 
        ret     nz                ;{{2E03:c0}} 
        scf                       ;{{2E04:37}} 
        ret                       ;{{2E05:c9}} 
;;--------------------------------------------------------------------

_compare_copy_cursor_relative_position_9:;{{Addr=$2e06 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{2E06:4f}} 
        call    get_copy_cursor_position;{{2E07:cdc12e}}  get copy cursor position
        ret     z                 ;{{2E0A:c8}}  quit if not active

;; adjust y position
        ld      a,l               ;{{2E0B:7d}} 
        add     a,c               ;{{2E0C:81}} 
        ld      l,a               ;{{2E0D:6f}} 

;; validate new position
_compare_copy_cursor_relative_position_15:;{{Addr=$2e0e Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_VALIDATE      ;{{2E0E:cdca11}}  TXT VALIDATE
        jr      nc,initialise_relative_copy_cursor_position_to_origin;{{2E11:30df}}  reset relative cursor pos

;; set cursor position
        ld      (copy_cursor_rel_to_origin),hl;{{2E13:2216b1}} 
        ret                       ;{{2E16:c9}} 

;;===========================================================================================
;; SHIFT key + left cursor key
;; 
;; move copy cursor left
SHIFT_key__left_cursor_key:       ;{{Addr=$2e17 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0100          ;{{2E17:110001}} ##LIT##;WARNING: Code area used as literal
        jr      _shift_key__left_cursor_pressed_1;{{2E1A:180d}}  (+&0d)
;;===========================================================================================
;; SHIFT key + right cursor pressed
;; 
;; move copy cursor right
SHIFT_key__right_cursor_pressed:  ;{{Addr=$2e1c Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$ff00          ;{{2E1C:1100ff}} 
        jr      _shift_key__left_cursor_pressed_1;{{2E1F:1808}}  (+&08)
;;===========================================================================================
;; SHIFT key + up cursor pressed
;;
;; move copy cursor up
SHIFT_key__up_cursor_pressed:     ;{{Addr=$2e21 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$00ff          ;{{2E21:11ff00}} ##LIT##;WARNING: Code area used as literal
        jr      _shift_key__left_cursor_pressed_1;{{2E24:1803}}  (+&03)
;;===========================================================================================
;; SHIFT key + left cursor pressed
;;
;; move copy cursor down
SHIFT_key__left_cursor_pressed:   ;{{Addr=$2e26 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0001          ;{{2E26:110100}} ##LIT##;WARNING: Code area used as literal

;;--------------------------------------------------------------------
;; D = column increment
;; E = row increment
_shift_key__left_cursor_pressed_1:;{{Addr=$2e29 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{2E29:c5}} 
        push    hl                ;{{2E2A:e5}} 
        call    get_copy_cursor_position;{{2E2B:cdc12e}}  get copy cursor position

;; get cursor position
        call    z,TXT_GET_CURSOR  ;{{2E2E:cc7c11}}  TXT GET CURSOR

;; adjust cursor position

;; adjust column
        ld      a,h               ;{{2E31:7c}} 
        add     a,d               ;{{2E32:82}} 
        ld      h,a               ;{{2E33:67}} 

;; adjust row
        ld      a,l               ;{{2E34:7d}} 
        add     a,e               ;{{2E35:83}} 
        ld      l,a               ;{{2E36:6f}} 
;; validate the position
        call    TXT_VALIDATE      ;{{2E37:cdca11}}  TXT VALIDATE
        jr      nc,_shift_key__left_cursor_pressed_18;{{2E3A:300b}}  position invalid?

;; position is valid

        push    hl                ;{{2E3C:e5}} 
        call    _shift_key__left_cursor_pressed_23;{{2E3D:cd4f2e}} 
        pop     hl                ;{{2E40:e1}} 

;; store new position
        ld      (copy_cursor_rel_to_origin),hl;{{2E41:2216b1}} 

        call    _shift_key__left_cursor_pressed_21;{{2E44:cd4a2e}} 

;;----------------

_shift_key__left_cursor_pressed_18:;{{Addr=$2e47 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2E47:e1}} 
        pop     bc                ;{{2E48:c1}} 
        ret                       ;{{2E49:c9}} 

;;--------------------------------------------------------------------

_shift_key__left_cursor_pressed_21:;{{Addr=$2e4a Code Calls/jump count: 4 Data use count: 0}}
        ld      de,TXT_PLACE_CURSOR;{{2E4A:116512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR ##LABEL##
        jr      _shift_key__left_cursor_pressed_24;{{2E4D:1803}} 

;;--------------------------------------------------------------------
_shift_key__left_cursor_pressed_23:;{{Addr=$2e4f Code Calls/jump count: 4 Data use count: 0}}
        ld      de,TXT_PLACE_CURSOR;{{2E4F:116512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR ##LABEL##

;;--------------------------------------------------------------------
_shift_key__left_cursor_pressed_24:;{{Addr=$2e52 Code Calls/jump count: 1 Data use count: 0}}
        call    get_copy_cursor_position;{{2E52:cdc12e}}  get copy cursor position
        ret     z                 ;{{2E55:c8}} 

        push    hl                ;{{2E56:e5}} 
        call    TXT_GET_CURSOR    ;{{2E57:cd7c11}}  TXT GET CURSOR
        ex      (sp),hl           ;{{2E5A:e3}} 
        call    TXT_SET_CURSOR    ;{{2E5B:cd7011}}  TXT SET CURSOR
        call    LOW_PCDE_INSTRUCTION;{{2E5E:cd1600}}  LOW: PCDE INSTRUCTION
        pop     hl                ;{{2E61:e1}} 
        jp      TXT_SET_CURSOR    ;{{2E62:c37011}}  TXT SET CURSOR
;;===========================================================================================
;; COPY key pressed
COPY_key_pressed:                 ;{{Addr=$2e65 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2E65:c5}} 
        push    hl                ;{{2E66:e5}} 
        call    TXT_GET_CURSOR    ;{{2E67:cd7c11}}  TXT GET CURSOR
        ex      de,hl             ;{{2E6A:eb}} 
        call    get_copy_cursor_position;{{2E6B:cdc12e}} 
        jr      nz,_copy_key_pressed_12;{{2E6E:200c}}  perform copy
        ld      a,b               ;{{2E70:78}} 
        or      c                 ;{{2E71:b1}} 
        jr      nz,_copy_key_pressed_25;{{2E72:2026}}  (+&26)
        call    TXT_GET_CURSOR    ;{{2E74:cd7c11}}  TXT GET CURSOR
        ld      (copy_cursor_rel_to_origin),hl;{{2E77:2216b1}} 
        jr      _copy_key_pressed_14;{{2E7A:1806}}  (+&06)

;;--------------------------------------------------------------------

_copy_key_pressed_12:             ;{{Addr=$2e7c Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_SET_CURSOR    ;{{2E7C:cd7011}}  TXT SET CURSOR
        call    TXT_PLACE_CURSOR  ;{{2E7F:cd6512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR

_copy_key_pressed_14:             ;{{Addr=$2e82 Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_RD_CHAR       ;{{2E82:cdac13}}  TXT RD CHAR
        push    af                ;{{2E85:f5}} 
        ex      de,hl             ;{{2E86:eb}} 
        call    TXT_SET_CURSOR    ;{{2E87:cd7011}}  TXT SET CURSOR
        ld      hl,(copy_cursor_rel_to_origin);{{2E8A:2a16b1}} 
        inc     h                 ;{{2E8D:24}} 
        call    TXT_VALIDATE      ;{{2E8E:cdca11}}  TXT VALIDATE
        jr      nc,_copy_key_pressed_23;{{2E91:3003}}  (+&03)
        ld      (copy_cursor_rel_to_origin),hl;{{2E93:2216b1}} 
_copy_key_pressed_23:             ;{{Addr=$2e96 Code Calls/jump count: 1 Data use count: 0}}
        call    _shift_key__left_cursor_pressed_21;{{2E96:cd4a2e}} 
        pop     af                ;{{2E99:f1}} 
_copy_key_pressed_25:             ;{{Addr=$2e9a Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2E9A:e1}} 
        pop     bc                ;{{2E9B:c1}} 
        jp      c,edit_for_key_13 ;{{2E9C:da8a2d}} 
        jp      edit_sound_bleeper;{{2E9F:c3fe2c}} 

;;--------------------------------------------------------------------

_copy_key_pressed_29:             ;{{Addr=$2ea2 Code Calls/jump count: 2 Data use count: 0}}
        ld      d,$01             ;{{2EA2:1601}} 
        jr      _copy_key_pressed_32;{{2EA4:1802}}  (+&02)

;;--------------------------------------------------------------------

_copy_key_pressed_31:             ;{{Addr=$2ea6 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,$ff             ;{{2EA6:16ff}} 
;;--------------------------------------------------------------------
_copy_key_pressed_32:             ;{{Addr=$2ea8 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2EA8:c5}} 
        push    hl                ;{{2EA9:e5}} 
        push    de                ;{{2EAA:d5}} 
        call    _shift_key__left_cursor_pressed_23;{{2EAB:cd4f2e}} 
        pop     de                ;{{2EAE:d1}} 
        call    get_copy_cursor_position;{{2EAF:cdc12e}} 
        jr      z,_copy_key_pressed_44;{{2EB2:2809}}  (+&09)
        ld      a,h               ;{{2EB4:7c}} 
        add     a,d               ;{{2EB5:82}} 
        ld      h,a               ;{{2EB6:67}} 
        call    _compare_copy_cursor_relative_position_15;{{2EB7:cd0e2e}} 
        call    _shift_key__left_cursor_pressed_21;{{2EBA:cd4a2e}} 
_copy_key_pressed_44:             ;{{Addr=$2ebd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2EBD:e1}} 
        pop     bc                ;{{2EBE:c1}} 
        or      a                 ;{{2EBF:b7}} 
        ret                       ;{{2EC0:c9}} 

;;===========================================================================================
;; get copy cursor position
;; this is relative to the actual cursor pos
;;
;; zero flag set if cursor is not active
get_copy_cursor_position:         ;{{Addr=$2ec1 Code Calls/jump count: 5 Data use count: 0}}
        ld      hl,(copy_cursor_rel_to_origin);{{2EC1:2a16b1}} 
        ld      a,h               ;{{2EC4:7c}} 
        or      l                 ;{{2EC5:b5}} 
        ret                       ;{{2EC6:c9}} 
;;===========================================================================================
;; try to move cursor left?
try_to_move_cursor_left:          ;{{Addr=$2ec7 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{2EC7:d5}} 
        ld      de,$ff08          ;{{2EC8:1108ff}} 
        jr      _try_to_move_cursor_right_2;{{2ECB:1804}}  (+&04)

;;===========================================================================================
;; try to move cursor right?
try_to_move_cursor_right:         ;{{Addr=$2ecd Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{2ECD:d5}} 
        ld      de,$0109          ;{{2ECE:110901}} ##LIT##;WARNING: Code area used as literal
;;--------------------------------------------------------------------
;; D = column increment
;; E = character to plot
_try_to_move_cursor_right_2:      ;{{Addr=$2ed1 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2ED1:c5}} 
        push    hl                ;{{2ED2:e5}} 

;; get current cursor position
        call    TXT_GET_CURSOR    ;{{2ED3:cd7c11}}  TXT GET CURSOR

;; adjust cursor position
        ld      a,d               ;{{2ED6:7a}}  column increment
        add     a,h               ;{{2ED7:84}}  add on column
        ld      h,a               ;{{2ED8:67}}  final column

;; validate this new position
        call    TXT_VALIDATE      ;{{2ED9:cdca11}}  TXT VALIDATE

;; if valid then output character, otherwise report error
        ld      a,e               ;{{2EDC:7b}} 
        call    c,TXT_OUTPUT      ;{{2EDD:dcfe13}}  TXT OUTPUT

        pop     hl                ;{{2EE0:e1}} 
        pop     bc                ;{{2EE1:c1}} 
        pop     de                ;{{2EE2:d1}} 
        ret                       ;{{2EE3:c9}} 

;;===========================================================================================
x2EE4_code:                       ;{{Addr=$2ee4 Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{2EE4:c5}} 
        push    hl                ;{{2EE5:e5}} 
        ex      de,hl             ;{{2EE6:eb}} 
        call    TXT_GET_CURSOR    ;{{2EE7:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2EEA:4f}} 
        ex      de,hl             ;{{2EEB:eb}} 
x2EEC_code:                       ;{{Addr=$2eec Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2EEC:7e}} 
        inc     hl                ;{{2EED:23}} 
        or      a                 ;{{2EEE:b7}} 
        call    nz,x2F02_code     ;{{2EEF:c4022f}} 
        jr      nz,x2EEC_code     ;{{2EF2:20f8}}  (-&08)
        call    TXT_GET_CURSOR    ;{{2EF4:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2EF7:91}} 
        ex      de,hl             ;{{2EF8:eb}} 
        add     a,l               ;{{2EF9:85}} 
        ld      l,a               ;{{2EFA:6f}} 
        call    TXT_SET_CURSOR    ;{{2EFB:cd7011}}  TXT SET CURSOR
        pop     hl                ;{{2EFE:e1}} 
        pop     bc                ;{{2EFF:c1}} 
        or      a                 ;{{2F00:b7}} 
        ret                       ;{{2F01:c9}} 

x2F02_code:                       ;{{Addr=$2f02 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{2F02:f5}} 
        push    bc                ;{{2F03:c5}} 
        push    de                ;{{2F04:d5}} 
        push    hl                ;{{2F05:e5}} 
        ld      b,a               ;{{2F06:47}} 
        call    TXT_GET_CURSOR    ;{{2F07:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2F0A:91}} 
        add     a,e               ;{{2F0B:83}} 
        ld      e,a               ;{{2F0C:5f}} 
        ld      c,b               ;{{2F0D:48}} 
        call    TXT_VALIDATE      ;{{2F0E:cdca11}}  TXT VALIDATE
        jr      c,x2F18_code      ;{{2F11:3805}}  (+&05)
        ld      a,b               ;{{2F13:78}} 
        add     a,a               ;{{2F14:87}} 
        inc     a                 ;{{2F15:3c}} 
        add     a,e               ;{{2F16:83}} 
        ld      e,a               ;{{2F17:5f}} 
x2F18_code:                       ;{{Addr=$2f18 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2F18:eb}} 
        call    TXT_VALIDATE      ;{{2F19:cdca11}}  TXT VALIDATE
        ld      a,c               ;{{2F1C:79}} 
        call    c,x2F25_code      ;{{2F1D:dc252f}} 
        pop     hl                ;{{2F20:e1}} 
        pop     de                ;{{2F21:d1}} 
        pop     bc                ;{{2F22:c1}} 
        pop     af                ;{{2F23:f1}} 
        ret                       ;{{2F24:c9}} 

x2F25_code:                       ;{{Addr=$2f25 Code Calls/jump count: 5 Data use count: 0}}
        push    af                ;{{2F25:f5}} 
        push    bc                ;{{2F26:c5}} 
        push    de                ;{{2F27:d5}} 
        push    hl                ;{{2F28:e5}} 
        ld      b,a               ;{{2F29:47}} 
        call    TXT_GET_CURSOR    ;{{2F2A:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2F2D:4f}} 
        push    bc                ;{{2F2E:c5}} 
        call    TXT_VALIDATE      ;{{2F2F:cdca11}}  TXT VALIDATE
        pop     bc                ;{{2F32:c1}} 
        call    c,compare_copy_cursor_relative_position;{{2F33:dcfa2d}} 
        push    af                ;{{2F36:f5}} 
        call    c,_shift_key__left_cursor_pressed_23;{{2F37:dc4f2e}} 
        ld      a,b               ;{{2F3A:78}} 
        push    bc                ;{{2F3B:c5}} 
        call    TXT_WR_CHAR       ;{{2F3C:cd3513}}  TXT WR CHAR
        pop     bc                ;{{2F3F:c1}} 
        call    TXT_GET_CURSOR    ;{{2F40:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2F43:91}} 
        call    nz,_compare_copy_cursor_relative_position_9;{{2F44:c4062e}} 
        pop     af                ;{{2F47:f1}} 
        jr      nc,x2F51_code     ;{{2F48:3007}}  (+&07)
        sbc     a,a               ;{{2F4A:9f}} 
        ld      (RAM_b114),a      ;{{2F4B:3214b1}} 
        call    _shift_key__left_cursor_pressed_21;{{2F4E:cd4a2e}} 
x2F51_code:                       ;{{Addr=$2f51 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2F51:e1}} 
        pop     de                ;{{2F52:d1}} 
        pop     bc                ;{{2F53:c1}} 
        pop     af                ;{{2F54:f1}} 
        ret                       ;{{2F55:c9}} 

x2F56_code:                       ;{{Addr=$2f56 Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_CURSOR    ;{{2F56:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2F59:4f}} 
        call    TXT_VALIDATE      ;{{2F5A:cdca11}}  TXT VALIDATE
        call    compare_copy_cursor_relative_position;{{2F5D:cdfa2d}} 
        jp      c,KM_WAIT_CHAR    ;{{2F60:dabf1b}}  KM WAIT CHAR
        call    TXT_CUR_ON        ;{{2F63:cd7612}}  TXT CUR ON
        call    TXT_GET_CURSOR    ;{{2F66:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2F69:91}} 
        call    nz,_compare_copy_cursor_relative_position_9;{{2F6A:c4062e}} 
        call    KM_WAIT_CHAR      ;{{2F6D:cdbf1b}}  KM WAIT CHAR
        jp      TXT_CUR_OFF       ;{{2F70:c37e12}}  TXT CUR OFF




