;; BASIC line editor
;;=====================================================================
;; EDIT
;; HL = address of buffer

EDIT:                             ;{{Addr=$2c02 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2c02:c5}} 
        push    de                ;{{2c03:d5}} 
        push    hl                ;{{2c04:e5}} 
        call    initialise_relative_copy_cursor_position_to_origin;{{2c05:cdf22d}}  reset relative cursor pos
        ld      bc,$00ff          ;{{2c08:01ff00}} ##LIT##;WARNING: Code area used as literal
; B = position in edit buffer
; C = number of characters remaining in buffer

;; if there is a number at the start of the line then skip it
_edit_5:                          ;{{Addr=$2c0b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2c0b:7e}} 
        cp      $30               ;{{2c0c:fe30}}  '0'
        jr      c,_edit_11        ;{{2c0e:3807}}  (+&07)
        cp      $3a               ;{{2c10:fe3a}}  '9'+1
        call    c,_edit_39        ;{{2c12:dc422c}} 
        jr      c,_edit_5         ;{{2c15:38f4}} 

;;--------------------------------------------------------------------
;; all other characters
_edit_11:                         ;{{Addr=$2c17 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{2c17:78}} 
        or      a                 ;{{2c18:b7}} 
;; zero flag set if start of buffer, zero flag clear if not start of buffer

        ld      a,(hl)            ;{{2c19:7e}} 
        call    nz,_edit_39       ;{{2c1a:c4422c}} 

        push    hl                ;{{2c1d:e5}} 
_edit_16:                         ;{{Addr=$2c1e Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{2c1e:0c}} 
        ld      a,(hl)            ;{{2c1f:7e}} 
        inc     hl                ;{{2c20:23}} 
        or      a                 ;{{2c21:b7}} 
        jr      nz,_edit_16       ;{{2c22:20fa}}  (-&06)

        ld      (insert_overwrite_mode_flag),a;{{2c24:3215b1}}  insert/overwrite mode
        pop     hl                ;{{2c27:e1}} 
        call    x2ee4_code        ;{{2c28:cde42e}} 


_edit_24:                         ;{{Addr=$2c2b Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2c2b:c5}} 
        push    hl                ;{{2c2c:e5}} 
        call    x2f56_code        ;{{2c2d:cd562f}} 
        pop     hl                ;{{2c30:e1}} 
        pop     bc                ;{{2c31:c1}} 
        call    _edit_43          ;{{2c32:cd482c}}  process key
        jr      nc,_edit_24       ;{{2c35:30f4}}  (-&0c)

        push    af                ;{{2c37:f5}} 
        call    _shift_key__left_cursor_pressed_23;{{2c38:cd4f2e}} 
        pop     af                ;{{2c3b:f1}} 
        pop     hl                ;{{2c3c:e1}} 
        pop     de                ;{{2c3d:d1}} 
        pop     bc                ;{{2c3e:c1}} 
        cp      $fc               ;{{2c3f:fefc}} 
        ret                       ;{{2c41:c9}} 

;;--------------------------------------------------------------------
;; used to skip characters in input buffer

_edit_39:                         ;{{Addr=$2c42 Code Calls/jump count: 2 Data use count: 0}}
        inc     c                 ;{{2c42:0c}} 
        inc     b                 ;{{2c43:04}}  increment pos
        inc     hl                ;{{2c44:23}}  increment position in buffer
        jp      x2f25_code        ;{{2c45:c3252f}} 

;;--------------------------------------------------------------------

_edit_43:                         ;{{Addr=$2c48 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{2c48:e5}} 
        ld      hl,keys_for_editing_an_existing_line;{{2c49:21722c}} 
        ld      e,a               ;{{2c4c:5f}} 
        ld      a,b               ;{{2c4d:78}} 
        or      c                 ;{{2c4e:b1}} 
        ld      a,e               ;{{2c4f:7b}} 
        jr      nz,_edit_55       ;{{2c50:200b}}  (+&0b)

        cp      $f0               ;{{2c52:fef0}} 
        jr      c,_edit_55        ;{{2c54:3807}}  (+&07)
        cp      $f4               ;{{2c56:fef4}} 
        jr      nc,_edit_55       ;{{2c58:3003}}  (+&03)

;; cursor keys
        ld      hl,keys_for_moving_cursor;{{2c5a:21ae2c}} 

;;--------------------------------------------------------------------
_edit_55:                         ;{{Addr=$2c5d Code Calls/jump count: 3 Data use count: 0}}
        ld      d,(hl)            ;{{2c5d:56}} 
        inc     hl                ;{{2c5e:23}} 
        push    hl                ;{{2c5f:e5}} 
_edit_58:                         ;{{Addr=$2c60 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{2c60:23}} 
        inc     hl                ;{{2c61:23}} 
        cp      (hl)              ;{{2c62:be}} 
        inc     hl                ;{{2c63:23}} 
        jr      z,_edit_66        ;{{2c64:2804}}  (+&04)
        dec     d                 ;{{2c66:15}} 
        jr      nz,_edit_58       ;{{2c67:20f7}}  (-&09)
        ex      (sp),hl           ;{{2c69:e3}} 
_edit_66:                         ;{{Addr=$2c6a Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{2c6a:f1}} 
        ld      a,(hl)            ;{{2c6b:7e}} 
        inc     hl                ;{{2c6c:23}} 
        ld      h,(hl)            ;{{2c6d:66}} 
        ld      l,a               ;{{2c6e:6f}} 
        ld      a,e               ;{{2c6f:7b}} 
        ex      (sp),hl           ;{{2c70:e3}} 
        ret                       ;{{2c71:c9}} 

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
        ld      a,$0b             ;{{2cbd:3e0b}}  VT (Move cursor up a line)
        jr      _left_cursor_key_pressed_1;{{2cbf:180a}}  

;;+--------------------------------------------------------------------
;; down cursor key pressed
down_cursor_key_pressed:          ;{{Addr=$2cc1 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,$0a             ;{{2cc1:3e0a}}  LF (Move cursor down a line)
        jr      _left_cursor_key_pressed_1;{{2cc3:1806}} 

;;+--------------------------------------------------------------------
;; right cursor key pressed
right_cursor_key_pressed:         ;{{Addr=$2cc5 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$09             ;{{2cc5:3e09}}  TAB (Move cursor forward one character)
        jr      _left_cursor_key_pressed_1;{{2cc7:1802}}  

;;+--------------------------------------------------------------------
;; left cursor key pressed
left_cursor_key_pressed:          ;{{Addr=$2cc9 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$08             ;{{2cc9:3e08}}  BS (Move character back one character)

;;--------------------------------------------------------------------

_left_cursor_key_pressed_1:       ;{{Addr=$2ccb Code Calls/jump count: 4 Data use count: 0}}
        call    TXT_OUTPUT        ;{{2ccb:cdfe13}}  TXT OUTPUT

;;===========================================================================================
;;edit for key ef
edit_for_key_ef:                  ;{{Addr=$2cce Code Calls/jump count: 0 Data use count: 1}}
        or      a                 ;{{2cce:b7}} 
        ret                       ;{{2ccf:c9}} 

;;===========================================================================================
;;edit for key fc ESC
edit_for_key_fc_ESC:              ;{{Addr=$2cd0 Code Calls/jump count: 0 Data use count: 1}}
        call    _break_message_1  ;{{2cd0:cdf22c}}  display message
        push    af                ;{{2cd3:f5}} 
        ld      hl,Break_message  ;{{2cd4:21ea2c}}  "*Break*"
        call    _break_message_1  ;{{2cd7:cdf22c}}  display message

        call    TXT_GET_CURSOR    ;{{2cda:cd7c11}}  TXT GET CURSOR
        dec     h                 ;{{2cdd:25}} 
        jr      z,_edit_for_key_fc_esc_10;{{2cde:2808}} 

;; go to next line
        ld      a,$0d             ;{{2ce0:3e0d}}  CR (Move cursor to left edge of window on current line)
        call    TXT_OUTPUT        ;{{2ce2:cdfe13}}  TXT OUTPUT
        call    down_cursor_key_pressed;{{2ce5:cdc12c}}  Move cursor down a line

_edit_for_key_fc_esc_10:          ;{{Addr=$2ce8 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{2ce8:f1}} 
        ret                       ;{{2ce9:c9}} 

;;+--------------------------------------------------------------------
;;Break message
Break_message:                    ;{{Addr=$2cea Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "*Break*",0          

;;--------------------------------------------------------------------
;; display 0 terminated string

_break_message_1:                 ;{{Addr=$2cf2 Code Calls/jump count: 2 Data use count: 1}}
        push af                   ;{{2cf2:f5}} 
_break_message_2:                 ;{{Addr=$2cf3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2cf3:7e}}  get character
        inc     hl                ;{{2cf4:23}} 
        or      a                 ;{{2cf5:b7}}  end of string marker?
        call    nz,x2f25_code     ;{{2cf6:c4252f}}  display character
        jr      nz,_break_message_2;{{2cf9:20f8}}  loop for next character
        pop     af                ;{{2cfb:f1}} 
        scf                       ;{{2cfc:37}} 
        ret                       ;{{2cfd:c9}} 

;;===========================================================================
;;edit sound bleeper
edit_sound_bleeper:               ;{{Addr=$2cfe Code Calls/jump count: 8 Data use count: 1}}
        ld      a,$07             ;{{2cfe:3e07}}  BEL (Sound bleeper)
        jr      _left_cursor_key_pressed_1;{{2d00:18c9}} 

;;===========================================================================
;; right cursor key pressed
right_cursor_key_pressed_B:       ;{{Addr=$2d02 Code Calls/jump count: 0 Data use count: 1}}
        ld      d,$01             ;{{2d02:1601}} 
        call    _ctrl_key__down_cursor_key_pressed_1;{{2d04:cd1e2d}} 
        jr      z,edit_sound_bleeper;{{2d07:28f5}}  (-&0b)
        ret                       ;{{2d09:c9}} 

;;===========================================================================
;; down cursor key pressed

down_cursor_key_pressed_B:        ;{{Addr=$2d0a Code Calls/jump count: 0 Data use count: 1}}
        call    x2d73_code        ;{{2d0a:cd732d}} 
        ld      a,c               ;{{2d0d:79}} 
        sub     b                 ;{{2d0e:90}} 
        cp      d                 ;{{2d0f:ba}} 
        jr      c,edit_sound_bleeper;{{2d10:38ec}}  (-&14)
        jr      _ctrl_key__down_cursor_key_pressed_1;{{2d12:180a}}  (+&0a)

;;===========================================================================================
;; CTRL key + right cursor key pressed
;; 
;; go to end of current line
CTRL_key__right_cursor_key_pressed:;{{Addr=$2d14 Code Calls/jump count: 0 Data use count: 1}}
        call    x2d73_code        ;{{2d14:cd732d}} 
        ld      a,d               ;{{2d17:7a}} 
        sub     e                 ;{{2d18:93}} 
        ret     z                 ;{{2d19:c8}} 

        ld      d,a               ;{{2d1a:57}} 
        jr      _ctrl_key__down_cursor_key_pressed_1;{{2d1b:1801}}  (+&01)

;;===========================================================================================
;; CTRL key + down cursor key pressed
;;
;; go to end of text 

CTRL_key__down_cursor_key_pressed:;{{Addr=$2d1d Code Calls/jump count: 0 Data use count: 1}}
        ld      d,c               ;{{2d1d:51}} 

;;--------------------------------------------------------------------

_ctrl_key__down_cursor_key_pressed_1:;{{Addr=$2d1e Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{2d1e:78}} 
        cp      c                 ;{{2d1f:b9}} 
        ret     z                 ;{{2d20:c8}} 

        push    de                ;{{2d21:d5}} 
        call    try_to_move_cursor_right;{{2d22:cdcd2e}} 
        ld      a,(hl)            ;{{2d25:7e}} 
        call    nc,x2f25_code     ;{{2d26:d4252f}} 
        inc     b                 ;{{2d29:04}} 
        inc     hl                ;{{2d2a:23}} 
        call    nc,x2ee4_code     ;{{2d2b:d4e42e}} 
        pop     de                ;{{2d2e:d1}} 
        dec     d                 ;{{2d2f:15}} 
        jr      nz,_ctrl_key__down_cursor_key_pressed_1;{{2d30:20ec}}  (-&14)
        jr      x2d70_code        ;{{2d32:183c}}  (+&3c)

;;===========================================================================
;; left cursor key pressed
left_cursor_key_pressed_B:        ;{{Addr=$2d34 Code Calls/jump count: 0 Data use count: 1}}
        ld      d,$01             ;{{2d34:1601}} 
        call    _ctrl_key__up_cursor_key_pressed_1;{{2d36:cd502d}} 
        jr      z,edit_sound_bleeper;{{2d39:28c3}}  (-&3d)
        ret                       ;{{2d3b:c9}} 


;;===========================================================================
;; up cursor key pressed
up_cursor_key_pressed_B:          ;{{Addr=$2d3c Code Calls/jump count: 0 Data use count: 1}}
        call    x2d73_code        ;{{2d3c:cd732d}} 
        ld      a,b               ;{{2d3f:78}} 
        cp      d                 ;{{2d40:ba}} 
        jr      c,edit_sound_bleeper;{{2d41:38bb}}  (-&45)
        jr      _ctrl_key__up_cursor_key_pressed_1;{{2d43:180b}}  (+&0b)


;;===========================================================================
;; CTRL key + left cursor key pressed
;;
;; go to start of current line

CTRL_key__left_cursor_key_pressed:;{{Addr=$2d45 Code Calls/jump count: 0 Data use count: 1}}
        call    x2d73_code        ;{{2d45:cd732d}} 
        ld      a,e               ;{{2d48:7b}} 
        sub     $01               ;{{2d49:d601}} 
        ret     z                 ;{{2d4b:c8}} 

        ld      d,a               ;{{2d4c:57}} 
        jr      _ctrl_key__up_cursor_key_pressed_1;{{2d4d:1801}}  (+&01)

;;===========================================================================
;; CTRL key + up cursor key pressed

;; go to start of text

CTRL_key__up_cursor_key_pressed:  ;{{Addr=$2d4f Code Calls/jump count: 0 Data use count: 1}}
        ld      d,c               ;{{2d4f:51}} 

_ctrl_key__up_cursor_key_pressed_1:;{{Addr=$2d50 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{2d50:78}} 
        or      a                 ;{{2d51:b7}} 
        ret     z                 ;{{2d52:c8}} 

        call    try_to_move_cursor_left;{{2d53:cdc72e}} 
        jr      nc,x2d5f_code     ;{{2d56:3007}}  (+&07)
        dec     b                 ;{{2d58:05}} 
        dec     hl                ;{{2d59:2b}} 
        dec     d                 ;{{2d5a:15}} 
        jr      nz,_ctrl_key__up_cursor_key_pressed_1;{{2d5b:20f3}}  (-&0d)
        jr      x2d70_code        ;{{2d5d:1811}}  (+&11)

;;===========================================================================
x2d5f_code:                       ;{{Addr=$2d5f Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{2d5f:78}} 
        or      a                 ;{{2d60:b7}} 
        jr      z,x2d6d_code      ;{{2d61:280a}}  (+&0a)
        dec     b                 ;{{2d63:05}} 
        dec     hl                ;{{2d64:2b}} 
        push    de                ;{{2d65:d5}} 
        call    _copy_key_pressed_29;{{2d66:cda22e}} 
        pop     de                ;{{2d69:d1}} 
        dec     d                 ;{{2d6a:15}} 
        jr      nz,x2d5f_code     ;{{2d6b:20f2}}  (-&0e)
x2d6d_code:                       ;{{Addr=$2d6d Code Calls/jump count: 1 Data use count: 0}}
        call    x2ee4_code        ;{{2d6d:cde42e}} 
x2d70_code:                       ;{{Addr=$2d70 Code Calls/jump count: 2 Data use count: 0}}
        or      $ff               ;{{2d70:f6ff}} 
        ret                       ;{{2d72:c9}} 

;;--------------------------------------------------------------------
x2d73_code:                       ;{{Addr=$2d73 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{2d73:e5}} 
        call    TXT_GET_WINDOW    ;{{2d74:cd5212}}  TXT GET WINDOW
        ld      a,d               ;{{2d77:7a}} 
        sub     h                 ;{{2d78:94}} 
        inc     a                 ;{{2d79:3c}} 
        ld      d,a               ;{{2d7a:57}} 
        call    TXT_GET_CURSOR    ;{{2d7b:cd7c11}}  TXT GET CURSOR
        ld      e,h               ;{{2d7e:5c}} 
        pop     hl                ;{{2d7f:e1}} 
        ret                       ;{{2d80:c9}} 
;;===========================================================================================
;; CTRL key + TAB key
;; 
;; toggle insert/overwrite mode
CTRL_key__TAB_key:                ;{{Addr=$2d81 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(insert_overwrite_mode_flag);{{2d81:3a15b1}}  insert/overwrite mode
        cpl                       ;{{2d84:2f}} 
        ld      (insert_overwrite_mode_flag),a;{{2d85:3215b1}} 
        or      a                 ;{{2d88:b7}} 
        ret                       ;{{2d89:c9}} 

;;===========================================================================================
;;edit for key 13
edit_for_key_13:                  ;{{Addr=$2d8a Code Calls/jump count: 1 Data use count: 1}}
        or      a                 ;{{2d8a:b7}} 
        ret     z                 ;{{2d8b:c8}} 

        ld      e,a               ;{{2d8c:5f}} 
        ld      a,(insert_overwrite_mode_flag);{{2d8d:3a15b1}}  insert/overwrite mode
        or      a                 ;{{2d90:b7}} 
        ld      a,c               ;{{2d91:79}} 
        jr      z,_edit_for_key_13_15;{{2d92:280b}}  (+&0b)
        cp      b                 ;{{2d94:b8}} 
        jr      z,_edit_for_key_13_15;{{2d95:2808}}  (+&08)
        ld      (hl),e            ;{{2d97:73}} 
        inc     hl                ;{{2d98:23}} 
        inc     b                 ;{{2d99:04}} 
        or      a                 ;{{2d9a:b7}} 
_edit_for_key_13_13:              ;{{Addr=$2d9b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{2d9b:7b}} 
        jp      x2f25_code        ;{{2d9c:c3252f}} 

_edit_for_key_13_15:              ;{{Addr=$2d9f Code Calls/jump count: 2 Data use count: 0}}
        cp      $ff               ;{{2d9f:feff}} 
        jp      z,edit_sound_bleeper;{{2da1:cafe2c}} 
        xor     a                 ;{{2da4:af}} 
        ld      (RAM_b114),a      ;{{2da5:3214b1}} 
        call    _edit_for_key_13_13;{{2da8:cd9b2d}} 
        inc     c                 ;{{2dab:0c}} 
        push    hl                ;{{2dac:e5}} 
_edit_for_key_13_22:              ;{{Addr=$2dad Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2dad:7e}} 
        ld      (hl),e            ;{{2dae:73}} 
        ld      e,a               ;{{2daf:5f}} 
        inc     hl                ;{{2db0:23}} 
        or      a                 ;{{2db1:b7}} 
        jr      nz,_edit_for_key_13_22;{{2db2:20f9}}  (-&07)
        ld      (hl),a            ;{{2db4:77}} 
        pop     hl                ;{{2db5:e1}} 
        inc     b                 ;{{2db6:04}} 
        inc     hl                ;{{2db7:23}} 
        call    x2ee4_code        ;{{2db8:cde42e}} 
        ld      a,(RAM_b114)      ;{{2dbb:3a14b1}} 
        or      a                 ;{{2dbe:b7}} 
        call    nz,_copy_key_pressed_29;{{2dbf:c4a22e}} 
        ret                       ;{{2dc2:c9}} 

;;===========================================================================================
;; ESC key pressed
ESC_key_pressed:                  ;{{Addr=$2dc3 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,b               ;{{2dc3:78}} 
        or      a                 ;{{2dc4:b7}} 
        call    nz,try_to_move_cursor_left;{{2dc5:c4c72e}} 
        jp      nc,edit_sound_bleeper;{{2dc8:d2fe2c}} 
        dec     b                 ;{{2dcb:05}} 
        dec     hl                ;{{2dcc:2b}} 

;;===========================================================================================
;; CLR key pressed
CLR_key_pressed:                  ;{{Addr=$2dcd Code Calls/jump count: 0 Data use count: 1}}
        ld      a,b               ;{{2dcd:78}} 
        cp      c                 ;{{2dce:b9}} 
        jp      z,edit_sound_bleeper;{{2dcf:cafe2c}} 
        push    hl                ;{{2dd2:e5}} 
_clr_key_pressed_4:               ;{{Addr=$2dd3 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{2dd3:23}} 
        ld      a,(hl)            ;{{2dd4:7e}} 
        dec     hl                ;{{2dd5:2b}} 
        ld      (hl),a            ;{{2dd6:77}} 
        inc     hl                ;{{2dd7:23}} 
        or      a                 ;{{2dd8:b7}} 
        jr      nz,_clr_key_pressed_4;{{2dd9:20f8}}  (-&08)
        dec     hl                ;{{2ddb:2b}} 
        ld      (hl),$20          ;{{2ddc:3620}} 
        ld      (RAM_b114),a      ;{{2dde:3214b1}} 
        ex      (sp),hl           ;{{2de1:e3}} 
        call    x2ee4_code        ;{{2de2:cde42e}} 
        ex      (sp),hl           ;{{2de5:e3}} 
        ld      (hl),$00          ;{{2de6:3600}} 
        pop     hl                ;{{2de8:e1}} 
        dec     c                 ;{{2de9:0d}} 
        ld      a,(RAM_b114)      ;{{2dea:3a14b1}} 
        or      a                 ;{{2ded:b7}} 
        call    nz,_copy_key_pressed_31;{{2dee:c4a62e}} 
        ret                       ;{{2df1:c9}} 


;;===========================================================================================
;; initialise relative copy cursor position to origin
initialise_relative_copy_cursor_position_to_origin:;{{Addr=$2df2 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{2df2:af}} 
        ld      (copy_cursor_rel_to_origin),a;{{2df3:3216b1}} 
        ld      (copy_cursor_Y_rel_to_origin_),a;{{2df6:3217b1}} 
        ret                       ;{{2df9:c9}} 

;;===========================================================================================
;; compare copy cursor relative position
;; HL = cursor position
compare_copy_cursor_relative_position:;{{Addr=$2dfa Code Calls/jump count: 2 Data use count: 0}}
        ld      de,(copy_cursor_rel_to_origin);{{2dfa:ed5b16b1}} 
        ld      a,h               ;{{2dfe:7c}} 
        xor     d                 ;{{2dff:aa}} 
        ret     nz                ;{{2e00:c0}} 
        ld      a,l               ;{{2e01:7d}} 
        xor     e                 ;{{2e02:ab}} 
        ret     nz                ;{{2e03:c0}} 
        scf                       ;{{2e04:37}} 
        ret                       ;{{2e05:c9}} 
;;--------------------------------------------------------------------

_compare_copy_cursor_relative_position_9:;{{Addr=$2e06 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{2e06:4f}} 
        call    get_copy_cursor_position;{{2e07:cdc12e}}  get copy cursor position
        ret     z                 ;{{2e0a:c8}}  quit if not active

;; adjust y position
        ld      a,l               ;{{2e0b:7d}} 
        add     a,c               ;{{2e0c:81}} 
        ld      l,a               ;{{2e0d:6f}} 

;; validate new position
_compare_copy_cursor_relative_position_15:;{{Addr=$2e0e Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_VALIDATE      ;{{2e0e:cdca11}}  TXT VALIDATE
        jr      nc,initialise_relative_copy_cursor_position_to_origin;{{2e11:30df}}  reset relative cursor pos

;; set cursor position
        ld      (copy_cursor_rel_to_origin),hl;{{2e13:2216b1}} 
        ret                       ;{{2e16:c9}} 

;;===========================================================================================
;; SHIFT key + left cursor key
;; 
;; move copy cursor left
SHIFT_key__left_cursor_key:       ;{{Addr=$2e17 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0100          ;{{2e17:110001}} ##LIT##;WARNING: Code area used as literal
        jr      _shift_key__left_cursor_pressed_1;{{2e1a:180d}}  (+&0d)
;;===========================================================================================
;; SHIFT key + right cursor pressed
;; 
;; move copy cursor right
SHIFT_key__right_cursor_pressed:  ;{{Addr=$2e1c Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$ff00          ;{{2e1c:1100ff}} 
        jr      _shift_key__left_cursor_pressed_1;{{2e1f:1808}}  (+&08)
;;===========================================================================================
;; SHIFT key + up cursor pressed
;;
;; move copy cursor up
SHIFT_key__up_cursor_pressed:     ;{{Addr=$2e21 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$00ff          ;{{2e21:11ff00}} ##LIT##;WARNING: Code area used as literal
        jr      _shift_key__left_cursor_pressed_1;{{2e24:1803}}  (+&03)
;;===========================================================================================
;; SHIFT key + left cursor pressed
;;
;; move copy cursor down
SHIFT_key__left_cursor_pressed:   ;{{Addr=$2e26 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0001          ;{{2e26:110100}} ##LIT##;WARNING: Code area used as literal

;;--------------------------------------------------------------------
;; D = column increment
;; E = row increment
_shift_key__left_cursor_pressed_1:;{{Addr=$2e29 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{2e29:c5}} 
        push    hl                ;{{2e2a:e5}} 
        call    get_copy_cursor_position;{{2e2b:cdc12e}}  get copy cursor position

;; get cursor position
        call    z,TXT_GET_CURSOR  ;{{2e2e:cc7c11}}  TXT GET CURSOR

;; adjust cursor position

;; adjust column
        ld      a,h               ;{{2e31:7c}} 
        add     a,d               ;{{2e32:82}} 
        ld      h,a               ;{{2e33:67}} 

;; adjust row
        ld      a,l               ;{{2e34:7d}} 
        add     a,e               ;{{2e35:83}} 
        ld      l,a               ;{{2e36:6f}} 
;; validate the position
        call    TXT_VALIDATE      ;{{2e37:cdca11}}  TXT VALIDATE
        jr      nc,_shift_key__left_cursor_pressed_18;{{2e3a:300b}}  position invalid?

;; position is valid

        push    hl                ;{{2e3c:e5}} 
        call    _shift_key__left_cursor_pressed_23;{{2e3d:cd4f2e}} 
        pop     hl                ;{{2e40:e1}} 

;; store new position
        ld      (copy_cursor_rel_to_origin),hl;{{2e41:2216b1}} 

        call    _shift_key__left_cursor_pressed_21;{{2e44:cd4a2e}} 

;;----------------

_shift_key__left_cursor_pressed_18:;{{Addr=$2e47 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2e47:e1}} 
        pop     bc                ;{{2e48:c1}} 
        ret                       ;{{2e49:c9}} 

;;--------------------------------------------------------------------

_shift_key__left_cursor_pressed_21:;{{Addr=$2e4a Code Calls/jump count: 4 Data use count: 0}}
        ld      de,TXT_PLACE_CURSOR;{{2e4a:116512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR ##LABEL##
        jr      _shift_key__left_cursor_pressed_24;{{2e4d:1803}} 

;;--------------------------------------------------------------------
_shift_key__left_cursor_pressed_23:;{{Addr=$2e4f Code Calls/jump count: 4 Data use count: 0}}
        ld      de,TXT_PLACE_CURSOR;{{2e4f:116512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR ##LABEL##

;;--------------------------------------------------------------------
_shift_key__left_cursor_pressed_24:;{{Addr=$2e52 Code Calls/jump count: 1 Data use count: 0}}
        call    get_copy_cursor_position;{{2e52:cdc12e}}  get copy cursor position
        ret     z                 ;{{2e55:c8}} 

        push    hl                ;{{2e56:e5}} 
        call    TXT_GET_CURSOR    ;{{2e57:cd7c11}}  TXT GET CURSOR
        ex      (sp),hl           ;{{2e5a:e3}} 
        call    TXT_SET_CURSOR    ;{{2e5b:cd7011}}  TXT SET CURSOR
        call    LOW_PCDE_INSTRUCTION;{{2e5e:cd1600}}  LOW: PCDE INSTRUCTION
        pop     hl                ;{{2e61:e1}} 
        jp      TXT_SET_CURSOR    ;{{2e62:c37011}}  TXT SET CURSOR
;;===========================================================================================
;; COPY key pressed
COPY_key_pressed:                 ;{{Addr=$2e65 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2e65:c5}} 
        push    hl                ;{{2e66:e5}} 
        call    TXT_GET_CURSOR    ;{{2e67:cd7c11}}  TXT GET CURSOR
        ex      de,hl             ;{{2e6a:eb}} 
        call    get_copy_cursor_position;{{2e6b:cdc12e}} 
        jr      nz,_copy_key_pressed_12;{{2e6e:200c}}  perform copy
        ld      a,b               ;{{2e70:78}} 
        or      c                 ;{{2e71:b1}} 
        jr      nz,_copy_key_pressed_25;{{2e72:2026}}  (+&26)
        call    TXT_GET_CURSOR    ;{{2e74:cd7c11}}  TXT GET CURSOR
        ld      (copy_cursor_rel_to_origin),hl;{{2e77:2216b1}} 
        jr      _copy_key_pressed_14;{{2e7a:1806}}  (+&06)

;;--------------------------------------------------------------------

_copy_key_pressed_12:             ;{{Addr=$2e7c Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_SET_CURSOR    ;{{2e7c:cd7011}}  TXT SET CURSOR
        call    TXT_PLACE_CURSOR  ;{{2e7f:cd6512}}  TXT PLACE CURSOR/TXT REMOVE CURSOR

_copy_key_pressed_14:             ;{{Addr=$2e82 Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_RD_CHAR       ;{{2e82:cdac13}}  TXT RD CHAR
        push    af                ;{{2e85:f5}} 
        ex      de,hl             ;{{2e86:eb}} 
        call    TXT_SET_CURSOR    ;{{2e87:cd7011}}  TXT SET CURSOR
        ld      hl,(copy_cursor_rel_to_origin);{{2e8a:2a16b1}} 
        inc     h                 ;{{2e8d:24}} 
        call    TXT_VALIDATE      ;{{2e8e:cdca11}}  TXT VALIDATE
        jr      nc,_copy_key_pressed_23;{{2e91:3003}}  (+&03)
        ld      (copy_cursor_rel_to_origin),hl;{{2e93:2216b1}} 
_copy_key_pressed_23:             ;{{Addr=$2e96 Code Calls/jump count: 1 Data use count: 0}}
        call    _shift_key__left_cursor_pressed_21;{{2e96:cd4a2e}} 
        pop     af                ;{{2e99:f1}} 
_copy_key_pressed_25:             ;{{Addr=$2e9a Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2e9a:e1}} 
        pop     bc                ;{{2e9b:c1}} 
        jp      c,edit_for_key_13 ;{{2e9c:da8a2d}} 
        jp      edit_sound_bleeper;{{2e9f:c3fe2c}} 

;;--------------------------------------------------------------------

_copy_key_pressed_29:             ;{{Addr=$2ea2 Code Calls/jump count: 2 Data use count: 0}}
        ld      d,$01             ;{{2ea2:1601}} 
        jr      _copy_key_pressed_32;{{2ea4:1802}}  (+&02)

;;--------------------------------------------------------------------

_copy_key_pressed_31:             ;{{Addr=$2ea6 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,$ff             ;{{2ea6:16ff}} 
;;--------------------------------------------------------------------
_copy_key_pressed_32:             ;{{Addr=$2ea8 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2ea8:c5}} 
        push    hl                ;{{2ea9:e5}} 
        push    de                ;{{2eaa:d5}} 
        call    _shift_key__left_cursor_pressed_23;{{2eab:cd4f2e}} 
        pop     de                ;{{2eae:d1}} 
        call    get_copy_cursor_position;{{2eaf:cdc12e}} 
        jr      z,_copy_key_pressed_44;{{2eb2:2809}}  (+&09)
        ld      a,h               ;{{2eb4:7c}} 
        add     a,d               ;{{2eb5:82}} 
        ld      h,a               ;{{2eb6:67}} 
        call    _compare_copy_cursor_relative_position_15;{{2eb7:cd0e2e}} 
        call    _shift_key__left_cursor_pressed_21;{{2eba:cd4a2e}} 
_copy_key_pressed_44:             ;{{Addr=$2ebd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2ebd:e1}} 
        pop     bc                ;{{2ebe:c1}} 
        or      a                 ;{{2ebf:b7}} 
        ret                       ;{{2ec0:c9}} 

;;===========================================================================================
;; get copy cursor position
;; this is relative to the actual cursor pos
;;
;; zero flag set if cursor is not active
get_copy_cursor_position:         ;{{Addr=$2ec1 Code Calls/jump count: 5 Data use count: 0}}
        ld      hl,(copy_cursor_rel_to_origin);{{2ec1:2a16b1}} 
        ld      a,h               ;{{2ec4:7c}} 
        or      l                 ;{{2ec5:b5}} 
        ret                       ;{{2ec6:c9}} 
;;===========================================================================================
;; try to move cursor left?
try_to_move_cursor_left:          ;{{Addr=$2ec7 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{2ec7:d5}} 
        ld      de,$ff08          ;{{2ec8:1108ff}} 
        jr      _try_to_move_cursor_right_2;{{2ecb:1804}}  (+&04)

;;===========================================================================================
;; try to move cursor right?
try_to_move_cursor_right:         ;{{Addr=$2ecd Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{2ecd:d5}} 
        ld      de,$0109          ;{{2ece:110901}} ##LIT##;WARNING: Code area used as literal
;;--------------------------------------------------------------------
;; D = column increment
;; E = character to plot
_try_to_move_cursor_right_2:      ;{{Addr=$2ed1 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2ed1:c5}} 
        push    hl                ;{{2ed2:e5}} 

;; get current cursor position
        call    TXT_GET_CURSOR    ;{{2ed3:cd7c11}}  TXT GET CURSOR

;; adjust cursor position
        ld      a,d               ;{{2ed6:7a}}  column increment
        add     a,h               ;{{2ed7:84}}  add on column
        ld      h,a               ;{{2ed8:67}}  final column

;; validate this new position
        call    TXT_VALIDATE      ;{{2ed9:cdca11}}  TXT VALIDATE

;; if valid then output character, otherwise report error
        ld      a,e               ;{{2edc:7b}} 
        call    c,TXT_OUTPUT      ;{{2edd:dcfe13}}  TXT OUTPUT

        pop     hl                ;{{2ee0:e1}} 
        pop     bc                ;{{2ee1:c1}} 
        pop     de                ;{{2ee2:d1}} 
        ret                       ;{{2ee3:c9}} 

;;===========================================================================================
x2ee4_code:                       ;{{Addr=$2ee4 Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{2ee4:c5}} 
        push    hl                ;{{2ee5:e5}} 
        ex      de,hl             ;{{2ee6:eb}} 
        call    TXT_GET_CURSOR    ;{{2ee7:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2eea:4f}} 
        ex      de,hl             ;{{2eeb:eb}} 
x2eec_code:                       ;{{Addr=$2eec Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{2eec:7e}} 
        inc     hl                ;{{2eed:23}} 
        or      a                 ;{{2eee:b7}} 
        call    nz,x2f02_code     ;{{2eef:c4022f}} 
        jr      nz,x2eec_code     ;{{2ef2:20f8}}  (-&08)
        call    TXT_GET_CURSOR    ;{{2ef4:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2ef7:91}} 
        ex      de,hl             ;{{2ef8:eb}} 
        add     a,l               ;{{2ef9:85}} 
        ld      l,a               ;{{2efa:6f}} 
        call    TXT_SET_CURSOR    ;{{2efb:cd7011}}  TXT SET CURSOR
        pop     hl                ;{{2efe:e1}} 
        pop     bc                ;{{2eff:c1}} 
        or      a                 ;{{2f00:b7}} 
        ret                       ;{{2f01:c9}} 

x2f02_code:                       ;{{Addr=$2f02 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{2f02:f5}} 
        push    bc                ;{{2f03:c5}} 
        push    de                ;{{2f04:d5}} 
        push    hl                ;{{2f05:e5}} 
        ld      b,a               ;{{2f06:47}} 
        call    TXT_GET_CURSOR    ;{{2f07:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2f0a:91}} 
        add     a,e               ;{{2f0b:83}} 
        ld      e,a               ;{{2f0c:5f}} 
        ld      c,b               ;{{2f0d:48}} 
        call    TXT_VALIDATE      ;{{2f0e:cdca11}}  TXT VALIDATE
        jr      c,x2f18_code      ;{{2f11:3805}}  (+&05)
        ld      a,b               ;{{2f13:78}} 
        add     a,a               ;{{2f14:87}} 
        inc     a                 ;{{2f15:3c}} 
        add     a,e               ;{{2f16:83}} 
        ld      e,a               ;{{2f17:5f}} 
x2f18_code:                       ;{{Addr=$2f18 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2f18:eb}} 
        call    TXT_VALIDATE      ;{{2f19:cdca11}}  TXT VALIDATE
        ld      a,c               ;{{2f1c:79}} 
        call    c,x2f25_code      ;{{2f1d:dc252f}} 
        pop     hl                ;{{2f20:e1}} 
        pop     de                ;{{2f21:d1}} 
        pop     bc                ;{{2f22:c1}} 
        pop     af                ;{{2f23:f1}} 
        ret                       ;{{2f24:c9}} 

x2f25_code:                       ;{{Addr=$2f25 Code Calls/jump count: 5 Data use count: 0}}
        push    af                ;{{2f25:f5}} 
        push    bc                ;{{2f26:c5}} 
        push    de                ;{{2f27:d5}} 
        push    hl                ;{{2f28:e5}} 
        ld      b,a               ;{{2f29:47}} 
        call    TXT_GET_CURSOR    ;{{2f2a:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2f2d:4f}} 
        push    bc                ;{{2f2e:c5}} 
        call    TXT_VALIDATE      ;{{2f2f:cdca11}}  TXT VALIDATE
        pop     bc                ;{{2f32:c1}} 
        call    c,compare_copy_cursor_relative_position;{{2f33:dcfa2d}} 
        push    af                ;{{2f36:f5}} 
        call    c,_shift_key__left_cursor_pressed_23;{{2f37:dc4f2e}} 
        ld      a,b               ;{{2f3a:78}} 
        push    bc                ;{{2f3b:c5}} 
        call    TXT_WR_CHAR       ;{{2f3c:cd3513}}  TXT WR CHAR
        pop     bc                ;{{2f3f:c1}} 
        call    TXT_GET_CURSOR    ;{{2f40:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2f43:91}} 
        call    nz,_compare_copy_cursor_relative_position_9;{{2f44:c4062e}} 
        pop     af                ;{{2f47:f1}} 
        jr      nc,x2f51_code     ;{{2f48:3007}}  (+&07)
        sbc     a,a               ;{{2f4a:9f}} 
        ld      (RAM_b114),a      ;{{2f4b:3214b1}} 
        call    _shift_key__left_cursor_pressed_21;{{2f4e:cd4a2e}} 
x2f51_code:                       ;{{Addr=$2f51 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{2f51:e1}} 
        pop     de                ;{{2f52:d1}} 
        pop     bc                ;{{2f53:c1}} 
        pop     af                ;{{2f54:f1}} 
        ret                       ;{{2f55:c9}} 

x2f56_code:                       ;{{Addr=$2f56 Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_CURSOR    ;{{2f56:cd7c11}}  TXT GET CURSOR
        ld      c,a               ;{{2f59:4f}} 
        call    TXT_VALIDATE      ;{{2f5a:cdca11}}  TXT VALIDATE
        call    compare_copy_cursor_relative_position;{{2f5d:cdfa2d}} 
        jp      c,KM_WAIT_CHAR    ;{{2f60:dabf1b}}  KM WAIT CHAR
        call    TXT_CUR_ON        ;{{2f63:cd7612}}  TXT CUR ON
        call    TXT_GET_CURSOR    ;{{2f66:cd7c11}}  TXT GET CURSOR
        sub     c                 ;{{2f69:91}} 
        call    nz,_compare_copy_cursor_relative_position_9;{{2f6a:c4062e}} 
        call    KM_WAIT_CHAR      ;{{2f6d:cdbf1b}}  KM WAIT CHAR
        jp      TXT_CUR_OFF       ;{{2f70:c37e12}}  TXT CUR OFF




