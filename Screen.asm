;; SCREEN ROUTINES
;;===========================================================================
;; SCR INITIALISE

SCR_INITIALISE:                   ;{{Addr=$0abf Code Calls/jump count: 1 Data use count: 1}}
        ld      de,default_colour_palette;{{0ABF:115210}} ; default colour palette
        call    MC_CLEAR_INKS     ;{{0AC2:cd8607}} ; MC CLEAR INKS
        ld      a,$c0             ;{{0AC5:3ec0}} 
        ld      (screen_base_HB_),a;{{0AC7:32c6b7}} 
        call    SCR_RESET         ;{{0ACA:cdd00a}} ; SCR RESET
        jp      set_mode_1        ;{{0ACD:c3120b}} 

;;===========================================================================
;; SCR RESET

SCR_RESET:                        ;{{Addr=$0ad0 Code Calls/jump count: 2 Data use count: 1}}
        xor     a                 ;{{0AD0:af}} 
        call    SCR_ACCESS        ;{{0AD1:cd550c}} ; SCR ACCESS
        ld      hl,_scr_reset_5   ;{{0AD4:21dd0a}} ; table used to initialise screen indirections
        call    initialise_firmware_indirections;{{0AD7:cdb40a}} ; initialise screen pack indirections
        jp      restore_colours_and_set_default_flashing;{{0ADA:c3d80c}} ; restore colours and set default flashing

_scr_reset_5:                     ;{{Addr=$0add Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $09                  
        defw SCR_READ                
        jp      IND_SCR_READ      ;{{0AE0:c38a0c}} ; IND: SCR READ
        jp      IND_SCR_WRITE     ;{{0AE3:c3710c}} ; IND: SCR WRITE
        jp      IND_SCR_MODE_CLEAR;{{0AE6:c3170b}} ; IND: SCR MODE CLEAR

;;===========================================================================
;; SCR SET MODE

SCR_SET_MODE:                     ;{{Addr=$0ae9 Code Calls/jump count: 0 Data use count: 2}}
        and     $03               ;{{0AE9:e603}} 
        cp      $03               ;{{0AEB:fe03}} 
        ret     nc                ;{{0AED:d0}} 

        push    af                ;{{0AEE:f5}} 
        call    delete_palette_swap_event;{{0AEF:cd550d}} 
        pop     de                ;{{0AF2:d1}} 
        call    clean_up_streams  ;{{0AF3:cdb310}} 
        push    af                ;{{0AF6:f5}} 
        call    x15CE_code        ;{{0AF7:cdce15}} 
        push    hl                ;{{0AFA:e5}} 
        ld      a,d               ;{{0AFB:7a}} 
        call    set_mode_         ;{{0AFC:cd310b}} 
        call    SCR_MODE_CLEAR    ;{{0AFF:cdebbd}}  IND: SCR MODE CLEAR
        pop     hl                ;{{0B02:e1}} 
        call    _gra_initialise_2 ;{{0B03:cdae15}} 
        pop     af                ;{{0B06:f1}} 
        call    initialise_txt_streams;{{0B07:cdd110}} 
        jr      _ind_scr_mode_clear_10;{{0B0A:1822}}  (+&22)

;;===========================================================================
;; SCR GET MODE

SCR_GET_MODE:                     ;{{Addr=$0b0c Code Calls/jump count: 10 Data use count: 1}}
        ld      a,(MODE_number)   ;{{0B0C:3ac3b7}} 
        cp      $01               ;{{0B0F:fe01}} 
        ret                       ;{{0B11:c9}} 

;;==========================================================================
;;set mode 1
set_mode_1:                       ;{{Addr=$0b12 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$01             ;{{0B12:3e01}} 
        call    set_mode_         ;{{0B14:cd310b}} 

;;===========================================================================
;; IND: SCR MODE CLEAR

IND_SCR_MODE_CLEAR:               ;{{Addr=$0b17 Code Calls/jump count: 1 Data use count: 1}}
        call    delete_palette_swap_event;{{0B17:cd550d}} 
        ld      hl,$0000          ;{{0B1A:210000}} ##LIT##;WARNING: Code area used as literal
        call    SCR_OFFSET        ;{{0B1D:cd370b}} ; SCR OFFSET
        ld      hl,($b7c5)        ;{{0B20:2ac5b7}} 
        ld      l,$00             ;{{0B23:2e00}} 
        ld      d,h               ;{{0B25:54}} 
        ld      e,$01             ;{{0B26:1e01}} 
        ld      bc,$3fff          ;{{0B28:01ff3f}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),l            ;{{0B2B:75}} 
        ldir                      ;{{0B2C:edb0}} 
_ind_scr_mode_clear_10:           ;{{Addr=$0b2e Code Calls/jump count: 1 Data use count: 0}}
        jp      setup_palette_swap_event;{{0B2E:c3420d}} 

;;===========================================================================
;; set mode 
set_mode_:                        ;{{Addr=$0b31 Code Calls/jump count: 2 Data use count: 0}}
        ld      (MODE_number),a   ;{{0B31:32c3b7}} 
        jp      MC_SET_MODE       ;{{0B34:c37607}}  MC SET MODE

;;===========================================================================
;; SCR OFFSET

SCR_OFFSET:                       ;{{Addr=$0b37 Code Calls/jump count: 2 Data use count: 1}}
        ld      a,(screen_base_HB_);{{0B37:3ac6b7}} 
        jr      _scr_set_base_1   ;{{0B3A:1803}}  (+&03)

;;===========================================================================
;; SCR SET BASE

SCR_SET_BASE:                     ;{{Addr=$0b3c Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(screen_offset);{{0B3C:2ac4b7}} 
_scr_set_base_1:                  ;{{Addr=$0b3f Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_SET_POSITION  ;{{0B3F:cd450b}}  SCR SET POSITION
        jp      MC_SCREEN_OFFSET  ;{{0B42:c3c007}}  MC SCREEN OFFSET

;;===========================================================================
;; SCR SET POSITION

SCR_SET_POSITION:                 ;{{Addr=$0b45 Code Calls/jump count: 1 Data use count: 1}}
        and     $c0               ;{{0B45:e6c0}} 
        ld      (screen_base_HB_),a;{{0B47:32c6b7}} 
        push    af                ;{{0B4A:f5}} 
        ld      a,h               ;{{0B4B:7c}} 
        and     $07               ;{{0B4C:e607}} 
        ld      h,a               ;{{0B4E:67}} 
        res     0,l               ;{{0B4F:cb85}} 
        ld      (screen_offset),hl;{{0B51:22c4b7}} 
        pop     af                ;{{0B54:f1}} 
        ret                       ;{{0B55:c9}} 

;;===========================================================================
;; SCR GET LOCATION

SCR_GET_LOCATION:                 ;{{Addr=$0b56 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(screen_offset);{{0B56:2ac4b7}} 
        ld      a,(screen_base_HB_);{{0B59:3ac6b7}} 
        ret                       ;{{0B5C:c9}} 

;;======================================================================================
;; SCR CHAR LIMITS
SCR_CHAR_LIMITS:                  ;{{Addr=$0b5d Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_GET_MODE      ;{{0B5D:cd0c0b}} ; SCR GET MODE
        ld      bc,$1318          ;{{0B60:011813}} ; B = 19, C = 24 ##LIT##;WARNING: Code area used as literal
        ret     c                 ;{{0B63:d8}} 

        ld      b,$27             ;{{0B64:0627}} ; 39
        ret     z                 ;{{0B66:c8}} 

        ld      b,$4f             ;{{0B67:064f}} ; 79
;; B = x limit-1
;; C = y limit-1
        ret                       ;{{0B69:c9}} 

;;======================================================================================
;; SCR CHAR POSITION

SCR_CHAR_POSITION:                ;{{Addr=$0b6a Code Calls/jump count: 7 Data use count: 1}}
        push    de                ;{{0B6A:d5}} 
        call    SCR_GET_MODE      ;{{0B6B:cd0c0b}} ; SCR GET MODE
        ld      b,$04             ;{{0B6E:0604}} 
        jr      c,_scr_char_position_7;{{0B70:3805}}  (+&05)
        ld      b,$02             ;{{0B72:0602}} 
        jr      z,_scr_char_position_7;{{0B74:2801}}  (+&01)
        dec     b                 ;{{0B76:05}} 
_scr_char_position_7:             ;{{Addr=$0b77 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0B77:c5}} 
        ld      e,h               ;{{0B78:5c}} 
        ld      d,$00             ;{{0B79:1600}} 
        ld      h,d               ;{{0B7B:62}} 
        push    de                ;{{0B7C:d5}} 
        ld      d,h               ;{{0B7D:54}} 
        ld      e,l               ;{{0B7E:5d}} 
        add     hl,hl             ;{{0B7F:29}} 
        add     hl,hl             ;{{0B80:29}} 
        add     hl,de             ;{{0B81:19}} 
        add     hl,hl             ;{{0B82:29}} 
        add     hl,hl             ;{{0B83:29}} 
        add     hl,hl             ;{{0B84:29}} 
        add     hl,hl             ;{{0B85:29}} 
        pop     de                ;{{0B86:d1}} 
_scr_char_position_22:            ;{{Addr=$0b87 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{0B87:19}} 
        djnz    _scr_char_position_22;{{0B88:10fd}}  (-&03)
        ld      de,(screen_offset);{{0B8A:ed5bc4b7}} 
        add     hl,de             ;{{0B8E:19}} 
        ld      a,h               ;{{0B8F:7c}} 
        and     $07               ;{{0B90:e607}} 
        ld      h,a               ;{{0B92:67}} 
        ld      a,(screen_base_HB_);{{0B93:3ac6b7}} 
        add     a,h               ;{{0B96:84}} 
        ld      h,a               ;{{0B97:67}} 
        pop     bc                ;{{0B98:c1}} 
        pop     de                ;{{0B99:d1}} 
        ret                       ;{{0B9A:c9}} 

_scr_char_position_35:            ;{{Addr=$0b9b Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{0B9B:7b}} 
        sub     l                 ;{{0B9C:95}} 
        inc     a                 ;{{0B9D:3c}} 
        add     a,a               ;{{0B9E:87}} 
        add     a,a               ;{{0B9F:87}} 
        add     a,a               ;{{0BA0:87}} 
        ld      e,a               ;{{0BA1:5f}} 
        ld      a,d               ;{{0BA2:7a}} 
        sub     h                 ;{{0BA3:94}} 
        inc     a                 ;{{0BA4:3c}} 
        ld      d,a               ;{{0BA5:57}} 
        call    SCR_CHAR_POSITION ;{{0BA6:cd6a0b}}  SCR CHAR POSITION
        xor     a                 ;{{0BA9:af}} 
_scr_char_position_48:            ;{{Addr=$0baa Code Calls/jump count: 1 Data use count: 0}}
        add     a,d               ;{{0BAA:82}} 
        djnz    _scr_char_position_48;{{0BAB:10fd}}  (-&03)
        ld      d,a               ;{{0BAD:57}} 
        ret                       ;{{0BAE:c9}} 

;;======================================================================================
;; SCR DOT POSITION

SCR_DOT_POSITION:                 ;{{Addr=$0baf Code Calls/jump count: 9 Data use count: 1}}
        push    de                ;{{0BAF:d5}} 
        ex      de,hl             ;{{0BB0:eb}} 
        ld      hl,$00c7          ;{{0BB1:21c700}} ##LIT##;WARNING: Code area used as literal
        or      a                 ;{{0BB4:b7}} 
        sbc     hl,de             ;{{0BB5:ed52}} 
        ld      a,l               ;{{0BB7:7d}} 
        and     $07               ;{{0BB8:e607}} 
        add     a,a               ;{{0BBA:87}} 
        add     a,a               ;{{0BBB:87}} 
        add     a,a               ;{{0BBC:87}} 
        ld      c,a               ;{{0BBD:4f}} 
        ld      a,l               ;{{0BBE:7d}} 
        and     $f8               ;{{0BBF:e6f8}} 
        ld      l,a               ;{{0BC1:6f}} 
        ld      d,h               ;{{0BC2:54}} 
        ld      e,l               ;{{0BC3:5d}} 
        add     hl,hl             ;{{0BC4:29}} 
        add     hl,hl             ;{{0BC5:29}} 
        add     hl,de             ;{{0BC6:19}} 
        add     hl,hl             ;{{0BC7:29}} 
        pop     de                ;{{0BC8:d1}} 
        push    bc                ;{{0BC9:c5}} 
        call    _scr_dot_position_52;{{0BCA:cdf60b}} 
        ld      a,b               ;{{0BCD:78}} 
        and     e                 ;{{0BCE:a3}} 
        jr      z,_scr_dot_position_29;{{0BCF:2805}}  (+&05)
_scr_dot_position_26:             ;{{Addr=$0bd1 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0BD1:cb09}} 
        dec     a                 ;{{0BD3:3d}} 
        jr      nz,_scr_dot_position_26;{{0BD4:20fb}}  (-&05)
_scr_dot_position_29:             ;{{Addr=$0bd6 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{0BD6:e3}} 
        ld      h,c               ;{{0BD7:61}} 
        ld      c,l               ;{{0BD8:4d}} 
        ex      (sp),hl           ;{{0BD9:e3}} 
        ld      a,b               ;{{0BDA:78}} 
        rrca                      ;{{0BDB:0f}} 
_scr_dot_position_35:             ;{{Addr=$0bdc Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{0BDC:cb3a}} 
        rr      e                 ;{{0BDE:cb1b}} 
        rrca                      ;{{0BE0:0f}} 
        jr      c,_scr_dot_position_35;{{0BE1:38f9}}  (-&07)
        add     hl,de             ;{{0BE3:19}} 
        ld      de,(screen_offset);{{0BE4:ed5bc4b7}} 
        add     hl,de             ;{{0BE8:19}} 
        ld      a,h               ;{{0BE9:7c}} 
        and     $07               ;{{0BEA:e607}} 
        ld      h,a               ;{{0BEC:67}} 
        ld      a,(screen_base_HB_);{{0BED:3ac6b7}} 
        add     a,h               ;{{0BF0:84}} 
        add     a,c               ;{{0BF1:81}} 
        ld      h,a               ;{{0BF2:67}} 
        pop     de                ;{{0BF3:d1}} 
        ld      c,d               ;{{0BF4:4a}} 
        ret                       ;{{0BF5:c9}} 

;;---------------------------------------------------------------------
_scr_dot_position_52:             ;{{Addr=$0bf6 Code Calls/jump count: 3 Data use count: 0}}
        call    SCR_GET_MODE      ;{{0BF6:cd0c0b}} ; SCR GET MODE
        ld      bc,$01aa          ;{{0BF9:01aa01}} ##LIT##;WARNING: Code area used as literal
        ret     c                 ;{{0BFC:d8}} 

        ld      bc,$0388          ;{{0BFD:018803}} ##LIT##;WARNING: Code area used as literal
        ret     z                 ;{{0C00:c8}} 

        ld      bc,$0780          ;{{0C01:018007}} ##LIT##;WARNING: Code area used as literal
        ret                       ;{{0C04:c9}} 


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
        inc     l                 ;{{0C05:2c}} 
        ret     nz                ;{{0C06:c0}} 

        inc     h                 ;{{0C07:24}} 
        ld      a,h               ;{{0C08:7c}} 
        and     $07               ;{{0C09:e607}} 
        ret     nz                ;{{0C0B:c0}} 

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

        ld      a,h               ;{{0C0C:7c}} 
        sub     $08               ;{{0C0D:d608}} 
        ld      h,a               ;{{0C0F:67}} 
        ret                       ;{{0C10:c9}} 

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
        ld      a,l               ;{{0C11:7d}} 
        dec     l                 ;{{0C12:2d}} 
        or      a                 ;{{0C13:b7}} 
        ret     nz                ;{{0C14:c0}} 

        ld      a,h               ;{{0C15:7c}} 
        dec     h                 ;{{0C16:25}} 
        and     $07               ;{{0C17:e607}} 
        ret     nz                ;{{0C19:c0}} 

        ld      a,h               ;{{0C1A:7c}} 
        add     a,$08             ;{{0C1B:c608}} 
        ld      h,a               ;{{0C1D:67}} 
        ret                       ;{{0C1E:c9}} 

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
        ld      a,h               ;{{0C1F:7c}} 
        add     a,$08             ;{{0C20:c608}} 
        ld      h,a               ;{{0C22:67}} 


        and     $38               ;{{0C23:e638}} 
        ret     nz                ;{{0C25:c0}} 

;; 

        ld      a,h               ;{{0C26:7c}} 
        sub     $40               ;{{0C27:d640}} 
        ld      h,a               ;{{0C29:67}} 
        ld      a,l               ;{{0C2A:7d}} 
        add     a,$50             ;{{0C2B:c650}} ; number of bytes per line
        ld      l,a               ;{{0C2D:6f}} 
        ret     nc                ;{{0C2E:d0}} 

        inc     h                 ;{{0C2F:24}} 
        ld      a,h               ;{{0C30:7c}} 
        and     $07               ;{{0C31:e607}} 
        ret     nz                ;{{0C33:c0}} 

        ld      a,h               ;{{0C34:7c}} 
        sub     $08               ;{{0C35:d608}} 
        ld      h,a               ;{{0C37:67}} 
        ret                       ;{{0C38:c9}} 

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
        ld      a,h               ;{{0C39:7c}} 
        sub     $08               ;{{0C3A:d608}} 
        ld      h,a               ;{{0C3C:67}} 
        and     $38               ;{{0C3D:e638}} 
        cp      $38               ;{{0C3F:fe38}} 
        ret     nz                ;{{0C41:c0}} 

        ld      a,h               ;{{0C42:7c}} 
        add     a,$40             ;{{0C43:c640}} 
        ld      h,a               ;{{0C45:67}} 

        ld      a,l               ;{{0C46:7d}} 
        sub     $50               ;{{0C47:d650}} ; number of bytes per line
        ld      l,a               ;{{0C49:6f}} 
        ret     nc                ;{{0C4A:d0}} 

        ld      a,h               ;{{0C4B:7c}} 
        dec     h                 ;{{0C4C:25}} 
        and     $07               ;{{0C4D:e607}} 
        ret     nz                ;{{0C4F:c0}} 

        ld      a,h               ;{{0C50:7c}} 
        add     a,$08             ;{{0C51:c608}} 
        ld      h,a               ;{{0C53:67}} 
        ret                       ;{{0C54:c9}} 


;;============================================================================
;; SCR ACCESS
;;
;; A = write mode:
;; 0 -> fill
;; 1 -> XOR
;; 2 -> AND
;; 3 -> OR 
SCR_ACCESS:                       ;{{Addr=$0c55 Code Calls/jump count: 2 Data use count: 2}}
        and     $03               ;{{0C55:e603}} 
        ld      hl,SCR_PIXELS     ;{{0C57:21740c}}  SCR PIXELS ##LABEL##
        jr      z,_scr_access_9   ;{{0C5A:280c}}  (+&0c)
        cp      $02               ;{{0C5C:fe02}} 

;;This block will (should) fail to assemble if the addresses reference span a page boundary.
;;Addresses = SCR_PIXELS, SCR_PIXELS_XOR, SCR_PIXELS_AND, SCR_PIXELS_OR
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_XOR and $ff00) + (SCR_PIXELS_XOR and $00ff);{{0C5E:2e7a}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal
        jr      c,_scr_access_9   ;{{0C60:3806}}  (+&06)
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_AND and $ff00) + (SCR_PIXELS_AND and $00ff);{{0C62:2e7f}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal
        jr      z,_scr_access_9   ;{{0C64:2802}}  (+&02)
        ld      l,(SCR_PIXELS and $ff00) - (SCR_PIXELS_OR and $ff00) + (SCR_PIXELS_OR and $00ff);{{0C66:2e85}} ;WARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literalWARNING: Code area used as literal

;; HL = address of screen write function 
;; initialise jump for IND: SCR WRITE
_scr_access_9:                    ;{{Addr=$0c68 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$c3             ;{{0C68:3ec3}} JP opcode
        ld      (graphics_VDU_write_mode_indirection__JP),a;{{0C6A:32c7b7}} Write JP
        ld      (graphics_VDU_write_mode_indirection__JP + 1),hl;{{0C6D:22c8b7}} Write address to jump to
        ret                       ;{{0C70:c9}} 

;;==================================================================================
;; IND: SCR WRITE

;; jump initialised by SCR ACCESS
IND_SCR_WRITE:                    ;{{Addr=$0c71 Code Calls/jump count: 1 Data use count: 0}}
        jp      graphics_VDU_write_mode_indirection__JP;{{0C71:c3c7b7}} 


;;============================================================================
;; SCR PIXELS
;; (write mode fill)
SCR_PIXELS:                       ;{{Addr=$0c74 Code Calls/jump count: 1 Data use count: 5}}
        ld      a,b               ;{{0C74:78}} 
        xor     (hl)              ;{{0C75:ae}} 
        and     c                 ;{{0C76:a1}} 
        xor     (hl)              ;{{0C77:ae}} 
        ld      (hl),a            ;{{0C78:77}} 
        ret                       ;{{0C79:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS XOR
;; screen write access mode

;; (write mode XOR)
SCR_PIXELS_XOR:                   ;{{Addr=$0c7a Code Calls/jump count: 0 Data use count: 2}}
        ld      a,b               ;{{0C7A:78}} 
        and     c                 ;{{0C7B:a1}} 
        xor     (hl)              ;{{0C7C:ae}} 
        ld      (hl),a            ;{{0C7D:77}} 
        ret                       ;{{0C7E:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS AND
;; screen write access mode
;;
;; (write mode AND)
SCR_PIXELS_AND:                   ;{{Addr=$0c7f Code Calls/jump count: 0 Data use count: 2}}
        ld      a,c               ;{{0C7F:79}} 
        cpl                       ;{{0C80:2f}} 
        or      b                 ;{{0C81:b0}} 
        and     (hl)              ;{{0C82:a6}} 
        ld      (hl),a            ;{{0C83:77}} 
        ret                       ;{{0C84:c9}} 

;;+----------------------------------------------------------------------------
;;SCR PIXELS OR
;; screen write access mode
;;
;; (write mode OR)
SCR_PIXELS_OR:                    ;{{Addr=$0c85 Code Calls/jump count: 0 Data use count: 2}}
        ld      a,b               ;{{0C85:78}} 
        and     c                 ;{{0C86:a1}} 
        or      (hl)              ;{{0C87:b6}} 
        ld      (hl),a            ;{{0C88:77}} 
        ret                       ;{{0C89:c9}} 

;;==================================================================================
;; IND: SCR READ
IND_SCR_READ:                     ;{{Addr=$0c8a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0C8A:7e}} 
        jp      _scr_ink_decode_7 ;{{0C8B:c3b20c}} 

;;==================================================================================
;; SCR INK ENCODE
SCR_INK_ENCODE:                   ;{{Addr=$0c8e Code Calls/jump count: 4 Data use count: 1}}
        push    bc                ;{{0C8E:c5}} 
        push    de                ;{{0C8F:d5}} 
        call    _scr_ink_decode_20;{{0C90:cdc80c}} 
        ld      e,a               ;{{0C93:5f}} 
        call    _scr_dot_position_52;{{0C94:cdf60b}} 
        ld      b,$08             ;{{0C97:0608}} 
_scr_ink_encode_6:                ;{{Addr=$0c99 Code Calls/jump count: 1 Data use count: 0}}
        rrc     e                 ;{{0C99:cb0b}} 
        rla                       ;{{0C9B:17}} 
        rrc     c                 ;{{0C9C:cb09}} 
        jr      c,_scr_ink_encode_11;{{0C9E:3802}}  (+&02)
        rlc     e                 ;{{0CA0:cb03}} 
_scr_ink_encode_11:               ;{{Addr=$0ca2 Code Calls/jump count: 1 Data use count: 0}}
        djnz    _scr_ink_encode_6 ;{{0CA2:10f5}}  (-&0b)
        pop     de                ;{{0CA4:d1}} 
        pop     bc                ;{{0CA5:c1}} 
        ret                       ;{{0CA6:c9}} 

;;============================================================================
;; SCR INK DECODE

SCR_INK_DECODE:                   ;{{Addr=$0ca7 Code Calls/jump count: 3 Data use count: 1}}
        push    bc                ;{{0CA7:c5}} 
        push    af                ;{{0CA8:f5}} 
        call    _scr_dot_position_52;{{0CA9:cdf60b}} 
        pop     af                ;{{0CAC:f1}} 
        call    _scr_ink_decode_7 ;{{0CAD:cdb20c}} 
        pop     bc                ;{{0CB0:c1}} 
        ret                       ;{{0CB1:c9}} 

;;-----------------------------------------------------------------------------

_scr_ink_decode_7:                ;{{Addr=$0cb2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{0CB2:d5}} 
        ld      de,$0008          ;{{0CB3:110800}} ##LIT##;WARNING: Code area used as literal
_scr_ink_decode_9:                ;{{Addr=$0cb6 Code Calls/jump count: 1 Data use count: 0}}
        rrca                      ;{{0CB6:0f}} 
        rl      d                 ;{{0CB7:cb12}} 
        rrc     c                 ;{{0CB9:cb09}} 
        jr      c,_scr_ink_decode_14;{{0CBB:3802}}  (+&02)
        rr      d                 ;{{0CBD:cb1a}} 
_scr_ink_decode_14:               ;{{Addr=$0cbf Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{0CBF:1d}} 
        jr      nz,_scr_ink_decode_9;{{0CC0:20f4}}  (-&0c)
        ld      a,d               ;{{0CC2:7a}} 
        call    _scr_ink_decode_20;{{0CC3:cdc80c}} 
        pop     de                ;{{0CC6:d1}} 
        ret                       ;{{0CC7:c9}} 

;;-----------------------------------------------------------------------------
_scr_ink_decode_20:               ;{{Addr=$0cc8 Code Calls/jump count: 2 Data use count: 0}}
        ld      d,a               ;{{0CC8:57}} 
        call    SCR_GET_MODE      ;{{0CC9:cd0c0b}} ; SCR GET MODE
        ld      a,d               ;{{0CCC:7a}} 
        ret     nc                ;{{0CCD:d0}} 
        rrca                      ;{{0CCE:0f}} 
        rrca                      ;{{0CCF:0f}} 
        adc     a,$00             ;{{0CD0:ce00}} 
        rrca                      ;{{0CD2:0f}} 
        sbc     a,a               ;{{0CD3:9f}} 
        and     $06               ;{{0CD4:e606}} 
        xor     d                 ;{{0CD6:aa}} 
        ret                       ;{{0CD7:c9}} 

;;========================================================
;; restore colours and set default flashing
restore_colours_and_set_default_flashing:;{{Addr=$0cd8 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,default_colour_palette;{{0CD8:215210}} ; default colour palette
        ld      de,hw_04__sw_1_   ;{{0CDB:11d4b7}} 
        ld      bc,$0022          ;{{0CDE:012200}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{0CE1:edb0}} 
        xor     a                 ;{{0CE3:af}} 
        ld      (RAM_b7f6),a      ;{{0CE4:32f6b7}} 
        ld      hl,$0a0a          ;{{0CE7:210a0a}} ##LIT##;WARNING: Code area used as literal

;;============================================================================
;; SCR SET FLASHING

SCR_SET_FLASHING:                 ;{{Addr=$0cea Code Calls/jump count: 0 Data use count: 1}}
        ld      (first_flash_period_),hl;{{0CEA:22d2b7}} 
        ret                       ;{{0CED:c9}} 


;;============================================================================
;; SCR GET FLASHING

SCR_GET_FLASHING:                 ;{{Addr=$0cee Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(first_flash_period_);{{0CEE:2ad2b7}} 
        ret                       ;{{0CF1:c9}} 

;;============================================================================
;; SCR SET INK
SCR_SET_INK:                      ;{{Addr=$0cf2 Code Calls/jump count: 1 Data use count: 1}}
        and     $0f               ;{{0CF2:e60f}}  keep pen within 0-15 range
        inc     a                 ;{{0CF4:3c}} 
        jr      _scr_set_border_1 ;{{0CF5:1801}} 

;;============================================================================
;; SCR SET BORDER
SCR_SET_BORDER:                   ;{{Addr=$0cf7 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{0CF7:af}} 
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
        ld      e,a               ;{{0CF8:5f}} 

        ld      a,b               ;{{0CF9:78}} 
        call    software_colour_to_hardware_colour;{{0CFA:cd100d}}  lookup address of hardware colour number in conversion
                                  ; table using software colour number
									
        ld      b,(hl)            ;{{0CFD:46}}  get hardware colour number for ink 1

        ld      a,c               ;{{0CFE:79}} 
        call    software_colour_to_hardware_colour;{{0CFF:cd100d}}  lookup address of hardware colour number in conversion
                                  ; table using software colour number
									
        ld      c,(hl)            ;{{0D02:4e}}  get hardware colour number for ink 2

        ld      a,e               ;{{0D03:7b}} 
        call    get_palette_entry_addresses;{{0D04:cd350d}}  get address of pen in both palette's in RAM

        ld      (hl),c            ;{{0D07:71}}  write ink 2
        ex      de,hl             ;{{0D08:eb}} 
        ld      (hl),b            ;{{0D09:70}}  write ink 1

        ld      a,$ff             ;{{0D0A:3eff}} 
        ld      (RAM_b7f7),a      ;{{0D0C:32f7b7}} 
        ret                       ;{{0D0F:c9}} 

;;============================================================================
;; software colour to hardware colour
;; input:
;; A = software colour number
;; output:
;; HL = address of element in table. Element is corresponding hardware colour number.
software_colour_to_hardware_colour:;{{Addr=$0d10 Code Calls/jump count: 2 Data use count: 0}}
        and     $1f               ;{{0D10:e61f}} 
        add     a,$99             ;{{0D12:c699}} 
        ld      l,a               ;{{0D14:6f}} 
        adc     a,$0d             ;{{0D15:ce0d}} 
        sub     l                 ;{{0D17:95}} 
        ld      h,a               ;{{0D18:67}} 
        ret                       ;{{0D19:c9}} 

;;============================================================================
;; SCR GET INK
SCR_GET_INK:                      ;{{Addr=$0d1a Code Calls/jump count: 0 Data use count: 1}}
        and     $0f               ;{{0D1A:e60f}}  keep pen within range 0-15.
        inc     a                 ;{{0D1C:3c}} 
        jr      _scr_get_border_1 ;{{0D1D:1801}} 

;;============================================================================
;; SCR GET BORDER

SCR_GET_BORDER:                   ;{{Addr=$0d1f Code Calls/jump count: 0 Data use count: 1}}
        xor     a                 ;{{0D1F:af}} 
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
        call    get_palette_entry_addresses;{{0D20:cd350d}}  get address of pen in both palette's in RAM
        ld      a,(de)            ;{{0D23:1a}}  ink 2

        ld      e,(hl)            ;{{0D24:5e}}  ink 1

        call    _scr_get_border_7 ;{{0D25:cd2a0d}}  lookup hardware colour number for ink 2
        ld      b,c               ;{{0D28:41}} 

;; lookup hardware colour number for ink 1
        ld      a,e               ;{{0D29:7b}} 

;;---------------------------------------------------------------------------
;; lookup software colour number which corresponds to the hardware colour number

;; entry:
;; A = hardware colour number
;; exit:
;; C = index in table (same as software colour number)
_scr_get_border_7:                ;{{Addr=$0d2a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$00             ;{{0D2A:0e00}} 
        ld      hl,software_colour_to_hardware_colour_table;{{0D2C:21990d}}  table to convert from software colour
                                  ; number to hardware colour number
;;----------
_scr_get_border_9:                ;{{Addr=$0d2f Code Calls/jump count: 1 Data use count: 0}}
        cp      (hl)              ;{{0D2F:be}}  same as this entry in the table?
        ret     z                 ;{{0D30:c8}}  zero set if entry is the same, zero clear if entry is different
        inc     hl                ;{{0D31:23}} 
        inc     c                 ;{{0D32:0c}} 
        jr      _scr_get_border_9 ;{{0D33:18fa}} 

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
        ld      e,a               ;{{0D35:5f}} 
        ld      d,$00             ;{{0D36:1600}} 
        ld      hl,Border_and_Pens_Second_Inks_;{{0D38:21e5b7}}  palette 2 start
        add     hl,de             ;{{0D3B:19}} 
        ex      de,hl             ;{{0D3C:eb}} 
        ld      hl,$ffef          ;{{0D3D:21efff}}  palette 1 start (B7D4)
        add     hl,de             ;{{0D40:19}} 
        ret                       ;{{0D41:c9}} 
;;============================================================================
;; setup palette swap event
setup_palette_swap_event:         ;{{Addr=$0d42 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b7f9       ;{{0D42:21f9b7}} 
        push    hl                ;{{0D45:e5}} 
        call    KL_DEL_FRAME_FLY  ;{{0D46:cd7001}}  KL DEL FRAME FLY
        call    _frame_flyback_routine_to_swap_palettes_10;{{0D49:cd730d}} 
        ld      de,frame_flyback_routine_to_swap_palettes;{{0D4C:11610d}} ##LABEL##
        ld      b,$81             ;{{0D4F:0681}} 
        pop     hl                ;{{0D51:e1}} 
        jp      KL_NEW_FRAME_FLY  ;{{0D52:c36301}}  KL NEW FRAME FLY

;;==================================================================================
;; delete palette swap event
delete_palette_swap_event:        ;{{Addr=$0d55 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b7f9       ;{{0D55:21f9b7}} 
        call    KL_DEL_FRAME_FLY  ;{{0D58:cd7001}}  KL DEL FRAME FLY
        call    _frame_flyback_routine_to_swap_palettes_20;{{0D5B:cd870d}} 
        jp      MC_CLEAR_INKS     ;{{0D5E:c38607}}  MC CLEAR INKS

;;===============================================================
;; frame flyback routine to swap palettes
frame_flyback_routine_to_swap_palettes:;{{Addr=$0d61 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,RAM_b7f8       ;{{0D61:21f8b7}} 
        dec     (hl)              ;{{0D64:35}} 
        jr      z,_frame_flyback_routine_to_swap_palettes_10;{{0D65:280c}}  (+&0c)
        dec     hl                ;{{0D67:2b}} 
        ld      a,(hl)            ;{{0D68:7e}} 
        or      a                 ;{{0D69:b7}} 
        ret     z                 ;{{0D6A:c8}} 

        call    _frame_flyback_routine_to_swap_palettes_20;{{0D6B:cd870d}} 
        call    MC_SET_INKS       ;{{0D6E:cd8c07}}  MC SET INKS
        jr      _frame_flyback_routine_to_swap_palettes_17;{{0D71:180f}}  (+&0f)
;;------------------------------------------------------------

_frame_flyback_routine_to_swap_palettes_10:;{{Addr=$0d73 Code Calls/jump count: 2 Data use count: 0}}
        call    _frame_flyback_routine_to_swap_palettes_20;{{0D73:cd870d}} 
        ld      (RAM_b7f8),a      ;{{0D76:32f8b7}} 
        call    MC_SET_INKS       ;{{0D79:cd8c07}}  MC SET INKS
        ld      hl,RAM_b7f6       ;{{0D7C:21f6b7}} 
        ld      a,(hl)            ;{{0D7F:7e}} 
        cpl                       ;{{0D80:2f}} 
        ld      (hl),a            ;{{0D81:77}} 
_frame_flyback_routine_to_swap_palettes_17:;{{Addr=$0d82 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{0D82:af}} 
        ld      (RAM_b7f7),a      ;{{0D83:32f7b7}} 
        ret                       ;{{0D86:c9}} 

;;------------------------------------------------------------

_frame_flyback_routine_to_swap_palettes_20:;{{Addr=$0d87 Code Calls/jump count: 3 Data use count: 0}}
        ld      de,Border_and_Pens_Second_Inks_;{{0D87:11e5b7}} 
        ld      a,(RAM_b7f6)      ;{{0D8A:3af6b7}} 
        or      a                 ;{{0D8D:b7}} 
        ld      a,(second_flash_period_);{{0D8E:3ad3b7}} 
        ret     z                 ;{{0D91:c8}} 

;;-------------------------------------------------------------

        ld      de,hw_04__sw_1_   ;{{0D92:11d4b7}} 
        ld      a,(first_flash_period_);{{0D95:3ad2b7}} 
        ret                       ;{{0D98:c9}} 

;;+---------------------------------------------------------------------------
;; software colour to hardware colour table
software_colour_to_hardware_colour_table:;{{Addr=$0d99 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $14,$04,$15,$1c,$18,$1d,$0c,$05,$0d,$16,$06,$17,$1e,$00,$1f,$0e,$07,$0f
        defb $12,$02,$13,$1a,$19,$1b,$0a,$03,$0b,$01,$08,$09,$10,$11

;;============================================================================
;; SCR FILL BOX

SCR_FILL_BOX:                     ;{{Addr=$0db9 Code Calls/jump count: 1 Data use count: 1}}
        ld      c,a               ;{{0DB9:4f}} 
        call    _scr_char_position_35;{{0DBA:cd9b0b}} 


;;============================================================================
;; SCR FLOOD BOX

SCR_FLOOD_BOX:                    ;{{Addr=$0dbd Code Calls/jump count: 4 Data use count: 1}}
        push    hl                ;{{0DBD:e5}} 
        ld      a,d               ;{{0DBE:7a}} 
        call    _scr_sw_roll_112  ;{{0DBF:cdee0e}} 
        jr      nc,_scr_flood_box_9;{{0DC2:3009}}  (+&09)
        ld      b,d               ;{{0DC4:42}} 
_scr_flood_box_5:                 ;{{Addr=$0dc5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),c            ;{{0DC5:71}} 
        call    SCR_NEXT_BYTE     ;{{0DC6:cd050c}}  SCR NEXT BYTE
        djnz    _scr_flood_box_5  ;{{0DC9:10fa}}  (-&06)
        jr      _scr_flood_box_22 ;{{0DCB:1810}}  (+&10)
_scr_flood_box_9:                 ;{{Addr=$0dcd Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{0DCD:c5}} 
        push    de                ;{{0DCE:d5}} 
        ld      (hl),c            ;{{0DCF:71}} 
        dec     d                 ;{{0DD0:15}} 
        jr      z,_scr_flood_box_20;{{0DD1:2808}}  (+&08)
        ld      c,d               ;{{0DD3:4a}} 
        ld      b,$00             ;{{0DD4:0600}} 
        ld      d,h               ;{{0DD6:54}} 
        ld      e,l               ;{{0DD7:5d}} 
        inc     de                ;{{0DD8:13}} 
        ldir                      ;{{0DD9:edb0}} 
_scr_flood_box_20:                ;{{Addr=$0ddb Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{0DDB:d1}} 
        pop     bc                ;{{0DDC:c1}} 
_scr_flood_box_22:                ;{{Addr=$0ddd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{0DDD:e1}} 
        call    SCR_NEXT_LINE     ;{{0DDE:cd1f0c}}  SCR NEXT LINE
        dec     e                 ;{{0DE1:1d}} 
        jr      nz,SCR_FLOOD_BOX  ;{{0DE2:20d9}}  (-&27)
        ret                       ;{{0DE4:c9}} 


;;============================================================================
;; SCR CHAR INVERT

SCR_CHAR_INVERT:                  ;{{Addr=$0de5 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,b               ;{{0DE5:78}} 
        xor     c                 ;{{0DE6:a9}} 
        ld      c,a               ;{{0DE7:4f}} 
        call    SCR_CHAR_POSITION ;{{0DE8:cd6a0b}}  SCR CHAR POSITION
        ld      d,$08             ;{{0DEB:1608}} 
_scr_char_invert_5:               ;{{Addr=$0ded Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0DED:e5}} 
        push    bc                ;{{0DEE:c5}} 
_scr_char_invert_7:               ;{{Addr=$0def Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0DEF:7e}} 
        xor     c                 ;{{0DF0:a9}} 
        ld      (hl),a            ;{{0DF1:77}} 
        call    SCR_NEXT_BYTE     ;{{0DF2:cd050c}}  SCR NEXT BYTE
        djnz    _scr_char_invert_7;{{0DF5:10f8}}  (-&08)
        pop     bc                ;{{0DF7:c1}} 
        pop     hl                ;{{0DF8:e1}} 
        call    SCR_NEXT_LINE     ;{{0DF9:cd1f0c}}  SCR NEXT LINE
        dec     d                 ;{{0DFC:15}} 
        jr      nz,_scr_char_invert_5;{{0DFD:20ee}}  (-&12)
        ret                       ;{{0DFF:c9}} 


;;============================================================================
;; SCR HW ROLL
SCR_HW_ROLL:                      ;{{Addr=$0e00 Code Calls/jump count: 1 Data use count: 1}}
        ld      c,a               ;{{0E00:4f}} 
        push    bc                ;{{0E01:c5}} 
        ld      de,$ffd0          ;{{0E02:11d0ff}} 
        ld      b,$30             ;{{0E05:0630}} 
        call    _scr_hw_roll_19   ;{{0E07:cd2a0e}} 
        pop     bc                ;{{0E0A:c1}} 
        call    MC_WAIT_FLYBACK   ;{{0E0B:cdb407}}  MC WAIT FLYBACK
        ld      a,b               ;{{0E0E:78}} 
        or      a                 ;{{0E0F:b7}} 
        jr      nz,_scr_hw_roll_15;{{0E10:200d}}  (+&0d)
        ld      de,$ffb0          ;{{0E12:11b0ff}} 
        call    _scr_hw_roll_30   ;{{0E15:cd3d0e}} 
        ld      de,$0000          ;{{0E18:110000}} ##LIT##;WARNING: Code area used as literal
        ld      b,$20             ;{{0E1B:0620}} 
        jr      _scr_hw_roll_19   ;{{0E1D:180b}}  (+&0b)
_scr_hw_roll_15:                  ;{{Addr=$0e1f Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0050          ;{{0E1F:115000}} ##LIT##;WARNING: Code area used as literal
        call    _scr_hw_roll_30   ;{{0E22:cd3d0e}} 
        ld      de,$ffb0          ;{{0E25:11b0ff}} 
        ld      b,$20             ;{{0E28:0620}} 
_scr_hw_roll_19:                  ;{{Addr=$0e2a Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(screen_offset);{{0E2A:2ac4b7}} 
        add     hl,de             ;{{0E2D:19}} 
        ld      a,h               ;{{0E2E:7c}} 
        and     $07               ;{{0E2F:e607}} 
        ld      h,a               ;{{0E31:67}} 
        ld      a,(screen_base_HB_);{{0E32:3ac6b7}} 
        add     a,h               ;{{0E35:84}} 
        ld      h,a               ;{{0E36:67}} 
        ld      d,b               ;{{0E37:50}} 
        ld      e,$08             ;{{0E38:1e08}} 
        jp      SCR_FLOOD_BOX     ;{{0E3A:c3bd0d}} ; SCR FLOOD BOX
_scr_hw_roll_30:                  ;{{Addr=$0e3d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(screen_offset);{{0E3D:2ac4b7}} 
        add     hl,de             ;{{0E40:19}} 
        jp      SCR_OFFSET        ;{{0E41:c3370b}} ; SCR OFFSET


;;============================================================================
;; SCR SW ROLL

SCR_SW_ROLL:                      ;{{Addr=$0e44 Code Calls/jump count: 1 Data use count: 1}}
        push    af                ;{{0E44:f5}} 
        ld      a,b               ;{{0E45:78}} 
        or      a                 ;{{0E46:b7}} 
        jr      z,_scr_sw_roll_34 ;{{0E47:2830}}  (+&30)
        push    hl                ;{{0E49:e5}} 
        call    _scr_char_position_35;{{0E4A:cd9b0b}} 
        ex      (sp),hl           ;{{0E4D:e3}} 
        inc     l                 ;{{0E4E:2c}} 
        call    SCR_CHAR_POSITION ;{{0E4F:cd6a0b}}  SCR CHAR POSITION
        ld      c,d               ;{{0E52:4a}} 
        ld      a,e               ;{{0E53:7b}} 
        sub     $08               ;{{0E54:d608}} 
        ld      b,a               ;{{0E56:47}} 
        jr      z,_scr_sw_roll_28 ;{{0E57:2817}}  (+&17)
        pop     de                ;{{0E59:d1}} 
        call    MC_WAIT_FLYBACK   ;{{0E5A:cdb407}}  MC WAIT FLYBACK
_scr_sw_roll_16:                  ;{{Addr=$0e5d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{0E5D:c5}} 
        push    hl                ;{{0E5E:e5}} 
        push    de                ;{{0E5F:d5}} 
        call    _scr_sw_roll_65   ;{{0E60:cdaa0e}} 
        pop     hl                ;{{0E63:e1}} 
        call    SCR_NEXT_LINE     ;{{0E64:cd1f0c}}  SCR NEXT LINE
        ex      de,hl             ;{{0E67:eb}} 
        pop     hl                ;{{0E68:e1}} 
        call    SCR_NEXT_LINE     ;{{0E69:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0E6C:c1}} 
        djnz    _scr_sw_roll_16   ;{{0E6D:10ee}}  (-&12)
        push    de                ;{{0E6F:d5}} 
_scr_sw_roll_28:                  ;{{Addr=$0e70 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{0E70:e1}} 
        ld      d,c               ;{{0E71:51}} 
        ld      e,$08             ;{{0E72:1e08}} 
        pop     af                ;{{0E74:f1}} 
        ld      c,a               ;{{0E75:4f}} 
        jp      SCR_FLOOD_BOX     ;{{0E76:c3bd0d}} ; SCR FLOOD BOX
_scr_sw_roll_34:                  ;{{Addr=$0e79 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0E79:e5}} 
        push    de                ;{{0E7A:d5}} 
        call    _scr_char_position_35;{{0E7B:cd9b0b}} 
        ld      c,d               ;{{0E7E:4a}} 
        ld      a,e               ;{{0E7F:7b}} 
        sub     $08               ;{{0E80:d608}} 
        ld      b,a               ;{{0E82:47}} 
        pop     de                ;{{0E83:d1}} 
        ex      (sp),hl           ;{{0E84:e3}} 
        jr      z,_scr_sw_roll_28 ;{{0E85:28e9}}  (-&17)
        push    bc                ;{{0E87:c5}} 
        ld      l,e               ;{{0E88:6b}} 
        ld      d,h               ;{{0E89:54}} 
        inc     e                 ;{{0E8A:1c}} 
        call    SCR_CHAR_POSITION ;{{0E8B:cd6a0b}}  SCR CHAR POSITION
        ex      de,hl             ;{{0E8E:eb}} 
        call    SCR_CHAR_POSITION ;{{0E8F:cd6a0b}}  SCR CHAR POSITION
        pop     bc                ;{{0E92:c1}} 
        call    MC_WAIT_FLYBACK   ;{{0E93:cdb407}}  MC WAIT FLYBACK
_scr_sw_roll_53:                  ;{{Addr=$0e96 Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_PREV_LINE     ;{{0E96:cd390c}}  SCR PREV LINE
        push    hl                ;{{0E99:e5}} 
        ex      de,hl             ;{{0E9A:eb}} 
        call    SCR_PREV_LINE     ;{{0E9B:cd390c}}  SCR PREV LINE
        push    hl                ;{{0E9E:e5}} 
        push    bc                ;{{0E9F:c5}} 
        call    _scr_sw_roll_65   ;{{0EA0:cdaa0e}} 
        pop     bc                ;{{0EA3:c1}} 
        pop     de                ;{{0EA4:d1}} 
        pop     hl                ;{{0EA5:e1}} 
        djnz    _scr_sw_roll_53   ;{{0EA6:10ee}}  (-&12)
        jr      _scr_sw_roll_28   ;{{0EA8:18c6}}  (-&3a)
_scr_sw_roll_65:                  ;{{Addr=$0eaa Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$00             ;{{0EAA:0600}} 
        call    _scr_sw_roll_110  ;{{0EAC:cdec0e}} 
        jr      c,_scr_sw_roll_84 ;{{0EAF:3816}}  (+&16)
        call    _scr_sw_roll_110  ;{{0EB1:cdec0e}} 
        jr      nc,_scr_sw_roll_99;{{0EB4:3025}}  (+&25)
        push    bc                ;{{0EB6:c5}} 
        xor     a                 ;{{0EB7:af}} 
        sub     l                 ;{{0EB8:95}} 
        ld      c,a               ;{{0EB9:4f}} 
        ldir                      ;{{0EBA:edb0}} 
        pop     bc                ;{{0EBC:c1}} 
        cpl                       ;{{0EBD:2f}} 
        inc     a                 ;{{0EBE:3c}} 
        add     a,c               ;{{0EBF:81}} 
        ld      c,a               ;{{0EC0:4f}} 
        ld      a,h               ;{{0EC1:7c}} 
        sub     $08               ;{{0EC2:d608}} 
        ld      h,a               ;{{0EC4:67}} 
        jr      _scr_sw_roll_99   ;{{0EC5:1814}}  (+&14)
_scr_sw_roll_84:                  ;{{Addr=$0ec7 Code Calls/jump count: 1 Data use count: 0}}
        call    _scr_sw_roll_110  ;{{0EC7:cdec0e}} 
        jr      c,_scr_sw_roll_101;{{0ECA:3812}}  (+&12)
        push    bc                ;{{0ECC:c5}} 
        xor     a                 ;{{0ECD:af}} 
        sub     e                 ;{{0ECE:93}} 
        ld      c,a               ;{{0ECF:4f}} 
        ldir                      ;{{0ED0:edb0}} 
        pop     bc                ;{{0ED2:c1}} 
        cpl                       ;{{0ED3:2f}} 
        inc     a                 ;{{0ED4:3c}} 
        add     a,c               ;{{0ED5:81}} 
        ld      c,a               ;{{0ED6:4f}} 
        ld      a,d               ;{{0ED7:7a}} 
        sub     $08               ;{{0ED8:d608}} 
        ld      d,a               ;{{0EDA:57}} 
_scr_sw_roll_99:                  ;{{Addr=$0edb Code Calls/jump count: 2 Data use count: 0}}
        ldir                      ;{{0EDB:edb0}} 
        ret                       ;{{0EDD:c9}} 

_scr_sw_roll_101:                 ;{{Addr=$0ede Code Calls/jump count: 1 Data use count: 0}}
        ld      b,c               ;{{0EDE:41}} 
_scr_sw_roll_102:                 ;{{Addr=$0edf Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0EDF:7e}} 
        ld      (de),a            ;{{0EE0:12}} 
        call    SCR_NEXT_BYTE     ;{{0EE1:cd050c}}  SCR NEXT BYTE
        ex      de,hl             ;{{0EE4:eb}} 
        call    SCR_NEXT_BYTE     ;{{0EE5:cd050c}}  SCR NEXT BYTE
        ex      de,hl             ;{{0EE8:eb}} 
        djnz    _scr_sw_roll_102  ;{{0EE9:10f4}} 
        ret                       ;{{0EEB:c9}} 

;;----------------------------------------------------------------------
_scr_sw_roll_110:                 ;{{Addr=$0eec Code Calls/jump count: 3 Data use count: 0}}
        ld      a,c               ;{{0EEC:79}} 
        ex      de,hl             ;{{0EED:eb}} 
_scr_sw_roll_112:                 ;{{Addr=$0eee Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{0EEE:3d}} 
        add     a,l               ;{{0EEF:85}} 
        ret     nc                ;{{0EF0:d0}} 

        ld      a,h               ;{{0EF1:7c}} 
        and     $07               ;{{0EF2:e607}} 
        xor     $07               ;{{0EF4:ee07}} 
        ret     nz                ;{{0EF6:c0}} 

        scf                       ;{{0EF7:37}} 
        ret                       ;{{0EF8:c9}} 


;;============================================================================
;; SCR UNPACK

SCR_UNPACK:                       ;{{Addr=$0ef9 Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_GET_MODE      ;{{0EF9:cd0c0b}} ; SCR GET MODE 
        jr      c,_scr_unpack_8   ;{{0EFC:380d}}  mode 0
        jr      z,_scr_unpack_6   ;{{0EFE:2806}}  mode 1
        ld      bc,$0008          ;{{0F00:010800}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{0F03:edb0}} 
        ret                       ;{{0F05:c9}} 

;;-----------------------------------------------------------------------------
;; SCR UNPACK: mode 1
_scr_unpack_6:                    ;{{Addr=$0f06 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0288          ;{{0F06:018802}} ##LIT##;WARNING: Code area used as literal
        jr      _scr_unpack_9     ;{{0F09:1803}}  0x088 is the pixel mask

;;-----------------------------------------------------------------------------
;; SCR UNPACK: mode 0
_scr_unpack_8:                    ;{{Addr=$0f0b Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$04aa          ;{{0F0B:01aa04}} ; 0x0aa is the pixel mask ##LIT##;WARNING: Code area used as literal

;;-----------------------------------------------------------------------------
;; routine used by mode 0 and mode 1 for SCR UNPACK
_scr_unpack_9:                    ;{{Addr=$0f0e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$08             ;{{0F0E:3e08}} 
_scr_unpack_10:                   ;{{Addr=$0f10 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{0F10:f5}} 
        push    hl                ;{{0F11:e5}} 
        ld      l,(hl)            ;{{0F12:6e}} 
        ld      h,b               ;{{0F13:60}} 
_scr_unpack_14:                   ;{{Addr=$0f14 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{0F14:af}} 
_scr_unpack_15:                   ;{{Addr=$0f15 Code Calls/jump count: 1 Data use count: 0}}
        rlc     l                 ;{{0F15:cb05}} 
        jr      nc,_scr_unpack_18 ;{{0F17:3001}}  (+&01)
        or      c                 ;{{0F19:b1}} 
_scr_unpack_18:                   ;{{Addr=$0f1a Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0F1A:cb09}} 
        jr      nc,_scr_unpack_15 ;{{0F1C:30f7}}  (-&09)
        ld      (de),a            ;{{0F1E:12}} 
        inc     de                ;{{0F1F:13}} 
        djnz    _scr_unpack_14    ;{{0F20:10f2}}  (-&0e)
        ld      b,h               ;{{0F22:44}} 
        pop     hl                ;{{0F23:e1}} 
        inc     hl                ;{{0F24:23}} 
        pop     af                ;{{0F25:f1}} 
        dec     a                 ;{{0F26:3d}} 
        jr      nz,_scr_unpack_10 ;{{0F27:20e7}}  (-&19)
        ret                       ;{{0F29:c9}} 


;;============================================================================
;; SCR REPACK

SCR_REPACK:                       ;{{Addr=$0f2a Code Calls/jump count: 2 Data use count: 1}}
        ld      c,a               ;{{0F2A:4f}} 
        call    SCR_CHAR_POSITION ;{{0F2B:cd6a0b}}  SCR CHAR POSITION
        call    SCR_GET_MODE      ;{{0F2E:cd0c0b}}  SCR GET MODE
        ld      b,$08             ;{{0F31:0608}} 
        jr      c,_scr_repack_40  ;{{0F33:3836}}  mode 0
        jr      z,_scr_repack_14  ;{{0F35:280b}}  mode 1

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 2
_scr_repack_6:                    ;{{Addr=$0f37 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0F37:7e}} 
        xor     c                 ;{{0F38:a9}} 
        cpl                       ;{{0F39:2f}} 
        ld      (de),a            ;{{0F3A:12}} 
        inc     de                ;{{0F3B:13}} 
        call    SCR_NEXT_LINE     ;{{0F3C:cd1f0c}}  SCR NEXT LINE
        djnz    _scr_repack_6     ;{{0F3F:10f6}} 
        ret                       ;{{0F41:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 1
_scr_repack_14:                   ;{{Addr=$0f42 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0F42:c5}} 
        push    hl                ;{{0F43:e5}} 
        push    de                ;{{0F44:d5}} 
        call    _scr_repack_29    ;{{0F45:cd5a0f}}  mode 1
        call    SCR_NEXT_BYTE     ;{{0F48:cd050c}}  SCR NEXT BYTE
        call    _scr_repack_29    ;{{0F4B:cd5a0f}}  mode 1
        ld      a,e               ;{{0F4E:7b}} 
        pop     de                ;{{0F4F:d1}} 
        ld      (de),a            ;{{0F50:12}} 
        inc     de                ;{{0F51:13}} 
        pop     hl                ;{{0F52:e1}} 
        call    SCR_NEXT_LINE     ;{{0F53:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0F56:c1}} 
        djnz    _scr_repack_14    ;{{0F57:10e9}} 
        ret                       ;{{0F59:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 1 (part)
_scr_repack_29:                   ;{{Addr=$0f5a Code Calls/jump count: 2 Data use count: 0}}
        ld      d,$88             ;{{0F5A:1688}}  pixel mask
        ld      b,$04             ;{{0F5C:0604}} 
_scr_repack_31:                   ;{{Addr=$0f5e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0F5E:7e}} 
        xor     c                 ;{{0F5F:a9}} 
        and     d                 ;{{0F60:a2}} 
        jr      nz,_scr_repack_36 ;{{0F61:2001}}  (+&01)
        scf                       ;{{0F63:37}} 
_scr_repack_36:                   ;{{Addr=$0f64 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0F64:cb13}} 
        rrc     d                 ;{{0F66:cb0a}} 
        djnz    _scr_repack_31    ;{{0F68:10f4}} 
        ret                       ;{{0F6A:c9}} 

;;----------------------------------------------------------------------------------------
;; SCR REPACK: mode 0
_scr_repack_40:                   ;{{Addr=$0f6b Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{0F6B:c5}} 
        push    hl                ;{{0F6C:e5}} 
        push    de                ;{{0F6D:d5}} 

        ld      b,$04             ;{{0F6E:0604}} 
_scr_repack_44:                   ;{{Addr=$0f70 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{0F70:7e}} 
        xor     c                 ;{{0F71:a9}} 
        and     $aa               ;{{0F72:e6aa}}  left pixel mask
        jr      nz,_scr_repack_49 ;{{0F74:2001}} 
        scf                       ;{{0F76:37}} 
_scr_repack_49:                   ;{{Addr=$0f77 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0F77:cb13}} 
        ld      a,(hl)            ;{{0F79:7e}} 
        xor     c                 ;{{0F7A:a9}} 
        and     $55               ;{{0F7B:e655}}  right pixel mask
        jr      nz,_scr_repack_55 ;{{0F7D:2001}} 
        scf                       ;{{0F7F:37}} 
_scr_repack_55:                   ;{{Addr=$0f80 Code Calls/jump count: 1 Data use count: 0}}
        rl      e                 ;{{0F80:cb13}} 
        call    SCR_NEXT_BYTE     ;{{0F82:cd050c}}  SCR NEXT BYTE
        djnz    _scr_repack_44    ;{{0F85:10e9}} 

        ld      a,e               ;{{0F87:7b}} 
        pop     de                ;{{0F88:d1}} 
        ld      (de),a            ;{{0F89:12}} 
        inc     de                ;{{0F8A:13}} 
        pop     hl                ;{{0F8B:e1}} 
        call    SCR_NEXT_LINE     ;{{0F8C:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{0F8F:c1}} 
        djnz    _scr_repack_40    ;{{0F90:10d9}} 
        ret                       ;{{0F92:c9}} 


;;============================================================================
;; SCR HORIZONTAL

SCR_HORIZONTAL:                   ;{{Addr=$0f93 Code Calls/jump count: 0 Data use count: 1}}
        call    _scr_vertical_8   ;{{0F93:cdad0f}} 
        call    _scr_vertical_18  ;{{0F96:cdc20f}} 
        jr      _scr_vertical_2   ;{{0F99:1806}}  (+&06)


;;============================================================================
;; SCR VERTICAL

SCR_VERTICAL:                     ;{{Addr=$0f9b Code Calls/jump count: 0 Data use count: 1}}
        call    _scr_vertical_8   ;{{0F9B:cdad0f}} 
        call    _scr_vertical_67  ;{{0F9E:cd1610}} 
_scr_vertical_2:                  ;{{Addr=$0fa1 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b802)     ;{{0FA1:2a02b8}} 
        ld      a,l               ;{{0FA4:7d}} 
        ld      (GRAPHICS_PEN),a  ;{{0FA5:32a3b6}}  graphics pen
        ld      a,h               ;{{0FA8:7c}} 
        ld      (line_MASK),a     ;{{0FA9:32b3b6}}  graphics line mask
        ret                       ;{{0FAC:c9}} 

;;---------------------------------------------------------------------

_scr_vertical_8:                  ;{{Addr=$0fad Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{0FAD:e5}} 
        ld      hl,(GRAPHICS_PEN) ;{{0FAE:2aa3b6}}  L = graphics pen, H = graphics paper
        ld      (GRAPHICS_PEN),a  ;{{0FB1:32a3b6}}  graphics pen
        ld      a,(line_MASK)     ;{{0FB4:3ab3b6}}  graphics line mask
        ld      h,a               ;{{0FB7:67}} 
        ld      a,$ff             ;{{0FB8:3eff}} 
        ld      (line_MASK),a     ;{{0FBA:32b3b6}}  graphics line mask
        ld      (RAM_b802),hl     ;{{0FBD:2202b8}} 
        pop     hl                ;{{0FC0:e1}} 
        ret                       ;{{0FC1:c9}} 

_scr_vertical_18:                 ;{{Addr=$0fc2 Code Calls/jump count: 2 Data use count: 0}}
        scf                       ;{{0FC2:37}} 
        call    _scr_vertical_86  ;{{0FC3:cd3b10}} 
_scr_vertical_20:                 ;{{Addr=$0fc6 Code Calls/jump count: 1 Data use count: 0}}
        rlc     b                 ;{{0FC6:cb00}} 
        ld      a,c               ;{{0FC8:79}} 
        jr      nc,_scr_vertical_34;{{0FC9:3013}}  (+&13)
_scr_vertical_23:                 ;{{Addr=$0fcb Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{0FCB:1d}} 
        jr      nz,_scr_vertical_27;{{0FCC:2003}}  (+&03)
        dec     d                 ;{{0FCE:15}} 
        jr      z,_scr_vertical_52;{{0FCF:282c}}  (+&2c)
_scr_vertical_27:                 ;{{Addr=$0fd1 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0FD1:cb09}} 
        jr      c,_scr_vertical_52;{{0FD3:3828}}  (+&28)
        bit     7,b               ;{{0FD5:cb78}} 
        jr      z,_scr_vertical_52;{{0FD7:2824}}  (+&24)
        or      c                 ;{{0FD9:b1}} 
        rlc     b                 ;{{0FDA:cb00}} 
        jr      _scr_vertical_23  ;{{0FDC:18ed}}  (-&13)
_scr_vertical_34:                 ;{{Addr=$0fde Code Calls/jump count: 2 Data use count: 0}}
        dec     e                 ;{{0FDE:1d}} 
        jr      nz,_scr_vertical_38;{{0FDF:2003}}  (+&03)
        dec     d                 ;{{0FE1:15}} 
        jr      z,_scr_vertical_45;{{0FE2:280d}}  (+&0d)
_scr_vertical_38:                 ;{{Addr=$0fe4 Code Calls/jump count: 1 Data use count: 0}}
        rrc     c                 ;{{0FE4:cb09}} 
        jr      c,_scr_vertical_45;{{0FE6:3809}}  (+&09)
        bit     7,b               ;{{0FE8:cb78}} 
        jr      nz,_scr_vertical_45;{{0FEA:2005}}  (+&05)
        or      c                 ;{{0FEC:b1}} 
        rlc     b                 ;{{0FED:cb00}} 
        jr      _scr_vertical_34  ;{{0FEF:18ed}}  (-&13)
_scr_vertical_45:                 ;{{Addr=$0ff1 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{0FF1:c5}} 
        ld      c,a               ;{{0FF2:4f}} 
        ld      a,(GRAPHICS_PAPER);{{0FF3:3aa4b6}}  graphics paper
        ld      b,a               ;{{0FF6:47}} 
        ld      a,(RAM_b6b4)      ;{{0FF7:3ab4b6}} 
        or      a                 ;{{0FFA:b7}} 
        jr      _scr_vertical_57  ;{{0FFB:1807}}  (+&07)
_scr_vertical_52:                 ;{{Addr=$0ffd Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{0FFD:c5}} 
        ld      c,a               ;{{0FFE:4f}} 
        ld      a,(GRAPHICS_PEN)  ;{{0FFF:3aa3b6}}  graphics pen
        ld      b,a               ;{{1002:47}} 
        xor     a                 ;{{1003:af}} 
_scr_vertical_57:                 ;{{Addr=$1004 Code Calls/jump count: 1 Data use count: 0}}
        call    z,SCR_WRITE       ;{{1004:cce8bd}}  IND: SCR WRITE
        pop     bc                ;{{1007:c1}} 
        bit     7,c               ;{{1008:cb79}} 
        call    nz,SCR_NEXT_BYTE  ;{{100A:c4050c}}  SCR NEXT BYTE
        ld      a,d               ;{{100D:7a}} 
        or      e                 ;{{100E:b3}} 
        jr      nz,_scr_vertical_20;{{100F:20b5}}  (-&4b)
_scr_vertical_64:                 ;{{Addr=$1011 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{1011:78}} 
        ld      (line_MASK),a     ;{{1012:32b3b6}}  graphics line mask
        ret                       ;{{1015:c9}} 

_scr_vertical_67:                 ;{{Addr=$1016 Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{1016:b7}} 
        call    _scr_vertical_86  ;{{1017:cd3b10}} 
_scr_vertical_69:                 ;{{Addr=$101a Code Calls/jump count: 2 Data use count: 0}}
        rlc     b                 ;{{101A:cb00}} 
        ld      a,(GRAPHICS_PEN)  ;{{101C:3aa3b6}}  graphics pen
        jr      c,_scr_vertical_76;{{101F:3809}}  (+&09)
        ld      a,(RAM_b6b4)      ;{{1021:3ab4b6}} 
        or      a                 ;{{1024:b7}} 
        jr      nz,_scr_vertical_80;{{1025:2009}}  (+&09)
        ld      a,(GRAPHICS_PAPER);{{1027:3aa4b6}}  graphics paper
_scr_vertical_76:                 ;{{Addr=$102a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{102A:c5}} 
        ld      b,a               ;{{102B:47}} 
        call    SCR_WRITE         ;{{102C:cde8bd}}  IND: SCR WRITE
        pop     bc                ;{{102F:c1}} 
_scr_vertical_80:                 ;{{Addr=$1030 Code Calls/jump count: 1 Data use count: 0}}
        call    SCR_PREV_LINE     ;{{1030:cd390c}}  SCR PREV LINE
        dec     e                 ;{{1033:1d}} 
        jr      nz,_scr_vertical_69;{{1034:20e4}}  (-&1c)
        dec     d                 ;{{1036:15}} 
        jr      nz,_scr_vertical_69;{{1037:20e1}}  (-&1f)
        jr      _scr_vertical_64  ;{{1039:18d6}}  (-&2a)
_scr_vertical_86:                 ;{{Addr=$103b Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{103B:e5}} 
        jr      nc,_scr_vertical_90;{{103C:3002}}  (+&02)
        ld      h,d               ;{{103E:62}} 
        ld      l,e               ;{{103F:6b}} 
_scr_vertical_90:                 ;{{Addr=$1040 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{1040:b7}} 
        sbc     hl,bc             ;{{1041:ed42}} 
        call    invert_HL         ;{{1043:cd3919}}  HL = -HL
        inc     h                 ;{{1046:24}} 
        inc     l                 ;{{1047:2c}} 
        ex      (sp),hl           ;{{1048:e3}} 
        call    SCR_DOT_POSITION  ;{{1049:cdaf0b}}  SCR DOT POSITION
        ld      a,(line_MASK)     ;{{104C:3ab3b6}}  graphics line mask
        ld      b,a               ;{{104F:47}} 
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



