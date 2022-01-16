;;===================================================================
;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>START OF DATA COPIED TO HI JUMPBLOCK
START_OF_DATA_COPIED_TO_HI_JUMPBLOCK:;{{Addr=$03a6 Code Calls/jump count: 0 Data use count: 1}}
                                  
org $b900,$

;;+HIGH KERNEL JUMPBLOCK
        jp      HI_KL_U_ROM_ENABLE;{{b900/16e5a:c35fba}} ; HI: KL U ROM ENABLE
        jp      HI_KL_U_ROM_DISABLE;{{03a9/b903:c366ba}} ; HI: KL U ROM DISABLE
        jp      HI_KL_L_ROM_ENABLE;{{03ac/b906:c351ba}} ; HI: KL L ROM ENABLE
        jp      HI_KL_L_ROM_DISABLE;{{03af/b909:c358ba}} ; HI: KL L ROM DISABLE
        jp      HI_KL_L_ROM_RESTORE;{{03b2/b90c:c370ba}} ; HI: KL L ROM RESTORE
        jp      HI_KL_ROM_SELECT  ;{{03b5/b90f:c379ba}} ; HI: KL ROM SELECT
        jp      HI_KL_CURR_SELECTION;{{03b8/b912:c39dba}} ; HI: KL CURR SELECTION
        jp      HI_KL_PROBE_ROM   ;{{03bb/b915:c37eba}} ; HI: KL PROBE ROM
        jp      HI_KL_ROM_DESELECT;{{03be/b918:c387ba}} ; HI: KL ROM DESELECT
        jp      HI_KL_LDIR        ;{{03c1/b91b:c3a1ba}} ; HI: KL LDIR
        jp      HI_KL_LDDR        ;{{03c4/b91e:c3a7ba}} ; HI: KL LDDR

;;============================================================
;; HI: KL POLL SYNCRONOUS
;!!!This is a published address and must not be changed: (03c7)/b921!!!
        ld      a,(High_byte_of_above_Address_of_the_first);{{03c7/b921:3ac1b8}} ; HI: KL POLL SYNCRONOUS
        or      a                 ;{{03ca/b924:b7}} 
        ret     z                 ;{{03cb/b925:c8}} 

        push    hl                ;{{03cc/b926:e5}} 
        di                        ;{{03cd/b927:f3}} 
        jr      do_kl_poll_syncronous;{{03ce/b928:1806}}  (+&06)

;;============================================================
;; HI: KL SCAN NEEDED
;!!!This is a published address and must not be changed: (03d0)/b92a!!!
        ld      hl,Keyboard_scan_flag_;{{03d0/b92a:21bfb8}} ; HI: KL SCAN NEEDED
        ld      (hl),$01          ;{{03d3/b92d:3601}} 
        ret                       ;{{03d5/b92f:c9}} 

;;======
;;do kl poll syncronous
do_kl_poll_syncronous:            ;{{Addr=$03d6 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_the_first_event_block_in_chai);{{03d6/b930:2ac0b8}}  synchronous event list
        ld      a,h               ;{{03d9/b933:7c}} 
        or      a                 ;{{03da/b934:b7}} 
        jr      z,_do_kl_poll_syncronous_9;{{03db/b935:2807}}  (+&07)
        inc     hl                ;{{03dd/b937:23}} 
        inc     hl                ;{{03de/b938:23}} 
        inc     hl                ;{{03df/b939:23}} 
        ld      a,(RAM_b8c2)      ;{{03e0/b93a:3ac2b8}} 
        cp      (hl)              ;{{03e3/b93d:be}} 
_do_kl_poll_syncronous_9:         ;{{Addr=$03e4 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{03e4/b93e:e1}} 
        ei                        ;{{03e5/b93f:fb}} 
        ret                       ;{{03e6/b940:c9}} 

;;============================================================================================
;; RST 7 - LOW: INTERRUPT ENTRY handler

RST_7__LOW_INTERRUPT_ENTRY_handler:;{{Addr=$03e7 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{03e7/b941:f3}} 
        ex      af,af'            ;{{03e8/b942:08}} 
        jr      c,_rst_7__low_interrupt_entry_handler_38;{{03e9/b943:3833}}  detect external interrupt
        exx                       ;{{03eb/b945:d9}} 
        ld      a,c               ;{{03ec/b946:79}} 
        scf                       ;{{03ed/b947:37}} 
        ei                        ;{{03ee/b948:fb}} 
        ex      af,af'            ;{{03ef/b949:08}}  allow interrupt function to be re-entered. This will happen if there is an external interrupt
                                  ; source that continues to assert INT. Internal raster interrupts are acknowledged automatically and cleared.
        di                        ;{{03f0/b94a:f3}} 
        push    af                ;{{03f1/b94b:f5}} 
        res     2,c               ;{{03f2/b94c:cb91}}  ensure lower rom is active in range &0000-&3fff
        out     (c),c             ;{{03f4/b94e:ed49}} 
        call    update_TIME       ;{{03f6/b950:cdb100}}  update time, execute FRAME FLY, FAST TICKER and SOUND events
                                  ; also scan keyboard
_rst_7__low_interrupt_entry_handler_13:;{{Addr=$03f9 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{03f9/b953:b7}} 
        ex      af,af'            ;{{03fa/b954:08}} 
        ld      c,a               ;{{03fb/b955:4f}} 
        ld      b,$7f             ;{{03fc/b956:067f}} 

        ld      a,(RAM_b831)      ;{{03fe/b958:3a31b8}} 
        or      a                 ;{{0401/b95b:b7}} 
        jr      z,_rst_7__low_interrupt_entry_handler_33;{{0402/b95c:2814}}  quit...
        jp      m,_rst_7__low_interrupt_entry_handler_33;{{0404/b95e:fa72b9}}  quit... (same as 0418, but in RAM)

        ld      a,c               ;{{0407/b961:79}} 
        and     $0c               ;{{0408/b962:e60c}}  %00001100
        push    af                ;{{040a/b964:f5}} 
        res     2,c               ;{{040b/b965:cb91}}  ensure lower rom is active in range &0000-&3fff
        exx                       ;{{040d/b967:d9}} 
        call    _queue_asynchronous_events_18;{{040e/b968:cd0a01}} 
        exx                       ;{{0411/b96b:d9}} 
        pop     hl                ;{{0412/b96c:e1}} 
        ld      a,c               ;{{0413/b96d:79}} 
        and     $f3               ;{{0414/b96e:e6f3}}  %11110011
        or      h                 ;{{0416/b970:b4}} 
        ld      c,a               ;{{0417/b971:4f}} 

;;
_rst_7__low_interrupt_entry_handler_33:;{{Addr=$0418 Code Calls/jump count: 2 Data use count: 0}}
        out     (c),c             ;{{0418/b972:ed49}} set rom config/mode etc
        exx                       ;{{041a/b974:d9}} 
        pop     af                ;{{041b/b975:f1}} 
        ei                        ;{{041c/b976:fb}} 
        ret                       ;{{041d/b977:c9}} 

;; handle external interrupt
_rst_7__low_interrupt_entry_handler_38:;{{Addr=$041e Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{041e/b978:08}} 
        pop     hl                ;{{041f/b979:e1}} 
        push    af                ;{{0420/b97a:f5}} 
        set     2,c               ;{{0421/b97b:cbd1}}  disable lower rom 
        out     (c),c             ;{{0423/b97d:ed49}}  set rom config/mode etc
        call    LOW_EXT_INTERRUPT ;{{0425/b97f:cd3b00}}  LOW: EXT INTERRUPT. Patchable by the user
        jr      _rst_7__low_interrupt_entry_handler_13;{{0428/b982:18cf}}  return to interrupt processing.

;;============================================================================================
;; LOW: KL LOW PCHL
LOW_KL_LOW_PCHL:                  ;{{Addr=$042a Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{042a/b984:f3}} 
        push    hl                ;{{042b/b985:e5}}  store HL onto stack
        exx                       ;{{042c/b986:d9}} 
        pop     de                ;{{042d/b987:d1}}  get it back from stack
        jr      low_jp_de         ;{{042e/b988:1806}}  

;;============================================================================================
;; RST 1 - LOW: LOW JUMP

RST_1__LOW_LOW_JUMP:              ;{{Addr=$0430 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{0430/b98a:f3}} 
        exx                       ;{{0431/b98b:d9}} 
        pop     hl                ;{{0432/b98c:e1}}  get return address from stack
        ld      e,(hl)            ;{{0433/b98d:5e}}  DE = address to call
        inc     hl                ;{{0434/b98e:23}} 
        ld      d,(hl)            ;{{0435/b98f:56}} 

;;--------------------------------------------------------------------------------------------
;;= low jp de
low_jp_de:                        ;{{Addr=$0436 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0436/b990:08}} 
        ld      a,d               ;{{0437/b991:7a}} 
        res     7,d               ;{{0438/b992:cbba}} Mask to a lower ROM address
        res     6,d               ;{{043a/b994:cbb2}} 
        rlca                      ;{{043c/b996:07}} rotate ROM code into bits 1,0
        rlca                      ;{{043d/b997:07}} 

;;---------------------------------------------------------------------------------------------
;;= low jp de with rom state in a
low_jp_de_with_rom_state_in_a:    ;{{Addr=$043e Code Calls/jump count: 1 Data use count: 0}}
        rlca                      ;{{043e/b998:07}} rotate ROM code into bits 3,2
        rlca                      ;{{043f/b999:07}} 
        xor     c                 ;{{0440/b99a:a9}} 
        and     $0c               ;{{0441/b99b:e60c}} 
        xor     c                 ;{{0443/b99d:a9}} 
        push    bc                ;{{0444/b99e:c5}} 
        call    set_rom_state_and_cleanup_and_JP_DE;{{0445/b99f:cdb0b9}} ROM select and CALL address in DE

        di                        ;{{0448/b9a2:f3}} Now do cleanup and return to caller
        exx                       ;{{0449/b9a3:d9}} 
        ex      af,af'            ;{{044a/b9a4:08}} 
        ld      a,c               ;{{044b/b9a5:79}} 
        pop     bc                ;{{044c/b9a6:c1}} 

;;=cleanup and return after rom call
cleanup_and_return_after_rom_call:;{{Addr=$044d Code Calls/jump count: 1 Data use count: 0}}
        and     $03               ;{{044d/b9a7:e603}} 
        res     1,c               ;{{044f/b9a9:cb89}} 
        res     0,c               ;{{0451/b9ab:cb81}} 
        or      c                 ;{{0453/b9ad:b1}} 
        jr      set_rom_state_and_cleanup;{{0454/b9ae:1801}}  (+&01)

;;============================================================================================
;; set rom state and cleanup and JP DE
; restores ROM state, registers etc and jumps to address in DE 
; (and then returns to caller)
set_rom_state_and_cleanup_and_JP_DE:;{{Addr=$0456 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{0456/b9b0:d5}} 
;;=set rom state and cleanup
set_rom_state_and_cleanup:        ;{{Addr=$0457 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{0457/b9b1:4f}} 
        out     (c),c             ;{{0458/b9b2:ed49}} 
        or      a                 ;{{045a/b9b4:b7}} 
        ex      af,af'            ;{{045b/b9b5:08}} 
        exx                       ;{{045c/b9b6:d9}} 
        ei                        ;{{045d/b9b7:fb}} 
        ret                       ;{{045e/b9b8:c9}} 

;;============================================================================================
;; LOW: KL FAR PCHL
; call to address in HL, ROM select in C
LOW_KL_FAR_PCHL:                  ;{{Addr=$045f Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{045f/b9b9:f3}} 
        ex      af,af'            ;{{0460/b9ba:08}} 
        ld      a,c               ;{{0461/b9bb:79}} 
        push    hl                ;{{0462/b9bc:e5}} 
        exx                       ;{{0463/b9bd:d9}} 
        pop     de                ;{{0464/b9be:d1}} 
        jr      do_far_call_to_de_a;{{0465/b9bf:1815}}  (+&15)

;;============================================================================================
;; LOW: KL FAR ICALL
; call to 3-byte indirect address. HL=pointer to address data (address, rom select)
LOW_KL_FAR_ICALL:                 ;{{Addr=$0467 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0467/b9c1:f3}} 
        push    hl                ;{{0468/b9c2:e5}} 
        exx                       ;{{0469/b9c3:d9}} 
        pop     hl                ;{{046a/b9c4:e1}} 
        jr      do_indirect_far_call_to_athl;{{046b/b9c5:1809}}  (+&09)

;;============================================================================================
;; RST 3 - LOW: FAR CALL
;; call to 3-byte inline address (address, rom select)
;;
;; far call limits rom select to 251. So firmware can call functions in ROMs up to 251.
;; If you want to access ROMs above this use KL ROM SELECT.
;;
RST_3__LOW_FAR_CALL:              ;{{Addr=$046d Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{046d/b9c7:f3}} 
        exx                       ;{{046e/b9c8:d9}} 
        pop     hl                ;{{046f/b9c9:e1}} Get return address
        ld      e,(hl)            ;{{0470/b9ca:5e}} DE=address of far pointer
        inc     hl                ;{{0471/b9cb:23}} 
        ld      d,(hl)            ;{{0472/b9cc:56}} 
        inc     hl                ;{{0473/b9cd:23}} 
        push    hl                ;{{0474/b9ce:e5}} Restore new return address
        ex      de,hl             ;{{0475/b9cf:eb}} HL=address to far pointer

;;= do indirect far call to athl
do_indirect_far_call_to_athl:     ;{{Addr=$0476 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{0476/b9d0:5e}} DE=address to call
        inc     hl                ;{{0477/b9d1:23}} 
        ld      d,(hl)            ;{{0478/b9d2:56}} 
        inc     hl                ;{{0479/b9d3:23}} 
        ex      af,af'            ;{{047a/b9d4:08}} 
        ld      a,(hl)            ;{{047b/b9d5:7e}} ROM select state

;;= do far call to de a
;; &fc - no change to rom select, enable upper and lower roms
;; &fd - no change to rom select, enable upper disable lower
;; &fe - no change to rom select, disable upper and enable lower
;; &ff - no change to rom select, disable upper and lower roms
do_far_call_to_de_a:              ;{{Addr=$047c Code Calls/jump count: 1 Data use count: 0}}
        cp      $fc               ;{{047c/b9d6:fefc}} 
        jr      nc,low_jp_de_with_rom_state_in_a;{{047e/b9d8:30be}} 

;; allow rom select to change
_do_far_call_to_de_a_2:           ;{{Addr=$0480 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$df             ;{{0480/b9da:06df}}  ROM select I/O port
        out     (c),a             ;{{0482/b9dc:ed79}}  select upper rom

        ld      hl,Upper_ROM_status_;{{0484/b9de:21d6b8}} 
        ld      b,(hl)            ;{{0487/b9e1:46}} 
        ld      (hl),a            ;{{0488/b9e2:77}} 
        push    bc                ;{{0489/b9e3:c5}} 
        push    iy                ;{{048a/b9e4:fde5}} 

;; rom select below 16 (max for firmware 1.1)?
        cp      $10               ;{{048c/b9e6:fe10}} 
        jr      nc,dispatch_far_call_de_a;{{048e/b9e8:300f}} 

;Get pointer to the ROMs data area (in IY)
;; 16-bit table at &b8da
        add     a,a               ;{{0490/b9ea:87}} 
        add     a,Background_ROM_data_address_table and $ff;{{0491/b9eb:c6da}} 
        ld      l,a               ;{{0493/b9ed:6f}} 
        adc     a,Background_ROM_data_address_table >> 8;{{0494/b9ee:ceb8}} 
        sub     l                 ;{{0496/b9f0:95}} 
        ld      h,a               ;{{0497/b9f1:67}} 

;; get 16-bit value from this address
        ld      a,(hl)            ;{{0498/b9f2:7e}} 
        inc     hl                ;{{0499/b9f3:23}} 
        ld      h,(hl)            ;{{049a/b9f4:66}} 
        ld      l,a               ;{{049b/b9f5:6f}} 
        push    hl                ;{{049c/b9f6:e5}} 
        pop     iy                ;{{049d/b9f7:fde1}} 

;;=dispatch far call de a
dispatch_far_call_de_a:           ;{{Addr=$049f Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$7f             ;{{049f/b9f9:067f}} 
        ld      a,c               ;{{04a1/b9fb:79}} 
        set     2,a               ;{{04a2/b9fc:cbd7}} 
        res     3,a               ;{{04a4/b9fe:cb9f}} 
        call    set_rom_state_and_cleanup_and_JP_DE;{{04a6/ba00:cdb0b9}} 
        pop     iy                ;{{04a9/ba03:fde1}} 
        di                        ;{{04ab/ba05:f3}} 
        exx                       ;{{04ac/ba06:d9}} 
        ex      af,af'            ;{{04ad/ba07:08}} 
        ld      e,c               ;{{04ae/ba08:59}} 
        pop     bc                ;{{04af/ba09:c1}} 
        ld      a,b               ;{{04b0/ba0a:78}} 
;; restore rom select
        ld      b,$df             ;{{04b1/ba0b:06df}}  ROM select I/O port
        out     (c),a             ;{{04b3/ba0d:ed79}}  restore upper rom selection

        ld      (Upper_ROM_status_),a;{{04b5/ba0f:32d6b8}} 
        ld      b,$7f             ;{{04b8/ba12:067f}} 
        ld      a,e               ;{{04ba/ba14:7b}} 
        jr      cleanup_and_return_after_rom_call;{{04bb/ba15:1890}}  (-&70)

;;============================================================================================
;; LOW: KL SIDE PCHL
LOW_KL_SIDE_PCHL:                 ;{{Addr=$04bd Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04bd/ba17:f3}} 
        push    hl                ;{{04be/ba18:e5}} 
        exx                       ;{{04bf/ba19:d9}} 
        pop     de                ;{{04c0/ba1a:d1}} 
        jr      do_JP_DE          ;{{04c1/ba1b:1808}}  (+&08)

;;============================================================================================
;; RST 2 - LOW: SIDE CALL

RST_2__LOW_SIDE_CALL:             ;{{Addr=$04c3 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04c3/ba1d:f3}} 
        exx                       ;{{04c4/ba1e:d9}} 
        pop     hl                ;{{04c5/ba1f:e1}} 
        ld      e,(hl)            ;{{04c6/ba20:5e}} 
        inc     hl                ;{{04c7/ba21:23}} 
        ld      d,(hl)            ;{{04c8/ba22:56}} 
        inc     hl                ;{{04c9/ba23:23}} 
        push    hl                ;{{04ca/ba24:e5}} 

;;=do JP DE
do_JP_DE:                         ;{{Addr=$04cb Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{04cb/ba25:08}} 
        ld      a,d               ;{{04cc/ba26:7a}} 
        set     7,d               ;{{04cd/ba27:cbfa}} 
        set     6,d               ;{{04cf/ba29:cbf2}} 
        and     $c0               ;{{04d1/ba2b:e6c0}} 
        rlca                      ;{{04d3/ba2d:07}} 
        rlca                      ;{{04d4/ba2e:07}} 
        ld      hl,foreground_ROM_select_address_;{{04d5/ba2f:21d9b8}} 
        add     a,(hl)            ;{{04d8/ba32:86}} 
        jr      _do_far_call_to_de_a_2;{{04d9/ba33:18a5}}  (-&5b)

;;============================================================================================
;; RST 5 - LOW: FIRM JUMP
rst_5__low_firm_jump_B:           ;{{Addr=$04db Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04db/ba35:f3}} 
        exx                       ;{{04dc/ba36:d9}} 
        pop     hl                ;{{04dd/ba37:e1}} 
        ld      e,(hl)            ;{{04de/ba38:5e}} 
        inc     hl                ;{{04df/ba39:23}} 
        ld      d,(hl)            ;{{04e0/ba3a:56}} 
        res     2,c               ;{{04e1/ba3b:cb91}}  enable lower rom
        out     (c),c             ;{{04e3/ba3d:ed49}} 
        ld      (do_low_firm_jump + 1),de;{{04e5/ba3f:ed5346ba}} Poke the address to call;WARNING: Code area used as literal
        exx                       ;{{04e9/ba43:d9}} 
        ei                        ;{{04ea/ba44:fb}} 
;;+do low firm jump
do_low_firm_jump:                 ;{{Addr=$04eb Code Calls/jump count: 1 Data use count: 1}}
        call    do_low_firm_jump  ;{{04eb/ba45:cd45ba}} Self modified code - address is poked above
        di                        ;{{04ee/ba48:f3}} 
        exx                       ;{{04ef/ba49:d9}} 
        set     2,c               ;{{04f0/ba4a:cbd1}}  disable lower rom
        out     (c),c             ;{{04f2/ba4c:ed49}} 
        exx                       ;{{04f4/ba4e:d9}} 
        ei                        ;{{04f5/ba4f:fb}} 
        ret                       ;{{04f6/ba50:c9}} 

;;============================================================================================
;; HI: KL L ROM ENABLE
HI_KL_L_ROM_ENABLE:               ;{{Addr=$04f7 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04f7/ba51:f3}} 
        exx                       ;{{04f8/ba52:d9}} 
        ld      a,c               ;{{04f9/ba53:79}}  current mode/rom state
        res     2,c               ;{{04fa/ba54:cb91}}  enable lower rom
        jr      enabledisable_rom_common_code;{{04fc/ba56:1813}}  enable/disable rom common code

;;============================================================================================
;; HI: KL L ROM DISABLE
HI_KL_L_ROM_DISABLE:              ;{{Addr=$04fe Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{04fe/ba58:f3}} 
        exx                       ;{{04ff/ba59:d9}} 
        ld      a,c               ;{{0500/ba5a:79}}  current mode/rom state
        set     2,c               ;{{0501/ba5b:cbd1}}  disable upper rom
        jr      enabledisable_rom_common_code;{{0503/ba5d:180c}}  enable/disable rom common code

;;============================================================================================
;; HI: KL U ROM ENABLE
HI_KL_U_ROM_ENABLE:               ;{{Addr=$0505 Code Calls/jump count: 3 Data use count: 0}}
        di                        ;{{0505/ba5f:f3}} 
        exx                       ;{{0506/ba60:d9}} 
        ld      a,c               ;{{0507/ba61:79}}  current mode/rom state
        res     3,c               ;{{0508/ba62:cb99}}  enable upper rom
        jr      enabledisable_rom_common_code;{{050a/ba64:1805}}  enable/disable rom common code

;;============================================================================================
;; HI: KL U ROM DISABLE
HI_KL_U_ROM_DISABLE:              ;{{Addr=$050c Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{050c/ba66:f3}} 
        exx                       ;{{050d/ba67:d9}} 
        ld      a,c               ;{{050e/ba68:79}}  current mode/rom state
        set     3,c               ;{{050f/ba69:cbd9}}  disable upper rom

;;+--------------------------------------------------------------------------------------------
;; enable/disable rom common code
enabledisable_rom_common_code:    ;{{Addr=$0511 Code Calls/jump count: 4 Data use count: 0}}
        out     (c),c             ;{{0511/ba6b:ed49}} 
        exx                       ;{{0513/ba6d:d9}} 
        ei                        ;{{0514/ba6e:fb}} 
        ret                       ;{{0515/ba6f:c9}} 

;;============================================================================================
;; HI: KL L ROM RESTORE
HI_KL_L_ROM_RESTORE:              ;{{Addr=$0516 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0516/ba70:f3}} 
        exx                       ;{{0517/ba71:d9}} 
        xor     c                 ;{{0518/ba72:a9}} 
        and     $0c               ;{{0519/ba73:e60c}}  %1100
        xor     c                 ;{{051b/ba75:a9}} 
        ld      c,a               ;{{051c/ba76:4f}} 
        jr      enabledisable_rom_common_code;{{051d/ba77:18f2}}  enable/disable rom common code

;;============================================================================================
;; HI: KL ROM SELECT
;; Any value can be used from 0-255.

HI_KL_ROM_SELECT:                 ;{{Addr=$051f Code Calls/jump count: 4 Data use count: 0}}
        call    HI_KL_U_ROM_ENABLE;{{051f/ba79:cd5fba}} ; HI: KL U ROM ENABLE
        jr      do_upper_rom_selection;{{0522/ba7c:180f}} ; common upper rom selection code      

;;============================================================================================
;; HI: KL PROBE ROM
HI_KL_PROBE_ROM:                  ;{{Addr=$0524 Code Calls/jump count: 2 Data use count: 0}}
        call    HI_KL_ROM_SELECT  ;{{0524/ba7e:cd79ba}} ; HI: KL ROM SELECT

;; read rom version etc
        ld      a,($c000)         ;{{0527/ba81:3a00c0}} 
        ld      hl,($c001)        ;{{052a/ba84:2a01c0}} 
;; drop through to HI: KL ROM DESELECT
;;============================================================================================
;; HI: KL ROM DESELECT
HI_KL_ROM_DESELECT:               ;{{Addr=$052d Code Calls/jump count: 3 Data use count: 0}}
        push    af                ;{{052d/ba87:f5}} 
        ld      a,b               ;{{052e/ba88:78}} 
        call    HI_KL_L_ROM_RESTORE;{{052f/ba89:cd70ba}} ; HI: KL L ROM RESTORE
        pop     af                ;{{0532/ba8c:f1}} 

;;+--------------------------------------------------------------------------------------------
;; do upper rom selection
; In: C=new ROM select
; Out: C=previous ROM select, B=value of A passed in (previous ROM state)
do_upper_rom_selection:           ;{{Addr=$0533 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0533/ba8d:e5}} 
        di                        ;{{0534/ba8e:f3}} 
        ld      b,$df             ;{{0535/ba8f:06df}} ; ROM select I/O port
        out     (c),c             ;{{0537/ba91:ed49}} ; select upper rom
        ld      hl,Upper_ROM_status_;{{0539/ba93:21d6b8}} ; previous upper rom selection
        ld      b,(hl)            ;{{053c/ba96:46}} ; get previous upper rom selection
        ld      (hl),c            ;{{053d/ba97:71}} ; store new rom selection
        ld      c,b               ;{{053e/ba98:48}} ; C = previous rom select
        ld      b,a               ;{{053f/ba99:47}} ; B = previous rom state
        ei                        ;{{0540/ba9a:fb}} 
        pop     hl                ;{{0541/ba9b:e1}} 
        ret                       ;{{0542/ba9c:c9}} 

;;============================================================================================
;; HI: KL CURR SELECTION
; Get current upper ROM selection
HI_KL_CURR_SELECTION:             ;{{Addr=$0543 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(Upper_ROM_status_);{{0543/ba9d:3ad6b8}} 
        ret                       ;{{0546/baa0:c9}} 

;;============================================================================================
;; HI: KL LDIR
; LDIR with ROMs disabled
HI_KL_LDIR:                       ;{{Addr=$0547 Code Calls/jump count: 5 Data use count: 0}}
        call    do_HI_KL_LDIR_and_HI_KL_LDDR;{{0547/baa1:cdadba}} ; disable upper/lower rom.. execute code below and then restore rom state

;; address of this code is popped from the stack and called by routine below
        ldir                      ;{{054a/baa4:edb0}} 
;; returns back to code after call in &baad   
        ret                       ;{{054c/baa6:c9}} 

;;============================================================================================
;; HI: KL LDDR
; LDDR with ROMs disabled
HI_KL_LDDR:                       ;{{Addr=$054d Code Calls/jump count: 2 Data use count: 0}}
        call    do_HI_KL_LDIR_and_HI_KL_LDDR;{{054d/baa7:cdadba}} ; disable upper/lower rom.. execute code below and then restore rom state

;; address of this code is popped from the stack and called by routine below
        lddr                      ;{{0550/baaa:edb8}} 
;; returns back to code after call in &baad   
        ret                       ;{{0552/baac:c9}} 

;;============================================================================================
;; do HI: KL LDIR and HI: KL LDDR
;; uses return address on stack as address of code to callback
;;
;; - disables upper and lower rom
;; - continues execution from function that called it allowing it to return back
;; - restores upper and lower rom state

do_HI_KL_LDIR_and_HI_KL_LDDR:     ;{{Addr=$0553 Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{0553/baad:f3}} 
        exx                       ;{{0554/baae:d9}} 
        pop     hl                ;{{0555/baaf:e1}}  return address
        push    bc                ;{{0556/bab0:c5}}  store rom state
        set     2,c               ;{{0557/bab1:cbd1}}  disable lower rom
        set     3,c               ;{{0559/bab3:cbd9}}  disable upper rom
        out     (c),c             ;{{055b/bab5:ed49}}  set rom state

;; call (HL): executes subroutine at address in HL
        call    do_LDIR_LDDR_as_callback;{{055d/bab7:cdc2ba}}  jump to function in HL


        di                        ;{{0560/baba:f3}} 
        exx                       ;{{0561/babb:d9}} 
        pop     bc                ;{{0562/babc:c1}}  get previous rom state
        out     (c),c             ;{{0563/babd:ed49}}  restore previous rom state
        exx                       ;{{0565/babf:d9}} 
        ei                        ;{{0566/bac0:fb}} 
        ret                       ;{{0567/bac1:c9}} 

;;============================================================================================
;; do LDIR LDDR as callback
; HL = address to return to (execute)
; (routine called will return to our caller)
do_LDIR_LDDR_as_callback:         ;{{Addr=$0568 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{0568/bac2:e5}} 
        exx                       ;{{0569/bac3:d9}} 
        ei                        ;{{056a/bac4:fb}} 
        ret                       ;{{056b/bac5:c9}} 

;;============================================================================================
;; RST 4 - LOW: RAM LAM
;; LD A,(HL) with ROMs disabled
RST_4__LOW_RAM_LAM:               ;{{Addr=$056c Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{056c/bac6:f3}} 
        exx                       ;{{056d/bac7:d9}} 
        ld      e,c               ;{{056e/bac8:59}} ; E = current rom configuration
        set     2,e               ;{{056f/bac9:cbd3}} ; disable lower rom
        set     3,e               ;{{0571/bacb:cbdb}} ; disable upper rom
        out     (c),e             ;{{0573/bacd:ed59}} ; set rom configuration
        exx                       ;{{0575/bacf:d9}} 
        ld      a,(hl)            ;{{0576/bad0:7e}} ; read byte from RAM
        exx                       ;{{0577/bad1:d9}} 
        out     (c),c             ;{{0578/bad2:ed49}} ; restore rom configuration
        exx                       ;{{057a/bad4:d9}} 
        ei                        ;{{057b/bad5:fb}} 
        ret                       ;{{057c/bad6:c9}} 

;;============================================================================================
;; read byte from address pointed to IX with roms disabled
;; (used by cassette functions to read/write to RAM)
;;
;; IX = address of byte to read
;; C' = current rom selection and mode

read_byte_from_address_pointed_to_IX_with_roms_disabled:;{{Addr=$057d Code Calls/jump count: 2 Data use count: 0}}
        exx                       ;{{057d/bad7:d9}} ; switch to alternative register set

        ld      a,c               ;{{057e/bad8:79}} ; get rom configuration
        or      $0c               ;{{057f/bad9:f60c}} ; %00001100 (disable upper and lower rom)
        out     (c),a             ;{{0581/badb:ed79}} ; set the new rom configuration

        ld      a,(ix+$00)        ;{{0583/badd:dd7e00}} ; read byte from RAM

        out     (c),c             ;{{0586/bae0:ed49}} ; restore original rom configuration
        exx                       ;{{0588/bae2:d9}} ; switch back from alternative register set
        ret                       ;{{0589/bae3:c9}} 

;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<END OF DATA COPIED TO HI JUMPBLOCK
;;==============================================================

org $

;;Padding?

        ld      h,$c7             ;{{058a:26c7}} 
        rst     $00               ;{{058c:c7}} 
        rst     $00               ;{{058d:c7}} 
        rst     $00               ;{{058e:c7}} 
        rst     $00               ;{{058f:c7}} 
        rst     $00               ;{{0590:c7}} 




