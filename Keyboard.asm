;; KEYBOARD ROUTINES
;;===========================================================================
;; KM INITIALISE

KM_INITIALISE:                    ;{{Addr=$1b5c Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,$1e02          ;{{1B5C:21021e}} ##LIT##;WARNING: Code area used as literal
        call    KM_SET_DELAY      ;{{1B5F:cdf61d}}  KM SET DELAY
        xor     a                 ;{{1B62:af}} 
        ld      (RAM_b655),a      ;{{1B63:3255b6}} 
        ld      h,a               ;{{1B66:67}} 
        ld      l,a               ;{{1B67:6f}} 
        ld      (Shift_lock_flag_),hl;{{1B68:2231b6}} 
        ld      bc,$ffb0          ;{{1B6B:01b0ff}} 
        ld      de,$b5d6          ;{{1B6E:11d6b5}} 
        ld      hl,RAM_b692       ;{{1B71:2192b6}} 
        ld      a,$04             ;{{1B74:3e04}} 
_km_initialise_11:                ;{{Addr=$1b76 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{1B76:eb}} 
        add     hl,bc             ;{{1B77:09}} 
        ex      de,hl             ;{{1B78:eb}} 
        ld      (hl),d            ;{{1B79:72}} 
        dec     hl                ;{{1B7A:2b}} 
        ld      (hl),e            ;{{1B7B:73}} 
        dec     hl                ;{{1B7C:2b}} 
        dec     a                 ;{{1B7D:3d}} 
        jr      nz,_km_initialise_11;{{1B7E:20f6}}  (-&0a)

;;-------------------------------------------
;; copy keyboard translation table
        ld      hl,keyboard_translation_table;{{1B80:21ef1e}} 
        ld      bc,$00fa          ;{{1B83:01fa00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1B86:edb0}} 

;;-------------------------------------------
        ld      b,$0a             ;{{1B88:060a}} 
        ld      de,Tables_used_for_key_scanning_bits_;{{1B8A:1135b6}} 
        ld      hl,complement_of_B635;{{1B8D:213fb6}} 
        xor     a                 ;{{1B90:af}} 
_km_initialise_27:                ;{{Addr=$1b91 Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{1B91:12}} 
        inc     de                ;{{1B92:13}} 
        ld      (hl),$ff          ;{{1B93:36ff}} 
        inc     hl                ;{{1B95:23}} 
        djnz    _km_initialise_27 ;{{1B96:10f9}}  (-&07)
;;-------------------------------------------

;;===========================================================================
;; KM RESET

KM_RESET:                         ;{{Addr=$1b98 Code Calls/jump count: 1 Data use count: 1}}
        call    km_reset_or_clear ;{{1B98:cd751e}} 
        call    clear_returned_key;{{1B9B:cdf81b}}  reset returned key (KM CHAR RETURN)
        ld      de,DEF_KEYs_definition_area_;{{1B9E:1190b5}} 
        ld      hl,$0098          ;{{1BA1:219800}} ##LIT##;WARNING: Code area used as literal
        call    _km_exp_buffer_4  ;{{1BA4:cd0a1c}} 

        ld      hl,_km_reset_9    ;{{1BA7:21b31b}}  table used to initialise keyboard manager indirections
        call    initialise_firmware_indirections;{{1BAA:cdb40a}}  initialise keyboard manager indirections (KM TEST BREAK)
        call    initialise_firmware_indirections;{{1BAD:cdb40a}}  initialise keyboard manager indirections (KM SCAN KEYS)
        jp      KM_DISARM_BREAK   ;{{1BB0:c30b1e}}  KM DISARM BREAK

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
        call    KM_READ_CHAR      ;{{1BBF:cdc51b}}  KM READ CHAR
        jr      nc,KM_WAIT_CHAR   ;{{1BC2:30fb}} 
        ret                       ;{{1BC4:c9}} 

;;===========================================================================
;; KM READ CHAR

KM_READ_CHAR:                     ;{{Addr=$1bc5 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{1BC5:e5}} 
        ld      hl,RAM_b62a       ;{{1BC6:212ab6}}  returned char
        ld      a,(hl)            ;{{1BC9:7e}}  get char
        ld      (hl),$ff          ;{{1BCA:36ff}}  reset state
        cp      (hl)              ;{{1BCC:be}}  was a char returned?
        jr      c,_km_read_char_27;{{1BCD:3827}}  a key was put back into buffer, return without expanding it

;; are we expanding?
        ld      hl,(Byte_after_end_of_DEF_KEY_area);{{1BCF:2a28b6}} 
        ld      a,h               ;{{1BD2:7c}} 
        or      a                 ;{{1BD3:b7}} 
        jr      nz,_km_read_char_19;{{1BD4:2011}}  continue expansion

_km_read_char_10:                 ;{{Addr=$1bd6 Code Calls/jump count: 1 Data use count: 0}}
        call    KM_READ_KEY       ;{{1BD6:cde11c}}  KM READ KEY
        jr      nc,_km_read_char_27;{{1BD9:301b}}  (+&1b)
        cp      $80               ;{{1BDB:fe80}} 
        jr      c,_km_read_char_27;{{1BDD:3817}}  (+&17)
        cp      $a0               ;{{1BDF:fea0}} 
        ccf                       ;{{1BE1:3f}} 
        jr      c,_km_read_char_27;{{1BE2:3812}}  (+&12)

;; begin expansion
        ld      h,a               ;{{1BE4:67}} 
        ld      l,$00             ;{{1BE5:2e00}} 

;; continue expansion
_km_read_char_19:                 ;{{Addr=$1be7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{1BE7:d5}} 
        call    KM_GET_EXPAND     ;{{1BE8:cdb31c}}  KM GET EXPAND
        jr      c,_km_read_char_23;{{1BEB:3802}} 

;; write expansion pointer
        ld      h,$00             ;{{1BED:2600}} 
_km_read_char_23:                 ;{{Addr=$1bef Code Calls/jump count: 1 Data use count: 0}}
        inc     l                 ;{{1BEF:2c}} 
        ld      (Byte_after_end_of_DEF_KEY_area),hl;{{1BF0:2228b6}} 
        pop     de                ;{{1BF3:d1}} 
        jr      nc,_km_read_char_10;{{1BF4:30e0}} 
_km_read_char_27:                 ;{{Addr=$1bf6 Code Calls/jump count: 4 Data use count: 0}}
        pop     hl                ;{{1BF6:e1}} 
        ret                       ;{{1BF7:c9}} 

;;===========================================================================
;; clear returned key
clear_returned_key:               ;{{Addr=$1bf8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$ff             ;{{1BF8:3eff}} 

;;===========================================================================
;; KM CHAR RETURN

KM_CHAR_RETURN:                   ;{{Addr=$1bfa Code Calls/jump count: 0 Data use count: 1}}
        ld      (RAM_b62a),a      ;{{1BFA:322ab6}} 
        ret                       ;{{1BFD:c9}} 

;;===========================================================================
;; KM FLUSH

KM_FLUSH:                         ;{{Addr=$1bfe Code Calls/jump count: 2 Data use count: 1}}
        call    KM_READ_CHAR      ;{{1BFE:cdc51b}}  KM READ CHAR
        jr      c,KM_FLUSH        ;{{1C01:38fb}} 
        ret                       ;{{1C03:c9}} 

;;===========================================================================
;; KM EXP BUFFER

KM_EXP_BUFFER:                    ;{{Addr=$1c04 Code Calls/jump count: 0 Data use count: 1}}
        call    _km_exp_buffer_4  ;{{1C04:cd0a1c}} 
        ccf                       ;{{1C07:3f}} 
        ei                        ;{{1C08:fb}} 
        ret                       ;{{1C09:c9}} 

;;-------------------------------------------------------------------------
_km_exp_buffer_4:                 ;{{Addr=$1c0a Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{1C0A:f3}} 
        ld      a,l               ;{{1C0B:7d}} 
        sub     $31               ;{{1C0C:d631}} 
        ld      a,h               ;{{1C0E:7c}} 
        sbc     a,$00             ;{{1C0F:de00}} 
        ret     c                 ;{{1C11:d8}} 

        add     hl,de             ;{{1C12:19}} 
        ld      (address_of_byte_after_end_of_DEF_KEY_are),hl;{{1C13:222db6}} 
        ex      de,hl             ;{{1C16:eb}} 
        ld      (address_of_DEF_KEY_area),hl;{{1C17:222bb6}} 
        ld      bc,$0a30          ;{{1C1A:01300a}} ##LIT##;WARNING: Code area used as literal
_km_exp_buffer_15:                ;{{Addr=$1c1d Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$01          ;{{1C1D:3601}} 
        inc     hl                ;{{1C1F:23}} 
        ld      (hl),c            ;{{1C20:71}} 
        inc     hl                ;{{1C21:23}} 
        inc     c                 ;{{1C22:0c}} 
        djnz    _km_exp_buffer_15 ;{{1C23:10f8}}  (-&08)
        ex      de,hl             ;{{1C25:eb}} 

        ld      hl,default_keyboard_expansion_table;{{1C26:213c1c}} ; default expansion values
        ld      c,$0a             ;{{1C29:0e0a}} 
        ldir                      ;{{1C2B:edb0}} 

        ex      de,hl             ;{{1C2D:eb}} 
        ld      b,$13             ;{{1C2E:0613}} 
        xor     a                 ;{{1C30:af}} 
_km_exp_buffer_28:                ;{{Addr=$1c31 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{1C31:77}} 
        inc     hl                ;{{1C32:23}} 
        djnz    _km_exp_buffer_28 ;{{1C33:10fc}}  (-&04)
        ld      (RAM_b62f),hl     ;{{1C35:222fb6}} 
        ld      (RAM_b629),a      ;{{1C38:3229b6}} 
        ret                       ;{{1C3B:c9}} 

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
        ld 		a,b                  ;{{1C46:78}} 
        call    keycode_above_7f_not_defineable;{{1C47:cdc31c}} 
        ret     nc                ;{{1C4A:d0}} 

        push    bc                ;{{1C4B:c5}} 
        push    de                ;{{1C4C:d5}} 
        push    hl                ;{{1C4D:e5}} 
        call    _km_set_expand_28 ;{{1C4E:cd6a1c}} 
        ccf                       ;{{1C51:3f}} 
        pop     hl                ;{{1C52:e1}} 
        pop     de                ;{{1C53:d1}} 
        pop     bc                ;{{1C54:c1}} 
        ret     nc                ;{{1C55:d0}} 

        dec     de                ;{{1C56:1b}} 
        ld      a,c               ;{{1C57:79}} 
        inc     c                 ;{{1C58:0c}} 
_km_set_expand_15:                ;{{Addr=$1c59 Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{1C59:12}} 
        inc     de                ;{{1C5A:13}} 
        rst     $20               ;{{1C5B:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{1C5C:23}} 
        dec     c                 ;{{1C5D:0d}} 
        jr      nz,_km_set_expand_15;{{1C5E:20f9}}  (-&07)
        ld      hl,RAM_b629       ;{{1C60:2129b6}} 
        ld      a,b               ;{{1C63:78}} 
        xor     (hl)              ;{{1C64:ae}} 
        jr      nz,_km_set_expand_26;{{1C65:2001}}  (+&01)
        ld      (hl),a            ;{{1C67:77}} 
_km_set_expand_26:                ;{{Addr=$1c68 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{1C68:37}} 
        ret                       ;{{1C69:c9}} 

;;---------------------------------------------------------------
_km_set_expand_28:                ;{{Addr=$1c6a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{1C6A:0600}} 
        ld      h,b               ;{{1C6C:60}} 
        ld      l,a               ;{{1C6D:6f}} 
        ld      a,c               ;{{1C6E:79}} 
        sub     l                 ;{{1C6F:95}} 
        ret     z                 ;{{1C70:c8}} 

        jr      nc,_km_set_expand_45;{{1C71:300f}}  (+&0f)
        ld      a,l               ;{{1C73:7d}} 
        ld      l,c               ;{{1C74:69}} 
        ld      c,a               ;{{1C75:4f}} 
        add     hl,de             ;{{1C76:19}} 
        ex      de,hl             ;{{1C77:eb}} 
        add     hl,bc             ;{{1C78:09}} 
        call    _km_set_expand_69 ;{{1C79:cda71c}} 
        jr      z,_km_set_expand_66;{{1C7C:2823}}  (+&23)
        ldir                      ;{{1C7E:edb0}} 
        jr      _km_set_expand_66 ;{{1C80:181f}}  (+&1f)
_km_set_expand_45:                ;{{Addr=$1c82 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{1C82:4f}} 
        add     hl,de             ;{{1C83:19}} 
        push    hl                ;{{1C84:e5}} 
        ld      hl,(RAM_b62f)     ;{{1C85:2a2fb6}} 
        add     hl,bc             ;{{1C88:09}} 
        ex      de,hl             ;{{1C89:eb}} 
        ld      hl,(address_of_byte_after_end_of_DEF_KEY_are);{{1C8A:2a2db6}} 
        ld      a,l               ;{{1C8D:7d}} 
        sub     e                 ;{{1C8E:93}} 
        ld      a,h               ;{{1C8F:7c}} 
        sbc     a,d               ;{{1C90:9a}} 
        pop     hl                ;{{1C91:e1}} 
        ret     c                 ;{{1C92:d8}} 

        call    _km_set_expand_69 ;{{1C93:cda71c}} 
        ld      hl,(RAM_b62f)     ;{{1C96:2a2fb6}} 
        jr      z,_km_set_expand_66;{{1C99:2806}}  (+&06)
        push    de                ;{{1C9B:d5}} 
        dec     de                ;{{1C9C:1b}} 
        dec     hl                ;{{1C9D:2b}} 
        lddr                      ;{{1C9E:edb8}} 
        pop     de                ;{{1CA0:d1}} 
_km_set_expand_66:                ;{{Addr=$1ca1 Code Calls/jump count: 3 Data use count: 0}}
        ld      (RAM_b62f),de     ;{{1CA1:ed532fb6}} 
        or      a                 ;{{1CA5:b7}} 
        ret                       ;{{1CA6:c9}} 

;;-----------------------------------------------------------------

_km_set_expand_69:                ;{{Addr=$1ca7 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_b62f)      ;{{1CA7:3a2fb6}} 
        sub     l                 ;{{1CAA:95}} 
        ld      c,a               ;{{1CAB:4f}} 
        ld      a,(RAM_b630)      ;{{1CAC:3a30b6}} 
        sbc     a,h               ;{{1CAF:9c}} 
        ld      b,a               ;{{1CB0:47}} 
        or      c                 ;{{1CB1:b1}} 
        ret                       ;{{1CB2:c9}} 

;;===========================================================================
;; KM GET EXPAND

KM_GET_EXPAND:                    ;{{Addr=$1cb3 Code Calls/jump count: 1 Data use count: 1}}
        call    keycode_above_7f_not_defineable;{{1CB3:cdc31c}} 
        ret     nc                ;{{1CB6:d0}} 

        cp      l                 ;{{1CB7:bd}} 
        ret     z                 ;{{1CB8:c8}} 

        ccf                       ;{{1CB9:3f}} 
        ret     nc                ;{{1CBA:d0}} 

        push    hl                ;{{1CBB:e5}} 
        ld      h,$00             ;{{1CBC:2600}} 
        add     hl,de             ;{{1CBE:19}} 
        ld      a,(hl)            ;{{1CBF:7e}} 
        pop     hl                ;{{1CC0:e1}} 
        scf                       ;{{1CC1:37}} 
        ret                       ;{{1CC2:c9}} 

;;===========================================================================

;; keycode above &7f not defineable?
keycode_above_7f_not_defineable:  ;{{Addr=$1cc3 Code Calls/jump count: 2 Data use count: 0}}
        and     $7f               ;{{1CC3:e67f}} 
;; keys between &20-&7f are not defineable?
        cp      $20               ;{{1CC5:fe20}} 
        ret     nc                ;{{1CC7:d0}} 

        push    hl                ;{{1CC8:e5}} 
        ld      hl,(address_of_DEF_KEY_area);{{1CC9:2a2bb6}} 
        ld      de,$0000          ;{{1CCC:110000}} ##LIT##;WARNING: Code area used as literal
        inc     a                 ;{{1CCF:3c}} 
_keycode_above_7f_not_defineable_7:;{{Addr=$1cd0 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{1CD0:19}} 
        ld      e,(hl)            ;{{1CD1:5e}} 
        inc     hl                ;{{1CD2:23}} 
        dec     a                 ;{{1CD3:3d}} 
        jr      nz,_keycode_above_7f_not_defineable_7;{{1CD4:20fa}}  (-&06)
        ld      a,e               ;{{1CD6:7b}} 
        ex      de,hl             ;{{1CD7:eb}} 
        pop     hl                ;{{1CD8:e1}} 
        scf                       ;{{1CD9:37}} 
        ret                       ;{{1CDA:c9}} 

;;===========================================================================
;; KM WAIT KEY

KM_WAIT_KEY:                      ;{{Addr=$1cdb Code Calls/jump count: 2 Data use count: 1}}
        call    KM_READ_KEY       ;{{1CDB:cde11c}}  KM READ KEY
        jr      nc,KM_WAIT_KEY    ;{{1CDE:30fb}} 
        ret                       ;{{1CE0:c9}} 

;;===========================================================================
;; KM READ KEY

KM_READ_KEY:                      ;{{Addr=$1ce1 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{1CE1:e5}} 
        push    bc                ;{{1CE2:c5}} 
_km_read_key_2:                   ;{{Addr=$1ce3 Code Calls/jump count: 2 Data use count: 0}}
        call    km_unknown_function_2;{{1CE3:cd9d1e}} 
        jr      nc,_km_read_key_37;{{1CE6:303a}}  (+&3a)
        ld      a,c               ;{{1CE8:79}} 
        cp      $ef               ;{{1CE9:feef}} 
        jr      z,_km_read_key_36 ;{{1CEB:2834}}  (+&34)
        and     $0f               ;{{1CED:e60f}} 
        add     a,a               ;{{1CEF:87}} 
        add     a,a               ;{{1CF0:87}} 
        add     a,a               ;{{1CF1:87}} 
        dec     a                 ;{{1CF2:3d}} 
_km_read_key_12:                  ;{{Addr=$1cf3 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{1CF3:3c}} 
        rrc     b                 ;{{1CF4:cb08}} 
        jr      nc,_km_read_key_12;{{1CF6:30fb}}  (-&05)
        call    _km_read_key_40   ;{{1CF8:cd251d}} 
        ld      hl,Caps_lock_flag_;{{1CFB:2132b6}} 
        bit     7,(hl)            ;{{1CFE:cb7e}} 
        jr      z,_km_read_key_24 ;{{1D00:280a}}  (+&0a)
        cp      $61               ;{{1D02:fe61}} 
        jr      c,_km_read_key_24 ;{{1D04:3806}}  (+&06)
        cp      $7b               ;{{1D06:fe7b}} 
        jr      nc,_km_read_key_24;{{1D08:3002}}  (+&02)
        add     a,$e0             ;{{1D0A:c6e0}} 
_km_read_key_24:                  ;{{Addr=$1d0c Code Calls/jump count: 3 Data use count: 0}}
        cp      $ff               ;{{1D0C:feff}} 
        jr      z,_km_read_key_2  ;{{1D0E:28d3}}  (-&2d)
        cp      $fe               ;{{1D10:fefe}} 
        ld      hl,Shift_lock_flag_;{{1D12:2131b6}} 
        jr      z,_km_read_key_32 ;{{1D15:2805}}  (+&05)
        cp      $fd               ;{{1D17:fefd}} 
        inc     hl                ;{{1D19:23}} 
        jr      nz,_km_read_key_36;{{1D1A:2005}}  (+&05)
_km_read_key_32:                  ;{{Addr=$1d1c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{1D1C:7e}} 
        cpl                       ;{{1D1D:2f}} 
        ld      (hl),a            ;{{1D1E:77}} 
        jr      _km_read_key_2    ;{{1D1F:18c2}}  (-&3e)
_km_read_key_36:                  ;{{Addr=$1d21 Code Calls/jump count: 2 Data use count: 0}}
        scf                       ;{{1D21:37}} 
_km_read_key_37:                  ;{{Addr=$1d22 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{1D22:c1}} 
        pop     hl                ;{{1D23:e1}} 
        ret                       ;{{1D24:c9}} 

;;-------------------------------------------------------

_km_read_key_40:                  ;{{Addr=$1d25 Code Calls/jump count: 1 Data use count: 0}}
        rl      c                 ;{{1D25:cb11}} 
        jp      c,KM_GET_CONTROL_ ;{{1D27:dace1e}}  KM GET CONTROL
        ld      b,a               ;{{1D2A:47}} 
        ld      a,(Shift_lock_flag_);{{1D2B:3a31b6}} 
        or      c                 ;{{1D2E:b1}} 
        and     $40               ;{{1D2F:e640}} 
        ld      a,b               ;{{1D31:78}} 
        jp      nz,KM_GET_SHIFT   ;{{1D32:c2c91e}}  KM GET SHIFT
        jp      KM_GET_TRANSLATE  ;{{1D35:c3c41e}}  KM GET TRANSLATE

;;===========================================================================
;; KM GET STATE

KM_GET_STATE:                     ;{{Addr=$1d38 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(Shift_lock_flag_);{{1D38:2a31b6}} 
        ret                       ;{{1D3B:c9}} 

;;===========================================================================
;; KM SET LOCKS

KM_SET_LOCKS:                     ;{{Addr=$1d3c Code Calls/jump count: 0 Data use count: 1}}
        ld      (Shift_lock_flag_),hl;{{1D3C:2231b6}} 
        ret                       ;{{1D3F:c9}} 

;;===========================================================================
;; IND: KM SCAN KEYS

IND_KM_SCAN_KEYS:                 ;{{Addr=$1d40 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$b649          ;{{1D40:1149b6}}  buffer for keys that have changed
        ld      hl,complement_of_B635;{{1D43:213fb6}}  buffer for current state of key matrix
                                  ; if a bit is '0' then key is pressed,
                                  ; if a bit is '1' then key is released.
        call    scan_keyboard     ;{{1D46:cd8308}}  scan keyboard

;;b635-b63e
;;b63f-b648
;;b649-b652 (keyboard line 0-10 inclusive)

        ld      a,(RAM_b64b)      ;{{1D49:3a4bb6}}  keyboard line 2
        and     $a0               ;{{1D4C:e6a0}}  isolate change state of CTRL and SHIFT keys
        ld      c,a               ;{{1D4E:4f}} 

        ld      hl,RAM_b637       ;{{1D4F:2137b6}} 
        or      (hl)              ;{{1D52:b6}} 
        ld      (hl),a            ;{{1D53:77}} 

;;----------------------------------------------------------------------
        ld      hl,$b649          ;{{1D54:2149b6}} 
        ld      de,Tables_used_for_key_scanning_bits_;{{1D57:1135b6}} 
        ld      b,$00             ;{{1D5A:0600}} 

_ind_km_scan_keys_12:             ;{{Addr=$1d5c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{1D5C:1a}} 
        xor     (hl)              ;{{1D5D:ae}} 
        and     (hl)              ;{{1D5E:a6}} 
        call    nz,km_scan_keys_sub;{{1D5F:c4d11d}} 
        ld      a,(hl)            ;{{1D62:7e}} 
        ld      (de),a            ;{{1D63:12}} 
        inc     hl                ;{{1D64:23}} 
        inc     de                ;{{1D65:13}} 
        inc     c                 ;{{1D66:0c}} 
        ld      a,c               ;{{1D67:79}} 
        and     $0f               ;{{1D68:e60f}} 
        cp      $0a               ;{{1D6A:fe0a}} 
        jr      nz,_ind_km_scan_keys_12;{{1D6C:20ee}}  (-&12)

;;---------------------------------------------------------------------

        ld      a,c               ;{{1D6E:79}} 
        and     $a0               ;{{1D6F:e6a0}} 
        bit     6,c               ;{{1D71:cb71}} 
        ld      c,a               ;{{1D73:4f}} 
        call    nz,KM_TEST_BREAK  ;{{1D74:c4eebd}}  IND: KM TEST BREAK
        ld      a,b               ;{{1D77:78}} 
        or      a                 ;{{1D78:b7}} 
        ret     nz                ;{{1D79:c0}} 

        ld      hl,RAM_b653       ;{{1D7A:2153b6}} 
        dec     (hl)              ;{{1D7D:35}} 
        ret     nz                ;{{1D7E:c0}} 

        ld      hl,(RAM_b654)     ;{{1D7F:2a54b6}} 
        ex      de,hl             ;{{1D82:eb}} 
        ld      b,d               ;{{1D83:42}} 
        ld      d,$00             ;{{1D84:1600}} 
        ld      hl,Tables_used_for_key_scanning_bits_;{{1D86:2135b6}} 
        add     hl,de             ;{{1D89:19}} 
        ld      a,(hl)            ;{{1D8A:7e}} 
        ld      hl,(address_of_the_KB_repeats_table);{{1D8B:2a91b6}} 
        add     hl,de             ;{{1D8E:19}} 
        and     (hl)              ;{{1D8F:a6}} 
        and     b                 ;{{1D90:a0}} 
        ret     z                 ;{{1D91:c8}} 

        ld      hl,RAM_b653       ;{{1D92:2153b6}} 
        inc     (hl)              ;{{1D95:34}} 
        ld      a,(RAM_b68a)      ;{{1D96:3a8ab6}} 
        or      a                 ;{{1D99:b7}} 
        ret     nz                ;{{1D9A:c0}} 

        ld      a,c               ;{{1D9B:79}} 
        or      e                 ;{{1D9C:b3}} 
        ld      c,a               ;{{1D9D:4f}} 
        ld      a,(KB_repeat_period_);{{1D9E:3a33b6}} 

_ind_km_scan_keys_57:             ;{{Addr=$1da1 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b653),a      ;{{1DA1:3253b6}} 
        call    km_unknown_function_1;{{1DA4:cd861e}} 
        ld      a,c               ;{{1DA7:79}} 
        and     $0f               ;{{1DA8:e60f}} 
        ld      l,a               ;{{1DAA:6f}} 
        ld      h,b               ;{{1DAB:60}} 
        ld      (RAM_b654),hl     ;{{1DAC:2254b6}} 

        cp      $08               ;{{1DAF:fe08}} 
        ret     nz                ;{{1DB1:c0}} 

        bit     4,b               ;{{1DB2:cb60}} 
        ret     nz                ;{{1DB4:c0}} 

        set     6,c               ;{{1DB5:cbf1}} 
        ret                       ;{{1DB7:c9}} 

;;=====================================================================================
;; IND: KM TEST BREAK

IND_KM_TEST_BREAK:                ;{{Addr=$1db8 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b63d       ;{{1DB8:213db6}} 
        bit     2,(hl)            ;{{1DBB:cb56}} 
        ret     z                 ;{{1DBD:c8}} 

        ld      a,c               ;{{1DBE:79}} 
        xor     $a0               ;{{1DBF:eea0}} 
        jr      nz,KM_BREAK_EVENT ;{{1DC1:2056}}  KM BREAK EVENT
        push    bc                ;{{1DC3:c5}} 
        inc     hl                ;{{1DC4:23}} 
        ld      b,$0a             ;{{1DC5:060a}} 
_ind_km_test_break_9:             ;{{Addr=$1dc7 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,(hl)            ;{{1DC7:8e}} 
        dec     hl                ;{{1DC8:2b}} 
        djnz    _ind_km_test_break_9;{{1DC9:10fc}}  (-&04)
        pop     bc                ;{{1DCB:c1}} 
        cp      $a4               ;{{1DCC:fea4}} 
        jr      nz,KM_BREAK_EVENT ;{{1DCE:2049}}  KM BREAK EVENT

;; do reset
        rst     $00               ;{{1DD0:c7}} 

;;====================================================================
;; km scan keys sub

km_scan_keys_sub:                 ;{{Addr=$1dd1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1DD1:e5}} 
        push    de                ;{{1DD2:d5}} 
_km_scan_keys_sub_2:              ;{{Addr=$1dd3 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{1DD3:5f}} 
        cpl                       ;{{1DD4:2f}} 
        inc     a                 ;{{1DD5:3c}} 
        and     e                 ;{{1DD6:a3}} 
        ld      b,a               ;{{1DD7:47}} 
        ld      a,(KB_delay_period_);{{1DD8:3a34b6}} 
        call    _ind_km_scan_keys_57;{{1DDB:cda11d}} 
        ld      a,b               ;{{1DDE:78}} 
        xor     e                 ;{{1DDF:ab}} 
        jr      nz,_km_scan_keys_sub_2;{{1DE0:20f1}}  (-&0f)
        pop     de                ;{{1DE2:d1}} 
        pop     hl                ;{{1DE3:e1}} 
        ret                       ;{{1DE4:c9}} 

;;===========================================================================
;; KM GET JOYSTICK

KM_GET_JOYSTICK:                  ;{{Addr=$1de5 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(RAM_b63b)      ;{{1DE5:3a3bb6}} 
        and     $7f               ;{{1DE8:e67f}} 
        ld      l,a               ;{{1DEA:6f}} 
        ld      a,(RAM_b63e)      ;{{1DEB:3a3eb6}} 
        and     $7f               ;{{1DEE:e67f}} 
        ld      h,a               ;{{1DF0:67}} 
        ret                       ;{{1DF1:c9}} 

;;===========================================================================
;; KM GET DELAY

KM_GET_DELAY:                     ;{{Addr=$1df2 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(KB_repeat_period_);{{1DF2:2a33b6}} 
        ret                       ;{{1DF5:c9}} 

;;===========================================================================
;; KM SET DELAY

KM_SET_DELAY:                     ;{{Addr=$1df6 Code Calls/jump count: 1 Data use count: 1}}
        ld      (KB_repeat_period_),hl;{{1DF6:2233b6}} 
        ret                       ;{{1DF9:c9}} 

;;===========================================================================
;; KM ARM BREAK

KM_ARM_BREAK:                     ;{{Addr=$1dfa Code Calls/jump count: 0 Data use count: 1}}
        call    KM_DISARM_BREAK   ;{{1DFA:cd0b1e}}  KM DISARM BREAK
        ld      hl,event_block_for_Keyboard_handling_compr;{{1DFD:2157b6}} 
        ld      b,$40             ;{{1E00:0640}} 
        call    KL_INIT_EVENT     ;{{1E02:cdd201}}  KL INIT EVENT
        ld      a,$ff             ;{{1E05:3eff}} 
        ld      (RAM_b656),a      ;{{1E07:3256b6}} 
        ret                       ;{{1E0A:c9}} 

;;===========================================================================
;; KM DISARM BREAK

KM_DISARM_BREAK:                  ;{{Addr=$1e0b Code Calls/jump count: 2 Data use count: 1}}
        push    bc                ;{{1E0B:c5}} 
        push    de                ;{{1E0C:d5}} 
        ld      hl,RAM_b656       ;{{1E0D:2156b6}} 
        ld      (hl),$00          ;{{1E10:3600}} 
        inc     hl                ;{{1E12:23}} 
        call    KL_DEL_SYNCHRONOUS;{{1E13:cd8402}}  KL DEL SYNCHRONOUS
        pop     de                ;{{1E16:d1}} 
        pop     bc                ;{{1E17:c1}} 
        ret                       ;{{1E18:c9}} 

;;===========================================================================
;; KM BREAK EVENT

KM_BREAK_EVENT:                   ;{{Addr=$1e19 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,RAM_b656       ;{{1E19:2156b6}} 
        ld      a,(hl)            ;{{1E1C:7e}} 
        ld      (hl),$00          ;{{1E1D:3600}} 
        cp      (hl)              ;{{1E1F:be}} 
        ret     z                 ;{{1E20:c8}} 

        push    bc                ;{{1E21:c5}} 
        push    de                ;{{1E22:d5}} 
        inc     hl                ;{{1E23:23}} 
        call    KL_EVENT          ;{{1E24:cde201}}  KL EVENT
        ld      c,$ef             ;{{1E27:0eef}} 
        call    km_unknown_function_1;{{1E29:cd861e}} 
        pop     de                ;{{1E2C:d1}} 
        pop     bc                ;{{1E2D:c1}} 
        ret                       ;{{1E2E:c9}} 

;;===========================================================================
;; KM GET REPEAT

KM_GET_REPEAT:                    ;{{Addr=$1e2f Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_KB_repeats_table);{{1E2F:2a91b6}} 
        jr      _km_test_key_6    ;{{1E32:181c}}  (+&1c)

;;===========================================================================
;; KM SET REPEAT

KM_SET_REPEAT:                    ;{{Addr=$1e34 Code Calls/jump count: 0 Data use count: 1}}
        cp      $50               ;{{1E34:fe50}} 
        ret     nc                ;{{1E36:d0}} 

        ld      hl,(address_of_the_KB_repeats_table);{{1E37:2a91b6}} 
        call    _km_test_key_9    ;{{1E3A:cd551e}} 
        cpl                       ;{{1E3D:2f}} 
        ld      c,a               ;{{1E3E:4f}} 
        ld      a,(hl)            ;{{1E3F:7e}} 
        xor     b                 ;{{1E40:a8}} 
        and     c                 ;{{1E41:a1}} 
        xor     b                 ;{{1E42:a8}} 
        ld      (hl),a            ;{{1E43:77}} 
        ret                       ;{{1E44:c9}} 

;;===========================================================================
;; KM TEST KEY

KM_TEST_KEY:                      ;{{Addr=$1e45 Code Calls/jump count: 1 Data use count: 1}}
        push    af                ;{{1E45:f5}} 
        ld      a,(RAM_b637)      ;{{1E46:3a37b6}} 
        and     $a0               ;{{1E49:e6a0}} 
        ld      c,a               ;{{1E4B:4f}} 
        pop     af                ;{{1E4C:f1}} 
        ld      hl,Tables_used_for_key_scanning_bits_;{{1E4D:2135b6}} 
_km_test_key_6:                   ;{{Addr=$1e50 Code Calls/jump count: 1 Data use count: 0}}
        call    _km_test_key_9    ;{{1E50:cd551e}} 
        and     (hl)              ;{{1E53:a6}} 
        ret                       ;{{1E54:c9}} 

;;-------------------------------------------------------
_km_test_key_9:                   ;{{Addr=$1e55 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{1E55:d5}} 
        push    af                ;{{1E56:f5}} 
        and     $f8               ;{{1E57:e6f8}} 
        rrca                      ;{{1E59:0f}} 
        rrca                      ;{{1E5A:0f}} 
        rrca                      ;{{1E5B:0f}} 
        ld      e,a               ;{{1E5C:5f}} 
        ld      d,$00             ;{{1E5D:1600}} 
        add     hl,de             ;{{1E5F:19}} 
        pop     af                ;{{1E60:f1}} 

        push    hl                ;{{1E61:e5}} 
        ld      hl,table_to_convert_from_bit_index_07_to_bit_OR_mask_1bit_index;{{1E62:216d1e}} 
        and     $07               ;{{1E65:e607}} 
        ld      e,a               ;{{1E67:5f}} 
        add     hl,de             ;{{1E68:19}} 
        ld      a,(hl)            ;{{1E69:7e}} 
        pop     hl                ;{{1E6A:e1}} 
        pop     de                ;{{1E6B:d1}} 
        ret                       ;{{1E6C:c9}} 

;;===========================================================================
;; table to convert from bit index (0-7) to bit OR mask (1<<bit index)
table_to_convert_from_bit_index_07_to_bit_OR_mask_1bit_index:;{{Addr=$1e6d Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $01,$02,$04,$08,$10,$20,$40,$80

;;===========================================================================
;;km reset or clear?
km_reset_or_clear:                ;{{Addr=$1e75 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{1E75:f3}} 
        ld      hl,RAM_b686       ;{{1E76:2186b6}} 
        ld      (hl),$15          ;{{1E79:3615}} 
        inc     hl                ;{{1E7B:23}} 
        xor     a                 ;{{1E7C:af}} 
        ld      (hl),a            ;{{1E7D:77}} 
        inc     hl                ;{{1E7E:23}} 
        ld      (hl),$01          ;{{1E7F:3601}} 
        inc     hl                ;{{1E81:23}} 
        ld      (hl),a            ;{{1E82:77}} 
        inc     hl                ;{{1E83:23}} 
        ld      (hl),a            ;{{1E84:77}} 
        ret                       ;{{1E85:c9}} 

;;===========================================================================
;; km unknown function 1
km_unknown_function_1:            ;{{Addr=$1e86 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b686       ;{{1E86:2186b6}} 
        or      a                 ;{{1E89:b7}} 
        dec     (hl)              ;{{1E8A:35}} 
        jr      z,_km_unknown_function_1_12;{{1E8B:280e}}  (+&0e)
        call    _km_unknown_function_2_14;{{1E8D:cdb41e}} 
        ld      (hl),c            ;{{1E90:71}} 
        inc     hl                ;{{1E91:23}} 
        ld      (hl),b            ;{{1E92:70}} 
        ld      hl,RAM_b68a       ;{{1E93:218ab6}} 
        inc     (hl)              ;{{1E96:34}} 
        ld      hl,number_of_keys_left_in_key_buffer;{{1E97:2188b6}} 
        scf                       ;{{1E9A:37}} 
_km_unknown_function_1_12:        ;{{Addr=$1e9b Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{1E9B:34}} 
        ret                       ;{{1E9C:c9}} 

;;===========================================================================
;; km unknown function 2
km_unknown_function_2:            ;{{Addr=$1e9d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,number_of_keys_left_in_key_buffer;{{1E9D:2188b6}} 
        or      a                 ;{{1EA0:b7}} 
        dec     (hl)              ;{{1EA1:35}} 
        jr      z,_km_unknown_function_2_12;{{1EA2:280e}}  (+&0e)
        call    _km_unknown_function_2_14;{{1EA4:cdb41e}} 
        ld      c,(hl)            ;{{1EA7:4e}} 
        inc     hl                ;{{1EA8:23}} 
        ld      b,(hl)            ;{{1EA9:46}} 
        ld      hl,RAM_b68a       ;{{1EAA:218ab6}} 
        dec     (hl)              ;{{1EAD:35}} 
        ld      hl,RAM_b686       ;{{1EAE:2186b6}} 
        scf                       ;{{1EB1:37}} 
_km_unknown_function_2_12:        ;{{Addr=$1eb2 Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{1EB2:34}} 
        ret                       ;{{1EB3:c9}} 

;;-----------------------------------------------------------
_km_unknown_function_2_14:        ;{{Addr=$1eb4 Code Calls/jump count: 2 Data use count: 0}}
        inc     hl                ;{{1EB4:23}} 
        inc     (hl)              ;{{1EB5:34}} 
        ld      a,(hl)            ;{{1EB6:7e}} 
        cp      $14               ;{{1EB7:fe14}} 
        jr      nz,_km_unknown_function_2_21;{{1EB9:2002}}  (+&02)

        xor     a                 ;{{1EBB:af}} 
        ld      (hl),a            ;{{1EBC:77}} 

_km_unknown_function_2_21:        ;{{Addr=$1ebd Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{1EBD:87}} 
        add     a,$5e             ;{{1EBE:c65e}} 
        ld      l,a               ;{{1EC0:6f}} 
        ld      h,$b6             ;{{1EC1:26b6}} 
        ret                       ;{{1EC3:c9}} 

;;===========================================================================
;; KM GET TRANSLATE

KM_GET_TRANSLATE:                 ;{{Addr=$1ec4 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_normal_key_table);{{1EC4:2a8bb6}} 
        jr      _km_get_control__1;{{1EC7:1808}}  (+&08)

;;===========================================================================
;; KM GET SHIFT

KM_GET_SHIFT:                     ;{{Addr=$1ec9 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_shifted_key_table);{{1EC9:2a8db6}} 
        jr      _km_get_control__1;{{1ECC:1803}}  (+&03)

;;===========================================================================
;; KM GET CONTROL 

KM_GET_CONTROL_:                  ;{{Addr=$1ece Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_the_control_key_table);{{1ECE:2a8fb6}} 

_km_get_control__1:               ;{{Addr=$1ed1 Code Calls/jump count: 2 Data use count: 0}}
        add     a,l               ;{{1ED1:85}} 
        ld      l,a               ;{{1ED2:6f}} 
        adc     a,h               ;{{1ED3:8c}} 
        sub     l                 ;{{1ED4:95}} 
        ld      h,a               ;{{1ED5:67}} 
        ld      a,(hl)            ;{{1ED6:7e}} 
        ret                       ;{{1ED7:c9}} 

;;===========================================================================
;; KM SET TRANSLATE

KM_SET_TRANSLATE:                 ;{{Addr=$1ed8 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_normal_key_table);{{1ED8:2a8bb6}} 
        jr      _km_set_control_1 ;{{1EDB:1808}}  (+&08)

;;===========================================================================
;; KM SET SHIFT

KM_SET_SHIFT:                     ;{{Addr=$1edd Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_shifted_key_table);{{1EDD:2a8db6}} 
        jr      _km_set_control_1 ;{{1EE0:1803}}  (+&03)

;;===========================================================================
;; KM SET CONTROL

KM_SET_CONTROL:                   ;{{Addr=$1ee2 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_the_control_key_table);{{1EE2:2a8fb6}} 
_km_set_control_1:                ;{{Addr=$1ee5 Code Calls/jump count: 2 Data use count: 0}}
        cp      $50               ;{{1EE5:fe50}} 
        ret     nc                ;{{1EE7:d0}} 

        add     a,l               ;{{1EE8:85}} 
        ld      l,a               ;{{1EE9:6f}} 
        adc     a,h               ;{{1EEA:8c}} 
        sub     l                 ;{{1EEB:95}} 
        ld      h,a               ;{{1EEC:67}} 
        ld      (hl),b            ;{{1EED:70}} 
        ret                       ;{{1EEE:c9}} 

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




