;;===================================================================
;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>START OF DATA COPIED TO HI JUMPBLOCK
START_OF_DATA_COPIED_TO_HI_JUMPBLOCK:;{{Addr=$03a6 Code Calls/jump count: 0 Data use count: 1}}
                                  
org $b900,$

;;+HIGH KERNEL JUMPBLOCK
        jp      HI_KL_U_ROM_ENABLE;{{B900/16E5A:c35fba}} ; HI: KL U ROM ENABLE
        jp      HI_KL_U_ROM_DISABLE;{{03A9/B903:c366ba}} ; HI: KL U ROM DISABLE
        jp      HI_KL_L_ROM_ENABLE;{{03AC/B906:c351ba}} ; HI: KL L ROM ENABLE
        jp      HI_KL_L_ROM_DISABLE;{{03AF/B909:c358ba}} ; HI: KL L ROM DISABLE
        jp      HI_KL_L_ROM_RESTORE;{{03B2/B90C:c370ba}} ; HI: KL L ROM RESTORE
        jp      HI_KL_ROM_SELECT  ;{{03B5/B90F:c379ba}} ; HI: KL ROM SELECT
        jp      HI_KL_CURR_SELECTION;{{03B8/B912:c39dba}} ; HI: KL CURR SELECTION
        jp      HI_KL_PROBE_ROM   ;{{03BB/B915:c37eba}} ; HI: KL PROBE ROM
        jp      HI_KL_ROM_DESELECT;{{03BE/B918:c387ba}} ; HI: KL ROM DESELECT
        jp      HI_KL_LDIR        ;{{03C1/B91B:c3a1ba}} ; HI: KL LDIR
        jp      HI_KL_LDDR        ;{{03C4/B91E:c3a7ba}} ; HI: KL LDDR

;;============================================================
;; HI: KL POLL SYNCRONOUS
;!!!This is a published address and must not be changed: (03c7)/b921!!!
        ld      a,(High_byte_of_above_Address_of_the_first);{{03C7/B921:3ac1b8}} ; HI: KL POLL SYNCRONOUS
        or      a                 ;{{03CA/B924:b7}} 
        ret     z                 ;{{03CB/B925:c8}} 

        push    hl                ;{{03CC/B926:e5}} 
        di                        ;{{03CD/B927:f3}} 
        jr      do_kl_poll_syncronous;{{03CE/B928:1806}}  (+&06)

;;============================================================
;; HI: KL SCAN NEEDED
;!!!This is a published address and must not be changed: (03d0)/b92a!!!
        ld      hl,Keyboard_scan_flag_;{{03D0/B92A:21bfb8}} ; HI: KL SCAN NEEDED
        ld      (hl),$01          ;{{03D3/B92D:3601}} 
        ret                       ;{{03D5/B92F:c9}} 

;;======
;;do kl poll syncronous
do_kl_poll_syncronous:            ;{{Addr=$03d6 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_the_first_event_block_in_chai);{{03D6/B930:2ac0b8}}  synchronous event list
        ld      a,h               ;{{03D9/B933:7c}} 
        or      a                 ;{{03DA/B934:b7}} 
        jr      z,_do_kl_poll_syncronous_9;{{03DB/B935:2807}}  (+&07)
        inc     hl                ;{{03DD/B937:23}} 
        inc     hl                ;{{03DE/B938:23}} 
        inc     hl                ;{{03DF/B939:23}} 
        ld      a,(RAM_b8c2)      ;{{03E0/B93A:3ac2b8}} 
        cp      (hl)              ;{{03E3/B93D:be}} 
_do_kl_poll_syncronous_9:         ;{{Addr=$03e4 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{03E4/B93E:e1}} 
        ei                        ;{{03E5/B93F:fb}} 
        ret                       ;{{03E6/B940:c9}} 

;;============================================================================================
;; RST 7 - LOW: INTERRUPT ENTRY handler

RST_7__LOW_INTERRUPT_ENTRY_handler:;{{Addr=$03e7 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{03E7/B941:f3}} 
        ex      af,af'            ;{{03E8/B942:08}} 
        jr      c,_rst_7__low_interrupt_entry_handler_38;{{03E9/B943:3833}}  detect external interrupt
        exx                       ;{{03EB/B945:d9}} 
        ld      a,c               ;{{03EC/B946:79}} 
        scf                       ;{{03ED/B947:37}} 
        ei                        ;{{03EE/B948:fb}} 
        ex      af,af'            ;{{03EF/B949:08}}  allow interrupt function to be re-entered. This will happen if there is an external interrupt
                                  ; source that continues to assert INT. Internal raster interrupts are acknowledged automatically and cleared.
        di                        ;{{03F0/B94A:f3}} 
        push    af                ;{{03F1/B94B:f5}} 
        res     2,c               ;{{03F2/B94C:cb91}}  ensure lower rom is active in range &0000-&3fff
        out     (c),c             ;{{03F4/B94E:ed49}} 
        call    update_TIME       ;{{03F6/B950:cdb100}}  update time, execute FRAME FLY, FAST TICKER and SOUND events
                                  ; also scan keyboard
_rst_7__low_interrupt_entry_handler_13:;{{Addr=$03f9 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{03F9/B953:b7}} 
        ex      af,af'            ;{{03FA/B954:08}} 
        ld      c,a               ;{{03FB/B955:4f}} 
        ld      b,$7f             ;{{03FC/B956:067f}} 

        ld      a,(RAM_b831)      ;{{03FE/B958:3a31b8}} 
        or      a                 ;{{0401/B95B:b7}} 
        jr      z,_rst_7__low_interrupt_entry_handler_33;{{0402/B95C:2814}}  quit...
        jp      m,_rst_7__low_interrupt_entry_handler_33;{{0404/B95E:fa72b9}}  quit... (same as 0418, but in RAM)

        ld      a,c               ;{{0407/B961:79}} 
        and     $0c               ;{{0408/B962:e60c}}  %00001100
        push    af                ;{{040A/B964:f5}} 
        res     2,c               ;{{040B/B965:cb91}}  ensure lower rom is active in range &0000-&3fff
        exx                       ;{{040D/B967:d9}} 
        call    _queue_asynchronous_events_18;{{040E/B968:cd0a01}} 
        exx                       ;{{0411/B96B:d9}} 
        pop     hl                ;{{0412/B96C:e1}} 
        ld      a,c               ;{{0413/B96D:79}} 
        and     $f3               ;{{0414/B96E:e6f3}}  %11110011
        or      h                 ;{{0416/B970:b4}} 
        ld      c,a               ;{{0417/B971:4f}} 

;;
_rst_7__low_interrupt_entry_handler_33:;{{Addr=$0418 Code Calls/jump count: 2 Data use count: 0}}
        out     (c),c             ;{{0418/B972:ed49}} set rom config/mode etc
        exx                       ;{{041A/B974:d9}} 
        pop     af                ;{{041B/B975:f1}} 
        ei                        ;{{041C/B976:fb}} 
        ret                       ;{{041D/B977:c9}} 

;; handle external interrupt
_rst_7__low_interrupt_entry_handler_38:;{{Addr=$041e Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{041E/B978:08}} 
        pop     hl                ;{{041F/B979:e1}} 
        push    af                ;{{0420/B97A:f5}} 
        set     2,c               ;{{0421/B97B:cbd1}}  disable lower rom 
        out     (c),c             ;{{0423/B97D:ed49}}  set rom config/mode etc
        call    LOW_EXT_INTERRUPT ;{{0425/B97F:cd3b00}}  LOW: EXT INTERRUPT. Patchable by the user
        jr      _rst_7__low_interrupt_entry_handler_13;{{0428/B982:18cf}}  return to interrupt processing.

;;============================================================================================
;; LOW: KL LOW PCHL
LOW_KL_LOW_PCHL:                  ;{{Addr=$042a Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{042A/B984:f3}} 
        push    hl                ;{{042B/B985:e5}}  store HL onto stack
        exx                       ;{{042C/B986:d9}} 
        pop     de                ;{{042D/B987:d1}}  get it back from stack
        jr      _rst_1__low_low_jump_6;{{042E/B988:1806}}  

;;============================================================================================
;; RST 1 - LOW: LOW JUMP

RST_1__LOW_LOW_JUMP:              ;{{Addr=$0430 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{0430/B98A:f3}} 
        exx                       ;{{0431/B98B:d9}} 
        pop     hl                ;{{0432/B98C:e1}}  get return address from stack
        ld      e,(hl)            ;{{0433/B98D:5e}}  DE = address to call
        inc     hl                ;{{0434/B98E:23}} 
        ld      d,(hl)            ;{{0435/B98F:56}} 

;;--------------------------------------------------------------------------------------------
_rst_1__low_low_jump_6:           ;{{Addr=$0436 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0436/B990:08}} 
        ld      a,d               ;{{0437/B991:7a}} 
        res     7,d               ;{{0438/B992:cbba}} 
        res     6,d               ;{{043A/B994:cbb2}} 
        rlca                      ;{{043C/B996:07}} 
        rlca                      ;{{043D/B997:07}} 

;;---------------------------------------------------------------------------------------------
_rst_1__low_low_jump_12:          ;{{Addr=$043e Code Calls/jump count: 1 Data use count: 0}}
        rlca                      ;{{043E/B998:07}} 
        rlca                      ;{{043F/B999:07}} 
        xor     c                 ;{{0440/B99A:a9}} 
        and     $0c               ;{{0441/B99B:e60c}} 
        xor     c                 ;{{0443/B99D:a9}} 
        push    bc                ;{{0444/B99E:c5}} 
        call    copied_to_b9b0_in_RAM;{{0445/B99F:cdb0b9}} 
        di                        ;{{0448/B9A2:f3}} 
        exx                       ;{{0449/B9A3:d9}} 
        ex      af,af'            ;{{044A/B9A4:08}} 
        ld      a,c               ;{{044B/B9A5:79}} 
        pop     bc                ;{{044C/B9A6:c1}} 
_rst_1__low_low_jump_24:          ;{{Addr=$044d Code Calls/jump count: 1 Data use count: 0}}
        and     $03               ;{{044D/B9A7:e603}} 
        res     1,c               ;{{044F/B9A9:cb89}} 
        res     0,c               ;{{0451/B9AB:cb81}} 
        or      c                 ;{{0453/B9AD:b1}} 
        jr      _copied_to_b9b0_in_ram_1;{{0454/B9AE:1801}}  (+&01)

;;============================================================================================
;; copied to &b9b0 in RAM

copied_to_b9b0_in_RAM:            ;{{Addr=$0456 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{0456/B9B0:d5}} 
_copied_to_b9b0_in_ram_1:         ;{{Addr=$0457 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{0457/B9B1:4f}} 
        out     (c),c             ;{{0458/B9B2:ed49}} 
        or      a                 ;{{045A/B9B4:b7}} 
        ex      af,af'            ;{{045B/B9B5:08}} 
        exx                       ;{{045C/B9B6:d9}} 
        ei                        ;{{045D/B9B7:fb}} 
        ret                       ;{{045E/B9B8:c9}} 

;;============================================================================================
;; LOW: KL FAR PCHL
LOW_KL_FAR_PCHL:                  ;{{Addr=$045f Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{045F/B9B9:f3}} 
        ex      af,af'            ;{{0460/B9BA:08}} 
        ld      a,c               ;{{0461/B9BB:79}} 
        push    hl                ;{{0462/B9BC:e5}} 
        exx                       ;{{0463/B9BD:d9}} 
        pop     de                ;{{0464/B9BE:d1}} 
        jr      _rst_3__low_far_call_15;{{0465/B9BF:1815}}  (+&15)

;;============================================================================================
;; LOW: KL FAR ICALL
LOW_KL_FAR_ICALL:                 ;{{Addr=$0467 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0467/B9C1:f3}} 
        push    hl                ;{{0468/B9C2:e5}} 
        exx                       ;{{0469/B9C3:d9}} 
        pop     hl                ;{{046A/B9C4:e1}} 
        jr      _rst_3__low_far_call_9;{{046B/B9C5:1809}}  (+&09)

;;============================================================================================
;; RST 3 - LOW: FAR CALL
;;
;; far call limits rom select to 251. So firmware can call functions in ROMs up to 251.
;; If you want to access ROMs above this use KL ROM SELECT.
;;
RST_3__LOW_FAR_CALL:              ;{{Addr=$046d Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{046D/B9C7:f3}} 
        exx                       ;{{046E/B9C8:d9}} 
        pop     hl                ;{{046F/B9C9:e1}} 
        ld      e,(hl)            ;{{0470/B9CA:5e}} 
        inc     hl                ;{{0471/B9CB:23}} 
        ld      d,(hl)            ;{{0472/B9CC:56}} 
        inc     hl                ;{{0473/B9CD:23}} 
        push    hl                ;{{0474/B9CE:e5}} 
        ex      de,hl             ;{{0475/B9CF:eb}} 
_rst_3__low_far_call_9:           ;{{Addr=$0476 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{0476/B9D0:5e}} 
        inc     hl                ;{{0477/B9D1:23}} 
        ld      d,(hl)            ;{{0478/B9D2:56}} 
        inc     hl                ;{{0479/B9D3:23}} 
        ex      af,af'            ;{{047A/B9D4:08}} 
        ld      a,(hl)            ;{{047B/B9D5:7e}} 
;; &fc - no change to rom select, enable upper and lower roms
;; &fd - no change to rom select, enable upper disable lower
;; &fe - no change to rom select, disable upper and enable lower
;; &ff - no change to rom select, disable upper and lower roms
_rst_3__low_far_call_15:          ;{{Addr=$047c Code Calls/jump count: 1 Data use count: 0}}
        cp      $fc               ;{{047C/B9D6:fefc}} 
        jr      nc,_rst_1__low_low_jump_12;{{047E/B9D8:30be}} 

;; allow rom select to change
_rst_3__low_far_call_17:          ;{{Addr=$0480 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$df             ;{{0480/B9DA:06df}}  ROM select I/O port
        out     (c),a             ;{{0482/B9DC:ed79}}  select upper rom

        ld      hl,Upper_ROM_status_;{{0484/B9DE:21d6b8}} 
        ld      b,(hl)            ;{{0487/B9E1:46}} 
        ld      (hl),a            ;{{0488/B9E2:77}} 
        push    bc                ;{{0489/B9E3:c5}} 
        push    iy                ;{{048A/B9E4:fde5}} 

;; rom select below 16 (max for firmware 1.1)?
        cp      $10               ;{{048C/B9E6:fe10}} 
        jr      nc,_rst_3__low_far_call_38;{{048E/B9E8:300f}} 

;; 16-bit table at &b8da
        add     a,a               ;{{0490/B9EA:87}} 
        add     a,$da             ;{{0491/B9EB:c6da}} 
        ld      l,a               ;{{0493/B9ED:6f}} 
        adc     a,$b8             ;{{0494/B9EE:ceb8}} 
        sub     l                 ;{{0496/B9F0:95}} 
        ld      h,a               ;{{0497/B9F1:67}} 

;; get 16-bit value from this address
        ld      a,(hl)            ;{{0498/B9F2:7e}} 
        inc     hl                ;{{0499/B9F3:23}} 
        ld      h,(hl)            ;{{049A/B9F4:66}} 
        ld      l,a               ;{{049B/B9F5:6f}} 
        push    hl                ;{{049C/B9F6:e5}} 
        pop     iy                ;{{049D/B9F7:fde1}} 

_rst_3__low_far_call_38:          ;{{Addr=$049f Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$7f             ;{{049F/B9F9:067f}} 
        ld      a,c               ;{{04A1/B9FB:79}} 
        set     2,a               ;{{04A2/B9FC:cbd7}} 
        res     3,a               ;{{04A4/B9FE:cb9f}} 
        call    copied_to_b9b0_in_RAM;{{04A6/BA00:cdb0b9}} 
        pop     iy                ;{{04A9/BA03:fde1}} 
        di                        ;{{04AB/BA05:f3}} 
        exx                       ;{{04AC/BA06:d9}} 
        ex      af,af'            ;{{04AD/BA07:08}} 
        ld      e,c               ;{{04AE/BA08:59}} 
        pop     bc                ;{{04AF/BA09:c1}} 
        ld      a,b               ;{{04B0/BA0A:78}} 
;; restore rom select
        ld      b,$df             ;{{04B1/BA0B:06df}}  ROM select I/O port
        out     (c),a             ;{{04B3/BA0D:ed79}}  restore upper rom selection

        ld      (Upper_ROM_status_),a;{{04B5/BA0F:32d6b8}} 
        ld      b,$7f             ;{{04B8/BA12:067f}} 
        ld      a,e               ;{{04BA/BA14:7b}} 
        jr      _rst_1__low_low_jump_24;{{04BB/BA15:1890}}  (-&70)

;;============================================================================================
;; LOW: KL SIDE PCHL
LOW_KL_SIDE_PCHL:                 ;{{Addr=$04bd Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04BD/BA17:f3}} 
        push    hl                ;{{04BE/BA18:e5}} 
        exx                       ;{{04BF/BA19:d9}} 
        pop     de                ;{{04C0/BA1A:d1}} 
        jr      _rst_2__low_side_call_8;{{04C1/BA1B:1808}}  (+&08)

;;============================================================================================
;; RST 2 - LOW: SIDE CALL

RST_2__LOW_SIDE_CALL:             ;{{Addr=$04c3 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04C3/BA1D:f3}} 
        exx                       ;{{04C4/BA1E:d9}} 
        pop     hl                ;{{04C5/BA1F:e1}} 
        ld      e,(hl)            ;{{04C6/BA20:5e}} 
        inc     hl                ;{{04C7/BA21:23}} 
        ld      d,(hl)            ;{{04C8/BA22:56}} 
        inc     hl                ;{{04C9/BA23:23}} 
        push    hl                ;{{04CA/BA24:e5}} 
_rst_2__low_side_call_8:          ;{{Addr=$04cb Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{04CB/BA25:08}} 
        ld      a,d               ;{{04CC/BA26:7a}} 
        set     7,d               ;{{04CD/BA27:cbfa}} 
        set     6,d               ;{{04CF/BA29:cbf2}} 
        and     $c0               ;{{04D1/BA2B:e6c0}} 
        rlca                      ;{{04D3/BA2D:07}} 
        rlca                      ;{{04D4/BA2E:07}} 
        ld      hl,foreground_ROM_select_address_;{{04D5/BA2F:21d9b8}} 
        add     a,(hl)            ;{{04D8/BA32:86}} 
        jr      _rst_3__low_far_call_17;{{04D9/BA33:18a5}}  (-&5b)

;;============================================================================================
;; RST 5 - LOW: FIRM JUMP
rst_5__low_firm_jump_B:           ;{{Addr=$04db Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04DB/BA35:f3}} 
        exx                       ;{{04DC/BA36:d9}} 
        pop     hl                ;{{04DD/BA37:e1}} 
        ld      e,(hl)            ;{{04DE/BA38:5e}} 
        inc     hl                ;{{04DF/BA39:23}} 
        ld      d,(hl)            ;{{04E0/BA3A:56}} 
        res     2,c               ;{{04E1/BA3B:cb91}}  enable lower rom
        out     (c),c             ;{{04E3/BA3D:ed49}} 
        ld      ($ba46),de        ;{{04E5/BA3F:ed5346ba}} 
        exx                       ;{{04E9/BA43:d9}} 
        ei                        ;{{04EA/BA44:fb}} 
_rst_5__low_firm_jump_b_11:       ;{{Addr=$04eb Code Calls/jump count: 1 Data use count: 0}}
        call    _rst_5__low_firm_jump_b_11;{{04EB/BA45:cd45ba}} 
        di                        ;{{04EE/BA48:f3}} 
        exx                       ;{{04EF/BA49:d9}} 
        set     2,c               ;{{04F0/BA4A:cbd1}}  disable lower rom
        out     (c),c             ;{{04F2/BA4C:ed49}} 
        exx                       ;{{04F4/BA4E:d9}} 
        ei                        ;{{04F5/BA4F:fb}} 
        ret                       ;{{04F6/BA50:c9}} 

;;============================================================================================
;; HI: KL L ROM ENABLE
HI_KL_L_ROM_ENABLE:               ;{{Addr=$04f7 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04F7/BA51:f3}} 
        exx                       ;{{04F8/BA52:d9}} 
        ld      a,c               ;{{04F9/BA53:79}}  current mode/rom state
        res     2,c               ;{{04FA/BA54:cb91}}  enable lower rom
        jr      _hi_kl_u_rom_disable_4;{{04FC/BA56:1813}}  enable/disable rom common code

;;============================================================================================
;; HI: KL L ROM DISABLE
HI_KL_L_ROM_DISABLE:              ;{{Addr=$04fe Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04FE/BA58:f3}} 
        exx                       ;{{04FF/BA59:d9}} 
        ld      a,c               ;{{0500/BA5A:79}}  current mode/rom state
        set     2,c               ;{{0501/BA5B:cbd1}}  disable upper rom
        jr      _hi_kl_u_rom_disable_4;{{0503/BA5D:180c}}  enable/disable rom common code

;;============================================================================================
;; HI: KL U ROM ENABLE
HI_KL_U_ROM_ENABLE:               ;{{Addr=$0505 Code Calls/jump count: 3 Data use count: 0}}
        di                        ;{{0505/BA5F:f3}} 
        exx                       ;{{0506/BA60:d9}} 
        ld      a,c               ;{{0507/BA61:79}}  current mode/rom state
        res     3,c               ;{{0508/BA62:cb99}}  enable upper rom
        jr      _hi_kl_u_rom_disable_4;{{050A/BA64:1805}}  enable/disable rom common code

;;============================================================================================
;; HI: KL U ROM DISABLE
HI_KL_U_ROM_DISABLE:              ;{{Addr=$050c Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{050C/BA66:f3}} 
        exx                       ;{{050D/BA67:d9}} 
        ld      a,c               ;{{050E/BA68:79}}  current mode/rom state
        set     3,c               ;{{050F/BA69:cbd9}}  disable upper rom

;;--------------------------------------------------------------------------------------------
;; enable/disable rom common code
_hi_kl_u_rom_disable_4:           ;{{Addr=$0511 Code Calls/jump count: 4 Data use count: 0}}
        out     (c),c             ;{{0511/BA6B:ed49}} 
        exx                       ;{{0513/BA6D:d9}} 
        ei                        ;{{0514/BA6E:fb}} 
        ret                       ;{{0515/BA6F:c9}} 

;;============================================================================================
;; HI: KL L ROM RESTORE
HI_KL_L_ROM_RESTORE:              ;{{Addr=$0516 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0516/BA70:f3}} 
        exx                       ;{{0517/BA71:d9}} 
        xor     c                 ;{{0518/BA72:a9}} 
        and     $0c               ;{{0519/BA73:e60c}}  %1100
        xor     c                 ;{{051B/BA75:a9}} 
        ld      c,a               ;{{051C/BA76:4f}} 
        jr      _hi_kl_u_rom_disable_4;{{051D/BA77:18f2}}  enable/disable rom common code

;;============================================================================================
;; HI: KL ROM SELECT
;; Any value can be used from 0-255.

HI_KL_ROM_SELECT:                 ;{{Addr=$051f Code Calls/jump count: 4 Data use count: 0}}
        call    HI_KL_U_ROM_ENABLE;{{051F/BA79:cd5fba}} ; HI: KL U ROM ENABLE
        jr      _hi_kl_rom_deselect_4;{{0522/BA7C:180f}} ; common upper rom selection code      

;;============================================================================================
;; HI: KL PROBE ROM
HI_KL_PROBE_ROM:                  ;{{Addr=$0524 Code Calls/jump count: 2 Data use count: 0}}
        call    HI_KL_ROM_SELECT  ;{{0524/BA7E:cd79ba}} ; HI: KL ROM SELECT

;; read rom version etc
        ld      a,($c000)         ;{{0527/BA81:3a00c0}} 
        ld      hl,($c001)        ;{{052A/BA84:2a01c0}} 
;; drop through to HI: KL ROM DESELECT
;;============================================================================================
;; HI: KL ROM DESELECT
HI_KL_ROM_DESELECT:               ;{{Addr=$052d Code Calls/jump count: 3 Data use count: 0}}
        push    af                ;{{052D/BA87:f5}} 
        ld      a,b               ;{{052E/BA88:78}} 
        call    HI_KL_L_ROM_RESTORE;{{052F/BA89:cd70ba}} ; HI: KL L ROM RESTORE
        pop     af                ;{{0532/BA8C:f1}} 

;;--------------------------------------------------------------------------------------------
;; common upper rom selection code
_hi_kl_rom_deselect_4:            ;{{Addr=$0533 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0533/BA8D:e5}} 
        di                        ;{{0534/BA8E:f3}} 
        ld      b,$df             ;{{0535/BA8F:06df}} ; ROM select I/O port
        out     (c),c             ;{{0537/BA91:ed49}} ; select upper rom
        ld      hl,Upper_ROM_status_;{{0539/BA93:21d6b8}} ; previous upper rom selection
        ld      b,(hl)            ;{{053C/BA96:46}} ; get previous upper rom selection
        ld      (hl),c            ;{{053D/BA97:71}} ; store new rom selection
        ld      c,b               ;{{053E/BA98:48}} ; C = previous rom select
        ld      b,a               ;{{053F/BA99:47}} ; B = previous rom state
        ei                        ;{{0540/BA9A:fb}} 
        pop     hl                ;{{0541/BA9B:e1}} 
        ret                       ;{{0542/BA9C:c9}} 

;;============================================================================================
;; HI: KL CURR SELECTION
HI_KL_CURR_SELECTION:             ;{{Addr=$0543 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(Upper_ROM_status_);{{0543/BA9D:3ad6b8}} 
        ret                       ;{{0546/BAA0:c9}} 

;;============================================================================================
;; HI: KL LDIR
HI_KL_LDIR:                       ;{{Addr=$0547 Code Calls/jump count: 5 Data use count: 0}}
        call    used_by_HI_KL_LDIR_and_HI_KL_LDDR;{{0547/BAA1:cdadba}} ; disable upper/lower rom.. execute code below and then restore rom state

;; called via &baad
        ldir                      ;{{054A/BAA4:edb0}} 
;; returns back to code after call in &baad   
        ret                       ;{{054C/BAA6:c9}} 

;;============================================================================================
;; HI: KL LDDR
HI_KL_LDDR:                       ;{{Addr=$054d Code Calls/jump count: 2 Data use count: 0}}
        call    used_by_HI_KL_LDIR_and_HI_KL_LDDR;{{054D/BAA7:cdadba}} ; disable upper/lower rom.. execute code below and then restore rom state

;; called via &baad
        lddr                      ;{{0550/BAAA:edb8}} 
;; returns back to code after call in &baad   
        ret                       ;{{0552/BAAC:c9}} 
;;============================================================================================
;; used by HI: KL LDIR and HI: KL LDDR
;; copied to &baad in RAM
;;
;; - disables upper and lower rom
;; - continues execution from function that called it allowing it to return back
;; - restores upper and lower rom state

used_by_HI_KL_LDIR_and_HI_KL_LDDR:;{{Addr=$0553 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0553/BAAD:f3}} 
        exx                       ;{{0554/BAAE:d9}} 
        pop     hl                ;{{0555/BAAF:e1}}  return address
        push    bc                ;{{0556/BAB0:c5}}  store rom state
        set     2,c               ;{{0557/BAB1:cbd1}}  disable lower rom
        set     3,c               ;{{0559/BAB3:cbd9}}  disable upper rom
        out     (c),c             ;{{055B/BAB5:ed49}}  set rom state

;; jump to function on the stack, allow it to return back here
        call    copied_to_bac2_into_RAM;{{055D/BAB7:cdc2ba}}  jump to function in HL


        di                        ;{{0560/BABA:f3}} 
        exx                       ;{{0561/BABB:d9}} 
        pop     bc                ;{{0562/BABC:c1}}  get previous rom state
        out     (c),c             ;{{0563/BABD:ed49}}  restore previous rom state
        exx                       ;{{0565/BABF:d9}} 
        ei                        ;{{0566/BAC0:fb}} 
        ret                       ;{{0567/BAC1:c9}} 

;;============================================================================================
;; copied to &bac2 into RAM
copied_to_bac2_into_RAM:          ;{{Addr=$0568 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0568/BAC2:e5}} 
        exx                       ;{{0569/BAC3:d9}} 
        ei                        ;{{056A/BAC4:fb}} 
        ret                       ;{{056B/BAC5:c9}} 

;;============================================================================================
;; RST 4 - LOW: RAM LAM
;; HL = address to read
RST_4__LOW_RAM_LAM:               ;{{Addr=$056c Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{056C/BAC6:f3}} 
        exx                       ;{{056D/BAC7:d9}} 
        ld      e,c               ;{{056E/BAC8:59}} ; E = current rom configuration
        set     2,e               ;{{056F/BAC9:cbd3}} ; disable lower rom
        set     3,e               ;{{0571/BACB:cbdb}} ; disable upper rom
        out     (c),e             ;{{0573/BACD:ed59}} ; set rom configuration
        exx                       ;{{0575/BACF:d9}} 
        ld      a,(hl)            ;{{0576/BAD0:7e}} ; read byte from RAM
        exx                       ;{{0577/BAD1:d9}} 
        out     (c),c             ;{{0578/BAD2:ed49}} ; restore rom configuration
        exx                       ;{{057A/BAD4:d9}} 
        ei                        ;{{057B/BAD5:fb}} 
        ret                       ;{{057C/BAD6:c9}} 

;;============================================================================================
;; read byte from address pointed to IX with roms disabled
;;
;; (used by cassette functions to read/write to RAM)
;;
;; IX = address of byte to read
;; C' = current rom selection and mode

read_byte_from_address_pointed_to_IX_with_roms_disabled:;{{Addr=$057d Code Calls/jump count: 2 Data use count: 0}}
        exx                       ;{{057D/BAD7:d9}} ; switch to alternative register set

        ld      a,c               ;{{057E/BAD8:79}} ; get rom configuration
        or      $0c               ;{{057F/BAD9:f60c}} ; %00001100 (disable upper and lower rom)
        out     (c),a             ;{{0581/BADB:ed79}} ; set the new rom configuration

        ld      a,(ix+$00)        ;{{0583/BADD:dd7e00}} ; read byte from RAM

        out     (c),c             ;{{0586/BAE0:ed49}} ; restore original rom configuration
        exx                       ;{{0588/BAE2:d9}} ; switch back from alternative register set
        ret                       ;{{0589/BAE3:c9}} 

;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<END OF DATA COPIED TO HI JUMPBLOCK
;;==============================================================

org $

;;Padding?

        ld      h,$c7             ;{{058A:26c7}} 
        rst     $00               ;{{058C:c7}} 
        rst     $00               ;{{058D:c7}} 
        rst     $00               ;{{058E:c7}} 
        rst     $00               ;{{058F:c7}} 
        rst     $00               ;{{0590:c7}} 




