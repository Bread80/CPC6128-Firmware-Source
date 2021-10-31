;; SCREEN ROUTINES
;;===========================================================================
;; SCR INITIALISE

SCR_INITIALISE:                   ;{{Addr=$0abf Code Calls/jump count: 1 Data use count: 1}}
        ld      de,default_colour_palette;{{0abf:115210}} ; default colour palette
        call    MC_CLEAR_INKS     ;{{0ac2:cd8607}} ; MC CLEAR INKS
        ld      a,$c0             ;{{0ac5:3ec0}} 
        ld      (screen_base_HB_),a;{{0ac7:32c6b7}} 
        call    SCR_RESET         ;{{0aca:cdd00a}} ; SCR RESET
        jp      set_mode_1        ;{{0acd:c3120b}} 

;;===========================================================================
;; SCR RESET

SCR_RESET:                        ;{{Addr=$0ad0 Code Calls/jump count: 2 Data use count: 1}}
        xor     a                 ;{{0ad0:af}} 
        call    SCR_ACCESS        ;{{0ad1:cd550c}} ; SCR ACCESS
        ld      hl,_scr_reset_5   ;{{0ad4:21dd0a}} ; table used to initialise screen indirections
        call    initialise_firmware_indirections;{{0ad7:cdb40a}} ; initialise screen pack indirections
        jp      restore_colours_and_set_default_flashing;{{0ada:c3d80c}} ; restore colours and set default flashing

_scr_reset_5:                     ;{{Addr=$0add Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $09                  
        defw SCR_READ                
        jp      IND_SCR_READ      ;{{0ae0:c38a0c}} ; IND: SCR READ
        jp      IND_SCR_WRITE     ;{{0ae3:c3710c}} ; IND: SCR WRITE
        jp      IND_SCR_MODE_CLEAR;{{0ae6:c3170b}} ; IND: SCR MODE CLEAR

;;===========================================================================
;; SCR SET MODE

SCR_SET_MODE:                     ;{{Addr=$0ae9 Code Calls/jump count: 0 Data use count: 2}}
        and     $03               ;{{0ae9:e603}} 
        cp      $03               ;{{0aeb:fe03}} 
        ret     nc                ;{{0aed:d0}} 

        push    af                ;{{0aee:f5}} 
        call    delete_palette_swap_event;{{0aef:cd550d}} 
        pop     de                ;{{0af2:d1}} 
        call    clean_up_streams  ;{{0af3:cdb310}} 
        push    af                ;{{0af6:f5}} 
        call    x15ce_code        ;{{0af7:cdce15}} 
        push    hl                ;{{0afa:e5}} 
        ld      a,d               ;{{0afb:7a}} 
        call    set_mode_         ;{{0afc:cd310b}} 
        call    SCR_MODE_CLEAR    ;{{0aff:cdebbd}}  IND: SCR MODE CLEAR
        pop     hl                ;{{0b02:e1}} 
        call    _gra_initialise_2 ;{{0b03:cdae15}} 
        pop     af                ;{{0b06:f1}} 
        call    initialise_txt_streams;{{0b07:cdd110}} 
        jr      _ind_scr_mode_clear_10;{{0b0a:1822}}  (+&22)

;;===========================================================================
;; SCR GET MODE

SCR_GET_MODE:                     ;{{Addr=$0b0c Code Calls/jump count: 10 Data use count: 1}}
        ld      a,(MODE_number)   ;{{0b0c:3ac3b7}} 
        cp      $01               ;{{0b0f:fe01}} 
        ret                       ;{{0b11:c9}} 

;;==========================================================================
;;set mode 1
set_mode_1:                       ;{{Addr=$0b12 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$01             ;{{0b12:3e01}} 
        call    set_mode_         ;{{0b14:cd310b}} 

;;===========================================================================
;; IND: SCR MODE CLEAR

IND_SCR_MODE_CLEAR:               ;{{Addr=$0b17 Code Calls/jump count: 1 Data use count: 1}}
        call    delete_palette_swap_event;{{0b17:cd550d}} 
        ld      hl,$0000          ;{{0b1a:210000}} ##LIT##;WARNING: Code area used as literal
        call    SCR_OFFSET        ;{{0b1d:cd370b}} ; SCR OFFSET
        ld      hl,($b7c5)        ;{{0b20:2ac5b7}} 
        ld      l,$00             ;{{0b23:2e00}} 
        ld      d,h               ;{{0b25:54}} 
        ld      e,$01             ;{{0b26:1e01}} 
        ld      bc,$3fff          ;{{0b28:01ff3f}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),l            ;{{0b2b:75}} 
        ldir                      ;{{0b2c:edb0}} 
_ind_scr_mode_clear_10:           ;{{Addr=$0b2e Code Calls/jump count: 1 Data use count: 0}}
        jp      setup_palette_swap_event;{{0b2e:c3420d}} 

;;===========================================================================
;; set mode 
set_mode_:                        ;{{Addr=$0b31 Code Calls/jump count: 2 Data use count: 0}}
        ld      (MODE_number),a   ;{{0b31:32c3b7}} 
        jp      MC_SET_MODE       ;{{0b34:c37607}}  MC SET MODE

;;===========================================================================
;; SCR OFFSET

SCR_OFFSET:                       ;{{Addr=$0b37 Code Calls/jump count: 2 Data use count: 1}}
        ld      a,(screen_base_HB_);{{0b37:3ac6b7}} 
        jr      _scr_set_base_1   ;{{0b3a:1803}}  (+&03)

;;===========================================================================
;; SCR SET BASE

SCR_SET_BASE:                     ;{{Addr=$0b3c Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(screen_offset);{{0b3c:2ac4b7}} 
_scr_set_base_1:                  ;{{Addr=$0b3f Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_SET_POSITION  ;{{0b3f:cd450b}}  SCR SET POSITION
        jp      MC_SCREEN_OFFSET  ;{{0b42:c3c007}}  MC SCREEN OFFSET

;;===========================================================================
;; SCR SET POSITION

SCR_SET_POSITION:                 ;{{Addr=$0b45 Code Calls/jump count: 1 Data use count: 1}}
        and     $c0               ;{{0b45:e6c0}} 
        ld      (screen_base_HB_),a;{{0b47:32c6b7}} 
        push    af                ;{{0b4a:f5}} 
        ld      a,h               ;{{0b4b:7c}} 
        and     $07               ;{{0b4c:e607}} 
        ld      h,a               ;{{0b4e:67}} 
        res     0,l               ;{{0b4f:cb85}} 
        ld      (screen_offset),hl;{{0b51:22c4b7}} 
        pop     af                ;{{0b54:f1}} 
        ret                       ;{{0b55:c9}} 

;;===========================================================================
;; SCR GET LOCATION

SCR_GET_LOCATION:                 ;{{Addr=$0b56 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(screen_offset);{{0b56:2ac4b7}} 
        ld      a,(screen_base_HB_);{{0b59:3ac6b7}} 
        ret                       ;{{0b5c:c9}} 

;;======================================================================================
;; SCR CHAR LIMITS
SCR_CHAR_LIMITS:                  ;{{Addr=$0b5d Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_GET_MODE      ;{{0b5d:cd0c0b}} ; SCR GET MODE
        ld      bc,$1318          ;{{0b60:011813}} ; B = 19, C = 24 ##LIT##;WARNING: Code area used as literal
        ret     c                 ;{{0b63:d8}} 

        ld      b,$27             ;{{0b64:0627}} ; 39
        ret     z                 ;{{0b66:c8}} 

        ld      b,$4f             ;{{0b67:064f}} ; 79
;; B = x limit-1
;; C = y limit-1
        ret                       ;{{0b69:c9}} 

;;======================================================================================
;; SCR CHAR POSITION

SCR_CHAR_POSITION:                ;{{Addr=$0b6a Code Calls/jump count: 7 Data use count: 1}}
        push    de                ;{{0b6a:d5}} 
        call    SCR_GET_MODE      ;{{0b6b:cd0c0b}} ; SCR GET MODE
        ld      b,$04             ;{{0b6e:0604}} 
        jr      c,_scr_char_position_7;{{0b70:3805}}  (+&05)
        ld      b,$02             ;{{0b72:0602}} 
        jr      z,_scr_char_position_7;{{0b74:2801}}  (+&01)
        dec     b                 ;{{0b76:05}} 
_scr_char_position_7:             ;{{Addr=$0b77 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0b77:c5}} 
        ld      e,h               ;{{0b78:5c}} 
        ld      d,$00             ;{{0b79:1600}} 
        ld      h,d               ;{{0b7b:62}} 
        push    de                ;{{0b7c:d5}} 
        ld      d,h               ;{{0b7d:54}} 
        ld      e,l               ;{{0b7e:5d}} 
        add     hl,hl             ;{{0b7f:29}} 
        add     hl,hl             ;{{0b80:29}} 
        add     hl,de             ;{{0b81:19}} 
        add     hl,hl             ;{{0b82:29}} 
        add     hl,hl             ;{{0b83:29}} 
        add     hl,hl             ;{{0b84:29}} 
        add     hl,hl             ;{{0b85:29}} 
        pop     de                ;{{0b86:d1}} 
_scr_char_position_22:            ;{{Addr=$0b87 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{0b87:19}} 
        djnz    _scr_char_position_22;{{0b88:10fd}}  (-&03)
        ld      de,(screen_offset);{{0b8a:ed5bc4b7}} 
        add     hl,de             ;{{0b8e:19}} 
        ld      a,h               ;{{0b8f:7c}} 
        and     $07               ;{{0b90:e607}} 
        ld      h,a               ;{{0b92:67}} 
        ld      a,(screen_base_HB_);{{0b93:3ac6b7}} 
        add     a,h               ;{{0b96:84}} 
        ld      h,a               ;{{0b97:67}} 
        pop     bc                ;{{0b98:c1}} 
        pop     de                ;{{0b99:d1}} 
        ret                       ;{{0b9a:c9}} 

_scr_char_position_35:            ;{{Addr=$0b9b Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{0b9b:7b}} 
        sub     l                 ;{{0b9c:95}} 
        inc     a                 ;{{0b9d:3c}} 
        add     a,a               ;{{0b9e:87}} 
        add     a,a               ;{{0b9f:87}} 
        add     a,a               ;{{0ba0:87}} 
        ld      e,a               ;{{0ba1:5f}} 
        ld      a,d               ;{{0ba2:7a}} 
        sub     h                 ;{{0ba3:94}} 
        inc     a                 ;{{0ba4:3c}} 
        ld      d,a               ;{{0ba5:57}} 
        call    SCR_CHAR_POSITION ;{{0ba6:cd6a0b}}  SCR CHAR POSITION
        xor     a                 ;{{0ba9:af}} 
_scr_char_position_48:            ;{{Addr=$0baa Code Calls/jump count: 1 Data use count: 0}}
        add     a,d               ;{{0baa:82}} 
        djnz    _scr_char_position_48;{{0bab:10fd}}  (-&03)
        ld      d,a               ;{{0bad:57}} 
        ret                       ;{{0bae:c9}} 

;;======================================================================================
;; SCR DOT POSITION

SCR_DOT_POSITION:                 ;{{Addr=$0baf Code Calls/jump count: 9 Data use count: 1}}
        push    de                ;{{0baf:d5}} 
        ex      de,hl             ;{{0bb0:eb}} 
        ld      hl,$00c7          ;{{0bb1:21c700}} ##LIT##;WARNING: Code area used as literal
        or      a                 ;{{0bb4:b7}} 
        sbc     hl,de             ;{{0bb5:ed52}} 
        ld      a,l               ;{{0bb7:7d}} 
        and     $07               ;{{0bb8:e607}} 
        add     a,a               ;{{0bba:87}} 
        add     a,a               ;{{0bbb:87}} 
        add     a,a               ;{{0bbc:87}} 
        ld      c,a               ;{{0bbd:4f}} 
        ld      a,l               ;{{0bbe:7d}} 
        and     $f8               ;{{0bbf:e6f8}} 
        ld      l,a               ;{{0bc1:6f}} 
        ld      d,h               ;{{0bc2:54}} 
        ld      e,l               ;{{0bc3:5d}} 
        add     hl,hl             ;{{0bc4:29}} 
        add     hl,hl             ;{{0bc5:29}} 
        add     hl,de             ;{{0bc6:19}} 
        add     hl,hl             ;{{0bc7:29}} 
        pop     de                ;{{0bc8:d1}} 
        push    bc                ;{{0bc9:c5}} 
        call    _scr_dot_position_52;{{0bca:cdf60b}} 
        ld      a,b               ;{{0bcd:78}} 
        and     e                 ;{{0bce:a3}} 
        jr      z,_scr_dot_position_29;{{0bcf:2805}}  (+&05)
_scr_dot_position_26:             ;{{Addr=$0bd1 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0bd1:cb09}} 
        dec     a                 ;{{0bd3:3d}} 
        jr      nz,_scr_dot_position_26;{{0bd4:20fb}}  (-&05)
_scr_dot_position_29:             ;{{Addr=$0bd6 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{0bd6:e3}} 
        ld      h,c               ;{{0bd7:61}} 
        ld      c,l               ;{{0bd8:4d}} 
        ex      (sp),hl           ;{{0bd9:e3}} 
        ld      a,b               ;{{0bda:78}} 
        rrca                      ;{{0bdb:0f}} 
_scr_dot_position_35:             ;{{Addr=$0bdc Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{0bdc:cb3a}} 
        rr      e                 ;{{0bde:cb1b}} 
        rrca                      ;{{0be0:0f}} 
        jr      c,_scr_dot_position_35;{{0be1:38f9}}  (-&07)
        add     hl,de             ;{{0be3:19}} 
        ld      de,(screen_offset);{{0be4:ed5bc4b7}} 
        add     hl,de             ;{{0be8:19}} 
        ld      a,h               ;{{0be9:7c}} 
        and     $07               ;{{0bea:e607}} 
        ld      h,a               ;{{0bec:67}} 
        ld      a,(screen_base_HB_);{{0bed:3ac6b7}} 
        add     a,h               ;{{0bf0:84}} 
        add     a,c               ;{{0bf1:81}} 
        ld      h,a               ;{{0bf2:67}} 
        pop     de                ;{{0bf3:d1}} 
        ld      c,d               ;{{0bf4:4a}} 
        ret                       ;{{0bf5:c9}} 

;;---------------------------------------------------------------------
_scr_dot_position_52:             ;{{Addr=$0bf6 Code Calls/jump count: 3 Data use count: 0}}
        call    SCR_GET_MODE      ;{{0bf6:cd0c0b}} ; SCR GET MODE
        ld      bc,$01aa          ;{{0bf9:01aa01}} ##LIT##;WARNING: Code area used as literal
        ret     c                 ;{{0bfc:d8}} 

        ld      bc,$0388          ;{{0bfd:018803}} ##LIT##;WARNING: Code area used as literal
        ret     z                 ;{{0c00:c8}} 

        ld      bc,$0780          ;{{0c01:018007}} ##LIT##;WARNING: Code area used as literal
        ret                       ;{{0c04:c9}} 


;;======================================================
;; SCR NEXT BYTE
;;
;; Entry conditions:
;; HL = screen address
;; Exit conditions:
;; HL = updated screen address
;; AF corrupt
;;
;; Assumes:
;; - 16k screen

SCR_NEXT_BYTE:                    ;{{Addr=$0c05 Code Calls/jump count: 9 Data use count: 1}}
        inc     l                 ;{{0c05:2c}} 
        ret     nz                ;{{0c06:c0}} 

        inc     h                 ;{{0c07:24}} 
        ld      a,h               ;{{0c08:7c}} 
        and     $07               ;{{0c09:e607}} 
        ret     nz                ;{{0c0b:c0}} 

;; at this point the address has incremented over a 2048
;; byte boundary.
;;
;; At this point, the next byte on screen is *not* previous byte plus 1.
;;
;; The following is true:
;; 07FF->0000
;; 0FFF->0800
;; 17FF->1000
;; 1FFF->1800
;; 27FF->2000
;; 2FFF->2800
;; 37FF->3000
;; 3FFF->3800
;;
;; The following code adjusts for this case.

        ld      a,h               ;{{0c0c:7c}} 
        sub     $08               ;{{0c0d:d608}} 
        ld      h,a               ;{{0c0f:67}} 
        ret                       ;{{0c10:c9}} 

;;======================================================
;; SCR PREV BYTE
;;
;; Entry conditions:
;; HL = screen address
;; Exit conditions:
;; HL = updated screen address
;; AF corrupt
;;
;; Assumes:
;; - 16k screen

SCR_PREV_BYTE:                    ;{{Addr=$0c11 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,l               ;{{0c11:7d}} 
        dec     l                 ;{{0c12:2d}} 
        or      a                 ;{{0c13:b7}} 
        ret     nz                ;{{0c14:c0}} 

        ld      a,h               ;{{0c15:7c}} 
        dec     h                 ;{{0c16:25}} 
        and     $07               ;{{0c17:e607}} 
        ret     nz                ;{{0c19:c0}} 

        ld      a,h               ;{{0c1a:7c}} 
        add     a,$08             ;{{0c1b:c608}} 
        ld      h,a               ;{{0c1d:67}} 
        ret                       ;{{0c1e:c9}} 

;;====================================================
;; SCR NEXT LINE
;;
;; Entry conditions:
;; HL = screen address
;; Exit conditions:
;; HL = updated screen address
;; AF corrupt
;;
;; Assumes:
;; - 16k screen
;; - 80 bytes per line (40 CRTC characters per line)

SCR_NEXT_LINE:                    ;{{Addr=$0c1f Code Calls/jump count: 10 Data use count: 1}}
        ld      a,h               ;{{0c1f:7c}} 
        add     a,$08             ;{{0c20:c608}} 
        ld      h,a               ;{{0c22:67}} 


        and     $38               ;{{0c23:e638}} 
        ret     nz                ;{{0c25:c0}} 

;; 

        ld      a,h               ;{{0c26:7c}} 
        sub     $40               ;{{0c27:d640}} 
        ld      h,a               ;{{0c29:67}} 
        ld      a,l               ;{{0c2a:7d}} 
        add     a,$50             ;{{0c2b:c650}} ; number of bytes per line
        ld      l,a               ;{{0c2d:6f}} 
        ret     nc                ;{{0c2e:d0}} 

        inc     h                 ;{{0c2f:24}} 
        ld      a,h               ;{{0c30:7c}} 
        and     $07               ;{{0c31:e607}} 
        ret     nz                ;{{0c33:c0}} 

        ld      a,h               ;{{0c34:7c}} 
        sub     $08               ;{{0c35:d608}} 
        ld      h,a               ;{{0c37:67}} 
        ret                       ;{{0c38:c9}} 

;;=======================================================
;; SCR PREV LINE
;;
;; Entry conditions:
;; HL = screen address
;; Exit conditions:
;; HL = updated screen address
;; AF corrupt
;;
;; Assumes:
;; - 16k screen
;; - 80 bytes per line (40 CRTC characters per line)

SCR_PREV_LINE:                    ;{{Addr=$0c39 Code Calls/jump count: 4 Data use count: 1}}
        ld      a,h               ;{{0c39:7c}} 
        sub     $08               ;{{0c3a:d608}} 
        ld      h,a               ;{{0c3c:67}} 
        and     $38               ;{{0c3d:e638}} 
        cp      $38               ;{{0c3f:fe38}} 
        ret     nz                ;{{0c41:c0}} 

        ld      a,h               ;{{0c42:7c}} 
        add     a,$40             ;{{0c43:c640}} 
        ld      h,a               ;{{0c45:67}} 

        ld      a,l               ;{{0c46:7d}} 
        sub     $50               ;{{0c47:d650}} ; number of bytes per line
        ld      l,a               ;{{0c49:6f}} 
        ret     nc                ;{{0c4a:d0}} 

        ld      a,h               ;{{0c4b:7c}} 
        dec     h                 ;{{0c4c:25}} 
        and     $07               ;{{0c4d:e607}} 
        ret     nz                ;{{0c4f:c0}} 

        ld      a,h               ;{{0c50:7c}} 
        add     a,$08             ;{{0c51:c608}} 
        ld      h,a               ;{{0c53:67}} 
        ret                       ;{{0c54:c9}} 


;;============================================================================
;; SCR ACCESS
;;
;; A = write mode:
;; 0 -> fill
;; 1 -> XOR
;; 2 -> AND
;; 3 -> OR 
SCR_ACCESS:                       ;{{Addr=$0c55 Code Calls/jump count: 2 Data use count: 2}}
        and     $03               ;{{0c55:e603}} 
        ld      hl,SCR_PIXELS     ;{{0c57:21740c}}  SCR PIXELS ##LABEL##
        jr      z,_scr_access_9   ;{{0c5a:280c}}  (+&0c)
        cp      $02               ;{{0c5c:fe02}} 

;;This block will (should) fail to assemble if the addresses reference span a page boundary.
;;Addresses = SCR_PIXELS, SCR_PIXELS_XOR, SCR_PIXELS_AND, SCR_PIXELS_OR
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_XOR and $ff00) + (SCR_PIXELS_XOR and $00ff);{{0c5e:2e7a}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal
        jr      c,_scr_access_9   ;{{0c60:3806}}  (+&06)
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_AND and $ff00) + (SCR_PIXELS_AND and $00ff);{{0c62:2e7f}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal
        jr      z,_scr_access_9   ;{{0c64:2802}}  (+&02)
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_OR and $ff00) + (SCR_PIXELS_OR and $00ff);{{0c66:2e85}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal

;; HL = address of screen write function 
;; initialise jump for IND: SCR WRITE
_scr_access_9:                    ;{{Addr=$0c68 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$c3             ;{{0c68:3ec3}} JP opcode
        ld      (graphics_VDU_write_mode_indirection__JP),a;{{0c6a:32c7b7}} Write JP
        ld      (graphics_VDU_write_mode_indirection__JP + 1),hl;{{0c6d:22c8b7}} Write address to jump to
        ret                       ;{{0c70:c9}} 

;;==================================================================================
;; IND: SCR WRITE

;; jump initialised by SCR ACCESS
IND_SCR_WRITE:                    ;{{Addr=$0c71 Code Calls/jump count: 1 Data use count: 0}}
        jp      graphics_VDU_write_mode_indirection__JP;{{0c71:c3c7b7}} 


;;============================================================================
;; SCR PIXELS
;; (write mode fill)
SCR_PIXELS:                       ;{{Addr=$0c74 Code Calls/jump count: 1 Data use count: 5}}
        ld      a,b               ;{{0c74:78}} 
        xor     (hl)              ;{{0c75:ae}} 
        and     c                 ;{{0c76:a1}} 
        xor     (hl)              ;{{0c77:ae}} 
        ld      (hl),a            ;{{0c78:77}} 
        ret                       ;{{0c79:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS XOR
;; screen write access mode

;; (write mode XOR)
SCR_PIXELS_XOR:                   ;{{Addr=$0c7a Code Calls/jump count: 0 Data use count: 2}}
        ld      a,b               ;{{0c7a:78}} 
        and     c                 ;{{0c7b:a1}} 
        xor     (hl)              ;{{0c7c:ae}} 
        ld      (hl),a            ;{{0c7d:77}} 
        ret                       ;{{0c7e:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS AND
;; screen write access mode
;;
;; (write mode AND)
SCR_PIXELS_AND:                   ;{{Addr=$0c7f Code Calls/jump count: 0 Data use count: 2}}
        ld      a,c               ;{{0c7f:79}} 
        cpl                       ;{{0c80:2f}} 
        or      b                 ;{{0c81:b0}} 
        and     (hl)              ;{{0c82:a6}} 
        ld      (hl),a            ;{{0c83:77}} 
        ret                       ;{{0c84:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS OR
;; screen write access mode
;;
;; (write mode OR)
SCR_PIXELS_OR:                    ;{{Addr=$0c85 Code Calls/jump count: 0 Data use count: 2}}
        ld      a,b               ;{{0c85:78}} 
        and     c                 ;{{0c86:a1}} 
        or      (hl)              ;{{0c87:b6}} 
        ld      (hl),a            ;{{0c88:77}} 
        ret                       ;{{0c89:c9}} 

;;==================================================================================
;; IND: SCR READ
IND_SCR_READ:                     ;{{Addr=$0c8a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0c8a:7e}} 
        jp      _scr_ink_decode_7 ;{{0c8b:c3b20c}} 

;;==================================================================================
;; SCR INK ENCODE
SCR_INK_ENCODE:                   ;{{Addr=$0c8e Code Calls/jump count: 4 Data use count: 1}}
        push    bc                ;{{0c8e:c5}} 
        push    de                ;{{0c8f:d5}} 
        call    _scr_ink_decode_20;{{0c90:cdc80c}} 
        ld      e,a               ;{{0c93:5f}} 
        call    _scr_dot_position_52;{{0c94:cdf60b}} 
        ld      b,$08             ;{{0c97:0608}} 
_scr_ink_encode_6:                ;{{Addr=$0c99 Code Calls/jump count: 1 Data use count: 0}}
        rrc     e                 ;{{0c99:cb0b}} 
        rla                       ;{{0c9b:17}} 
        rrc     c                 ;{{0c9c:cb09}} 
        jr      c,_scr_ink_encode_11;{{0c9e:3802}}  (+&02)
        rlc     e                 ;{{0ca0:cb03}} 
_scr_ink_encode_11:               ;{{Addr=$0ca2 Code Calls/jump count: 1 Data use count: 0}}
        djnz    _scr_ink_encode_6 ;{{0ca2:10f5}}  (-&0b)
        pop     de                ;{{0ca4:d1}} 
        pop     bc                ;{{0ca5:c1}} 
        ret                       ;{{0ca6:c9}} 

;;============================================================================
;; SCR INK DECODE

SCR_INK_DECODE:                   ;{{Addr=$0ca7 Code Calls/jump count: 3 Data use count: 1}}
        push    bc                ;{{0ca7:c5}} 
        push    af                ;{{0ca8:f5}} 
        call    _scr_dot_position_52;{{0ca9:cdf60b}} 
        pop     af                ;{{0cac:f1}} 
        call    _scr_ink_decode_7 ;{{0cad:cdb20c}} 
        pop     bc                ;{{0cb0:c1}} 
        ret                       ;{{0cb1:c9}} 

;;-----------------------------------------------------------------------------

_scr_ink_decode_7:                ;{{Addr=$0cb2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{0cb2:d5}} 
        ld      de,$0008          ;{{0cb3:110800}} ##LIT##;WARNING: Code area used as literal
_scr_ink_decode_9:                ;{{Addr=$0cb6 Code Calls/jump count: 1 Data use count: 0}}
        rrca                      ;{{0cb6:0f}} 
        rl      d                 ;{{0cb7:cb12}} 
        rrc     c                 ;{{0cb9:cb09}} 
        jr      c,_scr_ink_decode_14;{{0cbb:3802}}  (+&02)
        rr      d                 ;{{0cbd:cb1a}} 
_scr_ink_decode_14:               ;{{Addr=$0cbf Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{0cbf:1d}} 
        jr      nz,_scr_ink_decode_9;{{0cc0:20f4}}  (-&0c)
        ld      a,d               ;{{0cc2:7a}} 
        call    _scr_ink_decode_20;{{0cc3:cdc80c}} 
        pop     de                ;{{0cc6:d1}} 
        ret                       ;{{0cc7:c9}} 

;;-----------------------------------------------------------------------------
_scr_ink_decode_20:               ;{{Addr=$0cc8 Code Calls/jump count: 2 Data use count: 0}}
        ld      d,a               ;{{0cc8:57}} 
        call    SCR_GET_MODE      ;{{0cc9:cd0c0b}} ; SCR GET MODE
        ld      a,d               ;{{0ccc:7a}} 
        ret     nc                ;{{0ccd:d0}} 
        rrca                      ;{{0cce:0f}} 
        rrca                      ;{{0ccf:0f}} 
        adc     a,$00             ;{{0cd0:ce00}} 
        rrca                      ;{{0cd2:0f}} 
        sbc     a,a               ;{{0cd3:9f}} 
        and     $06               ;{{0cd4:e606}} 
        xor     d                 ;{{0cd6:aa}} 
        ret                       ;{{0cd7:c9}} 

;;========================================================
;; restore colours and set default flashing
restore_colours_and_set_default_flashing:;{{Addr=$0cd8 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,default_colour_palette;{{0cd8:215210}} ; default colour palette
        ld      de,hw_04__sw_1_   ;{{0cdb:11d4b7}} 
        ld      bc,$0022          ;{{0cde:012200}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{0ce1:edb0}} 
        xor     a                 ;{{0ce3:af}} 
        ld      (RAM_b7f6),a      ;{{0ce4:32f6b7}} 
        ld      hl,$0a0a          ;{{0ce7:210a0a}} ##LIT##;WARNING: Code area used as literal

;;============================================================================
;; SCR SET FLASHING

SCR_SET_FLASHING:                 ;{{Addr=$0cea Code Calls/jump count: 0 Data use count: 1}}
        ld      (first_flash_period_),hl;{{0cea:22d2b7}} 
        ret                       ;{{0ced:c9}} 


;;============================================================================
;; SCR GET FLASHING

SCR_GET_FLASHING:                 ;{{Addr=$0cee Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(first_flash_period_);{{0cee:2ad2b7}} 
        ret                       ;{{0cf1:c9}} 

;;============================================================================
;; SCR SET INK
SCR_SET_INK:                      ;{{Addr=$0cf2 Code Calls/jump count: 1 Data use count: 1}}
        and     $0f               ;{{0cf2:e60f}}  keep pen within 0-15 range
        inc     a                 ;{{0cf4:3c}} 
        jr      _scr_set_border_1 ;{{0cf5:1801}} 

;;============================================================================
;; SCR SET BORDER
SCR_SET_BORDER:                   ;{{Addr=$0cf7 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{0cf7:af}} 
;;----------------------------------------------------------------------------
;; SCR SET INK/SCR SET BORDER
;;
;; A = internal pen number
;; B = ink 1 (firmware colour number)
;; C = ink 2 (firmware colour number)
;; 0 = border
;; 1 = colour 0
;; 2 = colour 1
;; ...
;; 16 = colour 15
_scr_set_border_1:                ;{{Addr=$0cf8 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{0cf8:5f}} 

        ld      a,b               ;{{0cf9:78}} 
        call    software_colour_to_hardware_colour;{{0cfa:cd100d}}  lookup address of hardware colour number in conversion
                                  ; table using software colour number
									
        ld      b,(hl)            ;{{0cfd:46}}  get hardware colour number for ink 1

        ld      a,c               ;{{0cfe:79}} 
        call    software_colour_to_hardware_colour;{{0cff:cd100d}}  lookup address of hardware colour number in conversion
                                  ; table using software colour number
									
        ld      c,(hl)            ;{{0d02:4e}}  get hardware colour number for ink 2

        ld      a,e               ;{{0d03:7b}} 
        call    get_palette_entry_addresses;{{0d04:cd350d}}  get address of pen in both palette's in RAM

        ld      (hl),c            ;{{0d07:71}}  write ink 2
        ex      de,hl             ;{{0d08:eb}} 
        ld      (hl),b            ;{{0d09:70}}  write ink 1

        ld      a,$ff             ;{{0d0a:3eff}} 
        ld      (RAM_b7f7),a      ;{{0d0c:32f7b7}} 
        ret                       ;{{0d0f:c9}} 

;;============================================================================
;; software colour to hardware colour
;; input:
;; A = software colour number
;; output:
;; HL = address of element in table. Element is corresponding hardware colour number.
software_colour_to_hardware_colour:;{{Addr=$0d10 Code Calls/jump count: 2 Data use count: 0}}
        and     $1f               ;{{0d10:e61f}} 
        add     a,$99             ;{{0d12:c699}} 
        ld      l,a               ;{{0d14:6f}} 
        adc     a,$0d             ;{{0d15:ce0d}} 
        sub     l                 ;{{0d17:95}} 
        ld      h,a               ;{{0d18:67}} 
        ret                       ;{{0d19:c9}} 

;;============================================================================
;; SCR GET INK
SCR_GET_INK:                      ;{{Addr=$0d1a Code Calls/jump count: 0 Data use count: 1}}
        and     $0f               ;{{0d1a:e60f}}  keep pen within range 0-15.
        inc     a                 ;{{0d1c:3c}} 
        jr      _scr_get_border_1 ;{{0d1d:1801}} 

;;============================================================================
;; SCR GET BORDER

SCR_GET_BORDER:                   ;{{Addr=$0d1f Code Calls/jump count: 0 Data use count: 1}}
        xor     a                 ;{{0d1f:af}} 
;;----------------------------------------------------------------------------
;; SCR GET INK/SCR GET BORDER
;; entry:
;; A = internal pen number
;; 0 = border
;; 1 = colour 0
;; 2 = colour 1
;; ...
;; 16 = colour 15
;; exit:
;; B = ink 1 (software colour number)
;; C = ink 2 (software colour number)
_scr_get_border_1:                ;{{Addr=$0d20 Code Calls/jump count: 1 Data use count: 0}}
        call    get_palette_entry_addresses;{{0d20:cd350d}}  get address of pen in both palette's in RAM
        ld      a,(de)            ;{{0d23:1a}}  ink 2

        ld      e,(hl)            ;{{0d24:5e}}  ink 1

        call    _scr_get_border_7 ;{{0d25:cd2a0d}}  lookup hardware colour number for ink 2
        ld      b,c               ;{{0d28:41}} 

;; lookup hardware colour number for ink 1
        ld      a,e               ;{{0d29:7b}} 

;;---------------------------------------------------------------------------
;; lookup software colour number which corresponds to the hardware colour number

;; entry:
;; A = hardware colour number
;; exit:
;; C = index in table (same as software colour number)
_scr_get_border_7:                ;{{Addr=$0d2a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$00             ;{{0d2a:0e00}} 
        ld      hl,software_colour_to_hardware_colour_table;{{0d2c:21990d}}  table to convert from software colour
                                  ; number to hardware colour number
;;----------
_scr_get_border_9:                ;{{Addr=$0d2f Code Calls/jump count: 1 Data use count: 0}}
        cp      (hl)              ;{{0d2f:be}}  same as this entry in the table?
        ret     z                 ;{{0d30:c8}}  zero set if entry is the same, zero clear if entry is different
        inc     hl                ;{{0d31:23}} 
        inc     c                 ;{{0d32:0c}} 
        jr      _scr_get_border_9 ;{{0d33:18fa}} 

;;============================================================================
;; get palette entry addresses
;;
;; The firmware stores two palette's in RAM, this allows a pen to have a flashing ink.
;;
;; get address of palette entry for corresponding ink for both palettes in RAM.
;;
;; entry:
;; A = pen number
;; 0 = border
;; 1 = colour 0
;; 2 = colour 1
;; ...
;; 16 = colour 15
;; 
;; exit:
;; HL = address of element in palette 2
;; DE = address of element in palette 1
get_palette_entry_addresses:      ;{{Addr=$0d35 Code Calls/jump count: 2 Data use count: 0}}
        ld      e,a               ;{{0d35:5f}} 
        ld      d,$00             ;{{0d36:1600}} 
        ld      hl,Border_and_Pens_Second_Inks_;{{0d38:21e5b7}}  palette 2 start
        add     hl,de             ;{{0d3b:19}} 
        ex      de,hl             ;{{0d3c:eb}} 
        ld      hl,$ffef          ;{{0d3d:21efff}}  palette 1 start (B7D4)
        add     hl,de             ;{{0d40:19}} 
        ret                       ;{{0d41:c9}} 
;;============================================================================
;; setup palette swap event
setup_palette_swap_event:         ;{{Addr=$0d42 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b7f9       ;{{0d42:21f9b7}} 
        push    hl                ;{{0d45:e5}} 
        call    KL_DEL_FRAME_FLY  ;{{0d46:cd7001}}  KL DEL FRAME FLY
        call    _frame_flyback_routine_to_swap_palettes_10;{{0d49:cd730d}} 
        ld      de,frame_flyback_routine_to_swap_palettes;{{0d4c:11610d}} ##LABEL##
        ld      b,$81             ;{{0d4f:0681}} 
        pop     hl                ;{{0d51:e1}} 
        jp      KL_NEW_FRAME_FLY  ;{{0d52:c36301}}  KL NEW FRAME FLY

;;==================================================================================
;; delete palette swap event
delete_palette_swap_event:        ;{{Addr=$0d55 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b7f9       ;{{0d55:21f9b7}} 
        call    KL_DEL_FRAME_FLY  ;{{0d58:cd7001}}  KL DEL FRAME FLY
        call    _frame_flyback_routine_to_swap_palettes_20;{{0d5b:cd870d}} 
        jp      MC_CLEAR_INKS     ;{{0d5e:c38607}}  MC CLEAR INKS

;;===============================================================
;; frame flyback routine to swap palettes
frame_flyback_routine_to_swap_palettes:;{{Addr=$0d61 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,RAM_b7f8       ;{{0d61:21f8b7}} 
        dec     (hl)              ;{{0d64:35}} 
        jr      z,_frame_flyback_routine_to_swap_palettes_10;{{0d65:280c}}  (+&0c)
        dec     hl                ;{{0d67:2b}} 
        ld      a,(hl)            ;{{0d68:7e}} 
        or      a                 ;{{0d69:b7}} 
        ret     z                 ;{{0d6a:c8}} 

        call    _frame_flyback_routine_to_swap_palettes_20;{{0d6b:cd870d}} 
        call    MC_SET_INKS       ;{{0d6e:cd8c07}}  MC SET INKS
        jr      _frame_flyback_routine_to_swap_palettes_17;{{0d71:180f}}  (+&0f)
;;------------------------------------------------------------

_frame_flyback_routine_to_swap_palettes_10:;{{Addr=$0d73 Code Calls/jump count: 2 Data use count: 0}}
        call    _frame_flyback_routine_to_swap_palettes_20;{{0d73:cd870d}} 
        ld      (RAM_b7f8),a      ;{{0d76:32f8b7}} 
        call    MC_SET_INKS       ;{{0d79:cd8c07}}  MC SET INKS
        ld      hl,RAM_b7f6       ;{{0d7c:21f6b7}} 
        ld      a,(hl)            ;{{0d7f:7e}} 
        cpl                       ;{{0d80:2f}} 
        ld      (hl),a            ;{{0d81:77}} 
_frame_flyback_routine_to_swap_palettes_17:;{{Addr=$0d82 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{0d82:af}} 
        ld      (RAM_b7f7),a      ;{{0d83:32f7b7}} 
        ret                       ;{{0d86:c9}} 

;;------------------------------------------------------------

_frame_flyback_routine_to_swap_palettes_20:;{{Addr=$0d87 Code Calls/jump count: 3 Data use count: 0}}
        ld      de,Border_and_Pens_Second_Inks_;{{0d87:11e5b7}} 
        ld      a,(RAM_b7f6)      ;{{0d8a:3af6b7}} 
        or      a                 ;{{0d8d:b7}} 
        ld      a,(second_flash_period_);{{0d8e:3ad3b7}} 
        ret     z                 ;{{0d91:c8}} 

;;-------------------------------------------------------------

        ld      de,hw_04__sw_1_   ;{{0d92:11d4b7}} 
        ld      a,(first_flash_period_);{{0d95:3ad2b7}} 
        ret                       ;{{0d98:c9}} 

;;+---------------------------------------------------------------------------
;; software colour to hardware colour table
software_colour_to_hardware_colour_table:;{{Addr=$0d99 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $14,$04,$15,$1c,$18,$1d,$0c,$05,$0d,$16,$06,$17,$1e,$00,$1f,$0e,$07,$0f
        defb $12,$02,$13,$1a,$19,$1b,$0a,$03,$0b,$01,$08,$09,$10,$11

;;============================================================================
;; SCR FILL BOX

SCR_FILL_BOX:                     ;{{Addr=$0db9 Code Calls/jump count: 1 Data use count: 1}}
        ld      c,a               ;{{0db9:4f}} 
        call    _scr_char_position_35;{{0dba:cd9b0b}} 


;;============================================================================
;; SCR FLOOD BOX

SCR_FLOOD_BOX:                    ;{{Addr=$0dbd Code Calls/jump count: 4 Data use count: 1}}
        push    hl                ;{{0dbd:e5}} 
        ld      a,d               ;{{0dbe:7a}} 
        call    _scr_sw_roll_112  ;{{0dbf:cdee0e}} 
        jr      nc,_scr_flood_box_9;{{0dc2:3009}}  (+&09)
        ld      b,d               ;{{0dc4:42}} 
_scr_flood_box_5:                 ;{{Addr=$0dc5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),c            ;{{0dc5:71}} 
        call    SCR_NEXT_BYTE     ;{{0dc6:cd050c}}  SCR NEXT BYTE
        djnz    _scr_flood_box_5  ;{{0dc9:10fa}}  (-&06)
        jr      _scr_flood_box_22 ;{{0dcb:1810}}  (+&10)
_scr_flood_box_9:                 ;{{Addr=$0dcd Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{0dcd:c5}} 
        push    de                ;{{0dce:d5}} 
        ld      (hl),c            ;{{0dcf:71}} 
        dec     d                 ;{{0dd0:15}} 
        jr      z,_scr_flood_box_20;{{0dd1:2808}}  (+&08)
        ld      c,d               ;{{0dd3:4a}} 
        ld      b,$00             ;{{0dd4:0600}} 
        ld      d,h               ;{{0dd6:54}} 
        ld      e,l               ;{{0dd7:5d}} 
        inc     de                ;{{0dd8:13}} 
        ldir                      ;{{0dd9:edb0}} 
_scr_flood_box_20:                ;{{Addr=$0ddb Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{0ddb:d1}} 
        pop     bc                ;{{0ddc:c1}} 
_scr_flood_box_22:                ;{{Addr=$0ddd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{0ddd:e1}} 
        call    SCR_NEXT_LINE     ;{{0dde:cd1f0c}}  SCR NEXT LINE
        dec     e                 ;{{0de1:1d}} 
        jr      nz,SCR_FLOOD_BOX  ;{{0de2:20d9}}  (-&27)
        ret                       ;{{0de4:c9}} 


;;============================================================================
;; SCR CHAR INVERT

SCR_CHAR_INVERT:                  ;{{Addr=$0de5 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,b               ;{{0de5:78}} 
        xor     c                 ;{{0de6:a9}} 
        ld      c,a               ;{{0de7:4f}} 
        call    SCR_CHAR_POSITION ;{{0de8:cd6a0b}}  SCR CHAR POSITION
        ld      d,$08             ;{{0deb:1608}} 
_scr_char_invert_5:               ;{{Addr=$0ded Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0ded:e5}} 
        push    bc                ;{{0dee:c5}} 
_scr_char_invert_7:               ;{{Addr=$0def Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0def:7e}} 
        xor     c                 ;{{0df0:a9}} 
        ld      (hl),a            ;{{0df1:77}} 
        call    SCR_NEXT_BYTE     ;{{0df2:cd050c}}  SCR NEXT BYTE
        djnz    _scr_char_invert_7;{{0df5:10f8}}  (-&08)
        pop     bc                ;{{0df7:c1}} 
        pop     hl                ;{{0df8:e1}} 
        call    SCR_NEXT_LINE     ;{{0df9:cd1f0c}}  SCR NEXT LINE
        dec     d                 ;{{0dfc:15}} 
        jr      nz,_scr_char_invert_5;{{0dfd:20ee}}  (-&12)
        ret                       ;{{0dff:c9}} 


;;============================================================================
;; SCR HW ROLL
SCR_HW_ROLL:                      ;{{Addr=$0e00 Code Calls/jump count: 1 Data use count: 1}}
        ld      c,a               ;{{0e00:4f}} 
        push    bc                ;{{0e01:c5}} 
        ld      de,$ffd0          ;{{0e02:11d0ff}} 
        ld      b,$30             ;{{0e05:0630}} 
        call    _scr_hw_roll_19   ;{{0e07:cd2a0e}} 
        pop     bc                ;{{0e0a:c1}} 
        call    MC_WAIT_FLYBACK   ;{{0e0b:cdb407}}  MC WAIT FLYBACK
        ld      a,b               ;{{0e0e:78}} 
        or      a                 ;{{0e0f:b7}} 
        jr      nz,_scr_hw_roll_15;{{0e10:200d}}  (+&0d)
        ld      de,$ffb0          ;{{0e12:11b0ff}} 
        call    _scr_hw_roll_30   ;{{0e15:cd3d0e}} 
        ld      de,$0000          ;{{0e18:110000}} ##LIT##;WARNING: Code area used as literal
        ld      b,$20             ;{{0e1b:0620}} 
        jr      _scr_hw_roll_19   ;{{0e1d:180b}}  (+&0b)
_scr_hw_roll_15:                  ;{{Addr=$0e1f Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0050          ;{{0e1f:115000}} ##LIT##;WARNING: Code area used as literal
        call    _scr_hw_roll_30   ;{{0e22:cd3d0e}} 
        ld      de,$ffb0          ;{{0e25:11b0ff}} 
        ld      b,$20             ;{{0e28:0620}} 
_scr_hw_roll_19:                  ;{{Addr=$0e2a Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(screen_offset);{{0e2a:2ac4b7}} 
        add     hl,de             ;{{0e2d:19}} 
        ld      a,h               ;{{0e2e:7c}} 
        and     $07               ;{{0e2f:e607}} 
        ld      h,a               ;{{0e31:67}} 
        ld      a,(screen_base_HB_);{{0e32:3ac6b7}} 
        add     a,h               ;{{0e35:84}} 
        ld      h,a               ;{{0e36:67}} 
        ld      d,b               ;{{0e37:50}} 
        ld      e,$08             ;{{0e38:1e08}} 
        jp      SCR_FLOOD_BOX     ;{{0e3a:c3bd0d}} ; SCR FLOOD BOX
_scr_hw_roll_30:                  ;{{Addr=$0e3d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(screen_offset);{{0e3d:2ac4b7}} 
        add     hl,de             ;{{0e40:19}} 
        jp      SCR_OFFSET        ;{{0e41:c3370b}} ; SCR OFFSET


;;============================================================================
;; SCR SW ROLL

SCR_SW_ROLL:                      ;{{Addr=$0e44 Code Calls/jump count: 1 Data use count: 1}}
        push    af                ;{{0e44:f5}} 
        ld      a,b               ;{{0e45:78}} 
        or      a                 ;{{0e46:b7}} 
        jr      z,_scr_sw_roll_34 ;{{0e47:2830}}  (+&30)
        push    hl                ;{{0e49:e5}} 
        call    _scr_char_position_35;{{0e4a:cd9b0b}} 
        ex      (sp),hl           ;{{0e4d:e3}} 
        inc     l                 ;{{0e4e:2c}} 
        call    SCR_CHAR_POSITION ;{{0e4f:cd6a0b}}  SCR CHAR POSITION
        ld      c,d               ;{{0e52:4a}} 
        ld      a,e               ;{{0e53:7b}} 
        sub     $08               ;{{0e54:d608}} 
        ld      b,a               ;{{0e56:47}} 
        jr      z,_scr_sw_roll_28 ;{{0e57:2817}}  (+&17)
        pop     de                ;{{0e59:d1}} 
        call    MC_WAIT_FLYBACK   ;{{0e5a:cdb407}}  MC WAIT FLYBACK
_scr_sw_roll_16:                  ;{{Addr=$0e5d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{0e5d:c5}} 
        push    hl                ;{{0e5e:e5}} 
        push    de                ;{{0e5f:d5}} 
        call    _scr_sw_roll_65   ;{{0e60:cdaa0e}} 
        pop     hl                ;{{0e63:e1}} 
        call    SCR_NEXT_LINE     ;{{0e64:cd1f0c}}  SCR NEXT LINE
        ex      de,hl             ;{{0e67:eb}} 
        pop     hl                ;{{0e68:e1}} 
        call    SCR_NEXT_LINE     ;{{0e69:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0e6c:c1}} 
        djnz    _scr_sw_roll_16   ;{{0e6d:10ee}}  (-&12)
        push    de                ;{{0e6f:d5}} 
_scr_sw_roll_28:                  ;{{Addr=$0e70 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{0e70:e1}} 
        ld      d,c               ;{{0e71:51}} 
        ld      e,$08             ;{{0e72:1e08}} 
        pop     af                ;{{0e74:f1}} 
        ld      c,a               ;{{0e75:4f}} 
        jp      SCR_FLOOD_BOX     ;{{0e76:c3bd0d}} ; SCR FLOOD BOX
_scr_sw_roll_34:                  ;{{Addr=$0e79 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0e79:e5}} 
        push    de                ;{{0e7a:d5}} 
        call    _scr_char_position_35;{{0e7b:cd9b0b}} 
        ld      c,d               ;{{0e7e:4a}} 
        ld      a,e               ;{{0e7f:7b}} 
        sub     $08               ;{{0e80:d608}} 
        ld      b,a               ;{{0e82:47}} 
        pop     de                ;{{0e83:d1}} 
        ex      (sp),hl           ;{{0e84:e3}} 
        jr      z,_scr_sw_roll_28 ;{{0e85:28e9}}  (-&17)
        push    bc                ;{{0e87:c5}} 
        ld      l,e               ;{{0e88:6b}} 
        ld      d,h               ;{{0e89:54}} 
        inc     e                 ;{{0e8a:1c}} 
        call    SCR_CHAR_POSITION ;{{0e8b:cd6a0b}}  SCR CHAR POSITION
        ex      de,hl             ;{{0e8e:eb}} 
        call    SCR_CHAR_POSITION ;{{0e8f:cd6a0b}}  SCR CHAR POSITION
        pop     bc                ;{{0e92:c1}} 
        call    MC_WAIT_FLYBACK   ;{{0e93:cdb407}}  MC WAIT FLYBACK
_scr_sw_roll_53:                  ;{{Addr=$0e96 Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_PREV_LINE     ;{{0e96:cd390c}}  SCR PREV LINE
        push    hl                ;{{0e99:e5}} 
        ex      de,hl             ;{{0e9a:eb}} 
        call    SCR_PREV_LINE     ;{{0e9b:cd390c}}  SCR PREV LINE
        push    hl                ;{{0e9e:e5}} 
        push    bc                ;{{0e9f:c5}} 
        call    _scr_sw_roll_65   ;{{0ea0:cdaa0e}} 
        pop     bc                ;{{0ea3:c1}} 
        pop     de                ;{{0ea4:d1}} 
        pop     hl                ;{{0ea5:e1}} 
        djnz    _scr_sw_roll_53   ;{{0ea6:10ee}}  (-&12)
        jr      _scr_sw_roll_28   ;{{0ea8:18c6}}  (-&3a)
_scr_sw_roll_65:                  ;{{Addr=$0eaa Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$00             ;{{0eaa:0600}} 
        call    _scr_sw_roll_110  ;{{0eac:cdec0e}} 
        jr      c,_scr_sw_roll_84 ;{{0eaf:3816}}  (+&16)
        call    _scr_sw_roll_110  ;{{0eb1:cdec0e}} 
        jr      nc,_scr_sw_roll_99;{{0eb4:3025}}  (+&25)
        push    bc                ;{{0eb6:c5}} 
        xor     a                 ;{{0eb7:af}} 
        sub     l                 ;{{0eb8:95}} 
        ld      c,a               ;{{0eb9:4f}} 
        ldir                      ;{{0eba:edb0}} 
        pop     bc                ;{{0ebc:c1}} 
        cpl                       ;{{0ebd:2f}} 
        inc     a                 ;{{0ebe:3c}} 
        add     a,c               ;{{0ebf:81}} 
        ld      c,a               ;{{0ec0:4f}} 
        ld      a,h               ;{{0ec1:7c}} 
        sub     $08               ;{{0ec2:d608}} 
        ld      h,a               ;{{0ec4:67}} 
        jr      _scr_sw_roll_99   ;{{0ec5:1814}}  (+&14)
_scr_sw_roll_84:                  ;{{Addr=$0ec7 Code Calls/jump count: 1 Data use count: 0}}
        call    _scr_sw_roll_110  ;{{0ec7:cdec0e}} 
        jr      c,_scr_sw_roll_101;{{0eca:3812}}  (+&12)
        push    bc                ;{{0ecc:c5}} 
        xor     a                 ;{{0ecd:af}} 
        sub     e                 ;{{0ece:93}} 
        ld      c,a               ;{{0ecf:4f}} 
        ldir                      ;{{0ed0:edb0}} 
        pop     bc                ;{{0ed2:c1}} 
        cpl                       ;{{0ed3:2f}} 
        inc     a                 ;{{0ed4:3c}} 
        add     a,c               ;{{0ed5:81}} 
        ld      c,a               ;{{0ed6:4f}} 
        ld      a,d               ;{{0ed7:7a}} 
        sub     $08               ;{{0ed8:d608}} 
        ld      d,a               ;{{0eda:57}} 
_scr_sw_roll_99:                  ;{{Addr=$0edb Code Calls/jump count: 2 Data use count: 0}}
        ldir                      ;{{0edb:edb0}} 
        ret                       ;{{0edd:c9}} 

_scr_sw_roll_101:                 ;{{Addr=$0ede Code Calls/jump count: 1 Data use count: 0}}
        ld      b,c               ;{{0ede:41}} 
_scr_sw_roll_102:                 ;{{Addr=$0edf Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0edf:7e}} 
        ld      (de),a            ;{{0ee0:12}} 
        call    SCR_NEXT_BYTE     ;{{0ee1:cd050c}}  SCR NEXT BYTE
        ex      de,hl             ;{{0ee4:eb}} 
        call    SCR_NEXT_BYTE     ;{{0ee5:cd050c}}  SCR NEXT BYTE
        ex      de,hl             ;{{0ee8:eb}} 
        djnz    _scr_sw_roll_102  ;{{0ee9:10f4}} 
        ret                       ;{{0eeb:c9}} 

;;----------------------------------------------------------------------
_scr_sw_roll_110:                 ;{{Addr=$0eec Code Calls/jump count: 3 Data use count: 0}}
        ld      a,c               ;{{0eec:79}} 
        ex      de,hl             ;{{0eed:eb}} 
_scr_sw_roll_112:                 ;{{Addr=$0eee Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{0eee:3d}} 
        add     a,l               ;{{0eef:85}} 
        ret     nc                ;{{0ef0:d0}} 

        ld      a,h               ;{{0ef1:7c}} 
        and     $07               ;{{0ef2:e607}} 
        xor     $07               ;{{0ef4:ee07}} 
        ret     nz                ;{{0ef6:c0}} 

        scf                       ;{{0ef7:37}} 
        ret                       ;{{0ef8:c9}} 


;;============================================================================
;; SCR UNPACK

SCR_UNPACK:                       ;{{Addr=$0ef9 Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_GET_MODE      ;{{0ef9:cd0c0b}} ; SCR GET MODE 
        jr      c,_scr_unpack_8   ;{{0efc:380d}}  mode 0
        jr      z,_scr_unpack_6   ;{{0efe:2806}}  mode 1
        ld      bc,$0008          ;{{0f00:010800}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{0f03:edb0}} 
        ret                       ;{{0f05:c9}} 

;;-----------------------------------------------------------------------------
;; SCR UNPACK: mode 1
_scr_unpack_6:                    ;{{Addr=$0f06 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0288          ;{{0f06:018802}} ##LIT##;WARNING: Code area used as literal
        jr      _scr_unpack_9     ;{{0f09:1803}}  0x088 is the pixel mask

;;-----------------------------------------------------------------------------
;; SCR UNPACK: mode 0
_scr_unpack_8:                    ;{{Addr=$0f0b Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$04aa          ;{{0f0b:01aa04}} ; 0x0aa is the pixel mask ##LIT##;WARNING: Code area used as literal

;;-----------------------------------------------------------------------------
;; routine used by mode 0 and mode 1 for SCR UNPACK
_scr_unpack_9:                    ;{{Addr=$0f0e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$08             ;{{0f0e:3e08}} 
_scr_unpack_10:                   ;{{Addr=$0f10 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{0f10:f5}} 
        push    hl                ;{{0f11:e5}} 
        ld      l,(hl)            ;{{0f12:6e}} 
        ld      h,b               ;{{0f13:60}} 
_scr_unpack_14:                   ;{{Addr=$0f14 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{0f14:af}} 
_scr_unpack_15:                   ;{{Addr=$0f15 Code Calls/jump count: 1 Data use count: 0}}
        rlc     l                 ;{{0f15:cb05}} 
        jr      nc,_scr_unpack_18 ;{{0f17:3001}}  (+&01)
        or      c                 ;{{0f19:b1}} 
_scr_unpack_18:                   ;{{Addr=$0f1a Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0f1a:cb09}} 
        jr      nc,_scr_unpack_15 ;{{0f1c:30f7}}  (-&09)
        ld      (de),a            ;{{0f1e:12}} 
        inc     de                ;{{0f1f:13}} 
        djnz    _scr_unpack_14    ;{{0f20:10f2}}  (-&0e)
        ld      b,h               ;{{0f22:44}} 
        pop     hl                ;{{0f23:e1}} 
        inc     hl                ;{{0f24:23}} 
        pop     af                ;{{0f25:f1}} 
        dec     a                 ;{{0f26:3d}} 
        jr      nz,_scr_unpack_10 ;{{0f27:20e7}}  (-&19)
        ret                       ;{{0f29:c9}} 


;;============================================================================
;; SCR REPACK

SCR_REPACK:                       ;{{Addr=$0f2a Code Calls/jump count: 2 Data use count: 1}}
        ld      c,a               ;{{0f2a:4f}} 
        call    SCR_CHAR_POSITION ;{{0f2b:cd6a0b}}  SCR CHAR POSITION
        call    SCR_GET_MODE      ;{{0f2e:cd0c0b}}  SCR GET MODE
        ld      b,$08             ;{{0f31:0608}} 
        jr      c,_scr_repack_40  ;{{0f33:3836}}  mode 0
        jr      z,_scr_repack_14  ;{{0f35:280b}}  mode 1

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 2
_scr_repack_6:                    ;{{Addr=$0f37 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0f37:7e}} 
        xor     c                 ;{{0f38:a9}} 
        cpl                       ;{{0f39:2f}} 
        ld      (de),a            ;{{0f3a:12}} 
        inc     de                ;{{0f3b:13}} 
        call    SCR_NEXT_LINE     ;{{0f3c:cd1f0c}}  SCR NEXT LINE
        djnz    _scr_repack_6     ;{{0f3f:10f6}} 
        ret                       ;{{0f41:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 1
_scr_repack_14:                   ;{{Addr=$0f42 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0f42:c5}} 
        push    hl                ;{{0f43:e5}} 
        push    de                ;{{0f44:d5}} 
        call    _scr_repack_29    ;{{0f45:cd5a0f}}  mode 1
        call    SCR_NEXT_BYTE     ;{{0f48:cd050c}}  SCR NEXT BYTE
        call    _scr_repack_29    ;{{0f4b:cd5a0f}}  mode 1
        ld      a,e               ;{{0f4e:7b}} 
        pop     de                ;{{0f4f:d1}} 
        ld      (de),a            ;{{0f50:12}} 
        inc     de                ;{{0f51:13}} 
        pop     hl                ;{{0f52:e1}} 
        call    SCR_NEXT_LINE     ;{{0f53:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0f56:c1}} 
        djnz    _scr_repack_14    ;{{0f57:10e9}} 
        ret                       ;{{0f59:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 1 (part)
_scr_repack_29:                   ;{{Addr=$0f5a Code Calls/jump count: 2 Data use count: 0}}
        ld      d,$88             ;{{0f5a:1688}}  pixel mask
        ld      b,$04             ;{{0f5c:0604}} 
_scr_repack_31:                   ;{{Addr=$0f5e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0f5e:7e}} 
        xor     c                 ;{{0f5f:a9}} 
        and     d                 ;{{0f60:a2}} 
        jr      nz,_scr_repack_36 ;{{0f61:2001}}  (+&01)
        scf                       ;{{0f63:37}} 
_scr_repack_36:                   ;{{Addr=$0f64 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0f64:cb13}} 
        rrc     d                 ;{{0f66:cb0a}} 
        djnz    _scr_repack_31    ;{{0f68:10f4}} 
        ret                       ;{{0f6a:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 0
_scr_repack_40:                   ;{{Addr=$0f6b Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0f6b:c5}} 
        push    hl                ;{{0f6c:e5}} 
        push    de                ;{{0f6d:d5}} 

        ld      b,$04             ;{{0f6e:0604}} 
_scr_repack_44:                   ;{{Addr=$0f70 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0f70:7e}} 
        xor     c                 ;{{0f71:a9}} 
        and     $aa               ;{{0f72:e6aa}}  left pixel mask
        jr      nz,_scr_repack_49 ;{{0f74:2001}} 
        scf                       ;{{0f76:37}} 
_scr_repack_49:                   ;{{Addr=$0f77 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0f77:cb13}} 
        ld      a,(hl)            ;{{0f79:7e}} 
        xor     c                 ;{{0f7a:a9}} 
        and     $55               ;{{0f7b:e655}}  right pixel mask
        jr      nz,_scr_repack_55 ;{{0f7d:2001}} 
        scf                       ;{{0f7f:37}} 
_scr_repack_55:                   ;{{Addr=$0f80 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0f80:cb13}} 
        call    SCR_NEXT_BYTE     ;{{0f82:cd050c}}  SCR NEXT BYTE
        djnz    _scr_repack_44    ;{{0f85:10e9}} 

        ld      a,e               ;{{0f87:7b}} 
        pop     de                ;{{0f88:d1}} 
        ld      (de),a            ;{{0f89:12}} 
        inc     de                ;{{0f8a:13}} 
        pop     hl                ;{{0f8b:e1}} 
        call    SCR_NEXT_LINE     ;{{0f8c:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0f8f:c1}} 
        djnz    _scr_repack_40    ;{{0f90:10d9}} 
        ret                       ;{{0f92:c9}} 


;;============================================================================
;; SCR HORIZONTAL

SCR_HORIZONTAL:                   ;{{Addr=$0f93 Code Calls/jump count: 0 Data use count: 1}}
        call    _scr_vertical_8   ;{{0f93:cdad0f}} 
        call    _scr_vertical_18  ;{{0f96:cdc20f}} 
        jr      _scr_vertical_2   ;{{0f99:1806}}  (+&06)


;;============================================================================
;; SCR VERTICAL

SCR_VERTICAL:                     ;{{Addr=$0f9b Code Calls/jump count: 0 Data use count: 1}}
        call    _scr_vertical_8   ;{{0f9b:cdad0f}} 
        call    _scr_vertical_67  ;{{0f9e:cd1610}} 
_scr_vertical_2:                  ;{{Addr=$0fa1 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b802)     ;{{0fa1:2a02b8}} 
        ld      a,l               ;{{0fa4:7d}} 
        ld      (GRAPHICS_PEN),a  ;{{0fa5:32a3b6}}  graphics pen
        ld      a,h               ;{{0fa8:7c}} 
        ld      (line_MASK),a     ;{{0fa9:32b3b6}}  graphics line mask
        ret                       ;{{0fac:c9}} 

;;---------------------------------------------------------------------

_scr_vertical_8:                  ;{{Addr=$0fad Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{0fad:e5}} 
        ld      hl,(GRAPHICS_PEN) ;{{0fae:2aa3b6}}  L = graphics pen, H = graphics paper
        ld      (GRAPHICS_PEN),a  ;{{0fb1:32a3b6}}  graphics pen
        ld      a,(line_MASK)     ;{{0fb4:3ab3b6}}  graphics line mask
        ld      h,a               ;{{0fb7:67}} 
        ld      a,$ff             ;{{0fb8:3eff}} 
        ld      (line_MASK),a     ;{{0fba:32b3b6}}  graphics line mask
        ld      (RAM_b802),hl     ;{{0fbd:2202b8}} 
        pop     hl                ;{{0fc0:e1}} 
        ret                       ;{{0fc1:c9}} 

_scr_vertical_18:                 ;{{Addr=$0fc2 Code Calls/jump count: 2 Data use count: 0}}
        scf                       ;{{0fc2:37}} 
        call    _scr_vertical_86  ;{{0fc3:cd3b10}} 
_scr_vertical_20:                 ;{{Addr=$0fc6 Code Calls/jump count: 1 Data use count: 0}}
        rlc     b                 ;{{0fc6:cb00}} 
        ld      a,c               ;{{0fc8:79}} 
        jr      nc,_scr_vertical_34;{{0fc9:3013}}  (+&13)
_scr_vertical_23:                 ;{{Addr=$0fcb Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{0fcb:1d}} 
        jr      nz,_scr_vertical_27;{{0fcc:2003}}  (+&03)
        dec     d                 ;{{0fce:15}} 
        jr      z,_scr_vertical_52;{{0fcf:282c}}  (+&2c)
_scr_vertical_27:                 ;{{Addr=$0fd1 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0fd1:cb09}} 
        jr      c,_scr_vertical_52;{{0fd3:3828}}  (+&28)
        bit     7,b               ;{{0fd5:cb78}} 
        jr      z,_scr_vertical_52;{{0fd7:2824}}  (+&24)
        or      c                 ;{{0fd9:b1}} 
        rlc     b                 ;{{0fda:cb00}} 
        jr      _scr_vertical_23  ;{{0fdc:18ed}}  (-&13)
_scr_vertical_34:                 ;{{Addr=$0fde Code Calls/jump count: 2 Data use count: 0}}
        dec     e                 ;{{0fde:1d}} 
        jr      nz,_scr_vertical_38;{{0fdf:2003}}  (+&03)
        dec     d                 ;{{0fe1:15}} 
        jr      z,_scr_vertical_45;{{0fe2:280d}}  (+&0d)
_scr_vertical_38:                 ;{{Addr=$0fe4 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0fe4:cb09}} 
        jr      c,_scr_vertical_45;{{0fe6:3809}}  (+&09)
        bit     7,b               ;{{0fe8:cb78}} 
        jr      nz,_scr_vertical_45;{{0fea:2005}}  (+&05)
        or      c                 ;{{0fec:b1}} 
        rlc     b                 ;{{0fed:cb00}} 
        jr      _scr_vertical_34  ;{{0fef:18ed}}  (-&13)
_scr_vertical_45:                 ;{{Addr=$0ff1 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{0ff1:c5}} 
        ld      c,a               ;{{0ff2:4f}} 
        ld      a,(GRAPHICS_PAPER);{{0ff3:3aa4b6}}  graphics paper
        ld      b,a               ;{{0ff6:47}} 
        ld      a,(RAM_b6b4)      ;{{0ff7:3ab4b6}} 
        or      a                 ;{{0ffa:b7}} 
        jr      _scr_vertical_57  ;{{0ffb:1807}}  (+&07)
_scr_vertical_52:                 ;{{Addr=$0ffd Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{0ffd:c5}} 
        ld      c,a               ;{{0ffe:4f}} 
        ld      a,(GRAPHICS_PEN)  ;{{0fff:3aa3b6}}  graphics pen
        ld      b,a               ;{{1002:47}} 
        xor     a                 ;{{1003:af}} 
_scr_vertical_57:                 ;{{Addr=$1004 Code Calls/jump count: 1 Data use count: 0}}
        call    z,SCR_WRITE       ;{{1004:cce8bd}}  IND: SCR WRITE
        pop     bc                ;{{1007:c1}} 
        bit     7,c               ;{{1008:cb79}} 
        call    nz,SCR_NEXT_BYTE  ;{{100a:c4050c}}  SCR NEXT BYTE
        ld      a,d               ;{{100d:7a}} 
        or      e                 ;{{100e:b3}} 
        jr      nz,_scr_vertical_20;{{100f:20b5}}  (-&4b)
_scr_vertical_64:                 ;{{Addr=$1011 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{1011:78}} 
        ld      (line_MASK),a     ;{{1012:32b3b6}}  graphics line mask
        ret                       ;{{1015:c9}} 

_scr_vertical_67:                 ;{{Addr=$1016 Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{1016:b7}} 
        call    _scr_vertical_86  ;{{1017:cd3b10}} 
_scr_vertical_69:                 ;{{Addr=$101a Code Calls/jump count: 2 Data use count: 0}}
        rlc     b                 ;{{101a:cb00}} 
        ld      a,(GRAPHICS_PEN)  ;{{101c:3aa3b6}}  graphics pen
        jr      c,_scr_vertical_76;{{101f:3809}}  (+&09)
        ld      a,(RAM_b6b4)      ;{{1021:3ab4b6}} 
        or      a                 ;{{1024:b7}} 
        jr      nz,_scr_vertical_80;{{1025:2009}}  (+&09)
        ld      a,(GRAPHICS_PAPER);{{1027:3aa4b6}}  graphics paper
_scr_vertical_76:                 ;{{Addr=$102a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{102a:c5}} 
        ld      b,a               ;{{102b:47}} 
        call    SCR_WRITE         ;{{102c:cde8bd}}  IND: SCR WRITE
        pop     bc                ;{{102f:c1}} 
_scr_vertical_80:                 ;{{Addr=$1030 Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_PREV_LINE     ;{{1030:cd390c}}  SCR PREV LINE
        dec     e                 ;{{1033:1d}} 
        jr      nz,_scr_vertical_69;{{1034:20e4}}  (-&1c)
        dec     d                 ;{{1036:15}} 
        jr      nz,_scr_vertical_69;{{1037:20e1}}  (-&1f)
        jr      _scr_vertical_64  ;{{1039:18d6}}  (-&2a)
_scr_vertical_86:                 ;{{Addr=$103b Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{103b:e5}} 
        jr      nc,_scr_vertical_90;{{103c:3002}}  (+&02)
        ld      h,d               ;{{103e:62}} 
        ld      l,e               ;{{103f:6b}} 
_scr_vertical_90:                 ;{{Addr=$1040 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{1040:b7}} 
        sbc     hl,bc             ;{{1041:ed42}} 
        call    invert_HL         ;{{1043:cd3919}}  HL = -HL
        inc     h                 ;{{1046:24}} 
        inc     l                 ;{{1047:2c}} 
        ex      (sp),hl           ;{{1048:e3}} 
        call    SCR_DOT_POSITION  ;{{1049:cdaf0b}}  SCR DOT POSITION
        ld      a,(line_MASK)     ;{{104c:3ab3b6}}  graphics line mask
        ld      b,a               ;{{104f:47}} 
        pop     de                ;{{1050:d1}} 
        ret                       ;{{1051:c9}} 

;;=---------------------------------------------------------------------------
;; default colour palette
;; uses hardware colour numbers
;; 
;; There are two palettes here; so that flashing colours can be defined.
default_colour_palette:           ;{{Addr=$1052 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defb $04,$04,$0a,$13,$0c,$0b,$14,$15,$0d,$06,$1e,$1f,$07,$12,$19,$04,$17
        defb $04,$04,$0a,$13,$0c,$0b,$14,$15,$0d,$06,$1e,$1f,$07,$12,$19,$0a,$07



