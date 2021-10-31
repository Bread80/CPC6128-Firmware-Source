;; KEYBOARD ROUTINES
;;===========================================================================
;; KM INITIALISE

KM_INITIALISE:                    ;{{Addr=$1b5c Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,$1e02          ;{{1b5c:21021e}} ##LIT##;WARNING: Code area used as literal
        call    KM_SET_DELAY      ;{{1b5f:cdf61d}}  KM SET DELAY
        xor     a                 ;{{1b62:af}} 
        ld      (RAM_b655),a      ;{{1b63:3255b6}} 
        ld      h,a               ;{{1b66:67}} 
        ld      l,a               ;{{1b67:6f}} 
        ld      (Shift_lock_flag_),hl;{{1b68:2231b6}} 
        ld      bc,$ffb0          ;{{1b6b:01b0ff}} 
        ld      de,$b5d6          ;{{1b6e:11d6b5}} 
        ld      hl,RAM_b692       ;{{1b71:2192b6}} 
        ld      a,$04             ;{{1b74:3e04}} 
_km_initialise_11:                ;{{Addr=$1b76 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{1b76:eb}} 
        add     hl,bc             ;{{1b77:09}} 
        ex      de,hl             ;{{1b78:eb}} 
        ld      (hl),d            ;{{1b79:72}} 
        dec     hl                ;{{1b7a:2b}} 
        ld      (hl),e            ;{{1b7b:73}} 
        dec     hl                ;{{1b7c:2b}} 
        dec     a                 ;{{1b7d:3d}} 
        jr      nz,_km_initialise_11;{{1b7e:20f6}}  (-&0a)

;;-------------------------------------------
;; copy keyboard translation table
        ld      hl,keyboard_translation_table;{{1b80:21ef1e}} 
        ld      bc,$00fa          ;{{1b83:01fa00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1b86:edb0}} 

;;-------------------------------------------
        ld      b,$0a             ;{{1b88:060a}} 
        ld      de,Tables_used_for_key_scanning_bits_;{{1b8a:1135b6}} 
        ld      hl,complement_of_B635;{{1b8d:213fb6}} 
        xor     a                 ;{{1b90:af}} 
_km_initialise_27:                ;{{Addr=$1b91 Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{1b91:12}} 
        inc     de                ;{{1b92:13}} 
        ld      (hl),$ff          ;{{1b93:36ff}} 
        inc     hl                ;{{1b95:23}} 
        djnz    _km_initialise_27 ;{{1b96:10f9}}  (-&07)
;;-------------------------------------------

;;===========================================================================
;; KM RESET

KM_RESET:                         ;{{Addr=$1b98 Code Calls/jump count: 1 Data use count: 1}}
        call    km_reset_or_clear ;{{1b98:cd751e}} 
        call    clear_returned_key;{{1b9b:cdf81b}}  reset returned key (KM CHAR RETURN)
        ld      de,DEF_KEYs_definition_area_;{{1b9e:1190b5}} 
        ld      hl,$0098          ;{{1ba1:219800}} ##LIT##;WARNING: Code area used as literal
        call    _km_exp_buffer_4  ;{{1ba4:cd0a1c}} 

        ld      hl,_km_reset_9    ;{{1ba7:21b31b}}  table used to initialise keyboard manager indirections
        call    initialise_firmware_indirections;{{1baa:cdb40a}}  initialise keyboard manager indirections (KM TEST BREAK)
        call    initialise_firmware_indirections;{{1bad:cdb40a}}  initialise keyboard manager indirections (KM SCAN KEYS)
        jp      KM_DISARM_BREAK   ;{{1bb0:c30b1e}}  KM DISARM BREAK

_km_reset_9:                      ;{{Addr=$1bb3 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $3                   
        defw KM_TEST_BREAK        ; IND: KM TEST BREAK
        jp      IND_KM_TEST_BREAK             
                                  
        defb $3                   
        defw KM_SCAN_KEYS         ; IND: KM SCAN KEYS
        jp		IND_KM_SCAN_KEYS                 

;;===========================================================================
;; KM WAIT CHAR

KM_WAIT_CHAR:                     ;{{Addr=$1bbf Code Calls/jump count: 3 Data use count: 1}}
        call    KM_READ_CHAR      ;{{1bbf:cdc51b}}  KM READ CHAR
        jr      nc,KM_WAIT_CHAR   ;{{1bc2:30fb}} 
        ret                       ;{{1bc4:c9}} 

;;===========================================================================
;; KM READ CHAR

KM_READ_CHAR:                     ;{{Addr=$1bc5 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{1bc5:e5}} 
        ld      hl,RAM_b62a       ;{{1bc6:212ab6}}  returned char
        ld      a,(hl)            ;{{1bc9:7e}}  get char
        ld      (hl),$ff          ;{{1bca:36ff}}  reset state
        cp      (hl)              ;{{1bcc:be}}  was a char returned?
        jr      c,_km_read_char_27;{{1bcd:3827}}  a key was put back into buffer, return without expanding it

;; are we expanding?
        ld      hl,(Byte_after_end_of_DEF_KEY_area);{{1bcf:2a28b6}} 
        ld      a,h               ;{{1bd2:7c}} 
        or      a                 ;{{1bd3:b7}} 
        jr      nz,_km_read_char_19;{{1bd4:2011}}  continue expansion

_km_read_char_10:                 ;{{Addr=$1bd6 Code Calls/jump count: 1 Data use count: 0}}
        call    KM_READ_KEY       ;{{1bd6:cde11c}}  KM READ KEY
        jr      nc,_km_read_char_27;{{1bd9:301b}}  (+&1b)
        cp      $80               ;{{1bdb:fe80}} 
        jr      c,_km_read_char_27;{{1bdd:3817}}  (+&17)
        cp      $a0               ;{{1bdf:fea0}} 
        ccf                       ;{{1be1:3f}} 
        jr      c,_km_read_char_27;{{1be2:3812}}  (+&12)

;; begin expansion
        ld      h,a               ;{{1be4:67}} 
        ld      l,$00             ;{{1be5:2e00}} 

;; continue expansion
_km_read_char_19:                 ;{{Addr=$1be7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{1be7:d5}} 
        call    KM_GET_EXPAND     ;{{1be8:cdb31c}}  KM GET EXPAND
        jr      c,_km_read_char_23;{{1beb:3802}} 

;; write expansion pointer
        ld      h,$00             ;{{1bed:2600}} 
_km_read_char_23:                 ;{{Addr=$1bef Code Calls/jump count: 1 Data use count: 0}}
        inc     l                 ;{{1bef:2c}} 
        ld      (Byte_after_end_of_DEF_KEY_area),hl;{{1bf0:2228b6}} 
        pop     de                ;{{1bf3:d1}} 
        jr      nc,_km_read_char_10;{{1bf4:30e0}} 
_km_read_char_27:                 ;{{Addr=$1bf6 Code Calls/jump count: 4 Data use count: 0}}
        pop     hl                ;{{1bf6:e1}} 
        ret                       ;{{1bf7:c9}} 

;;===========================================================================
;; clear returned key
clear_returned_key:               ;{{Addr=$1bf8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$ff             ;{{1bf8:3eff}} 

;;===========================================================================
;; KM CHAR RETURN

KM_CHAR_RETURN:                   ;{{Addr=$1bfa Code Calls/jump count: 0 Data use count: 1}}
        ld      (RAM_b62a),a      ;{{1bfa:322ab6}} 
        ret                       ;{{1bfd:c9}} 

;;===========================================================================
;; KM FLUSH

KM_FLUSH:                         ;{{Addr=$1bfe Code Calls/jump count: 2 Data use count: 1}}
        call    KM_READ_CHAR      ;{{1bfe:cdc51b}}  KM READ CHAR
        jr      c,KM_FLUSH        ;{{1c01:38fb}} 
        ret                       ;{{1c03:c9}} 

;;===========================================================================
;; KM EXP BUFFER

KM_EXP_BUFFER:                    ;{{Addr=$1c04 Code Calls/jump count: 0 Data use count: 1}}
        call    _km_exp_buffer_4  ;{{1c04:cd0a1c}} 
        ccf                       ;{{1c07:3f}} 
        ei                        ;{{1c08:fb}} 
        ret                       ;{{1c09:c9}} 

;;-------------------------------------------------------------------------
_km_exp_buffer_4:                 ;{{Addr=$1c0a Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{1c0a:f3}} 
        ld      a,l               ;{{1c0b:7d}} 
        sub     $31               ;{{1c0c:d631}} 
        ld      a,h               ;{{1c0e:7c}} 
        sbc     a,$00             ;{{1c0f:de00}} 
        ret     c                 ;{{1c11:d8}} 

        add     hl,de             ;{{1c12:19}} 
        ld      (address_of_byte_after_end_of_DEF_KEY_are),hl;{{1c13:222db6}} 
        ex      de,hl             ;{{1c16:eb}} 
        ld      (address_of_DEF_KEY_area),hl;{{1c17:222bb6}} 
        ld      bc,$0a30          ;{{1c1a:01300a}} ##LIT##;WARNING: Code area used as literal
_km_exp_buffer_15:                ;{{Addr=$1c1d Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$01          ;{{1c1d:3601}} 
        inc     hl                ;{{1c1f:23}} 
        ld      (hl),c            ;{{1c20:71}} 
        inc     hl                ;{{1c21:23}} 
        inc     c                 ;{{1c22:0c}} 
        djnz    _km_exp_buffer_15 ;{{1c23:10f8}}  (-&08)
        ex      de,hl             ;{{1c25:eb}} 

        ld      hl,default_keyboard_expansion_table;{{1c26:213c1c}} ; default expansion values
        ld      c,$0a             ;{{1c29:0e0a}} 
        ldir                      ;{{1c2b:edb0}} 

        ex      de,hl             ;{{1c2d:eb}} 
        ld      b,$13             ;{{1c2e:0613}} 
        xor     a                 ;{{1c30:af}} 
_km_exp_buffer_28:                ;{{Addr=$1c31 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{1c31:77}} 
        inc     hl                ;{{1c32:23}} 
        djnz    _km_exp_buffer_28 ;{{1c33:10fc}}  (-&04)
        ld      (RAM_b62f),hl     ;{{1c35:222fb6}} 
        ld      (RAM_b629),a      ;{{1c38:3229b6}} 
        ret                       ;{{1c3b:c9}} 

;;+-------------------
;; default keyboard expansion table
default_keyboard_expansion_table: ;{{Addr=$1c3c Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $01                  
        defb "."                  
        defb $01                  
        defb 13                   
        defb $5                   
        defb "RUN",$22,13         

;;===========================================================================
;; KM SET EXPAND
KM_SET_EXPAND:                    ;{{Addr=$1c46 Code Calls/jump count: 0 Data use count: 1}}
        ld 		a,b                  ;{{1c46:78}} 
        call    keycode_above_7f_not_defineable;{{1c47:cdc31c}} 
        ret     nc                ;{{1c4a:d0}} 

        push    bc                ;{{1c4b:c5}} 
        push    de                ;{{1c4c:d5}} 
        push    hl                ;{{1c4d:e5}} 
        call    _km_set_expand_28 ;{{1c4e:cd6a1c}} 
        ccf                       ;{{1c51:3f}} 
        pop     hl                ;{{1c52:e1}} 
        pop     de                ;{{1c53:d1}} 
        pop     bc                ;{{1c54:c1}} 
        ret     nc                ;{{1c55:d0}} 

        dec     de                ;{{1c56:1b}} 
        ld      a,c               ;{{1c57:79}} 
        inc     c                 ;{{1c58:0c}} 
_km_set_expand_15:                ;{{Addr=$1c59 Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{1c59:12}} 
        inc     de                ;{{1c5a:13}} 
        rst     $20               ;{{1c5b:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{1c5c:23}} 
        dec     c                 ;{{1c5d:0d}} 
        jr      nz,_km_set_expand_15;{{1c5e:20f9}}  (-&07)
        ld      hl,RAM_b629       ;{{1c60:2129b6}} 
        ld      a,b               ;{{1c63:78}} 
        xor     (hl)              ;{{1c64:ae}} 
        jr      nz,_km_set_expand_26;{{1c65:2001}}  (+&01)
        ld      (hl),a            ;{{1c67:77}} 
_km_set_expand_26:                ;{{Addr=$1c68 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{1c68:37}} 
        ret                       ;{{1c69:c9}} 

;;---------------------------------------------------------------
_km_set_expand_28:                ;{{Addr=$1c6a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{1c6a:0600}} 
        ld      h,b               ;{{1c6c:60}} 
        ld      l,a               ;{{1c6d:6f}} 
        ld      a,c               ;{{1c6e:79}} 
        sub     l                 ;{{1c6f:95}} 
        ret     z                 ;{{1c70:c8}} 

        jr      nc,_km_set_expand_45;{{1c71:300f}}  (+&0f)
        ld      a,l               ;{{1c73:7d}} 
        ld      l,c               ;{{1c74:69}} 
        ld      c,a               ;{{1c75:4f}} 
        add     hl,de             ;{{1c76:19}} 
        ex      de,hl             ;{{1c77:eb}} 
        add     hl,bc             ;{{1c78:09}} 
        call    _km_set_expand_69 ;{{1c79:cda71c}} 
        jr      z,_km_set_expand_66;{{1c7c:2823}}  (+&23)
        ldir                      ;{{1c7e:edb0}} 
        jr      _km_set_expand_66 ;{{1c80:181f}}  (+&1f)
_km_set_expand_45:                ;{{Addr=$1c82 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{1c82:4f}} 
        add     hl,de             ;{{1c83:19}} 
        push    hl                ;{{1c84:e5}} 
        ld      hl,(RAM_b62f)     ;{{1c85:2a2fb6}} 
        add     hl,bc             ;{{1c88:09}} 
        ex      de,hl             ;{{1c89:eb}} 
        ld      hl,(address_of_byte_after_end_of_DEF_KEY_are);{{1c8a:2a2db6}} 
        ld      a,l               ;{{1c8d:7d}} 
        sub     e                 ;{{1c8e:93}} 
        ld      a,h               ;{{1c8f:7c}} 
        sbc     a,d               ;{{1c90:9a}} 
        pop     hl                ;{{1c91:e1}} 
        ret     c                 ;{{1c92:d8}} 

        call    _km_set_expand_69 ;{{1c93:cda71c}} 
        ld      hl,(RAM_b62f)     ;{{1c96:2a2fb6}} 
        jr      z,_km_set_expand_66;{{1c99:2806}}  (+&06)
        push    de                ;{{1c9b:d5}} 
        dec     de                ;{{1c9c:1b}} 
        dec     hl                ;{{1c9d:2b}} 
        lddr                      ;{{1c9e:edb8}} 
        pop     de                ;{{1ca0:d1}} 
_km_set_expand_66:                ;{{Addr=$1ca1 Code Calls/jump count: 3 Data use count: 0}}
        ld      (RAM_b62f),de     ;{{1ca1:ed532fb6}} 
        or      a                 ;{{1ca5:b7}} 
        ret                       ;{{1ca6:c9}} 

;;-----------------------------------------------------------------

_km_set_expand_69:                ;{{Addr=$1ca7 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_b62f)      ;{{1ca7:3a2fb6}} 
        sub     l                 ;{{1caa:95}} 
        ld      c,a               ;{{1cab:4f}} 
        ld      a,(RAM_b630)      ;{{1cac:3a30b6}} 
        sbc     a,h               ;{{1caf:9c}} 
        ld      b,a               ;{{1cb0:47}} 
        or      c                 ;{{1cb1:b1}} 
        ret                       ;{{1cb2:c9}} 

;;===========================================================================
;; KM GET EXPAND

KM_GET_EXPAND:                    ;{{Addr=$1cb3 Code Calls/jump count: 1 Data use count: 1}}
        call    keycode_above_7f_not_defineable;{{1cb3:cdc31c}} 
        ret     nc                ;{{1cb6:d0}} 

        cp      l                 ;{{1cb7:bd}} 
        ret     z                 ;{{1cb8:c8}} 

        ccf                       ;{{1cb9:3f}} 
        ret     nc                ;{{1cba:d0}} 

        push    hl                ;{{1cbb:e5}} 
        ld      h,$00             ;{{1cbc:2600}} 
        add     hl,de             ;{{1cbe:19}} 
        ld      a,(hl)            ;{{1cbf:7e}} 
        pop     hl                ;{{1cc0:e1}} 
        scf                       ;{{1cc1:37}} 
        ret                       ;{{1cc2:c9}} 

;;===========================================================================

;; keycode above &7f not defineable?
keycode_above_7f_not_defineable:  ;{{Addr=$1cc3 Code Calls/jump count: 2 Data use count: 0}}
        and     $7f               ;{{1cc3:e67f}} 
;; keys between &20-&7f are not defineable?
        cp      $20               ;{{1cc5:fe20}} 
        ret     nc                ;{{1cc7:d0}} 

        push    hl                ;{{1cc8:e5}} 
        ld      hl,(address_of_DEF_KEY_area);{{1cc9:2a2bb6}} 
        ld      de,$0000          ;{{1ccc:110000}} ##LIT##;WARNING: Code area used as literal
        inc     a                 ;{{1ccf:3c}} 
_keycode_above_7f_not_defineable_7:;{{Addr=$1cd0 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{1cd0:19}} 
        ld      e,(hl)            ;{{1cd1:5e}} 
        inc     hl                ;{{1cd2:23}} 
        dec     a                 ;{{1cd3:3d}} 
        jr      nz,_keycode_above_7f_not_defineable_7;{{1cd4:20fa}}  (-&06)
        ld      a,e               ;{{1cd6:7b}} 
        ex      de,hl             ;{{1cd7:eb}} 
        pop     hl                ;{{1cd8:e1}} 
        scf                       ;{{1cd9:37}} 
        ret                       ;{{1cda:c9}} 

;;===========================================================================
;; KM WAIT KEY

KM_WAIT_KEY:                      ;{{Addr=$1cdb Code Calls/jump count: 2 Data use count: 1}}
        call    KM_READ_KEY       ;{{1cdb:cde11c}}  KM READ KEY
        jr      nc,KM_WAIT_KEY    ;{{1cde:30fb}} 
        ret                       ;{{1ce0:c9}} 

;;===========================================================================
;; KM READ KEY

KM_READ_KEY:                      ;{{Addr=$1ce1 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{1ce1:e5}} 
        push    bc                ;{{1ce2:c5}} 
_km_read_key_2:                   ;{{Addr=$1ce3 Code Calls/jump count: 2 Data use count: 0}}
        call    km_unknown_function_2;{{1ce3:cd9d1e}} 
        jr      nc,_km_read_key_37;{{1ce6:303a}}  (+&3a)
        ld      a,c               ;{{1ce8:79}} 
        cp      $ef               ;{{1ce9:feef}} 
        jr      z,_km_read_key_36 ;{{1ceb:2834}}  (+&34)
        and     $0f               ;{{1ced:e60f}} 
        add     a,a               ;{{1cef:87}} 
        add     a,a               ;{{1cf0:87}} 
        add     a,a               ;{{1cf1:87}} 
        dec     a                 ;{{1cf2:3d}} 
_km_read_key_12:                  ;{{Addr=$1cf3 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{1cf3:3c}} 
        rrc     b                 ;{{1cf4:cb08}} 
        jr      nc,_km_read_key_12;{{1cf6:30fb}}  (-&05)
        call    _km_read_key_40   ;{{1cf8:cd251d}} 
        ld      hl,Caps_lock_flag_;{{1cfb:2132b6}} 
        bit     7,(hl)            ;{{1cfe:cb7e}} 
        jr      z,_km_read_key_24 ;{{1d00:280a}}  (+&0a)
        cp      $61               ;{{1d02:fe61}} 
        jr      c,_km_read_key_24 ;{{1d04:3806}}  (+&06)
        cp      $7b               ;{{1d06:fe7b}} 
        jr      nc,_km_read_key_24;{{1d08:3002}}  (+&02)
        add     a,$e0             ;{{1d0a:c6e0}} 
_km_read_key_24:                  ;{{Addr=$1d0c Code Calls/jump count: 3 Data use count: 0}}
        cp      $ff               ;{{1d0c:feff}} 
        jr      z,_km_read_key_2  ;{{1d0e:28d3}}  (-&2d)
        cp      $fe               ;{{1d10:fefe}} 
        ld      hl,Shift_lock_flag_;{{1d12:2131b6}} 
        jr      z,_km_read_key_32 ;{{1d15:2805}}  (+&05)
        cp      $fd               ;{{1d17:fefd}} 
        inc     hl                ;{{1d19:23}} 
        jr      nz,_km_read_key_36;{{1d1a:2005}}  (+&05)
_km_read_key_32:                  ;{{Addr=$1d1c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{1d1c:7e}} 
        cpl                       ;{{1d1d:2f}} 
        ld      (hl),a            ;{{1d1e:77}} 
        jr      _km_read_key_2    ;{{1d1f:18c2}}  (-&3e)
_km_read_key_36:                  ;{{Addr=$1d21 Code Calls/jump count: 2 Data use count: 0}}
        scf                       ;{{1d21:37}} 
_km_read_key_37:                  ;{{Addr=$1d22 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{1d22:c1}} 
        pop     hl                ;{{1d23:e1}} 
        ret                       ;{{1d24:c9}} 

;;-------------------------------------------------------

_km_read_key_40:                  ;{{Addr=$1d25 Code Calls/jump count: 1 Data use count: 0}}
        rl      c                 ;{{1d25:cb11}} 
        jp      c,KM_GET_CONTROL_ ;{{1d27:dace1e}}  KM GET CONTROL
        ld      b,a               ;{{1d2a:47}} 
        ld      a,(Shift_lock_flag_);{{1d2b:3a31b6}} 
        or      c                 ;{{1d2e:b1}} 
        and     $40               ;{{1d2f:e640}} 
        ld      a,b               ;{{1d31:78}} 
        jp      nz,KM_GET_SHIFT   ;{{1d32:c2c91e}}  KM GET SHIFT
        jp      KM_GET_TRANSLATE  ;{{1d35:c3c41e}}  KM GET TRANSLATE

;;===========================================================================
;; KM GET STATE

KM_GET_STATE:                     ;{{Addr=$1d38 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(Shift_lock_flag_);{{1d38:2a31b6}} 
        ret                       ;{{1d3b:c9}} 

;;===========================================================================
;; KM SET LOCKS

KM_SET_LOCKS:                     ;{{Addr=$1d3c Code Calls/jump count: 0 Data use count: 1}}
        ld      (Shift_lock_flag_),hl;{{1d3c:2231b6}} 
        ret                       ;{{1d3f:c9}} 

;;===========================================================================
;; IND: KM SCAN KEYS

IND_KM_SCAN_KEYS:                 ;{{Addr=$1d40 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$b649          ;{{1d40:1149b6}}  buffer for keys that have changed
        ld      hl,complement_of_B635;{{1d43:213fb6}}  buffer for current state of key matrix
                                  ; if a bit is '0' then key is pressed,
                                  ; if a bit is '1' then key is released.
        call    scan_keyboard     ;{{1d46:cd8308}}  scan keyboard

;;b635-b63e
;;b63f-b648
;;b649-b652 (keyboard line 0-10 inclusive)

        ld      a,(RAM_b64b)      ;{{1d49:3a4bb6}}  keyboard line 2
        and     $a0               ;{{1d4c:e6a0}}  isolate change state of CTRL and SHIFT keys
        ld      c,a               ;{{1d4e:4f}} 

        ld      hl,RAM_b637       ;{{1d4f:2137b6}} 
        or      (hl)              ;{{1d52:b6}} 
        ld      (hl),a            ;{{1d53:77}} 

;;----------------------------------------------------------------------
        ld      hl,$b649          ;{{1d54:2149b6}} 
        ld      de,Tables_used_for_key_scanning_bits_;{{1d57:1135b6}} 
        ld      b,$00             ;{{1d5a:0600}} 

_ind_km_scan_keys_12:             ;{{Addr=$1d5c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{1d5c:1a}} 
        xor     (hl)              ;{{1d5d:ae}} 
        and     (hl)              ;{{1d5e:a6}} 
        call    nz,km_scan_keys_sub;{{1d5f:c4d11d}} 
        ld      a,(hl)            ;{{1d62:7e}} 
        ld      (de),a            ;{{1d63:12}} 
        inc     hl                ;{{1d64:23}} 
        inc     de                ;{{1d65:13}} 
        inc     c                 ;{{1d66:0c}} 
        ld      a,c               ;{{1d67:79}} 
        and     $0f               ;{{1d68:e60f}} 
        cp      $0a               ;{{1d6a:fe0a}} 
        jr      nz,_ind_km_scan_keys_12;{{1d6c:20ee}}  (-&12)

;;---------------------------------------------------------------------

        ld      a,c               ;{{1d6e:79}} 
        and     $a0               ;{{1d6f:e6a0}} 
        bit     6,c               ;{{1d71:cb71}} 
        ld      c,a               ;{{1d73:4f}} 
        call    nz,KM_TEST_BREAK  ;{{1d74:c4eebd}}  IND: KM TEST BREAK
        ld      a,b               ;{{1d77:78}} 
        or      a                 ;{{1d78:b7}} 
        ret     nz                ;{{1d79:c0}} 

        ld      hl,RAM_b653       ;{{1d7a:2153b6}} 
        dec     (hl)              ;{{1d7d:35}} 
        ret     nz                ;{{1d7e:c0}} 

        ld      hl,(RAM_b654)     ;{{1d7f:2a54b6}} 
        ex      de,hl             ;{{1d82:eb}} 
        ld      b,d               ;{{1d83:42}} 
        ld      d,$00             ;{{1d84:1600}} 
        ld      hl,Tables_used_for_key_scanning_bits_;{{1d86:2135b6}} 
        add     hl,de             ;{{1d89:19}} 
        ld      a,(hl)            ;{{1d8a:7e}} 
        ld      hl,(address_of_the_KB_repeats_table);{{1d8b:2a91b6}} 
        add     hl,de             ;{{1d8e:19}} 
        and     (hl)              ;{{1d8f:a6}} 
        and     b                 ;{{1d90:a0}} 
        ret     z                 ;{{1d91:c8}} 

        ld      hl,RAM_b653       ;{{1d92:2153b6}} 
        inc     (hl)              ;{{1d95:34}} 
        ld      a,(RAM_b68a)      ;{{1d96:3a8ab6}} 
        or      a                 ;{{1d99:b7}} 
        ret     nz                ;{{1d9a:c0}} 

        ld      a,c               ;{{1d9b:79}} 
        or      e                 ;{{1d9c:b3}} 
        ld      c,a               ;{{1d9d:4f}} 
        ld      a,(KB_repeat_period_);{{1d9e:3a33b6}} 

_ind_km_scan_keys_57:             ;{{Addr=$1da1 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b653),a      ;{{1da1:3253b6}} 
        call    km_unknown_function_1;{{1da4:cd861e}} 
        ld      a,c               ;{{1da7:79}} 
        and     $0f               ;{{1da8:e60f}} 
        ld      l,a               ;{{1daa:6f}} 
        ld      h,b               ;{{1dab:60}} 
        ld      (RAM_b654),hl     ;{{1dac:2254b6}} 

        cp      $08               ;{{1daf:fe08}} 
        ret     nz                ;{{1db1:c0}} 

        bit     4,b               ;{{1db2:cb60}} 
        ret     nz                ;{{1db4:c0}} 

        set     6,c               ;{{1db5:cbf1}} 
        ret                       ;{{1db7:c9}} 

;;=====================================================================================
;; IND: KM TEST BREAK

IND_KM_TEST_BREAK:                ;{{Addr=$1db8 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b63d       ;{{1db8:213db6}} 
        bit     2,(hl)            ;{{1dbb:cb56}} 
        ret     z                 ;{{1dbd:c8}} 

        ld      a,c               ;{{1dbe:79}} 
        xor     $a0               ;{{1dbf:eea0}} 
        jr      nz,KM_BREAK_EVENT ;{{1dc1:2056}}  KM BREAK EVENT
        push    bc                ;{{1dc3:c5}} 
        inc     hl                ;{{1dc4:23}} 
        ld      b,$0a             ;{{1dc5:060a}} 
_ind_km_test_break_9:             ;{{Addr=$1dc7 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,(hl)            ;{{1dc7:8e}} 
        dec     hl                ;{{1dc8:2b}} 
        djnz    _ind_km_test_break_9;{{1dc9:10fc}}  (-&04)
        pop     bc                ;{{1dcb:c1}} 
        cp      $a4               ;{{1dcc:fea4}} 
        jr      nz,KM_BREAK_EVENT ;{{1dce:2049}}  KM BREAK EVENT

;; do reset
        rst     $00               ;{{1dd0:c7}} 

;;====================================================================
;; km scan keys sub

km_scan_keys_sub:                 ;{{Addr=$1dd1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1dd1:e5}} 
        push    de                ;{{1dd2:d5}} 
_km_scan_keys_sub_2:              ;{{Addr=$1dd3 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{1dd3:5f}} 
        cpl                       ;{{1dd4:2f}} 
        inc     a                 ;{{1dd5:3c}} 
        and     e                 ;{{1dd6:a3}} 
        ld      b,a               ;{{1dd7:47}} 
        ld      a,(KB_delay_period_);{{1dd8:3a34b6}} 
        call    _ind_km_scan_keys_57;{{1ddb:cda11d}} 
        ld      a,b               ;{{1dde:78}} 
        xor     e                 ;{{1ddf:ab}} 
        jr      nz,_km_scan_keys_sub_2;{{1de0:20f1}}  (-&0f)
        pop     de                ;{{1de2:d1}} 
        pop     hl                ;{{1de3:e1}} 
        ret                       ;{{1de4:c9}} 

;;===========================================================================
;; KM GET JOYSTICK

KM_GET_JOYSTICK:                  ;{{Addr=$1de5 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(RAM_b63b)      ;{{1de5:3a3bb6}} 
        and     $7f               ;{{1de8:e67f}} 
        ld      l,a               ;{{1dea:6f}} 
        ld      a,(RAM_b63e)      ;{{1deb:3a3eb6}} 
        and     $7f               ;{{1dee:e67f}} 
        ld      h,a               ;{{1df0:67}} 
        ret                       ;{{1df1:c9}} 

;;===========================================================================
;; KM GET DELAY

KM_GET_DELAY:                     ;{{Addr=$1df2 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(KB_repeat_period_);{{1df2:2a33b6}} 
        ret                       ;{{1df5:c9}} 

;;===========================================================================
;; KM SET DELAY

KM_SET_DELAY:                     ;{{Addr=$1df6 Code Calls/jump count: 1 Data use count: 1}}
        ld      (KB_repeat_period_),hl;{{1df6:2233b6}} 
        ret                       ;{{1df9:c9}} 

;;===========================================================================
;; KM ARM BREAK

KM_ARM_BREAK:                     ;{{Addr=$1dfa Code Calls/jump count: 0 Data use count: 1}}
        call    KM_DISARM_BREAK   ;{{1dfa:cd0b1e}}  KM DISARM BREAK
        ld      hl,event_block_for_Keyboard_handling_compr;{{1dfd:2157b6}} 
        ld      b,$40             ;{{1e00:0640}} 
        call    KL_INIT_EVENT     ;{{1e02:cdd201}}  KL INIT EVENT
        ld      a,$ff             ;{{1e05:3eff}} 
        ld      (RAM_b656),a      ;{{1e07:3256b6}} 
        ret                       ;{{1e0a:c9}} 

;;===========================================================================
;; KM DISARM BREAK

KM_DISARM_BREAK:                  ;{{Addr=$1e0b Code Calls/jump count: 2 Data use count: 1}}
        push    bc                ;{{1e0b:c5}} 
        push    de                ;{{1e0c:d5}} 
        ld      hl,RAM_b656       ;{{1e0d:2156b6}} 
        ld      (hl),$00          ;{{1e10:3600}} 
        inc     hl                ;{{1e12:23}} 
        call    KL_DEL_SYNCHRONOUS;{{1e13:cd8402}}  KL DEL SYNCHRONOUS
        pop     de                ;{{1e16:d1}} 
        pop     bc                ;{{1e17:c1}} 
        ret                       ;{{1e18:c9}} 

;;===========================================================================
;; KM BREAK EVENT

KM_BREAK_EVENT:                   ;{{Addr=$1e19 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,RAM_b656       ;{{1e19:2156b6}} 
        ld      a,(hl)            ;{{1e1c:7e}} 
        ld      (hl),$00          ;{{1e1d:3600}} 
        cp      (hl)              ;{{1e1f:be}} 
        ret     z                 ;{{1e20:c8}} 

        push    bc                ;{{1e21:c5}} 
        push    de                ;{{1e22:d5}} 
        inc     hl                ;{{1e23:23}} 
        call    KL_EVENT          ;{{1e24:cde201}}  KL EVENT
        ld      c,$ef             ;{{1e27:0eef}} 
        call    km_unknown_function_1;{{1e29:cd861e}} 
        pop     de                ;{{1e2c:d1}} 
        pop     bc                ;{{1e2d:c1}} 
        ret                       ;{{1e2e:c9}} 

;;===========================================================================
;; KM GET REPEAT

KM_GET_REPEAT:                    ;{{Addr=$1e2f Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_KB_repeats_table);{{1e2f:2a91b6}} 
        jr      _km_test_key_6    ;{{1e32:181c}}  (+&1c)

;;===========================================================================
;; KM SET REPEAT

KM_SET_REPEAT:                    ;{{Addr=$1e34 Code Calls/jump count: 0 Data use count: 1}}
        cp      $50               ;{{1e34:fe50}} 
        ret     nc                ;{{1e36:d0}} 

        ld      hl,(address_of_the_KB_repeats_table);{{1e37:2a91b6}} 
        call    _km_test_key_9    ;{{1e3a:cd551e}} 
        cpl                       ;{{1e3d:2f}} 
        ld      c,a               ;{{1e3e:4f}} 
        ld      a,(hl)            ;{{1e3f:7e}} 
        xor     b                 ;{{1e40:a8}} 
        and     c                 ;{{1e41:a1}} 
        xor     b                 ;{{1e42:a8}} 
        ld      (hl),a            ;{{1e43:77}} 
        ret                       ;{{1e44:c9}} 

;;===========================================================================
;; KM TEST KEY

KM_TEST_KEY:                      ;{{Addr=$1e45 Code Calls/jump count: 1 Data use count: 1}}
        push    af                ;{{1e45:f5}} 
        ld      a,(RAM_b637)      ;{{1e46:3a37b6}} 
        and     $a0               ;{{1e49:e6a0}} 
        ld      c,a               ;{{1e4b:4f}} 
        pop     af                ;{{1e4c:f1}} 
        ld      hl,Tables_used_for_key_scanning_bits_;{{1e4d:2135b6}} 
_km_test_key_6:                   ;{{Addr=$1e50 Code Calls/jump count: 1 Data use count: 0}}
        call    _km_test_key_9    ;{{1e50:cd551e}} 
        and     (hl)              ;{{1e53:a6}} 
        ret                       ;{{1e54:c9}} 

;;-------------------------------------------------------
_km_test_key_9:                   ;{{Addr=$1e55 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{1e55:d5}} 
        push    af                ;{{1e56:f5}} 
        and     $f8               ;{{1e57:e6f8}} 
        rrca                      ;{{1e59:0f}} 
        rrca                      ;{{1e5a:0f}} 
        rrca                      ;{{1e5b:0f}} 
        ld      e,a               ;{{1e5c:5f}} 
        ld      d,$00             ;{{1e5d:1600}} 
        add     hl,de             ;{{1e5f:19}} 
        pop     af                ;{{1e60:f1}} 

        push    hl                ;{{1e61:e5}} 
        ld      hl,table_to_convert_from_bit_index_07_to_bit_OR_mask_1bit_index;{{1e62:216d1e}} 
        and     $07               ;{{1e65:e607}} 
        ld      e,a               ;{{1e67:5f}} 
        add     hl,de             ;{{1e68:19}} 
        ld      a,(hl)            ;{{1e69:7e}} 
        pop     hl                ;{{1e6a:e1}} 
        pop     de                ;{{1e6b:d1}} 
        ret                       ;{{1e6c:c9}} 

;;===========================================================================
;; table to convert from bit index (0-7) to bit OR mask (1<<bit index)
table_to_convert_from_bit_index_07_to_bit_OR_mask_1bit_index:;{{Addr=$1e6d Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $01,$02,$04,$08,$10,$20,$40,$80

;;===========================================================================
;;km reset or clear?
km_reset_or_clear:                ;{{Addr=$1e75 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{1e75:f3}} 
        ld      hl,RAM_b686       ;{{1e76:2186b6}} 
        ld      (hl),$15          ;{{1e79:3615}} 
        inc     hl                ;{{1e7b:23}} 
        xor     a                 ;{{1e7c:af}} 
        ld      (hl),a            ;{{1e7d:77}} 
        inc     hl                ;{{1e7e:23}} 
        ld      (hl),$01          ;{{1e7f:3601}} 
        inc     hl                ;{{1e81:23}} 
        ld      (hl),a            ;{{1e82:77}} 
        inc     hl                ;{{1e83:23}} 
        ld      (hl),a            ;{{1e84:77}} 
        ret                       ;{{1e85:c9}} 

;;===========================================================================
;; km unknown function 1
km_unknown_function_1:            ;{{Addr=$1e86 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b686       ;{{1e86:2186b6}} 
        or      a                 ;{{1e89:b7}} 
        dec     (hl)              ;{{1e8a:35}} 
        jr      z,_km_unknown_function_1_12;{{1e8b:280e}}  (+&0e)
        call    _km_unknown_function_2_14;{{1e8d:cdb41e}} 
        ld      (hl),c            ;{{1e90:71}} 
        inc     hl                ;{{1e91:23}} 
        ld      (hl),b            ;{{1e92:70}} 
        ld      hl,RAM_b68a       ;{{1e93:218ab6}} 
        inc     (hl)              ;{{1e96:34}} 
        ld      hl,number_of_keys_left_in_key_buffer;{{1e97:2188b6}} 
        scf                       ;{{1e9a:37}} 
_km_unknown_function_1_12:        ;{{Addr=$1e9b Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{1e9b:34}} 
        ret                       ;{{1e9c:c9}} 

;;===========================================================================
;; km unknown function 2
km_unknown_function_2:            ;{{Addr=$1e9d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,number_of_keys_left_in_key_buffer;{{1e9d:2188b6}} 
        or      a                 ;{{1ea0:b7}} 
        dec     (hl)              ;{{1ea1:35}} 
        jr      z,_km_unknown_function_2_12;{{1ea2:280e}}  (+&0e)
        call    _km_unknown_function_2_14;{{1ea4:cdb41e}} 
        ld      c,(hl)            ;{{1ea7:4e}} 
        inc     hl                ;{{1ea8:23}} 
        ld      b,(hl)            ;{{1ea9:46}} 
        ld      hl,RAM_b68a       ;{{1eaa:218ab6}} 
        dec     (hl)              ;{{1ead:35}} 
        ld      hl,RAM_b686       ;{{1eae:2186b6}} 
        scf                       ;{{1eb1:37}} 
_km_unknown_function_2_12:        ;{{Addr=$1eb2 Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{1eb2:34}} 
        ret                       ;{{1eb3:c9}} 

;;-----------------------------------------------------------
_km_unknown_function_2_14:        ;{{Addr=$1eb4 Code Calls/jump count: 2 Data use count: 0}}
        inc     hl                ;{{1eb4:23}} 
        inc     (hl)              ;{{1eb5:34}} 
        ld      a,(hl)            ;{{1eb6:7e}} 
        cp      $14               ;{{1eb7:fe14}} 
        jr      nz,_km_unknown_function_2_21;{{1eb9:2002}}  (+&02)

        xor     a                 ;{{1ebb:af}} 
        ld      (hl),a            ;{{1ebc:77}} 

_km_unknown_function_2_21:        ;{{Addr=$1ebd Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{1ebd:87}} 
        add     a,$5e             ;{{1ebe:c65e}} 
        ld      l,a               ;{{1ec0:6f}} 
        ld      h,$b6             ;{{1ec1:26b6}} 
        ret                       ;{{1ec3:c9}} 

;;===========================================================================
;; KM GET TRANSLATE

KM_GET_TRANSLATE:                 ;{{Addr=$1ec4 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_normal_key_table);{{1ec4:2a8bb6}} 
        jr      _km_get_control__1;{{1ec7:1808}}  (+&08)

;;===========================================================================
;; KM GET SHIFT

KM_GET_SHIFT:                     ;{{Addr=$1ec9 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_shifted_key_table);{{1ec9:2a8db6}} 
        jr      _km_get_control__1;{{1ecc:1803}}  (+&03)

;;===========================================================================
;; KM GET CONTROL 

KM_GET_CONTROL_:                  ;{{Addr=$1ece Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_control_key_table);{{1ece:2a8fb6}} 

_km_get_control__1:               ;{{Addr=$1ed1 Code Calls/jump count: 2 Data use count: 0}}
        add     a,l               ;{{1ed1:85}} 
        ld      l,a               ;{{1ed2:6f}} 
        adc     a,h               ;{{1ed3:8c}} 
        sub     l                 ;{{1ed4:95}} 
        ld      h,a               ;{{1ed5:67}} 
        ld      a,(hl)            ;{{1ed6:7e}} 
        ret                       ;{{1ed7:c9}} 

;;===========================================================================
;; KM SET TRANSLATE

KM_SET_TRANSLATE:                 ;{{Addr=$1ed8 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_normal_key_table);{{1ed8:2a8bb6}} 
        jr      _km_set_control_1 ;{{1edb:1808}}  (+&08)

;;===========================================================================
;; KM SET SHIFT

KM_SET_SHIFT:                     ;{{Addr=$1edd Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_shifted_key_table);{{1edd:2a8db6}} 
        jr      _km_set_control_1 ;{{1ee0:1803}}  (+&03)

;;===========================================================================
;; KM SET CONTROL

KM_SET_CONTROL:                   ;{{Addr=$1ee2 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_control_key_table);{{1ee2:2a8fb6}} 
_km_set_control_1:                ;{{Addr=$1ee5 Code Calls/jump count: 2 Data use count: 0}}
        cp      $50               ;{{1ee5:fe50}} 
        ret     nc                ;{{1ee7:d0}} 

        add     a,l               ;{{1ee8:85}} 
        ld      l,a               ;{{1ee9:6f}} 
        adc     a,h               ;{{1eea:8c}} 
        sub     l                 ;{{1eeb:95}} 
        ld      h,a               ;{{1eec:67}} 
        ld      (hl),b            ;{{1eed:70}} 
        ret                       ;{{1eee:c9}} 

;;+------------------------------------------------------
;; keyboard translation table

keyboard_translation_table:       ;{{Addr=$1eef Data Calls/jump count: 0 Data use count: 1}}
        defb $f0,$f3,$f1,$89,$86,$83,$8b,$8a
        defb $f2,$e0,$87,$88,$85,$81,$82,$80
        defb $10,$5b,$0d,$5d,$84,$ff,$5c,$ff
        defb $5e,$2d,$40,$70,$3b,$3a,$2f,$2e
        defb $30,$39,$6f,$69,$6c,$6b,$6d,$2c
        defb $38,$37,$75,$79,$68,$6a,$6e,$20
        defb $36,$35,$72,$74,$67,$66,$62,$76
        defb $34,$33,$65,$77,$73,$64,$63,$78
        defb $31,$32,$fc,$71,$09,$61,$fd,$7a
        defb $0b,$0a,$08,$09,$58,$5a,$ff,$7f
        defb $f4,$f7,$f5,$89,$86,$83,$8b,$8a
        defb $f6,$e0,$87,$88,$85,$81,$82,$80
        defb $10,$7b,$0d,$7d,$84,$ff,$60,$ff
        defb $a3,$3d,$7c,$50,$2b,$2a,$3f,$3e
        defb $5f,$29,$4f,$49,$4c,$4b,$4d,$3c
        defb $28,$27,$55,$59,$48,$4a,$4e,$20
        defb $26,$25,$52,$54,$47,$46,$42,$56
        defb $24,$23,$45,$57,$53,$44,$43,$58
        defb $21,$22,$fc,$51,$09,$41,$fd,$5a
        defb $0b,$0a,$08,$09,$58,$5a,$ff,$7f
        defb $f8,$fb,$f9,$89,$86,$83,$8c,$8a
        defb $fa,$e0,$87,$88,$85,$81,$82,$80
        defb $10,$1b,$0d,$1d,$84,$ff,$1c,$ff
        defb $1e,$ff,$00,$10,$ff,$ff,$ff,$ff
        defb $1f,$ff,$0f,$09,$0c,$0b,$0d,$ff
        defb $ff,$ff,$15,$19,$08,$0a,$0e,$ff
        defb $ff,$ff,$12,$14,$07,$06,$02,$16
        defb $ff,$ff,$05,$17,$13,$04,$03,$18
        defb $ff,$7e,$fc,$11,$e1,$01,$fe,$1a
        defb $ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
        defb $07,$03,$4b,$ff,$ff,$ff,$ff,$ff
        defb $ab,$8f              




