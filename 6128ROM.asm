;;***Main.asm
;#dialect=RASM

;'Unassembled'[1] Amstrad CPC6128 Source Code

;[1] 'Unassembled' meaning that this code can be modified and reassembled.
;(As far as I can tell) all links etc have been converted to labels etc in
;such a way that the code can be assembled at a different target address
;and still function correctly (excepting code which must run at a specific
;address).

;Based on the riginal commented disassembly at:
; http://cpctech.cpc-live.com/docs/os.asm

;There are two versions of this file: a single monolithic version and
;one which has been broken out into separate 'includes'. The latter may
;prove better for modification, assembly and re-use. The former for 
;exploration and reverse engineering.

;For more details see: https://github.com/Bread80/CPC6128-Firmware-Source
;and http://Bread80.com


;; KERNEL ROUTINES
;;***LowJumpblock.asm
;;=============================================================================
;; START OF LOW KERNEL JUMPBLOCK AND ROM START
;;
;; firmware register assignments:
;; B' = 0x07f - Gate Array I/O port address (upper 8 bits)
;; C': upper/lower rom enabled state and current mode. Bit 7 = 1, Bit 6 = 0.


;----------------------------------------------------------------
; RST 0 - LOW: RESET ENTRY

org $0000                         ;##LIT##
include "JumpblockHigh.asm"
include "JumpblockIndirections.asm"
include "MemoryFirmware.asm"
        ld      bc,$7f89          ;{{0000:01897f}}  select mode 1, disable upper rom, enable lower rom		
        out     (c),c             ;{{0003:ed49}}  select mode and rom configuration
        jp      STARTUP_entry_point;{{0005:c39105}} 
;;+----------------------------------------------------------------
        jp      RST_1__LOW_LOW_JUMP;{{0008:c38ab9}}  RST 1 - LOW: LOW JUMP
;;+----------------------------------------------------------------
        jp      LOW_KL_LOW_PCHL   ;{{000B:c384b9}}  LOW: KL LOW PCHL
;;+----------------------------------------------------------------
        push    bc                ;{{000E:c5}}  LOW: PCBC INSTRUCTION
        ret                       ;{{000F:c9}} 
;;+----------------------------------------------------------------
        jp      RST_2__LOW_SIDE_CALL;{{0010:c31dba}}  RST 2 - LOW: SIDE CALL
;;+----------------------------------------------------------------
        jp      LOW_KL_SIDE_PCHL  ;{{0013:c317ba}}  LOW: KL SIDE PCHL
;;+----------------------------------------------------------------
;; LOW: PCDE INSTRUCTION
LOW_PCDE_INSTRUCTION:             ;{{Addr=$0016 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{0016:d5}}  LOW: PCDE INSTRUCTION
        ret                       ;{{0017:c9}} 
;;+----------------------------------------------------------------
        jp      RST_3__LOW_FAR_CALL;{{0018:c3c7b9}}  RST 3 - LOW: FAR CALL
;;+----------------------------------------------------------------
        jp      LOW_KL_FAR_PCHL   ;{{001B:c3b9b9}}  LOW: KL FAR PCHL
;;+----------------------------------------------------------------
;; LOW: PCHL INSTRUCTION
LOW_PCHL_INSTRUCTION:             ;{{Addr=$001e Code Calls/jump count: 2 Data use count: 0}}
        jp      (hl)              ;{{001E:e9}}  LOW: PCHL INSTRUCTION
;;+----------------------------------------------------------------
        nop                       ;{{001F:00}} 
;;+----------------------------------------------------------------
        jp      RST_4__LOW_RAM_LAM;{{0020:c3c6ba}}  RST 4 - LOW: RAM LAM
;;+----------------------------------------------------------------
        jp      LOW_KL_FAR_ICALL  ;{{0023:c3c1b9}}  LOW: KL FAR ICALL
;;+----------------------------------------------------------------
        nop                       ;{{0026:00}} 
        nop                       ;{{0027:00}} 
;;+----------------------------------------------------------------
;; RST 5 - LOW: FIRM JUMP
        jp      rst_5__low_firm_jump_B;{{0028:c335ba}}  RST 5 - LOW: FIRM JUMP
        nop                       ;{{002B:00}} 
;;+----------------------------------------------------------------     
;;do rst 6
do_rst_6:                         ;{{Addr=$002c Code Calls/jump count: 1 Data use count: 0}}
        out     (c),c             ;{{002C:ed49}} 
        exx                       ;{{002E:d9}} 
        ei                        ;{{002F:fb}} 
;;+----------------------------------------------------------------
;; RST 6 - LOW: USER RESTART
;This restart is free for the end user to use as they wish.
;If it's called when lower ROM is enabled then we need to disable lower
;ROM and jump back to do_rst_6 above to run the users rst code
RST_6__LOW_USER_RESTART:          ;{{Addr=$0030 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0030:f3}}  RST 6 - LOW: USER RESTART
        exx                       ;{{0031:d9}} 
        ld      hl,$002b          ;{{0032:212b00}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),c            ;{{0035:71}} 
        jr      END_OF_LOW_KERNEL_JUMPBLOCK;{{0036:1808}} Do another couple of instructions before we loop back above       
;;+----------------------------------------------------------------
        jp      RST_7__LOW_INTERRUPT_ENTRY_handler;{{0038:c341b9}}  RST 7 - LOW: INTERRUPT ENTRY
;;+----------------------------------------------------------------
;; LOW: EXT INTERRUPT
;; This is the default handler in the ROM. The user can patch the RAM version of this
;; handler.
LOW_EXT_INTERRUPT:                ;{{Addr=$003b Code Calls/jump count: 1 Data use count: 0}}
        ret                       ;{{003B:c9}}  LOW: EXT INTERRUPT
        nop                       ;{{003C:00}} 
        nop                       ;{{003D:00}} 
        nop                       ;{{003E:00}} 
        nop                       ;{{003F:00}} 

;;==================================================================
;; END OF LOW KERNEL JUMPBLOCK
;;----------------------------------------------------------------------------------------

;This is a bit more the of the RST 6 code (see above)
;PS I'm not sure why they didn't put the SET opcode at &002b and jump straight 
;there from &0036. Technical reason or oversight?
END_OF_LOW_KERNEL_JUMPBLOCK:      ;{{Addr=$0040 Code Calls/jump count: 1 Data use count: 2}}
        set     2,c               ;{{0040:cbd1}} 
        jr      do_rst_6          ;{{0042:18e8}}  (-&18)






;;***Kernel.asm
;;==========================================================================
;; Setup KERNEL jumpblocks

;; Setup LOW KERNEL jumpblock

;; Copy RSTs to RAM
Setup_KERNEL_jumpblocks:          ;{{Addr=$0044 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,END_OF_LOW_KERNEL_JUMPBLOCK;{{0044:214000}}  copy first &40 bytes of this rom to &0000 ##LABEL##
                                  ; in RAM, and therefore initialise low kernel jumpblock
_setup_kernel_jumpblocks_1:       ;{{Addr=$0047 Code Calls/jump count: 1 Data use count: 0}}
        dec     l                 ;{{0047:2d}} 
        ld      a,(hl)            ;{{0048:7e}}  get byte from rom
        ld      (hl),a            ;{{0049:77}}  write byte to ram
        jr      nz,_setup_kernel_jumpblocks_1;{{004A:20fb}}  

;; initialise USER RESTART in LOW KERNEL jumpblock
        ld      a,$c7             ;{{004C:3ec7}} 
        ld      (RST_6__LOW_USER_RESTART),a;{{004E:323000}} ;WARNING: Code area used as literal

;; Setup HIGH KERNEL jumpblock

        ld      hl,START_OF_DATA_COPIED_TO_HI_JUMPBLOCK;{{0051:21a603}}  copy high kernel jumpblock ##LABEL## ##NOOFFSET##
        ld      de,KL_U_ROM_ENABLE;{{0054:1100b9}} 
        ld      bc,$01e4          ;{{0057:01e401}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{005A:edb0}} 

;;==========================================================================
;; KL CHOKE OFF

KL_CHOKE_OFF:                     ;{{Addr=$005c Code Calls/jump count: 1 Data use count: 1}}
        di                        ;{{005C:f3}} 
        ld      a,(foreground_ROM_select_address_);{{005D:3ad9b8}} 
        ld      de,(entry_point_of_foreground_ROM_in_use_);{{0060:ed5bd7b8}} 
        ld      b,$cd             ;{{0064:06cd}} 
        ld      hl,RAM_b82d       ;{{0066:212db8}} 
_kl_choke_off_5:                  ;{{Addr=$0069 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0069:3600}} 
        inc     hl                ;{{006B:23}} 
        djnz    _kl_choke_off_5   ;{{006C:10fb}}  (-&05)
        ld      b,a               ;{{006E:47}} 
        ld      c,$ff             ;{{006F:0eff}} 
        xor     c                 ;{{0071:a9}} 
        ret     nz                ;{{0072:c0}} 
        ld      b,a               ;{{0073:47}} 
        ld      e,a               ;{{0074:5f}} 
        ld      d,a               ;{{0075:57}} 
        ret                       ;{{0076:c9}} 

;;==========================================================================
;; Start BASIC or program
;; this is called once the rest of the system is initialised. 
;;
;; HL = address to start or (if zero) &C006 in ROM 0 will be used
;; C = rom select (unless HL is zero)
;;
;; if HL=0, then BASIC is started.

Start_BASIC_or_program:           ;{{Addr=$0077 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{0077:7c}} 
        or      l                 ;{{0078:b5}} 
        ld      a,c               ;{{0079:79}} 
        jr      nz,_start_basic_or_program_6;{{007A:2004}}  HL=0?

;; yes, HL = 0
        ld      a,l               ;{{007C:7d}}  A = 0 (BASIC)
        ld      hl,$c006          ;{{007D:2106c0}}  execution address for BASIC

;; A = rom select 
;; HL = address to start
_start_basic_or_program_6:        ;{{Addr=$0080 Code Calls/jump count: 1 Data use count: 0}}
        ld      (Upper_ROM_status_),a;{{0080:32d6b8}} 
;; initialise three byte far address
        ld      (foreground_ROM_select_address_),a;{{0083:32d9b8}}  rom select byte
        ld      (entry_point_of_foreground_ROM_in_use_),hl;{{0086:22d7b8}}  address

        ld      hl,$abff          ;{{0089:21ffab}} last byte of free memory not used by BASIC.
        ld      de,END_OF_LOW_KERNEL_JUMPBLOCK;{{008C:114000}} start of free memory ##LABEL## 
        ld      bc,Last_byte_of_free_memory;{{008F:01ffb0}} last byte of free memory not used by firmware
        ld      sp,$c000          ;{{0092:3100c0}} 
        rst     $18               ;{{0095:df}}  RST 3 - LOW: FAR CALL
        defw entry_point_of_foreground_ROM_in_use_                
        rst     $00               ;{{0098:c7}}  RST 0 - LOW: RESET ENTRY

;;==========================================================================
;; KL TIME PLEASE

KL_TIME_PLEASE:                   ;{{Addr=$0099 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0099:f3}} 
        ld      de,($b8b6)        ;{{009A:ed5bb6b8}} 
        ld      hl,(TIME_)        ;{{009E:2ab4b8}} 
        ei                        ;{{00A1:fb}} 
        ret                       ;{{00A2:c9}} 

;;==========================================================================
;; KL TIME SET

KL_TIME_SET:                      ;{{Addr=$00a3 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{00A3:f3}} 
        xor     a                 ;{{00A4:af}} 
        ld      (RAM_b8b8),a      ;{{00A5:32b8b8}} 
        ld      ($b8b6),de        ;{{00A8:ed53b6b8}} 
        ld      (TIME_),hl        ;{{00AC:22b4b8}} 
        ei                        ;{{00AF:fb}} 
        ret                       ;{{00B0:c9}} 

;;==========================================================================

;; update TIME
update_TIME:                      ;{{Addr=$00b1 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,TIME_          ;{{00B1:21b4b8}} 
_update_time_1:                   ;{{Addr=$00b4 Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{00B4:34}} 
        inc     hl                ;{{00B5:23}} 
        jr      z,_update_time_1  ;{{00B6:28fc}}  (-&04)

;; test VSYNC state
        ld      b,$f5             ;{{00B8:06f5}} 
        in      a,(c)             ;{{00BA:ed78}} 
        rra                       ;{{00BC:1f}} 
        jr      nc,_update_time_12;{{00BD:3008}} 

;; VSYNC is set
        ld      hl,(RAM_b8b9)     ;{{00BF:2ab9b8}} ; FRAME FLY events
        ld      a,h               ;{{00C2:7c}} 
        or      a                 ;{{00C3:b7}} 
        call    nz,_queue_asynchronous_events_58;{{00C4:c45301}} 

_update_time_12:                  ;{{Addr=$00c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b8bb)     ;{{00C7:2abbb8}} ; FAST TICKER events
        ld      a,h               ;{{00CA:7c}} 
        or      a                 ;{{00CB:b7}} 
        call    nz,_queue_asynchronous_events_58;{{00CC:c45301}} 

        call    process_sound     ;{{00CF:cdd720}} ; process sound

        ld      hl,Keyboard_scan_flag_;{{00D2:21bfb8}} ; keyboard scan interrupt counter
        dec     (hl)              ;{{00D5:35}} 
        ret     nz                ;{{00D6:c0}} 

        ld      (hl),$06          ;{{00D7:3606}} ; reset keyboard scan interrupt counter

        call    KM_SCAN_KEYS      ;{{00D9:cdf4bd}}  IND: KM SCAN KEYS

        ld      hl,(address_of_the_first_ticker_block_in_cha);{{00DC:2abdb8}}  ticker list
        ld      a,h               ;{{00DF:7c}} 
        or      a                 ;{{00E0:b7}} 
        ret     z                 ;{{00E1:c8}} 

        ld      hl,RAM_b831       ;{{00E2:2131b8}}  indicate there are some ticker events to process?
        set     0,(hl)            ;{{00E5:cbc6}} 
        ret                       ;{{00E7:c9}} 

;;========================================================
;; Queue asynchronous events
;; these two are for queuing up normal Asynchronous events to be processed after all others

;; normal event 
Queue_asynchronous_events:        ;{{Addr=$00e8 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{00E8:2b}} 
        ld      (hl),$00          ;{{00E9:3600}} 
        dec     hl                ;{{00EB:2b}} 
;; has list been setup?
        ld      a,(RAM_b82e)      ;{{00EC:3a2eb8}} 
        or      a                 ;{{00EF:b7}} 
        jr      nz,_queue_asynchronous_events_11;{{00F0:200c}}  (+&0c)
;; add to start of list
        ld      (RAM_b82d),hl     ;{{00F2:222db8}} 
        ld      (RAM_b82f),hl     ;{{00F5:222fb8}} 
;; signal normal event list setup
        ld      hl,RAM_b831       ;{{00F8:2131b8}} 
        set     6,(hl)            ;{{00FB:cbf6}} 
        ret                       ;{{00FD:c9}} 

;; add another event to 
_queue_asynchronous_events_11:    ;{{Addr=$00fe Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(RAM_b82f)     ;{{00FE:ed5b2fb8}} 
        ld      (RAM_b82f),hl     ;{{0102:222fb8}} 
        ex      de,hl             ;{{0105:eb}} 
        ld      (hl),e            ;{{0106:73}} 
        inc     hl                ;{{0107:23}} 
        ld      (hl),d            ;{{0108:72}} 
        ret                       ;{{0109:c9}} 

;;---------------------------------------------------
;; Queue synchronous event??
_queue_asynchronous_events_18:    ;{{Addr=$010a Code Calls/jump count: 1 Data use count: 0}}
        ld      (temporary_store_for_stack_pointer_),sp;{{010A:ed7332b8}} 
        ld      sp,TIME_          ;{{010E:31b4b8}} 
        push    hl                ;{{0111:e5}} 
        push    de                ;{{0112:d5}} 
        push    bc                ;{{0113:c5}} 
;; normal event has been setup?
        ld      hl,RAM_b831       ;{{0114:2131b8}} 
        bit     6,(hl)            ;{{0117:cb76}} 
        jr      z,_queue_asynchronous_events_42;{{0119:281e}}  (+&1e)

_queue_asynchronous_events_26:    ;{{Addr=$011b Code Calls/jump count: 1 Data use count: 0}}
        set     7,(hl)            ;{{011B:cbfe}} 
_queue_asynchronous_events_27:    ;{{Addr=$011d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b82d)     ;{{011D:2a2db8}} 
        ld      a,h               ;{{0120:7c}} 
        or      a                 ;{{0121:b7}} 
        jr      z,_queue_asynchronous_events_39;{{0122:280e}}  (+&0e)
        ld      e,(hl)            ;{{0124:5e}} 
        inc     hl                ;{{0125:23}} 
        ld      d,(hl)            ;{{0126:56}} 
        ld      (RAM_b82d),de     ;{{0127:ed532db8}} 
        inc     hl                ;{{012B:23}} 
        call    _kl_event_29      ;{{012C:cd0902}}  execute event function
        di                        ;{{012F:f3}} 
        jr      _queue_asynchronous_events_27;{{0130:18eb}}  (-&15)

;;---------------------------------------------------
_queue_asynchronous_events_39:    ;{{Addr=$0132 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b831       ;{{0132:2131b8}} 
        bit     0,(hl)            ;{{0135:cb46}} 
        jr      z,_queue_asynchronous_events_52;{{0137:2810}}  (+&10)
_queue_asynchronous_events_42:    ;{{Addr=$0139 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0139:3600}} 
        scf                       ;{{013B:37}} 
        ex      af,af'            ;{{013C:08}} 
        call    Execute_ticker    ;{{013D:cd8901}} ; execute ticker
        or      a                 ;{{0140:b7}} 
        ex      af,af'            ;{{0141:08}} 
        ld      hl,RAM_b831       ;{{0142:2131b8}} 
        ld      a,(hl)            ;{{0145:7e}} 
        or      a                 ;{{0146:b7}} 
        jr      nz,_queue_asynchronous_events_26;{{0147:20d2}}  (-&2e)
_queue_asynchronous_events_52:    ;{{Addr=$0149 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0149:3600}} 
        pop     bc                ;{{014B:c1}} 
        pop     de                ;{{014C:d1}} 
        pop     hl                ;{{014D:e1}} 
        ld      sp,(temporary_store_for_stack_pointer_);{{014E:ed7b32b8}} 
        ret                       ;{{0152:c9}} 

;;---------------------------------------------------------------------
;; loop over events
;;
;; HL = address of event list
_queue_asynchronous_events_58:    ;{{Addr=$0153 Code Calls/jump count: 3 Data use count: 0}}
        ld      e,(hl)            ;{{0153:5e}} 
        inc     hl                ;{{0154:23}} 
        ld      a,(hl)            ;{{0155:7e}} 
        inc     hl                ;{{0156:23}} 
        or      a                 ;{{0157:b7}} 
        jp      z,KL_EVENT        ;{{0158:cae201}}  KL EVENT

        ld      d,a               ;{{015B:57}} 
        push    de                ;{{015C:d5}} 
        call    KL_EVENT          ;{{015D:cde201}}  KL EVENT
        pop     hl                ;{{0160:e1}} 
        jr      _queue_asynchronous_events_58;{{0161:18f0}}  (-&10)

;;==========================================================================
;; KL NEW FRAME FLY

KL_NEW_FRAME_FLY:                 ;{{Addr=$0163 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{0163:e5}} 
        inc     hl                ;{{0164:23}} 
        inc     hl                ;{{0165:23}} 
        call    KL_INIT_EVENT     ;{{0166:cdd201}}  KL INIT EVENT
        pop     hl                ;{{0169:e1}} 

;;==========================================================================
;; KL ADD FRAME FLY

KL_ADD_FRAME_FLY:                 ;{{Addr=$016a Code Calls/jump count: 0 Data use count: 1}}
        ld      de,RAM_b8b9       ;{{016A:11b9b8}} 
        jp      add_event_to_an_event_list;{{016D:c37903}} ; add event to list

;;==========================================================================
;; KL DEL FRAME FLY

KL_DEL_FRAME_FLY:                 ;{{Addr=$0170 Code Calls/jump count: 2 Data use count: 1}}
        ld      de,RAM_b8b9       ;{{0170:11b9b8}} 
        jp      delete_event_from_list;{{0173:c38803}}  remove event from list

;;==========================================================================
;; KL NEW FAST TICKER

KL_NEW_FAST_TICKER:               ;{{Addr=$0176 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{0176:e5}} 
        inc     hl                ;{{0177:23}} 
        inc     hl                ;{{0178:23}} 
        call    KL_INIT_EVENT     ;{{0179:cdd201}}  KL INIT EVENT
        pop     hl                ;{{017C:e1}} 

;;==========================================================================
;; KL ADD FAST TICKER

;; HL = address of event block
KL_ADD_FAST_TICKER:               ;{{Addr=$017d Code Calls/jump count: 0 Data use count: 1}}
        ld      de,RAM_b8bb       ;{{017D:11bbb8}} 
        jp      add_event_to_an_event_list;{{0180:c37903}} ; add event to list

;;==========================================================================
;; KL DEL FAST TICKER

;; HL = address of event block
KL_DEL_FAST_TICKER:               ;{{Addr=$0183 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,RAM_b8bb       ;{{0183:11bbb8}} 
        jp      delete_event_from_list;{{0186:c38803}}  remove event from list

;;==========================================================================
;; Execute ticker
Execute_ticker:                   ;{{Addr=$0189 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_the_first_ticker_block_in_cha);{{0189:2abdb8}}  ticker list
_execute_ticker_1:                ;{{Addr=$018c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{018C:7c}} 
        or      a                 ;{{018D:b7}} 
        ret     z                 ;{{018E:c8}} 

        ld      e,(hl)            ;{{018F:5e}} 
        inc     hl                ;{{0190:23}} 
        ld      d,(hl)            ;{{0191:56}} 
        inc     hl                ;{{0192:23}} 
        ld      c,(hl)            ;{{0193:4e}} 
        inc     hl                ;{{0194:23}} 
        ld      b,(hl)            ;{{0195:46}} 
        ld      a,b               ;{{0196:78}} 
        or      c                 ;{{0197:b1}} 
        jr      z,_execute_ticker_33;{{0198:2816}}  (+&16)
        dec     bc                ;{{019A:0b}} 
        ld      a,b               ;{{019B:78}} 
        or      c                 ;{{019C:b1}} 
        jr      nz,_execute_ticker_30;{{019D:200e}}  (+&0e)
        push    de                ;{{019F:d5}} 
        inc     hl                ;{{01A0:23}} 
        inc     hl                ;{{01A1:23}} 
        push    hl                ;{{01A2:e5}} 
        inc     hl                ;{{01A3:23}} 
        call    KL_EVENT          ;{{01A4:cde201}}  KL EVENT
        pop     hl                ;{{01A7:e1}} 
        ld      b,(hl)            ;{{01A8:46}} 
        dec     hl                ;{{01A9:2b}} 
        ld      c,(hl)            ;{{01AA:4e}} 
        dec     hl                ;{{01AB:2b}} 
        pop     de                ;{{01AC:d1}} 
_execute_ticker_30:               ;{{Addr=$01ad Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),b            ;{{01AD:70}} 
        dec     hl                ;{{01AE:2b}} 
        ld      (hl),c            ;{{01AF:71}} 
_execute_ticker_33:               ;{{Addr=$01b0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{01B0:eb}} 
        jr      _execute_ticker_1 ;{{01B1:18d9}}  (-&27)

;;==========================================================================
;; KL ADD TICKER
;; HL = event b lock
;; DE = initial value for counter
;; BC = reset count

KL_ADD_TICKER:                    ;{{Addr=$01b3 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{01B3:e5}} 
        inc     hl                ;{{01B4:23}} 
        inc     hl                ;{{01B5:23}} 
        di                        ;{{01B6:f3}} 
        ld      (hl),e            ;{{01B7:73}} ; initial counter
        inc     hl                ;{{01B8:23}} 
        ld      (hl),d            ;{{01B9:72}} 
        inc     hl                ;{{01BA:23}} 
        ld      (hl),c            ;{{01BB:71}} ; reset count
        inc     hl                ;{{01BC:23}} 
        ld      (hl),b            ;{{01BD:70}} 
        pop     hl                ;{{01BE:e1}} 
        ld      de,address_of_the_first_ticker_block_in_cha;{{01BF:11bdb8}} ; ticker list
        jp      add_event_to_an_event_list;{{01C2:c37903}} ; add event to list

;;==========================================================================
;; KL DEL TICKER

KL_DEL_TICKER:                    ;{{Addr=$01c5 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,address_of_the_first_ticker_block_in_cha;{{01C5:11bdb8}} 
        call    delete_event_from_list;{{01C8:cd8803}}  remove event from list
        ret     nc                ;{{01CB:d0}} 

        ex      de,hl             ;{{01CC:eb}} 
        inc     hl                ;{{01CD:23}} 
        ld      e,(hl)            ;{{01CE:5e}} 
        inc     hl                ;{{01CF:23}} 
        ld      d,(hl)            ;{{01D0:56}} 
        ret                       ;{{01D1:c9}} 

;;==========================================================================
;; KL INIT EVENT

KL_INIT_EVENT:                    ;{{Addr=$01d2 Code Calls/jump count: 4 Data use count: 1}}
        di                        ;{{01D2:f3}} 
        inc     hl                ;{{01D3:23}} 
        inc     hl                ;{{01D4:23}} 
        ld      (hl),$00          ;{{01D5:3600}} ; tick count
        inc     hl                ;{{01D7:23}} 
        ld      (hl),b            ;{{01D8:70}} ; class
        inc     hl                ;{{01D9:23}} 
        ld      (hl),e            ;{{01DA:73}} ; routine
        inc     hl                ;{{01DB:23}} 
        ld      (hl),d            ;{{01DC:72}} 
        inc     hl                ;{{01DD:23}} 
        ld      (hl),c            ;{{01DE:71}} ; rom
        inc     hl                ;{{01DF:23}} 
        ei                        ;{{01E0:fb}} 
        ret                       ;{{01E1:c9}} 

;;==========================================================================
;; KL EVENT
;;
;; perform event
;; DE = address of next in chain
;; HL = address of current event

KL_EVENT:                         ;{{Addr=$01e2 Code Calls/jump count: 7 Data use count: 1}}
        inc     hl                ;{{01E2:23}} 
        inc     hl                ;{{01E3:23}} 
        di                        ;{{01E4:f3}} 
        ld      a,(hl)            ;{{01E5:7e}} ; count
        inc     (hl)              ;{{01E6:34}} 
        jp      m,_kl_event_22    ;{{01E7:fa0102}} ; update count 

        or      a                 ;{{01EA:b7}} 
        jr      nz,_kl_event_23   ;{{01EB:2015}}  (+&15)

        inc     hl                ;{{01ED:23}} 
        ld      a,(hl)            ;{{01EE:7e}}  class
        dec     hl                ;{{01EF:2b}} 
        or      a                 ;{{01F0:b7}} 
        jp      p,Synchronous_Event;{{01F1:f22e02}}  -ve (bit = 1) = Asynchronous, +ve (bit = 0) = synchronous

;; Asynchronous
        ex      af,af'            ;{{01F4:08}} 
        jr      nc,_kl_event_28   ;{{01F5:3011}} 
        ex      af,af'            ;{{01F7:08}} 

        add     a,a               ;{{01F8:87}}  express = -ve (bit = 1), normal = +ve (bit = 0)
        jp      p,Queue_asynchronous_events;{{01F9:f2e800}}  add to normal list

;; Asynchronous Express
        dec     (hl)              ;{{01FC:35}}  indicate it needs processing
        inc     hl                ;{{01FD:23}} 
        inc     hl                ;{{01FE:23}} 
                                  ; HL = routine address
        jr      _kl_do_sync_7     ;{{01FF:1821}}  execute event

;; update count 
_kl_event_22:                     ;{{Addr=$0201 Code Calls/jump count: 1 Data use count: 0}}
        dec     (hl)              ;{{0201:35}} 

;; done processing

_kl_event_23:                     ;{{Addr=$0202 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0202:08}} 
        jr      c,_kl_event_26    ;{{0203:3801}}  (+&01)
        ei                        ;{{0205:fb}} 
_kl_event_26:                     ;{{Addr=$0206 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0206:08}} 
        ret                       ;{{0207:c9}} 

_kl_event_28:                     ;{{Addr=$0208 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0208:08}} 

;;--------------------------
;; execute event func
_kl_event_29:                     ;{{Addr=$0209 Code Calls/jump count: 1 Data use count: 0}}
        ei                        ;{{0209:fb}}  enable ints
        ld      a,(hl)            ;{{020A:7e}} 
        dec     a                 ;{{020B:3d}} 
        ret     m                 ;{{020C:f8}} 

_kl_event_33:                     ;{{Addr=$020d Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{020D:e5}} 
        call    _kl_do_sync_2     ;{{020E:cd1b02}}  part of KL DO SYNC
        pop     hl                ;{{0211:e1}} 
        dec     (hl)              ;{{0212:35}} 
        ret     z                 ;{{0213:c8}} 

        jp      p,_kl_event_33    ;{{0214:f20d02}} 
        inc     (hl)              ;{{0217:34}} 
        ret                       ;{{0218:c9}} 

;;==========================================================================
;; KL DO SYNC

;; HL = event block
;; DE = address of event
KL_DO_SYNC:                       ;{{Addr=$0219 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{0219:23}} 
        inc     hl                ;{{021A:23}} 
_kl_do_sync_2:                    ;{{Addr=$021b Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{021B:23}} 

;; near or far address?
        ld      a,(hl)            ;{{021C:7e}} 
        inc     hl                ;{{021D:23}} 
        rra                       ;{{021E:1f}} 
        jp      nc,LOW_KL_FAR_ICALL;{{021F:d2c1b9}} 	 LOW: KL FAR ICALL

;; event uses near address
;; execute it.
;; note that lower rom is enabled at this point so the function can't sit under the lower rom
_kl_do_sync_7:                    ;{{Addr=$0222 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{0222:5e}} 
        inc     hl                ;{{0223:23}} 
        ld      d,(hl)            ;{{0224:56}} 
        ex      de,hl             ;{{0225:eb}} 
        jp      (hl)              ;{{0226:e9}} 

;;==========================================================================
;; KL SYNC RESET

KL_SYNC_RESET:                    ;{{Addr=$0227 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,$0000          ;{{0227:210000}} ##LIT##;WARNING: Code area used as literal
        ld      (High_byte_of_above_Address_of_the_first),hl;{{022A:22c1b8}} 
        ret                       ;{{022D:c9}} 

;;==========================================================================
;; Synchronous Event
Synchronous_Event:                ;{{Addr=$022e Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{022E:e5}} 
        ld      b,a               ;{{022F:47}} 
        ld      de,buffer_for_last_RSX_or_RSX_command_name_;{{0230:11c3b8}} 
_synchronous_event_3:             ;{{Addr=$0233 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{0233:eb}} 

        dec     hl                ;{{0234:2b}} 
        dec     hl                ;{{0235:2b}} 
        ld      d,(hl)            ;{{0236:56}} 
        dec     hl                ;{{0237:2b}} 
        ld      e,(hl)            ;{{0238:5e}} 
        ld      a,d               ;{{0239:7a}} 
        or      a                 ;{{023A:b7}} 
        jr      z,_synchronous_event_18;{{023B:2807}}  (+&07)

        inc     de                ;{{023D:13}}  count
        inc     de                ;{{023E:13}}  class
        inc     de                ;{{023F:13}} 
        ld      a,(de)            ;{{0240:1a}} 
        cp      b                 ;{{0241:b8}} 
        jr      nc,_synchronous_event_3;{{0242:30ef}}  (-&11)

_synchronous_event_18:            ;{{Addr=$0244 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{0244:d1}} 
        dec     de                ;{{0245:1b}} 
        inc     hl                ;{{0246:23}} 
        ld      a,(hl)            ;{{0247:7e}} 
        ld      (de),a            ;{{0248:12}} 
        dec     de                ;{{0249:1b}} 
        ld      (hl),d            ;{{024A:72}} 
        dec     hl                ;{{024B:2b}} 
        ld      a,(hl)            ;{{024C:7e}} 
        ld      (de),a            ;{{024D:12}} 
        ld      (hl),e            ;{{024E:73}} 
        ex      af,af'            ;{{024F:08}} 
        jr      c,_synchronous_event_32;{{0250:3801}}  (+&01)

        ei                        ;{{0252:fb}} 
_synchronous_event_32:            ;{{Addr=$0253 Code Calls/jump count: 1 Data use count: 0}}
        ex      af,af'            ;{{0253:08}} 
        ret                       ;{{0254:c9}} 

;;==========================================================================
;; KL NEXT SYNC

KL_NEXT_SYNC:                     ;{{Addr=$0255 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0255:f3}} 
        ld      hl,(address_of_the_first_event_block_in_chai);{{0256:2ac0b8}}  synchronous event list
        ld      a,h               ;{{0259:7c}} 
        or      a                 ;{{025A:b7}} 
        jr      z,_kl_next_sync_20;{{025B:2817}}  (+&17)
        push    hl                ;{{025D:e5}} 
        ld      e,(hl)            ;{{025E:5e}} 
        inc     hl                ;{{025F:23}} 
        ld      d,(hl)            ;{{0260:56}} 
        inc     hl                ;{{0261:23}} 
        inc     hl                ;{{0262:23}} 
        ld      a,(RAM_b8c2)      ;{{0263:3ac2b8}} 
        cp      (hl)              ;{{0266:be}} 
        jr      nc,_kl_next_sync_19;{{0267:300a}}  (+&0a)
        push    af                ;{{0269:f5}} 
        ld      a,(hl)            ;{{026A:7e}} 
        ld      (RAM_b8c2),a      ;{{026B:32c2b8}} 
        ld      (address_of_the_first_event_block_in_chai),de;{{026E:ed53c0b8}}  synchronous event list
        pop     af                ;{{0272:f1}} 
_kl_next_sync_19:                 ;{{Addr=$0273 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{0273:e1}} 
_kl_next_sync_20:                 ;{{Addr=$0274 Code Calls/jump count: 1 Data use count: 0}}
        ei                        ;{{0274:fb}} 
        ret                       ;{{0275:c9}} 

;;==========================================================================
;; KL DONE SYNC

KL_DONE_SYNC:                     ;{{Addr=$0276 Code Calls/jump count: 0 Data use count: 1}}
        ld      (RAM_b8c2),a      ;{{0276:32c2b8}} 
        inc     hl                ;{{0279:23}} 
        inc     hl                ;{{027A:23}} 
        dec     (hl)              ;{{027B:35}} 
        ret     z                 ;{{027C:c8}} 

        di                        ;{{027D:f3}} 
        jp      p,Synchronous_Event;{{027E:f22e02}} ; Synchronous event
        inc     (hl)              ;{{0281:34}} 
        ei                        ;{{0282:fb}} 
        ret                       ;{{0283:c9}} 

;;==========================================================================
;; KL DEL SYNCHRONOUS

KL_DEL_SYNCHRONOUS:               ;{{Addr=$0284 Code Calls/jump count: 1 Data use count: 1}}
        call    KL_DISARM_EVENT   ;{{0284:cd8d02}}  KL DISARM EVENT
        ld      de,address_of_the_first_event_block_in_chai;{{0287:11c0b8}}  synchronouse event list
        jp      delete_event_from_list;{{028A:c38803}}  remove event from list

;;==========================================================================
;; KL DISARM EVENT

KL_DISARM_EVENT:                  ;{{Addr=$028d Code Calls/jump count: 1 Data use count: 1}}
        inc     hl                ;{{028D:23}} 
        inc     hl                ;{{028E:23}} 
        ld      (hl),$c0          ;{{028F:36c0}} 
        dec     hl                ;{{0291:2b}} 
        dec     hl                ;{{0292:2b}} 
        ret                       ;{{0293:c9}} 

;;==========================================================================
;; KL EVENT DISABLE

KL_EVENT_DISABLE:                 ;{{Addr=$0294 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,RAM_b8c2       ;{{0294:21c2b8}} 
        set     5,(hl)            ;{{0297:cbee}} 
        ret                       ;{{0299:c9}} 

;;==========================================================================
;; KL EVENT ENABLE

KL_EVENT_ENABLE:                  ;{{Addr=$029a Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,RAM_b8c2       ;{{029A:21c2b8}} 
        res     5,(hl)            ;{{029D:cbae}} 
        ret                       ;{{029F:c9}} 

;;==========================================================================
;; KL LOG EXT
;;
;; BC contains the address of the RSX's command table
;; HL contains the address of four bytes exclusively for use by the firmware 
;; 
;; NOTES: Most recent command is added to the start of the list. The next oldest
;; is next and so on until we get to the command that was registered first and the 
;; end of the list.
;; 
;; HL can't be in the range &0000-&3fff because the OS rom will be active in this range. 
;; Sensible range is &4000-&c000. (&c000-&ffff is normally where upper ROM is located, so it
;; is unwise to locate it here if you want to access the command from BASIC because BASIC
;; will be active in this range)
KL_LOG_EXT:                       ;{{Addr=$02a0 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{02A0:e5}} 
        ld      de,(address_of_first_ROM_or_RSX_chaining_blo);{{02A1:ed5bd3b8}} ; get head of the list
        ld      (address_of_first_ROM_or_RSX_chaining_blo),hl;{{02A5:22d3b8}} ; set new head of the list
        ld      (hl),e            ;{{02A8:73}} ; previous | command registered with KL LOG EXT or 0 if end of list
        inc     hl                ;{{02A9:23}} 
        ld      (hl),d            ;{{02AA:72}} 
        inc     hl                ;{{02AB:23}} 
        ld      (hl),c            ;{{02AC:71}} ; address of RSX's command table
        inc     hl                ;{{02AD:23}} 
        ld      (hl),b            ;{{02AE:70}} 
        pop     hl                ;{{02AF:e1}} 
        ret                       ;{{02B0:c9}} 

;;==========================================================================
;; KL FIND COMMAND
;; HL = address of command name to be found.

;; NOTES: 
;; - last char must have bit 7 set to indicate the end of the string.
;; - up to 16 characters is compared. Name can be any length but first 16 characters must be unique.

KL_FIND_COMMAND:                  ;{{Addr=$02b1 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,buffer_for_last_RSX_or_RSX_command_name_;{{02B1:11c3b8}} ; destination
        ld      bc,$0010          ;{{02B4:011000}} ; length ##LIT##;WARNING: Code area used as literal
        call    HI_KL_LDIR        ;{{02B7:cda1ba}} ; HI: KL LDIR (disable upper and lower roms and perform LDIR)

;; ensure last character has bit 7 set (indicates end of string, where length of name is longer
;; than 16 characters). If name is less than 16 characters the last char will have bit 7 set anyway.
        ex      de,hl             ;{{02BA:eb}} 
        dec     hl                ;{{02BB:2b}} 
        set     7,(hl)            ;{{02BC:cbfe}} 

        ld      hl,(address_of_first_ROM_or_RSX_chaining_blo);{{02BE:2ad3b8}}  points to commands registered with KL LOG EXT
        ld      a,l               ;{{02C1:7d}}  preload lower byte of address into A for comparison
        jr      _kl_find_command_23;{{02C2:1810}} 

;; search for more | commands registered with KL LOG EXT
_kl_find_command_9:               ;{{Addr=$02c4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{02C4:e5}} 
        inc     hl                ;{{02C5:23}}  skip pointer to next registered RSX
        inc     hl                ;{{02C6:23}} 
        ld      c,(hl)            ;{{02C7:4e}}  fetch address of RSX table
        inc     hl                ;{{02C8:23}} 
        ld      b,(hl)            ;{{02C9:46}} 
        call    search_for_RSX_in_commandtable;{{02CA:cdf102}}  search for command
        pop     de                ;{{02CD:d1}} 
        ret     c                 ;{{02CE:d8}} 

        ex      de,hl             ;{{02CF:eb}} 
        ld      a,(hl)            ;{{02D0:7e}}  get address of next registered RSX
        inc     hl                ;{{02D1:23}} 
        ld      h,(hl)            ;{{02D2:66}} 
        ld      l,a               ;{{02D3:6f}} 

_kl_find_command_23:              ;{{Addr=$02d4 Code Calls/jump count: 1 Data use count: 0}}
        or      h                 ;{{02D4:b4}}  if HL is zero, then this is the end of the list.
        jr      nz,_kl_find_command_9;{{02D5:20ed}}  loop if we didn't get to the end of the list


        ld      c,$ff             ;{{02D7:0eff}} 
_kl_find_command_26:              ;{{Addr=$02d9 Code Calls/jump count: 2 Data use count: 0}}
        inc     c                 ;{{02D9:0c}} 
;; C = ROM select address of ROM to probe
        call    HI_KL_PROBE_ROM   ;{{02DA:cd7eba}} ; HI: KL PROBE ROM
;; A = ROM's class.
;; 0 = Foreground
;; 1 = Background
;; 2 = Extension foreground ROM
        push    af                ;{{02DD:f5}} 
        and     $03               ;{{02DE:e603}} 
        ld      b,a               ;{{02E0:47}} 
        call    z,search_for_RSX_in_commandtable;{{02E1:ccf102}}  search for command

        call    c,MC_START_PROGRAM;{{02E4:dc1c06}}  MC START PROGRAM
        pop     af                ;{{02E7:f1}} 
        add     a,a               ;{{02E8:87}} 
        jr      nc,_kl_find_command_26;{{02E9:30ee}}  (-&12)
        ld      a,c               ;{{02EB:79}} 
        cp      $10               ;{{02EC:fe10}}  maximum rom selection scanned by firmware
        jr      c,_kl_find_command_26;{{02EE:38e9}}  (-&17)
        ret                       ;{{02F0:c9}} 

;;========================================================
;; search for RSX in command-table.
;; EIther RSX in RAM or RSX in ROM.

;; HL = address of command-table in ROM
search_for_RSX_in_commandtable:   ;{{Addr=$02f1 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$c004          ;{{02F1:2104c0}} 

;;B=0 for RSX in ROM, B!=0 for RSX in RAM
;; This also means that ROM class must be foreground.
        ld      a,b               ;{{02F4:78}} 
        or      a                 ;{{02F5:b7}} 
        jr      z,_search_for_rsx_in_commandtable_7;{{02F6:2804}} 

;; HL = address of RSX table
        ld      h,b               ;{{02F8:60}} 
        ld      l,c               ;{{02F9:69}} 
;; "ROM select" for RAM 
        ld      c,$ff             ;{{02FA:0eff}} 

;; C = ROM select address
_search_for_rsx_in_commandtable_7:;{{Addr=$02fc Code Calls/jump count: 1 Data use count: 0}}
        call    HI_KL_ROM_SELECT  ;{{02FC:cd79ba}} ; HI: KL ROM SELECT
;; C contains the ROM select address of the previously selected ROM.
;; B contains the previous ROM state
;; preserve previous rom selection and rom state
        push    bc                ;{{02FF:c5}} 

;; get address of strings from table.
        ld      e,(hl)            ;{{0300:5e}} 
        inc     hl                ;{{0301:23}} 
        ld      d,(hl)            ;{{0302:56}} 
        inc     hl                ;{{0303:23}} 
;; DE = jumpblock for RSX commands
        ex      de,hl             ;{{0304:eb}} 
        jr      _search_for_rsx_in_commandtable_32;{{0305:1817}}  (+&17)

;; B8C3 = RSX command to look for stored in RAM
_search_for_rsx_in_commandtable_15:;{{Addr=$0307 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,buffer_for_last_RSX_or_RSX_command_name_;{{0307:01c3b8}} 
_search_for_rsx_in_commandtable_16:;{{Addr=$030a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(bc)            ;{{030A:0a}} 
        cp      (hl)              ;{{030B:be}} 
        jr      nz,_search_for_rsx_in_commandtable_25;{{030C:2008}}  (+&08)
        inc     hl                ;{{030E:23}} 
        inc     bc                ;{{030F:03}} 
        add     a,a               ;{{0310:87}} 
        jr      nc,_search_for_rsx_in_commandtable_16;{{0311:30f7}}  (-&09)
;; if we get to here, then we found the name
        ex      de,hl             ;{{0313:eb}} 
        jr      _search_for_rsx_in_commandtable_35;{{0314:180c}}  (+&0c)

;; char didn't match in name
;; look for end of string, it has bit 7 set
_search_for_rsx_in_commandtable_25:;{{Addr=$0316 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{0316:7e}} 
        inc     hl                ;{{0317:23}} 
;; transfer bit 7 into carry flag
        add     a,a               ;{{0318:87}} 
        jr      nc,_search_for_rsx_in_commandtable_25;{{0319:30fb}}  (-&05)

;; update jumpblock pointer
        inc     de                ;{{031B:13}} 
        inc     de                ;{{031C:13}} 
        inc     de                ;{{031D:13}} 

;; 0 indicates end of list.
_search_for_rsx_in_commandtable_32:;{{Addr=$031e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{031E:7e}} 
        or      a                 ;{{031F:b7}} 
        jr      nz,_search_for_rsx_in_commandtable_15;{{0320:20e5}}  (-&1b)

;; we got to the end of the RSX command-table and we didn't find the command

_search_for_rsx_in_commandtable_35:;{{Addr=$0322 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{0322:c1}} 
;; restore previous rom selection
        jp      HI_KL_ROM_DESELECT;{{0323:c387ba}} ; HI: KL ROM DESELECT

;;==========================================================================
;; KL ROM WALK

KL_ROM_WALK:                      ;{{Addr=$0326 Code Calls/jump count: 0 Data use count: 1}}
        ld      c,$0f             ;{{0326:0e0f}} ; maximum number of roms that firmware supports -1
_kl_rom_walk_1:                   ;{{Addr=$0328 Code Calls/jump count: 1 Data use count: 0}}
        call    KL_INIT_BACK      ;{{0328:cd3003}}  KL INIT BACK
        dec     c                 ;{{032B:0d}} 
        jp      p,_kl_rom_walk_1  ;{{032C:f22803}} 
        ret                       ;{{032F:c9}} 

;;==========================================================================
;; KL INIT BACK

KL_INIT_BACK:                     ;{{Addr=$0330 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(foreground_ROM_select_address_);{{0330:3ad9b8}} 
        cp      c                 ;{{0333:b9}} 
        ret     z                 ;{{0334:c8}} 

        ld      a,c               ;{{0335:79}} 
        cp      $10               ;{{0336:fe10}} ; maximum rom selection supported by firmware
        ret     nc                ;{{0338:d0}} 

        call    HI_KL_ROM_SELECT  ;{{0339:cd79ba}} ; HI: KL ROM SELECT
        ld      a,($c000)         ;{{033C:3a00c0}} 
        and     $03               ;{{033F:e603}} 
        dec     a                 ;{{0341:3d}} 
        jr      nz,_kl_init_back_32;{{0342:2022}}  (+&22)
        push    bc                ;{{0344:c5}} 
        scf                       ;{{0345:37}} 
        call    $c006             ;{{0346:cd06c0}} 
        jr      nc,_kl_init_back_31;{{0349:301a}}  (+&1a)
        push    de                ;{{034B:d5}} 
        inc     hl                ;{{034C:23}} 
        ex      de,hl             ;{{034D:eb}} 
        ld      hl,ROM_entry_IY_value_;{{034E:21dab8}} 
        ld      bc,(Upper_ROM_status_);{{0351:ed4bd6b8}} 
        ld      b,$00             ;{{0355:0600}} 
        add     hl,bc             ;{{0357:09}} 
        add     hl,bc             ;{{0358:09}} 
        ld      (hl),e            ;{{0359:73}} 
        inc     hl                ;{{035A:23}} 
        ld      (hl),d            ;{{035B:72}} 
        ld      hl,$fffc          ;{{035C:21fcff}} 
        add     hl,de             ;{{035F:19}} 
        call    KL_LOG_EXT        ;{{0360:cda002}}  KL LOG EXT
        dec     hl                ;{{0363:2b}} 
        pop     de                ;{{0364:d1}} 
_kl_init_back_31:                 ;{{Addr=$0365 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{0365:c1}} 
_kl_init_back_32:                 ;{{Addr=$0366 Code Calls/jump count: 1 Data use count: 0}}
        jp      HI_KL_ROM_DESELECT;{{0366:c387ba}} ; HI: KL ROM DESELECT

;;====================================================================
;; find event in list

;; DE = address of event block
;; HL = address of event list

find_event_in_list:               ;{{Addr=$0369 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{0369:7e}} 
        cp      e                 ;{{036A:bb}} 
        inc     hl                ;{{036B:23}} 
        ld      a,(hl)            ;{{036C:7e}} 
        dec     hl                ;{{036D:2b}} 
        jr      nz,_find_event_in_list_9;{{036E:2003}}  (+&03)
        cp      d                 ;{{0370:ba}} 
        scf                       ;{{0371:37}} 
        ret     z                 ;{{0372:c8}} 

_find_event_in_list_9:            ;{{Addr=$0373 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{0373:b7}} 
        ret     z                 ;{{0374:c8}} 

        ld      l,(hl)            ;{{0375:6e}} 
        ld      h,a               ;{{0376:67}} 
        jr      find_event_in_list;{{0377:18f0}} ; find event in list            ; (-&10)

;;====================================================================
;; add event to an event list
;; HL = address of event block
;; DE = address of event list
add_event_to_an_event_list:       ;{{Addr=$0379 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{0379:eb}} 
        di                        ;{{037A:f3}} 
        call    find_event_in_list;{{037B:cd6903}} ; find event in list
        jr      c,_add_event_to_an_event_list_10;{{037E:3806}}  event found
;; add to head of list
        ld      (hl),e            ;{{0380:73}} 
        inc     hl                ;{{0381:23}} 
        ld      (hl),d            ;{{0382:72}} 
        inc     de                ;{{0383:13}} 
        xor     a                 ;{{0384:af}} 
        ld      (de),a            ;{{0385:12}} 

_add_event_to_an_event_list_10:   ;{{Addr=$0386 Code Calls/jump count: 1 Data use count: 0}}
        ei                        ;{{0386:fb}} 
        ret                       ;{{0387:c9}} 

;;====================================================================
;; delete event from list
;; HL = address of event block
;; DE = address of event list
delete_event_from_list:           ;{{Addr=$0388 Code Calls/jump count: 4 Data use count: 0}}
        ex      de,hl             ;{{0388:eb}} 
        di                        ;{{0389:f3}} 
        call    find_event_in_list;{{038A:cd6903}} ; find event in list
        jr      nc,_delete_event_from_list_10;{{038D:3006}}  (+&06)
        ld      a,(de)            ;{{038F:1a}} 
        ld      (hl),a            ;{{0390:77}} 
        inc     de                ;{{0391:13}} 
        inc     hl                ;{{0392:23}} 
        ld      a,(de)            ;{{0393:1a}} 
        ld      (hl),a            ;{{0394:77}} 
_delete_event_from_list_10:       ;{{Addr=$0395 Code Calls/jump count: 1 Data use count: 0}}
        ei                        ;{{0395:fb}} 
        ret                       ;{{0396:c9}} 

;;====================================================================
;; KL BANK SWITCH 
;;
;; A = new configuration (0-31)
;;
;; Allows any configuration to be used, so compatible with ALL Dk'Tronics RAM sizes.

KL_BANK_SWITCH_:                  ;{{Addr=$0397 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0397:f3}} 
        exx                       ;{{0398:d9}} 
        ld      hl,RAM_bank_number;{{0399:21d5b8}}  current bank selection
        ld      d,(hl)            ;{{039C:56}}  get previous
        ld      (hl),a            ;{{039D:77}}  set new
        or      $c0               ;{{039E:f6c0}}  bit 7 = 1, bit 6 = 1, selection in lower bits.
        out     (c),a             ;{{03A0:ed79}} 
        ld      a,d               ;{{03A2:7a}}  previous bank selection
        exx                       ;{{03A3:d9}} 
        ei                        ;{{03A4:fb}} 
        ret                       ;{{03A5:c9}} 




;;***HighJumpblock.asm
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




;;***Machine.asm
;; MACHINE PACK ROUTINES
;;==============================================================
;; STARTUP entry point
;; This routine is jumped to by RST 0 after it has set screen mode 1, 
;; upper ROM off, lower ROM on

STARTUP_entry_point:              ;{{Addr=$0591 Code Calls/jump count: 1 Data use count: 0}}
        di                        ;{{0591:f3}} 
        ld      bc,$f782          ;{{0592:0182f7}} 
        out     (c),c             ;{{0595:ed49}} 

        ld      bc,$f400          ;{{0597:0100f4}} ; initialise PPI port A data
        out     (c),c             ;{{059A:ed49}} 

        ld      bc,$f600          ;{{059C:0100f6}} ; initialise PPI port C data 
                                  ;; - select keyboard line 0
                                  ;; - PSG control inactive
                                  ;; - cassette motor off
                                  ;; - cassette write data "0"
        out     (c),c             ;{{059F:ed49}} ; set PPI port C data

        ld      bc,$ef7f          ;{{05A1:017fef}} 
        out     (c),c             ;{{05A4:ed49}} 

        ld      b,$f5             ;{{05A6:06f5}} ; PPI port B inputs
        in      a,(c)             ;{{05A8:ed78}} Bits 4..1 are factory set links for (sales) region
        and     $10               ;{{05AA:e610}} bit4 = 50/60Hz config (60Hz if installed)
        ld      hl,_startup_entry_point_26;{{05AC:21d505}} ; **end** of CRTC data for 50Hz display
        jr      nz,_startup_entry_point_15;{{05AF:2003}} 
        ld      hl,_startup_entry_point_27;{{05B1:21e505}} ; **end** of CRTC data for 60Hz display ##LABEL##

;; initialise display
;; starting with register 15, then down to 0
_startup_entry_point_15:          ;{{Addr=$05b4 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$bc0f          ;{{05B4:010fbc}} 
_startup_entry_point_16:          ;{{Addr=$05b7 Code Calls/jump count: 1 Data use count: 0}}
        out     (c),c             ;{{05B7:ed49}}  select CRTC register
        dec     hl                ;{{05B9:2b}} 
        ld      a,(hl)            ;{{05BA:7e}}  get data from table 
        inc     b                 ;{{05BB:04}} 
        out     (c),a             ;{{05BC:ed79}}  write data to selected CRTC register
        dec     b                 ;{{05BE:05}} 
        dec     c                 ;{{05BF:0d}} 
        jp      p,_startup_entry_point_16;{{05C0:f2b705}} 

;; continue with setup...
        jr      _startup_entry_point_27;{{05C3:1820}}  (+&20)

;; CRTC data for 50Hz display
        defb $3f, $28, $2e, $8e, $26, $00, $19, $1e, $00, $07, $00,$00,$30,$00,$c0,$00
;; CRTC data for 60Hz display
_startup_entry_point_26:          ;{{Addr=$05d5 Data Calls/jump count: 0 Data use count: 1}}
        defb $3f, $28, $2e, $8e, $1f, $06, $19, $1b, $00, $07, $00,$00,$30,$00,$c0,$00

;;-------------------------------------------------------
;; continue with setup...

_startup_entry_point_27:          ;{{Addr=$05e5 Code Calls/jump count: 1 Data use count: 1}}
        ld      de,display_boot_message;{{05E5:117706}}  this is executed by execution address ##LABEL##
        ld      hl,$0000          ;{{05E8:210000}}  this will force MC START PROGRAM to start BASIC ##LIT##;WARNING: Code area used as literal
        jr      _mc_start_program_1;{{05EB:1832}}  mc start program

;;========================================================
;; MC BOOT PROGRAM
;; 
;; HL = execute address

MC_BOOT_PROGRAM:                  ;{{Addr=$05ed Code Calls/jump count: 0 Data use count: 1}}
        ld      sp,$c000          ;{{05ED:3100c0}} 
        push    hl                ;{{05F0:e5}} 
        call    SOUND_RESET       ;{{05F1:cde91f}} ; SOUND RESET
        di                        ;{{05F4:f3}} 

        ld      bc,$f8ff          ;{{05F5:01fff8}} ; reset all peripherals
        out     (c),c             ;{{05F8:ed49}} 

        call    KL_CHOKE_OFF      ;{{05FA:cd5c00}} ; KL CHOKE OFF
        pop     hl                ;{{05FD:e1}} 
        push    de                ;{{05FE:d5}} 
        push    bc                ;{{05FF:c5}} 
        push    hl                ;{{0600:e5}} 
        call    KM_RESET          ;{{0601:cd981b}} ; KM RESET
        call    TXT_RESET         ;{{0604:cd8410}} ; TXT RESET
        call    SCR_RESET         ;{{0607:cdd00a}} ; SCR RESET
        call    HI_KL_U_ROM_ENABLE;{{060A:cd5fba}} ; HI: KL U ROM ENABLE
        pop     hl                ;{{060D:e1}} 
        call    LOW_PCHL_INSTRUCTION;{{060E:cd1e00}} ; LOW: PCHL INSTRUCTION
        pop     bc                ;{{0611:c1}} 
        pop     de                ;{{0612:d1}} 
        jr      c,MC_START_PROGRAM;{{0613:3807}}  MC START PROGRAM


;; display program load failed message
        ex      de,hl             ;{{0615:eb}} 
        ld      c,b               ;{{0616:48}} 
        ld      de,_boot_message_1;{{0617:11f906}}  program load failed ##LABEL##
        jr      _mc_start_program_1;{{061A:1803}}  

;;=========================================================
;; MC START PROGRAM
;; HL = entry address, or zero to start the default ROM
;; DE = address of code to run prior to program to (e.g) display system boot message
;; C = rom select (unless HL==0)

MC_START_PROGRAM:                 ;{{Addr=$061c Code Calls/jump count: 2 Data use count: 1}}
        ld      de,_get_a_pointer_to_the_machine_name_13;{{061C:113707}}  RET (no message) ##LABEL##
                                  ; this is executed by: LOW: PCHL INSTRUCTION

;;---------------------------------------------------------

_mc_start_program_1:              ;{{Addr=$061f Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{061F:f3}}  disable interrupts
        im      1                 ;{{0620:ed56}}  Z80 interrupt mode 1
        exx                       ;{{0622:d9}} 

        ld      bc,$df00          ;{{0623:0100df}}  select upper ROM 0
        out     (c),c             ;{{0626:ed49}} 

        ld      bc,$f8ff          ;{{0628:01fff8}}  reset all peripherals
        out     (c),c             ;{{062B:ed49}} 

        ld      bc,$7fc0          ;{{062D:01c07f}}  select ram configuration 0
        out     (c),c             ;{{0630:ed49}} 

        ld      bc,$fa7e          ;{{0632:017efa}}  stop disc motor
        xor     a                 ;{{0635:af}} 
        out     (c),a             ;{{0636:ed79}} 

        ld      hl,Last_byte_of_free_memory + 1;{{0638:2100b1}}  clear memory block which will hold 
        ld      de,Last_byte_of_free_memory + 2;{{063B:1101b1}}  firmware jumpblock
        ld      bc,$07f9          ;{{063E:01f907}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),a            ;{{0641:77}} 
        ldir                      ;{{0642:edb0}} 

        ld      bc,$7f89          ;{{0644:01897f}}  select mode 1, lower rom on, upper rom off
        out     (c),c             ;{{0647:ed49}} 

        exx                       ;{{0649:d9}} 
        xor     a                 ;{{064A:af}} 
        ex      af,af'            ;{{064B:08}} 
        ld      sp,$c000          ;{{064C:3100c0}} ; initial stack location
        push    hl                ;{{064F:e5}} 
        push    bc                ;{{0650:c5}} 
        push    de                ;{{0651:d5}} 

        call    Setup_KERNEL_jumpblocks;{{0652:cd4400}} ; initialise LOW KERNEL and HIGH KERNEL jumpblocks
        call    JUMP_RESTORE      ;{{0655:cdbd08}} ; JUMP RESTORE
        call    KM_INITIALISE     ;{{0658:cd5c1b}} ; KM INITIALISE
        call    SOUND_RESET       ;{{065B:cde91f}} ; SOUND RESET
        call    SCR_INITIALISE    ;{{065E:cdbf0a}} ; SCR INITIALISE
        call    TXT_INITIALISE    ;{{0661:cd7410}} ; TXT INITIALISE
        call    GRA_INITIALISE    ;{{0664:cda815}} ; GRA INITIALISE
        call    CAS_INITIALISE    ;{{0667:cdbc24}} ; CAS INITIALISE
        call    MC_RESET_PRINTER  ;{{066A:cde007}} ; MC RESET PRINTER
        ei                        ;{{066D:fb}} 
        pop     hl                ;{{066E:e1}} 
        call    LOW_PCHL_INSTRUCTION;{{066F:cd1e00}} ; LOW: PCHL INSTRUCTION
        pop     bc                ;{{0672:c1}} 
        pop     hl                ;{{0673:e1}} 
        jp      Start_BASIC_or_program;{{0674:c37700}} ; start BASIC or program

;;======================================================================
;; display boot message
display_boot_message:             ;{{Addr=$0677 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,$0202          ;{{0677:210202}} ##LIT##;WARNING: Code area used as literal
        call    TXT_SET_CURSOR    ;{{067A:cd7011}}  TXT SET CURSOR

        call    get_a_pointer_to_the_machine_name;{{067D:cd2307}}  get pointer to machine name (based on LK1-LK3 on PCB)

        call    display_a_null_terminated_string;{{0680:cdfc06}}  display message

        ld      hl,boot_message   ;{{0683:218806}}  "128K Microcomputer.." message
        jr      display_a_null_terminated_string;{{0686:1874}}  

;;+------
;; boot message
boot_message:                     ;{{Addr=$0688 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb " 128K Microcomputer  (v3)"
        defb $1f,$02,$04          
        defb "Copyright"          
        defb $1f,$02,$04          
        defb $a4                  ; copyright symbol
        defb "1985 Amstrad Consumer Electronics plc"
        defb $1f,$0c,$05          
        defb "and Locomotive Software Ltd."
        defb $1f,$01,$07          
        defb 0                    

_boot_message_1:                  ;{{Addr=$06f9 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,program_load_failed_message;{{06F9:210507}}  "*** PROGRAM LOAD FAILED ***" message

;;+-----------------------------------------------------------------------
;; display a null terminated string
display_a_null_terminated_string: ;{{Addr=$06fc Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{06FC:7e}}  get message character
        inc     hl                ;{{06FD:23}} 
        or      a                 ;{{06FE:b7}} 
        ret     z                 ;{{06FF:c8}} 

        call    TXT_OUTPUT        ;{{0700:cdfe13}}  TXT OUTPUT
        jr      display_a_null_terminated_string;{{0703:18f7}} 

;;+---------------------------------
;; program load failed message
program_load_failed_message:      ;{{Addr=$0705 Data Calls/jump count: 0 Data use count: 1}}
        defb "*** PROGRAM LOAD FAILED ***",13,10,0

;;=================================================================
;; get a pointer to the machine name
;; HL = machine name
get_a_pointer_to_the_machine_name:;{{Addr=$0723 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f5             ;{{0723:06f5}} ; PPI port B input
        in      a,(c)             ;{{0725:ed78}} 
        cpl                       ;{{0727:2f}} 
        and     $0e               ;{{0728:e60e}} ; isolate LK1-LK3 (defines machine name on startup)
        rrca                      ;{{072A:0f}} 
;; A = machine name number
        ld      hl,startup_name_table;{{072B:213807}}  table of names
        inc     a                 ;{{072E:3c}} 
        ld      b,a               ;{{072F:47}} 

;; B = index of string wanted

;; keep getting bytes until end of string marker (0) is found
;; decrement string count and continue until we have got string
;; wanted
_get_a_pointer_to_the_machine_name_8:;{{Addr=$0730 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{0730:7e}}  get byte
        inc     hl                ;{{0731:23}} 
        or      a                 ;{{0732:b7}}  end of string?
        jr      nz,_get_a_pointer_to_the_machine_name_8;{{0733:20fb}}  

        djnz    _get_a_pointer_to_the_machine_name_8;{{0735:10f9}}  (-&07)
_get_a_pointer_to_the_machine_name_13:;{{Addr=$0737 Code Calls/jump count: 0 Data use count: 1}}
        ret                       ;{{0737:c9}} 

;;+--------------
;; start-up name table
startup_name_table:               ;{{Addr=$0738 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "Arnold",0           ; this name can't be chosen
        defb "Amstrad",0          
        defb "Orion",0            
        defb "Schneider",0        
        defb "Awa",0              
        defb "Solavox",0          
        defb "Saisho",0           
        defb "Triumph",0          
        defb "Isp",0              


;;====================================================================
;; MC SET MODE
;; 
;; A = mode index
;;
;; C' = Gate Array rom and mode configuration register

;; test mode index is in range
MC_SET_MODE:                      ;{{Addr=$0776 Code Calls/jump count: 1 Data use count: 1}}
        cp      $03               ;{{0776:fe03}} 
        ret     nc                ;{{0778:d0}} 

;; mode index is in range: A = 0,1 or 2.

        di                        ;{{0779:f3}} 
        exx                       ;{{077A:d9}} 
        res     1,c               ;{{077B:cb89}} ; clear mode bits (bit 1 and bit 0)
        res     0,c               ;{{077D:cb81}} 

        or      c                 ;{{077F:b1}} ; set mode bits to new mode value
        ld      c,a               ;{{0780:4f}} 
        out     (c),c             ;{{0781:ed49}} ; set mode
        ei                        ;{{0783:fb}} 
        exx                       ;{{0784:d9}} 
        ret                       ;{{0785:c9}} 

;;====================================================================
;; MC CLEAR INKS

MC_CLEAR_INKS:                    ;{{Addr=$0786 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{0786:e5}} 
        ld      hl,$0000          ;{{0787:210000}} ##LIT##;WARNING: Code area used as literal
        jr      _mc_set_inks_2    ;{{078A:1804}} 

;;====================================================================
;; MC SET INKS

MC_SET_INKS:                      ;{{Addr=$078c Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{078C:e5}} 
        ld      hl,$0001          ;{{078D:210100}} ##LIT##;WARNING: Code area used as literal

;;--------------------------------------------------------------------
;; HL = 0 for clear, 1 for set
_mc_set_inks_2:                   ;{{Addr=$0790 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{0790:d5}} 
        push    bc                ;{{0791:c5}} 
        ex      de,hl             ;{{0792:eb}} 

        ld      bc,$7f10          ;{{0793:01107f}}  set border colour
        call    set_colour_for_a_pen;{{0796:cdaa07}}  set colour for PEN/border direct to hardware
        inc     hl                ;{{0799:23}} 
        ld      c,$00             ;{{079A:0e00}} 

_mc_set_inks_9:                   ;{{Addr=$079c Code Calls/jump count: 1 Data use count: 0}}
        call    set_colour_for_a_pen;{{079C:cdaa07}}  set colour for PEN/border direct to hardware
        add     hl,de             ;{{079F:19}} 
        inc     c                 ;{{07A0:0c}} 
        ld      a,c               ;{{07A1:79}} 
        cp      $10               ;{{07A2:fe10}}  maximum number of colours (mode 0 has 16 colours)
        jr      nz,_mc_set_inks_9 ;{{07A4:20f6}}  (-&0a)

        pop     bc                ;{{07A6:c1}} 
        pop     de                ;{{07A7:d1}} 
        pop     hl                ;{{07A8:e1}} 
        ret                       ;{{07A9:c9}} 

;;====================================================================
;; set colour for a pen
;;
;; HL = address of colour for pen
;; C = pen index

set_colour_for_a_pen:             ;{{Addr=$07aa Code Calls/jump count: 2 Data use count: 0}}
        out     (c),c             ;{{07AA:ed49}}  select pen 
        ld      a,(hl)            ;{{07AC:7e}} 
        and     $1f               ;{{07AD:e61f}} 
        or      $40               ;{{07AF:f640}} 
        out     (c),a             ;{{07B1:ed79}}  set colour for pen
        ret                       ;{{07B3:c9}} 


;;====================================================================
;; MC WAIT FLYBACK

MC_WAIT_FLYBACK:                  ;{{Addr=$07b4 Code Calls/jump count: 3 Data use count: 1}}
        push    af                ;{{07B4:f5}} 
        push    bc                ;{{07B5:c5}} 

        ld      b,$f5             ;{{07B6:06f5}}  PPI port B I/O address
_mc_wait_flyback_3:               ;{{Addr=$07b8 Code Calls/jump count: 1 Data use count: 0}}
        in      a,(c)             ;{{07B8:ed78}}  read PPI port B input
        rra                       ;{{07BA:1f}}  transfer bit 0 (VSYNC signal from CRTC) into carry flag
        jr      nc,_mc_wait_flyback_3;{{07BB:30fb}}  wait until VSYNC=1

        pop     bc                ;{{07BD:c1}} 
        pop     af                ;{{07BE:f1}} 
        ret                       ;{{07BF:c9}} 

;;====================================================================
;; MC SCREEN OFFSET
;;
;; HL = offset
;; A = base

MC_SCREEN_OFFSET:                 ;{{Addr=$07c0 Code Calls/jump count: 1 Data use count: 1}}
        push    bc                ;{{07C0:c5}} 
        rrca                      ;{{07C1:0f}} 
        rrca                      ;{{07C2:0f}} 
        and     $30               ;{{07C3:e630}} 
        ld      c,a               ;{{07C5:4f}} 
        ld      a,h               ;{{07C6:7c}} 
        rra                       ;{{07C7:1f}} 
        and     $03               ;{{07C8:e603}} 
        or      c                 ;{{07CA:b1}} 

;; CRTC register 12 and 13 define screen base and offset

        ld      bc,$bc0c          ;{{07CB:010cbc}} 
        out     (c),c             ;{{07CE:ed49}}  select CRTC register 12
        inc     b                 ;{{07D0:04}}  BC = bd0c
        out     (c),a             ;{{07D1:ed79}}  set CRTC register 12 data
        dec     b                 ;{{07D3:05}}  BC = bc0c
        inc     c                 ;{{07D4:0c}}  BC = bc0d
        out     (c),c             ;{{07D5:ed49}}  select CRTC register 13
        inc     b                 ;{{07D7:04}}  BC = bd0d

        ld      a,h               ;{{07D8:7c}} 
        rra                       ;{{07D9:1f}} 
        ld      a,l               ;{{07DA:7d}} 
        rra                       ;{{07DB:1f}} 

        out     (c),a             ;{{07DC:ed79}}  set CRTC register 13 data
        pop     bc                ;{{07DE:c1}} 
        ret                       ;{{07DF:c9}} 


;;====================================================================
;; MC RESET PRINTER

MC_RESET_PRINTER:                 ;{{Addr=$07e0 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,_mc_reset_printer_8;{{07E0:21f707}} ##LABEL##
        ld      de,number_of_entries_in_the_Printer_Transla;{{07E3:1104b8}} 
        ld      bc,$0015          ;{{07E6:011500}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{07E9:edb0}} 

        ld      hl,_mc_reset_printer_6;{{07EB:21f107}} ; table used to initialise printer indirections
        jp      initialise_firmware_indirections;{{07EE:c3b40a}} ; initialise printer indirections

_mc_reset_printer_6:              ;{{Addr=$07f1 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $03                  
        defw MC_WAIT_PRINTER                
        jp      IND_MC_WAIT_PRINTER; IND: MC WAIT PRINTER

_mc_reset_printer_8:              ;{{Addr=$07f7 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $0a,$a0,$5e,$a1,$5c,$a2,$7b,$a3,$23,$a6,$40,$ab,
        defb $7c,$ac,$7d,$ad,$7e,$ae,$5d,$af,$5b

;;===========================================================================
;; MC PRINT TRANSLATION

MC_PRINT_TRANSLATION:             ;{{Addr=$080c Code Calls/jump count: 0 Data use count: 1}}
        rst     $20               ;{{080C:e7}}  RST 4 - LOW: RAM LAM
        add     a,a               ;{{080D:87}} 
        inc     a                 ;{{080E:3c}} 
        ld      c,a               ;{{080F:4f}} 
        ld      b,$00             ;{{0810:0600}} 
        ld      de,number_of_entries_in_the_Printer_Transla;{{0812:1104b8}} 
        cp      $2a               ;{{0815:fe2a}} 
        call    c,HI_KL_LDIR      ;{{0817:dca1ba}} ; HI: KL LDIR
        ret                       ;{{081A:c9}} 

;;===========================================================================
;; MC PRINT CHAR

MC_PRINT_CHAR:                    ;{{Addr=$081b Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{081B:c5}} 
        push    hl                ;{{081C:e5}} 
        ld      hl,number_of_entries_in_the_Printer_Transla;{{081D:2104b8}} 
        ld      b,(hl)            ;{{0820:46}} 
        inc     b                 ;{{0821:04}} 
_mc_print_char_5:                 ;{{Addr=$0822 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{0822:05}} 
        jr      z,_mc_print_char_14;{{0823:280a}}  (+&0a)
        inc     hl                ;{{0825:23}} 
        cp      (hl)              ;{{0826:be}} 
        inc     hl                ;{{0827:23}} 
        jr      nz,_mc_print_char_5;{{0828:20f8}}  (-&08)
        ld      a,(hl)            ;{{082A:7e}} 
        cp      $ff               ;{{082B:feff}} 
        jr      z,_mc_print_char_15;{{082D:2803}}  (+&03)
_mc_print_char_14:                ;{{Addr=$082f Code Calls/jump count: 1 Data use count: 0}}
        call    MC_WAIT_PRINTER   ;{{082F:cdf1bd}}  IND: MC WAIT PRINTER
_mc_print_char_15:                ;{{Addr=$0832 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{0832:e1}} 
        pop     bc                ;{{0833:c1}} 
        ret                       ;{{0834:c9}} 

;;====================================================================
;; IND: MC WAIT PRINTER

IND_MC_WAIT_PRINTER:              ;{{Addr=$0835 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0032          ;{{0835:013200}} ##LIT##;WARNING: Code area used as literal
_ind_mc_wait_printer_1:           ;{{Addr=$0838 Code Calls/jump count: 2 Data use count: 0}}
        call    MC_BUSY_PRINTER   ;{{0838:cd5808}}  MC BUSY PRINTER
        jr      nc,MC_SEND_PRINTER;{{083B:3007}}  MC SEND PRINTER
        djnz    _ind_mc_wait_printer_1;{{083D:10f9}} 
        dec     c                 ;{{083F:0d}} 
        jr      nz,_ind_mc_wait_printer_1;{{0840:20f6}} 
        or      a                 ;{{0842:b7}} 
        ret                       ;{{0843:c9}} 

;;====================================================================
;; MC SEND PRINTER
;; 
;; NOTES: 
;; - bits 6..0 of A contain the data
;; - bit 7 of data is /STROBE signal
;; - /STROBE signal is inverted by hardware; therefore 0->1 and 1->0
;; - data is written with /STROBE pulsed low 
MC_SEND_PRINTER:                  ;{{Addr=$0844 Code Calls/jump count: 1 Data use count: 1}}
        push    bc                ;{{0844:c5}} 
        ld      b,$ef             ;{{0845:06ef}}  printer I/O address
        and     $7f               ;{{0847:e67f}}  clear bit 7 (/STROBE)
        out     (c),a             ;{{0849:ed79}}  write data with /STROBE=1
        or      $80               ;{{084B:f680}}  set bit 7 (/STROBE)
        di                        ;{{084D:f3}} 
        out     (c),a             ;{{084E:ed79}}  write data with /STROBE=0
        and     $7f               ;{{0850:e67f}}  clear bit 7 (/STROBE)
        ei                        ;{{0852:fb}} 
        out     (c),a             ;{{0853:ed79}}  write data with /STROBE=1
        pop     bc                ;{{0855:c1}} 
        scf                       ;{{0856:37}} 
        ret                       ;{{0857:c9}} 

;;====================================================================
;; MC BUSY PRINTER
;; 
;; exit:
;; carry = state of BUSY input from printer

MC_BUSY_PRINTER:                  ;{{Addr=$0858 Code Calls/jump count: 1 Data use count: 1}}
        push    bc                ;{{0858:c5}} 
        ld      c,a               ;{{0859:4f}} 
        ld      b,$f5             ;{{085A:06f5}}  PPI port B I/O address
        in      a,(c)             ;{{085C:ed78}}  read PPI port B input
        rla                       ;{{085E:17}}  transfer bit 6 into carry (BUSY input from printer)						
        rla                       ;{{085F:17}} 
        ld      a,c               ;{{0860:79}} 
        pop     bc                ;{{0861:c1}} 
        ret                       ;{{0862:c9}} 

;;====================================================================
;; MC SOUND REGISTER
;; 
;; entry:
;; A = register index
;; C = register data
;; 

MC_SOUND_REGISTER:                ;{{Addr=$0863 Code Calls/jump count: 9 Data use count: 1}}
        di                        ;{{0863:f3}} 

        ld      b,$f4             ;{{0864:06f4}}  PPI port A I/O address
        out     (c),a             ;{{0866:ed79}}  write register index

        ld      b,$f6             ;{{0868:06f6}}  PPI port C I/O address
        in      a,(c)             ;{{086A:ed78}}  get current outputs of PPI port C I/O port
        or      $c0               ;{{086C:f6c0}}  bit 7,6: PSG register select
        out     (c),a             ;{{086E:ed79}}  write control to PSG. PSG will select register
                                  ; referenced by data at PPI port A output
        and     $3f               ;{{0870:e63f}}  bit 7,6: PSG inactive
        out     (c),a             ;{{0872:ed79}}  write control to PSG.

        ld      b,$f4             ;{{0874:06f4}}  PPI port A I/O address
        out     (c),c             ;{{0876:ed49}}  write register data

        ld      b,$f6             ;{{0878:06f6}}  PPI port C I/O address
        ld      c,a               ;{{087A:4f}} 
        or      $80               ;{{087B:f680}}  bit 7,6: PSG write data to selected register
        out     (c),a             ;{{087D:ed79}}  write control to PSG. PSG will write the data
                                  ; at PPI port A into the currently selected register
; bit 7,6: PSG inactive
        out     (c),c             ;{{087F:ed49}}  write control to PSG
        ei                        ;{{0881:fb}} 
        ret                       ;{{0882:c9}} 

;;================================================================================
;; scan keyboard

;;---------------------------------------------------------------------------------
;; select PSG port A register
scan_keyboard:                    ;{{Addr=$0883 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$f40e          ;{{0883:010ef4}}  B = I/O address for PPI port A
                                  ; C = 14 (index of PSG I/O port A register)
        out     (c),c             ;{{0886:ed49}}  write PSG register index to PPI port A

        ld      b,$f6             ;{{0888:06f6}}  B = I/O address for PPI port C
        in      a,(c)             ;{{088A:ed78}}  get current port C data
        and     $30               ;{{088C:e630}} 
        ld      c,a               ;{{088E:4f}} 

        or      $c0               ;{{088F:f6c0}}  PSG operation: select register
        out     (c),a             ;{{0891:ed79}}  write to PPI port C 
                                  ; PSG will use data from PPI port A
                                  ; to select a register
        out     (c),c             ;{{0893:ed49}} 

;;---------------------------------------------------------------------------------
;; set PPI port A to input
        inc     b                 ;{{0895:04}}  B = &f7 (I/O address for PPI control)
        ld      a,$92             ;{{0896:3e92}}  PPI port A: input
                                  ; PPI port B: input
                                  ; PPI port C (upper and lower): output
        out     (c),a             ;{{0898:ed79}}  write to PPI control register

;;---------------------------------------------------------------------------------

        push    bc                ;{{089A:c5}} 
        set     6,c               ;{{089B:cbf1}}  PSG: operation: read data from selected register


_scan_keyboard_14:                ;{{Addr=$089d Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f6             ;{{089D:06f6}}  B = I/O address for PPI port C
        out     (c),c             ;{{089F:ed49}} 
        ld      b,$f4             ;{{08A1:06f4}}  B = I/O address for PPI port A
        in      a,(c)             ;{{08A3:ed78}}  read selected keyboard line
                                  ; (keyboard data->PSG port A->PPI port A)

        ld      b,(hl)            ;{{08A5:46}}  get previous keyboard line state
                                  ; "0" indicates a pressed key
                                  ; "1" indicates a released key
        ld      (hl),a            ;{{08A6:77}}  store new keyboard line state

        and     b                 ;{{08A7:a0}}  a bit will be 1 where a key was not pressed
                                  ; in the previous keyboard scan and the current keyboard scan.
                                  ; a bit will be 0 where a key has been:
                                  ; - pressed in previous keyboard scan, released in this keyboard scan
                                  ; - not pressed in previous keyboard scan, pressed in this keyboard scan
                                  ; - key has been held for previous and this keyboard scan.
        cpl                       ;{{08A8:2f}}  change so a '1' now indicates held/pressed key
                                  ; '0' indicates a key that has not been pressed/held
        ld      (de),a            ;{{08A9:12}}  store keybaord line data

        inc     hl                ;{{08AA:23}} 
        inc     de                ;{{08AB:13}} 
        inc     c                 ;{{08AC:0c}} 

        ld      a,c               ;{{08AD:79}} 
        and     $0f               ;{{08AE:e60f}}  current keyboard line
        cp      $0a               ;{{08B0:fe0a}}  10 keyboard lines
        jr      nz,_scan_keyboard_14;{{08B2:20e9}} 

        pop     bc                ;{{08B4:c1}} 
;; B = I/O address of PPI control register
        ld      a,$82             ;{{08B5:3e82}}  PPI port A: output
                                  ; PPI port B: input
                                  ; PPI port C (upper and lower): output
        out     (c),a             ;{{08B7:ed79}} 
;; B = I/O address of PPI port C lower

        dec     b                 ;{{08B9:05}} 
        out     (c),c             ;{{08BA:ed49}} 
        ret                       ;{{08BC:c9}} 





;;***JumpRestore.asm
;;==============================================================
;; JUMP RESTORE
;;
;; (restore all the firmware jump routines)

;; main firmware jumpblock
JUMP_RESTORE:                     ;{{Addr=$08bd Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,main_firmware_jumpblock;{{08BD:21de08}}  table of addressess for firmware functions
        ld      de,Key_Manager_Jumpblock;{{08C0:1100bb}}  start of firmware jumpblock
        ld      bc,$cbcf          ;{{08C3:01cfcb}}  B = 203 entries, C = 0x0cf -> RST 1 -> LOW: LOW JUMP
        call    _jump_restore_5   ;{{08C6:cdcc08}} 

        ld      bc,$20ef          ;{{08C9:01ef20}}  B = number of entries: 32 entries ##LIT##;WARNING: Code area used as literal
                                  ; C=  0x0ef -> RST 5 -> LOW: FIRM JUMP
;;-------------------------------------------------------------------------------------
; C = 0x0cf -> RST 1 -> LOW: LOW JUMP
; OR
; C=  0x0ef -> RST 5 -> LOW: FIRM JUMP

_jump_restore_5:                  ;{{Addr=$08cc Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{08CC:79}}  write RST instruction 			
        ld      (de),a            ;{{08CD:12}} 
        inc     de                ;{{08CE:13}} 
        ldi                       ;{{08CF:eda0}}  write low byte of address in ROM
        inc     bc                ;{{08D1:03}} 
        cpl                       ;{{08D2:2f}} 
        rlca                      ;{{08D3:07}} 
        rlca                      ;{{08D4:07}} 
        and     $80               ;{{08D5:e680}} 
        or      (hl)              ;{{08D7:b6}} 
        ld      (de),a            ;{{08D8:12}}  write high byte of address in ROM
        inc     de                ;{{08D9:13}} 
        inc     hl                ;{{08DA:23}} 
        djnz    _jump_restore_5   ;{{08DB:10ef}} 
        ret                       ;{{08DD:c9}} 

;;+--------------------------------------------------------------
;; main firmware jumpblock
;; each entry is an address (within this ROM) which will perform
;; the associated firmware function
main_firmware_jumpblock:          ;{{Addr=$08de Data Calls/jump count: 0 Data use count: 1}}
                                  
        defw KM_INITIALISE        ; 0 firmware function: KM INITIALISE ##LABEL##
        defw KM_RESET             ; 1 firmware function: KM RESET ##LABEL##
        defw KM_WAIT_CHAR         ; 2 firmware function: KM WAIT CHAR ##LABEL##
        defw KM_READ_CHAR         ; 3 firmware function: KM READ CHAR ##LABEL##
        defw KM_CHAR_RETURN       ; 4 firmware function: KM CHAR RETURN ##LABEL##
        defw KM_SET_EXPAND        ; 5 firmware function: KM SET EXPAND ##LABEL##
        defw KM_GET_EXPAND        ; 6 firmware function: KM GET EXPAND ##LABEL##
        defw KM_EXP_BUFFER        ; 7 firmware function: KM EXP BUFFER ##LABEL##
        defw KM_WAIT_KEY          ; 8 firmware function: KM WAIT KEY ##LABEL##
        defw KM_READ_KEY          ; 9 firmware function: KM READ KEY ##LABEL##
        defw KM_TEST_KEY          ; 10 firmware function: KM TEST KEY ##LABEL##
        defw KM_GET_STATE         ; 11 firmware function: KM GET STATE ##LABEL##
        defw KM_GET_JOYSTICK      ; 12 firmware function: KM GET JOYSTICK ##LABEL##
        defw KM_SET_TRANSLATE     ; 13 firmware function: KM SET TRANSLATE ##LABEL##
        defw KM_GET_TRANSLATE     ; 14 firmware function: KM GET TRANSLATE ##LABEL##
        defw KM_SET_SHIFT         ; 15 firmware function: KM SET SHIFT ##LABEL##
        defw KM_GET_SHIFT         ; 16 firmware function: KM GET SHIFT ##LABEL##
        defw KM_SET_CONTROL       ; 17 firmware function: KM SET CONTROL  ##LABEL##
        defw KM_GET_CONTROL_      ; 18 firmware function: KM GET CONTROL  ##LABEL##
        defw KM_SET_REPEAT        ; 19 firmware function: KM SET REPEAT ##LABEL##
        defw KM_GET_REPEAT        ; 20 firmware function: KM GET REPEAT ##LABEL##
        defw KM_SET_DELAY         ; 21 firmware function: KM SET DELAY ##LABEL##
        defw KM_GET_DELAY         ; 22 firmware function: KM GET DELAY ##LABEL##
        defw KM_ARM_BREAK         ; 23 firmware function: KM ARM BREAK ##LABEL##
        defw KM_DISARM_BREAK      ; 24 firmware function: KM DISARM BREAK ##LABEL##
        defw KM_BREAK_EVENT       ; 25 firmware function: KM BREAK EVENT  ##LABEL##
        defw TXT_INITIALISE       ; 26 firmware function: TXT INITIALISE ##LABEL##
        defw TXT_RESET            ; 27 firmware function: TXT RESET ##LABEL##
        defw TXT_VDU_ENABLE       ; 28 firmware function: TXT VDU ENABLE ##LABEL##
        defw TXT_VDU_DISABLE      ; 29 firmware function: TXT VDU DISABLE ##LABEL##
        defw TXT_OUTPUT           ; 30 firmware function: TXT OUTPUT ##LABEL##
        defw TXT_WR_CHAR          ; 31 firmware function: TXT WR CHAR ##LABEL##
        defw TXT_RD_CHAR          ; 32 firmware function: TXT RD CHAR ##LABEL##
        defw TXT_SET_GRAPHIC      ; 33 firmware function: TXT SET GRAPHIC ##LABEL##
        defw TXT_WIN_ENABLE       ; 34 firmware function: TXT WIN ENABLE ##LABEL##
        defw TXT_GET_WINDOW       ; 35 firmware function: TXT GET WINDOW ##LABEL##
        defw TXT_CLEAR_WINDOW     ; 36 firmware function: TXT CLEAR WINDOW ##LABEL##
        defw TXT_SET_COLUMN       ; 37 firmware function: TXT SET COLUMN ##LABEL##
        defw TXT_SET_ROW          ; 38 firmware function: TXT SET ROW ##LABEL##
        defw TXT_SET_CURSOR       ; 39 firmware function: TXT SET CURSOR ##LABEL##
        defw TXT_GET_CURSOR       ; 40 firmware function: TXT GET CURSOR ##LABEL##
        defw TXT_CUR_ENABLE       ; 41 firmware function: TXT CUR ENABLE ##LABEL##
        defw TXT_CUR_DISABLE      ; 42 firmware function: TXT CUR DISABLE ##LABEL##
        defw TXT_CUR_ON           ; 43 firmware function: TXT CUR ON ##LABEL##
        defw TXT_CUR_OFF          ; 44 firmware function: TXT CUR OFF ##LABEL##
        defw TXT_VALIDATE         ; 45 firmware function: TXT VALIDATE ##LABEL##
        defw TXT_PLACE_CURSOR     ; 46 firmware function: TXT PLACE CURSOR ##LABEL##
        defw TXT_PLACE_CURSOR     ; 47 firmware function: TXT REMOVE CURSOR ##LABEL##
        defw TXT_SET_PEN_         ; 48 firmware function: TXT SET PEN  ##LABEL##
        defw TXT_GET_PEN          ; 49 firmware function: TXT GET PEN ##LABEL##
        defw TXT_SET_PAPER        ; 50 firmware function: TXT SET PAPER ##LABEL##
        defw TXT_GET_PAPER        ; 51 firmware function: TXT GET PAPER ##LABEL##
        defw TXT_INVERSE          ; 52 firmware function: TXT INVERSE ##LABEL##
        defw TXT_SET_BACK         ; 53 firmware function: TXT SET BACK ##LABEL##
        defw TXT_GET_BACK         ; 54 firmware function: TXT GET BACK ##LABEL##
        defw TXT_GET_MATRIX       ; 55 firmware function: TXT GET MATRIX ##LABEL##
        defw TXT_SET_MATRIX       ; 56 firmware function: TXT SET MATRIX ##LABEL##
        defw TXT_SET_M_TABLE      ; 57 firmware function: TXT SET M TABLE ##LABEL##
        defw TXT_GET_M_TABLE      ; 58 firmware function: TXT GET M TABLE ##LABEL##
        defw TXT_GET_CONTROLS     ; 59 firmware function: TXT GET CONTROLS ##LABEL##
        defw TXT_STR_SELECT       ; 60 firmware function: TXT STR SELECT ##LABEL##
        defw TXT_SWAP_STREAMS     ; 61 firmware function: TXT SWAP STREAMS ##LABEL##
        defw GRA_INITIALISE       ; 62 firmware function: GRA INITIALISE ##LABEL##
        defw GRA_RESET            ; 63 firmware function: GRA RESET ##LABEL##
        defw GRA_MOVE_ABSOLUTE    ; 64 firmware function: GRA MOVE ABSOLUTE ##LABEL##
        defw GRA_MOVE_RELATIVE    ; 65 firmware function: GRA MOVE RELATIVE ##LABEL##
        defw GRA_ASK_CURSOR       ; 66 firmware function: GRA ASK CURSOR ##LABEL##
        defw GRA_SET_ORIGIN       ; 67 firmware function: GRA SET ORIGIN ##LABEL##
        defw GRA_GET_ORIGIN       ; 68 firmware function: GRA GET ORIGIN ##LABEL##
        defw GRA_WIN_WIDTH        ; 69 firmware function: GRA WIN WIDTH ##LABEL##
        defw GRA_WIN_HEIGHT       ; 70 firmware function: GRA WIN HEIGHT ##LABEL##
        defw GRA_GET_W_WIDTH      ; 71 firmware function: GRA GET W WIDTH ##LABEL##
        defw GRA_GET_W_HEIGHT     ; 72 firmware function: GRA GET W HEIGHT ##LABEL##
        defw GRA_CLEAR_WINDOW     ; 73 firmware function: GRA CLEAR WINDOW ##LABEL##
        defw GRA_SET_PEN          ; 74 firmware function: GRA SET PEN ##LABEL##
        defw GRA_GET_PEN          ; 75 firmware function: GRA GET PEN ##LABEL##
        defw GRA_SET_PAPER        ; 76 firmware function: GRA SET PAPER ##LABEL##
        defw GRA_GET_PAPER        ; 77 firmware function: GRA GET PAPER ##LABEL##
        defw GRA_PLOT_ABSOLUTE    ; 78 firmware function: GRA PLOT ABSOLUTE ##LABEL##
        defw GRA_PLOT_RELATIVE    ; 79 firmware function: GRA PLOT RELATIVE ##LABEL##
        defw GRA_TEST_ABSOLUTE    ; 80 firmware function: GRA TEST ABSOLUTE ##LABEL##
        defw GRA_TEST_RELATIVE    ; 81 firmware function: GRA TEST RELATIVE ##LABEL##
        defw GRA_LINE_ABSOLUTE    ; 82 firmware function: GRA LINE ABSOLUTE ##LABEL##
        defw GRA_LINE_RELATIVE    ; 83 firmware function: GRA LINE RELATIVE ##LABEL##
        defw GRA_WR_CHAR          ; 84 firmware function: GRA WR CHAR ##LABEL##
        defw SCR_INITIALISE       ; 85 firmware function: SCR INITIALIZE ##LABEL##
        defw SCR_RESET            ; 86 firmware function: SCR RESET ##LABEL##
        defw SCR_OFFSET           ; 87 firmware function: SCR OFFSET ##LABEL##
        defw SCR_SET_BASE         ; 88 firmware function: SCR SET BASE ##LABEL##
        defw SCR_GET_LOCATION     ; 89 firmware function: SCR GET LOCATION ##LABEL##
        defw SCR_SET_MODE         ; 90 firmware function: SCR SET MODE ##LABEL##
        defw SCR_GET_MODE         ; 91 firmware function: SCR GET MODE ##LABEL##
        defw IND_SCR_MODE_CLEAR   ; 92 firmware function: SCR CLEAR ##LABEL##
        defw SCR_CHAR_LIMITS      ; 93 firmware function: SCR CHAR LIMITS ##LABEL##
        defw SCR_CHAR_POSITION    ; 94 firmware function: SCR CHAR POSITION ##LABEL##
        defw SCR_DOT_POSITION     ; 95 firmware function: SCR DOT POSITION ##LABEL##
        defw SCR_NEXT_BYTE        ; 96 firmware function: SCR NEXT BYTE ##LABEL##
        defw SCR_PREV_BYTE        ; 97 firmware function: SCR PREV BYTE ##LABEL##
        defw SCR_NEXT_LINE        ; 98 firmware function: SCR NEXT LINE ##LABEL##
        defw SCR_PREV_LINE        ; 99 firmware function: SCR PREV LINE ##LABEL##
        defw SCR_INK_ENCODE       ; 100 firmware function: SCR INK ENCODE ##LABEL##
        defw SCR_INK_DECODE       ; 101 firmware function: SCR INK DECODE ##LABEL##
        defw SCR_SET_INK          ; 102 firmware function: SCR SET INK ##LABEL##
        defw SCR_GET_INK          ; 103 firmware function: SCR GET INK ##LABEL##
        defw SCR_SET_BORDER       ; 104 firmware function: SCR SET BORDER ##LABEL##
        defw SCR_GET_BORDER       ; 105 firmware function: SCR GET BORDER ##LABEL##
        defw SCR_SET_FLASHING     ; 106 firmware function: SCR SET FLASHING ##LABEL##
        defw SCR_GET_FLASHING     ; 107 firmware function: SCR GET FLASHING ##LABEL##
        defw SCR_FILL_BOX         ; 108 firmware function: SCR FILL BOX ##LABEL##
        defw SCR_FLOOD_BOX        ; 109 firmware function: SCR FLOOD BOX ##LABEL##
        defw SCR_CHAR_INVERT      ; 110 firmware function: SCR CHAR INVERT ##LABEL##
        defw SCR_HW_ROLL          ; 111 firmware function: SCR HW ROLL ##LABEL##
        defw SCR_SW_ROLL          ; 112 firmware function: SCR SW ROLL ##LABEL##
        defw SCR_UNPACK           ; 113 firmware function: SCR UNPACK ##LABEL##
        defw SCR_REPACK           ; 114 firmware function: SCR REPACK ##LABEL##
        defw SCR_ACCESS           ; 115 firmware function: SCR ACCESS ##LABEL##
        defw SCR_PIXELS           ; 116 firmware function: SCR PIXELS ##LABEL##
        defw SCR_HORIZONTAL       ; 117 firmware function: SCR HORIZONTAL ##LABEL##
        defw SCR_VERTICAL         ; 118 firmware function: SCR VERTICAL ##LABEL##
        defw CAS_INITIALISE       ; 119 firmware function: CAS INITIALISE ##LABEL##
        defw CAS_SET_SPEED        ; 120 firmware function: CAS SET SPEED ##LABEL##
        defw CAS_NOISY            ; 121 firmware function: CAS NOISY ##LABEL##
        defw CAS_START_MOTOR      ; 122 firmware function: CAS START MOTOR ##LABEL##
        defw CAS_STOP_MOTOR       ; 123 firmware function: CAS STOP MOTOR ##LABEL##
        defw CAS_RESTORE_MOTOR    ; 124 firmware function: CAS RESTORE MOTOR ##LABEL##
        defw CAS_IN_OPEN          ; 125 firmware function: CAS IN OPEN ##LABEL##
        defw CAS_IN_CLOSE         ; 126 firmware function: CAS IN CLOSE ##LABEL##
        defw CAS_IN_ABANDON       ; 127 firmware function: CAS IN ABANDON ##LABEL##
        defw CAS_IN_CHAR          ; 128 firmware function: CAS IN CHAR ##LABEL##
        defw CAS_IN_DIRECT        ; 129 firmware function: CAS IN DIRECT ##LABEL##
        defw CAS_RETURN           ; 130 firmware function: CAS RETURN ##LABEL##
        defw CAS_TEST_EOF         ; 131 firmware function: CAS TEST EOF ##LABEL##
        defw CAS_OUT_OPEN         ; 132 firmware function: CAS OUT OPEN ##LABEL##
        defw CAS_OUT_CLOSE        ; 133 firmware function: CAS OUT CLOSE ##LABEL##
        defw CAS_OUT_ABANDON      ; 134 firmware function: CAS OUT ABANDON ##LABEL##
        defw CAS_OUT_CHAR         ; 135 firmware function: CAS OUT CHAR ##LABEL##
        defw CAS_OUT_DIRECT       ; 136 firmware function: CAS OUT DIRECT ##LABEL##
        defw CAS_CATALOG          ; 137 firmware function: CAS CATALOG ##LABEL##
        defw CAS_WRITE            ; 138 firmware function: CAS WRITE ##LABEL##
        defw CAS_READ             ; 139 firmware function: CAS READ ##LABEL##
        defw CAS_CHECK            ; 140 firmware function: CAS CHECK ##LABEL##
        defw SOUND_RESET          ; 141 firmware function: SOUND RESET ##LABEL##
        defw SOUND_QUEUE          ; 142 firmware function: SOUND QUEUE ##LABEL##
        defw SOUND_CHECK          ; 143 firmware function: SOUND CHECK ##LABEL##
        defw SOUND_ARM_EVENT      ; 144 firmware function: SOUND ARM EVENT ##LABEL##
        defw SOUND_RELEASE        ; 145 firmware function: SOUND RELEASE ##LABEL##
        defw SOUND_HOLD           ; 146 firmware function: SOUND HOLD ##LABEL##
        defw SOUND_CONTINUE       ; 147 firmware function: SOUND CONTINUE ##LABEL##
        defw SOUND_AMPL_ENVELOPE  ; 148 firmware function: SOUND AMPL ENVELOPE ##LABEL##
        defw SOUND_TONE_ENVELOPE  ; 149 firmware function: SOUND TONE ENVELOPE ##LABEL##
        defw SOUND_A_ADDRESS      ; 150 firmware function: SOUND A ADDRESS ##LABEL##
        defw SOUND_T_ADDRESS      ; 151 firmware function: SOUND T ADDRESS ##LABEL##
        defw KL_CHOKE_OFF         ; 152 firmware function: KL CHOKE OFF ##LABEL##
        defw KL_ROM_WALK          ; 153 firmware function: KL ROM WALK ##LABEL##
        defw KL_INIT_BACK         ; 154 firmware function: KL INIT BACK ##LABEL##
        defw KL_LOG_EXT           ; 155 firmware function: KL LOG EXT ##LABEL##
        defw KL_FIND_COMMAND      ; 156 firmware function: KL FIND COMMAND ##LABEL##
        defw KL_NEW_FRAME_FLY     ; 157 firmware function: KL NEW FRAME FLY ##LABEL##
        defw KL_ADD_FRAME_FLY     ; 158 firmware function: KL ADD FRAME FLY ##LABEL##
        defw KL_DEL_FRAME_FLY     ; 159 firmware function: KL DEL FRAME FLY ##LABEL##
        defw KL_NEW_FAST_TICKER   ; 160 firmware function: KL NEW FAST TICKER ##LABEL##
        defw KL_ADD_FAST_TICKER   ; 161 firmware function: KL ADD FAST TICKER ##LABEL##
        defw KL_DEL_FAST_TICKER   ; 162 firmware function: KL DEL FAST TICKER ##LABEL##
        defw KL_ADD_TICKER        ; 163 firmware function: KL ADD TICKER ##LABEL##
        defw KL_DEL_TICKER        ; 164 firmware function: KL DEL TICKER ##LABEL##
        defw KL_INIT_EVENT        ; 165 firmware function: KL INIT EVENT ##LABEL##
        defw KL_EVENT             ; 166 firmware function: KL EVENT ##LABEL##
        defw KL_SYNC_RESET        ; 167 firmware function: KL SYNC RESET ##LABEL##
        defw KL_DEL_SYNCHRONOUS   ; 168 firmware function: KL DEL SYNCHRONOUS ##LABEL##
        defw KL_NEXT_SYNC         ; 169 firmware function: KL NEXT SYNC ##LABEL##
        defw KL_DO_SYNC           ; 170 firmware function: KL DO SYNC ##LABEL##
        defw KL_DONE_SYNC         ; 171 firmware function: KL DONE SYNC ##LABEL##
        defw KL_EVENT_DISABLE     ; 172 firmware function: KL EVENT DISABLE ##LABEL##
        defw KL_EVENT_ENABLE      ; 173 firmware function: KL EVENT ENABLE ##LABEL##
        defw KL_DISARM_EVENT      ; 174 firmware function: KL DISARM EVENT ##LABEL##
        defw KL_TIME_PLEASE       ; 175 firmware function: KL TIME PLEASE ##LABEL##
        defw KL_TIME_SET          ; 176 firmware function: KL TIME SET ##LABEL##
        defw MC_BOOT_PROGRAM      ; 177 firmware function: MC BOOT PROGRAM ##LABEL##
        defw MC_START_PROGRAM     ; 178 firmware function: MC START PROGRAM ##LABEL##
        defw MC_WAIT_FLYBACK      ; 179 firmware function: MC WAIT FLYBACK ##LABEL##
        defw MC_SET_MODE          ; 180 firmware function: MC SET MODE  ##LABEL##
        defw MC_SCREEN_OFFSET     ; 181 firmware function: MC SCREEN OFFSET ##LABEL##
        defw MC_CLEAR_INKS        ; 182 firmware function: MC CLEAR INKS ##LABEL##
        defw MC_SET_INKS          ; 183 firmware function: MC SET INKS ##LABEL##
        defw MC_RESET_PRINTER     ; 184 firmware function: MC RESET PRINTER ##LABEL##
        defw MC_PRINT_CHAR        ; 185 firmware function: MC PRINT CHAR ##LABEL##
        defw MC_BUSY_PRINTER      ; 186 firmware function: MC BUSY PRINTER ##LABEL##
        defw MC_SEND_PRINTER      ; 187 firmware function: MC SEND PRINTER ##LABEL##
        defw MC_SOUND_REGISTER    ; 188 firmware function: MC SOUND REGISTER ##LABEL##
        defw JUMP_RESTORE         ; 189 firmware function: JUMP RESTORE ##LABEL##
        defw KM_SET_LOCKS         ; 190 firmware function: KM SET LOCKS ##LABEL##
        defw KM_FLUSH             ; 191 firmware function: KM FLUSH ##LABEL##
        defw TXT_ASK_STATE        ; 192 firmware function: TXT ASK STATE ##LABEL##
        defw GRA_DEFAULT          ; 193 firmware function: GRA DEFAULT ##LABEL##
        defw GRA_SET_BACK         ; 194 firmware function: GRA SET BACK ##LABEL##
        defw GRA_SET_FIRST        ; 195 firmware function: GRA SET FIRST ##LABEL##
        defw GRA_SET_LINE_MASK    ; 196 firmware function: GRA SET LINE MASK ##LABEL##
        defw GRA_FROM_USER        ; 197 firmware function: GRA FROM USER ##LABEL##
        defw GRA_FILL             ; 198 firmware function: GRA FILL ##LABEL##
        defw SCR_SET_POSITION     ; 199 firmware function: SCR SET POSITION ##LABEL##
        defw MC_PRINT_TRANSLATION ; 200 firmware function: MC PRINT TRANSLATION ##LABEL##
        defw KL_BANK_SWITCH_      ; 201 firmware function: KL BANK SWITCH ##LABEL##
        defw EDIT                 ; 202 BD5E ##LABEL##
        defw REAL_copy_atDE_to_atHL; 0 BD61 ##LABEL##
        defw REAL_INT_to_real     ; 1 BD64 ##LABEL##
        defw REAL_BIN_to_real     ; 2 BD67 ##LABEL##
        defw REAL_to_int          ; 3 BD6A ##LABEL##
        defw REAL_to_bin          ; 4 BD6D ##LABEL##
        defw REAL_fix             ; 5 BD70 ##LABEL##
        defw REAL_int             ; 6 BD73 ##LABEL##
        defw REAL_prepare_for_decimal; 7 BD76 ##LABEL##
        defw REAL_exp_A           ; 8 BD79 ##LABEL##
        defw REAL_addition        ; 9 BD7C ##LABEL##
        defw REAL_rnd             ; 10 BD7F ##LABEL##
        defw REAL_reverse_subtract; 11 BD82 ##LABEL##
        defw REAL_multiplication  ; 12 BD85 ##LABEL##
        defw REAL_division        ; 13 BD88 ##LABEL##
        defw REAL_rnd0            ; 14 BD8B ##LABEL##
        defw REAL_compare         ; 15 BD8E ##LABEL##
        defw REAL_Negate          ; 16 BD91 ##LABEL##
        defw REAL_SGN             ; 17 BD94 ##LABEL##
        defw REAL_set_degrees_or_radians; 18 BD97 ##LABEL##
        defw REAL_PI_to_DE        ; 19 BD9A ##LABEL##
        defw REAL_sqr             ; 20 BD9D ##LABEL##
        defw REAL_power           ; 21 BDA0 ##LABEL##
        defw REAL_log             ; 22 BDA3 ##LABEL##
        defw REAL_log10           ; 23 BDA6 ##LABEL##
        defw REAL_exp             ; 24 BDA9 ##LABEL##
        defw REAL_sin             ; 25 BDAC ##LABEL##
        defw REAL_cosine          ; 26 BDAF ##LABEL##
        defw REAL_tan             ; 27 BDB2 ##LABEL##
        defw REAL_arctan          ; 28 BDB5 ##LABEL##
        defw REAL_5byte_to_real   ; 29 BDB8 ##LABEL##
        defw REAL_init_random_number_generator; 30 BDBB ##LABEL##
        defw REAL_RANDOMIZE_seed  ; 31 BDBE ##LABEL##

;;==========================================================================
;; initialise firmware indirections
;; this routine is called by each of the firmware "units"
;; i.e. screen pack, graphics pack etc.

;; HL = pointer to start of a table

;; table format:
;;
;; 0 = length of data 
;; 1,2 = destination to copy data
;; 3.. = data

initialise_firmware_indirections: ;{{Addr=$0ab4 Code Calls/jump count: 6 Data use count: 0}}
        ld      c,(hl)            ;{{0AB4:4e}} 
        ld      b,$00             ;{{0AB5:0600}} 
        inc     hl                ;{{0AB7:23}} 
        ld      e,(hl)            ;{{0AB8:5e}} 
        inc     hl                ;{{0AB9:23}} 
        ld      d,(hl)            ;{{0ABA:56}} 
        inc     hl                ;{{0ABB:23}} 
        ldir                      ;{{0ABC:edb0}} 
        ret                       ;{{0ABE:c9}} 




;;***Screen.asm
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



;;***Text.asm
;; TEXT ROUTINES
;;===========================================================================
;; TXT INITIALISE

TXT_INITIALISE:                   ;{{Addr=$1074 Code Calls/jump count: 1 Data use count: 1}}
        call    TXT_RESET         ;{{1074:cd8410}} ; TXT RESET
        xor     a                 ;{{1077:af}} 
        ld      (UDG_matrix_table_flag_),a;{{1078:3235b7}} 
        ld      hl,$0001          ;{{107B:210100}} ##LIT##;WARNING: Code area used as literal
        call    initialise_a_stream;{{107E:cd3911}} 
        jp      clear_txt_streams_area;{{1081:c39f10}} 

;;===========================================================================
;; TXT RESET

TXT_RESET:                        ;{{Addr=$1084 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,_txt_reset_3   ;{{1084:218d10}} ; table used to initialise text vdu indirections
        call    initialise_firmware_indirections;{{1087:cdb40a}} ; initialise text vdu indirections
        jp      initialise_control_code_functions;{{108A:c36414}} ; initialise control code handler functions

_txt_reset_3:                     ;{{Addr=$108d Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $f                   
        defw TXT_DRAW_CURSOR                
        jp		IND_TXT_UNDRAW_CURSOR ; IND: TXT DRAW CURSOR
        jp      IND_TXT_UNDRAW_CURSOR; IND: TXT UNDRAW CURSOR
        jp      IND_TXT_WRITE_CHAR; IND: TXT WRITE CHAR
        jp      IND_TXT_UNWRITE   ; IND: TXT UNWRITE
        jp      IND_TXT_OUT_ACTION; IND: TXT OUT ACTION

;;===========================================================================
;; clear txt streams area?

clear_txt_streams_area:           ;{{Addr=$109f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$08             ;{{109F:3e08}} 
        ld      de,RAM_b6b6       ;{{10A1:11b6b6}} 
_clear_txt_streams_area_2:        ;{{Addr=$10a4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,Current_Stream_;{{10A4:2126b7}} 
        ld      bc,$000e          ;{{10A7:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{10AA:edb0}} 
        dec     a                 ;{{10AC:3d}} 
        jr      nz,_clear_txt_streams_area_2;{{10AD:20f5}}  (-&0b)
        ld      (current_stream_number),a;{{10AF:32b5b6}} 
        ret                       ;{{10B2:c9}} 

;;==================================================================================
;; clean up streams?
clean_up_streams:                 ;{{Addr=$10b3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_stream_number);{{10B3:3ab5b6}} 
        ld      c,a               ;{{10B6:4f}} 
        ld      b,$08             ;{{10B7:0608}} 

_clean_up_streams_3:              ;{{Addr=$10b9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10B9:78}} 
        dec     a                 ;{{10BA:3d}} 
        call    TXT_STR_SELECT    ;{{10BB:cde410}}  TXT STR SELECT
        call    TXT_UNDRAW_CURSOR ;{{10BE:cdd0bd}}  IND: TXT UNDRAW CURSOR
        call    TXT_GET_PAPER     ;{{10C1:cdc012}}  TXT GET PAPER
        ld      (current_PAPER_number_),a;{{10C4:3230b7}} 
        call    TXT_GET_PEN       ;{{10C7:cdba12}}  TXT GET PEN
        ld      (current_PEN_number_),a;{{10CA:322fb7}} 
        djnz    _clean_up_streams_3;{{10CD:10ea}}  (-&16)
        ld      a,c               ;{{10CF:79}} 
        ret                       ;{{10D0:c9}} 

;;==================================================================================
;; initialise txt streams
initialise_txt_streams:           ;{{Addr=$10d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{10D1:4f}} 
        ld      b,$08             ;{{10D2:0608}} 
_initialise_txt_streams_2:        ;{{Addr=$10d4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10D4:78}} 
        dec     a                 ;{{10D5:3d}} 
        call    TXT_STR_SELECT    ;{{10D6:cde410}}  TXT STR SELECT
        push    bc                ;{{10D9:c5}} 
        ld      hl,(current_PEN_number_);{{10DA:2a2fb7}} 
        call    initialise_a_stream;{{10DD:cd3911}} 
        pop     bc                ;{{10E0:c1}} 
        djnz    _initialise_txt_streams_2;{{10E1:10f1}}  (-&0f)
        ld      a,c               ;{{10E3:79}} 

;;==================================================================================
;; TXT STR SELECT
TXT_STR_SELECT:                   ;{{Addr=$10e4 Code Calls/jump count: 4 Data use count: 1}}
        and     $07               ;{{10E4:e607}} 
        ld      hl,current_stream_number;{{10E6:21b5b6}} 
        cp      (hl)              ;{{10E9:be}} 
        ret     z                 ;{{10EA:c8}} 

        push    bc                ;{{10EB:c5}} 
        push    de                ;{{10EC:d5}} 
        ld      c,(hl)            ;{{10ED:4e}} 
        ld      (hl),a            ;{{10EE:77}} 
        ld      b,a               ;{{10EF:47}} 
        ld      a,c               ;{{10F0:79}} 
        call    _txt_swap_streams_19;{{10F1:cd2611}} 
        call    _txt_swap_streams_14;{{10F4:cd1e11}} 
        ld      a,b               ;{{10F7:78}} 
        call    _txt_swap_streams_19;{{10F8:cd2611}} 
        ex      de,hl             ;{{10FB:eb}} 
        call    _txt_swap_streams_14;{{10FC:cd1e11}} 
        ld      a,c               ;{{10FF:79}} 
        pop     de                ;{{1100:d1}} 
        pop     bc                ;{{1101:c1}} 
        ret                       ;{{1102:c9}} 

;;===========================================================================
;; TXT SWAP STREAMS
TXT_SWAP_STREAMS:                 ;{{Addr=$1103 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(current_stream_number);{{1103:3ab5b6}} 
        push    af                ;{{1106:f5}} 
        ld      a,c               ;{{1107:79}} 
        call    TXT_STR_SELECT    ;{{1108:cde410}} 
        ld      a,b               ;{{110B:78}} 
        ld      (current_stream_number),a;{{110C:32b5b6}} 
        call    _txt_swap_streams_19;{{110F:cd2611}} 
        push    de                ;{{1112:d5}} 
        ld      a,c               ;{{1113:79}} 
        call    _txt_swap_streams_19;{{1114:cd2611}} 
        pop     hl                ;{{1117:e1}} 
        call    _txt_swap_streams_14;{{1118:cd1e11}} 
        pop     af                ;{{111B:f1}} 
        jr      TXT_STR_SELECT    ;{{111C:18c6}}  (-&3a)
;;--------------------------------------------------------------
_txt_swap_streams_14:             ;{{Addr=$111e Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{111E:c5}} 
        ld      bc,$000e          ;{{111F:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1122:edb0}} 
        pop     bc                ;{{1124:c1}} 
        ret                       ;{{1125:c9}} 

;;--------------------------------------------------------------
_txt_swap_streams_19:             ;{{Addr=$1126 Code Calls/jump count: 4 Data use count: 0}}
        and     $07               ;{{1126:e607}} 
        ld      e,a               ;{{1128:5f}} 
        add     a,a               ;{{1129:87}} 
        add     a,e               ;{{112A:83}} 
        add     a,a               ;{{112B:87}} 
        add     a,e               ;{{112C:83}} 
        add     a,a               ;{{112D:87}} 
        add     a,$b6             ;{{112E:c6b6}} 
        ld      e,a               ;{{1130:5f}} 
        adc     a,$b6             ;{{1131:ceb6}} 
        sub     e                 ;{{1133:93}} 
        ld      d,a               ;{{1134:57}} 
        ld      hl,Current_Stream_;{{1135:2126b7}} 
        ret                       ;{{1138:c9}} 

;;===========================================================================
;; initialise a stream??
initialise_a_stream:              ;{{Addr=$1139 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{1139:eb}} 
        ld      a,$83             ;{{113A:3e83}} 
        ld      (cursor_flag_),a  ;{{113C:322eb7}} 
        ld      a,d               ;{{113F:7a}} 
        call    TXT_SET_PAPER     ;{{1140:cdab12}}  TXT SET PAPER
        ld      a,e               ;{{1143:7b}} 
        call    TXT_SET_PEN_      ;{{1144:cda612}}  TXT SET PEN
        xor     a                 ;{{1147:af}} 
        call    TXT_SET_GRAPHIC   ;{{1148:cda813}}  TXT SET GRAPHIC
        call    TXT_SET_BACK      ;{{114B:cd7b13}}  TXT SET BACK
        ld      hl,$0000          ;{{114E:210000}} ##LIT##;WARNING: Code area used as literal
        ld      de,$7f7f          ;{{1151:117f7f}} 
        call    TXT_WIN_ENABLE    ;{{1154:cd0812}}  TXT WIN ENABLE
        jp      TXT_VDU_ENABLE    ;{{1157:c35914}}  TXT VDU ENABLE

;;===========================================================================
;; TXT SET COLUMN

TXT_SET_COLUMN:                   ;{{Addr=$115a Code Calls/jump count: 1 Data use count: 1}}
        dec     a                 ;{{115A:3d}} 
        ld      hl,window_left_column_;{{115B:212ab7}} 
        add     a,(hl)            ;{{115E:86}} 
        ld      hl,(Current_Stream_);{{115F:2a26b7}} 
        ld      h,a               ;{{1162:67}} 
        jr      _txt_set_cursor_1 ;{{1163:180e}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; TXT SET ROW

TXT_SET_ROW:                      ;{{Addr=$1165 Code Calls/jump count: 0 Data use count: 1}}
        dec     a                 ;{{1165:3d}} 
        ld      hl,window_top_line_;{{1166:2129b7}} 
        add     a,(hl)            ;{{1169:86}} 
        ld      hl,(Current_Stream_);{{116A:2a26b7}} 
        ld      l,a               ;{{116D:6f}} 
        jr      _txt_set_cursor_1 ;{{116E:1803}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; TXT SET CURSOR

TXT_SET_CURSOR:                   ;{{Addr=$1170 Code Calls/jump count: 7 Data use count: 1}}
        call    _txt_get_cursor_4 ;{{1170:cd8611}} 

;; undraw cursor, set cursor position and draw it
_txt_set_cursor_1:                ;{{Addr=$1173 Code Calls/jump count: 4 Data use count: 0}}
        call    TXT_UNDRAW_CURSOR ;{{1173:cdd0bd}}  IND: TXT UNDRAW CURSOR

;; set cursor position and draw it
_txt_set_cursor_2:                ;{{Addr=$1176 Code Calls/jump count: 1 Data use count: 0}}
        ld      (Current_Stream_),hl;{{1176:2226b7}} 
        jp      TXT_DRAW_CURSOR   ;{{1179:c3cdbd}}  IND: TXT DRAW CURSOR

;;===========================================================================
;; TXT GET CURSOR

TXT_GET_CURSOR:                   ;{{Addr=$117c Code Calls/jump count: 16 Data use count: 1}}
        ld      hl,(Current_Stream_);{{117C:2a26b7}} 
        call    _txt_get_cursor_13;{{117F:cd9311}} 
        ld      a,(scroll_count)  ;{{1182:3a2db7}} 
        ret                       ;{{1185:c9}} 

;;----------------------------------------------------------------
_txt_get_cursor_4:                ;{{Addr=$1186 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_top_line_);{{1186:3a29b7}} 
        dec     a                 ;{{1189:3d}} 
        add     a,l               ;{{118A:85}} 
        ld      l,a               ;{{118B:6f}} 
        ld      a,(window_left_column_);{{118C:3a2ab7}} 
        dec     a                 ;{{118F:3d}} 
        add     a,h               ;{{1190:84}} 
        ld      h,a               ;{{1191:67}} 
        ret                       ;{{1192:c9}} 

;;------------------------------------------------------------------
_txt_get_cursor_13:               ;{{Addr=$1193 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_top_line_);{{1193:3a29b7}} 
        sub     l                 ;{{1196:95}} 
        cpl                       ;{{1197:2f}} 
        inc     a                 ;{{1198:3c}} 
        inc     a                 ;{{1199:3c}} 
        ld      l,a               ;{{119A:6f}} 
        ld      a,(window_left_column_);{{119B:3a2ab7}} 
        sub     h                 ;{{119E:94}} 
        cpl                       ;{{119F:2f}} 
        inc     a                 ;{{11A0:3c}} 
        inc     a                 ;{{11A1:3c}} 
        ld      h,a               ;{{11A2:67}} 
        ret                       ;{{11A3:c9}} 

;;====================================================================
;; scroll window?
scroll_window:                    ;{{Addr=$11a4 Code Calls/jump count: 8 Data use count: 0}}
        call    TXT_UNDRAW_CURSOR ;{{11A4:cdd0bd}} ; IND: TXT UNDRAW CURSOR

;;--------------------------------------------------------------------
_scroll_window_1:                 ;{{Addr=$11a7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(Current_Stream_);{{11A7:2a26b7}} 
        call    _txt_validate_6   ;{{11AA:cdd611}} 
        ld      (Current_Stream_),hl;{{11AD:2226b7}} 
        ret     c                 ;{{11B0:d8}} 

        push    hl                ;{{11B1:e5}} 
        ld      hl,scroll_count   ;{{11B2:212db7}} 
        ld      a,b               ;{{11B5:78}} 
        add     a,a               ;{{11B6:87}} 
        inc     a                 ;{{11B7:3c}} 
        add     a,(hl)            ;{{11B8:86}} 
        ld      (hl),a            ;{{11B9:77}} 
        call    TXT_GET_WINDOW    ;{{11BA:cd5212}} ; TXT GET WINDOW
        ld      a,(current_PAPER_number_);{{11BD:3a30b7}} 
        push    af                ;{{11C0:f5}} 
        call    c,SCR_SW_ROLL     ;{{11C1:dc440e}} ; SCR SW ROLL
        pop     af                ;{{11C4:f1}} 
        call    nc,SCR_HW_ROLL    ;{{11C5:d4000e}} ; SCR HW ROLL
        pop     hl                ;{{11C8:e1}} 
        ret                       ;{{11C9:c9}} 


;;===========================================================================
;; TXT VALIDATE

TXT_VALIDATE:                     ;{{Addr=$11ca Code Calls/jump count: 8 Data use count: 1}}
        call    _txt_get_cursor_4 ;{{11CA:cd8611}} 
        call    _txt_validate_6   ;{{11CD:cdd611}} 
        push    af                ;{{11D0:f5}} 
        call    _txt_get_cursor_13;{{11D1:cd9311}} 
        pop     af                ;{{11D4:f1}} 
        ret                       ;{{11D5:c9}} 
;;------------------------------------------------------------------
_txt_validate_6:                  ;{{Addr=$11d6 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_right_colwnn_);{{11D6:3a2cb7}} 
        cp      h                 ;{{11D9:bc}} 
        jp      p,_txt_validate_12;{{11DA:f2e211}} 
        ld      a,(window_left_column_);{{11DD:3a2ab7}} 
        ld      h,a               ;{{11E0:67}} 
        inc     l                 ;{{11E1:2c}} 
_txt_validate_12:                 ;{{Addr=$11e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_left_column_);{{11E2:3a2ab7}} 
        dec     a                 ;{{11E5:3d}} 
        cp      h                 ;{{11E6:bc}} 
        jp      m,_txt_validate_19;{{11E7:faef11}} 
        ld      a,(window_right_colwnn_);{{11EA:3a2cb7}} 
        ld      h,a               ;{{11ED:67}} 
        dec     l                 ;{{11EE:2d}} 
_txt_validate_19:                 ;{{Addr=$11ef Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_top_line_);{{11EF:3a29b7}} 
        dec     a                 ;{{11F2:3d}} 
        cp      l                 ;{{11F3:bd}} 
        jp      p,_txt_validate_31;{{11F4:f20212}} 
        ld      a,(window_bottom_line_);{{11F7:3a2bb7}} 
        cp      l                 ;{{11FA:bd}} 
        scf                       ;{{11FB:37}} 
        ret     p                 ;{{11FC:f0}} 

        ld      l,a               ;{{11FD:6f}} 
        ld      b,$ff             ;{{11FE:06ff}} 
        or      a                 ;{{1200:b7}} 
        ret                       ;{{1201:c9}} 

;;------------------------------------------------------------------
_txt_validate_31:                 ;{{Addr=$1202 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{1202:3c}} 
        ld      l,a               ;{{1203:6f}} 
        ld      b,$00             ;{{1204:0600}} 
        or      a                 ;{{1206:b7}} 
        ret                       ;{{1207:c9}} 

;;===========================================================================
;; TXT WIN ENABLE

TXT_WIN_ENABLE:                   ;{{Addr=$1208 Code Calls/jump count: 2 Data use count: 1}}
        call    SCR_CHAR_LIMITS   ;{{1208:cd5d0b}} ; SCR CHAR LIMITS
        ld      a,h               ;{{120B:7c}} 
        call    _txt_win_enable_33;{{120C:cd4012}} 
        ld      h,a               ;{{120F:67}} 
        ld      a,d               ;{{1210:7a}} 
        call    _txt_win_enable_33;{{1211:cd4012}} 
        ld      d,a               ;{{1214:57}} 
        cp      h                 ;{{1215:bc}} 
        jr      nc,_txt_win_enable_11;{{1216:3002}}  (+&02)
        ld      d,h               ;{{1218:54}} 
        ld      h,a               ;{{1219:67}} 
_txt_win_enable_11:               ;{{Addr=$121a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{121A:7d}} 
        call    _txt_win_enable_40;{{121B:cd4912}} 
        ld      l,a               ;{{121E:6f}} 
        ld      a,e               ;{{121F:7b}} 
        call    _txt_win_enable_40;{{1220:cd4912}} 
        ld      e,a               ;{{1223:5f}} 
        cp      l                 ;{{1224:bd}} 
        jr      nc,_txt_win_enable_21;{{1225:3002}}  (+&02)
        ld      e,l               ;{{1227:5d}} 
        ld      l,a               ;{{1228:6f}} 
_txt_win_enable_21:               ;{{Addr=$1229 Code Calls/jump count: 1 Data use count: 0}}
        ld      (window_top_line_),hl;{{1229:2229b7}} 
        ld      (window_bottom_line_),de;{{122C:ed532bb7}} 
        ld      a,h               ;{{1230:7c}} 
        or      l                 ;{{1231:b5}} 
        jr      nz,_txt_win_enable_31;{{1232:2006}}  (+&06)
        ld      a,d               ;{{1234:7a}} 
        xor     b                 ;{{1235:a8}} 
        jr      nz,_txt_win_enable_31;{{1236:2002}}  (+&02)
        ld      a,e               ;{{1238:7b}} 
        xor     c                 ;{{1239:a9}} 
_txt_win_enable_31:               ;{{Addr=$123a Code Calls/jump count: 2 Data use count: 0}}
        ld      (RAM_b728),a      ;{{123A:3228b7}} 
        jp      _txt_set_cursor_1 ;{{123D:c37311}} ; undraw cursor, set cursor position and draw it

;;------------------------------------------------------------------
_txt_win_enable_33:               ;{{Addr=$1240 Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{1240:b7}} 
        jp      p,_txt_win_enable_36;{{1241:f24512}} 
        xor     a                 ;{{1244:af}} 
_txt_win_enable_36:               ;{{Addr=$1245 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{1245:b8}} 
        ret     c                 ;{{1246:d8}} 

        ld      a,b               ;{{1247:78}} 
        ret                       ;{{1248:c9}} 

_txt_win_enable_40:               ;{{Addr=$1249 Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{1249:b7}} 
        jp      p,_txt_win_enable_43;{{124A:f24e12}} 
        xor     a                 ;{{124D:af}} 
_txt_win_enable_43:               ;{{Addr=$124e Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{124E:b9}} 
        ret     c                 ;{{124F:d8}} 

        ld      a,c               ;{{1250:79}} 
        ret                       ;{{1251:c9}} 

;;===========================================================================
;; TXT GET WINDOW

TXT_GET_WINDOW:                   ;{{Addr=$1252 Code Calls/jump count: 3 Data use count: 1}}
        ld      hl,(window_top_line_);{{1252:2a29b7}} 
        ld      de,(window_bottom_line_);{{1255:ed5b2bb7}} 
        ld      a,(RAM_b728)      ;{{1259:3a28b7}} 
        add     a,$ff             ;{{125C:c6ff}} 
        ret                       ;{{125E:c9}} 

;;===========================================================================
;; IND: TXT UNDRAW CURSOR
IND_TXT_UNDRAW_CURSOR:            ;{{Addr=$125f Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(cursor_flag_)  ;{{125F:3a2eb7}} 
        and     $03               ;{{1262:e603}} 
        ret     nz                ;{{1264:c0}} 

;;===========================================================================
;; TXT PLACE CURSOR
;; TXT REMOVE CURSOR

TXT_PLACE_CURSOR:                 ;{{Addr=$1265 Code Calls/jump count: 1 Data use count: 4}}
        push    bc                ;{{1265:c5}} 
        push    de                ;{{1266:d5}} 
        push    hl                ;{{1267:e5}} 
        call    _scroll_window_1  ;{{1268:cda711}} 
        ld      bc,(current_PEN_number_);{{126B:ed4b2fb7}} 
        call    SCR_CHAR_INVERT   ;{{126F:cde50d}} ; SCR CHAR INVERT
        pop     hl                ;{{1272:e1}} 
        pop     de                ;{{1273:d1}} 
        pop     bc                ;{{1274:c1}} 
        ret                       ;{{1275:c9}} 

;;===========================================================================
;; TXT CUR ON

TXT_CUR_ON:                       ;{{Addr=$1276 Code Calls/jump count: 2 Data use count: 1}}
        push    af                ;{{1276:f5}} 
        ld      a,$fd             ;{{1277:3efd}} 
        call    _txt_cur_enable_1 ;{{1279:cd8812}} 
        pop     af                ;{{127C:f1}} 
        ret                       ;{{127D:c9}} 

;;===========================================================================
;; TXT CUR OFF

TXT_CUR_OFF:                      ;{{Addr=$127e Code Calls/jump count: 2 Data use count: 1}}
        push    af                ;{{127E:f5}} 
        ld      a,$02             ;{{127F:3e02}} 
        call    _txt_cur_disable_1;{{1281:cd9912}} 
        pop     af                ;{{1284:f1}} 
        ret                       ;{{1285:c9}} 

;;===========================================================================
;; TXT CUR ENABLE

TXT_CUR_ENABLE:                   ;{{Addr=$1286 Code Calls/jump count: 0 Data use count: 2}}
        ld      a,$fe             ;{{1286:3efe}} 
;;---------------------------------------------------------------------------
_txt_cur_enable_1:                ;{{Addr=$1288 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{1288:f5}} 
        call    TXT_UNDRAW_CURSOR ;{{1289:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{128C:f1}} 
        push    hl                ;{{128D:e5}} 
        ld      hl,cursor_flag_   ;{{128E:212eb7}} 
        and     (hl)              ;{{1291:a6}} 
        ld      (hl),a            ;{{1292:77}} 
        pop     hl                ;{{1293:e1}} 
        jp      TXT_DRAW_CURSOR   ;{{1294:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; TXT CUR DISABLE

TXT_CUR_DISABLE:                  ;{{Addr=$1297 Code Calls/jump count: 0 Data use count: 2}}
        ld      a,$01             ;{{1297:3e01}} 
;;---------------------------------------------------------------------------
_txt_cur_disable_1:               ;{{Addr=$1299 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{1299:f5}} 
        call    TXT_UNDRAW_CURSOR ;{{129A:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{129D:f1}} 
        push    hl                ;{{129E:e5}} 
        ld      hl,cursor_flag_   ;{{129F:212eb7}} 
        or      (hl)              ;{{12A2:b6}} 
        ld      (hl),a            ;{{12A3:77}} 
        pop     hl                ;{{12A4:e1}} 
        ret                       ;{{12A5:c9}} 

;;===========================================================================
;; TXT SET PEN 
TXT_SET_PEN_:                     ;{{Addr=$12a6 Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PEN_number_;{{12A6:212fb7}} 
        jr      _txt_set_paper_1  ;{{12A9:1803}}  (+&03)

;;===========================================================================
;; TXT SET PAPER
TXT_SET_PAPER:                    ;{{Addr=$12ab Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PAPER_number_;{{12AB:2130b7}} 
;;---------------------------------------------------------------------------
_txt_set_paper_1:                 ;{{Addr=$12ae Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12AE:f5}} 
        call    TXT_UNDRAW_CURSOR ;{{12AF:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{12B2:f1}} 
        call    SCR_INK_ENCODE    ;{{12B3:cd8e0c}} ; SCR INK ENCODE
        ld      (hl),a            ;{{12B6:77}} 
_txt_set_paper_6:                 ;{{Addr=$12b7 Code Calls/jump count: 1 Data use count: 0}}
        jp      TXT_DRAW_CURSOR   ;{{12B7:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; TXT GET PEN
TXT_GET_PEN:                      ;{{Addr=$12ba Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PEN_number_);{{12BA:3a2fb7}} 
        jp      SCR_INK_DECODE    ;{{12BD:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT GET PAPER
TXT_GET_PAPER:                    ;{{Addr=$12c0 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PAPER_number_);{{12C0:3a30b7}} 
        jp      SCR_INK_DECODE    ;{{12C3:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT INVERSE
TXT_INVERSE:                      ;{{Addr=$12c6 Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{12C6:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        ld      hl,(current_PEN_number_);{{12C9:2a2fb7}} 
        ld      a,h               ;{{12CC:7c}} 
        ld      h,l               ;{{12CD:65}} 
        ld      l,a               ;{{12CE:6f}} 
        ld      (current_PEN_number_),hl;{{12CF:222fb7}} 
        jr      _txt_set_paper_6  ;{{12D2:18e3}}  (-&1d)

;;===========================================================================
;; TXT GET MATRIX
TXT_GET_MATRIX:                   ;{{Addr=$12d4 Code Calls/jump count: 5 Data use count: 1}}
        push    de                ;{{12D4:d5}} 
        ld      e,a               ;{{12D5:5f}} 
        call    TXT_GET_M_TABLE   ;{{12D6:cd2b13}}  TXT GET M TABLE
        jr      nc,get_font_glyph_address;{{12D9:3009}}  get pointer to character graphics
        ld      d,a               ;{{12DB:57}} 
        ld      a,e               ;{{12DC:7b}} 
        sub     d                 ;{{12DD:92}} 
        ccf                       ;{{12DE:3f}} 
        jr      nc,get_font_glyph_address;{{12DF:3003}}  get pointer to character graphics
        ld      e,a               ;{{12E1:5f}} 
        jr      _get_font_glyph_address_1;{{12E2:1803}}  (+&03)

;;=============================================================
;; get font glyph address
;;
;; Entry conditions:
;; A = character code
;; Exit conditions:
;; HL = pointer to graphics for character

get_font_glyph_address:           ;{{Addr=$12e4 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,Font_graphics  ;{{12E4:210038}}  font graphics
_get_font_glyph_address_1:        ;{{Addr=$12e7 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12E7:f5}} 
        ld      d,$00             ;{{12E8:1600}} 
        ex      de,hl             ;{{12EA:eb}} 
        add     hl,hl             ;{{12EB:29}}  x2
        add     hl,hl             ;{{12EC:29}}  x4
        add     hl,hl             ;{{12ED:29}}  x8
        add     hl,de             ;{{12EE:19}} 
        pop     af                ;{{12EF:f1}} 
        pop     de                ;{{12F0:d1}} 
        ret                       ;{{12F1:c9}} 

;;===========================================================================
;; TXT SET MATRIX
TXT_SET_MATRIX:                   ;{{Addr=$12f2 Code Calls/jump count: 1 Data use count: 1}}
        ex      de,hl             ;{{12F2:eb}} 
        call    TXT_GET_MATRIX    ;{{12F3:cdd412}}  TXT GET MATRIX
        ret     nc                ;{{12F6:d0}} 

        ex      de,hl             ;{{12F7:eb}} 

;;---------------------------------------------------------------------------
_txt_set_matrix_4:                ;{{Addr=$12f8 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0008          ;{{12F8:010800}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{12FB:edb0}} 
        ret                       ;{{12FD:c9}} 

;;===========================================================================
;; TXT SET M TABLE
TXT_SET_M_TABLE:                  ;{{Addr=$12fe Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{12FE:e5}} 
        ld      a,d               ;{{12FF:7a}} 
        or      a                 ;{{1300:b7}} 
        ld      d,$00             ;{{1301:1600}} 
        jr      nz,_txt_set_m_table_23;{{1303:2019}}  (+&19)
        dec     d                 ;{{1305:15}} 
        push    de                ;{{1306:d5}} 
        ld      c,e               ;{{1307:4b}} 
        ex      de,hl             ;{{1308:eb}} 
_txt_set_m_table_9:               ;{{Addr=$1309 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{1309:79}} 
        call    TXT_GET_MATRIX    ;{{130A:cdd412}}  TXT GET MATRIX
        ld      a,h               ;{{130D:7c}} 
        xor     d                 ;{{130E:aa}} 
        jr      nz,_txt_set_m_table_17;{{130F:2004}}  (+&04)
        ld      a,l               ;{{1311:7d}} 
        xor     e                 ;{{1312:ab}} 
        jr      z,_txt_set_m_table_22;{{1313:2808}}  (+&08)
_txt_set_m_table_17:              ;{{Addr=$1315 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{1315:c5}} 
        call    _txt_set_matrix_4 ;{{1316:cdf812}} 
        pop     bc                ;{{1319:c1}} 
        inc     c                 ;{{131A:0c}} 
        jr      nz,_txt_set_m_table_9;{{131B:20ec}}  (-&14)
_txt_set_m_table_22:              ;{{Addr=$131d Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{131D:d1}} 
_txt_set_m_table_23:              ;{{Addr=$131e Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_M_TABLE   ;{{131E:cd2b13}}  TXT GET M TABLE
        ld      (ASCII_number_of_the_first_character_in_U),de;{{1321:ed5334b7}} 
        pop     de                ;{{1325:d1}} 
        ld      (address_of_UDG_matrix_table),de;{{1326:ed5336b7}} 
        ret                       ;{{132A:c9}} 

;;===========================================================================
;; TXT GET M TABLE
TXT_GET_M_TABLE:                  ;{{Addr=$132b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,(ASCII_number_of_the_first_character_in_U);{{132B:2a34b7}} 
        ld      a,h               ;{{132E:7c}} 
        rrca                      ;{{132F:0f}} 
        ld      a,l               ;{{1330:7d}} 
        ld      hl,(address_of_UDG_matrix_table);{{1331:2a36b7}} 
        ret                       ;{{1334:c9}} 

;;===========================================================================
;; TXT WR CHAR

TXT_WR_CHAR:                      ;{{Addr=$1335 Code Calls/jump count: 3 Data use count: 2}}
        ld      b,a               ;{{1335:47}} 
        ld      a,(cursor_flag_)  ;{{1336:3a2eb7}} 
        rlca                      ;{{1339:07}} 
        ret     c                 ;{{133A:d8}} 

        push    bc                ;{{133B:c5}} 
        call    scroll_window     ;{{133C:cda411}} 
        inc     h                 ;{{133F:24}} 
        ld      (Current_Stream_),hl;{{1340:2226b7}} 
        dec     h                 ;{{1343:25}} 
        pop     af                ;{{1344:f1}} 
        call    TXT_WRITE_CHAR    ;{{1345:cdd3bd}} ; IND: TXT WRITE CURSOR
        jp      TXT_DRAW_CURSOR   ;{{1348:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; IND: TXT WRITE CHAR
IND_TXT_WRITE_CHAR:               ;{{Addr=$134b Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{134B:e5}} 
        call    TXT_GET_MATRIX    ;{{134C:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{134F:1138b7}} 
        push    de                ;{{1352:d5}} 
        call    SCR_UNPACK        ;{{1353:cdf90e}}  SCR UNPACK
        pop     de                ;{{1356:d1}} 
        pop     hl                ;{{1357:e1}} 
        call    SCR_CHAR_POSITION ;{{1358:cd6a0b}}  SCR CHAR POSITION
        ld      c,$08             ;{{135B:0e08}} 
_ind_txt_write_char_9:            ;{{Addr=$135d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135D:c5}} 
        push    hl                ;{{135E:e5}} 
_ind_txt_write_char_11:           ;{{Addr=$135f Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135F:c5}} 
        push    de                ;{{1360:d5}} 
        ex      de,hl             ;{{1361:eb}} 
        ld      c,(hl)            ;{{1362:4e}} 
        call    _ind_txt_write_char_27;{{1363:cd7713}} 
        call    SCR_NEXT_BYTE     ;{{1366:cd050c}}  SCR NEXT BYTE
        pop     de                ;{{1369:d1}} 
        inc     de                ;{{136A:13}} 
        pop     bc                ;{{136B:c1}} 
        djnz    _ind_txt_write_char_11;{{136C:10f1}}  (-&0f)
        pop     hl                ;{{136E:e1}} 
        call    SCR_NEXT_LINE     ;{{136F:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{1372:c1}} 
        dec     c                 ;{{1373:0d}} 
        jr      nz,_ind_txt_write_char_9;{{1374:20e7}}  (-&19)
        ret                       ;{{1376:c9}} 

;;------------------------------------------------------------------
_ind_txt_write_char_27:           ;{{Addr=$1377 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_text_background_routine_opaq);{{1377:2a31b7}} 
        jp      (hl)              ;{{137A:e9}} 
;;===========================================================================
;; TXT SET BACK
TXT_SET_BACK:                     ;{{Addr=$137b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,write_opaque   ;{{137B:219213}} ##LABEL##
        or      a                 ;{{137E:b7}} 
        jr      z,_txt_set_back_4 ;{{137F:2803}}  (+&03)
        ld      hl,write_transparent;{{1381:21a013}} ##LABEL##
_txt_set_back_4:                  ;{{Addr=$1384 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_text_background_routine_opaq),hl;{{1384:2231b7}} 
        ret                       ;{{1387:c9}} 

;;===========================================================================
;; TXT GET BACK
TXT_GET_BACK:                     ;{{Addr=$1388 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_text_background_routine_opaq);{{1388:2a31b7}} 
        ld      de,$10000 - write_opaque;{{138B:116eec}} ;was &ec6e ##LABEL##
        add     hl,de             ;{{138E:19}} 
        ld      a,h               ;{{138F:7c}} 
        or      l                 ;{{1390:b5}} 
        ret                       ;{{1391:c9}} 
;;===========================================================================
;;write opaque
write_opaque:                     ;{{Addr=$1392 Code Calls/jump count: 0 Data use count: 2}}
        ld      hl,(current_PEN_number_);{{1392:2a2fb7}} 
        ld      a,c               ;{{1395:79}} 
        cpl                       ;{{1396:2f}} 
        and     h                 ;{{1397:a4}} 
        ld      b,a               ;{{1398:47}} 
        ld      a,c               ;{{1399:79}} 
        and     l                 ;{{139A:a5}} 
        or      b                 ;{{139B:b0}} 
        ld      c,$ff             ;{{139C:0eff}} 
        jr      _write_transparent_1;{{139E:1803}}  (+&03)

;;===========================================================================
;;write transparent
write_transparent:                ;{{Addr=$13a0 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(current_PEN_number_);{{13A0:3a2fb7}} 
;;---------------------------------------------------------------------------
_write_transparent_1:             ;{{Addr=$13a3 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{13A3:47}} 
        ex      de,hl             ;{{13A4:eb}} 
        jp      SCR_PIXELS        ;{{13A5:c3740c}}  SCR PIXELS

;;===========================================================================
;; TXT SET GRAPHIC

TXT_SET_GRAPHIC:                  ;{{Addr=$13a8 Code Calls/jump count: 1 Data use count: 1}}
        ld      (graphics_character_writing_flag_),a;{{13A8:3233b7}} 
        ret                       ;{{13AB:c9}} 

;;===========================================================================
;; TXT RD CHAR

TXT_RD_CHAR:                      ;{{Addr=$13ac Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{13AC:e5}} 
        push    de                ;{{13AD:d5}} 
        push    bc                ;{{13AE:c5}} 
        call    scroll_window     ;{{13AF:cda411}} 
        call    TXT_UNWRITE       ;{{13B2:cdd6bd}}  IND: TXT UNWRITE
        push    af                ;{{13B5:f5}} 
        call    TXT_DRAW_CURSOR   ;{{13B6:cdcdbd}}  IND: TXT DRAW CURSOR
        pop     af                ;{{13B9:f1}} 
        pop     bc                ;{{13BA:c1}} 
        pop     de                ;{{13BB:d1}} 
        pop     hl                ;{{13BC:e1}} 
        ret                       ;{{13BD:c9}} 

;;===========================================================================
;; IND: TXT UNWRITE

IND_TXT_UNWRITE:                  ;{{Addr=$13be Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{13BE:3a30b7}} 
        ld      de,RAM_b738       ;{{13C1:1138b7}} 
        push    hl                ;{{13C4:e5}} 
        push    de                ;{{13C5:d5}} 
        call    SCR_REPACK        ;{{13C6:cd2a0f}}  SCR REPACK
        pop     de                ;{{13C9:d1}} 
        push    de                ;{{13CA:d5}} 
        ld      b,$08             ;{{13CB:0608}} 
_ind_txt_unwrite_8:               ;{{Addr=$13cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13CD:1a}} 
        cpl                       ;{{13CE:2f}} 
        ld      (de),a            ;{{13CF:12}} 
        inc     de                ;{{13D0:13}} 
        djnz    _ind_txt_unwrite_8;{{13D1:10fa}}  (-&06)
        call    _ind_txt_unwrite_20;{{13D3:cde113}} 
        pop     de                ;{{13D6:d1}} 
        pop     hl                ;{{13D7:e1}} 
        jr      nc,_ind_txt_unwrite_18;{{13D8:3001}}  (+&01)
        ret     nz                ;{{13DA:c0}} 

_ind_txt_unwrite_18:              ;{{Addr=$13db Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PEN_number_);{{13DB:3a2fb7}} 
        call    SCR_REPACK        ;{{13DE:cd2a0f}}  SCR REPACK
_ind_txt_unwrite_20:              ;{{Addr=$13e1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$00             ;{{13E1:0e00}} 
_ind_txt_unwrite_21:              ;{{Addr=$13e3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{13E3:79}} 
        call    TXT_GET_MATRIX    ;{{13E4:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{13E7:1138b7}} 
        ld      b,$08             ;{{13EA:0608}} 
_ind_txt_unwrite_25:              ;{{Addr=$13ec Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13EC:1a}} 
        cp      (hl)              ;{{13ED:be}} 
        jr      nz,_ind_txt_unwrite_35;{{13EE:2009}}  (+&09)
        inc     hl                ;{{13F0:23}} 
        inc     de                ;{{13F1:13}} 
        djnz    _ind_txt_unwrite_25;{{13F2:10f8}}  (-&08)
        ld      a,c               ;{{13F4:79}} 
        cp      $8f               ;{{13F5:fe8f}} 
        scf                       ;{{13F7:37}} 
        ret                       ;{{13F8:c9}} 

_ind_txt_unwrite_35:              ;{{Addr=$13f9 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{13F9:0c}} 
        jr      nz,_ind_txt_unwrite_21;{{13FA:20e7}}  (-&19)
        xor     a                 ;{{13FC:af}} 
        ret                       ;{{13FD:c9}} 

;;===========================================================================
;; TXT OUTPUT

TXT_OUTPUT:                       ;{{Addr=$13fe Code Calls/jump count: 5 Data use count: 1}}
        push    af                ;{{13FE:f5}} 
        push    bc                ;{{13FF:c5}} 
        push    de                ;{{1400:d5}} 
        push    hl                ;{{1401:e5}} 
        call    TXT_OUT_ACTION    ;{{1402:cdd9bd}}  IND: TXT OUT ACTION
        pop     hl                ;{{1405:e1}} 
        pop     de                ;{{1406:d1}} 
        pop     bc                ;{{1407:c1}} 
        pop     af                ;{{1408:f1}} 
        ret                       ;{{1409:c9}} 

;;===========================================================================
;; IND: TXT OUT ACTION

IND_TXT_OUT_ACTION:               ;{{Addr=$140a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{140A:4f}} 
        ld      a,(graphics_character_writing_flag_);{{140B:3a33b7}} 
        or      a                 ;{{140E:b7}} 
        ld      a,c               ;{{140F:79}} 
        jp      nz,GRA_WR_CHAR    ;{{1410:c24019}}  GRA WR CHAR

        ld      hl,RAM_b758       ;{{1413:2158b7}} 
        ld      b,(hl)            ;{{1416:46}} 
        ld      a,b               ;{{1417:78}} 
        cp      $0a               ;{{1418:fe0a}} 
        jr      nc,_ind_txt_out_action_42;{{141A:3031}}  (+&31)
        or      a                 ;{{141C:b7}} 
        jr      nz,_ind_txt_out_action_15;{{141D:2006}}  (+&06)
        ld      a,c               ;{{141F:79}} 
        cp      $20               ;{{1420:fe20}} 
        jp      nc,TXT_WR_CHAR    ;{{1422:d23513}}  TXT WR CHAR
_ind_txt_out_action_15:           ;{{Addr=$1425 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{1425:04}} 
        ld      (hl),b            ;{{1426:70}} 
        ld      e,b               ;{{1427:58}} 
        ld      d,$00             ;{{1428:1600}} 
        add     hl,de             ;{{142A:19}} 
        ld      (hl),c            ;{{142B:71}} 


;; b759 = control code character
        ld      a,(RAM_b759)      ;{{142C:3a59b7}} 
        ld      e,a               ;{{142F:5f}} 

;; start of control code table in RAM
;; each entry is 3 bytes
        ld      hl,ASC_0_801513_NUL;{{1430:2163b7}} 
;; this effectively multiplies E by 3
;; and adds it onto the base address of the table

        add     hl,de             ;{{1433:19}} 
        add     hl,de             ;{{1434:19}} 
        add     hl,de             ;{{1435:19}} ; 3 bytes per entry

        ld      a,(hl)            ;{{1436:7e}} 
        and     $0f               ;{{1437:e60f}} 
        cp      b                 ;{{1439:b8}} 
        ret     nc                ;{{143A:d0}} 

        ld      a,(cursor_flag_)  ;{{143B:3a2eb7}} 
        and     (hl)              ;{{143E:a6}} 
        rlca                      ;{{143F:07}} 
        jr      c,_ind_txt_out_action_42;{{1440:380b}}  (+&0b)

        inc     hl                ;{{1442:23}} 
        ld      e,(hl)            ;{{1443:5e}} ; function to execute
        inc     hl                ;{{1444:23}} 
        ld      d,(hl)            ;{{1445:56}} 
        ld      hl,RAM_b759       ;{{1446:2159b7}} 
        ld      a,c               ;{{1449:79}} 
        call    LOW_PCDE_INSTRUCTION;{{144A:cd1600}}  LOW: PCDE INSTRUCTION
_ind_txt_out_action_42:           ;{{Addr=$144d Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{144D:af}} 
        ld      (RAM_b758),a      ;{{144E:3258b7}} 
        ret                       ;{{1451:c9}} 

;;===========================================================================
;; TXT VDU DISABLE

TXT_VDU_DISABLE:                  ;{{Addr=$1452 Code Calls/jump count: 0 Data use count: 2}}
        ld      a,$81             ;{{1452:3e81}} 
        call    _txt_cur_disable_1;{{1454:cd9912}} 
        jr      _ind_txt_out_action_42;{{1457:18f4}}  (-&0c)

;;===========================================================================
;; TXT VDU ENABLE

TXT_VDU_ENABLE:                   ;{{Addr=$1459 Code Calls/jump count: 1 Data use count: 2}}
        ld      a,$7e             ;{{1459:3e7e}} 
        call    _txt_cur_enable_1 ;{{145B:cd8812}} 
        jr      _ind_txt_out_action_42;{{145E:18ed}}  (-&13)

;;===========================================================================
;; TXT ASK STATE

TXT_ASK_STATE:                    ;{{Addr=$1460 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(cursor_flag_)  ;{{1460:3a2eb7}} 
        ret                       ;{{1463:c9}} 

;;===========================================================================
;; initialise control code functions
initialise_control_code_functions:;{{Addr=$1464 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{1464:af}} 
        ld      (RAM_b758),a      ;{{1465:3258b7}} 

        ld      hl,control_code_handler_functions;{{1468:217414}} 
        ld      de,ASC_0_801513_NUL;{{146B:1163b7}} 
        ld      bc,$0060          ;{{146E:016000}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1471:edb0}} 
        ret                       ;{{1473:c9}} 

;;===========================================================================
;; control code handler functions
;; (see SOFT968	for a description of the control character operations)

;; byte 0: bits 3..0: number of parameters expected
;; byte 1,2: handler function

control_code_handler_functions:   ;{{Addr=$1474 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $80                  
        defw performs_control_character_NUL_function; NUL: ##LABEL##
        defb $81                  
        defw TXT_WR_CHAR          ; SOH: firmware function: TXT WR CHAR ##LABEL##
        defb $80                  
        defw TXT_CUR_DISABLE      ; STX: firmware function: TXT CUR DISABLE ##LABEL##
        defb $80                  
        defw TXT_CUR_ENABLE       ; ETX: firmware function: TXT CUR ENABLE ##LABEL##
        defb $81                  
        defw SCR_SET_MODE         ; EOT: firmware function: SCR SET MODE ##LABEL##
        defb $81                  
        defw GRA_WR_CHAR          ; ENQ: firmware function: GRA WR CHAR ##LABEL##
        defb $00                  
        defw TXT_VDU_ENABLE       ; ACK: firmware function: TXT VDU ENABLE ##LABEL##
        defb $80                  
        defw performs_control_character_BEL_function; BEL: ##LABEL##
        defb $80                  
        defw performs_control_character_BS_function; BS: ##LABEL##
        defb $80                  
        defw performs_control_character_TAB_function; TAB: ##LABEL##
        defb $80                  
        defw performs_control_character_LF_function; LF: ##LABEL##
        defb $80                  
        defw performs_control_character_VT_function; VT: ##LABEL##
        defb $80                  
        defw TXT_CLEAR_WINDOW     ; FF: firmware function: TXT CLEAR WINDOW ##LABEL##
        defb $80                  
        defw performs_control_character_CR_function; CR: ##LABEL##
        defb $81                  
        defw TXT_SET_PAPER        ; SO: firmware function: TXT SET PAPER ##LABEL##
        defb $81                  
        defw TXT_SET_PEN_         ; SI: firmware function: TXT SET PEN ##LABEL##
        defb $80                  
        defw performs_control_character_DLE_function; DLE: ##LABEL##
        defb $80                  
        defw performs_control_character_DC1_function; DC1: ##LABEL##
        defb $80                  
        defw performs_control_character_DC2_function; DC2: ##LABEL##
        defb $80                  
        defw performs_control_character_DC3_function; DC3: ##LABEL##
        defb $80                  
        defw performs_control_character_DC4_function; DC4: ##LABEL##
        defb $80                  
        defw TXT_VDU_DISABLE      ; NAK: firmware function: TXT VDU DISABLE ##LABEL##
        defb $81                  
        defw performs_control_character_SYN_function; SYN: ##LABEL##
        defb $81                  
        defw SCR_ACCESS           ; ETB: firmware function: SCR ACCESS ##LABEL##
        defb $80                  
        defw TXT_INVERSE          ; CAN: firmware function: TXT INVERSE ##LABEL##
        defb $89                  
        defw performs_control_character_EM_function; EM: ##LABEL##
        defb $84                  
        defw performs_control_character_SUB_function; SUB: ##LABEL##
        defb $00                  
        defw performs_control_character_ESC_function; ESC ##LABEL##
        defb $83                  
        defw performs_control_character_FS_function; FS: ##LABEL##
        defb $82                  
        defw performs_control_character_GS_instruction; GS: ##LABEL##
        defb $80                  
        defw performs_control_character_RS_function; RS: ##LABEL##
        defb $82                  
        defw performs_control_character_US_function; US: ##LABEL##

;;=============================================================================
;; TXT GET CONTROLS
TXT_GET_CONTROLS:                 ;{{Addr=$14d4 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,ASC_0_801513_NUL;{{14D4:2163b7}} 
        ret                       ;{{14D7:c9}} 

;;=============================================================================
;; data for control character 'BEL' sound
data_for_control_character_BEL_sound:;{{Addr=$14d8 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $87                  ; channel status byte
        defb $00                  ; volume envelope to use
        defb $00                  ; tone envelope to use
        defb $5a                  ; tone period low
        defb $00                  ; tone period high
        defb $00                  ; noise period
        defb $0b                  ; start volume
        defb $14                  ; envelope repeat count low
        defb $00                  ; envelope repeat count high

;;=============================================================================
;; performs control character 'BEL' function
performs_control_character_BEL_function:;{{Addr=$14e1 Code Calls/jump count: 0 Data use count: 1}}
        push    ix                ;{{14E1:dde5}} 
        ld      hl,data_for_control_character_BEL_sound;{{14E3:21d814}}  
        call    SOUND_QUEUE       ;{{14E6:cd1421}}  SOUND QUEUE
        pop     ix                ;{{14E9:dde1}} 

;;=============================================================================
;;performs control character 'ESC' function
performs_control_character_ESC_function:;{{Addr=$14eb Code Calls/jump count: 0 Data use count: 1}}
        ret                       ;{{14EB:c9}} 

;;=============================================================================
;; performs control character 'SYN' function
performs_control_character_SYN_function:;{{Addr=$14ec Code Calls/jump count: 0 Data use count: 1}}
        rrca                      ;{{14EC:0f}} 
        sbc     a,a               ;{{14ED:9f}} 
        jp      TXT_SET_BACK      ;{{14EE:c37b13}}  TXT SET BACK

;;=============================================================================
;; performs control character 'FS' function
performs_control_character_FS_function:;{{Addr=$14f1 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14F1:23}} 
        ld      a,(hl)            ;{{14F2:7e}}  pen number
        inc     hl                ;{{14F3:23}} 
        ld      b,(hl)            ;{{14F4:46}}  ink 1
        inc     hl                ;{{14F5:23}} 
        ld      c,(hl)            ;{{14F6:4e}}  ink 2
        jp      SCR_SET_INK       ;{{14F7:c3f20c}}  SCR SET INK

;;====================================================================
;; performs control character 'GS' instruction
performs_control_character_GS_instruction:;{{Addr=$14fa Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14FA:23}} 
        ld      b,(hl)            ;{{14FB:46}}  ink 1
        inc     hl                ;{{14FC:23}} 
        ld      c,(hl)            ;{{14FD:4e}}  ink 2
        jp      SCR_SET_BORDER    ;{{14FE:c3f70c}}  SCR SET BORDER

;;====================================================================
;; performs control character 'SUB' function
performs_control_character_SUB_function:;{{Addr=$1501 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{1501:23}} 
        ld      d,(hl)            ;{{1502:56}}  left column
        inc     hl                ;{{1503:23}} 
        ld      a,(hl)            ;{{1504:7e}}  right column
        inc     hl                ;{{1505:23}} 
        ld      e,(hl)            ;{{1506:5e}}  top row
        inc     hl                ;{{1507:23}} 
        ld      l,(hl)            ;{{1508:6e}}  bottom row
        ld      h,a               ;{{1509:67}} 
        jp      TXT_WIN_ENABLE    ;{{150A:c30812}}  TXT WIN ENABLE

;;====================================================================
;; performs control character 'EM' function
performs_control_character_EM_function:;{{Addr=$150d Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{150D:23}} 
        ld      a,(hl)            ;{{150E:7e}}  character index
        inc     hl                ;{{150F:23}} 
        jp      TXT_SET_MATRIX    ;{{1510:c3f212}}  TXT SET MATRIX

;;====================================================================
;; performs control character 'NUL' function
performs_control_character_NUL_function:;{{Addr=$1513 Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{1513:cda411}} 
        jp      TXT_DRAW_CURSOR   ;{{1516:c3cdbd}}  IND: TXT DRAW CURSOR

;;====================================================================
;; performs control character 'BS' function
performs_control_character_BS_function:;{{Addr=$1519 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$ff00          ;{{1519:1100ff}} 
        jr      _performs_control_character_vt_function_1;{{151C:180d}}  (+&0d)

;;====================================================================
;; performs control character 'TAB' function
performs_control_character_TAB_function:;{{Addr=$151e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0100          ;{{151E:110001}} ##LIT##;WARNING: Code area used as literal
        jr      _performs_control_character_vt_function_1;{{1521:1808}}  (+&08)

;;====================================================================
;; performs control character 'LF' function
performs_control_character_LF_function:;{{Addr=$1523 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0001          ;{{1523:110100}} ##LIT##;WARNING: Code area used as literal
        jr      _performs_control_character_vt_function_1;{{1526:1803}}  (+&03)

;;====================================================================
;; performs control character 'VT' function
performs_control_character_VT_function:;{{Addr=$1528 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$00ff          ;{{1528:11ff00}} ##LIT##;WARNING: Code area used as literal

;;--------------------------------------------------------------------
;; D = column adjustment
;; E = row adjustment
_performs_control_character_vt_function_1:;{{Addr=$152b Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{152B:d5}} 
        call    scroll_window     ;{{152C:cda411}} 
        pop     de                ;{{152F:d1}} 

;; adjust row 
        ld      a,l               ;{{1530:7d}} 
        add     a,e               ;{{1531:83}} 
        ld      l,a               ;{{1532:6f}} 

;; adjust column
        ld      a,h               ;{{1533:7c}} 
        add     a,d               ;{{1534:82}} 
_performs_control_character_vt_function_9:;{{Addr=$1535 Code Calls/jump count: 1 Data use count: 0}}
        ld      h,a               ;{{1535:67}} 

        jp      _txt_set_cursor_2 ;{{1536:c37611}}  set cursor position and draw it

;;====================================================================
;; performs control character 'RS' function
performs_control_character_RS_function:;{{Addr=$1539 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(window_top_line_);{{1539:2a29b7}} 
        jp      _txt_set_cursor_1 ;{{153C:c37311}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; performs control character 'CR' function
performs_control_character_CR_function:;{{Addr=$153f Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{153F:cda411}} 
        ld      a,(window_left_column_);{{1542:3a2ab7}} 
        jr      _performs_control_character_vt_function_9;{{1545:18ee}}  (-&12)

;;===========================================================================
;; performs control character 'US' function
performs_control_character_US_function:;{{Addr=$1547 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{1547:23}} 
        ld      d,(hl)            ;{{1548:56}}  column
        inc     hl                ;{{1549:23}} 
        ld      e,(hl)            ;{{154A:5e}}  row
        ex      de,hl             ;{{154B:eb}} 
        jp      TXT_SET_CURSOR    ;{{154C:c37011}}  TXT SET CURSOR

;;===========================================================================
;; TXT CLEAR WINDOW

TXT_CLEAR_WINDOW:                 ;{{Addr=$154f Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{154F:cdd0bd}}  IND: TXT UNDRAW CURSOR
        ld      hl,(window_top_line_);{{1552:2a29b7}} 
        ld      (Current_Stream_),hl;{{1555:2226b7}} 
        ld      de,(window_bottom_line_);{{1558:ed5b2bb7}} 
        jr      _performs_control_character_dc1_function_5;{{155C:1844}}  (+&44)

;;===========================================================================
;; performs control character 'DLE' function
performs_control_character_DLE_function:;{{Addr=$155e Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{155E:cda411}} 
        ld      d,h               ;{{1561:54}} 
        ld      e,l               ;{{1562:5d}} 
        jr      _performs_control_character_dc1_function_5;{{1563:183d}}  (+&3d)

;;===========================================================================
;; performs control character 'DC4' function
performs_control_character_DC4_function:;{{Addr=$1565 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC2_function;{{1565:cd8f15}}  control character 'DC2'
        ld      hl,(window_top_line_);{{1568:2a29b7}} 
        ld      de,(window_bottom_line_);{{156B:ed5b2bb7}} 
        ld      a,(Current_Stream_);{{156F:3a26b7}} 
        ld      l,a               ;{{1572:6f}} 
        inc     l                 ;{{1573:2c}} 
        cp      e                 ;{{1574:bb}} 
        ret     nc                ;{{1575:d0}} 

        jr      _performs_control_character_dc3_function_9;{{1576:1811}}  (+&11)

;;===========================================================================
;; performs control character 'DC3' function
performs_control_character_DC3_function:;{{Addr=$1578 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC1_function;{{1578:cd9915}}  control character 'DC1' function
        ld      hl,(window_top_line_);{{157B:2a29b7}} 
        ld      a,(window_right_colwnn_);{{157E:3a2cb7}} 
        ld      d,a               ;{{1581:57}} 
        ld      a,(Current_Stream_);{{1582:3a26b7}} 
        dec     a                 ;{{1585:3d}} 
        ld      e,a               ;{{1586:5f}} 
        cp      l                 ;{{1587:bd}} 
        ret     c                 ;{{1588:d8}} 

_performs_control_character_dc3_function_9:;{{Addr=$1589 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{1589:3a30b7}} 
        jp      SCR_FILL_BOX      ;{{158C:c3b90d}}  SCR FILL BOX

;;===========================================================================
;; performs control character 'DC2' function
performs_control_character_DC2_function:;{{Addr=$158f Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{158F:cda411}} 
        ld      e,l               ;{{1592:5d}} 
        ld      a,(window_right_colwnn_);{{1593:3a2cb7}} 
        ld      d,a               ;{{1596:57}} 
        jr      _performs_control_character_dc1_function_5;{{1597:1809}}  (+&09)

;;===========================================================================
;; performs control character 'DC1' function
performs_control_character_DC1_function:;{{Addr=$1599 Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{1599:cda411}} 
        ex      de,hl             ;{{159C:eb}} 
        ld      l,e               ;{{159D:6b}} 
        ld      a,(window_left_column_);{{159E:3a2ab7}} 
        ld      h,a               ;{{15A1:67}} 

;;---------------------------------------------------------------------------
_performs_control_character_dc1_function_5:;{{Addr=$15a2 Code Calls/jump count: 3 Data use count: 0}}
        call    _performs_control_character_dc3_function_9;{{15A2:cd8915}} 
        jp      TXT_DRAW_CURSOR   ;{{15A5:c3cdbd}}  IND: TXT DRAW CURSOR




;;***Graphics.asm
;; GRAPHICS ROUTINES
;;===========================================================================
;; GRA INITIALISE
GRA_INITIALISE:                   ;{{Addr=$15a8 Code Calls/jump count: 1 Data use count: 1}}
        call    GRA_RESET         ;{{15A8:cdd715}}  GRA RESET
        ld      hl,$0001          ;{{15AB:210100}} ##LIT##;WARNING: Code area used as literal
_gra_initialise_2:                ;{{Addr=$15ae Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{15AE:7c}} 
        call    GRA_SET_PAPER     ;{{15AF:cd6e17}}  GRA SET PAPER
        ld      a,l               ;{{15B2:7d}} 
        call    GRA_SET_PEN       ;{{15B3:cd6717}}  GRA SET PEN
        ld      hl,$0000          ;{{15B6:210000}} ##LIT##;WARNING: Code area used as literal
        ld      d,h               ;{{15B9:54}} 
        ld      e,l               ;{{15BA:5d}} 
        call    GRA_SET_ORIGIN    ;{{15BB:cd0e16}}  GRA SET ORIGIN
        ld      de,$8000          ;{{15BE:110080}} 
        ld      hl,$7fff          ;{{15C1:21ff7f}} 
        push    hl                ;{{15C4:e5}} 
        push    de                ;{{15C5:d5}} 
        call    GRA_WIN_WIDTH     ;{{15C6:cda516}}  GRA WIN WIDTH
        pop     hl                ;{{15C9:e1}} 
        pop     de                ;{{15CA:d1}} 
        jp      GRA_WIN_HEIGHT    ;{{15CB:c3ea16}}  GRA WIN HEIGHT
;;===========================================================================

x15CE_code:                       ;{{Addr=$15ce Code Calls/jump count: 1 Data use count: 0}}
        call    GRA_GET_PAPER     ;{{15CE:cd7a17}}  GRA GET PAPER
        ld      h,a               ;{{15D1:67}} 
        call    GRA_GET_PEN       ;{{15D2:cd7517}}  GRA GET PEN
        ld      l,a               ;{{15D5:6f}} 
        ret                       ;{{15D6:c9}} 

;;===========================================================================
;; GRA RESET
GRA_RESET:                        ;{{Addr=$15d7 Code Calls/jump count: 1 Data use count: 1}}
        call    _gra_default_2    ;{{15D7:cdf015}} 
        ld      hl,_gra_reset_3   ;{{15DA:21e015}} ; table used to initialise graphics pack indirections
        jp      initialise_firmware_indirections;{{15DD:c3b40a}} ; initialise graphics pack indirections

_gra_reset_3:                     ;{{Addr=$15e0 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $09                  
        defw GRA_PLOT                
        jp      IND_GRA_PLOT      ; IND: GRA PLOT
        jp      IND_GRA_TEXT      ; IND: GRA TEXT
        jp      IND_GRA_LINE      ; IND: GRA LINE

;;===========================================================================
;; GRA DEFAULT

GRA_DEFAULT:                      ;{{Addr=$15ec Code Calls/jump count: 0 Data use count: 1}}
        xor     a                 ;{{15EC:af}} 
        call    SCR_ACCESS        ;{{15ED:cd550c}}  SCR ACCESS

_gra_default_2:                   ;{{Addr=$15f0 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{15F0:af}} 
        call    GRA_SET_BACK      ;{{15F1:cdd519}}  GRA SET BACK
        cpl                       ;{{15F4:2f}} 
        call    GRA_SET_FIRST     ;{{15F5:cdb017}}  GRA SET FIRST
        jp      GRA_SET_LINE_MASK ;{{15F8:c3ac17}}  GRA SET LINE MASK

;;===========================================================================
;; GRA MOVE RELATIVE
GRA_MOVE_RELATIVE:                ;{{Addr=$15fb Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{15FB:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate


;;==========================================================================
;; GRA MOVE ABSOLUTE
GRA_MOVE_ABSOLUTE:                ;{{Addr=$15fe Code Calls/jump count: 3 Data use count: 1}}
        ld      (graphics_text_x_position_),de;{{15FE:ed5397b6}}  absolute x
        ld      (graphics_text_y_position),hl;{{1602:2299b6}}  absolute y
        ret                       ;{{1605:c9}} 

;;===========================================================================
;; GRA ASK CURSOR
GRA_ASK_CURSOR:                   ;{{Addr=$1606 Code Calls/jump count: 2 Data use count: 1}}
        ld      de,(graphics_text_x_position_);{{1606:ed5b97b6}}  absolute x
        ld      hl,(graphics_text_y_position);{{160A:2a99b6}}  absolute y
        ret                       ;{{160D:c9}} 

;;===========================================================================
;; GRA SET ORIGIN
GRA_SET_ORIGIN:                   ;{{Addr=$160e Code Calls/jump count: 1 Data use count: 1}}
        ld      (ORIGIN_x),de     ;{{160E:ed5393b6}}  origin x
        ld      (ORIGIN_y),hl     ;{{1612:2295b6}}  origin y


;;===========================================================================
;; set absolute position to origin
set_absolute_position_to_origin:  ;{{Addr=$1615 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0000          ;{{1615:110000}}  x = 0 ##LIT##;WARNING: Code area used as literal
        ld      h,d               ;{{1618:62}} 
        ld      l,e               ;{{1619:6b}}  y = 0
        jr      GRA_MOVE_ABSOLUTE ;{{161A:18e2}}  GRA MOVE ABSOLUTE

;;===========================================================================
;; GRA GET ORIGIN
GRA_GET_ORIGIN:                   ;{{Addr=$161c Code Calls/jump count: 0 Data use count: 1}}
        ld      de,(ORIGIN_x)     ;{{161C:ed5b93b6}}  origin x	
        ld      hl,(ORIGIN_y)     ;{{1620:2a95b6}}  origin y
        ret                       ;{{1623:c9}} 

;;===========================================================================
;; get cursor absolute user coordinate
get_cursor_absolute_user_coordinate:;{{Addr=$1624 Code Calls/jump count: 3 Data use count: 0}}
        call    GRA_ASK_CURSOR    ;{{1624:cd0616}}  GRA ASK CURSOR

;;----------------------------------------------------------------------------
;; get absolute user coordinate
_get_cursor_absolute_user_coordinate_1:;{{Addr=$1627 Code Calls/jump count: 2 Data use count: 0}}
        call    GRA_MOVE_ABSOLUTE ;{{1627:cdfe15}}  GRA MOVE ABSOLUTE

;;===========================================================================
;; GRA FROM USER
;; DE = X user coordinate
;; HL = Y user coordinate
;; out:
;; DE = x base coordinate
;; HL = y base coordinate
GRA_FROM_USER:                    ;{{Addr=$162a Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{162A:e5}} 
        call    SCR_GET_MODE      ;{{162B:cd0c0b}}  SCR GET MODE
        neg                       ;{{162E:ed44}} 
        sbc     a,$fd             ;{{1630:defd}} 
        ld      h,$00             ;{{1632:2600}} 
        ld      l,a               ;{{1634:6f}} 
        bit     7,d               ;{{1635:cb7a}} 
        jr      z,_gra_from_user_11;{{1637:2803}}  (+&03)
        ex      de,hl             ;{{1639:eb}} 
        add     hl,de             ;{{163A:19}} 
        ex      de,hl             ;{{163B:eb}} 
_gra_from_user_11:                ;{{Addr=$163c Code Calls/jump count: 1 Data use count: 0}}
        cpl                       ;{{163C:2f}} 
        and     e                 ;{{163D:a3}} 
        ld      e,a               ;{{163E:5f}} 
        ld      a,l               ;{{163F:7d}} 
        ld      hl,(ORIGIN_x)     ;{{1640:2a93b6}}  origin x
        add     hl,de             ;{{1643:19}} 
        rrca                      ;{{1644:0f}} 
        call    c,HL_div_2        ;{{1645:dce516}}  HL = HL/2
        rrca                      ;{{1648:0f}} 
        call    c,HL_div_2        ;{{1649:dce516}}  HL = HL/2
        pop     de                ;{{164C:d1}} 
        push    hl                ;{{164D:e5}} 
        ld      a,d               ;{{164E:7a}} 
        rlca                      ;{{164F:07}} 
        jr      nc,_gra_from_user_27;{{1650:3001}} 
        inc     de                ;{{1652:13}} 
_gra_from_user_27:                ;{{Addr=$1653 Code Calls/jump count: 1 Data use count: 0}}
        res     0,e               ;{{1653:cb83}} 
        ld      hl,(ORIGIN_y)     ;{{1655:2a95b6}}  origin y
        add     hl,de             ;{{1658:19}} 
        pop     de                ;{{1659:d1}} 
        jp      HL_div_2          ;{{165A:c3e516}}  HL = HL/2

;;==================================================================================
;; graph coord relative to absolute
;; convert relative graphics coordinate to absolute graphics coordinate
;; DE = relative X
;; HL = relative Y
graph_coord_relative_to_absolute: ;{{Addr=$165d Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{165D:e5}} 
        ld      hl,(graphics_text_x_position_);{{165E:2a97b6}}  absolute x		
        add     hl,de             ;{{1661:19}} 
        pop     de                ;{{1662:d1}} 
        push    hl                ;{{1663:e5}} 
        ld      hl,(graphics_text_y_position);{{1664:2a99b6}}  absolute y
        add     hl,de             ;{{1667:19}} 
        pop     de                ;{{1668:d1}} 
        ret                       ;{{1669:c9}} 

;;==================================================================================
;; X graphics coordinate within window

;; DE = x coordinate
X_graphics_coordinate_within_window:;{{Addr=$166a Code Calls/jump count: 4 Data use count: 0}}
        ld      hl,(graphics_window_x_of_one_edge_);{{166A:2a9bb6}}  graphics window left edge
        scf                       ;{{166D:37}} 
        sbc     hl,de             ;{{166E:ed52}} 
        jp      p,_x_graphics_coordinate_within_window_11;{{1670:f27e16}} 

        ld      hl,(graphics_window_x_of_other_edge_);{{1673:2a9db6}}  graphics window right edge
        or      a                 ;{{1676:b7}} 
        sbc     hl,de             ;{{1677:ed52}} 
        scf                       ;{{1679:37}} 
        ret     p                 ;{{167A:f0}} 

_x_graphics_coordinate_within_window_9:;{{Addr=$167b Code Calls/jump count: 1 Data use count: 0}}
        or      $ff               ;{{167B:f6ff}} 
        ret                       ;{{167D:c9}} 

_x_graphics_coordinate_within_window_11:;{{Addr=$167e Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{167E:af}} 
        ret                       ;{{167F:c9}} 

;;==================================================================================
;; y graphics coordinate within window
;; DE = y coordinate
y_graphics_coordinate_within_window:;{{Addr=$1680 Code Calls/jump count: 4 Data use count: 0}}
        ld      hl,(graphics_window_y_of_one_side_);{{1680:2a9fb6}}  graphics window top edge
        or      a                 ;{{1683:b7}} 
        sbc     hl,de             ;{{1684:ed52}} 
        jp      m,_x_graphics_coordinate_within_window_9;{{1686:fa7b16}} 
        ld      hl,(graphics_window_y_of_other_side_);{{1689:2aa1b6}}  graphics window bottom edge
        scf                       ;{{168C:37}} 
        sbc     hl,de             ;{{168D:ed52}} 
        jp      p,_x_graphics_coordinate_within_window_11;{{168F:f27e16}} 
        scf                       ;{{1692:37}} 
        ret                       ;{{1693:c9}} 

;;==================================================================================

;; current point within graphics window
current_point_within_graphics_window:;{{Addr=$1694 Code Calls/jump count: 2 Data use count: 0}}
        call    _get_cursor_absolute_user_coordinate_1;{{1694:cd2716}}  get absolute user coordinate

;; point in graphics window?
;; HL = x coordinate
;; DE = y coordinate
_current_point_within_graphics_window_1:;{{Addr=$1697 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{1697:e5}} 
        call    X_graphics_coordinate_within_window;{{1698:cd6a16}}  X graphics coordinate within window
        pop     hl                ;{{169B:e1}} 
        ret     nc                ;{{169C:d0}} 

        push    de                ;{{169D:d5}} 
        ex      de,hl             ;{{169E:eb}} 
        call    y_graphics_coordinate_within_window;{{169F:cd8016}}  Y graphics coordinate within window
        ex      de,hl             ;{{16A2:eb}} 
        pop     de                ;{{16A3:d1}} 
        ret                       ;{{16A4:c9}} 

;;==================================================================================
;; GRA WIN WIDTH
;; DE = left edge
;; HL = right edge
GRA_WIN_WIDTH:                    ;{{Addr=$16a5 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{16A5:e5}} 
        call    Make_X_coordinate_within_range_0639;{{16A6:cdd116}} ; Make X coordinate within range 0-639
        pop     de                ;{{16A9:d1}} 
        push    hl                ;{{16AA:e5}} 
        call    Make_X_coordinate_within_range_0639;{{16AB:cdd116}} ; Make X coordinate within range 0-639
        pop     de                ;{{16AE:d1}} 
        ld      a,e               ;{{16AF:7b}} 
        sub     l                 ;{{16B0:95}} 
        ld      a,d               ;{{16B1:7a}} 
        sbc     a,h               ;{{16B2:9c}} 
        jr      c,_gra_win_width_12;{{16B3:3801}} 

        ex      de,hl             ;{{16B5:eb}} 
_gra_win_width_12:                ;{{Addr=$16b6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{16B6:7b}} 
        and     $f8               ;{{16B7:e6f8}} 
        ld      e,a               ;{{16B9:5f}} 
        ld      a,l               ;{{16BA:7d}} 
        or      $07               ;{{16BB:f607}} 
        ld      l,a               ;{{16BD:6f}} 
        call    SCR_GET_MODE      ;{{16BE:cd0c0b}}  SCR GET MODE
        dec     a                 ;{{16C1:3d}} 
        call    m,DE_div_2_HL_div_2;{{16C2:fce116}}  DE = DE/2 and HL = HL/2
        dec     a                 ;{{16C5:3d}} 
        call    m,DE_div_2_HL_div_2;{{16C6:fce116}}  DE = DE/2 and HL = HL/2
        ld      (graphics_window_x_of_one_edge_),de;{{16C9:ed539bb6}}  graphics window left edge
        ld      (graphics_window_x_of_other_edge_),hl;{{16CD:229db6}}  graphics window right edge
        ret                       ;{{16D0:c9}} 

;;==================================================================================
;; Make X coordinate within range 0-639
Make_X_coordinate_within_range_0639:;{{Addr=$16d1 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{16D1:7a}} 
        or      a                 ;{{16D2:b7}} 
        ld      hl,$0000          ;{{16D3:210000}} ##LIT##;WARNING: Code area used as literal
        ret     m                 ;{{16D6:f8}} 

        ld      hl,$027f          ;{{16D7:217f02}}  639 ##LIT##;WARNING: Code area used as literal
        ld      a,e               ;{{16DA:7b}} 
        sub     l                 ;{{16DB:95}} 
        ld      a,d               ;{{16DC:7a}} 
        sbc     a,h               ;{{16DD:9c}} 
        ret     nc                ;{{16DE:d0}} 

        ex      de,hl             ;{{16DF:eb}} 
        ret                       ;{{16E0:c9}} 

;;==================================================================================
;; DE div 2 HL div 2
;; DE = DE/2
;; HL = HL/2
DE_div_2_HL_div_2:                ;{{Addr=$16e1 Code Calls/jump count: 2 Data use count: 0}}
        sra     d                 ;{{16E1:cb2a}} 
        rr      e                 ;{{16E3:cb1b}} 

;;+----------------------------------------------------------------------------------
;; HL div 2
;; HL = HL/2
HL_div_2:                         ;{{Addr=$16e5 Code Calls/jump count: 5 Data use count: 0}}
        sra     h                 ;{{16E5:cb2c}} 
        rr      l                 ;{{16E7:cb1d}} 
        ret                       ;{{16E9:c9}} 

;;==================================================================================
;; GRA WIN HEIGHT
GRA_WIN_HEIGHT:                   ;{{Addr=$16ea Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{16EA:e5}} 
        call    make_Y_coordinate_in_range_0199;{{16EB:cd0317}} ; make Y coordinate in range 0-199
        pop     de                ;{{16EE:d1}} 
        push    hl                ;{{16EF:e5}} 
        call    make_Y_coordinate_in_range_0199;{{16F0:cd0317}} ; make Y coordinate in range 0-199
        pop     de                ;{{16F3:d1}} 
        ld      a,l               ;{{16F4:7d}} 
        sub     e                 ;{{16F5:93}} 
        ld      a,h               ;{{16F6:7c}} 
        sbc     a,d               ;{{16F7:9a}} 
        jr      c,_gra_win_height_12;{{16F8:3801}}  (+&01)
        ex      de,hl             ;{{16FA:eb}} 
_gra_win_height_12:               ;{{Addr=$16fb Code Calls/jump count: 1 Data use count: 0}}
        ld      (graphics_window_y_of_one_side_),de;{{16FB:ed539fb6}}  graphics window top edge
        ld      (graphics_window_y_of_other_side_),hl;{{16FF:22a1b6}}  graphics window bottom edge
        ret                       ;{{1702:c9}} 

;;==================================================================================
;; make Y coordinate in range 0-199

make_Y_coordinate_in_range_0199:  ;{{Addr=$1703 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{1703:7a}} 
        or      a                 ;{{1704:b7}} 
        ld      hl,$0000          ;{{1705:210000}} ##LIT##;WARNING: Code area used as literal
        ret     m                 ;{{1708:f8}} 

        srl     d                 ;{{1709:cb3a}} 
        rr      e                 ;{{170B:cb1b}} 
        ld      hl,$00c7          ;{{170D:21c700}}  199 ##LIT##;WARNING: Code area used as literal
        ld      a,e               ;{{1710:7b}} 
        sub     l                 ;{{1711:95}} 
        ld      a,d               ;{{1712:7a}} 
        sbc     a,h               ;{{1713:9c}} 
        ret     nc                ;{{1714:d0}} 

        ex      de,hl             ;{{1715:eb}} 
        ret                       ;{{1716:c9}} 

;;==================================================================================
;; GRA GET W WIDTH
GRA_GET_W_WIDTH:                  ;{{Addr=$1717 Code Calls/jump count: 1 Data use count: 1}}
        ld      de,(graphics_window_x_of_one_edge_);{{1717:ed5b9bb6}}  graphics window left edge
        ld      hl,(graphics_window_x_of_other_edge_);{{171B:2a9db6}}  graphics window right edge
        call    SCR_GET_MODE      ;{{171E:cd0c0b}}  SCR GET MODE
        dec     a                 ;{{1721:3d}} 
        call    m,_gra_get_w_width_7;{{1722:fc2717}} 
        dec     a                 ;{{1725:3d}} 
        ret     p                 ;{{1726:f0}} 

;; HL = (HL*2)+1
_gra_get_w_width_7:               ;{{Addr=$1727 Code Calls/jump count: 2 Data use count: 0}}
        add     hl,hl             ;{{1727:29}} 
        inc     hl                ;{{1728:23}} 

;; DE = DE * 2
        ex      de,hl             ;{{1729:eb}} 
        add     hl,hl             ;{{172A:29}} 
        ex      de,hl             ;{{172B:eb}} 

        ret                       ;{{172C:c9}} 
;;==================================================================================
;; GRA GET W HEIGHT
GRA_GET_W_HEIGHT:                 ;{{Addr=$172d Code Calls/jump count: 0 Data use count: 1}}
        ld      de,(graphics_window_y_of_one_side_);{{172D:ed5b9fb6}}  graphics window top edge
        ld      hl,(graphics_window_y_of_other_side_);{{1731:2aa1b6}}  graphics window bottom edge
        jr      _gra_get_w_width_7;{{1734:18f1}} 
;;==================================================================================
;; GRA CLEAR WINDOW
GRA_CLEAR_WINDOW:                 ;{{Addr=$1736 Code Calls/jump count: 0 Data use count: 1}}
        call    GRA_GET_W_WIDTH   ;{{1736:cd1717}}  GRA GET W WIDTH
        or      a                 ;{{1739:b7}} 
        sbc     hl,de             ;{{173A:ed52}} 
        inc     hl                ;{{173C:23}} 
        call    HL_div_2          ;{{173D:cde516}}  HL = HL/2
        call    HL_div_2          ;{{1740:cde516}}  HL = HL/2
        srl     l                 ;{{1743:cb3d}} 
        ld      b,l               ;{{1745:45}} 
        ld      de,(graphics_window_y_of_other_side_);{{1746:ed5ba1b6}}  graphics window bottom edge
        ld      hl,(graphics_window_y_of_one_side_);{{174A:2a9fb6}}  graphics window top edge
        push    hl                ;{{174D:e5}} 
        or      a                 ;{{174E:b7}} 
        sbc     hl,de             ;{{174F:ed52}} 
        inc     hl                ;{{1751:23}} 
        ld      c,l               ;{{1752:4d}} 
        ld      de,(graphics_window_x_of_one_edge_);{{1753:ed5b9bb6}}  graphics window left edge
        pop     hl                ;{{1757:e1}} 
        push    bc                ;{{1758:c5}} 
        call    SCR_DOT_POSITION  ;{{1759:cdaf0b}} ; SCR DOT POSITION
        pop     de                ;{{175C:d1}} 
        ld      a,(GRAPHICS_PAPER);{{175D:3aa4b6}}  graphics paper
        ld      c,a               ;{{1760:4f}} 
        call    SCR_FLOOD_BOX     ;{{1761:cdbd0d}} ; SCR FLOOD BOX
        jp      set_absolute_position_to_origin;{{1764:c31516}} ; set absolute position to origin

;;==================================================================================
;; GRA SET PEN
GRA_SET_PEN:                      ;{{Addr=$1767 Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_INK_ENCODE    ;{{1767:cd8e0c}} ; SCR INK ENCODE
        ld      (GRAPHICS_PEN),a  ;{{176A:32a3b6}}  graphics pen
        ret                       ;{{176D:c9}} 

;;==================================================================================
;; GRA SET PAPER
GRA_SET_PAPER:                    ;{{Addr=$176e Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_INK_ENCODE    ;{{176E:cd8e0c}} ; SCR INK ENCODE
        ld      (GRAPHICS_PAPER),a;{{1771:32a4b6}}  graphics paper
        ret                       ;{{1774:c9}} 
;;==================================================================================
;; GRA GET PEN
GRA_GET_PEN:                      ;{{Addr=$1775 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(GRAPHICS_PEN)  ;{{1775:3aa3b6}}  graphics pen
        jr      _gra_get_paper_1  ;{{1778:1803}}  do SCR INK ENCODE
;;==================================================================================
;; GRA GET PAPER
GRA_GET_PAPER:                    ;{{Addr=$177a Code Calls/jump count: 2 Data use count: 1}}
        ld      a,(GRAPHICS_PAPER);{{177A:3aa4b6}}  graphics paper
_gra_get_paper_1:                 ;{{Addr=$177d Code Calls/jump count: 1 Data use count: 0}}
        jp      SCR_INK_DECODE    ;{{177D:c3a70c}} ; SCR INK DECODE

;;==================================================================================
;; GRA PLOT RELATIVE
GRA_PLOT_RELATIVE:                ;{{Addr=$1780 Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{1780:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate

;;===================================================================================
;; GRA PLOT ABSOLUTE
GRA_PLOT_ABSOLUTE:                ;{{Addr=$1783 Code Calls/jump count: 0 Data use count: 1}}
        jp      GRA_PLOT          ;{{1783:c3dcbd}}  IND: GRA PLOT

;;============================================================================
;; IND: GRA PLOT
IND_GRA_PLOT:                     ;{{Addr=$1786 Code Calls/jump count: 1 Data use count: 0}}
        call    current_point_within_graphics_window;{{1786:cd9416}}  test if current coordinate within graphics window
        ret     nc                ;{{1789:d0}} 

        call    SCR_DOT_POSITION  ;{{178A:cdaf0b}} ; SCR DOT POSITION
        ld      a,(GRAPHICS_PEN)  ;{{178D:3aa3b6}}  graphics pen
        ld      b,a               ;{{1790:47}} 
        jp      SCR_WRITE         ;{{1791:c3e8bd}}  IND: SCR WRITE

;;===========================================================================
;; GRA TEST RELATIVE
GRA_TEST_RELATIVE:                ;{{Addr=$1794 Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{1794:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate

;;==============================================================================
;; GRA TEST ABSOLUTE
GRA_TEST_ABSOLUTE:                ;{{Addr=$1797 Code Calls/jump count: 0 Data use count: 1}}
        jp      GRA_TEST          ;{{1797:c3dfbd}}  IND: GRA TEST

;;===========================================================================
;; IND: GRA TEXT
IND_GRA_TEXT:                     ;{{Addr=$179a Code Calls/jump count: 1 Data use count: 0}}
        call    current_point_within_graphics_window;{{179A:cd9416}}  test if current coordinate within graphics window
        jp      nc,GRA_GET_PAPER  ;{{179D:d27a17}}  GRA GET PAPER
        call    SCR_DOT_POSITION  ;{{17A0:cdaf0b}}  SCR DOT POSITION
        jp      SCR_READ          ;{{17A3:c3e5bd}}  IND: SCR READ

;;===========================================================================
;; GRA LINE RELATIVE
GRA_LINE_RELATIVE:                ;{{Addr=$17a6 Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{17A6:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate

;;===========================================================================
;; GRA LINE ABSOLUTE
GRA_LINE_ABSOLUTE:                ;{{Addr=$17a9 Code Calls/jump count: 0 Data use count: 1}}
        jp      GRA_LINE          ;{{17A9:c3e2bd}}  IND: GRA LINE

;;===========================================================================
;; GRA SET LINE MASK

GRA_SET_LINE_MASK:                ;{{Addr=$17ac Code Calls/jump count: 1 Data use count: 1}}
        ld      (line_MASK),a     ;{{17AC:32b3b6}}  gra line mask
        ret                       ;{{17AF:c9}} 

;;===========================================================================
;; GRA SET FIRST

GRA_SET_FIRST:                    ;{{Addr=$17b0 Code Calls/jump count: 1 Data use count: 1}}
        ld      (first_point_on_drawn_line_flag_),a;{{17B0:32b2b6}} 
        ret                       ;{{17B3:c9}} 

;;===========================================================================
;; IND: GRA LINE
IND_GRA_LINE:                     ;{{Addr=$17b4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{17B4:e5}} 
        call    gra_line_sub_1    ;{{17B5:cd8b18}}  get cursor absolute position
        pop     hl                ;{{17B8:e1}} 
        call    _get_cursor_absolute_user_coordinate_1;{{17B9:cd2716}}  get absolute user coordinate

;; remember Y coordinate
        push    hl                ;{{17BC:e5}} 

;; DE = X coordinate

;;-------------------------------------------

;; calculate dx
        ld      hl,(RAM_b6a5)     ;{{17BD:2aa5b6}}  absolute user X coordinate
        or      a                 ;{{17C0:b7}} 
        sbc     hl,de             ;{{17C1:ed52}} 

;; this will record the fact of dx is +ve or negative
        ld      a,h               ;{{17C3:7c}} 
        ld      (RAM_b6ad),a      ;{{17C4:32adb6}} 

;; if dx is negative, make it positive
        call    m,invert_HL       ;{{17C7:fc3919}}  HL = -HL

;; HL = abs(dx)

;;-------------------------------------------

;; calculate dy
        pop     de                ;{{17CA:d1}} 
;; DE = Y coordinate
        push    hl                ;{{17CB:e5}} 
        ld      hl,(x1)           ;{{17CC:2aa7b6}}  absolute user Y coordinate
        or      a                 ;{{17CF:b7}} 
        sbc     hl,de             ;{{17D0:ed52}} 

;; this stores the fact of dy is +ve or negative
        ld      a,h               ;{{17D2:7c}} 
        ld      ($b6ae),a         ;{{17D3:32aeb6}} 

;; if dy is negative, make it positive
        call    m,invert_HL       ;{{17D6:fc3919}}  HL = -HL

;; HL = abs(dy)


        pop     de                ;{{17D9:d1}} 
;; DE = abs(dx)
;; HL = abs(dy)

;;-------------------------------------------

;; is dx or dy largest?
        or      a                 ;{{17DA:b7}} 
        sbc     hl,de             ;{{17DB:ed52}}  dy-dx
        add     hl,de             ;{{17DD:19}}  and return it back to their original values

        sbc     a,a               ;{{17DE:9f}} 
        ld      (RAM_b6af),a      ;{{17DF:32afb6}}  remembers which of dy/dx was largest

        ld      a,($b6ae)         ;{{17E2:3aaeb6}}  dy is negative
        jr      z,_ind_gra_line_29;{{17E5:2804}}  depends on result of dy-dx

;; if yes, then swap dx/dy
        ex      de,hl             ;{{17E7:eb}} 
;; DE = abs(dy)
;; HL = abs(dx)

        ld      a,(RAM_b6ad)      ;{{17E8:3aadb6}}  dx is negative

;;-------------------------------------------

_ind_gra_line_29:                 ;{{Addr=$17eb Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{17EB:f5}} 
        ld      (y2x),de          ;{{17EC:ed53abb6}} 
        ld      b,h               ;{{17F0:44}} 
        ld      c,l               ;{{17F1:4d}} 
        ld      a,(first_point_on_drawn_line_flag_);{{17F2:3ab2b6}} 
        or      a                 ;{{17F5:b7}} 
        jr      z,_ind_gra_line_37;{{17F6:2801}}  (+&01)
        inc     bc                ;{{17F8:03}} 
_ind_gra_line_37:                 ;{{Addr=$17f9 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6b0),bc     ;{{17F9:ed43b0b6}} 
        call    invert_HL         ;{{17FD:cd3919}}  HL = -HL
        push    hl                ;{{1800:e5}} 
        add     hl,de             ;{{1801:19}} 
        ld      (y21),hl          ;{{1802:22a9b6}} 
        pop     hl                ;{{1805:e1}} 
        sra     h                 ;{{1806:cb2c}} ; /2 for y coordinate (0-400 GRA coordinates, 0-200 actual number of lines)
        rr      l                 ;{{1808:cb1d}} 
        pop     af                ;{{180A:f1}} 
        rlca                      ;{{180B:07}} 
        jr      c,_ind_gra_line_59;{{180C:3812}}  (+&12)
        push    hl                ;{{180E:e5}} 
        call    gra_line_sub_1    ;{{180F:cd8b18}}  get cursor absolute position
        ld      hl,(RAM_b6ad)     ;{{1812:2aadb6}} 
        ld      a,h               ;{{1815:7c}} 
        cpl                       ;{{1816:2f}} 
        ld      h,a               ;{{1817:67}} 
        ld      a,l               ;{{1818:7d}} 
        cpl                       ;{{1819:2f}} 
        ld      l,a               ;{{181A:6f}} 
        ld      (RAM_b6ad),hl     ;{{181B:22adb6}} 
        jr      _ind_gra_line_68  ;{{181E:1812}}  (+&12)


_ind_gra_line_59:                 ;{{Addr=$1820 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(first_point_on_drawn_line_flag_);{{1820:3ab2b6}} 
        or      a                 ;{{1823:b7}} 
        jr      nz,_ind_gra_line_69;{{1824:200d}}  (+&0d)
        add     hl,de             ;{{1826:19}} 
        push    hl                ;{{1827:e5}} 

        ld      a,(RAM_b6af)      ;{{1828:3aafb6}}  dy or dx was biggest?
        rlca                      ;{{182B:07}} 
        call    c,_gra_line_sub_2_33;{{182C:dcda18}}  plot a pixel moving up
        call    nc,_clip_coords_to_be_within_range_31;{{182F:d42819}}  plot a pixel moving right

_ind_gra_line_68:                 ;{{Addr=$1832 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{1832:e1}} 
_ind_gra_line_69:                 ;{{Addr=$1833 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{1833:7a}} 
        or      e                 ;{{1834:b3}} 
        jp      z,gra_line_sub_2  ;{{1835:ca9818}} 
        push    ix                ;{{1838:dde5}} 
        ld      bc,$0000          ;{{183A:010000}} ##LIT##;WARNING: Code area used as literal
        push    bc                ;{{183D:c5}} 
        pop     ix                ;{{183E:dde1}} 
_ind_gra_line_76:                 ;{{Addr=$1840 Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{1840:dde5}} 
        pop     de                ;{{1842:d1}} 
        or      a                 ;{{1843:b7}} 
        adc     hl,de             ;{{1844:ed5a}} 
        ld      de,(y2x)          ;{{1846:ed5babb6}} 
        jp      p,_ind_gra_line_86;{{184A:f25318}} 
_ind_gra_line_82:                 ;{{Addr=$184d Code Calls/jump count: 1 Data use count: 0}}
        inc     bc                ;{{184D:03}} 
        add     ix,de             ;{{184E:dd19}} 
        add     hl,de             ;{{1850:19}} 
        jr      nc,_ind_gra_line_82;{{1851:30fa}}  (-&06)

; DE = -DE
_ind_gra_line_86:                 ;{{Addr=$1853 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{1853:af}} 
        sub     e                 ;{{1854:93}} 
        ld      e,a               ;{{1855:5f}} 
        sbc     a,a               ;{{1856:9f}} 
        sub     d                 ;{{1857:92}} 
        ld      d,a               ;{{1858:57}} 

_ind_gra_line_92:                 ;{{Addr=$1859 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{1859:19}} 
        jr      nc,_ind_gra_line_97;{{185A:3005}}  (+&05)
        add     ix,de             ;{{185C:dd19}} 
        dec     bc                ;{{185E:0b}} 
        jr      _ind_gra_line_92  ;{{185F:18f8}}  (-&08)


_ind_gra_line_97:                 ;{{Addr=$1861 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(y21)          ;{{1861:ed5ba9b6}} 
        add     hl,de             ;{{1865:19}} 
        push    bc                ;{{1866:c5}} 
        push    hl                ;{{1867:e5}} 
        ld      hl,(RAM_b6b0)     ;{{1868:2ab0b6}} 
        or      a                 ;{{186B:b7}} 
        sbc     hl,bc             ;{{186C:ed42}} 
        jr      nc,_ind_gra_line_109;{{186E:3006}}  (+&06)

        add     hl,bc             ;{{1870:09}} 
        ld      b,h               ;{{1871:44}} 
        ld      c,l               ;{{1872:4d}} 
        ld      hl,$0000          ;{{1873:210000}} ##LIT##;WARNING: Code area used as literal

_ind_gra_line_109:                ;{{Addr=$1876 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6b0),hl     ;{{1876:22b0b6}} 
        call    gra_line_sub_2    ;{{1879:cd9818}}  plot with clip
        pop     hl                ;{{187C:e1}} 
        pop     bc                ;{{187D:c1}} 
        jr      nc,_ind_gra_line_118;{{187E:3008}}  (+&08)
        ld      de,(RAM_b6b0)     ;{{1880:ed5bb0b6}} 
        ld      a,d               ;{{1884:7a}} 
        or      e                 ;{{1885:b3}} 
        jr      nz,_ind_gra_line_76;{{1886:20b8}}  (-&48)
_ind_gra_line_118:                ;{{Addr=$1888 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{1888:dde1}} 
        ret                       ;{{188A:c9}} 
    
;;==================================================================================
;; gra line sub 1

gra_line_sub_1:                   ;{{Addr=$188b Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{188B:d5}} 
        call    get_cursor_absolute_user_coordinate;{{188C:cd2416}} ; get cursor absolute user coordinate
        ld      (RAM_b6a5),de     ;{{188F:ed53a5b6}} 
        ld      (x1),hl           ;{{1893:22a7b6}} 
        pop     de                ;{{1896:d1}} 
        ret                       ;{{1897:c9}} 

;;==================================================================================
;; gra line sub 2

gra_line_sub_2:                   ;{{Addr=$1898 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_b6af)      ;{{1898:3aafb6}} 
        rlca                      ;{{189B:07}} 
        jr      c,clip_coords_to_be_within_range;{{189C:384d}}  (+&4d)
        ld      a,b               ;{{189E:78}} 
        or      c                 ;{{189F:b1}} 
        jr      z,_gra_line_sub_2_33;{{18A0:2838}}  (+&38)
        ld      hl,(x1)           ;{{18A2:2aa7b6}} 
        add     hl,bc             ;{{18A5:09}} 
        dec     hl                ;{{18A6:2b}} 
        ld      b,h               ;{{18A7:44}} 
        ld      c,l               ;{{18A8:4d}} 
        ex      de,hl             ;{{18A9:eb}} 
        call    y_graphics_coordinate_within_window;{{18AA:cd8016}}  Y graphics coordinate within window
        ld      hl,(x1)           ;{{18AD:2aa7b6}} 
        ex      de,hl             ;{{18B0:eb}} 
        inc     hl                ;{{18B1:23}} 
        ld      (x1),hl           ;{{18B2:22a7b6}} 
        jr      c,_gra_line_sub_2_20;{{18B5:3806}}  
        jr      z,_gra_line_sub_2_33;{{18B7:2821}}  
        ld      bc,(graphics_window_y_of_one_side_);{{18B9:ed4b9fb6}}  graphics window top edge
_gra_line_sub_2_20:               ;{{Addr=$18bd Code Calls/jump count: 1 Data use count: 0}}
        call    y_graphics_coordinate_within_window;{{18BD:cd8016}}  Y graphics coordinate within window
        jr      c,_gra_line_sub_2_24;{{18C0:3805}}  (+&05)
        ret     nz                ;{{18C2:c0}} 

        ld      de,(graphics_window_y_of_other_side_);{{18C3:ed5ba1b6}}  graphics window bottom edge
_gra_line_sub_2_24:               ;{{Addr=$18c7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{18C7:d5}} 
        ld      de,(RAM_b6a5)     ;{{18C8:ed5ba5b6}} 
        call    X_graphics_coordinate_within_window;{{18CC:cd6a16}}  graphics x coordinate within window
        pop     hl                ;{{18CF:e1}} 
        jr      c,_gra_line_sub_2_32;{{18D0:3805}}  (+&05)
        ld      hl,RAM_b6ad       ;{{18D2:21adb6}} 
        xor     (hl)              ;{{18D5:ae}} 
        ret     p                 ;{{18D6:f0}} 

_gra_line_sub_2_32:               ;{{Addr=$18d7 Code Calls/jump count: 1 Data use count: 0}}
        call    c,_scr_vertical_67;{{18D7:dc1610}}  plot a pixel, going up a line


_gra_line_sub_2_33:               ;{{Addr=$18da Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(RAM_b6a5)     ;{{18DA:2aa5b6}} 
        ld      a,(RAM_b6ad)      ;{{18DD:3aadb6}} 
        rlca                      ;{{18E0:07}} 
        inc     hl                ;{{18E1:23}} 
        jr      c,_gra_line_sub_2_40;{{18E2:3802}}  (+&02)
        dec     hl                ;{{18E4:2b}} 
        dec     hl                ;{{18E5:2b}} 
_gra_line_sub_2_40:               ;{{Addr=$18e6 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6a5),hl     ;{{18E6:22a5b6}} 
        scf                       ;{{18E9:37}} 
        ret                       ;{{18EA:c9}} 

;;=============================
;; clip coords to be within range
;; we work with coordinates...

;; this performs the clipping to find if the coordinates are within range

clip_coords_to_be_within_range:   ;{{Addr=$18eb Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{18EB:78}} 
        or      c                 ;{{18EC:b1}} 
        jr      z,_clip_coords_to_be_within_range_31;{{18ED:2839}}  (+&39)
        ld      hl,(RAM_b6a5)     ;{{18EF:2aa5b6}} 
        add     hl,bc             ;{{18F2:09}} 
        dec     hl                ;{{18F3:2b}} 
        ld      b,h               ;{{18F4:44}} 
        ld      c,l               ;{{18F5:4d}} 
        ex      de,hl             ;{{18F6:eb}} 
        call    X_graphics_coordinate_within_window;{{18F7:cd6a16}}  x graphics coordinate within window
        ld      hl,(RAM_b6a5)     ;{{18FA:2aa5b6}} 
        ex      de,hl             ;{{18FD:eb}} 
        inc     hl                ;{{18FE:23}} 
        ld      (RAM_b6a5),hl     ;{{18FF:22a5b6}} 
        jr      c,_clip_coords_to_be_within_range_17;{{1902:3806}} 
        jr      z,_clip_coords_to_be_within_range_31;{{1904:2822}} 
        ld      bc,(graphics_window_x_of_other_edge_);{{1906:ed4b9db6}}  graphics window right edge
_clip_coords_to_be_within_range_17:;{{Addr=$190a Code Calls/jump count: 1 Data use count: 0}}
        call    X_graphics_coordinate_within_window;{{190A:cd6a16}}  x graphics coordinate within window
        jr      c,_clip_coords_to_be_within_range_21;{{190D:3805}} 
        ret     nz                ;{{190F:c0}} 

        ld      de,(graphics_window_x_of_one_edge_);{{1910:ed5b9bb6}}  graphics window left edge
_clip_coords_to_be_within_range_21:;{{Addr=$1914 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{1914:d5}} 
        ld      de,(x1)           ;{{1915:ed5ba7b6}} 
        call    y_graphics_coordinate_within_window;{{1919:cd8016}}  Y graphics coordinate within window
        pop     hl                ;{{191C:e1}} 
        jr      c,_clip_coords_to_be_within_range_29;{{191D:3805}}  (+&05)

        ld      hl,$b6ae          ;{{191F:21aeb6}} 
        xor     (hl)              ;{{1922:ae}} 
        ret     p                 ;{{1923:f0}} 

_clip_coords_to_be_within_range_29:;{{Addr=$1924 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{1924:eb}} 
        call    c,_scr_vertical_18;{{1925:dcc20f}}  plot a pixel moving right

_clip_coords_to_be_within_range_31:;{{Addr=$1928 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(x1)           ;{{1928:2aa7b6}} 
        ld      a,($b6ae)         ;{{192B:3aaeb6}} 
        rlca                      ;{{192E:07}} 
        inc     hl                ;{{192F:23}} 
        jr      c,_clip_coords_to_be_within_range_38;{{1930:3802}}  (+&02)
        dec     hl                ;{{1932:2b}} 
        dec     hl                ;{{1933:2b}} 
_clip_coords_to_be_within_range_38:;{{Addr=$1934 Code Calls/jump count: 1 Data use count: 0}}
        ld      (x1),hl           ;{{1934:22a7b6}} 
        scf                       ;{{1937:37}} 
        ret                       ;{{1938:c9}} 

;;==================================================================================
;; invert HL
; HL = -HL
invert_HL:                        ;{{Addr=$1939 Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{1939:af}} 
        sub     l                 ;{{193A:95}} 
        ld      l,a               ;{{193B:6f}} 
        sbc     a,a               ;{{193C:9f}} 
        sub     h                 ;{{193D:94}} 
        ld      h,a               ;{{193E:67}} 
        ret                       ;{{193F:c9}} 

;;===========================================================================
;; GRA WR CHAR

GRA_WR_CHAR:                      ;{{Addr=$1940 Code Calls/jump count: 1 Data use count: 2}}
        push    ix                ;{{1940:dde5}} 
        call    TXT_GET_MATRIX    ;{{1942:cdd412}}  TXT GET MATRIX
        push    hl                ;{{1945:e5}} 
        pop     ix                ;{{1946:dde1}} 
        call    get_cursor_absolute_user_coordinate;{{1948:cd2416}} ; get cursor absolute user coordinate
        call    _current_point_within_graphics_window_1;{{194B:cd9716}} ; point in graphics window
        jr      nc,gra_wr_char_sub_2;{{194E:304b}}  (+&4b)
        push    hl                ;{{1950:e5}} 
        push    de                ;{{1951:d5}} 
        ld      bc,$0007          ;{{1952:010700}} ##LIT##;WARNING: Code area used as literal
        ex      de,hl             ;{{1955:eb}} 
        add     hl,bc             ;{{1956:09}} 
        ex      de,hl             ;{{1957:eb}} 
        or      a                 ;{{1958:b7}} 
        sbc     hl,bc             ;{{1959:ed42}} 
        call    _current_point_within_graphics_window_1;{{195B:cd9716}} ; point in graphics window
        pop     de                ;{{195E:d1}} 
        pop     hl                ;{{195F:e1}} 
        jr      nc,gra_wr_char_sub_2;{{1960:3039}}  (+&39)
        call    SCR_DOT_POSITION  ;{{1962:cdaf0b}} ; SCR DOT POSITION
        ld      d,$08             ;{{1965:1608}} 
_gra_wr_char_21:                  ;{{Addr=$1967 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1967:e5}} 
        ld      e,(ix+$00)        ;{{1968:dd5e00}} 
        scf                       ;{{196B:37}} 
        rl      e                 ;{{196C:cb13}} 
_gra_wr_char_25:                  ;{{Addr=$196e Code Calls/jump count: 1 Data use count: 0}}
        call    gra_wr_char_sub_3 ;{{196E:cdc419}} 
        rrc     c                 ;{{1971:cb09}} 
        call    c,SCR_NEXT_BYTE   ;{{1973:dc050c}}  SCR NEXT BYTE
        sla     e                 ;{{1976:cb23}} 
        jr      nz,_gra_wr_char_25;{{1978:20f4}}  (-&0c)
        pop     hl                ;{{197A:e1}} 
        call    SCR_NEXT_LINE     ;{{197B:cd1f0c}}  SCR NEXT LINE
        inc     ix                ;{{197E:dd23}} 
        dec     d                 ;{{1980:15}} 
        jr      nz,_gra_wr_char_21;{{1981:20e4}}  (-&1c)
_gra_wr_char_35:                  ;{{Addr=$1983 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{1983:dde1}} 
        call    GRA_ASK_CURSOR    ;{{1985:cd0616}}  GRA ASK CURSOR
        ex      de,hl             ;{{1988:eb}} 
        call    SCR_GET_MODE      ;{{1989:cd0c0b}}  SCR GET MODE
        ld      bc,$0008          ;{{198C:010800}} ##LIT##;WARNING: Code area used as literal
        jr      z,_gra_wr_char_44 ;{{198F:2804}}  (+&04)
        jr      nc,_gra_wr_char_45;{{1991:3003}}  (+&03)
        add     hl,bc             ;{{1993:09}} 
        add     hl,bc             ;{{1994:09}} 
_gra_wr_char_44:                  ;{{Addr=$1995 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{1995:09}} 
_gra_wr_char_45:                  ;{{Addr=$1996 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{1996:09}} 
        ex      de,hl             ;{{1997:eb}} 
        jp      GRA_MOVE_ABSOLUTE ;{{1998:c3fe15}}  GRA MOVE ABSOLUTE

;;==================================================================================
;; gra wr char sub 2
gra_wr_char_sub_2:                ;{{Addr=$199b Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$08             ;{{199B:0608}} 
_gra_wr_char_sub_2_1:             ;{{Addr=$199d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{199D:c5}} 
        push    de                ;{{199E:d5}} 
        ld      a,(ix+$00)        ;{{199F:dd7e00}} 
        scf                       ;{{19A2:37}} 
        adc     a,a               ;{{19A3:8f}} 
_gra_wr_char_sub_2_6:             ;{{Addr=$19a4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{19A4:e5}} 
        push    de                ;{{19A5:d5}} 
        push    af                ;{{19A6:f5}} 
        call    _current_point_within_graphics_window_1;{{19A7:cd9716}} ; point in graphics window
        jr      nc,_gra_wr_char_sub_2_15;{{19AA:3008}}  (+&08)
        call    SCR_DOT_POSITION  ;{{19AC:cdaf0b}} ; SCR DOT POSITION
        pop     af                ;{{19AF:f1}} 
        push    af                ;{{19B0:f5}} 
        call    gra_wr_char_sub_3 ;{{19B1:cdc419}} 
_gra_wr_char_sub_2_15:            ;{{Addr=$19b4 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{19B4:f1}} 
        pop     de                ;{{19B5:d1}} 
        pop     hl                ;{{19B6:e1}} 
        inc     de                ;{{19B7:13}} 
        add     a,a               ;{{19B8:87}} 
        jr      nz,_gra_wr_char_sub_2_6;{{19B9:20e9}}  (-&17)
        pop     de                ;{{19BB:d1}} 
        dec     hl                ;{{19BC:2b}} 
        inc     ix                ;{{19BD:dd23}} 
        pop     bc                ;{{19BF:c1}} 
        djnz    _gra_wr_char_sub_2_1;{{19C0:10db}}  (-&25)
        jr      _gra_wr_char_35   ;{{19C2:18bf}}  (-&41)

;;==================================================================================
;; gra wr char sub 3

gra_wr_char_sub_3:                ;{{Addr=$19c4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(GRAPHICS_PEN)  ;{{19C4:3aa3b6}}  graphics pen
        jr      c,_gra_wr_char_sub_3_6;{{19C7:3808}}  (+&08)
        ld      a,(RAM_b6b4)      ;{{19C9:3ab4b6}} 
        or      a                 ;{{19CC:b7}} 
        ret     nz                ;{{19CD:c0}} 

        ld      a,(GRAPHICS_PAPER);{{19CE:3aa4b6}}  graphics paper
_gra_wr_char_sub_3_6:             ;{{Addr=$19d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{19D1:47}} 
        jp      SCR_WRITE         ;{{19D2:c3e8bd}}  IND: SCR WRITE

;;===========================================================================
;; GRA SET BACK

GRA_SET_BACK:                     ;{{Addr=$19d5 Code Calls/jump count: 1 Data use count: 1}}
        ld      (RAM_b6b4),a      ;{{19D5:32b4b6}} 
        ret                       ;{{19D8:c9}} 

;;===========================================================================
;; GRA FILL
;; HL = buffer
;; A = pen to fill
;; DE = length of buffer

GRA_FILL:                         ;{{Addr=$19d9 Code Calls/jump count: 0 Data use count: 1}}
        ld      (RAM_b6a5),hl     ;{{19D9:22a5b6}} 
        ld      (hl),$01          ;{{19DC:3601}} 
        dec     de                ;{{19DE:1b}} 
        ld      (x1),de           ;{{19DF:ed53a7b6}} 
        call    SCR_INK_ENCODE    ;{{19E3:cd8e0c}} ; SCR INK ENCODE
        ld      ($b6aa),a         ;{{19E6:32aab6}} 
        call    get_cursor_absolute_user_coordinate;{{19E9:cd2416}} ; get cursor absolute user coordinate
        call    _current_point_within_graphics_window_1;{{19EC:cd9716}} ; point in graphics window
        call    c,gra_fill_sub_5  ;{{19EF:dc421b}} 
        ret     nc                ;{{19F2:d0}} 

        push    hl                ;{{19F3:e5}} 
        call    _gra_fill_sub_2_83;{{19F4:cde71a}} 
        ex      (sp),hl           ;{{19F7:e3}} 
        call    _gra_fill_sub_3_23;{{19F8:cd151b}} 
        pop     bc                ;{{19FB:c1}} 
        ld      a,$ff             ;{{19FC:3eff}} 
        ld      (y21),a           ;{{19FE:32a9b6}} 
        push    hl                ;{{1A01:e5}} 
        push    de                ;{{1A02:d5}} 
        push    bc                ;{{1A03:c5}} 
        call    _gra_fill_25      ;{{1A04:cd0b1a}} 
        pop     bc                ;{{1A07:c1}} 
        pop     de                ;{{1A08:d1}} 
        pop     hl                ;{{1A09:e1}} 
        xor     a                 ;{{1A0A:af}} 
_gra_fill_25:                     ;{{Addr=$1a0b Code Calls/jump count: 1 Data use count: 0}}
        ld      (y2x),a           ;{{1A0B:32abb6}} 
_gra_fill_26:                     ;{{Addr=$1a0e Code Calls/jump count: 1 Data use count: 0}}
        call    _gra_fill_sub_2_76;{{1A0E:cdde1a}} 
_gra_fill_27:                     ;{{Addr=$1a11 Code Calls/jump count: 1 Data use count: 0}}
        call    _current_point_within_graphics_window_1;{{1A11:cd9716}} ; point in graphics window
        call    c,gra_fill_sub_2  ;{{1A14:dc501a}} 
        jr      c,_gra_fill_26    ;{{1A17:38f5}}  (-&0b)
        ld      hl,(RAM_b6a5)     ;{{1A19:2aa5b6}}  graphics fill buffer
        rst     $20               ;{{1A1C:e7}}  RST 4 - LOW: RAM LAM
        cp      $01               ;{{1A1D:fe01}} 
        jr      z,_gra_fill_65    ;{{1A1F:282a}}  (+&2a)
        ld      (y2x),a           ;{{1A21:32abb6}} 
        ex      de,hl             ;{{1A24:eb}} 
        ld      hl,(x1)           ;{{1A25:2aa7b6}} 
        ld      bc,$0007          ;{{1A28:010700}} ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{1A2B:09}} 
        ld      (x1),hl           ;{{1A2C:22a7b6}} 
        ex      de,hl             ;{{1A2F:eb}} 
        dec     hl                ;{{1A30:2b}} 
        rst     $20               ;{{1A31:e7}}  RST 4 - LOW: RAM LAM
        ld      b,a               ;{{1A32:47}} 
        dec     hl                ;{{1A33:2b}} 
        rst     $20               ;{{1A34:e7}}  RST 4 - LOW: RAM LAM
        ld      c,a               ;{{1A35:4f}} 
        dec     hl                ;{{1A36:2b}} 
        rst     $20               ;{{1A37:e7}}  RST 4 - LOW: RAM LAM
        ld      d,a               ;{{1A38:57}} 
        dec     hl                ;{{1A39:2b}} 
        rst     $20               ;{{1A3A:e7}}  RST 4 - LOW: RAM LAM
        ld      e,a               ;{{1A3B:5f}} 
        push    de                ;{{1A3C:d5}} 
        dec     hl                ;{{1A3D:2b}} 
        rst     $20               ;{{1A3E:e7}}  RST 4 - LOW: RAM LAM
        ld      d,a               ;{{1A3F:57}} 
        dec     hl                ;{{1A40:2b}} 
        rst     $20               ;{{1A41:e7}}  RST 4 - LOW: RAM LAM
        ld      e,a               ;{{1A42:5f}} 
        dec     hl                ;{{1A43:2b}} 
        ld      (RAM_b6a5),hl     ;{{1A44:22a5b6}}  graphics fill buffer
        ex      de,hl             ;{{1A47:eb}} 
        pop     de                ;{{1A48:d1}} 
        jr      _gra_fill_27      ;{{1A49:18c6}}  (-&3a)
_gra_fill_65:                     ;{{Addr=$1a4b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(y21)           ;{{1A4B:3aa9b6}} 
        rrca                      ;{{1A4E:0f}} 
        ret                       ;{{1A4F:c9}} 

;;==================================================================================
;; gra fill sub 2

gra_fill_sub_2:                   ;{{Addr=$1a50 Code Calls/jump count: 1 Data use count: 0}}
        ld      ($b6ac),bc        ;{{1A50:ed43acb6}} 
        call    gra_fill_sub_5    ;{{1A54:cd421b}} 
        jr      c,_gra_fill_sub_2_7;{{1A57:3809}}  (+&09)
        call    gra_fill_sub_3    ;{{1A59:cdf11a}} 
        ret     nc                ;{{1A5C:d0}} 

        ld      ($b6ae),hl        ;{{1A5D:22aeb6}} 
        jr      _gra_fill_sub_2_18;{{1A60:1811}}  (+&11)
_gra_fill_sub_2_7:                ;{{Addr=$1a62 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1A62:e5}} 
        call    _gra_fill_sub_3_23;{{1A63:cd151b}} 
        ld      ($b6ae),hl        ;{{1A66:22aeb6}} 
        pop     bc                ;{{1A69:c1}} 
        ld      a,l               ;{{1A6A:7d}} 
        sub     c                 ;{{1A6B:91}} 
        ld      a,h               ;{{1A6C:7c}} 
        sbc     a,b               ;{{1A6D:98}} 
        call    c,_gra_fill_sub_2_69;{{1A6E:dccb1a}} 
        ld      h,b               ;{{1A71:60}} 
        ld      l,c               ;{{1A72:69}} 
_gra_fill_sub_2_18:               ;{{Addr=$1a73 Code Calls/jump count: 1 Data use count: 0}}
        call    _gra_fill_sub_2_83;{{1A73:cde71a}} 
        ld      (RAM_b6b0),hl     ;{{1A76:22b0b6}} 
        ld      bc,($b6ac)        ;{{1A79:ed4bacb6}} 
        or      a                 ;{{1A7D:b7}} 
        sbc     hl,bc             ;{{1A7E:ed42}} 
        add     hl,bc             ;{{1A80:09}} 
        jr      z,_gra_fill_sub_2_34;{{1A81:2811}}  (+&11)
        jr      nc,_gra_fill_sub_2_29;{{1A83:3008}}  (+&08)
        call    gra_fill_sub_3    ;{{1A85:cdf11a}} 
        call    c,_gra_fill_sub_2_38;{{1A88:dc9d1a}} 
        jr      _gra_fill_sub_2_34;{{1A8B:1807}}  (+&07)
_gra_fill_sub_2_29:               ;{{Addr=$1a8d Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1A8D:e5}} 
        ld      h,b               ;{{1A8E:60}} 
        ld      l,c               ;{{1A8F:69}} 
        pop     bc                ;{{1A90:c1}} 
        call    _gra_fill_sub_2_69;{{1A91:cdcb1a}} 
_gra_fill_sub_2_34:               ;{{Addr=$1a94 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,($b6ae)        ;{{1A94:2aaeb6}} 
        ld      bc,(RAM_b6b0)     ;{{1A97:ed4bb0b6}} 
        scf                       ;{{1A9B:37}} 
        ret                       ;{{1A9C:c9}} 

_gra_fill_sub_2_38:               ;{{Addr=$1a9d Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{1A9D:d5}} 
        push    hl                ;{{1A9E:e5}} 
        ld      hl,(x1)           ;{{1A9F:2aa7b6}} 
        ld      de,$fff9          ;{{1AA2:11f9ff}} 
        add     hl,de             ;{{1AA5:19}} 
        pop     de                ;{{1AA6:d1}} 
        jr      nc,_gra_fill_sub_2_65;{{1AA7:301c}}  (+&1c)
        ld      (x1),hl           ;{{1AA9:22a7b6}} 
        ld      hl,(RAM_b6a5)     ;{{1AAC:2aa5b6}}  graphics fill buffer
        inc     hl                ;{{1AAF:23}} 
        ld      (hl),e            ;{{1AB0:73}} 
        inc     hl                ;{{1AB1:23}} 
        ld      (hl),d            ;{{1AB2:72}} 
        inc     hl                ;{{1AB3:23}} 
        pop     de                ;{{1AB4:d1}} 
        ld      (hl),e            ;{{1AB5:73}} 
        inc     hl                ;{{1AB6:23}} 
        ld      (hl),d            ;{{1AB7:72}} 
        inc     hl                ;{{1AB8:23}} 
        ld      (hl),c            ;{{1AB9:71}} 
        inc     hl                ;{{1ABA:23}} 
        ld      (hl),b            ;{{1ABB:70}} 
        inc     hl                ;{{1ABC:23}} 
        ld      a,(y2x)           ;{{1ABD:3aabb6}} 
        ld      (hl),a            ;{{1AC0:77}} 
        ld      (RAM_b6a5),hl     ;{{1AC1:22a5b6}}  graphics fill buffer
        ret                       ;{{1AC4:c9}} 

_gra_fill_sub_2_65:               ;{{Addr=$1ac5 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{1AC5:af}} 
        ld      (y21),a           ;{{1AC6:32a9b6}} 
        pop     de                ;{{1AC9:d1}} 
        ret                       ;{{1ACA:c9}} 

_gra_fill_sub_2_69:               ;{{Addr=$1acb Code Calls/jump count: 2 Data use count: 0}}
        call    _gra_fill_sub_2_73;{{1ACB:cdd71a}} 
        call    gra_fill_sub_5    ;{{1ACE:cd421b}} 
        call    nc,gra_fill_sub_3 ;{{1AD1:d4f11a}} 
        call    c,_gra_fill_sub_2_38;{{1AD4:dc9d1a}} 
_gra_fill_sub_2_73:               ;{{Addr=$1ad7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(y2x)           ;{{1AD7:3aabb6}} 
        cpl                       ;{{1ADA:2f}} 
        ld      (y2x),a           ;{{1ADB:32abb6}} 
_gra_fill_sub_2_76:               ;{{Addr=$1ade Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{1ADE:1b}} 
        ld      a,(y2x)           ;{{1ADF:3aabb6}} 
        or      a                 ;{{1AE2:b7}} 
        ret     z                 ;{{1AE3:c8}} 

        inc     de                ;{{1AE4:13}} 
        inc     de                ;{{1AE5:13}} 
        ret                       ;{{1AE6:c9}} 

_gra_fill_sub_2_83:               ;{{Addr=$1ae7 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{1AE7:af}} 
        ld      bc,(graphics_window_y_of_one_side_);{{1AE8:ed4b9fb6}}  graphics window top edge
        call    _gra_fill_sub_3_1 ;{{1AEC:cdf31a}} 
        dec     hl                ;{{1AEF:2b}} 
        ret                       ;{{1AF0:c9}} 

;;==================================================================================
;; gra fill sub 3

gra_fill_sub_3:                   ;{{Addr=$1af1 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$ff             ;{{1AF1:3eff}} 
_gra_fill_sub_3_1:                ;{{Addr=$1af3 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{1AF3:c5}} 
        push    de                ;{{1AF4:d5}} 
        push    hl                ;{{1AF5:e5}} 
        push    af                ;{{1AF6:f5}} 
        call    gra_fill_sub_6    ;{{1AF7:cd4f1b}} 
        pop     af                ;{{1AFA:f1}} 
        ld      b,a               ;{{1AFB:47}} 
_gra_fill_sub_3_8:                ;{{Addr=$1afc Code Calls/jump count: 1 Data use count: 0}}
        call    gra_fill_sub_4    ;{{1AFC:cd341b}} 
        inc     b                 ;{{1AFF:04}} 
        djnz    _gra_fill_sub_3_14;{{1B00:1004}}  (+&04)
        jr      nc,_gra_fill_sub_5_5;{{1B02:3047}}  (+&47)
        xor     (hl)              ;{{1B04:ae}} 
        ld      (hl),a            ;{{1B05:77}} 
_gra_fill_sub_3_14:               ;{{Addr=$1b06 Code Calls/jump count: 1 Data use count: 0}}
        jr      c,_gra_fill_sub_5_5;{{1B06:3843}}  (+&43)
        ex      (sp),hl           ;{{1B08:e3}} 
        inc     hl                ;{{1B09:23}} 
        ex      (sp),hl           ;{{1B0A:e3}} 
        sbc     hl,de             ;{{1B0B:ed52}} 
        jr      z,_gra_fill_sub_5_5;{{1B0D:283c}}  (+&3c)
        add     hl,de             ;{{1B0F:19}} 
        call    SCR_PREV_LINE     ;{{1B10:cd390c}}  SCR PREV LINE
        jr      _gra_fill_sub_3_8 ;{{1B13:18e7}}  (-&19)
_gra_fill_sub_3_23:               ;{{Addr=$1b15 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{1B15:c5}} 
        push    de                ;{{1B16:d5}} 
        push    hl                ;{{1B17:e5}} 
        ld      bc,(graphics_window_y_of_other_side_);{{1B18:ed4ba1b6}}  graphics window bottom edge
        call    gra_fill_sub_6    ;{{1B1C:cd4f1b}} 
_gra_fill_sub_3_28:               ;{{Addr=$1b1f Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{1B1F:b7}} 
        sbc     hl,de             ;{{1B20:ed52}} 
        jr      z,_gra_fill_sub_5_5;{{1B22:2827}}  (+&27)
        add     hl,de             ;{{1B24:19}} 
        call    SCR_NEXT_LINE     ;{{1B25:cd1f0c}}  SCR NEXT LINE
        call    gra_fill_sub_4    ;{{1B28:cd341b}} 
        jr      z,_gra_fill_sub_5_5;{{1B2B:281e}}  (+&1e)
        xor     (hl)              ;{{1B2D:ae}} 
        ld      (hl),a            ;{{1B2E:77}} 
        ex      (sp),hl           ;{{1B2F:e3}} 
        dec     hl                ;{{1B30:2b}} 
        ex      (sp),hl           ;{{1B31:e3}} 
        jr      _gra_fill_sub_3_28;{{1B32:18eb}}  (-&15)

;;==================================================================================
;; gra fill sub 4

gra_fill_sub_4:                   ;{{Addr=$1b34 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(GRAPHICS_PEN)  ;{{1B34:3aa3b6}}  graphics pen
        xor     (hl)              ;{{1B37:ae}} 
        and     c                 ;{{1B38:a1}} 
        ret     z                 ;{{1B39:c8}} 

        ld      a,($b6aa)         ;{{1B3A:3aaab6}} 
        xor     (hl)              ;{{1B3D:ae}} 
        and     c                 ;{{1B3E:a1}} 
        ret     z                 ;{{1B3F:c8}} 

        scf                       ;{{1B40:37}} 
        ret                       ;{{1B41:c9}} 

;;==================================================================================
;; gra fill sub 5

gra_fill_sub_5:                   ;{{Addr=$1b42 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{1B42:c5}} 
        push    de                ;{{1B43:d5}} 
        push    hl                ;{{1B44:e5}} 
        call    SCR_DOT_POSITION  ;{{1B45:cdaf0b}} ; SCR DOT POSITION
        call    gra_fill_sub_4    ;{{1B48:cd341b}} 
_gra_fill_sub_5_5:                ;{{Addr=$1b4b Code Calls/jump count: 5 Data use count: 0}}
        pop     hl                ;{{1B4B:e1}} 
        pop     de                ;{{1B4C:d1}} 
        pop     bc                ;{{1B4D:c1}} 
        ret                       ;{{1B4E:c9}} 

;;==================================================================================
;; gra fill sub 6

gra_fill_sub_6:                   ;{{Addr=$1b4f Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{1B4F:c5}} 
        push    de                ;{{1B50:d5}} 
        call    SCR_DOT_POSITION  ;{{1B51:cdaf0b}} ; SCR DOT POSITION
        pop     de                ;{{1B54:d1}} 
        ex      (sp),hl           ;{{1B55:e3}} 
        call    SCR_DOT_POSITION  ;{{1B56:cdaf0b}} ; SCR DOT POSITION
        ex      de,hl             ;{{1B59:eb}} 
        pop     hl                ;{{1B5A:e1}} 
        ret                       ;{{1B5B:c9}} 






;;***Keyboard.asm
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




;;***Sound.asm
;; SOUND ROUTINES
;;============================================================================
;; SOUND RESET

;; for each channel:
;; &00 - channel number (0,1,2)
;; &01 - mixer value for tone (also used for active mask)
;; &02 - mixer value for noise
;; &03 - status
;; status bit 0=rendezvous channel A
;; status bit 1=rendezvous channel B
;; status bit 2=rendezvous channel C
;; status bit 3=hold

;; &04 - bit 0 = tone envelope active
;; &07 - bit 0 = volume envelope active

;; &08,&09 - duration of sound or envelope repeat count
;; &0a,&0b - volume envelope pointer reload
;; &0c - volume envelope step down count
;; &0d,&0e - current volume envelope pointer
;; &0f - current volume for channel (bit 7 set if has noise)
;; &10 - volume envelope current step down count

;; &11,&12 - tone envelope pointer reload
;; &13 - number of sections in tone remaining
;; &14,&15 - current tone pointer
;; &16 - low byte tone for channel
;; &17 - high byte tone for channel
;; &18 - tone envelope current step down count

;; &19 - read position in queue
;; &1a - number of items in the queue
;; &1b - write position in queue
;; &1c - number of items free in queue
;; &1d - low byte event 
;; &1e - high byte event (set to 0 to disarm event)



SOUND_RESET:                      ;{{Addr=$1fe9 Code Calls/jump count: 3 Data use count: 1}}
        ld      hl,used_by_sound_routines_C;{{1FE9:21edb1}}  channels active at SOUND HOLD

;; clear flags
;; b1ed - channels active at SOUND HOLD
;; b1ee - sound channels active
;; b1ef - sound timer?
;; b1f0 - ??
        ld      b,$04             ;{{1FEC:0604}} 
_sound_reset_2:                   ;{{Addr=$1fee Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{1FEE:3600}} 
        inc     hl                ;{{1FF0:23}} 
        djnz    _sound_reset_2    ;{{1FF1:10fb}} 

;; HL  = event block (b1f1)
        ld      de,sound_processing_function;{{1FF3:118b20}} ; sound event function ##LABEL##
        ld      b,$81             ;{{1FF6:0681}} ; asynchronous event, near address
                                  ;; C = rom select, but unused because it's a near address
        call    KL_INIT_EVENT     ;{{1FF8:cdd201}}  KL INIT EVENT

        ld      a,$3f             ;{{1FFB:3e3f}}  default mixer value (noise/tone off + I/O)
        ld      ($b2b5),a         ;{{1FFD:32b5b2}} 

        ld      hl,FSound_Channel_A_;{{2000:21f8b1}} ; data for channel A
        ld      bc,$003d          ;{{2003:013d00}} ; size of data for each channel ##LIT##;WARNING: Code area used as literal
        ld      de,$0108          ;{{2006:110801}} ; D = mixer value for tone (channel A) ##LIT##;WARNING: Code area used as literal
                                  ;; E = mixer value for noise (channel A)

;; initialise channel data
        xor     a                 ;{{2009:af}} 

_sound_reset_14:                  ;{{Addr=$200a Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{200A:77}} ; channel number
        inc     hl                ;{{200B:23}} 
        ld      (hl),d            ;{{200C:72}} ; mixer tone for channel
        inc     hl                ;{{200D:23}} 
        ld      (hl),e            ;{{200E:73}} ; mixer noise for channel
        add     hl,bc             ;{{200F:09}} ; update channel data pointer

        inc     a                 ;{{2010:3c}} ; increment channel number

        ex      de,hl             ;{{2011:eb}} ; update tone/noise mixer for next channel shifting it left once
        add     hl,hl             ;{{2012:29}} 
        ex      de,hl             ;{{2013:eb}} 

        cp      $03               ;{{2014:fe03}} ; setup all channels?
        jr      nz,_sound_reset_14;{{2016:20f2}} 

        ld      c,$07             ;{{2018:0e07}}  all channels active
_sound_reset_27:                  ;{{Addr=$201a Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{201A:dde5}} 
        push    hl                ;{{201C:e5}} 
        ld      hl,used_by_sound_routines_E;{{201D:21f0b1}} 
        inc     (hl)              ;{{2020:34}} 
        push    hl                ;{{2021:e5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2022:dd21b9b1}} 
        ld      a,c               ;{{2026:79}}  channels active

_sound_reset_34:                  ;{{Addr=$2027 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{2027:cd0922}} ; get next active channel
        push    af                ;{{202A:f5}} 
        push    bc                ;{{202B:c5}} 
        call    _sound_unknown_function_2;{{202C:cd8622}} ; update channels that are active
        call    disable_channel   ;{{202F:cde723}} ; disable channel
        push    ix                ;{{2032:dde5}} 
        pop     de                ;{{2034:d1}} 
        inc     de                ;{{2035:13}} 
        inc     de                ;{{2036:13}} 
        inc     de                ;{{2037:13}} 
        ld      l,e               ;{{2038:6b}} 
        ld      h,d               ;{{2039:62}} 
        inc     de                ;{{203A:13}} 
        ld      bc,$003b          ;{{203B:013b00}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),$00          ;{{203E:3600}} 
        ldir                      ;{{2040:edb0}} 
        ld      (ix+$1c),$04      ;{{2042:dd361c04}} ; number of spaces in queue
        pop     bc                ;{{2046:c1}} 
        pop     af                ;{{2047:f1}} 
        jr      nz,_sound_reset_34;{{2048:20dd}}  (-&23)


        pop     hl                ;{{204A:e1}} 
        dec     (hl)              ;{{204B:35}} 
        pop     hl                ;{{204C:e1}} 
        pop     ix                ;{{204D:dde1}} 
        ret                       ;{{204F:c9}} 

;;==========================================================================
;; SOUND HOLD
;;
;; - Stop firmware handling sound
;; - turn off all volume registers
;;
;; carry false - already stopped
;; carry true - sound has been held
SOUND_HOLD:                       ;{{Addr=$2050 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,used_by_sound_routines_D;{{2050:21eeb1}} ; sound channels active
        di                        ;{{2053:f3}} 
        ld      a,(hl)            ;{{2054:7e}} ; get channels that were active
        ld      (hl),$00          ;{{2055:3600}} ; no channels active
        ei                        ;{{2057:fb}} 
        or      a                 ;{{2058:b7}} ; already stopped?
        ret     z                 ;{{2059:c8}} 

        dec     hl                ;{{205A:2b}} 
        ld      (hl),a            ;{{205B:77}} ; channels held

;; set all AY volume registers to zero to silence sound
        ld      l,$03             ;{{205C:2e03}} 
        ld      c,$00             ;{{205E:0e00}}  set zero volume

_sound_hold_11:                   ;{{Addr=$2060 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$07             ;{{2060:3e07}}  AY Mixer register
        add     a,l               ;{{2062:85}}  add on value to get volume register
                                  ; A = AY volume register (10,9,8)
        call    MC_SOUND_REGISTER ;{{2063:cd6308}}  MC SOUND REGISTER
        dec     l                 ;{{2066:2d}} 
        jr      nz,_sound_hold_11 ;{{2067:20f7}} 
 
        scf                       ;{{2069:37}} 
        ret                       ;{{206A:c9}} 


;;==========================================================================
;; SOUND CONTINUE

SOUND_CONTINUE:                   ;{{Addr=$206b Code Calls/jump count: 2 Data use count: 1}}
        ld      de,used_by_sound_routines_C;{{206B:11edb1}} ; channels active at SOUND HELD
        ld      a,(de)            ;{{206E:1a}} 
        or      a                 ;{{206F:b7}} 
        ret     z                 ;{{2070:c8}} 

;; at least one channel was held

        push    de                ;{{2071:d5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2072:dd21b9b1}} 
_sound_continue_6:                ;{{Addr=$2076 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{2076:cd0922}}  get next active channel
        push    af                ;{{2079:f5}} 
        ld      a,(ix+$0f)        ;{{207A:dd7e0f}}  volume for channel
        call    c,set_volume_for_channel;{{207D:dcde23}}  set channel volume
        pop     af                ;{{2080:f1}} 
        jr      nz,_sound_continue_6;{{2081:20f3}} repeat next held channel

        ex      (sp),hl           ;{{2083:e3}} 
        ld      a,(hl)            ;{{2084:7e}} 
        ld      (hl),$00          ;{{2085:3600}} 
        inc     hl                ;{{2087:23}} 
        ld      (hl),a            ;{{2088:77}} 
        pop     hl                ;{{2089:e1}} 
        ret                       ;{{208A:c9}} 

;;===============================================================================
;; sound processing function

sound_processing_function:        ;{{Addr=$208b Code Calls/jump count: 0 Data use count: 1}}
        push    ix                ;{{208B:dde5}} 
        ld      a,(used_by_sound_routines_D);{{208D:3aeeb1}}  sound channels active
        or      a                 ;{{2090:b7}} 
        jr      z,_sound_processing_function_33;{{2091:283d}} 

;; A = channel to process
        push    af                ;{{2093:f5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2094:dd21b9b1}} 
_sound_processing_function_6:     ;{{Addr=$2098 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$003f          ;{{2098:013f00}} ##LIT##;WARNING: Code area used as literal
_sound_processing_function_7:     ;{{Addr=$209b Code Calls/jump count: 1 Data use count: 0}}
        add     ix,bc             ;{{209B:dd09}} 
        srl     a                 ;{{209D:cb3f}} 
        jr      nc,_sound_processing_function_7;{{209F:30fa}} 

        push    af                ;{{20A1:f5}} 
        ld      a,(ix+$04)        ;{{20A2:dd7e04}} 
        rra                       ;{{20A5:1f}} 
        call    c,tone_envelope_function;{{20A6:dc1f24}}  update tone envelope

        ld      a,(ix+$07)        ;{{20A9:dd7e07}} 
        rra                       ;{{20AC:1f}} 
        call    c,update_volume_envelope;{{20AD:dc1f23}}  update volume envelope

        call    c,process_queue_item;{{20B0:dc1322}}  process queue
        pop     af                ;{{20B3:f1}} 
        jr      nz,_sound_processing_function_6;{{20B4:20e2}} ; process next..?

        pop     bc                ;{{20B6:c1}} 
        ld      a,(used_by_sound_routines_D);{{20B7:3aeeb1}}  sound channels active
        cpl                       ;{{20BA:2f}} 
        and     b                 ;{{20BB:a0}} 
        jr      z,_sound_processing_function_33;{{20BC:2812}}  (+&12)

        ld      ix,base_address_for_calculating_relevant_So;{{20BE:dd21b9b1}} 
        ld      de,$003f          ;{{20C2:113f00}} ##LIT##;WARNING: Code area used as literal
_sound_processing_function_27:    ;{{Addr=$20c5 Code Calls/jump count: 1 Data use count: 0}}
        add     ix,de             ;{{20C5:dd19}} 
        srl     a                 ;{{20C7:cb3f}} 
        push    af                ;{{20C9:f5}} 
        call    c,disable_channel ;{{20CA:dce723}}  mixer
        pop     af                ;{{20CD:f1}} 
        jr      nz,_sound_processing_function_27;{{20CE:20f5}}  (-&0b)

;; ???
_sound_processing_function_33:    ;{{Addr=$20d0 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{20D0:af}} 
        ld      (used_by_sound_routines_E),a;{{20D1:32f0b1}} 
        pop     ix                ;{{20D4:dde1}} 
        ret                       ;{{20D6:c9}} 

;;====================================================
;; process sound

process_sound:                    ;{{Addr=$20d7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,used_by_sound_routines_D;{{20D7:21eeb1}} ; sound active flag?
        ld      a,(hl)            ;{{20DA:7e}} 
        or      a                 ;{{20DB:b7}} 
        ret     z                 ;{{20DC:c8}} 
;; sound is active

        inc     hl                ;{{20DD:23}} ; sound timer?
        dec     (hl)              ;{{20DE:35}} 
        ret     nz                ;{{20DF:c0}} 

        ld      b,a               ;{{20E0:47}} 
        inc     (hl)              ;{{20E1:34}} 
        inc     hl                ;{{20E2:23}} 

        ld      a,(hl)            ;{{20E3:7e}} ; b1f0
        or      a                 ;{{20E4:b7}} 
        ret     nz                ;{{20E5:c0}} 

        dec     hl                ;{{20E6:2b}} 
        ld      (hl),$03          ;{{20E7:3603}} 

        ld      hl,RAM_b1be       ;{{20E9:21beb1}} 
        ld      de,$003f          ;{{20EC:113f00}} ##LIT##;WARNING: Code area used as literal
        xor     a                 ;{{20EF:af}} 
_process_sound_18:                ;{{Addr=$20f0 Code Calls/jump count: 2 Data use count: 0}}
        add     hl,de             ;{{20F0:19}} 
        srl     b                 ;{{20F1:cb38}} 
        jr      nc,_process_sound_18;{{20F3:30fb}}  (-&05)

        dec     (hl)              ;{{20F5:35}} 
        jr      nz,_process_sound_27;{{20F6:2005}}  (+&05)
        dec     hl                ;{{20F8:2b}} 
        rlc     (hl)              ;{{20F9:cb06}} 
        adc     a,d               ;{{20FB:8a}} 
        inc     hl                ;{{20FC:23}} 
_process_sound_27:                ;{{Addr=$20fd Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{20FD:23}} 
        dec     (hl)              ;{{20FE:35}} 
        jr      nz,_process_sound_34;{{20FF:2005}}  (+&05)
        inc     hl                ;{{2101:23}} 
        rlc     (hl)              ;{{2102:cb06}} 
        adc     a,d               ;{{2104:8a}} 
        dec     hl                ;{{2105:2b}} 
_process_sound_34:                ;{{Addr=$2106 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{2106:2b}} 
        inc     b                 ;{{2107:04}} 
        djnz    _process_sound_18 ;{{2108:10e6}}  (-&1a)
        or      a                 ;{{210A:b7}} 
        ret     z                 ;{{210B:c8}} 

        ld      hl,used_by_sound_routines_E;{{210C:21f0b1}} 
        ld      (hl),a            ;{{210F:77}} 
        inc     hl                ;{{2110:23}} 
;; HL = event block
;; kick off event
        jp      KL_EVENT          ;{{2111:c3e201}}  KL EVENT


;;============================================================================
;; SOUND QUEUE
;; HL = sound data
;;byte 0 - channel status byte 
;; bit 0 = send sound to channel A
;; bit 1 = send sound to channel B
;; bit 2 = send sound to channel C
;; bit 3 = rendezvous with channel A
;; bit 4 = rendezvous with channel B
;; bit 5 = rendezvous with channel C
;; bit 6 = hold sound channel
;; bit 7 = flush sound channel

;;byte 1 - volume envelope to use 
;;byte 2 - tone envelope to use 
;;bytes 3&4 - tone period (0 = no tone)
;;byte 5 - noise period (0 = no noise)
;;byte 6 - start volume 
;;bytes 7&8 - duration of the sound, or envelope repeat count 


SOUND_QUEUE:                      ;{{Addr=$2114 Code Calls/jump count: 1 Data use count: 1}}
        call    SOUND_CONTINUE    ;{{2114:cd6b20}}  SOUND CONTINUE
        ld      a,(hl)            ;{{2117:7e}}  channel status byte
        and     $07               ;{{2118:e607}} 
        scf                       ;{{211A:37}} 
        ret     z                 ;{{211B:c8}} 

        ld      c,a               ;{{211C:4f}} 
        or      (hl)              ;{{211D:b6}} 
        call    m,_sound_reset_27 ;{{211E:fc1a20}} 
        ld      b,c               ;{{2121:41}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2122:dd21b9b1}} 
;; get channel address
        ld      de,$003f          ;{{2126:113f00}} ##LIT##;WARNING: Code area used as literal
        xor     a                 ;{{2129:af}} 

_sound_queue_12:                  ;{{Addr=$212a Code Calls/jump count: 2 Data use count: 0}}
        add     ix,de             ;{{212A:dd19}} 
        srl     b                 ;{{212C:cb38}} 
        jr      nc,_sound_queue_12;{{212E:30fa}}  (-&06)

        ld      (ix+$1e),d        ;{{2130:dd721e}} ; disarm event
        cp      (ix+$1c)          ;{{2133:ddbe1c}} ; number of spaces in queue
        ccf                       ;{{2136:3f}} 
        sbc     a,a               ;{{2137:9f}} 
        inc     b                 ;{{2138:04}} 
        djnz    _sound_queue_12   ;{{2139:10ef}} 

        or      a                 ;{{213B:b7}} 
        ret     nz                ;{{213C:c0}} 

        ld      b,c               ;{{213D:41}} 
        ld      a,(hl)            ;{{213E:7e}} ; channel status
        rra                       ;{{213F:1f}} 
        rra                       ;{{2140:1f}} 
        rra                       ;{{2141:1f}} 
        or      b                 ;{{2142:b0}} 
        and     $0f               ;{{2143:e60f}} 
        ld      c,a               ;{{2145:4f}} 
        push    hl                ;{{2146:e5}} 
        ld      hl,used_by_sound_routines_E;{{2147:21f0b1}} 
        inc     (hl)              ;{{214A:34}} 
        ex      (sp),hl           ;{{214B:e3}} 
        inc     hl                ;{{214C:23}} 
        ld      ix,base_address_for_calculating_relevant_So;{{214D:dd21b9b1}} 

_sound_queue_37:                  ;{{Addr=$2151 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$003f          ;{{2151:113f00}} ##LIT##;WARNING: Code area used as literal
_sound_queue_38:                  ;{{Addr=$2154 Code Calls/jump count: 1 Data use count: 0}}
        add     ix,de             ;{{2154:dd19}} 
        srl     b                 ;{{2156:cb38}} 
        jr      nc,_sound_queue_38;{{2158:30fa}}  (-&06)

        push    hl                ;{{215A:e5}} 
        push    bc                ;{{215B:c5}} 
        ld      a,(ix+$1b)        ;{{215C:dd7e1b}}  write pointer in queue
        inc     (ix+$1b)          ;{{215F:dd341b}}  increment for next item
        dec     (ix+$1c)          ;{{2162:dd351c}} ; number of spaces in queue
        ex      de,hl             ;{{2165:eb}} 
        call    _sound_queue_84   ;{{2166:cd9c21}} ; get sound queue slot
        push    hl                ;{{2169:e5}} 
        ex      de,hl             ;{{216A:eb}} 
        ld      a,(ix+$01)        ;{{216B:dd7e01}} ; channel's active flag
        cpl                       ;{{216E:2f}} 
        and     c                 ;{{216F:a1}} 
        ld      (de),a            ;{{2170:12}} 
        inc     de                ;{{2171:13}} 
        ld      a,(hl)            ;{{2172:7e}} 
        inc     hl                ;{{2173:23}} 
        add     a,a               ;{{2174:87}} 
        add     a,a               ;{{2175:87}} 
        add     a,a               ;{{2176:87}} 
        add     a,a               ;{{2177:87}} 
        ld      b,a               ;{{2178:47}} 
        ld      a,(hl)            ;{{2179:7e}} 
        inc     hl                ;{{217A:23}} 
        and     $0f               ;{{217B:e60f}} 
        or      b                 ;{{217D:b0}} 
        ld      (de),a            ;{{217E:12}} 
        inc     de                ;{{217F:13}} 
        ld      bc,$0006          ;{{2180:010600}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2183:edb0}} 
        pop     hl                ;{{2185:e1}} 
        ld      a,(ix+$1a)        ;{{2186:dd7e1a}} ; number of items in the queue
        inc     (ix+$1a)          ;{{2189:dd341a}} 
        or      (ix+$03)          ;{{218C:ddb603}} ; status
        call    z,_process_queue_item_5;{{218F:cc1f22}} 
        pop     bc                ;{{2192:c1}} 
        pop     hl                ;{{2193:e1}} 
        inc     b                 ;{{2194:04}} 
        djnz    _sound_queue_37   ;{{2195:10ba}} 

        ex      (sp),hl           ;{{2197:e3}} 
        dec     (hl)              ;{{2198:35}} 
        pop     hl                ;{{2199:e1}} 
        scf                       ;{{219A:37}} 
        ret                       ;{{219B:c9}} 

;; A = index in queue
_sound_queue_84:                  ;{{Addr=$219c Code Calls/jump count: 2 Data use count: 0}}
        and     $03               ;{{219C:e603}} 
        add     a,a               ;{{219E:87}} 
        add     a,a               ;{{219F:87}} 
        add     a,a               ;{{21A0:87}} 
        add     a,$1f             ;{{21A1:c61f}} 
        push    ix                ;{{21A3:dde5}} 
        pop     hl                ;{{21A5:e1}} 
        add     a,l               ;{{21A6:85}} 
        ld      l,a               ;{{21A7:6f}} 
        adc     a,h               ;{{21A8:8c}} 
        sub     l                 ;{{21A9:95}} 
        ld      h,a               ;{{21AA:67}} 
        ret                       ;{{21AB:c9}} 

;;==========================================================================
;; SOUND RELEASE

SOUND_RELEASE:                    ;{{Addr=$21ac Code Calls/jump count: 0 Data use count: 1}}
        ld      l,a               ;{{21AC:6f}} 
        call    SOUND_CONTINUE    ;{{21AD:cd6b20}}  SOUND CONTINUE
        ld      a,l               ;{{21B0:7d}} 
        and     $07               ;{{21B1:e607}} 
        ret     z                 ;{{21B3:c8}} 

        ld      hl,used_by_sound_routines_E;{{21B4:21f0b1}} 
        inc     (hl)              ;{{21B7:34}} 
        push    hl                ;{{21B8:e5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{21B9:dd21b9b1}} 
_sound_release_9:                 ;{{Addr=$21bd Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{21BD:cd0922}}  get next active channel
        push    af                ;{{21C0:f5}} 
        bit     3,(ix+$03)        ;{{21C1:ddcb035e}}  held?
        call    nz,_process_queue_item_3;{{21C5:c41922}}  process queue item
        pop     af                ;{{21C8:f1}} 
        jr      nz,_sound_release_9;{{21C9:20f2}}  (-&0e)
        pop     hl                ;{{21CB:e1}} 
        dec     (hl)              ;{{21CC:35}} 
        ret                       ;{{21CD:c9}} 


;;============================================================================
;; SOUND CHECK
;; in:
;; bit 0 = channel 0
;; bit 1 = channel 1
;; bit 2 = channel 2
;;
;; result:
;; xxxxx000 - not allowed
;; xxxxx001 - 0
;; xxxxx010 - 1
;; xxxxx011 - 0
;; xxxxx100 - 2
;; xxxxx101 - 0
;; xxxxx110 - 1
;; xxxxx111 - 2
;; out:
;;bits 0 to 2 - the number of free spaces in the sound queue 
;;bit 3 - trying to rendezvous with channel A 
;;bit 4 - trying to rendezvous with channel B 
;;bit 5 - trying to rendezvous with channel C 
;;bit 6 - holding the channel 
;;bit 7 - producing a sound 

SOUND_CHECK:                      ;{{Addr=$21ce Code Calls/jump count: 0 Data use count: 1}}
        and     $07               ;{{21CE:e607}} 
        ret     z                 ;{{21D0:c8}} 

        ld      hl,base_address_for_calculating_relevant_so_B;{{21D1:21bcb1}} ; sound data - 63
        ld      de,$003f          ;{{21D4:113f00}} ; 63 ##LIT##;WARNING: Code area used as literal

_sound_check_4:                   ;{{Addr=$21d7 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{21D7:19}} 
        rra                       ;{{21D8:1f}} 
        jr      nc,_sound_check_4 ;{{21D9:30fc}} ; bit a zero?

        di                        ;{{21DB:f3}} 
        ld      a,(hl)            ;{{21DC:7e}} 
        add     a,a               ;{{21DD:87}} ; x2
        add     a,a               ;{{21DE:87}} ; x4
        add     a,a               ;{{21DF:87}} ; x8
        ld      de,$0019          ;{{21E0:111900}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{21E3:19}} 
        or      (hl)              ;{{21E4:b6}} 
        inc     hl                ;{{21E5:23}} 
        inc     hl                ;{{21E6:23}} 
        ld      (hl),$00          ;{{21E7:3600}} 
        ei                        ;{{21E9:fb}} 
        ret                       ;{{21EA:c9}} 

;;============================================================================
;; SOUND ARM EVENT
;; 
;; Sets up an event which will be activated when a space occurs in a sound queue.
;; if there is space the event is kicked immediately.
;;
;;
;; A:
;; bit 0 = channel 0
;; bit 1 = channel 1
;; bit 2 = channel 2
;; 
;; result:
;; xxxxx000 - not allowed
;; xxxxx001 - 0
;; xxxxx010 - 1
;; xxxxx011 - 0
;; xxxxx100 - 2
;; xxxxx101 - 0
;; xxxxx110 - 1
;; xxxxx111 - 2
;;
;; HL = event function
SOUND_ARM_EVENT:                  ;{{Addr=$21eb Code Calls/jump count: 0 Data use count: 1}}
        and     $07               ;{{21EB:e607}} 
        ret     z                 ;{{21ED:c8}} 

        ex      de,hl             ;{{21EE:eb}} ; DE = event function

;; get address of data
        ld      hl,base_address_for_calculating_relevant_so_D;{{21EF:21d5b1}} 
        ld      bc,$003f          ;{{21F2:013f00}} ##LIT##;WARNING: Code area used as literal
_sound_arm_event_5:               ;{{Addr=$21f5 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{21F5:09}} 
        rra                       ;{{21F6:1f}} 
        jr      nc,_sound_arm_event_5;{{21F7:30fc}} 

        xor     a                 ;{{21F9:af}} ; 0=no space in queue. !=0  space in the queue
        di                        ;{{21FA:f3}} ; stop event processing changing the value (this is a data fence)
        cp      (hl)              ;{{21FB:be}} ; +&1c -> number of events remaining in queue
        jr      nz,_sound_arm_event_13;{{21FC:2001}} ; if it has space, disarm and call

;; no space in the queue, arm the event
        ld      a,d               ;{{21FE:7a}} 

;; write function
_sound_arm_event_13:              ;{{Addr=$21ff Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{21FF:23}} 
        ld      (hl),e            ;{{2200:73}} ; +&1d
        inc     hl                ;{{2201:23}} 
        ld      (hl),a            ;{{2202:77}} ; +&1e if zero means event is disarmed
        ei                        ;{{2203:fb}} 
        ret     z                 ;{{2204:c8}} ; queue is full
;; queue has space
        ex      de,hl             ;{{2205:eb}} 
        jp      KL_EVENT          ;{{2206:c3e201}}  KL EVENT

;;==================================================================================
;; get next active channel
;; A = channel mask (updated)
;; IX = channel pointer
get_next_active_channel:          ;{{Addr=$2209 Code Calls/jump count: 3 Data use count: 0}}
        ld      de,$003f          ;{{2209:113f00}}  63 ##LIT##;WARNING: Code area used as literal
_get_next_active_channel_1:       ;{{Addr=$220c Code Calls/jump count: 1 Data use count: 0}}
        add     ix,de             ;{{220C:dd19}} 
        srl     a                 ;{{220E:cb3f}} 
        ret     c                 ;{{2210:d8}} 
        jr      _get_next_active_channel_1;{{2211:18f9}}  (-&07)

;;==================================================================================
;; process queue item

process_queue_item:               ;{{Addr=$2213 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(ix+$1a)        ;{{2213:dd7e1a}}  has items in the queue
        or      a                 ;{{2216:b7}} 
        jr      z,_sound_unknown_function_2;{{2217:286d}} 

;; process queue item
_process_queue_item_3:            ;{{Addr=$2219 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(ix+$19)        ;{{2219:dd7e19}}  read pointer in queue
        call    _sound_queue_84   ;{{221C:cd9c21}}  get sound queue slot

;;----------------------------
_process_queue_item_5:            ;{{Addr=$221f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{221F:7e}}  channel status byte
;; bit 0=rendezvous channel A
;; bit 1=rendezvous channel B
;; bit 2=rendezvous channel C
;; bit 3=hold
        or      a                 ;{{2220:b7}} 
        jr      z,_process_queue_item_15;{{2221:280d}} 

        bit     3,a               ;{{2223:cb5f}}  hold channel?
        jr      nz,sound_unknown_function;{{2225:2059}}  

        push    hl                ;{{2227:e5}} 
        ld      (hl),$00          ;{{2228:3600}} 
        call    process_rendezvous;{{222A:cd9022}}  process rendezvous
        pop     hl                ;{{222D:e1}} 
        jr      nc,_sound_unknown_function_2;{{222E:3056}} 

_process_queue_item_15:           ;{{Addr=$2230 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$03),$10      ;{{2230:dd360310}}  playing

        inc     hl                ;{{2234:23}} 
        ld      a,(hl)            ;{{2235:7e}}  	
        and     $f0               ;{{2236:e6f0}} 
        push    af                ;{{2238:f5}} 
        xor     (hl)              ;{{2239:ae}} 
        ld      e,a               ;{{223A:5f}}  tone envelope number
        inc     hl                ;{{223B:23}} 
        ld      c,(hl)            ;{{223C:4e}}  tone low
        inc     hl                ;{{223D:23}} 
        ld      d,(hl)            ;{{223E:56}}  tone period high
        inc     hl                ;{{223F:23}} 

        or      d                 ;{{2240:b2}}  tone period set?
        or      c                 ;{{2241:b1}} 
        jr      z,_process_queue_item_34;{{2242:2808}} 
;; 
        push    hl                ;{{2244:e5}} 
        call    set_tone_and_get_tone_envelope;{{2245:cd0824}}  set tone and tone envelope	
        ld      d,(ix+$01)        ;{{2248:dd5601}}  tone mixer value
        pop     hl                ;{{224B:e1}} 

_process_queue_item_34:           ;{{Addr=$224c Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{224C:4e}}  noise
        inc     hl                ;{{224D:23}} 
        ld      e,(hl)            ;{{224E:5e}}  start volume
        inc     hl                ;{{224F:23}} 
        ld      a,(hl)            ;{{2250:7e}}  duration of sound or envelope repeat count
        inc     hl                ;{{2251:23}} 
        ld      h,(hl)            ;{{2252:66}} 
        ld      l,a               ;{{2253:6f}} 
        pop     af                ;{{2254:f1}} 
        call    set_initial_values;{{2255:cdde22}} ; set noise

        ld      hl,used_by_sound_routines_D;{{2258:21eeb1}} ; channel active flag
        ld      b,(ix+$01)        ;{{225B:dd4601}} ; channels' active flag
        ld      a,(hl)            ;{{225E:7e}} 
        or      b                 ;{{225F:b0}} 
        ld      (hl),a            ;{{2260:77}} 
        xor     b                 ;{{2261:a8}} 
        jr      nz,_process_queue_item_53;{{2262:2003}}  (+&03)

        inc     hl                ;{{2264:23}} 
        ld      (hl),$03          ;{{2265:3603}} 

_process_queue_item_53:           ;{{Addr=$2267 Code Calls/jump count: 1 Data use count: 0}}
        inc     (ix+$19)          ;{{2267:dd3419}} ; increment read position in queue
        dec     (ix+$1a)          ;{{226A:dd351a}} ; number of items in the queue
;; 
        inc     (ix+$1c)          ;{{226D:dd341c}} ; increase space in the queue

;; there is a space in the queue...
        ld      a,(ix+$1e)        ;{{2270:dd7e1e}} ; high byte of event (0=disarmed)
        ld      (ix+$1e),$00      ;{{2273:dd361e00}} ; disarm event
        or      a                 ;{{2277:b7}} 
        ret     z                 ;{{2278:c8}} 

;; event is armed, kick it off.
        ld      h,a               ;{{2279:67}} 
        ld      l,(ix+$1d)        ;{{227A:dd6e1d}} 
        jp      KL_EVENT          ;{{227D:c3e201}}  KL EVENT

;;=============================================================================
;; sound unknown function
;; ?
sound_unknown_function:           ;{{Addr=$2280 Code Calls/jump count: 1 Data use count: 0}}
        res     3,(hl)            ;{{2280:cb9e}} 
        ld      (ix+$03),$08      ;{{2282:dd360308}} ; held

;; stop sound?
_sound_unknown_function_2:        ;{{Addr=$2286 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,used_by_sound_routines_D;{{2286:21eeb1}} ; sound channels active flag
        ld      a,(ix+$01)        ;{{2289:dd7e01}} ; channels' active flag
        cpl                       ;{{228C:2f}} 
        and     (hl)              ;{{228D:a6}} 
        ld      (hl),a            ;{{228E:77}} 
        ret                       ;{{228F:c9}} 

;;==============================================================
;; process rendezvous
process_rendezvous:               ;{{Addr=$2290 Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{2290:dde5}} 
        ld      b,a               ;{{2292:47}} 
        ld      c,(ix+$01)        ;{{2293:dd4e01}} ; channels' active flag
        ld      ix,FSound_Channel_A_;{{2296:dd21f8b1}} ; channel A's data
        bit     0,a               ;{{229A:cb47}} 
        jr      nz,_process_rendezvous_10;{{229C:200c}} 

        ld      ix,FSound_Channel_B_;{{229E:dd2137b2}} ; channel B's data
        bit     1,a               ;{{22A2:cb4f}} 
        jr      nz,_process_rendezvous_10;{{22A4:2004}} 
        ld      ix,FSound_Channel_C_;{{22A6:dd2176b2}} ; channel C's data

_process_rendezvous_10:           ;{{Addr=$22aa Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$03)        ;{{22AA:dd7e03}}  channels' rendezvous flags
        and     c                 ;{{22AD:a1}}  ignore rendezvous with self.
        jr      z,_process_rendezvous_31;{{22AE:2827}} 
          
        ld      a,b               ;{{22B0:78}} 
        cp      (ix+$01)          ;{{22B1:ddbe01}}  channels' active flag
        jr      z,_process_rendezvous_26;{{22B4:2819}}  ignore rendezvous with self (process own queue)

        push    ix                ;{{22B6:dde5}} 
        ld      ix,FSound_Channel_C_;{{22B8:dd2176b2}}  channel C's data
        bit     2,a               ;{{22BC:cb57}}  rendezvous channel C
        jr      nz,_process_rendezvous_21;{{22BE:2004}} 
        ld      ix,FSound_Channel_B_;{{22C0:dd2137b2}}  channel B's data

_process_rendezvous_21:           ;{{Addr=$22c4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(ix+$03)        ;{{22C4:dd7e03}}  channels' rendezvous flags
        and     c                 ;{{22C7:a1}}  ignore rendezvous with self.
        jr      z,_process_rendezvous_30;{{22C8:280c}} 
;; process us/other

        call    _process_queue_item_3;{{22CA:cd1922}}  process queue item
        pop     ix                ;{{22CD:dde1}} 
_process_rendezvous_26:           ;{{Addr=$22cf Code Calls/jump count: 1 Data use count: 0}}
        call    _process_queue_item_3;{{22CF:cd1922}}  process queue item
        pop     ix                ;{{22D2:dde1}} 
        scf                       ;{{22D4:37}} 
        ret                       ;{{22D5:c9}} 

_process_rendezvous_30:           ;{{Addr=$22d6 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{22D6:e1}} 
_process_rendezvous_31:           ;{{Addr=$22d7 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{22D7:dde1}} 
        ld      (ix+$03),b        ;{{22D9:dd7003}}  status
        or      a                 ;{{22DC:b7}} 
        ret                       ;{{22DD:c9}} 


;;=================================================================================

;; set initial values
;; C = noise value
;; E = initial volume
;; HL = duration of sound or envelope repeat count
set_initial_values:               ;{{Addr=$22de Code Calls/jump count: 1 Data use count: 0}}
        set     7,e               ;{{22DE:cbfb}} 
        ld      (ix+$0f),e        ;{{22E0:dd730f}} ; volume for channel?
        ld      e,a               ;{{22E3:5f}} 

;; duration of sound or envelope repeat count
        ld      a,l               ;{{22E4:7d}} 
        or      h                 ;{{22E5:b4}} 
        jr      nz,_set_initial_values_7;{{22E6:2001}} 

        dec     hl                ;{{22E8:2b}} 
_set_initial_values_7:            ;{{Addr=$22e9 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$08),l        ;{{22E9:dd7508}}  duration of sound or envelope repeat count
        ld      (ix+$09),h        ;{{22EC:dd7409}} 

        ld      a,c               ;{{22EF:79}}  if zero do not set noise
        or      a                 ;{{22F0:b7}} 
        jr      z,_set_initial_values_15;{{22F1:2808}} 

        ld      a,$06             ;{{22F3:3e06}}  PSG noise register
        call    MC_SOUND_REGISTER ;{{22F5:cd6308}}  MC SOUND REGISTER
        ld      a,(ix+$02)        ;{{22F8:dd7e02}} 

_set_initial_values_15:           ;{{Addr=$22fb Code Calls/jump count: 1 Data use count: 0}}
        or      d                 ;{{22FB:b2}} 
        call    update_mixer_for_channel;{{22FC:cde823}}  mixer for channel
        ld      a,e               ;{{22FF:7b}} 
        or      a                 ;{{2300:b7}} 
        jr      z,_set_initial_values_26;{{2301:280a}} 

        ld      hl,base_address_for_calculating_relevant_EN;{{2303:21a6b2}} 
        ld      d,$00             ;{{2306:1600}} 
        add     hl,de             ;{{2308:19}} 
        ld      a,(hl)            ;{{2309:7e}} 
        or      a                 ;{{230A:b7}} 
        jr      nz,_set_initial_values_27;{{230B:2003}} 

_set_initial_values_26:           ;{{Addr=$230d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,default_volume_envelope;{{230D:211b23}}  default volume envelope	
_set_initial_values_27:           ;{{Addr=$2310 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$0a),l        ;{{2310:dd750a}} 
        ld      (ix+$0b),h        ;{{2313:dd740b}} 
        call    _unknown_sound_function_13;{{2316:cdcd23}}  set volume envelope?
        jr      _update_volume_envelope_3;{{2319:180d}}  (+&0d)

;;=================================================================================
;; default volume envelope
default_volume_envelope:          ;{{Addr=$231b Data Calls/jump count: 0 Data use count: 3}}
                                  
        defb 1                    ; step count
        defb 1                    ; step size
        defb 0                    ; pause time

;; unused?
        defb $c8                  

;;=================================================================================
;; update volume envelope
update_volume_envelope:           ;{{Addr=$231f Code Calls/jump count: 1 Data use count: 0}}
        ld      l,(ix+$0d)        ;{{231F:dd6e0d}}  volume envelope pointer
        ld      h,(ix+$0e)        ;{{2322:dd660e}} 
        ld      e,(ix+$10)        ;{{2325:dd5e10}}  step count	

_update_volume_envelope_3:        ;{{Addr=$2328 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{2328:7b}} 
        cp      $ff               ;{{2329:feff}} 
        jr      z,clear_sound_data;{{232B:2875}}  no tone/volume envelopes active


        add     a,a               ;{{232D:87}} 
        ld      a,(hl)            ;{{232E:7e}}  reload envelope shape/step count
        inc     hl                ;{{232F:23}} 
        jr      c,_update_volume_envelope_49;{{2330:3849}}  set hardware envelope (HL) = hardware envelope value
        jr      z,_update_volume_envelope_18;{{2332:280c}}  set volume

        dec     e                 ;{{2334:1d}}  decrease step count

        ld      c,(ix+$0f)        ;{{2335:dd4e0f}} ; 
        or      a                 ;{{2338:b7}} 
        jr      nz,_update_volume_envelope_17;{{2339:2004}} 

        bit     7,c               ;{{233B:cb79}}  has noise
        jr      z,_update_volume_envelope_20;{{233D:2806}}        

;; 
_update_volume_envelope_17:       ;{{Addr=$233f Code Calls/jump count: 1 Data use count: 0}}
        add     a,c               ;{{233F:81}} 


_update_volume_envelope_18:       ;{{Addr=$2340 Code Calls/jump count: 1 Data use count: 0}}
        and     $0f               ;{{2340:e60f}} 
        call    write_volume_     ;{{2342:cddb23}}  write volume for channel and store

_update_volume_envelope_20:       ;{{Addr=$2345 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{2345:4e}} 
        ld      a,(ix+$09)        ;{{2346:dd7e09}} 
        ld      b,a               ;{{2349:47}} 
        add     a,a               ;{{234A:87}} 
        jr      c,_update_volume_envelope_39;{{234B:381b}}  (+&1b)
        xor     a                 ;{{234D:af}} 
        sub     c                 ;{{234E:91}} 
        add     a,(ix+$08)        ;{{234F:dd8608}} 
        jr      c,_update_volume_envelope_35;{{2352:380c}}  (+&0c)
        dec     b                 ;{{2354:05}} 
        jp      p,_update_volume_envelope_34;{{2355:f25d23}} 
        ld      c,(ix+$08)        ;{{2358:dd4e08}} 
        xor     a                 ;{{235B:af}} 
        ld      b,a               ;{{235C:47}} 
_update_volume_envelope_34:       ;{{Addr=$235d Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$09),b        ;{{235D:dd7009}} 
_update_volume_envelope_35:       ;{{Addr=$2360 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$08),a        ;{{2360:dd7708}} 
        or      b                 ;{{2363:b0}} 
        jr      nz,_update_volume_envelope_39;{{2364:2002}}  (+&02)
        ld      e,$ff             ;{{2366:1eff}} 
_update_volume_envelope_39:       ;{{Addr=$2368 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,e               ;{{2368:7b}} 
        or      a                 ;{{2369:b7}} 
        call    z,unknown_sound_function;{{236A:ccae23}} 
        ld      (ix+$10),e        ;{{236D:dd7310}} 
        di                        ;{{2370:f3}} 
        ld      (ix+$06),c        ;{{2371:dd7106}} 
        ld      (ix+$07),$80      ;{{2374:dd360780}}  has tone envelope
        ei                        ;{{2378:fb}} 
        or      a                 ;{{2379:b7}} 
        ret                       ;{{237A:c9}} 

;; E = hardware envelope shape
;; D = hardware envelope period low
;; (HL) = hardware envelope period high

;; DE = hardware envelope period
_update_volume_envelope_49:       ;{{Addr=$237b Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{237B:57}} 
        ld      c,e               ;{{237C:4b}} 
        ld      a,$0d             ;{{237D:3e0d}}  PSG hardware volume shape register
        call    MC_SOUND_REGISTER ;{{237F:cd6308}}  MC SOUND REGISTER
        ld      c,d               ;{{2382:4a}} 
        ld      a,$0b             ;{{2383:3e0b}}  PSG hardware volume period low
        call    MC_SOUND_REGISTER ;{{2385:cd6308}}  MC SOUND REGISTER
        ld      c,(hl)            ;{{2388:4e}} 
        ld      a,$0c             ;{{2389:3e0c}}  PSG hardware volume period high
        call    MC_SOUND_REGISTER ;{{238B:cd6308}}  MC SOUND REGISTER
        ld      a,$10             ;{{238E:3e10}}  use hardware envelope
        call    write_volume_     ;{{2390:cddb23}}  write volume for channel and store

        call    unknown_sound_function;{{2393:cdae23}} 
        ld      a,e               ;{{2396:7b}} 
        inc     a                 ;{{2397:3c}} 
        jr      nz,_update_volume_envelope_3;{{2398:208e}} 

        ld      hl,default_volume_envelope;{{239A:211b23}}  default volume envelope
        call    _unknown_sound_function_13;{{239D:cdcd23}}  set volume envelope
        jr      _update_volume_envelope_3;{{23A0:1886}} 

;;=======================================================================
;; clear sound data?
clear_sound_data:                 ;{{Addr=$23a2 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{23A2:af}} 
        ld      (ix+$03),a        ;{{23A3:dd7703}}  no rendezvous/hold and not playing
        ld      (ix+$07),a        ;{{23A6:dd7707}}  no tone envelope active
        ld      (ix+$04),a        ;{{23A9:dd7704}}  no volume envelope active
        scf                       ;{{23AC:37}} 
        ret                       ;{{23AD:c9}} 

;;=======================================================================
;; unknown sound function
unknown_sound_function:           ;{{Addr=$23ae Code Calls/jump count: 2 Data use count: 0}}
        dec     (ix+$0c)          ;{{23AE:dd350c}} 
        jr      nz,_unknown_sound_function_15;{{23B1:201e}}  (+&1e)

        ld      a,(ix+$09)        ;{{23B3:dd7e09}} 
        add     a,a               ;{{23B6:87}} 
        ld      hl,default_volume_envelope;{{23B7:211b23}}  
        jr      nc,_unknown_sound_function_13;{{23BA:3011}}  set volume envelope

        inc     (ix+$08)          ;{{23BC:dd3408}} 
        jr      nz,_unknown_sound_function_11;{{23BF:2006}}  (+&06)
        inc     (ix+$09)          ;{{23C1:dd3409}} 
        ld      e,$ff             ;{{23C4:1eff}} 
        ret     z                 ;{{23C6:c8}} 

;; reload?
_unknown_sound_function_11:       ;{{Addr=$23c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,(ix+$0a)        ;{{23C7:dd6e0a}} 
        ld      h,(ix+$0b)        ;{{23CA:dd660b}} 

;; set volume envelope
_unknown_sound_function_13:       ;{{Addr=$23cd Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{23CD:7e}} 
        ld      (ix+$0c),a        ;{{23CE:dd770c}} ; step count
_unknown_sound_function_15:       ;{{Addr=$23d1 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{23D1:23}} 
        ld      e,(hl)            ;{{23D2:5e}} ; step size
        inc     hl                ;{{23D3:23}} 
        ld      (ix+$0d),l        ;{{23D4:dd750d}} ; current volume envelope pointer
        ld      (ix+$0e),h        ;{{23D7:dd740e}} 
        ret                       ;{{23DA:c9}} 

;;============================================
;; write volume 
;;0 = channel, 15 = value
write_volume_:                    ;{{Addr=$23db Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$0f),a        ;{{23DB:dd770f}} 

;;+----------------------------
;; set volume for channel
;; IX = pointer to channel data
;;
;; A = volume
set_volume_for_channel:           ;{{Addr=$23de Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{23DE:4f}} 
        ld      a,(ix+$00)        ;{{23DF:dd7e00}} 
        add     a,$08             ;{{23E2:c608}}  PSG volume register for channel A
        jp      MC_SOUND_REGISTER ;{{23E4:c36308}}  MC SOUND REGISTER

;;==================================
;; disable channel
disable_channel:                  ;{{Addr=$23e7 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{23E7:af}} 

;;+-------------------------
;; update mixer for channel
update_mixer_for_channel:         ;{{Addr=$23e8 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{23E8:47}} 
        ld      a,(ix+$01)        ;{{23E9:dd7e01}}  tone mixer value
        or      (ix+$02)          ;{{23EC:ddb602}}  noise mixer value

        ld      hl,$b2b5          ;{{23EF:21b5b2}}  mixer value
        di                        ;{{23F2:f3}} 
        or      (hl)              ;{{23F3:b6}}  combine with current
        xor     b                 ;{{23F4:a8}} 
        cp      (hl)              ;{{23F5:be}} 
        ld      (hl),a            ;{{23F6:77}} 
        ei                        ;{{23F7:fb}} 
        jr      nz,_update_mixer_for_channel_14;{{23F8:2003}}  this means tone and noise disabled

        ld      a,b               ;{{23FA:78}} 
        or      a                 ;{{23FB:b7}} 
        ret     nz                ;{{23FC:c0}} 

_update_mixer_for_channel_14:     ;{{Addr=$23fd Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{23FD:af}}  silence sound
        call    set_volume_for_channel;{{23FE:cdde23}}  set channel volume
        di                        ;{{2401:f3}} 
        ld      c,(hl)            ;{{2402:4e}} 
        ld      a,$07             ;{{2403:3e07}}  PSG mixer register
        jp      MC_SOUND_REGISTER ;{{2405:c36308}}  MC SOUND REGISTER

;;==========================================================
;; set tone and get tone envelope
;; E = tone envelope number
set_tone_and_get_tone_envelope:   ;{{Addr=$2408 Code Calls/jump count: 1 Data use count: 0}}
        call    write_tone_to_PSG ;{{2408:cd8124}}  write tone to psg registers
        ld      a,e               ;{{240B:7b}} 
        call    SOUND_T_ADDRESS   ;{{240C:cdab24}}  SOUND T ADDRESS
        ret     nc                ;{{240F:d0}} 

        ld      a,(hl)            ;{{2410:7e}}  number of sections in tone
        and     $7f               ;{{2411:e67f}} 
        ret     z                 ;{{2413:c8}} 

        ld      (ix+$11),l        ;{{2414:dd7511}}  set tone envelope pointer reload
        ld      (ix+$12),h        ;{{2417:dd7412}} 
        call    steps_remaining   ;{{241A:cd7024}} 
        jr      _tone_envelope_function_3;{{241D:1809}}  initial update tone envelope            

;;====================================================================================
;; tone envelope function
tone_envelope_function:           ;{{Addr=$241f Code Calls/jump count: 1 Data use count: 0}}
        ld      l,(ix+$14)        ;{{241F:dd6e14}}  current tone pointer?
        ld      h,(ix+$15)        ;{{2422:dd6615}} 

        ld      e,(ix+$18)        ;{{2425:dd5e18}}  step count

;; update tone envelope
_tone_envelope_function_3:        ;{{Addr=$2428 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{2428:4e}}  step size
        inc     hl                ;{{2429:23}} 
        ld      a,e               ;{{242A:7b}} 
        sub     $f0               ;{{242B:d6f0}} 
        jr      c,_tone_envelope_function_10;{{242D:3804}}  increase/decrease tone

        ld      e,$00             ;{{242F:1e00}} 
        jr      _tone_envelope_function_20;{{2431:180e}} 

;;-------------------------------------

_tone_envelope_function_10:       ;{{Addr=$2433 Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{2433:1d}}  decrease step count
        ld      a,c               ;{{2434:79}} 
        add     a,a               ;{{2435:87}} 
        sbc     a,a               ;{{2436:9f}} 
        ld      d,a               ;{{2437:57}} 
        ld      a,(ix+$16)        ;{{2438:dd7e16}} ; low byte tone
        add     a,c               ;{{243B:81}} 
        ld      c,a               ;{{243C:4f}} 
        ld      a,(ix+$17)        ;{{243D:dd7e17}} ; high byte tone
        adc     a,d               ;{{2440:8a}} 

_tone_envelope_function_20:       ;{{Addr=$2441 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{2441:57}} 
        call    write_tone_to_PSG ;{{2442:cd8124}}  write tone to psg registers
        ld      c,(hl)            ;{{2445:4e}}  pause time
        ld      a,e               ;{{2446:7b}} 
        or      a                 ;{{2447:b7}} 
        jr      nz,_pause_sound_1 ;{{2448:2019}}  (+&19)

;; step count done..

        ld      a,(ix+$13)        ;{{244A:dd7e13}}  number of tone sections remaining..
        dec     a                 ;{{244D:3d}} 
        jr      nz,pause_sound    ;{{244E:2010}} 

;; reload
        ld      l,(ix+$11)        ;{{2450:dd6e11}} 
        ld      h,(ix+$12)        ;{{2453:dd6612}} 

        ld      a,(hl)            ;{{2456:7e}}  number of sections.
        add     a,$80             ;{{2457:c680}} 
        jr      c,pause_sound     ;{{2459:3805}} 

        ld      (ix+$04),$00      ;{{245B:dd360400}}  no volume envelope
        ret                       ;{{245F:c9}} 

;;====================================================
;; pause sound?
pause_sound:                      ;{{Addr=$2460 Code Calls/jump count: 2 Data use count: 0}}
        call    steps_remaining   ;{{2460:cd7024}} 
_pause_sound_1:                   ;{{Addr=$2463 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$18),e        ;{{2463:dd7318}} 
        di                        ;{{2466:f3}} 
        ld      (ix+$05),c        ;{{2467:dd7105}}  pause
        ld      (ix+$04),$80      ;{{246A:dd360480}}  has volume envelope
        ei                        ;{{246E:fb}} 
        ret                       ;{{246F:c9}} 

;;=====================================================================
;; steps remaining?

steps_remaining:                  ;{{Addr=$2470 Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$13),a        ;{{2470:dd7713}} ; number of sections remaining in envelope
        inc     hl                ;{{2473:23}} 
        ld      e,(hl)            ;{{2474:5e}} ; step count
        inc     hl                ;{{2475:23}} 
        ld      (ix+$14),l        ;{{2476:dd7514}} 
        ld      (ix+$15),h        ;{{2479:dd7415}} 
        ld      a,e               ;{{247C:7b}} 
        or      a                 ;{{247D:b7}} 
        ret     nz                ;{{247E:c0}} 

        inc     e                 ;{{247F:1c}} 
        ret                       ;{{2480:c9}} 

;;===========================================================================
;; write tone to PSG
;; C = tone low byte
;; D = tone high byte
write_tone_to_PSG:                ;{{Addr=$2481 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$00)        ;{{2481:dd7e00}} ; sound channel 0 = A, 1 = B, 2 =C 
        add     a,a               ;{{2484:87}} 
                                  ;; A = 0/2/4
        push    af                ;{{2485:f5}} 
        ld      (ix+$16),c        ;{{2486:dd7116}} 
        call    MC_SOUND_REGISTER ;{{2489:cd6308}}  MC SOUND REGISTER
        pop     af                ;{{248C:f1}} 
        inc     a                 ;{{248D:3c}} 
                                  ;; A = 1/3/5
        ld      c,d               ;{{248E:4a}} 
        ld      (ix+$17),c        ;{{248F:dd7117}} 
        jp      MC_SOUND_REGISTER ;{{2492:c36308}}  MC SOUND REGISTER


;;==========================================================================
;; SOUND AMPL ENVELOPE
;; sets up a volume envelope
;; A = envelope 1-15
SOUND_AMPL_ENVELOPE:              ;{{Addr=$2495 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,base_address_for_calculating_relevant_EN;{{2495:11a6b2}} 
        jr      _sound_tone_envelope_1;{{2498:1803}}  (+&03)


;;==========================================================================
;; SOUND TONE ENVELOPE
;; sets up a tone envelope
;; A = envelope 1-15

SOUND_TONE_ENVELOPE:              ;{{Addr=$249a Code Calls/jump count: 0 Data use count: 1}}
        ld      de,ENV_15         ;{{249A:1196b3}} 
_sound_tone_envelope_1:           ;{{Addr=$249d Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{249D:eb}} 
        call    _sound_t_address_1;{{249E:cdae24}} ; get envelope
        ex      de,hl             ;{{24A1:eb}} 
        ret     nc                ;{{24A2:d0}} 

;; +0 - number of sections in the envelope 
;; +1..3 - first section of the envelope 
;; +4..6 - second section of the envelope 
;; +7..9 - third section of the envelope 
;; +10..12 - fourth section of the envelope 
;; +13..15 = fifth section of the envelope 
;;
;; Each section of the envelope has three bytes set out as follows 

;; non-hardware envelope:
;;byte 0 - step count (with bit 7 set) 
;;byte 1 - step size 
;;byte 2 - pause time 
;; hardware-envelope:
;;byte 0 - envelope shape (with bit 7 not set)
;;bytes 1 and 2 - envelope period 
        ldir                      ;{{24A3:edb0}} 
        ret                       ;{{24A5:c9}} 

;;==========================================================================
;; SOUND A ADDRESS
;; Gets the address of the data block associated with the amplitude/volume envelope
;; A = envelope number (1-15)

SOUND_A_ADDRESS:                  ;{{Addr=$24a6 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,base_address_for_calculating_relevant_EN;{{24A6:21a6b2}}  first amplitude envelope - &10
        jr      _sound_t_address_1;{{24A9:1803}}  get envelope

;;==========================================================================
;; SOUND T ADDRESS
;; Gets the address of the data block associated with the tone envelope
;; A = envelope number (1-15)
 
SOUND_T_ADDRESS:                  ;{{Addr=$24ab Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,ENV_15         ;{{24AB:2196b3}} ; first tone envelope - &10

;; get envelope
_sound_t_address_1:               ;{{Addr=$24ae Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{24AE:b7}} ; 0 = invalid envelope number
        ret     z                 ;{{24AF:c8}} 

        cp      $10               ;{{24B0:fe10}} ; >=16 invalid envelope number
        ret     nc                ;{{24B2:d0}} 

        ld      bc,$0010          ;{{24B3:011000}} ; 16 bytes per envelope (5 sections + count) ##LIT##;WARNING: Code area used as literal
_sound_t_address_6:               ;{{Addr=$24b6 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{24B6:09}} 
        dec     a                 ;{{24B7:3d}} 
        jr      nz,_sound_t_address_6;{{24B8:20fc}}  (-&04)
        scf                       ;{{24BA:37}} 
        ret                       ;{{24BB:c9}} 



;;***Cassette.asm
;;CASSETTE ROUTINES
;;============================================================================
;; CAS INITIALISE

CAS_INITIALISE:                   ;{{Addr=$24bc Code Calls/jump count: 1 Data use count: 1}}
        call    CAS_IN_ABANDON    ;{{24BC:cd5725}}  CAS IN ABANDON
        call    CAS_OUT_ABANDON   ;{{24BF:cd9925}}  CAS OUT ABANDON

;; enable cassette messages
        xor     a                 ;{{24C2:af}} 
        call    CAS_NOISY         ;{{24C3:cde124}}  CAS NOISY

;; stop cassette motor
        call    CAS_STOP_MOTOR    ;{{24C6:cdbf2b}}  CAS STOP MOTOR

;; set default speed for writing
        ld      hl,$014d          ;{{24C9:214d01}} ##LIT##;WARNING: Code area used as literal
        ld      a,$19             ;{{24CC:3e19}} 

;;============================================================================
;; CAS SET SPEED

CAS_SET_SPEED:                    ;{{Addr=$24ce Code Calls/jump count: 0 Data use count: 1}}
        add     hl,hl             ;{{24CE:29}}  x2
        add     hl,hl             ;{{24CF:29}}  x4
        add     hl,hl             ;{{24D0:29}}  x8
        add     hl,hl             ;{{24D1:29}}  x32
        add     hl,hl             ;{{24D2:29}}  x64
        add     hl,hl             ;{{24D3:29}}  x128
        rrca                      ;{{24D4:0f}} 
        rrca                      ;{{24D5:0f}} 
        and     $3f               ;{{24D6:e63f}} 
        ld      l,a               ;{{24D8:6f}} 
        ld      (cassette_precompensation_),hl;{{24D9:22e9b1}} 
        ld      a,($b1e7)         ;{{24DC:3ae7b1}} 
        scf                       ;{{24DF:37}} 
        ret                       ;{{24E0:c9}} 

;;============================================================================
;; CAS NOISY

CAS_NOISY:                        ;{{Addr=$24e1 Code Calls/jump count: 2 Data use count: 1}}
        ld      (cassette_handling_messages_flag_),a;{{24E1:3218b1}} 
        ret                       ;{{24E4:c9}} 

;;============================================================================
;; CAS IN OPEN
;; 
;; B = length of filename
;; HL = filename
;; DE = address of 2K buffer
;;
;; NOTES:
;; - first block of file *must* be 2K long

CAS_IN_OPEN:                      ;{{Addr=$24e5 Code Calls/jump count: 0 Data use count: 1}}
        ld      ix,file_IN_flag_  ;{{24E5:dd211ab1}} ; input header

        call    _cas_out_open_1   ;{{24E9:cd0225}} ; initialise header
        push    hl                ;{{24EC:e5}} 
        call    c,read_a_block    ;{{24ED:dcac26}} ; read a block
        pop     hl                ;{{24F0:e1}} 
        ret     nc                ;{{24F1:d0}} 

        ld      de,(address_to_load_this_or_the_next_block_a);{{24F2:ed5b34b1}} ; load address
        ld      bc,(total_length_of_file_);{{24F6:ed4b37b1}} ; execution address
        ld      a,(file_type_)    ;{{24FA:3a31b1}} ; file type from header
        ret                       ;{{24FD:c9}} 

;;============================================================================
;; CAS OUT OPEN

CAS_OUT_OPEN:                     ;{{Addr=$24fe Code Calls/jump count: 0 Data use count: 1}}
        ld      ix,file_OUT_flag_ ;{{24FE:dd215fb1}} 

;;----------------------------------------------------------------------------
;; DE = address of 2k buffer
;; HL = address of filename
;; B = length of filename

_cas_out_open_1:                  ;{{Addr=$2502 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(ix+$00)        ;{{2502:dd7e00}} 
        or      a                 ;{{2505:b7}} 
        ld      a,$0e             ;{{2506:3e0e}} 
        ret     nz                ;{{2508:c0}} 

        push    ix                ;{{2509:dde5}} 
        ex      (sp),hl           ;{{250B:e3}} 
        inc     (hl)              ;{{250C:34}} 
        inc     hl                ;{{250D:23}} 
        ld      (hl),e            ;{{250E:73}} 
        inc     hl                ;{{250F:23}} 
        ld      (hl),d            ;{{2510:72}} 
        inc     hl                ;{{2511:23}} 
        ld      (hl),e            ;{{2512:73}} 
        inc     hl                ;{{2513:23}} 
        ld      (hl),d            ;{{2514:72}} 
        inc     hl                ;{{2515:23}} 
        ex      de,hl             ;{{2516:eb}} 
        pop     hl                ;{{2517:e1}} 
        push    de                ;{{2518:d5}} 

;; length of header
        ld      c,$40             ;{{2519:0e40}} 

;; clear header
        xor     a                 ;{{251B:af}} 
_cas_out_open_22:                 ;{{Addr=$251c Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{251C:12}} 
        inc     de                ;{{251D:13}} 
        dec     c                 ;{{251E:0d}} 
        jr      nz,_cas_out_open_22;{{251F:20fb}}  (-&05)

;; write filename
        pop     de                ;{{2521:d1}} 
        push    de                ;{{2522:d5}} 

;;-----------------------------------------------------
;; copy filename into buffer

        ld      a,b               ;{{2523:78}} 
        cp      $10               ;{{2524:fe10}} 
        jr      c,_cas_out_open_32;{{2526:3802}}  (+&02)

        ld      b,$10             ;{{2528:0610}} 

_cas_out_open_32:                 ;{{Addr=$252a Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{252A:04}} 
        ld      c,b               ;{{252B:48}} 
        jr      _cas_out_open_40  ;{{252C:1807}}  (+&07)

;; read character from RAM
_cas_out_open_35:                 ;{{Addr=$252e Code Calls/jump count: 1 Data use count: 0}}
        rst     $20               ;{{252E:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{252F:23}} 
        call    convert_character_to_upper_case;{{2530:cd2629}}  convert character to upper case
        ld      (de),a            ;{{2533:12}}  store character
        inc     de                ;{{2534:13}} 
_cas_out_open_40:                 ;{{Addr=$2535 Code Calls/jump count: 1 Data use count: 0}}
        djnz    _cas_out_open_35  ;{{2535:10f7}} 

;; pad with spaces
_cas_out_open_41:                 ;{{Addr=$2537 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{2537:0d}} 
        jr      z,_cas_out_open_49;{{2538:2809}}  (+&09)
        dec     de                ;{{253A:1b}} 
        ld      a,(de)            ;{{253B:1a}} 
        xor     $20               ;{{253C:ee20}} 
        jr      nz,_cas_out_open_49;{{253E:2003}}  

        ld      (de),a            ;{{2540:12}}  write character
        jr      _cas_out_open_41  ;{{2541:18f4}}  

;;------------------------------------------------------

_cas_out_open_49:                 ;{{Addr=$2543 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{2543:e1}} 
        inc     (ix+$15)          ;{{2544:dd3415}}  set block index
        ld      (ix+$17),$16      ;{{2547:dd361716}}  set initial file type
        dec     (ix+$1c)          ;{{254B:dd351c}}  set first block flag
        scf                       ;{{254E:37}} 
        ret                       ;{{254F:c9}} 

;;============================================================================
;; CAS IN CLOSE

CAS_IN_CLOSE:                     ;{{Addr=$2550 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(file_IN_flag_) ;{{2550:3a1ab1}}  get current read function
        or      a                 ;{{2553:b7}} 
        ld      a,$0e             ;{{2554:3e0e}} 
        ret     z                 ;{{2556:c8}} 

;;============================================================================
;; CAS IN ABANDON

CAS_IN_ABANDON:                   ;{{Addr=$2557 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,file_IN_flag_  ;{{2557:211ab1}}  get current read function
        ld      b,$01             ;{{255A:0601}} 
_cas_in_abandon_2:                ;{{Addr=$255c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{255C:7e}} 
        ld      (hl),$00          ;{{255D:3600}}  clear function allowing other functions to proceed
        push    bc                ;{{255F:c5}} 
        call    cleanup_after_abandon;{{2560:cd6d25}} 
        pop     af                ;{{2563:f1}} 

        ld      hl,RAM_b1e4       ;{{2564:21e4b1}} 
        xor     (hl)              ;{{2567:ae}} 
        scf                       ;{{2568:37}} 
        ret     nz                ;{{2569:c0}} 
        ld      (hl),a            ;{{256A:77}} 
        sbc     a,a               ;{{256B:9f}} 
        ret                       ;{{256C:c9}} 

;;============================================================================
;;cleanup after abandon?
;; A = function code
;; HL = ?
cleanup_after_abandon:            ;{{Addr=$256d Code Calls/jump count: 2 Data use count: 0}}
        cp      $04               ;{{256D:fe04}} 
        ret     c                 ;{{256F:d8}} 

;; clear
        inc     hl                ;{{2570:23}} 
        ld      e,(hl)            ;{{2571:5e}} 
        inc     hl                ;{{2572:23}} 
        ld      d,(hl)            ;{{2573:56}} 
        ld      l,e               ;{{2574:6b}} 
        ld      h,d               ;{{2575:62}} 
        inc     de                ;{{2576:13}} 
        ld      (hl),$00          ;{{2577:3600}} 
        ld      bc,$07ff          ;{{2579:01ff07}} ##LIT##;WARNING: Code area used as literal
        jp      HI_KL_LDIR        ;{{257C:c3a1ba}} ; HI: KL LDIR			

;;============================================================================
;; CAS OUT CLOSE

CAS_OUT_CLOSE:                    ;{{Addr=$257f Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(file_OUT_flag_);{{257F:3a5fb1}} 
        cp      $03               ;{{2582:fe03}} 
        jr      z,CAS_OUT_ABANDON ;{{2584:2813}}  (+&13)
        add     a,$ff             ;{{2586:c6ff}} 
        ld      a,$0e             ;{{2588:3e0e}} 
        ret     nc                ;{{258A:d0}} 

        ld      hl,last_block_flag__B;{{258B:2175b1}} 
        dec     (hl)              ;{{258E:35}} 
        inc     hl                ;{{258F:23}} 
        inc     hl                ;{{2590:23}} 
        ld      a,(hl)            ;{{2591:7e}} 
        inc     hl                ;{{2592:23}} 
        or      (hl)              ;{{2593:b6}} 
        scf                       ;{{2594:37}} 
        call    nz,write_a_block  ;{{2595:c48627}} ; write a block
        ret     nc                ;{{2598:d0}} 

;;============================================================================
;; CAS OUT ABANDON

CAS_OUT_ABANDON:                  ;{{Addr=$2599 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,file_OUT_flag_ ;{{2599:215fb1}} 
        ld      b,$02             ;{{259C:0602}} 
        jr      _cas_in_abandon_2 ;{{259E:18bc}}  (-&44)

;;============================================================================
;; CAS IN CHAR

CAS_IN_CHAR:                      ;{{Addr=$25a0 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{25A0:e5}} 
        push    de                ;{{25A1:d5}} 
        push    bc                ;{{25A2:c5}} 
        ld      b,$05             ;{{25A3:0605}} 
        call    attempt_to_set_cassette_input_function;{{25A5:cdf625}} ; set cassette input function
        jr      nz,_cas_in_char_19;{{25A8:201a}}  (+&1a)
        ld      hl,(length_of_this_block);{{25AA:2a32b1}} 
        ld      a,h               ;{{25AD:7c}} 
        or      l                 ;{{25AE:b5}} 
        scf                       ;{{25AF:37}} 
        call    z,read_a_block    ;{{25B0:ccac26}} ; read a block
        jr      nc,_cas_in_char_19;{{25B3:300f}}  (+&0f)
        ld      hl,(length_of_this_block);{{25B5:2a32b1}} 
        dec     hl                ;{{25B8:2b}} 
        ld      (length_of_this_block),hl;{{25B9:2232b1}} 
        ld      hl,(address_of_2K_buffer_for_loading_blocks_);{{25BC:2a1db1}} 
        rst     $20               ;{{25BF:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{25C0:23}} 
        ld      (address_of_2K_buffer_for_loading_blocks_),hl;{{25C1:221db1}} 
_cas_in_char_19:                  ;{{Addr=$25c4 Code Calls/jump count: 2 Data use count: 0}}
        jr      _cas_out_char_22  ;{{25C4:182c}}  (+&2c)

;;============================================================================
;; CAS OUT CHAR

CAS_OUT_CHAR:                     ;{{Addr=$25c6 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{25C6:e5}} 
        push    de                ;{{25C7:d5}} 
        push    bc                ;{{25C8:c5}} 
        ld      c,a               ;{{25C9:4f}} 
        ld      hl,file_OUT_flag_ ;{{25CA:215fb1}} 
        ld      b,$05             ;{{25CD:0605}} 
        call    _attempt_to_set_cassette_input_function_1;{{25CF:cdf925}} 
        jr      nz,_cas_out_char_22;{{25D2:201e}}  (+&1e)
        ld      hl,(length_saved_so_far);{{25D4:2a77b1}} 
        ld      de,$0800          ;{{25D7:110008}} ##LIT##;WARNING: Code area used as literal
        sbc     hl,de             ;{{25DA:ed52}} 
        push    bc                ;{{25DC:c5}} 
        call    nc,write_a_block  ;{{25DD:d48627}} ; write a block
        pop     bc                ;{{25E0:c1}} 
        jr      nc,_cas_out_char_22;{{25E1:300f}}  (+&0f)
        ld      hl,(length_saved_so_far);{{25E3:2a77b1}} 
        inc     hl                ;{{25E6:23}} 
        ld      (length_saved_so_far),hl;{{25E7:2277b1}} 
        ld      hl,(address_of_start_of_the_last_block_saved);{{25EA:2a62b1}} 
        ld      (hl),c            ;{{25ED:71}} 
        inc     hl                ;{{25EE:23}} 
        ld      (address_of_start_of_the_last_block_saved),hl;{{25EF:2262b1}} 
_cas_out_char_22:                 ;{{Addr=$25f2 Code Calls/jump count: 3 Data use count: 0}}
        pop     bc                ;{{25F2:c1}} 
        pop     de                ;{{25F3:d1}} 
        pop     hl                ;{{25F4:e1}} 
        ret                       ;{{25F5:c9}} 


;;============================================================================
;; attempt to set cassette input function

;; entry:
;; B = function code
;;
;; 0 = no function active
;; 1 = opened using CAS IN OPEN or CAS OUT OPEN
;; 2 = reading with CAS IN DIRECT
;; 3 = broken into with ESC
;; 4 = catalog
;; 5 = reading with CAS IN CHAR
;;
;; exit:
;; zero set = no error. function has been set or function is already set
;; zero clear = error. A = error code
;;
attempt_to_set_cassette_input_function:;{{Addr=$25f6 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,file_IN_flag_  ;{{25F6:211ab1}} 

_attempt_to_set_cassette_input_function_1:;{{Addr=$25f9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{25F9:7e}} ; get current function code
        cp      b                 ;{{25FA:b8}} ; same as existing code?
        ret     z                 ;{{25FB:c8}} 
;; function codes are different
        xor     $01               ;{{25FC:ee01}} ; just opened?
        ld      a,$0e             ;{{25FE:3e0e}} 
        ret     nz                ;{{2600:c0}} 
;; must be just opened for this to succeed
;;
;; set new function

        ld      (hl),b            ;{{2601:70}} 
        ret                       ;{{2602:c9}} 

;;============================================================================
;; CAS TEST EOF

CAS_TEST_EOF:                     ;{{Addr=$2603 Code Calls/jump count: 0 Data use count: 1}}
        call    CAS_IN_CHAR       ;{{2603:cda025}} 
        ret     nc                ;{{2606:d0}} 

;;============================================================================
;; CAS RETURN

CAS_RETURN:                       ;{{Addr=$2607 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{2607:e5}} 
        ld      hl,(length_of_this_block);{{2608:2a32b1}} 
        inc     hl                ;{{260B:23}} 
        ld      (length_of_this_block),hl;{{260C:2232b1}} 
        ld      hl,(address_of_2K_buffer_for_loading_blocks_);{{260F:2a1db1}} 
        dec     hl                ;{{2612:2b}} 
        ld      (address_of_2K_buffer_for_loading_blocks_),hl;{{2613:221db1}} 
        pop     hl                ;{{2616:e1}} 
        ret                       ;{{2617:c9}} 

;;============================================================================
;; CAS IN DIRECT
;; 
;; HL = load address
;;
;; Notes:
;; - file must be contiguous;
;; - load address of first block is important, load address of subsequent blocks 
;;   is ignored and can be any value
;; - first block of file must be 2k long; subsequent blocks can be any length
;; - execution address is taken from header of last block
;; - filename of each block must be the same
;; - block numbers are consecutive and increment
;; - first block number is *not* important; it can be any value!

CAS_IN_DIRECT:                    ;{{Addr=$2618 Code Calls/jump count: 0 Data use count: 1}}
        ex      de,hl             ;{{2618:eb}} 
        ld      b,$02             ;{{2619:0602}} ; IN direct
        call    attempt_to_set_cassette_input_function;{{261B:cdf625}} ; set cassette input function
        ret     nz                ;{{261E:c0}} 

;; set initial load address
        ld      (address_to_load_this_or_the_next_block_a),de;{{261F:ed5334b1}} 

;; transfer first block to destination
        call    transfer_loaded_block_to_destination_location;{{2623:cd3c26}} ; transfer loaded block to destination location


;; update load address
_cas_in_direct_6:                 ;{{Addr=$2626 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_to_load_this_or_the_next_block_a);{{2626:2a34b1}} ; load address from in memory header
        ld      de,(length_of_this_block);{{2629:ed5b32b1}} ; length from loaded header
        add     hl,de             ;{{262D:19}} 
        ld      (address_to_load_this_or_the_next_block_a),hl;{{262E:2234b1}} 

        call    read_a_block      ;{{2631:cdac26}} ; read a block
        jr      c,_cas_in_direct_6;{{2634:38f0}}  (-&10)

        ret     z                 ;{{2636:c8}} 
        ld      hl,(RAM_b1be)     ;{{2637:2abeb1}} ; execution address
        scf                       ;{{263A:37}} 
        ret                       ;{{263B:c9}} 

;;============================================================================
;; transfer loaded block to destination location

transfer_loaded_block_to_destination_location:;{{Addr=$263c Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_2K_buffer_for_directories);{{263C:2a1bb1}} 
        ld      bc,(length_of_this_block);{{263F:ed4b32b1}} 
        ld      a,e               ;{{2643:7b}} 
        sub     l                 ;{{2644:95}} 
        ld      a,d               ;{{2645:7a}} 
        sbc     a,h               ;{{2646:9c}} 
        jp      c,HI_KL_LDIR      ;{{2647:daa1ba}} ; HI: KL LDIR
        add     hl,bc             ;{{264A:09}} 
        dec     hl                ;{{264B:2b}} 
        ex      de,hl             ;{{264C:eb}} 
        add     hl,bc             ;{{264D:09}} 
        dec     hl                ;{{264E:2b}} 
        ex      de,hl             ;{{264F:eb}} 
        jp      HI_KL_LDDR        ;{{2650:c3a7ba}} ; HI: KL LDDR

;;============================================================================
;; CAS OUT DIRECT
;; 
;; HL = load address
;; DE = length
;; BC = execution address
;; A = file type

CAS_OUT_DIRECT:                   ;{{Addr=$2653 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{2653:e5}} 
        push    bc                ;{{2654:c5}} 
        ld      c,a               ;{{2655:4f}} 
        ld      hl,file_OUT_flag_ ;{{2656:215fb1}} 
        ld      b,$02             ;{{2659:0602}} 
        call    _attempt_to_set_cassette_input_function_1;{{265B:cdf925}} 
        jr      nz,_cas_out_direct_28;{{265E:202d}}  (+&2d)

        ld      a,c               ;{{2660:79}} 
        pop     bc                ;{{2661:c1}} 
        pop     hl                ;{{2662:e1}} 

;; setup header
        ld      (file_type__B),a  ;{{2663:3276b1}} 
        ld      (total_length_of_file_to_be_saved),de;{{2666:ed537cb1}}  length
        ld      (execution_address_for_bin_files__B),bc;{{266A:ed437eb1}}  execution address

_cas_out_direct_13:               ;{{Addr=$266e Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_to_start_the_next_block_save_fro),hl;{{266E:2260b1}}  load address
        ld      (length_saved_so_far),de;{{2671:ed5377b1}}  length
        ld      hl,$f7ff          ;{{2675:21fff7}}  &f7ff = -&800
        add     hl,de             ;{{2678:19}} 
        ccf                       ;{{2679:3f}} 
        ret     c                 ;{{267A:d8}} 

        ld      hl,$0800          ;{{267B:210008}} ##LIT##;WARNING: Code area used as literal
        ld      (length_saved_so_far),hl;{{267E:2277b1}}  length of this block

        ex      de,hl             ;{{2681:eb}} 
        sbc     hl,de             ;{{2682:ed52}} 
        push    hl                ;{{2684:e5}} 
        ld      hl,(address_to_start_the_next_block_save_fro);{{2685:2a60b1}} 
        add     hl,de             ;{{2688:19}} 
        push    hl                ;{{2689:e5}} 
        call    write_a_block     ;{{268A:cd8627}}  write block
	
_cas_out_direct_28:               ;{{Addr=$268d Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{268D:e1}} 
        pop     de                ;{{268E:d1}} 
        ret     nc                ;{{268F:d0}} 

        jr      _cas_out_direct_13;{{2690:18dc}}  (-&24)

;;============================================================================
;; CAS CATALOG
;;
;; DE = address of 2k buffer

CAS_CATALOG:                      ;{{Addr=$2692 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,file_IN_flag_  ;{{2692:211ab1}} 
        ld      a,(hl)            ;{{2695:7e}} 
        or      a                 ;{{2696:b7}} 
        ld      a,$0e             ;{{2697:3e0e}} 
        ret     nz                ;{{2699:c0}} 

        ld      (hl),$04          ;{{269A:3604}}  set catalog function

        ld      (address_of_2K_buffer_for_directories),de;{{269C:ed531bb1}}  buffer to load blocks to
        xor     a                 ;{{26A0:af}} 
        call    CAS_NOISY         ;{{26A1:cde124}} ; CAS NOISY
_cas_catalog_9:                   ;{{Addr=$26a4 Code Calls/jump count: 1 Data use count: 0}}
        call    _read_a_block_4   ;{{26A4:cdb326}}  read block
        jr      c,_cas_catalog_9  ;{{26A7:38fb}}  loop if cassette not pressed

        jp      CAS_IN_ABANDON    ;{{26A9:c35725}} ; CAS IN ABANDON


;;=================================================================================
;; read a block
;; 
;; 
;; notes:
;;

read_a_block:                     ;{{Addr=$26ac Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(last_block_flag_);{{26AC:3a30b1}}  last block flag
        or      a                 ;{{26AF:b7}} 
        ld      a,$0f             ;{{26B0:3e0f}}  "hard end of file"
        ret     nz                ;{{26B2:c0}} 

_read_a_block_4:                  ;{{Addr=$26b3 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$8301          ;{{26B3:010183}}  Press PLAY then any key
        call    wait_key_start_motor;{{26B6:cde527}}  display message if required
        jr      nc,handle_read_error;{{26B9:305f}} 

_read_a_block_7:                  ;{{Addr=$26bb Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,used_to_construct_IN_Channel_header;{{26BB:21a4b1}}  location to load header
        ld      de,$0040          ;{{26BE:114000}}  header length ##LIT##;WARNING: Code area used as literal
        ld      a,$2c             ;{{26C1:3e2c}}  header marker byte
        call    CAS_READ          ;{{26C3:cda629}}  cas read: read header
        jr      nc,handle_read_error;{{26C6:3052}} 

        ld      b,$8b             ;{{26C8:068b}}  no message
        call    test_if_read_function_is_CATALOG;{{26CA:cd2f29}}  catalog?
        jr      z,_read_a_block_18;{{26CD:2807}} 

;; not catalog, so compare filenames
        call    compare_filenames ;{{26CF:cd3727}}  compare filenames
        jr      nz,block_found    ;{{26D2:2053}}  if nz, display "Found xxx block x"

        ld      b,$89             ;{{26D4:0689}}  "Loading"
_read_a_block_18:                 ;{{Addr=$26d6 Code Calls/jump count: 1 Data use count: 0}}
        call    _test_and_delay_6 ;{{26D6:cd0428}}  display "Loading xxx block x"

        ld      de,(RAM_b1b7)     ;{{26D9:ed5bb7b1}}  length from loaded header
        ld      hl,(address_to_load_this_or_the_next_block_a);{{26DD:2a34b1}}  location from in-memory header

        ld      a,(file_IN_flag_) ;{{26E0:3a1ab1}}  
        cp      $02               ;{{26E3:fe02}}  in direct?
        jr      z,_read_a_block_30;{{26E5:280e}}  

;; not in direct, so is:
;; 1. catalog
;; 2. opening file for read
;; 3. reading file char by char
;;
;; check the block is no longer than &800 bytes
;; if it is report a "read error d"
        ld      hl,$f7ff          ;{{26E7:21fff7}}  &f7ff = -&800
        add     hl,de             ;{{26EA:19}}  add length from header

        ld      a,$04             ;{{26EB:3e04}}  code for 'read error d'
        jr      c,handle_read_error;{{26ED:382b}}  (+&2b)

        ld      hl,(address_of_2K_buffer_for_directories);{{26EF:2a1bb1}}  2k buffer
        ld      (address_of_2K_buffer_for_loading_blocks_),hl;{{26F2:221db1}} 

_read_a_block_30:                 ;{{Addr=$26f5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$16             ;{{26F5:3e16}}  data marker
        call    CAS_READ          ;{{26F7:cda629}}  cas read: read data

        jr      nc,handle_read_error;{{26FA:301e}} 

;; increment block number in internal header
        ld      hl,number_of_block_being_loaded_or_next_to;{{26FC:212fb1}}  block number
        inc     (hl)              ;{{26FF:34}}  increment block number

;; get last block flag from loaded header and store into
;; internal header
        ld      a,(RAM_b1b5)      ;{{2700:3ab5b1}} 
        inc     hl                ;{{2703:23}} 
        ld      (hl),a            ;{{2704:77}} 

;; clear first block flag
        xor     a                 ;{{2705:af}} 
        ld      (first_block_flag_),a;{{2706:3236b1}} 

        ld      hl,(RAM_b1b7)     ;{{2709:2ab7b1}}  get length from loaded header
        ld      (length_of_this_block),hl;{{270C:2232b1}}  store in internal header

        call    test_if_read_function_is_CATALOG;{{270F:cd2f29}}  catalog?

;; if catalog display OK message
        ld      a,$8c             ;{{2712:3e8c}}  "OK"
        call    z,A__message_code ;{{2714:cc7e28}}  display message

;; 
        scf                       ;{{2717:37}} 
        jr      _abandon_4        ;{{2718:1865}}  (+&65)

;;===========================================================================
;; handle read error?
;; A = code (A=0: no error; A<>0: error)

handle_read_error:                ;{{Addr=$271a Code Calls/jump count: 4 Data use count: 0}}
        or      a                 ;{{271A:b7}} 
        ld      hl,file_IN_flag_  ;{{271B:211ab1}} 
        jr      z,abandon         ;{{271E:2858}}  

;; A = error code
        ld      b,$85             ;{{2720:0685}}  "Read error"
        call    display_message_with_code_on_end;{{2722:cd8528}}  display message with code
;; .. retry
        jr      _read_a_block_7   ;{{2725:1894}} 

;;===========================================================================
;; block found?
block_found:                      ;{{Addr=$2727 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{2727:f5}} 
        ld      b,$88             ;{{2728:0688}}  "Found "
        call    _test_and_delay_6 ;{{272A:cd0428}}  "Found xxx block x"
        pop     af                ;{{272D:f1}} 
        jr      nc,_read_a_block_7;{{272E:308b}}  (-&75)

        ld      b,$87             ;{{2730:0687}}  "Rewind tape"
        call    x2883_code        ;{{2732:cd8328}} 
        jr      _read_a_block_7   ;{{2735:1884}}  (-&7c)

;;========================================================================
;; compare filenames
;;
;; if not first block:
;; compare names
;; if first block:
;; - compare filenames if a filename was specified
;; - copy loaded header into ram

compare_filenames:                ;{{Addr=$2737 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(first_block_flag_);{{2737:3a36b1}}  first block flag in internal header?
        or      a                 ;{{273A:b7}} 
        jr      z,compare_name_and_block_number;{{273B:281b}} 

        ld      a,($b1bb)         ;{{273D:3abbb1}}  first block flag in loaded header?
        cpl                       ;{{2740:2f}} 
        or      a                 ;{{2741:b7}} 
        ret     nz                ;{{2742:c0}} 

;; if user specified a filename, compare it against the filename in the loaded
;; header, otherwise accept the file

        ld      a,(IN_Channel_header);{{2743:3a1fb1}}  did user specify a filename?
                                  ; e.g. LOAD"bob
        or      a                 ;{{2746:b7}} 

        call    nz,compare_two_filenames;{{2747:c46027}}  compare filenames and block number
        ret     nz                ;{{274A:c0}}  if filenames do not match, quit

;; gets here if:

;; 1. if a filename was specified by user and filename matches with 
;; filename in loaded header
;;
;; 2. no filename was specified by user

;; copy loaded header to in-memory header
        ld      hl,used_to_construct_IN_Channel_header;{{274B:21a4b1}} 
        ld      de,IN_Channel_header;{{274E:111fb1}} 
        ld      bc,$0040          ;{{2751:014000}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2754:edb0}} 

        xor     a                 ;{{2756:af}} 
        ret                       ;{{2757:c9}} 

;;=========================================================================
;; compare name and block number

compare_name_and_block_number:    ;{{Addr=$2758 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_two_filenames;{{2758:cd6027}}  compare filenames
        ret     nz                ;{{275B:c0}} 

;; compare block number
        ex      de,hl             ;{{275C:eb}} 
        ld      a,(de)            ;{{275D:1a}} 
        cp      (hl)              ;{{275E:be}} 
        ret                       ;{{275F:c9}} 

;;============================================================================
;; compare two filenames
;; one filename is in the loaded header
;; the second filename is in the in-memory header
;;
;; nz = filenames are different
;; z = filenames are identical

compare_two_filenames:            ;{{Addr=$2760 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,IN_Channel_header;{{2760:211fb1}}  in-memory header
        ld      de,used_to_construct_IN_Channel_header;{{2763:11a4b1}}  loaded header

;; compare filenames
        ld      b,$10             ;{{2766:0610}}  16 characters

_compare_two_filenames_3:         ;{{Addr=$2768 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{2768:1a}}  get character from loaded header
        call    convert_character_to_upper_case;{{2769:cd2629}}  convert character to upper case
        ld      c,a               ;{{276C:4f}} 
        ld      a,(hl)            ;{{276D:7e}}  get character from in-memory header
        call    convert_character_to_upper_case;{{276E:cd2629}}  convert character to upper case

        xor     c                 ;{{2771:a9}}  result will be 0 if the characters are identical.
                                  ; will be <>0 if the characters are different

        ret     nz                ;{{2772:c0}}  quit if characters are not the same

        inc     hl                ;{{2773:23}}  increment pointer
        inc     de                ;{{2774:13}}  increment pointer
        djnz    _compare_two_filenames_3;{{2775:10f1}} 

;; if control gets to here, then the filenames are identical
        ret                       ;{{2777:c9}} 
;;============================================================================
;; abandon?
abandon:                          ;{{Addr=$2778 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{2778:7e}} 
        ld      (hl),$03          ;{{2779:3603}}  
        call    cleanup_after_abandon;{{277B:cd6d25}} 
        or      a                 ;{{277E:b7}} 

;;----------------------------------------------------------------------------
;; quit loading block
_abandon_4:                       ;{{Addr=$277f Code Calls/jump count: 2 Data use count: 0}}
        sbc     a,a               ;{{277F:9f}} 
        push    af                ;{{2780:f5}} 
        call    CAS_STOP_MOTOR    ;{{2781:cdbf2b}}  CAS STOP MOTOR
        pop     af                ;{{2784:f1}} 
        ret                       ;{{2785:c9}} 

;;============================================================================
;; write a block

write_a_block:                    ;{{Addr=$2786 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,$8402          ;{{2786:010284}}  press rec
        call    wait_key_start_motor;{{2789:cde527}}   display message if required
        jr      nc,handle_write_error;{{278C:304a}}  (+&4a)
        ld      b,$8a             ;{{278E:068a}} 
        ld      de,OUT_Channel_Header_;{{2790:1164b1}} 
        call    _test_and_delay_7 ;{{2793:cd0728}} 
        ld      hl,first_block_flag__B;{{2796:217bb1}} 
        call    test_and_delay    ;{{2799:cdfa27}} 
        jr      nc,handle_write_error;{{279C:303a}}  (+&3a)
_write_a_block_9:                 ;{{Addr=$279e Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_to_start_the_next_block_save_fro);{{279E:2a60b1}} 
        ld      (address_of_start_of_the_last_block_saved),hl;{{27A1:2262b1}} 
        ld      (address_of_start_of_area_to_save_or_add),hl;{{27A4:2279b1}} 
        push    hl                ;{{27A7:e5}} 

;; write header for this block
        ld      hl,OUT_Channel_Header_;{{27A8:2164b1}} 
        ld      de,$0040          ;{{27AB:114000}} ##LIT##;WARNING: Code area used as literal
        ld      a,$2c             ;{{27AE:3e2c}}  header marker
        call    CAS_WRITE         ;{{27B0:cdaf29}}  cas write: write header

        pop     hl                ;{{27B3:e1}} 
        jr      nc,handle_write_error;{{27B4:3022}}  (+&22)

;; write data for this block
        ld      de,(length_saved_so_far);{{27B6:ed5b77b1}} 
        ld      a,$16             ;{{27BA:3e16}}  data marker
        call    CAS_WRITE         ;{{27BC:cdaf29}}  cas write: write data block
        ld      hl,last_block_flag__B;{{27BF:2175b1}} 
        call    c,test_and_delay  ;{{27C2:dcfa27}} 
        jr      nc,handle_write_error;{{27C5:3011}}  (+&11)
        ld      hl,$0000          ;{{27C7:210000}} ##LIT##;WARNING: Code area used as literal
        ld      (length_saved_so_far),hl;{{27CA:2277b1}} 
        ld      hl,number_of_the_block_being_saved_or_next;{{27CD:2174b1}} 
        inc     (hl)              ;{{27D0:34}} 
        xor     a                 ;{{27D1:af}} 
        ld      (first_block_flag__B),a;{{27D2:327bb1}} 
        scf                       ;{{27D5:37}} 
        jr      _abandon_4        ;{{27D6:18a7}}  (-&59)

;;=======================================================================
;;handle write error?
;; A = code (A=0: no error; A<>0: error)
handle_write_error:               ;{{Addr=$27d8 Code Calls/jump count: 4 Data use count: 0}}
        or      a                 ;{{27D8:b7}} 
        ld      hl,file_OUT_flag_ ;{{27D9:215fb1}} 
        jr      z,abandon         ;{{27DC:289a}}  (-&66)

;; a = code
        ld      b,$86             ;{{27DE:0686}}  "Write error"
        call    display_message_with_code_on_end;{{27E0:cd8528}}  display message with code
        jr      _write_a_block_9  ;{{27E3:18b9}}  (-&47)

;;========================================================================
;; wait key start motor
;; C = message code
;; exit:
;; A = 0: no error
;; A <>0: error

wait_key_start_motor:             ;{{Addr=$27e5 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b1e4       ;{{27E5:21e4b1}} 
        ld      a,c               ;{{27E8:79}} 
        cp      (hl)              ;{{27E9:be}} 
        ld      (hl),c            ;{{27EA:71}} 
        scf                       ;{{27EB:37}} 

        push    hl                ;{{27EC:e5}} 
        push    bc                ;{{27ED:c5}} 
        call    nz,prepare_display_for_message;{{27EE:c4d228}}  Press play then any key
        pop     bc                ;{{27F1:c1}} 
        pop     hl                ;{{27F2:e1}} 

        sbc     a,a               ;{{27F3:9f}} 
        ret     nc                ;{{27F4:d0}} 

        call    CAS_START_MOTOR   ;{{27F5:cdbb2b}}  CAS START MOTOR
        sbc     a,a               ;{{27F8:9f}} 
        ret                       ;{{27F9:c9}} 

;;========================================================================
;; test and delay?
test_and_delay:                   ;{{Addr=$27fa Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{27FA:7e}} 
        or      a                 ;{{27FB:b7}} 
        scf                       ;{{27FC:37}} 
        ret     z                 ;{{27FD:c8}} 

        ld      bc,$012c          ;{{27FE:012c01}}  delay in 1/100ths of a second ##LIT##;WARNING: Code area used as literal
        jp      delay__check_for_escape;{{2801:c3e22b}}  delay for 3 seconds

;;-===================================================================================

_test_and_delay_6:                ;{{Addr=$2804 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,used_to_construct_IN_Channel_header;{{2804:11a4b1}} 

_test_and_delay_7:                ;{{Addr=$2807 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(cassette_handling_messages_flag_);{{2807:3a18b1}}  cassette messages enabled?
        or      a                 ;{{280A:b7}} 
        ret     nz                ;{{280B:c0}} 

        ld      (RAM_b119),a      ;{{280C:3219b1}} 
        call    set_column_1      ;{{280F:cdf328}} 

        call    x2898_code        ;{{2812:cd9828}}  display message

        ld      a,(de)            ;{{2815:1a}}  is first character of filename = 0?
        or      a                 ;{{2816:b7}} 
        jr      nz,_test_and_delay_20;{{2817:200a}}  

;; unnamed file

        ld      a,$8e             ;{{2819:3e8e}}  "Unnamed file"
        call    display_message   ;{{281B:cd9928}}  display message

        ld      bc,$0010          ;{{281E:011000}} ##LIT##;WARNING: Code area used as literal
        jr      _test_and_delay_48;{{2821:182e}}  (+&2e)

;;-----------------------------
;; named file
_test_and_delay_20:               ;{{Addr=$2823 Code Calls/jump count: 1 Data use count: 0}}
        call    test_if_read_function_is_CATALOG;{{2823:cd2f29}} 

        ld      bc,$1000          ;{{2826:010010}} ##LIT##;WARNING: Code area used as literal
        jr      z,_test_and_delay_34;{{2829:280d}}  (+&0d)
        ld      l,e               ;{{282B:6b}} 
        ld      h,d               ;{{282C:62}} 
_test_and_delay_25:               ;{{Addr=$282d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{282D:7e}} 
        or      a                 ;{{282E:b7}} 
        jr      z,_test_and_delay_31;{{282F:2804}}  (+&04)
        inc     c                 ;{{2831:0c}} 
        inc     hl                ;{{2832:23}} 
        djnz    _test_and_delay_25;{{2833:10f8}}  (-&08)
_test_and_delay_31:               ;{{Addr=$2835 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{2835:78}} 
        ld      b,c               ;{{2836:41}} 
        ld      c,a               ;{{2837:4f}} 

_test_and_delay_34:               ;{{Addr=$2838 Code Calls/jump count: 1 Data use count: 0}}
        call    determine_if_word_can_be_displayed_on_this_line;{{2838:cdfd28}}  insert new-line if word
                                  ; can't fit onto current-line

_test_and_delay_35:               ;{{Addr=$283b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{283B:1a}}  get character from filename
        call    convert_character_to_upper_case;{{283C:cd2629}}  convert character to upper case

        or      a                 ;{{283F:b7}}  zero?
        jr      nz,_test_and_delay_40;{{2840:2002}} 

;; display a space if a zero is found

        ld      a,$20             ;{{2842:3e20}}  display a space

_test_and_delay_40:               ;{{Addr=$2844 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2844:c5}} 
        push    de                ;{{2845:d5}} 
        call    TXT_WR_CHAR       ;{{2846:cd3513}}  TXT WR CHAR
        pop     de                ;{{2849:d1}} 
        pop     bc                ;{{284A:c1}} 
        inc     de                ;{{284B:13}} 
        djnz    _test_and_delay_35;{{284C:10ed}}  (-&13)

        call    _display_message_with_word_wrap_15;{{284E:cdce28}}  display space

_test_and_delay_48:               ;{{Addr=$2851 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2851:eb}} 
        add     hl,bc             ;{{2852:09}} 
        ex      de,hl             ;{{2853:eb}} 

        ld      a,$8d             ;{{2854:3e8d}}  "block "
        call    display_message   ;{{2856:cd9928}}  display message

        ld      b,$02             ;{{2859:0602}}  length of word
        call    determine_if_word_can_be_displayed_on_this_line;{{285B:cdfd28}}  insert new-line if word
                                  ; can't fit onto current-line

        ld      a,(de)            ;{{285E:1a}} 
        call    divide_by_10      ;{{285F:cd1429}}  display decimal number

        call    _display_message_with_word_wrap_15;{{2862:cdce28}}  display space

        inc     de                ;{{2865:13}} 
        call    test_if_read_function_is_CATALOG;{{2866:cd2f29}} 
        jr      nz,x2876_code     ;{{2869:200b}}  (+&0b)
        inc     de                ;{{286B:13}} 
        ld      a,(de)            ;{{286C:1a}} 
        and     $0f               ;{{286D:e60f}} 
        add     a,$24             ;{{286F:c624}} 
        call    _prepare_display_for_message_14;{{2871:cdf028}} 

        jr      _display_message_with_word_wrap_15;{{2874:1858}}  display space

;;=========================================================================

x2876_code:                       ;{{Addr=$2876 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{2876:1a}} 
        ld      hl,RAM_b119       ;{{2877:2119b1}} 
        or      (hl)              ;{{287A:b6}} 
        ret     z                 ;{{287B:c8}} 
        jr      _prepare_display_for_message_12;{{287C:186d}}  (+&6d)

;;=========================================================================
;; A = message code

A__message_code:                  ;{{Addr=$287e Code Calls/jump count: 1 Data use count: 0}}
        call    display_message   ;{{287E:cd9928}}  display message
        jr      _prepare_display_for_message_12;{{2881:1868}}  (+&68)

;;=========================================================================

x2883_code:                       ;{{Addr=$2883 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$ff             ;{{2883:3eff}} 

;; display message with code on end
;; (e.g. "Read error x" or "Write error x"
;; A = code (1,2,3)
display_message_with_code_on_end: ;{{Addr=$2885 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{2885:f5}} 
        call    x2891_code        ;{{2886:cd9128}} 
        pop     af                ;{{2889:f1}} 
        add     a,$60             ;{{288A:c660}}  'a'-1
        call    nc,_prepare_display_for_message_14;{{288C:d4f028}}  display character
        jr      _prepare_display_for_message_12;{{288F:185a}} 

;;=========================================================================

x2891_code:                       ;{{Addr=$2891 Code Calls/jump count: 2 Data use count: 0}}
        call    TXT_GET_CURSOR    ;{{2891:cd7c11}}  TXT GET CURSOR
        dec     h                 ;{{2894:25}} 
        call    nz,_prepare_display_for_message_12;{{2895:c4eb28}} 

x2898_code:                       ;{{Addr=$2898 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{2898:78}} 

;;=========================================================================
;; display message
;;
;; - message is displayed using word-wrap
;;
;; a = message number (&80-&FF)
display_message:                  ;{{Addr=$2899 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{2899:e5}} 

        and     $7f               ;{{289A:e67f}}  get message index (0-127)
        ld      b,a               ;{{289C:47}} 

        ld      hl,cassette_messages;{{289D:213529}}  start of message list (points to first message)

;; first message in list? (message 0?)
        jr      z,_display_message_10;{{28A0:2807}} 

;; not first. 
;; 
;; - each message is terminated by a zero byte
;; - keep fetching bytes until a zero is found.
;; - if a zero is found, decrement count. If count reaches zero, then 
;; the first byte following the zero, is the start of the message we want

_display_message_5:               ;{{Addr=$28a2 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{28A2:7e}}  get byte
        inc     hl                ;{{28A3:23}}  increment pointer

        or      a                 ;{{28A4:b7}}  is it zero (0) ?
        jr      nz,_display_message_5;{{28A5:20fb}}  if zero, it is the end of this string

;; got a zero byte, so at end of the current string

        djnz    _display_message_5;{{28A7:10f9}}  decrement message count

;; HL = start of message to display

;; this part is looped; message may contain multiple strings

;; end of message?
_display_message_10:              ;{{Addr=$28a9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{28A9:7e}} 
        or      a                 ;{{28AA:b7}} 
        jr      z,_display_message_15;{{28AB:2805}}  (+&05)

;; display message
        call    display_message_with_word_wrap;{{28AD:cdb528}}  display message with word-wrap

;; at this point there might be a end of string marker (0), the start
;; of another string (next byte will have bit 7=0) or a continuation string
;; (next byte will have bit 7=1)
        jr      _display_message_10;{{28B0:18f7}}  continue displaying string 

;; finished displaying complete string , or displayed part of string sequence
_display_message_15:              ;{{Addr=$28b2 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{28B2:e1}} 

        inc     hl                ;{{28B3:23}}  if part of a complete message, go to next sub-string or word
        ret                       ;{{28B4:c9}} 

;;=========================================================================
;; display message with word wrap

;; HL = address of message
;; A = first character in message

;; if -ve, then bit 7 is set. Bit 6..0 define the ID of the message to display
;; if +ve, then this is the first character in the message
display_message_with_word_wrap:   ;{{Addr=$28b5 Code Calls/jump count: 1 Data use count: 0}}
        jp      m,display_message ;{{28B5:fa9928}} 


;;-------------------------------------
;; count number of letters in word

        push    hl                ;{{28B8:e5}} ; store start of word

;; count number of letters in world
        ld      b,$00             ;{{28B9:0600}} 
_display_message_with_word_wrap_3:;{{Addr=$28bb Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{28BB:04}} 

        ld      a,(hl)            ;{{28BC:7e}} ; get character
        inc     hl                ;{{28BD:23}} ; increment pointer
        rlca                      ;{{28BE:07}} ; if bit 7 is set, then this is the last character of the current word
        jr      nc,_display_message_with_word_wrap_3;{{28BF:30fa}} 

;; B = number of letters

;; if word will not fit onto end of current line, insert
;; a line break, and display on next line
        call    determine_if_word_can_be_displayed_on_this_line;{{28C1:cdfd28}} 

        pop     hl                ;{{28C4:e1}} ; restore start of word 

;;------------------------------------
;; display word

;; HL = location of characters
;; B = number of characters 
_display_message_with_word_wrap_10:;{{Addr=$28c5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{28C5:7e}}  get byte
        inc     hl                ;{{28C6:23}}  increment counter
        and     $7f               ;{{28C7:e67f}}  isolate byte
        call    _prepare_display_for_message_14;{{28C9:cdf028}}  display char (txt output?)
        djnz    _display_message_with_word_wrap_10;{{28CC:10f7}} 

;; display space
_display_message_with_word_wrap_15:;{{Addr=$28ce Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$20             ;{{28CE:3e20}}  " " (space) character
        jr      _prepare_display_for_message_14;{{28D0:181e}}  display character

;;=========================================================================
;; prepare display for message
prepare_display_for_message:      ;{{Addr=$28d2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(cassette_handling_messages_flag_);{{28D2:3a18b1}}  cassette messages enabled?
        or      a                 ;{{28D5:b7}} 
        scf                       ;{{28D6:37}} 
        ret     nz                ;{{28D7:c0}} 

        call    x2891_code        ;{{28D8:cd9128}}  display message

        call    KM_FLUSH          ;{{28DB:cdfe1b}}  KM FLUSH
        call    TXT_CUR_ON        ;{{28DE:cd7612}}  TXT CUR ON
        call    KM_WAIT_KEY       ;{{28E1:cddb1c}}  KM WAIT KEY
        call    TXT_CUR_OFF       ;{{28E4:cd7e12}}  TXT CUR OFF
        cp      $fc               ;{{28E7:fefc}} 
        ret     z                 ;{{28E9:c8}} 

        scf                       ;{{28EA:37}} 

;;-----------------------------------------------------------------------

_prepare_display_for_message_12:  ;{{Addr=$28eb Code Calls/jump count: 5 Data use count: 0}}
        call    set_column_1      ;{{28EB:cdf328}} 

;; display cr
        ld      a,$0a             ;{{28EE:3e0a}} 
_prepare_display_for_message_14:  ;{{Addr=$28f0 Code Calls/jump count: 5 Data use count: 0}}
        jp      TXT_OUTPUT        ;{{28F0:c3fe13}}  TXT OUTPUT

;;==========================================================================
;; set column 1
set_column_1:                     ;{{Addr=$28f3 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{28F3:f5}} 
        push    hl                ;{{28F4:e5}} 
        ld      a,$01             ;{{28F5:3e01}} 
        call    TXT_SET_COLUMN    ;{{28F7:cd5a11}}  TXT SET COLUMN
        pop     hl                ;{{28FA:e1}} 
        pop     af                ;{{28FB:f1}} 
        ret                       ;{{28FC:c9}} 

;;==========================================================================
;; determine if word can be displayed on this line
determine_if_word_can_be_displayed_on_this_line:;{{Addr=$28fd Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{28FD:d5}} 
        call    TXT_GET_WINDOW    ;{{28FE:cd5212}}  TXT GET WINDOW
        ld      e,h               ;{{2901:5c}} 
        call    TXT_GET_CURSOR    ;{{2902:cd7c11}}  TXT GET CURSOR
        ld      a,h               ;{{2905:7c}} 
        dec     a                 ;{{2906:3d}} 
        add     a,e               ;{{2907:83}} 
        add     a,b               ;{{2908:80}} 
        dec     a                 ;{{2909:3d}} 
        cp      d                 ;{{290A:ba}} 
        pop     de                ;{{290B:d1}} 
        ret     c                 ;{{290C:d8}} 

        ld      a,$ff             ;{{290D:3eff}} 
        ld      (RAM_b119),a      ;{{290F:3219b1}} 
        jr      _prepare_display_for_message_12;{{2912:18d7}}  (-&29)


;;============================================================================

;; divide by 10
divide_by_10:                     ;{{Addr=$2914 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$ff             ;{{2914:06ff}} 
_divide_by_10_1:                  ;{{Addr=$2916 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{2916:04}} 
        sub     $0a               ;{{2917:d60a}} 
        jr      nc,_divide_by_10_1;{{2919:30fb}}  (-&05)
;; B = result of division by 10
;; A = <10

        add     a,$3a             ;{{291B:c63a}}  convert to ASCII digit
			
        push    af                ;{{291D:f5}} 
        ld      a,b               ;{{291E:78}} 
        or      a                 ;{{291F:b7}} 
        call    nz,divide_by_10   ;{{2920:c41429}}  continue with division

        pop     af                ;{{2923:f1}} 
        jr      _prepare_display_for_message_14;{{2924:18ca}}  display character

;;============================================================================
;; convert character to upper case
convert_character_to_upper_case:  ;{{Addr=$2926 Code Calls/jump count: 4 Data use count: 0}}
        cp      $61               ;{{2926:fe61}}  "a"
        ret     c                 ;{{2928:d8}} 

        cp      $7b               ;{{2929:fe7b}}  "z"
        ret     nc                ;{{292B:d0}} 

        add     a,$e0             ;{{292C:c6e0}} 
        ret                       ;{{292E:c9}} 

;;============================================================================
;; test if read function is CATALOG
;;
;; zero set = catalog
;; zero clear = not catalog
test_if_read_function_is_CATALOG: ;{{Addr=$292f Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(file_IN_flag_) ;{{292F:3a1ab1}}  get current read function
        cp      $04               ;{{2932:fe04}}  catalog function?
        ret                       ;{{2934:c9}} 

;;============================================================================
;; cassette messages
;; - a zero (0) byte indicates end of complete message
;; - a byte with bit 7 set indicates:
;;	 end of a word, the id of another continuing string
;; 0: "Press"
;; 1: "PLAY then any key:"
;; 2: "error"
;; 3: "Press PLAY then any key:"
;; 4: "Press REC and PLAY then any key:"
;; 5: "Read error"
;; 6: "Write error"
;; 7: "Rewind tape"
;; 8: "Found  "
;; 9: "Loading"
;; 10: "Saving"
;; 11: <blank>
;; 12: "Ok"
;; 13: "block"
;; 14: "Unnamed file"

cassette_messages:                ;{{Addr=$2935 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "Pres","s"+$80,0     
        defb "PLA","Y"+$80,"the","n"+$80,"an","y"+$80,"key",":"+$80,0
        defb "erro","r"+$80,0     
        defb 0+$80,1+$80,0        
        defb 0+$80,"RE","C"+$80,"an","d"+$80,$81,0
        defb "Rea","d"+$80,$82,0  
        defb "Writ","e"+$80,$82,0 
        defb "Rewin","d"+$80,"tap","e"+$80,0
        defb "Found "," "+$80,0   
        defb "Loadin","g"+$80,0   
        defb "Savin","g"+$80,0    
        defb 0                    
        defb "O","k"+$80,0        
        defb "bloc","k"+$80,0     
        defb "Unname","d"+$80,"file   "," "+$80,0


;;=========================================================================
;; CAS READ

;; A = sync byte
;; HL = location of data
;; DE = length of data

CAS_READ:                         ;{{Addr=$29a6 Code Calls/jump count: 2 Data use count: 1}}
        call    enable_key_checking_and_start_the_cassette_motor;{{29A6:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29A9:f5}} 
        ld      hl,Read_block_of_data;{{29AA:21282a}}  read block of data ##LABEL##
        jr      _cas_check_3      ;{{29AD:1819}}  do read

;;=========================================================================
;; CAS WRITE

;; A = sync byte
;; HL = destination location for data
;; DE = length of data

CAS_WRITE:                        ;{{Addr=$29af Code Calls/jump count: 2 Data use count: 1}}
        call    enable_key_checking_and_start_the_cassette_motor;{{29AF:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29B2:f5}} 
        call    write_start_of_block;{{29B3:cdd42a}} ; write start of block (pilot and syncs)
        ld      hl,write_block_of_data_;{{29B6:21672a}} ; write block of data ##LABEL##
        call    c,readwrite_blocks;{{29B9:dc0d2a}} ; read/write 256 byte blocks
        call    c,write_trailer__33_1_bits;{{29BC:dce92a}} ; write trailer
        jr      _cas_check_7      ;{{29BF:180f}} ; 

;;=========================================================================
;; CAS CHECK

CAS_CHECK:                        ;{{Addr=$29c1 Code Calls/jump count: 0 Data use count: 1}}
        call    enable_key_checking_and_start_the_cassette_motor;{{29C1:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29C4:f5}} 
        ld      hl,check_stored_block_with_block_in_memory;{{29C5:21372a}} ; check stored block with block in memory ##LABEL##

;;------------------------------------------------------
;; do read
;; cas check or cas read
_cas_check_3:                     ;{{Addr=$29c8 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{29C8:e5}} 
        call    read_pilot_and_sync;{{29C9:cd892a}} ; read pilot and sync
        pop     hl                ;{{29CC:e1}} 
        call    c,readwrite_blocks;{{29CD:dc0d2a}} ; read/write 256 byte blocks


;;----------------------------------------------------------------
;; cas check, cas read or cas write
_cas_check_7:                     ;{{Addr=$29d0 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{29D0:d1}} 
        push    af                ;{{29D1:f5}} 

        ld      bc,$f782          ;{{29D2:0182f7}} ; set PPI port A to output
        out     (c),c             ;{{29D5:ed49}} 

        ld      bc,$f610          ;{{29D7:0110f6}} ; cassette motor on
        out     (c),c             ;{{29DA:ed49}} 

;; if cassette motor is stopped, then it will stop immediatly
;; if cassette motor is running, then there will not be any pause.

        ei                        ;{{29DC:fb}} ; enable interrupts

        ld      a,d               ;{{29DD:7a}} 
        call    CAS_RESTORE_MOTOR ;{{29DE:cdc12b}} ; CAS RESTORE MOTOR
        pop     af                ;{{29E1:f1}} 
        ret                       ;{{29E2:c9}} 

;;=========================================================================
;; enable key checking and start the cassette motor

;; store marker
enable_key_checking_and_start_the_cassette_motor:;{{Addr=$29e3 Code Calls/jump count: 3 Data use count: 0}}
        ld      (synchronisation_byte),a;{{29E3:32e5b1}} 

        dec     de                ;{{29E6:1b}} 
        inc     e                 ;{{29E7:1c}} 

        push    hl                ;{{29E8:e5}} 
        push    de                ;{{29E9:d5}} 
        call    SOUND_RESET       ;{{29EA:cde91f}}  SOUND RESET
        pop     de                ;{{29ED:d1}} 
        pop     ix                ;{{29EE:dde1}} 

        call    CAS_START_MOTOR   ;{{29F0:cdbb2b}}  CAS START MOTOR


        di                        ;{{29F3:f3}} ; disable interrupts

;; select PSG register 14 (PSG port A)
;; (keyboard data is connected to PSG port A)
        ld      bc,$f40e          ;{{29F4:010ef4}} ; select keyboard line 14
        out     (c),c             ;{{29F7:ed49}} 

        ld      bc,$f6d0          ;{{29F9:01d0f6}} ; cassette motor on + PSG select register operation
        out     (c),c             ;{{29FC:ed49}} 

        ld      c,$10             ;{{29FE:0e10}} 
        out     (c),c             ;{{2A00:ed49}} ; cassette motor on + PSG inactive operation

        ld      bc,$f792          ;{{2A02:0192f7}} ; set PPI port A to input
        out     (c),c             ;{{2A05:ed49}} 
                                  ;; PSG port A data can be read through PPI port A now

        ld      bc,$f658          ;{{2A07:0158f6}} ; cassette motor on + PSG read data operation + select keyboard line 8
        out     (c),c             ;{{2A0A:ed49}} 
        ret                       ;{{2A0C:c9}} 

;;========================================================================================
;; read/write blocks

;; DE = number of bytes to read/write
;; HL = address of routine to call to do the read/write/verify etc.

;; D = number of 256 blocks to read/write 
;; if D = 0, then there is a single block to write, which has E bytes
;; in it.
;; if D!=0, then there is more than one block to write, write 256 bytes
;; for each block except the last. Then write final block with remaining
;; bytes.

readwrite_blocks:                 ;{{Addr=$2a0d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{2A0D:7a}} 
        or      a                 ;{{2A0E:b7}} 
        jr      z,_readwrite_blocks_12;{{2A0F:280d}}  (+&0d)

;; do each complete 256 byte block
_readwrite_blocks_3:              ;{{Addr=$2a11 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{2A11:e5}} 
        push    de                ;{{2A12:d5}} 
        ld      e,$00             ;{{2A13:1e00}}  number of bytes
        call    _readwrite_blocks_12;{{2A15:cd1e2a}}  read/write block
        pop     de                ;{{2A18:d1}} 
        pop     hl                ;{{2A19:e1}} 
        ret     nc                ;{{2A1A:d0}} 

        dec     d                 ;{{2A1B:15}} 
        jr      nz,_readwrite_blocks_3;{{2A1C:20f3}}  (-&0d)

;; E = number of bytes in last block to write

;;------------------------------------
;; initialise crc
_readwrite_blocks_12:             ;{{Addr=$2a1e Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$ffff          ;{{2A1E:01ffff}} 
        ld      (RAM_b1eb),bc     ;{{2A21:ed43ebb1}}  crc 

;; do function
        ld      d,$01             ;{{2A25:1601}} 
        jp      (hl)              ;{{2A27:e9}} 

;;========================================================================================
;; Read block of data
;; IX = address to load data to 
;; read data
;; input:
;; D = block size
;; E = actual data size
;; output:
;; D = bytes remaining in block (block size - actual data size)

Read_block_of_data:               ;{{Addr=$2a28 Code Calls/jump count: 1 Data use count: 1}}
        call    read_databyte     ;{{2A28:cd202b}}  read byte from cassette
        ret     nc                ;{{2A2B:d0}} 

        ld      (ix+$00),a        ;{{2A2C:dd7700}}  store byte
        inc     ix                ;{{2A2F:dd23}}  increment pointer

        dec     d                 ;{{2A31:15}}  decrement block count

        dec     e                 ;{{2A32:1d}} 
        jr      nz,Read_block_of_data;{{2A33:20f3}}  decrement actual data count

;; D = number of bytes remaining in block

;; read remaining bytes in block; but ignore
        jr      _check_stored_block_with_block_in_memory_11;{{2A35:1812}}  (+&12)

;;========================================================================================
;; check stored block with block in memory
check_stored_block_with_block_in_memory:;{{Addr=$2a37 Code Calls/jump count: 1 Data use count: 1}}
        call    read_databyte     ;{{2A37:cd202b}}  read byte from cassette
        ret     nc                ;{{2A3A:d0}} 

        ld      b,a               ;{{2A3B:47}} 
        call    read_byte_from_address_pointed_to_IX_with_roms_disabled;{{2A3C:cdd7ba}}  get byte from IX with roms disabled
        xor     b                 ;{{2A3F:a8}} 


        ld      a,$03             ;{{2A40:3e03}}  
        ret     nz                ;{{2A42:c0}} 

        inc     ix                ;{{2A43:dd23}} 
        dec     d                 ;{{2A45:15}} 
        dec     e                 ;{{2A46:1d}} 
        jr      nz,check_stored_block_with_block_in_memory;{{2A47:20ee}}  (-&12)

;; any more bytes remaining in block??
_check_stored_block_with_block_in_memory_11:;{{Addr=$2a49 Code Calls/jump count: 2 Data use count: 0}}
        dec     d                 ;{{2A49:15}} 
        jr      z,_check_stored_block_with_block_in_memory_16;{{2A4A:2806}}  

;; bytes remaining
;; read the remaining bytes but ignore

        call    read_databyte     ;{{2A4C:cd202b}}  read byte from cassette	
        ret     nc                ;{{2A4F:d0}} 

        jr      _check_stored_block_with_block_in_memory_11;{{2A50:18f7}}  

;;-----------------------------------------------------

_check_stored_block_with_block_in_memory_16:;{{Addr=$2a52 Code Calls/jump count: 1 Data use count: 0}}
        call    get_stored_data_crc_and_1s_complement_it;{{2A52:cd162b}}  get 1's complemented crc

        call    read_databyte     ;{{2A55:cd202b}}  read crc byte1 from cassette
        ret     nc                ;{{2A58:d0}} 

        xor     d                 ;{{2A59:aa}} 
        jr      nz,_check_stored_block_with_block_in_memory_26;{{2A5A:2007}} 

        call    read_databyte     ;{{2A5C:cd202b}}  read crc byte2 from cassette
        ret     nc                ;{{2A5F:d0}} 

        xor     e                 ;{{2A60:ab}} 
        scf                       ;{{2A61:37}} 
        ret     z                 ;{{2A62:c8}} 

_check_stored_block_with_block_in_memory_26:;{{Addr=$2a63 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$02             ;{{2A63:3e02}} 
        or      a                 ;{{2A65:b7}} 
        ret                       ;{{2A66:c9}} 

;;========================================================================================
;; write block of data 
;; (pad with 0's if less than block size)
;; IX = address of data
;; E = actual byte count
;; D = block size count
 
write_block_of_data_:             ;{{Addr=$2a67 Code Calls/jump count: 1 Data use count: 1}}
        call    read_byte_from_address_pointed_to_IX_with_roms_disabled;{{2A67:cdd7ba}}  get byte from IX with roms disabled
        call    write_data_byte_to_cassette;{{2A6A:cd682b}}  write data byte
        ret     nc                ;{{2A6D:d0}} 

        inc     ix                ;{{2A6E:dd23}}  increment pointer

        dec     d                 ;{{2A70:15}}  decrement block size count
        dec     e                 ;{{2A71:1d}}  decrement actual count
        jr      nz,write_block_of_data_;{{2A72:20f3}}  (-&0d)

;; actual byte count = block size count?
_write_block_of_data__7:          ;{{Addr=$2a74 Code Calls/jump count: 1 Data use count: 0}}
        dec     d                 ;{{2A74:15}} 
        jr      z,_write_block_of_data__13;{{2A75:2807}} 

;; no, actual byte count was less than block size
;; pad up to block size with zeros

        xor     a                 ;{{2A77:af}} 
        call    write_data_byte_to_cassette;{{2A78:cd682b}}  write data byte
        ret     nc                ;{{2A7B:d0}} 

        jr      _write_block_of_data__7;{{2A7C:18f6}}  (-&0a)


;; get 1's complemented crc
_write_block_of_data__13:         ;{{Addr=$2a7e Code Calls/jump count: 1 Data use count: 0}}
        call    get_stored_data_crc_and_1s_complement_it;{{2A7E:cd162b}} 

;; write crc 1
        call    write_data_byte_to_cassette;{{2A81:cd682b}}  write data byte
        ret     nc                ;{{2A84:d0}} 

;; write crc 2
        ld      a,e               ;{{2A85:7b}} 
        jp      write_data_byte_to_cassette;{{2A86:c3682b}}  write data byte

;;========================================================================================
;; read pilot and sync

read_pilot_and_sync:              ;{{Addr=$2a89 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{2A89:d5}} 
        call    read_pilot_and_sync_B;{{2A8A:cd932a}}  read pilot and sync
        pop     de                ;{{2A8D:d1}} 

        ret     c                 ;{{2A8E:d8}} 

        or      a                 ;{{2A8F:b7}} 
        ret     z                 ;{{2A90:c8}} 

        jr      read_pilot_and_sync;{{2A91:18f6}}  (-&0a)

;;==========================================================================
;; read pilot and sync

;;---------------------------------
;; wait for start of leader/pilot

read_pilot_and_sync_B:            ;{{Addr=$2a93 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,$55             ;{{2A93:2e55}}  %01010101
                                  ; this is used to generate the cassette input data comparison 
                                  ; used in the edge detection

        call    sample_edge_and_check_for_escape;{{2A95:cd3d2b}}  sample edge
        ret     nc                ;{{2A98:d0}} 

;;------------------------------------------
;; get 256 pulses of leader/pilot
        ld      de,$0000          ;{{2A99:110000}}  initial total ##LIT##;WARNING: Code area used as literal

        ld      h,d               ;{{2A9C:62}} 

_read_pilot_and_sync_b_5:         ;{{Addr=$2a9d Code Calls/jump count: 1 Data use count: 0}}
        call    sample_edge_and_check_for_escape;{{2A9D:cd3d2b}}  sample edge
        ret     nc                ;{{2AA0:d0}} 

        ex      de,hl             ;{{2AA1:eb}} 
;; C = measured time
;; add measured time to total
        ld      b,$00             ;{{2AA2:0600}} 
        add     hl,bc             ;{{2AA4:09}} 
        ex      de,hl             ;{{2AA5:eb}} 

        dec     h                 ;{{2AA6:25}} 
        jr      nz,_read_pilot_and_sync_b_5;{{2AA7:20f4}}  (-&0c)


;; C = duration of last pulse read

;; look for sync bit
;; and adjust the average for every non-sync

;; DE = sum of 256 edges
;; D:E forms a 8.8 fixed point number
;; D = integer part of number (integer average of 256 pulses)
;; E = fractional part of number

_read_pilot_and_sync_b_13:        ;{{Addr=$2aa9 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,c               ;{{2AA9:61}}  time of last pulse

        ld      a,c               ;{{2AAA:79}} 
        sub     d                 ;{{2AAB:92}}  subtract initial average 
        ld      c,a               ;{{2AAC:4f}} 
        sbc     a,a               ;{{2AAD:9f}} 
        ld      b,a               ;{{2AAE:47}} 

;; if C>D then BC is +ve; BC = +ve delta
;; if C<D then BC is -ve; BC = -ve delta

;; adjust average
        ex      de,hl             ;{{2AAF:eb}} 
        add     hl,bc             ;{{2AB0:09}}  DE = DE + BC
        ex      de,hl             ;{{2AB1:eb}} 

        call    sample_edge_and_check_for_escape;{{2AB2:cd3d2b}}  sample edge
        ret     nc                ;{{2AB5:d0}} 

; A = D * 5/4
        ld      a,d               ;{{2AB6:7a}}  average so far			
        srl     a                 ;{{2AB7:cb3f}}  /2
        srl     a                 ;{{2AB9:cb3f}}  /4
                                  ; A = D * 1/4
        adc     a,d               ;{{2ABB:8a}}  A = D + (D*1/4)

;; sync pulse will have a duration which is half that of a pulse in a 1 bit
;; average<previous 


        sub     h                 ;{{2ABC:94}}  time of last pulse
        jr      c,_read_pilot_and_sync_b_13;{{2ABD:38ea}}  carry set if H>A

;; average>=previous (possibly read first pulse of sync or second of sync)

        sub     c                 ;{{2ABF:91}}  time of current pulse
        jr      c,_read_pilot_and_sync_b_13;{{2AC0:38e7}}  carry set if C>(A-H)

;; to get here average>=(previous*2)
;; and this means we have just read the second pulse of the sync bit


;; calculate bit 1 timing
        ld      a,d               ;{{2AC2:7a}}  average
        rra                       ;{{2AC3:1f}}  /2
                                  ; A = D/2
        adc     a,d               ;{{2AC4:8a}}  A = D + (D/2)
                                  ; A = D * (3/2)
        ld      h,a               ;{{2AC5:67}} 
                                  ; this is the middle time
                                  ; to calculate difference between 0 and 1 bit

;; if pulse measured is > this time, then we have a 1 bit
;; if pulse measured is < this time, then we have a 0 bit

;; H = timing constant
;; L = initial cassette data input state
        ld      (RAM_b1e6),hl     ;{{2AC6:22e6b1}} 

;; read marker
        call    read_databyte     ;{{2AC9:cd202b}}  read data-byte
        ret     nc                ;{{2ACC:d0}} 

        ld      hl,synchronisation_byte;{{2ACD:21e5b1}}  marker
        xor     (hl)              ;{{2AD0:ae}} 
        ret     nz                ;{{2AD1:c0}} 

        scf                       ;{{2AD2:37}} 
        ret                       ;{{2AD3:c9}} 

;;========================================================================================
;; write start of block
write_start_of_block:             ;{{Addr=$2ad4 Code Calls/jump count: 1 Data use count: 0}}
        call    tenth_of_a_second_delay;{{2AD4:cdf92b}} ; 1/100th of a second delay

;; write leader
        ld      hl,$0801          ;{{2AD7:210108}} ; 2049 ##LIT##;WARNING: Code area used as literal
        call    _write_trailer__33_1_bits_1;{{2ADA:cdec2a}} ; write leader (2049 1 bits; 4096 pulses)
        ret     nc                ;{{2ADD:d0}} 

;; write sync bit
        or      a                 ;{{2ADE:b7}} 
        call    write_bit_to_cassette;{{2ADF:cd782b}} ; write data-bit
        ret     nc                ;{{2AE2:d0}} 

;; write marker
        ld      a,(synchronisation_byte);{{2AE3:3ae5b1}} 
        jp      write_data_byte_to_cassette;{{2AE6:c3682b}} ; write data byte

;;=============================================================================
;; write trailer = 33 "1" bits
;;
;; carry set = trailer written successfully
;; zero set = escape was pressed

write_trailer__33_1_bits:         ;{{Addr=$2ae9 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,$0021          ;{{2AE9:212100}} ; 33 ##LIT##;WARNING: Code area used as literal

;; check for escape
_write_trailer__33_1_bits_1:      ;{{Addr=$2aec Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$f4             ;{{2AEC:06f4}} ; PPI port A
        in      a,(c)             ;{{2AEE:ed78}} ; read keyboard data through PPI port A (connected to PSG port A)
        and     $04               ;{{2AF0:e604}} ; escape key pressed?
                                  ;; bit 2 is 0 if escape key pressed
        ret     z                 ;{{2AF2:c8}} 

;; write trailer bit
        push    hl                ;{{2AF3:e5}} 
        scf                       ;{{2AF4:37}} ; a "1" bit   
        call    write_bit_to_cassette;{{2AF5:cd782b}} ; write data-bit
        pop     hl                ;{{2AF8:e1}} 
        dec     hl                ;{{2AF9:2b}} ; decrement trailer bit count

        ld      a,h               ;{{2AFA:7c}} 
        or      l                 ;{{2AFB:b5}} 
        jr      nz,_write_trailer__33_1_bits_1;{{2AFC:20ee}} ;

        scf                       ;{{2AFE:37}} 
        ret                       ;{{2AFF:c9}} 
;;=============================================================================

;; update crc
update_crc:                       ;{{Addr=$2b00 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(RAM_b1eb)     ;{{2B00:2aebb1}} ; get crc
        xor     h                 ;{{2B03:ac}} 
        jp      p,_update_crc_10  ;{{2B04:f2102b}} 

        ld      a,h               ;{{2B07:7c}} 
        xor     $08               ;{{2B08:ee08}} 
        ld      h,a               ;{{2B0A:67}} 
        ld      a,l               ;{{2B0B:7d}} 
        xor     $10               ;{{2B0C:ee10}} 
        ld      l,a               ;{{2B0E:6f}} 
        scf                       ;{{2B0F:37}} 

_update_crc_10:                   ;{{Addr=$2b10 Code Calls/jump count: 1 Data use count: 0}}
        adc     hl,hl             ;{{2B10:ed6a}} 
        ld      (RAM_b1eb),hl     ;{{2B12:22ebb1}} ; store crc
        ret                       ;{{2B15:c9}} 

;;========================================================================================
;; get stored data crc and 1's complement it
;; initialise ready to write to cassette or to compare against crc from cassette

get_stored_data_crc_and_1s_complement_it:;{{Addr=$2b16 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(RAM_b1eb)     ;{{2B16:2aebb1}} ; block crc

;; 1's complement crc
        ld      a,l               ;{{2B19:7d}} 
        cpl                       ;{{2B1A:2f}} 
        ld      e,a               ;{{2B1B:5f}} 
        ld      a,h               ;{{2B1C:7c}} 
        cpl                       ;{{2B1D:2f}} 
        ld      d,a               ;{{2B1E:57}} 
        ret                       ;{{2B1F:c9}} 

;;========================================================================================
;; read data-byte

read_databyte:                    ;{{Addr=$2b20 Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{2B20:d5}} 
        ld      e,$08             ;{{2B21:1e08}} ; number of data-bits

_read_databyte_2:                 ;{{Addr=$2b23 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b1e6)     ;{{2B23:2ae6b1}} 
;; H = timing constant
;; L = initial cassette data input state

        call    _sample_edge_and_check_for_escape_4;{{2B26:cd442b}} ; get edge

        call    c,_sample_edge_and_check_for_escape_10;{{2B29:dc4d2b}} ; get edge
        jr      nc,_read_databyte_15;{{2B2C:300d}} 

        ld      a,h               ;{{2B2E:7c}} ; ideal time
        sub     c                 ;{{2B2F:91}} ; subtract measured time
                                  ;; -ve (1 pulse) or +ve (0 pulse)
        sbc     a,a               ;{{2B30:9f}} 
                                  ;; if -ve, set carry
                                  ;; if +ve, clear carry

;; carry flag = bit state: carry set = 1 bit, carry clear = 0 bit

        rl      d                 ;{{2B31:cb12}} ; shift carry state into bit 0
                                  ;; updating data-byte
										
        call    update_crc        ;{{2B33:cd002b}} ; update crc
        dec     e                 ;{{2B36:1d}} 
        jr      nz,_read_databyte_2;{{2B37:20ea}}  

        ld      a,d               ;{{2B39:7a}} 
        scf                       ;{{2B3A:37}} 
_read_databyte_15:                ;{{Addr=$2b3b Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{2B3B:d1}} 
        ret                       ;{{2B3C:c9}} 

;;========================================================================================
;; sample edge and check for escape
;; L = bit-sequence which is shifted after each edge detected
;; starts of as &55 (%01010101)

;; check for escape
sample_edge_and_check_for_escape: ;{{Addr=$2b3d Code Calls/jump count: 3 Data use count: 0}}
        ld      b,$f4             ;{{2B3D:06f4}} ; PPI port A
        in      a,(c)             ;{{2B3F:ed78}} ; read keyboard data through PPI port A (connected to PSG port A)
        and     $04               ;{{2B41:e604}} ; escape key pressed?
                                  ;; bit 2 is 0 if escape key pressed
        ret     z                 ;{{2B43:c8}} 


;; precompensation?
_sample_edge_and_check_for_escape_4:;{{Addr=$2b44 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,r               ;{{2B44:ed5f}} 

;; round up to divisible by 4
;; i.e.
;; 0->0, 
;; 1->4, 
;; 2->4, 
;; 3->4, 
;; 4->8, 
;; 5->8
;; etc

        add     a,$03             ;{{2B46:c603}} 
        rrca                      ;{{2B48:0f}} ; /2
        rrca                      ;{{2B49:0f}} ; /4

        and     $1f               ;{{2B4A:e61f}} ; 

        ld      c,a               ;{{2B4C:4f}} 

_sample_edge_and_check_for_escape_10:;{{Addr=$2b4d Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f5             ;{{2B4D:06f5}}  PPI port B input (includes cassette data input)

;; -----------------------------------------------------
;; loop to count time between edges
;; C = time in 17us units (68T states)
;; carry set = edge arrived within time
;; carry clear = edge arrived too late

_sample_edge_and_check_for_escape_11:;{{Addr=$2b4f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{2B4F:79}}  [1] update edge timer
        add     a,$02             ;{{2B50:c602}}  [2]
        ld      c,a               ;{{2B52:4f}}  [1]
        jr      c,_sample_edge_and_check_for_escape_24;{{2B53:380e}}  [3] overflow?

        in      a,(c)             ;{{2B55:ed78}}  [4] read cassette input data
        xor     l                 ;{{2B57:ad}}  [1]
        and     $80               ;{{2B58:e680}}  [2] isolate cassette input in bit 7
        jr      nz,_sample_edge_and_check_for_escape_11;{{2B5A:20f3}}  [3] has bit 7 (cassette data input) changed state?

;; pulse successfully read

        xor     a                 ;{{2B5C:af}} 
        ld      r,a               ;{{2B5D:ed4f}} 

        rrc     l                 ;{{2B5F:cb0d}}  toggles between 0 and 1 

        scf                       ;{{2B61:37}} 
        ret                       ;{{2B62:c9}} 

;; time-out
_sample_edge_and_check_for_escape_24:;{{Addr=$2b63 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{2B63:af}} 
        ld      r,a               ;{{2B64:ed4f}} 
        inc     a                 ;{{2B66:3c}}  "read error a"
        ret                       ;{{2B67:c9}} 

;;========================================================================================
;; write data byte to cassette
;; A = data byte
write_data_byte_to_cassette:      ;{{Addr=$2b68 Code Calls/jump count: 5 Data use count: 0}}
        push    de                ;{{2B68:d5}} 
        ld      e,$08             ;{{2B69:1e08}} ; number of bits
        ld      d,a               ;{{2B6B:57}} 

_write_data_byte_to_cassette_3:   ;{{Addr=$2b6c Code Calls/jump count: 1 Data use count: 0}}
        rlc     d                 ;{{2B6C:cb02}} ; shift bit state into carry
        call    write_bit_to_cassette;{{2B6E:cd782b}} ; write bit to cassette
        jr      nc,_write_data_byte_to_cassette_8;{{2B71:3003}} 

        dec     e                 ;{{2B73:1d}} 
        jr      nz,_write_data_byte_to_cassette_3;{{2B74:20f6}} ; loop for next bit

_write_data_byte_to_cassette_8:   ;{{Addr=$2b76 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{2B76:d1}} 
        ret                       ;{{2B77:c9}} 

;;========================================================================================
;; write bit to cassette
;;
;; carry flag = state of bit
;; carry set = 1 data bit
;; carry clear = 0 data bit

write_bit_to_cassette:            ;{{Addr=$2b78 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,(RAM_b1e8)     ;{{2B78:ed4be8b1}} 
        ld      hl,(cassette_Half_a_Zero_duration_);{{2B7C:2aeab1}} 
        sbc     a,a               ;{{2B7F:9f}} 
        ld      h,a               ;{{2B80:67}} 
        jr      z,_write_bit_to_cassette_12;{{2B81:2807}}  (+&07)
        ld      a,l               ;{{2B83:7d}} 
        add     a,a               ;{{2B84:87}} 
        add     a,b               ;{{2B85:80}} 
        ld      l,a               ;{{2B86:6f}} 
        ld      a,c               ;{{2B87:79}} 
        sub     b                 ;{{2B88:90}} 
        ld      c,a               ;{{2B89:4f}} 
_write_bit_to_cassette_12:        ;{{Addr=$2b8a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{2B8A:7d}} 
        ld      (RAM_b1e8),a      ;{{2B8B:32e8b1}} 

;; write a low level
        ld      l,$0a             ;{{2B8E:2e0a}}  %00001010 = clear bit 5 (cassette write data)
        call    write_level_to_cassette;{{2B90:cda72b}} 

        jr      c,_write_bit_to_cassette_22;{{2B93:3806}}  (+&06)
        sub     c                 ;{{2B95:91}} 
        jr      nc,_write_bit_to_cassette_26;{{2B96:300c}}  (+&0c)
        cpl                       ;{{2B98:2f}} 
        inc     a                 ;{{2B99:3c}} 
        ld      c,a               ;{{2B9A:4f}} 
_write_bit_to_cassette_22:        ;{{Addr=$2b9b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{2B9B:7c}} 
        call    update_crc        ;{{2B9C:cd002b}}  update crc

;; write a high level
        ld      l,$0b             ;{{2B9F:2e0b}}  %00001011 = set bit 5 (cassette write data)
        call    write_level_to_cassette;{{2BA1:cda72b}} 

_write_bit_to_cassette_26:        ;{{Addr=$2ba4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$01             ;{{2BA4:3e01}} 
        ret                       ;{{2BA6:c9}} 


;;=====================================================================
;; write level to cassette
;; uses PPI control bit set/clear function
;; L = PPI Control byte 
;;   bit 7 = 0
;;   bit 3,2,1 = bit index
;;   bit 0: 1=bit set, 0=bit clear

write_level_to_cassette:          ;{{Addr=$2ba7 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,r               ;{{2BA7:ed5f}} 
        srl     a                 ;{{2BA9:cb3f}} 
        sub     c                 ;{{2BAB:91}} 
        jr      nc,_write_level_to_cassette_6;{{2BAC:3003}}  

;; delay in 4us (16T-state) units
;; total delay = ((A-1)*4) + 3

_write_level_to_cassette_4:       ;{{Addr=$2bae Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{2BAE:3c}}  [1]
        jr      nz,_write_level_to_cassette_4;{{2BAF:20fd}}  [3] 

;; set low/high level
_write_level_to_cassette_6:       ;{{Addr=$2bb1 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f7             ;{{2BB1:06f7}}  PPI control 
        out     (c),l             ;{{2BB3:ed69}}  set control

        push    af                ;{{2BB5:f5}} 
        xor     a                 ;{{2BB6:af}} 
        ld      r,a               ;{{2BB7:ed4f}} 
        pop     af                ;{{2BB9:f1}} 
        ret                       ;{{2BBA:c9}} 

;;=====================================================================
;; CAS START MOTOR
;;
;; start cassette motor (if cassette motor was previously off
;; allow to to achieve full rotational speed)
CAS_START_MOTOR:                  ;{{Addr=$2bbb Code Calls/jump count: 2 Data use count: 1}}
        ld      a,$10             ;{{2BBB:3e10}}  start cassette motor
        jr      CAS_RESTORE_MOTOR ;{{2BBD:1802}}  CAS RESTORE MOTOR 

;;=====================================================================
;; CAS STOP MOTOR

CAS_STOP_MOTOR:                   ;{{Addr=$2bbf Code Calls/jump count: 2 Data use count: 1}}
        ld      a,$ef             ;{{2BBF:3eef}}  stop cassette motor

;;=====================================================================
;; CAS RESTORE MOTOR
;;
;; - if motor was switched from off->on, delay for a time to allow
;; cassette motor to achieve full rotational speed
;; - if motor was switched from on->off, do nothing

;; bit 4 of register A = cassette motor state
CAS_RESTORE_MOTOR:                ;{{Addr=$2bc1 Code Calls/jump count: 2 Data use count: 1}}
        push    bc                ;{{2BC1:c5}} 

        ld      b,$f6             ;{{2BC2:06f6}}  B = I/O address for PPI port C 
        in      c,(c)             ;{{2BC4:ed48}}  read current inputs (includes cassette input data)
        inc     b                 ;{{2BC6:04}}  B = I/O address for PPI control		

        and     $10               ;{{2BC7:e610}}  isolate cassette motor state from requested
                                  ; cassette motor status
									
        ld      a,$08             ;{{2BC9:3e08}}  %00001000	= cassette motor off
        jr      z,_cas_restore_motor_8;{{2BCB:2801}} 

        inc     a                 ;{{2BCD:3c}}  %00001001 = cassette motor on

_cas_restore_motor_8:             ;{{Addr=$2bce Code Calls/jump count: 1 Data use count: 0}}
        out     (c),a             ;{{2BCE:ed79}}  set the requested motor state
                                  ; (uses PPI Control bit set/reset feature)

        scf                       ;{{2BD0:37}} 
        jr      z,_cas_restore_motor_18;{{2BD1:280c}} 

        ld      a,c               ;{{2BD3:79}} 
        and     $10               ;{{2BD4:e610}}  previous state

        push    bc                ;{{2BD6:c5}} 
        ld      bc,$00c8          ;{{2BD7:01c800}}  delay in 1/100ths of a second ##LIT##;WARNING: Code area used as literal
        scf                       ;{{2BDA:37}} 
        call    z,delay__check_for_escape;{{2BDB:cce22b}}  delay for 2 seconds
        pop     bc                ;{{2BDE:c1}} 

_cas_restore_motor_18:            ;{{Addr=$2bdf Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{2BDF:79}} 
        pop     bc                ;{{2BE0:c1}} 
        ret                       ;{{2BE1:c9}} 

;;=================================================================
;; delay & check for escape
;; allows cassette motor to achieve full rotational speed

;; entry conditions:
;; B = delay factor in 1/100ths of a second

;; exit conditions:
;; c = delay completed and escape was not pressed
;; nc = escape was pressed

delay__check_for_escape:          ;{{Addr=$2be2 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{2BE2:c5}} 
        push    hl                ;{{2BE3:e5}} 
        call    tenth_of_a_second_delay;{{2BE4:cdf92b}} ; 1/100th of a second delay

        ld      a,$42             ;{{2BE7:3e42}} ; keycode for escape key 
        call    KM_TEST_KEY       ;{{2BE9:cd451e}} ; check for escape pressed (km test key)
                                  ;; if non-zero then escape key has been pressed
                                  ;; if zero, then escape key is not pressed
        pop     hl                ;{{2BEC:e1}} 
        pop     bc                ;{{2BED:c1}} 
        jr      nz,_delay__check_for_escape_14;{{2BEE:2007}} ; escape key pressed?

;; continue delay
        dec     bc                ;{{2BF0:0b}} 
        ld      a,b               ;{{2BF1:78}} 
        or      c                 ;{{2BF2:b1}} 
        jr      nz,delay__check_for_escape;{{2BF3:20ed}} 

;; delay completed successfully and escape was not pressed
        scf                       ;{{2BF5:37}} 
        ret                       ;{{2BF6:c9}} 

;; escape was pressed
_delay__check_for_escape_14:      ;{{Addr=$2bf7 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{2BF7:af}} 
        ret                       ;{{2BF8:c9}} 

;;========================================================================================
;; tenth of a second delay

tenth_of_a_second_delay:          ;{{Addr=$2bf9 Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$0682          ;{{2BF9:018206}}  [3] ##LIT##;WARNING: Code area used as literal

;; total delay is ((BC-1)*(2+1+1+3)) + (2+1+1+2) + 3 + 3 = 11667 microseconds
;; there are 1000000 microseconds in a second
;; therefore delay is 11667/1000000 = 0.01 seconds or 1/100th of a second

_tenth_of_a_second_delay_1:       ;{{Addr=$2bfc Code Calls/jump count: 1 Data use count: 0}}
        dec     bc                ;{{2BFC:0b}}  [2]
        ld      a,b               ;{{2BFD:78}}  [1]
        or      c                 ;{{2BFE:b1}}  [1]
        jr      nz,_tenth_of_a_second_delay_1;{{2BFF:20fb}}  [3]

        ret                       ;{{2C01:c9}}  [3]





;;***LineEditor.asm
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




;;***FPMaths.asm
;; MATHS ROUTINES
;;=============================================================================
;;
;;Limited documentation for these can be found at
;;https://www.cpcwiki.eu/index.php/BIOS_Function_Summary

;;=============================================================================
;; REAL: PI to DE
REAL_PI_to_DE:                    ;{{Addr=$2f73 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,PI_const       ;{{2F73:11782f}} 
        jr      REAL_copy_atDE_to_atHL;{{2F76:1819}} 

;;+
;;PI const
PI_const:                         ;{{Addr=$2f78 Data Calls/jump count: 0 Data use count: 1}}
        defb $a2,$da,$0f,$49,$82  ; PI in floating point format 3.14159265

;;===========================================================================================
;; REAL: ONE to DE
REAL_ONE_to_DE:                   ;{{Addr=$2f7d Code Calls/jump count: 4 Data use count: 0}}
        ld      de,ONE_const      ;{{2F7D:11822f}} 
        jr      REAL_copy_atDE_to_atHL;{{2F80:180f}}  (+&0f)

;;+
;;ONE const
ONE_const:                        ;{{Addr=$2f82 Data Calls/jump count: 0 Data use count: 2}}
        defb $00,$00,$00,$00,$81  ; 1 in floating point format

;;===========================================================================================
;;REAL copy atHL to b10e swapped
REAL_copy_atHL_to_b10e_swapped:   ;{{Addr=$2f87 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{2F87:eb}} 

;;= REAL move DE to b10e
REAL_move_DE_to_b10e:             ;{{Addr=$2f88 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,internal_REAL_store_3;{{2F88:210eb1}} 
        jr      REAL_copy_atDE_to_atHL;{{2F8B:1804}}  (+&04)

;;---------------------------------------
;;REAL copy atHL to b104
_real_move_de_to_b10e_2:          ;{{Addr=$2f8d Code Calls/jump count: 3 Data use count: 0}}
        ld      de,internal_REAL_store_1;{{2F8D:1104b1}} 

;;= REAL copy atHL to atDE swapped
REAL_copy_atHL_to_atDE_swapped:   ;{{Addr=$2f90 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{2F90:eb}} 

;;=---------------------------------------
;; REAL copy atDE to atHL
;; HL = points to address to write floating point number to
;; DE = points to address of a floating point number

REAL_copy_atDE_to_atHL:           ;{{Addr=$2f91 Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{2F91:e5}} 
        push    de                ;{{2F92:d5}} 
        push    bc                ;{{2F93:c5}} 
        ex      de,hl             ;{{2F94:eb}} 
        ld      bc,$0005          ;{{2F95:010500}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2F98:edb0}} 
        pop     bc                ;{{2F9A:c1}} 
        pop     de                ;{{2F9B:d1}} 
        pop     hl                ;{{2F9C:e1}} 
        scf                       ;{{2F9D:37}} 
        ret                       ;{{2F9E:c9}} 

;;============================================================================================
;; REAL: INT to real
REAL_INT_to_real:                 ;{{Addr=$2f9f Code Calls/jump count: 2 Data use count: 1}}
        push    de                ;{{2F9F:d5}} 
        push    bc                ;{{2FA0:c5}} 
        or      $7f               ;{{2FA1:f67f}} 
        ld      b,a               ;{{2FA3:47}} 
        xor     a                 ;{{2FA4:af}} 
        ld      (de),a            ;{{2FA5:12}} 
        inc     de                ;{{2FA6:13}} 
        ld      (de),a            ;{{2FA7:12}} 
        inc     de                ;{{2FA8:13}} 
        ld      c,$90             ;{{2FA9:0e90}} 
        or      h                 ;{{2FAB:b4}} 
        jr      nz,_real_int_to_real_21;{{2FAC:200d}}  (+&0d)
        ld      c,a               ;{{2FAE:4f}} 
        or      l                 ;{{2FAF:b5}} 
        jr      z,_real_int_to_real_23;{{2FB0:280d}}  (+&0d)
        ld      l,h               ;{{2FB2:6c}} 
        ld      c,$88             ;{{2FB3:0e88}} 
        jr      _real_int_to_real_21;{{2FB5:1804}}  (+&04)
_real_int_to_real_18:             ;{{Addr=$2fb7 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{2FB7:0d}} 
        sla     l                 ;{{2FB8:cb25}} 
        adc     a,a               ;{{2FBA:8f}} 
_real_int_to_real_21:             ;{{Addr=$2fbb Code Calls/jump count: 2 Data use count: 0}}
        jp      p,_real_int_to_real_18;{{2FBB:f2b72f}} 
        and     b                 ;{{2FBE:a0}} 
_real_int_to_real_23:             ;{{Addr=$2fbf Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2FBF:eb}} 
        ld      (hl),e            ;{{2FC0:73}} 
        inc     hl                ;{{2FC1:23}} 
        ld      (hl),a            ;{{2FC2:77}} 
        inc     hl                ;{{2FC3:23}} 
        ld      (hl),c            ;{{2FC4:71}} 
        pop     bc                ;{{2FC5:c1}} 
        pop     hl                ;{{2FC6:e1}} 
        ret                       ;{{2FC7:c9}} 

;;============================================================================================
;; REAL: BIN to real
REAL_BIN_to_real:                 ;{{Addr=$2fc8 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2FC8:c5}} 
        ld      bc,$a000          ;{{2FC9:0100a0}} 
        call    _real_5byte_to_real_1;{{2FCC:cdd32f}} 
        pop     bc                ;{{2FCF:c1}} 
        ret                       ;{{2FD0:c9}} 

;;============================================================================================
;; REAL 5-byte to real
REAL_5byte_to_real:               ;{{Addr=$2fd1 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$a8             ;{{2FD1:06a8}} 
_real_5byte_to_real_1:            ;{{Addr=$2fd3 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{2FD3:d5}} 
        call    Process_REAL_at_HL;{{2FD4:cd9c37}} 
        pop     de                ;{{2FD7:d1}} 
        ret                       ;{{2FD8:c9}} 

;;============================================================================================
;; REAL to int
REAL_to_int:                      ;{{Addr=$2fd9 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{2FD9:e5}} 
        pop     ix                ;{{2FDA:dde1}} 
        xor     a                 ;{{2FDC:af}} 
        sub     (ix+$04)          ;{{2FDD:dd9604}} 
        jr      z,_real_to_int_22 ;{{2FE0:281b}}  (+&1b)
        add     a,$90             ;{{2FE2:c690}} 
        ret     nc                ;{{2FE4:d0}} 

        push    de                ;{{2FE5:d5}} 
        push    bc                ;{{2FE6:c5}} 
        add     a,$10             ;{{2FE7:c610}} 
        call    x373D_code        ;{{2FE9:cd3d37}} 
        sla     c                 ;{{2FEC:cb21}} 
        adc     hl,de             ;{{2FEE:ed5a}} 
        jr      z,_real_to_int_20 ;{{2FF0:2808}}  (+&08)
        ld      a,(ix+$03)        ;{{2FF2:dd7e03}} 
        or      a                 ;{{2FF5:b7}} 
_real_to_int_16:                  ;{{Addr=$2ff6 Code Calls/jump count: 1 Data use count: 0}}
        ccf                       ;{{2FF6:3f}} 
        pop     bc                ;{{2FF7:c1}} 
        pop     de                ;{{2FF8:d1}} 
        ret                       ;{{2FF9:c9}} 

_real_to_int_20:                  ;{{Addr=$2ffa Code Calls/jump count: 1 Data use count: 0}}
        sbc     a,a               ;{{2FFA:9f}} 
        jr      _real_to_int_16   ;{{2FFB:18f9}}  (-&07)
_real_to_int_22:                  ;{{Addr=$2ffd Code Calls/jump count: 1 Data use count: 0}}
        ld      l,a               ;{{2FFD:6f}} 
        ld      h,a               ;{{2FFE:67}} 
        scf                       ;{{2FFF:37}} 
        ret                       ;{{3000:c9}} 

;;============================================================================================
;; REAL to bin
REAL_to_bin:                      ;{{Addr=$3001 Code Calls/jump count: 1 Data use count: 1}}
        call    REAL_fix          ;{{3001:cd1430}} 
        ret     nc                ;{{3004:d0}} 

        ret     p                 ;{{3005:f0}} 

_real_to_bin_3:                   ;{{Addr=$3006 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{3006:e5}} 
        ld      a,c               ;{{3007:79}} 
_real_to_bin_5:                   ;{{Addr=$3008 Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{3008:34}} 
        jr      nz,_real_to_bin_12;{{3009:2006}}  (+&06)
        inc     hl                ;{{300B:23}} 
        dec     a                 ;{{300C:3d}} 
        jr      nz,_real_to_bin_5 ;{{300D:20f9}}  (-&07)
        inc     (hl)              ;{{300F:34}} 
        inc     c                 ;{{3010:0c}} 
_real_to_bin_12:                  ;{{Addr=$3011 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{3011:e1}} 
        scf                       ;{{3012:37}} 
        ret                       ;{{3013:c9}} 

;;============================================================================================
;; REAL fix

REAL_fix:                         ;{{Addr=$3014 Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{3014:e5}} 
        push    de                ;{{3015:d5}} 
        push    hl                ;{{3016:e5}} 
        pop     ix                ;{{3017:dde1}} 
        xor     a                 ;{{3019:af}} 
        sub     (ix+$04)          ;{{301A:dd9604}} 
        jr      nz,_real_fix_13   ;{{301D:200a}}  (+&0a)
        ld      b,$04             ;{{301F:0604}} 
_real_fix_8:                      ;{{Addr=$3021 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{3021:77}} 
        inc     hl                ;{{3022:23}} 
        djnz    _real_fix_8       ;{{3023:10fc}}  (-&04)
        ld      c,$01             ;{{3025:0e01}} 
        jr      _real_fix_45      ;{{3027:1828}}  (+&28)

_real_fix_13:                     ;{{Addr=$3029 Code Calls/jump count: 1 Data use count: 0}}
        add     a,$a0             ;{{3029:c6a0}} 
        jr      nc,_real_fix_46   ;{{302B:3025}}  (+&25)
        push    hl                ;{{302D:e5}} 
        call    x373D_code        ;{{302E:cd3d37}} 
        xor     a                 ;{{3031:af}} 
        cp      b                 ;{{3032:b8}} 
        adc     a,a               ;{{3033:8f}} 
        or      c                 ;{{3034:b1}} 
        ld      c,l               ;{{3035:4d}} 
        ld      b,h               ;{{3036:44}} 
        pop     hl                ;{{3037:e1}} 
        ld      (hl),c            ;{{3038:71}} 
        inc     hl                ;{{3039:23}} 
        ld      (hl),b            ;{{303A:70}} 
        inc     hl                ;{{303B:23}} 
        ld      (hl),e            ;{{303C:73}} 
        inc     hl                ;{{303D:23}} 
        ld      e,a               ;{{303E:5f}} 
        ld      a,(hl)            ;{{303F:7e}} 
        ld      (hl),d            ;{{3040:72}} 
        and     $80               ;{{3041:e680}} 
        ld      b,a               ;{{3043:47}} 
        ld      c,$04             ;{{3044:0e04}} 
        xor     a                 ;{{3046:af}} 
_real_fix_37:                     ;{{Addr=$3047 Code Calls/jump count: 1 Data use count: 0}}
        or      (hl)              ;{{3047:b6}} 
        jr      nz,_real_fix_43   ;{{3048:2005}}  (+&05)
        dec     hl                ;{{304A:2b}} 
        dec     c                 ;{{304B:0d}} 
        jr      nz,_real_fix_37   ;{{304C:20f9}}  (-&07)
        inc     c                 ;{{304E:0c}} 
_real_fix_43:                     ;{{Addr=$304f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{304F:7b}} 
        or      a                 ;{{3050:b7}} 
_real_fix_45:                     ;{{Addr=$3051 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{3051:37}} 
_real_fix_46:                     ;{{Addr=$3052 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{3052:d1}} 
        pop     hl                ;{{3053:e1}} 
        ret                       ;{{3054:c9}} 

;;============================================================================================
;; REAL int

REAL_int:                         ;{{Addr=$3055 Code Calls/jump count: 0 Data use count: 1}}
        call    REAL_fix          ;{{3055:cd1430}} 
        ret     nc                ;{{3058:d0}} 

        ret     z                 ;{{3059:c8}} 

        bit     7,b               ;{{305A:cb78}} 
        ret     z                 ;{{305C:c8}} 

        jr      _real_to_bin_3    ;{{305D:18a7}}  (-&59)

;;================================================================
;; REAL prepare for decimal

REAL_prepare_for_decimal:         ;{{Addr=$305f Code Calls/jump count: 0 Data use count: 1}}
        call    REAL_SGN          ;{{305F:cd2737}} 
        ld      b,a               ;{{3062:47}} 
        jr      z,_real_prepare_for_decimal_55;{{3063:2852}}  (+&52)
        call    m,_real_negate_2  ;{{3065:fc3437}} 
        push    hl                ;{{3068:e5}} 
        ld      a,(ix+$04)        ;{{3069:dd7e04}} 
        sub     $80               ;{{306C:d680}} 
        ld      e,a               ;{{306E:5f}} 
        sbc     a,a               ;{{306F:9f}} 
        ld      d,a               ;{{3070:57}} 
        ld      l,e               ;{{3071:6b}} 
        ld      h,d               ;{{3072:62}} 
        add     hl,hl             ;{{3073:29}} 
        add     hl,hl             ;{{3074:29}} 
        add     hl,hl             ;{{3075:29}} 
        add     hl,de             ;{{3076:19}} 
        add     hl,hl             ;{{3077:29}} 
        add     hl,de             ;{{3078:19}} 
        add     hl,hl             ;{{3079:29}} 
        add     hl,hl             ;{{307A:29}} 
        add     hl,de             ;{{307B:19}} 
        ld      a,h               ;{{307C:7c}} 
        sub     $09               ;{{307D:d609}} 
        ld      c,a               ;{{307F:4f}} 
        pop     hl                ;{{3080:e1}} 
        push    bc                ;{{3081:c5}} 
        call    nz,_real_exp_a_2  ;{{3082:c4c830}} 
_real_prepare_for_decimal_27:     ;{{Addr=$3085 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,Jumpblock_BD76_constant_a;{{3085:11bc30}} 
        call    _real_compare_2   ;{{3088:cde236}} 
        jr      nc,_real_prepare_for_decimal_36;{{308B:300b}}  (+&0b)
        ld      de,powers_of_10_constants;{{308D:11f530}}  start of power's of ten
        call    REAL_multiplication;{{3090:cd7735}} 
        pop     de                ;{{3093:d1}} 
        dec     e                 ;{{3094:1d}} 
        push    de                ;{{3095:d5}} 
        jr      _real_prepare_for_decimal_27;{{3096:18ed}}  (-&13)
_real_prepare_for_decimal_36:     ;{{Addr=$3098 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,Jumpblock_BD76_constant_b;{{3098:11c130}} 
        call    _real_compare_2   ;{{309B:cde236}} 
        jr      c,_real_prepare_for_decimal_45;{{309E:380b}}  (+&0b)
        ld      de,powers_of_10_constants;{{30A0:11f530}}  start of power's of ten
        call    REAL_division     ;{{30A3:cd0436}} 
        pop     de                ;{{30A6:d1}} 
        inc     e                 ;{{30A7:1c}} 
        push    de                ;{{30A8:d5}} 
        jr      _real_prepare_for_decimal_36;{{30A9:18ed}}  (-&13)
_real_prepare_for_decimal_45:     ;{{Addr=$30ab Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_to_bin       ;{{30AB:cd0130}} 
        ld      a,c               ;{{30AE:79}} 
        pop     de                ;{{30AF:d1}} 
        ld      b,d               ;{{30B0:42}} 
        dec     a                 ;{{30B1:3d}} 
        add     a,l               ;{{30B2:85}} 
        ld      l,a               ;{{30B3:6f}} 
        ret     nc                ;{{30B4:d0}} 

        inc     h                 ;{{30B5:24}} 
        ret                       ;{{30B6:c9}} 

_real_prepare_for_decimal_55:     ;{{Addr=$30b7 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{30B7:5f}} 
        ld      (hl),a            ;{{30B8:77}} 
        ld      c,$01             ;{{30B9:0e01}} 
        ret                       ;{{30BB:c9}} 

;;=Jumpblock BD76 constant a
Jumpblock_BD76_constant_a:        ;{{Addr=$30bc Data Calls/jump count: 0 Data use count: 1}}
        defb $f0,$1f,$bc,$3e,$96  ;3124999.98
;;=Jumpblock BD76 constant b
Jumpblock_BD76_constant_b:        ;{{Addr=$30c1 Data Calls/jump count: 0 Data use count: 1}}
        defb $fe,$27,$6b,$6e,$9e  ;Manual fix (corrected to data from a ROM dump) 1e+09
;30c1 defb &fe,&27,&7b,&6e,&9e   ;(original line from disassembly listing) 1.00026e+09

;;============================================================================================
;; REAL exp A
REAL_exp_A:                       ;{{Addr=$30c6 Code Calls/jump count: 0 Data use count: 1}}
        cpl                       ;{{30C6:2f}} 
        inc     a                 ;{{30C7:3c}} 
_real_exp_a_2:                    ;{{Addr=$30c8 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{30C8:b7}} 
        scf                       ;{{30C9:37}} 
        ret     z                 ;{{30CA:c8}} 

        ld      c,a               ;{{30CB:4f}} 
        jp      p,_real_exp_a_9   ;{{30CC:f2d130}} 
        cpl                       ;{{30CF:2f}} 
        inc     a                 ;{{30D0:3c}} 
_real_exp_a_9:                    ;{{Addr=$30d1 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,_powers_of_10_constants_12;{{30D1:113131}} 
        sub     $0d               ;{{30D4:d60d}} 
        jr      z,_real_exp_a_28  ;{{30D6:2815}}  (+&15)
        jr      c,_real_exp_a_19  ;{{30D8:3809}}  (+&09)
        push    bc                ;{{30DA:c5}} 
        push    af                ;{{30DB:f5}} 
        call    _real_exp_a_28    ;{{30DC:cded30}} 
        pop     af                ;{{30DF:f1}} 
        pop     bc                ;{{30E0:c1}} 
        jr      _real_exp_a_9     ;{{30E1:18ee}}  (-&12)
_real_exp_a_19:                   ;{{Addr=$30e3 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{30E3:47}} 
        add     a,a               ;{{30E4:87}} 
        add     a,a               ;{{30E5:87}} 
        add     a,b               ;{{30E6:80}} 
        add     a,e               ;{{30E7:83}} 
        ld      e,a               ;{{30E8:5f}} 
        ld      a,$ff             ;{{30E9:3eff}} 
        adc     a,d               ;{{30EB:8a}} 
        ld      d,a               ;{{30EC:57}} 
_real_exp_a_28:                   ;{{Addr=$30ed Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{30ED:79}} 
        or      a                 ;{{30EE:b7}} 
        jp      p,REAL_division   ;{{30EF:f20436}} 
        jp      REAL_multiplication;{{30F2:c37735}} 

;;===========================================================================================
;; power's of 10 constants
;; in internal floating point representation
;;
powers_of_10_constants:           ;{{Addr=$30f5 Data Calls/jump count: 0 Data use count: 2}}
        defb $00,$00,$00,$20,$84  ; 10 (10^1)  (Data corrected to match that from a ROM dump) 10
;30f5 defb &00,&00,&00,&00,&84			;; 10 (10^1)  (Original line from disassembly) 8
        defb $00,$00,$00,$48,$87  ; 100 (10^2) 100
        defb $00,$00,$00,$7A,$8A  ; 1000 (10^3) 1000
        defb $00,$00,$40,$1c,$8e  ; 10000 (10^4) (1E+4) 10000
        defb $00,$00,$50,$43,$91  ; 100000 (10^5) (1E+5) 100000
        defb $00,$00,$24,$74,$94  ; 1000000 (10^6) (1E+6) 1000000
        defb $00,$80,$96,$18,$98  ; 10000000 (10^7) (1E+7) 10000000
        defb $00,$20,$bc,$3e,$9b  ; 100000000 (10^8) (1E+8) 100000000
        defb $00,$28,$6b,$6e,$9e  ; 1000000000 (10^9) (1E+9) 1e+09
        defb $00,$f9,$02,$15,$a2  ; 10000000000 (10^10) (1E+10) 1e+10
        defb $40,$b7,$43,$3a,$a5  ; 100000000000 (10^11) (1E+11) 1e+11
        defb $10,$a5,$d4,$68,$a8  ; 1000000000000 (10^12) (1E+12) 1e+12
_powers_of_10_constants_12:       ;{{Addr=$3131 Data Calls/jump count: 0 Data use count: 1}}
        defb $2a,$e7,$84,$11,$ac  ; 10000000000000 (10^13) (1E+13) 1e+13

;;===========================================================================================
;; REAL init random number generator
;;Called (only) at start of BASIC ROM and at start of RANDOMIZE seed (below). 
;;The data locations appear to store the last random number generated.
;;Possibly initialise/reset of random number generator?
REAL_init_random_number_generator:;{{Addr=$3136 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,$8965          ;{{3136:216589}} 
        ld      (last_random_number),hl;{{3139:2202b1}} 
        ld      hl,$6c07          ;{{313C:21076c}} 
        ld      (C6_last_random_number),hl;{{313F:2200b1}} 
        ret                       ;{{3142:c9}} 

;;============================================================================================
;; REAL: RANDOMIZE seed
REAL_RANDOMIZE_seed:              ;{{Addr=$3143 Code Calls/jump count: 0 Data use count: 1}}
        ex      de,hl             ;{{3143:eb}} 
        call    REAL_init_random_number_generator;{{3144:cd3631}} 
        ex      de,hl             ;{{3147:eb}} 
        call    REAL_SGN          ;{{3148:cd2737}} 
        ret     z                 ;{{314B:c8}} 

        ld      de,C6_last_random_number;{{314C:1100b1}} 
        ld      b,$04             ;{{314F:0604}} 
_real_randomize_seed_7:           ;{{Addr=$3151 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{3151:1a}} 
        xor     (hl)              ;{{3152:ae}} 
        ld      (de),a            ;{{3153:12}} 
        inc     de                ;{{3154:13}} 
        inc     hl                ;{{3155:23}} 
        djnz    _real_randomize_seed_7;{{3156:10f9}}  (-&07)
        ret                       ;{{3158:c9}} 

;;============================================================================================
;; REAL rnd
REAL_rnd:                         ;{{Addr=$3159 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{3159:e5}} 
        ld      hl,(last_random_number);{{315A:2a02b1}} 
        ld      bc,$6c07          ;{{315D:01076c}} 
        call    _real_rnd0_7      ;{{3160:cd9c31}} 
        push    hl                ;{{3163:e5}} 
        ld      hl,(C6_last_random_number);{{3164:2a00b1}} 
        ld      bc,$8965          ;{{3167:016589}} 
        call    _real_rnd0_7      ;{{316A:cd9c31}} 
        push    de                ;{{316D:d5}} 
        push    hl                ;{{316E:e5}} 
        ld      hl,(last_random_number);{{316F:2a02b1}} 
        call    _real_rnd0_7      ;{{3172:cd9c31}} 
        ex      (sp),hl           ;{{3175:e3}} 
        add     hl,bc             ;{{3176:09}} 
        ld      (C6_last_random_number),hl;{{3177:2200b1}} 
        pop     hl                ;{{317A:e1}} 
        ld      bc,$6c07          ;{{317B:01076c}} 
        adc     hl,bc             ;{{317E:ed4a}} 
        pop     bc                ;{{3180:c1}} 
        add     hl,bc             ;{{3181:09}} 
        pop     bc                ;{{3182:c1}} 
        add     hl,bc             ;{{3183:09}} 
        ld      (last_random_number),hl;{{3184:2202b1}} 
        pop     hl                ;{{3187:e1}} 

;;============================================================================================
;; REAL rnd0
REAL_rnd0:                        ;{{Addr=$3188 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{3188:e5}} 
        pop     ix                ;{{3189:dde1}} 
        ld      hl,(C6_last_random_number);{{318B:2a00b1}} 
        ld      de,(last_random_number);{{318E:ed5b02b1}} 
        ld      bc,$0000          ;{{3192:010000}} ##LIT##;WARNING: Code area used as literal
        ld      (ix+$04),$80      ;{{3195:dd360480}} 
        jp      _process_real_at_hl_13;{{3199:c3ac37}} 

_real_rnd0_7:                     ;{{Addr=$319c Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{319C:eb}} 
        ld      hl,$0000          ;{{319D:210000}} ##LIT##;WARNING: Code area used as literal
        ld      a,$11             ;{{31A0:3e11}} 
_real_rnd0_10:                    ;{{Addr=$31a2 Code Calls/jump count: 3 Data use count: 0}}
        dec     a                 ;{{31A2:3d}} 
        ret     z                 ;{{31A3:c8}} 

        add     hl,hl             ;{{31A4:29}} 
        rl      e                 ;{{31A5:cb13}} 
        rl      d                 ;{{31A7:cb12}} 
        jr      nc,_real_rnd0_10  ;{{31A9:30f7}}  (-&09)
        add     hl,bc             ;{{31AB:09}} 
        jr      nc,_real_rnd0_10  ;{{31AC:30f4}}  (-&0c)
        inc     de                ;{{31AE:13}} 
        jr      _real_rnd0_10     ;{{31AF:18f1}}  (-&0f)

;;============================================================================================
;; REAL log10
REAL_log10:                       ;{{Addr=$31b1 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,const_0301029996;{{31B1:112a32}} 
        jr      _real_log_1       ;{{31B4:1803}}  (+&03)

;;============================================================================================
;; REAL log
REAL_log:                         ;{{Addr=$31b6 Code Calls/jump count: 1 Data use count: 1}}
        ld      de,const_0693147181;{{31B6:112532}} 
_real_log_1:                      ;{{Addr=$31b9 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_SGN          ;{{31B9:cd2737}} 
        dec     a                 ;{{31BC:3d}} 
        cp      $01               ;{{31BD:fe01}} 
        ret     nc                ;{{31BF:d0}} 

        push    de                ;{{31C0:d5}} 
        call    _real_division_121;{{31C1:cdd336}} 
        push    af                ;{{31C4:f5}} 
        ld      (ix+$04),$80      ;{{31C5:dd360480}} 
        ld      de,const_0707106781;{{31C9:112032}} 
        call    REAL_compare      ;{{31CC:cddf36}} 
        jr      nc,_real_log_16   ;{{31CF:3006}}  (+&06)
        inc     (ix+$04)          ;{{31D1:dd3404}} 
        pop     af                ;{{31D4:f1}} 
        dec     a                 ;{{31D5:3d}} 
        push    af                ;{{31D6:f5}} 
_real_log_16:                     ;{{Addr=$31d7 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_copy_atHL_to_b10e_swapped;{{31D7:cd872f}} 
        push    de                ;{{31DA:d5}} 
        ld      de,ONE_const      ;{{31DB:11822f}} 
        push    de                ;{{31DE:d5}} 
        call    REAL_addition     ;{{31DF:cda234}} 
        pop     de                ;{{31E2:d1}} 
        ex      (sp),hl           ;{{31E3:e3}} 
        call    x349A_code        ;{{31E4:cd9a34}} 
        pop     de                ;{{31E7:d1}} 
        call    REAL_division     ;{{31E8:cd0436}} 
        call    process_inline_parameters;{{31EB:cd4034}} Code takes inline parameter block

;Inline parameter block
        defb $04                  ;Parameter count
        defb $4c,$4b,$57,$5e,$7f  ; 0.434259751
        defb $0d,$08,$9b,$13,$80  ; 0.576584342
        defb $23,$93,$38,$76,$80  ; 0.961800762
        defb $20,$3b,$aa,$38,$82  ; 2.88539007

;Return address
        push    de                ;{{3203:d5}} 
        call    REAL_multiplication;{{3204:cd7735}} 
        pop     de                ;{{3207:d1}} 
        ex      (sp),hl           ;{{3208:e3}} 
        ld      a,h               ;{{3209:7c}} 
        or      a                 ;{{320A:b7}} 
        jp      p,_real_log_41    ;{{320B:f21032}} 
        cpl                       ;{{320E:2f}} 
        inc     a                 ;{{320F:3c}} 
_real_log_41:                     ;{{Addr=$3210 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,a               ;{{3210:6f}} 
        ld      a,h               ;{{3211:7c}} 
        ld      h,$00             ;{{3212:2600}} 
        call    REAL_INT_to_real  ;{{3214:cd9f2f}} 
        ex      de,hl             ;{{3217:eb}} 
        pop     hl                ;{{3218:e1}} 
        call    REAL_addition     ;{{3219:cda234}} 
        pop     de                ;{{321C:d1}} 
        jp      REAL_multiplication;{{321D:c37735}} 

;;= const 0_707106781
const_0707106781:                 ;{{Addr=$3220 Data Calls/jump count: 0 Data use count: 1}}
        defb $34,$f3,$04,$35,$80  ; 0.707106781
;;= const 0_693147181
const_0693147181:                 ;{{Addr=$3225 Data Calls/jump count: 0 Data use count: 1}}
        defb $f8,$17,$72,$31,$80  ; 0.693147181
;;= const 0_301029996
const_0301029996:                 ;{{Addr=$322a Data Calls/jump count: 0 Data use count: 1}}
        defb $85,$9a,$20,$1a,$7f  ; 0.301029996

;;============================================================================================
;; REAL exp
REAL_exp:                         ;{{Addr=$322f Code Calls/jump count: 1 Data use count: 1}}
        ld      b,$e1             ;{{322F:06e1}} 
        call    x3492_code        ;{{3231:cd9234}} 
        jp      nc,REAL_ONE_to_DE ;{{3234:d27d2f}} 
        ld      de,exp_constant_c ;{{3237:11a232}} 
        call    REAL_compare      ;{{323A:cddf36}} 
        jp      p,REAL_at_IX_to_max_pos;{{323D:f2e837}} 
        ld      de,exp_constant_d ;{{3240:11a732}} 
        call    REAL_compare      ;{{3243:cddf36}} 
        jp      m,_process_real_at_hl_42;{{3246:fae237}} 
        ld      de,exp_constant_b ;{{3249:119d32}} 
        call    x3469_code        ;{{324C:cd6934}} 
        ld      a,e               ;{{324F:7b}} 
        jp      p,_real_exp_14    ;{{3250:f25532}} 
        neg                       ;{{3253:ed44}} 
_real_exp_14:                     ;{{Addr=$3255 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{3255:f5}} 
        call    _real_addition_119;{{3256:cd7035}} 
        call    _real_move_de_to_b10e_2;{{3259:cd8d2f}} 
        push    de                ;{{325C:d5}} 
        call    _process_inline_parameters_1;{{325D:cd4334}} Code takes inline parameter block

;Inline parameter block
        defb $03                  ;Parameter count
        defb $f4,$32,$eb,$0f,$73  ; 6.86258e-05
        defb $08,$b8,$d5,$52,$7b  ; 2.57367e-02
;;= exp constant a
exp_constant_a:                   ;{{Addr=$326b Data Calls/jump count: 0 Data use count: 3}}
        defb $00,$00,$00,$00,$80  ; 0.5

;Return address
        ex      (sp),hl           ;{{3270:e3}} 
        call    _process_inline_parameters_1;{{3271:cd4334}} Code takes inline parameter block

;Inline parameter block
        defb $02                  ;parameter count
        defb $09,$60,$de,$01,$78  ; 1.98164e-03
        defb $f8,$17,$72,$31,$7e  ; 0.173286795

;Return address
        call    REAL_multiplication;{{32FF:cd7735}} 
        pop     de                ;{{3282:d1}} 
        push    hl                ;{{3283:e5}} 
        ex      de,hl             ;{{3284:eb}} 
        call    x349A_code        ;{{3285:cd9a34}} 
        ex      de,hl             ;{{3288:eb}} 
        pop     hl                ;{{3289:e1}} 
        call    REAL_division     ;{{328A:cd0436}} 
        ld      de,exp_constant_a ;{{328D:116b32}} 
        call    REAL_addition     ;{{3290:cda234}} 
        pop     af                ;{{3293:f1}} 
        scf                       ;{{3294:37}} 
        adc     a,(ix+$04)        ;{{3295:dd8e04}} 
        ld      (ix+$04),a        ;{{3298:dd7704}} 
        scf                       ;{{329B:37}} 
        ret                       ;{{329C:c9}} 

;;= exp constant b
exp_constant_b:                   ;{{Addr=$329d Data Calls/jump count: 0 Data use count: 1}}
        defb $29,$3b,$aa,$38,$81  ;   1.44269504
;;= exp constant c
exp_constant_c:                   ;{{Addr=$32a2 Data Calls/jump count: 0 Data use count: 1}}
        defb $c7,$33,$0f,$30,$87  ;  88.0296919
;;= exp constant d
exp_constant_d:                   ;{{Addr=$32a7 Data Calls/jump count: 0 Data use count: 1}}
        defb $f8,$17,$72,$b1,$87  ; -88.7228391

;;============================================================================================
;; REAL sqr
REAL_sqr:                         ;{{Addr=$32ac Code Calls/jump count: 0 Data use count: 1}}
        ld      de,exp_constant_a ;{{32AC:116b32}} 

;;============================================================================================
;; REAL power
REAL_power:                       ;{{Addr=$32af Code Calls/jump count: 0 Data use count: 1}}
        ex      de,hl             ;{{32AF:eb}} 
        call    REAL_SGN          ;{{32B0:cd2737}} 
        ex      de,hl             ;{{32B3:eb}} 
        jp      z,REAL_ONE_to_DE  ;{{32B4:ca7d2f}} 
        push    af                ;{{32B7:f5}} 
        call    REAL_SGN          ;{{32B8:cd2737}} 
        jr      z,_real_power_29  ;{{32BB:2825}}  (+&25)
        ld      b,a               ;{{32BD:47}} 
        call    m,_real_negate_2  ;{{32BE:fc3437}} 
        push    hl                ;{{32C1:e5}} 
        call    _real_power_72    ;{{32C2:cd2433}} 
        pop     hl                ;{{32C5:e1}} 
        jr      c,_real_power_38  ;{{32C6:3825}}  (+&25)
        ex      (sp),hl           ;{{32C8:e3}} 
        pop     hl                ;{{32C9:e1}} 
        jp      m,_real_power_35  ;{{32CA:faea32}} 
        push    bc                ;{{32CD:c5}} 
        push    de                ;{{32CE:d5}} 
        call    REAL_log          ;{{32CF:cdb631}} 
        pop     de                ;{{32D2:d1}} 
        call    c,REAL_multiplication;{{32D3:dc7735}} 
        call    c,REAL_exp        ;{{32D6:dc2f32}} 
_real_power_22:                   ;{{Addr=$32d9 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{32D9:c1}} 
        ret     nc                ;{{32DA:d0}} 

        ld      a,b               ;{{32DB:78}} 
        or      a                 ;{{32DC:b7}} 
        call    m,REAL_Negate     ;{{32DD:fc3137}} 
        scf                       ;{{32E0:37}} 
        ret                       ;{{32E1:c9}} 

_real_power_29:                   ;{{Addr=$32e2 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{32E2:f1}} 
        scf                       ;{{32E3:37}} 
        ret     p                 ;{{32E4:f0}} 

        call    REAL_at_IX_to_max_pos;{{32E5:cde837}} 
        xor     a                 ;{{32E8:af}} 
        ret                       ;{{32E9:c9}} 

_real_power_35:                   ;{{Addr=$32ea Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{32EA:af}} 
        inc     a                 ;{{32EB:3c}} 
        ret                       ;{{32EC:c9}} 

_real_power_38:                   ;{{Addr=$32ed Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{32ED:4f}} 
        pop     af                ;{{32EE:f1}} 
        push    bc                ;{{32EF:c5}} 
        push    af                ;{{32F0:f5}} 
        ld      a,c               ;{{32F1:79}} 
        scf                       ;{{32F2:37}} 
_real_power_44:                   ;{{Addr=$32f3 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{32F3:8f}} 
        jr      nc,_real_power_44 ;{{32F4:30fd}}  (-&03)
        ld      b,a               ;{{32F6:47}} 
        call    _real_move_de_to_b10e_2;{{32F7:cd8d2f}} 
        ex      de,hl             ;{{32FA:eb}} 
        ld      a,b               ;{{32FB:78}} 
_real_power_50:                   ;{{Addr=$32fc Code Calls/jump count: 2 Data use count: 0}}
        add     a,a               ;{{32FC:87}} 
        jr      z,_real_power_63  ;{{32FD:2815}}  (+&15)
        push    af                ;{{32FF:f5}} 
        call    _real_addition_119;{{3300:cd7035}} 
        jr      nc,_real_power_67 ;{{3303:3016}}  (+&16)
        pop     af                ;{{3305:f1}} 
        jr      nc,_real_power_50 ;{{3306:30f4}}  (-&0c)
        push    af                ;{{3308:f5}} 
        ld      de,internal_REAL_store_1;{{3309:1104b1}} 
        call    REAL_multiplication;{{330C:cd7735}} 
        jr      nc,_real_power_67 ;{{330F:300a}}  (+&0a)
        pop     af                ;{{3311:f1}} 
        jr      _real_power_50    ;{{3312:18e8}}  (-&18)

_real_power_63:                   ;{{Addr=$3314 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{3314:f1}} 
        scf                       ;{{3315:37}} 
        call    m,_real_multiplication_72;{{3316:fcfb35}} 
        jr      _real_power_22    ;{{3319:18be}}  (-&42)

_real_power_67:                   ;{{Addr=$331b Code Calls/jump count: 2 Data use count: 0}}
        pop     af                ;{{331B:f1}} 
        pop     af                ;{{331C:f1}} 
        pop     bc                ;{{331D:c1}} 
        jp      m,_process_real_at_hl_42;{{331E:fae237}} 
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3321:c3ea37}} 

_real_power_72:                   ;{{Addr=$3324 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{3324:c5}} 
        call    REAL_move_DE_to_b10e;{{3325:cd882f}} 
        call    REAL_fix          ;{{3328:cd1430}} 
        ld      a,c               ;{{332B:79}} 
        pop     bc                ;{{332C:c1}} 
        jr      nc,_real_power_79 ;{{332D:3002}}  (+&02)
        jr      z,_real_power_82  ;{{332F:2803}}  (+&03)
_real_power_79:                   ;{{Addr=$3331 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{3331:78}} 
        or      a                 ;{{3332:b7}} 
        ret                       ;{{3333:c9}} 

_real_power_82:                   ;{{Addr=$3334 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{3334:4f}} 
        ld      a,(hl)            ;{{3335:7e}} 
        rra                       ;{{3336:1f}} 
        sbc     a,a               ;{{3337:9f}} 
        and     b                 ;{{3338:a0}} 
        ld      b,a               ;{{3339:47}} 
        ld      a,c               ;{{333A:79}} 
        cp      $02               ;{{333B:fe02}} 
        sbc     a,a               ;{{333D:9f}} 
        ret     nc                ;{{333E:d0}} 

        ld      a,(hl)            ;{{333F:7e}} 
        cp      $27               ;{{3340:fe27}} 
        ret     c                 ;{{3342:d8}} 

        xor     a                 ;{{3343:af}} 
        ret                       ;{{3344:c9}} 

;;============================================================================================
;; REAL set degrees or radians
REAL_set_degrees_or_radians:      ;{{Addr=$3345 Code Calls/jump count: 0 Data use count: 1}}
        ld      (DEG__RAD_flag_),a;{{3345:3213b1}} 
        ret                       ;{{3348:c9}} 

;;============================================================================================
;; REAL cosine
REAL_cosine:                      ;{{Addr=$3349 Code Calls/jump count: 1 Data use count: 1}}
        call    REAL_SGN          ;{{3349:cd2737}} 
        call    m,_real_negate_2  ;{{334C:fc3437}} 
        or      $01               ;{{334F:f601}} 
        jr      _real_sin_1       ;{{3351:1801}}  (+&01)

;;============================================================================================
;; REAL sin
REAL_sin:                         ;{{Addr=$3353 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{3353:af}} 
_real_sin_1:                      ;{{Addr=$3354 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{3354:f5}} 
        ld      de,sin_constant_b ;{{3355:11b433}} 
        ld      b,$f0             ;{{3358:06f0}} 
        ld      a,(DEG__RAD_flag_);{{335A:3a13b1}} 
        or      a                 ;{{335D:b7}} 
        jr      z,_real_sin_9     ;{{335E:2805}}  (+&05)
        ld      de,sin_constant_c ;{{3360:11b933}} 
        ld      b,$f6             ;{{3363:06f6}} 
_real_sin_9:                      ;{{Addr=$3365 Code Calls/jump count: 1 Data use count: 0}}
        call    x3492_code        ;{{3365:cd9234}} 
        jr      nc,_sin_code_block_2_1;{{3368:303a}}  (+&3a)
        pop     af                ;{{336A:f1}} 
        call    x346A_code        ;{{336B:cd6a34}} 
        ret     nc                ;{{336E:d0}} 

        ld      a,e               ;{{336F:7b}} 
        rra                       ;{{3370:1f}} 
        call    c,_real_negate_2  ;{{3371:dc3437}} 
        ld      b,$e8             ;{{3374:06e8}} 
        call    x3492_code        ;{{3376:cd9234}} 
        jp      nc,_process_real_at_hl_42;{{3379:d2e237}} 
        inc     (ix+$04)          ;{{337C:dd3404}} 
        call    process_inline_parameters;{{337F:cd4034}} Code pops parameter block address from stack

;Inline parameter block
        defb $06                  ;Parameter count (6)
        defb $1b,$2d,$1a,$e6,$6e  ; -3.42879e-06
        defb $f8,$fb,$07,$28,$74  ;  1.60247e-04
        defb $01,$89,$68,$99,$79  ; -4.68165e-03
        defb $e1,$df,$35,$23,$7d  ;  7.96926e-02
        defb $28,$e7,$5d,$a5,$80  ; -0.645964095
;;=sin constant a
sin_constant_a:                   ;{{Addr=$339c Data Calls/jump count: 0 Data use count: 1}}
        defb $a2,$da,$0f,$49,$81  ;  1.57079633

;;=Sin code block 2
;Code returns here
        jp      REAL_multiplication;{{33A1:c37735}} 

_sin_code_block_2_1:              ;{{Addr=$33a4 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{33A4:f1}} 
        jp      nz,REAL_ONE_to_DE ;{{33A5:c27d2f}} 
        ld      a,(DEG__RAD_flag_);{{33A8:3a13b1}} 
        cp      $01               ;{{33AB:fe01}} 
        ret     c                 ;{{33AD:d8}} 

        ld      de,sin_constant_d ;{{33AE:11be33}} 
        jp      REAL_multiplication;{{33B1:c37735}} 

;;=sin constant b
sin_constant_b:                   ;{{Addr=$33b4 Data Calls/jump count: 0 Data use count: 1}}
        defb $6e,$83,$f9,$22,$7f  ;  0.318309886
;;=sin constant c
sin_constant_c:                   ;{{Addr=$33b9 Data Calls/jump count: 0 Data use count: 1}}
        defb $b6,$60,$0b,$36,$79  ;  5.55556e-03
;;=sin constant d
sin_constant_d:                   ;{{Addr=$33be Data Calls/jump count: 0 Data use count: 1}}
        defb $13,$35,$fa,$0e,$7b  ;  1.74533e-02
;;=sin constant e
sin_constant_e:                   ;{{Addr=$33c3 Data Calls/jump count: 0 Data use count: 1}}
        defb $d3,$e0,$2e,$65,$86  ; 57.2957795

;;============================================================================================
;; REAL tan
REAL_tan:                         ;{{Addr=$33c8 Code Calls/jump count: 0 Data use count: 1}}
        call    _real_move_de_to_b10e_2;{{33C8:cd8d2f}} 
        push    de                ;{{33CB:d5}} 
        call    REAL_cosine       ;{{33CC:cd4933}} 
        ex      (sp),hl           ;{{33CF:e3}} 
        call    c,REAL_sin        ;{{33D0:dc5333}} 
        pop     de                ;{{33D3:d1}} 
        jp      c,REAL_division   ;{{33D4:da0436}} 
        ret                       ;{{33D7:c9}} 

;;============================================================================================
;; REAL arctan
REAL_arctan:                      ;{{Addr=$33d8 Code Calls/jump count: 0 Data use count: 1}}
        call    REAL_SGN          ;{{33D8:cd2737}} 
        push    af                ;{{33DB:f5}} 
        call    m,_real_negate_2  ;{{33DC:fc3437}} 
        ld      b,$f0             ;{{33DF:06f0}} 
        call    x3492_code        ;{{33E1:cd9234}} 
        jr      nc,_real_arctan_26;{{33E4:304a}}  (+&4a)
        dec     a                 ;{{33E6:3d}} 
        push    af                ;{{33E7:f5}} 
        call    p,_real_multiplication_72;{{33E8:f4fb35}} 
        call    process_inline_parameters;{{33EB:cd4034}} Code which takes an inline parameter block

;Inline paremeter blcok, address retrieved from the call stack
        defb $0b                  ;Parameter count (11)
        defb $ff,$c1,$03,$0f,$77  ;  1.09112e-03
        defb $83,$fc,$e8,$eb,$79  ; -0.007199405 
        defb $6f,$ca,$78,$36,$7b  ;  2.22744e-02
        defb $d5,$3e,$b0,$b5,$7c  ; -4.43575e-02
        defb $b0,$c1,$8b,$09,$7d  ;  6.71611e-02
        defb $af,$e8,$32,$b4,$7d  ; -8.79877e-02
        defb $74,$6c,$65,$62,$7d  ;  0.110545013
        defb $d1,$f5,$37,$92,$7e  ; -0.142791596
        defb $7a,$c3,$cb,$4c,$7e  ;  0.199996046
        defb $83,$a7,$aa,$aa,$7f  ; -0.333333239
        defb $fe,$ff,$ff,$7f,$80  ;  1

        call    REAL_multiplication;{{3426:cd7735}} Return address after data block
        pop     af                ;{{3429:f1}} 
        ld      de,sin_constant_a ;{{342A:119c33}} 
        call    p,REAL_reverse_subtract;{{342D:f49e34}} 
_real_arctan_26:                  ;{{Addr=$3430 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(DEG__RAD_flag_);{{3430:3a13b1}} 
        or      a                 ;{{3433:b7}} 
        ld      de,sin_constant_e ;{{3434:11c333}} 
        call    nz,REAL_multiplication;{{3437:c47735}} 
        pop     af                ;{{343A:f1}} 
        call    m,_real_negate_2  ;{{343B:fc3437}} 
        scf                       ;{{343E:37}} 
        ret                       ;{{343F:c9}} 


;;=====================================================
;; process inline parameters
;This code takes a list of parameters starting at the next byte after the call.
;It pops the return value off the stack, reads in the values, and eventually returns 
;to the address after the data block.
;The first byte of the data block is the count of the number of parameters. Each 
;parameter is five bytes long (a real).

process_inline_parameters:        ;{{Addr=$3440 Code Calls/jump count: 3 Data use count: 0}}
        call    _real_addition_119;{{3440:cd7035}} 
_process_inline_parameters_1:     ;{{Addr=$3443 Code Calls/jump count: 2 Data use count: 0}}
        call    REAL_copy_atHL_to_b10e_swapped;{{3443:cd872f}} 
        pop     hl                ;{{3446:e1}} Pop the return address/address of data block
        ld      b,(hl)            ;{{3447:46}} Parameter count
        inc     hl                ;{{3448:23}} First parameter
        call    REAL_copy_atHL_to_atDE_swapped;{{3449:cd902f}} 
_process_inline_parameters_6:     ;{{Addr=$344c Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{344C:13}} Advance to next parameter
        inc     de                ;{{344D:13}} 
        inc     de                ;{{344E:13}} 
        inc     de                ;{{344F:13}} 
        inc     de                ;{{3450:13}} 
        push    de                ;{{3451:d5}} Possible return address
        ld      de,internal_REAL_store_2;{{3452:1109b1}} 
        dec     b                 ;{{3455:05}} 
        ret     z                 ;{{3456:c8}} 

        push    bc                ;{{3457:c5}} 
        ld      de,internal_REAL_store_3;{{3458:110eb1}} 
        call    REAL_multiplication;{{345B:cd7735}} 
        pop     bc                ;{{345E:c1}} 
        pop     de                ;{{345F:d1}} Get back address of next parameter
        push    de                ;{{3460:d5}} 
        push    bc                ;{{3461:c5}} 
        call    REAL_addition     ;{{3462:cda234}} 
        pop     bc                ;{{3465:c1}} 
        pop     de                ;{{3466:d1}} 
        jr      _process_inline_parameters_6;{{3467:18e3}}  (-&1d)

;;=======================================================

x3469_code:                       ;{{Addr=$3469 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{3469:af}} 
x346A_code:                       ;{{Addr=$346a Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{346A:f5}} 
        call    REAL_multiplication;{{346B:cd7735}} 
        pop     af                ;{{346E:f1}} 
        ld      de,exp_constant_a ;{{346F:116b32}} 
        call    nz,REAL_addition  ;{{3472:c4a234}} 
        push    hl                ;{{3475:e5}} 
        call    REAL_to_int       ;{{3476:cdd92f}} 
        jr      nc,x348E_code     ;{{3479:3013}}  (+&13)
        pop     de                ;{{347B:d1}} 
        push    hl                ;{{347C:e5}} 
        push    af                ;{{347D:f5}} 
        push    de                ;{{347E:d5}} 
        ld      de,internal_REAL_store_2;{{347F:1109b1}} 
        call    REAL_INT_to_real  ;{{3482:cd9f2f}} 
        ex      de,hl             ;{{3485:eb}} 
        pop     hl                ;{{3486:e1}} 
        call    x349A_code        ;{{3487:cd9a34}} 
        pop     af                ;{{348A:f1}} 
        pop     de                ;{{348B:d1}} 
        scf                       ;{{348C:37}} 
        ret                       ;{{348D:c9}} 

x348E_code:                       ;{{Addr=$348e Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{348E:e1}} 
        xor     a                 ;{{348F:af}} 
        inc     a                 ;{{3490:3c}} 
        ret                       ;{{3491:c9}} 

x3492_code:                       ;{{Addr=$3492 Code Calls/jump count: 4 Data use count: 0}}
        call    _real_division_121;{{3492:cdd336}} 
        ret     p                 ;{{3495:f0}} 

        cp      b                 ;{{3496:b8}} 
        ret     z                 ;{{3497:c8}} 

        ccf                       ;{{3498:3f}} 
        ret                       ;{{3499:c9}} 

x349A_code:                       ;{{Addr=$349a Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$01             ;{{349A:3e01}} 
        jr      _real_addition_1  ;{{349C:1805}}  (+&05)

;;============================================================================================
;; REAL reverse subtract
REAL_reverse_subtract:            ;{{Addr=$349e Code Calls/jump count: 1 Data use count: 1}}
        ld      a,$80             ;{{349E:3e80}} 
        jr      _real_addition_1  ;{{34A0:1801}}  (+&01)

;;============================================================================================
;; REAL addition
REAL_addition:                    ;{{Addr=$34a2 Code Calls/jump count: 5 Data use count: 1}}
        xor     a                 ;{{34A2:af}} 

; A = function, &00, &01 or &80
_real_addition_1:                 ;{{Addr=$34a3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{34A3:e5}} 
        pop     ix                ;{{34A4:dde1}} 
        push    de                ;{{34A6:d5}} 
        pop     iy                ;{{34A7:fde1}} 
        ld      b,(ix+$03)        ;{{34A9:dd4603}} 
        ld      c,(iy+$03)        ;{{34AC:fd4e03}} 
        or      a                 ;{{34AF:b7}} 
        jr      z,_real_addition_16;{{34B0:280a}}  (+&0a)
        jp      m,_real_addition_14;{{34B2:faba34}} 
        rrca                      ;{{34B5:0f}} 
        xor     c                 ;{{34B6:a9}} 
        ld      c,a               ;{{34B7:4f}} 
        jr      _real_addition_16 ;{{34B8:1802}}  (+&02)

_real_addition_14:                ;{{Addr=$34ba Code Calls/jump count: 1 Data use count: 0}}
        xor     b                 ;{{34BA:a8}} 
        ld      b,a               ;{{34BB:47}} 
_real_addition_16:                ;{{Addr=$34bc Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$04)        ;{{34BC:dd7e04}} 
        cp      (iy+$04)          ;{{34BF:fdbe04}} 
        jr      nc,_real_addition_31;{{34C2:3014}}  (+&14)
        ld      d,b               ;{{34C4:50}} 
        ld      b,c               ;{{34C5:41}} 
        ld      c,d               ;{{34C6:4a}} 
        or      a                 ;{{34C7:b7}} 
        ld      d,a               ;{{34C8:57}} 
        ld      a,(iy+$04)        ;{{34C9:fd7e04}} 
        ld      (ix+$04),a        ;{{34CC:dd7704}} 
        jr      z,_real_addition_74;{{34CF:2854}}  (+&54)
        sub     d                 ;{{34D1:92}} 
        cp      $21               ;{{34D2:fe21}} 
        jr      nc,_real_addition_74;{{34D4:304f}}  (+&4f)
        jr      _real_addition_40 ;{{34D6:1811}}  (+&11)

_real_addition_31:                ;{{Addr=$34d8 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{34D8:af}} 
        sub     (iy+$04)          ;{{34D9:fd9604}} 
        jr      z,_real_addition_80;{{34DC:2859}}  (+&59)
        add     a,(ix+$04)        ;{{34DE:dd8604}} 
        cp      $21               ;{{34E1:fe21}} 
        jr      nc,_real_addition_80;{{34E3:3052}}  (+&52)
        push    hl                ;{{34E5:e5}} 
        pop     iy                ;{{34E6:fde1}} 
        ex      de,hl             ;{{34E8:eb}} 
_real_addition_40:                ;{{Addr=$34e9 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{34E9:5f}} 
        ld      a,b               ;{{34EA:78}} 
        xor     c                 ;{{34EB:a9}} 
        push    af                ;{{34EC:f5}} 
        push    bc                ;{{34ED:c5}} 
        ld      a,e               ;{{34EE:7b}} 
        call    x3743_code        ;{{34EF:cd4337}} 
        ld      a,c               ;{{34F2:79}} 
        pop     bc                ;{{34F3:c1}} 
        ld      c,a               ;{{34F4:4f}} 
        pop     af                ;{{34F5:f1}} 
        jp      m,_real_addition_83;{{34F6:fa3c35}} 
        ld      a,(iy+$00)        ;{{34F9:fd7e00}} 
        add     a,l               ;{{34FC:85}} 
        ld      l,a               ;{{34FD:6f}} 
        ld      a,(iy+$01)        ;{{34FE:fd7e01}} 
        adc     a,h               ;{{3501:8c}} 
        ld      h,a               ;{{3502:67}} 
        ld      a,(iy+$02)        ;{{3503:fd7e02}} 
        adc     a,e               ;{{3506:8b}} 
        ld      e,a               ;{{3507:5f}} 
        ld      a,(iy+$03)        ;{{3508:fd7e03}} 
        set     7,a               ;{{350B:cbff}} 
        adc     a,d               ;{{350D:8a}} 
        ld      d,a               ;{{350E:57}} 
        jp      nc,_process_real_at_hl_18;{{350F:d2b737}} 
        rr      d                 ;{{3512:cb1a}} 
        rr      e                 ;{{3514:cb1b}} 
        rr      h                 ;{{3516:cb1c}} 
        rr      l                 ;{{3518:cb1d}} 
        rr      c                 ;{{351A:cb19}} 
        inc     (ix+$04)          ;{{351C:dd3404}} 
        jp      nz,_process_real_at_hl_18;{{351F:c2b737}} 
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3522:c3ea37}} 

_real_addition_74:                ;{{Addr=$3525 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(iy+$02)        ;{{3525:fd7e02}} 
        ld      (ix+$02),a        ;{{3528:dd7702}} 
        ld      a,(iy+$01)        ;{{352B:fd7e01}} 
        ld      (ix+$01),a        ;{{352E:dd7701}} 
        ld      a,(iy+$00)        ;{{3531:fd7e00}} 
        ld      (ix+$00),a        ;{{3534:dd7700}} 
_real_addition_80:                ;{{Addr=$3537 Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$03),b        ;{{3537:dd7003}} 
        scf                       ;{{353A:37}} 
        ret                       ;{{353B:c9}} 

_real_addition_83:                ;{{Addr=$353c Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{353C:af}} 
        sub     c                 ;{{353D:91}} 
        ld      c,a               ;{{353E:4f}} 
        ld      a,(iy+$00)        ;{{353F:fd7e00}} 
        sbc     a,l               ;{{3542:9d}} 
        ld      l,a               ;{{3543:6f}} 
        ld      a,(iy+$01)        ;{{3544:fd7e01}} 
        sbc     a,h               ;{{3547:9c}} 
        ld      h,a               ;{{3548:67}} 
        ld      a,(iy+$02)        ;{{3549:fd7e02}} 
        sbc     a,e               ;{{354C:9b}} 
        ld      e,a               ;{{354D:5f}} 
        ld      a,(iy+$03)        ;{{354E:fd7e03}} 
        set     7,a               ;{{3551:cbff}} 
        sbc     a,d               ;{{3553:9a}} 
        ld      d,a               ;{{3554:57}} 
        jr      nc,_real_addition_118;{{3555:3016}}  (+&16)
        ld      a,b               ;{{3557:78}} 
        cpl                       ;{{3558:2f}} 
        ld      b,a               ;{{3559:47}} 
        xor     a                 ;{{355A:af}} 
        sub     c                 ;{{355B:91}} 
        ld      c,a               ;{{355C:4f}} 
        ld      a,$00             ;{{355D:3e00}} 
        sbc     a,l               ;{{355F:9d}} 
        ld      l,a               ;{{3560:6f}} 
        ld      a,$00             ;{{3561:3e00}} 
        sbc     a,h               ;{{3563:9c}} 
        ld      h,a               ;{{3564:67}} 
        ld      a,$00             ;{{3565:3e00}} 
        sbc     a,e               ;{{3567:9b}} 
        ld      e,a               ;{{3568:5f}} 
        ld      a,$00             ;{{3569:3e00}} 
        sbc     a,d               ;{{356B:9a}} 
        ld      d,a               ;{{356C:57}} 
_real_addition_118:               ;{{Addr=$356d Code Calls/jump count: 1 Data use count: 0}}
        jp      _process_real_at_hl_13;{{356D:c3ac37}} 

_real_addition_119:               ;{{Addr=$3570 Code Calls/jump count: 3 Data use count: 0}}
        ld      de,internal_REAL_store_2;{{3570:1109b1}} 
        call    REAL_copy_atHL_to_atDE_swapped;{{3573:cd902f}} 
        ex      de,hl             ;{{3576:eb}} 

;;============================================================================================
;; REAL multiplication
REAL_multiplication:              ;{{Addr=$3577 Code Calls/jump count: 13 Data use count: 1}}
        push    de                ;{{3577:d5}} 
        pop     iy                ;{{3578:fde1}} 
        push    hl                ;{{357A:e5}} 
        pop     ix                ;{{357B:dde1}} 
        ld      a,(iy+$04)        ;{{357D:fd7e04}} 
        or      a                 ;{{3580:b7}} 
        jr      z,_real_multiplication_30;{{3581:282a}}  (+&2a)
        dec     a                 ;{{3583:3d}} 
        call    _real_division_98 ;{{3584:cdaf36}} 
        jr      z,_real_multiplication_30;{{3587:2824}}  (+&24)
        jr      nc,_real_multiplication_29;{{3589:301f}}  (+&1f)
        push    af                ;{{358B:f5}} 
        push    bc                ;{{358C:c5}} 
        call    _real_multiplication_31;{{358D:cdb035}} 
        ld      a,c               ;{{3590:79}} 
        pop     bc                ;{{3591:c1}} 
        ld      c,a               ;{{3592:4f}} 
        pop     af                ;{{3593:f1}} 
        bit     7,d               ;{{3594:cb7a}} 
        jr      nz,_real_multiplication_26;{{3596:200b}}  (+&0b)
        dec     a                 ;{{3598:3d}} 
        jr      z,_real_multiplication_30;{{3599:2812}}  (+&12)
        sla     c                 ;{{359B:cb21}} 
        adc     hl,hl             ;{{359D:ed6a}} 
        rl      e                 ;{{359F:cb13}} 
        rl      d                 ;{{35A1:cb12}} 
_real_multiplication_26:          ;{{Addr=$35a3 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$04),a        ;{{35A3:dd7704}} 
        or      a                 ;{{35A6:b7}} 
        jp      nz,_process_real_at_hl_18;{{35A7:c2b737}} 
_real_multiplication_29:          ;{{Addr=$35aa Code Calls/jump count: 1 Data use count: 0}}
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{35AA:c3ea37}} 

_real_multiplication_30:          ;{{Addr=$35ad Code Calls/jump count: 3 Data use count: 0}}
        jp      _process_real_at_hl_42;{{35AD:c3e237}} 

_real_multiplication_31:          ;{{Addr=$35b0 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,$0000          ;{{35B0:210000}} ##LIT##;WARNING: Code area used as literal
        ld      e,l               ;{{35B3:5d}} 
        ld      d,h               ;{{35B4:54}} 
        ld      a,(iy+$00)        ;{{35B5:fd7e00}} 
        call    _real_multiplication_65;{{35B8:cdf335}} 
        ld      a,(iy+$01)        ;{{35BB:fd7e01}} 
        call    _real_multiplication_65;{{35BE:cdf335}} 
        ld      a,(iy+$02)        ;{{35C1:fd7e02}} 
        call    _real_multiplication_65;{{35C4:cdf335}} 
        ld      a,(iy+$03)        ;{{35C7:fd7e03}} 
        or      $80               ;{{35CA:f680}} 
_real_multiplication_42:          ;{{Addr=$35cc Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$08             ;{{35CC:0608}} 
        rra                       ;{{35CE:1f}} 
        ld      c,a               ;{{35CF:4f}} 
_real_multiplication_45:          ;{{Addr=$35d0 Code Calls/jump count: 1 Data use count: 0}}
        jr      nc,_real_multiplication_58;{{35D0:3014}}  (+&14)
        ld      a,l               ;{{35D2:7d}} 
        add     a,(ix+$00)        ;{{35D3:dd8600}} 
        ld      l,a               ;{{35D6:6f}} 
        ld      a,h               ;{{35D7:7c}} 
        adc     a,(ix+$01)        ;{{35D8:dd8e01}} 
        ld      h,a               ;{{35DB:67}} 
        ld      a,e               ;{{35DC:7b}} 
        adc     a,(ix+$02)        ;{{35DD:dd8e02}} 
        ld      e,a               ;{{35E0:5f}} 
        ld      a,d               ;{{35E1:7a}} 
        adc     a,(ix+$03)        ;{{35E2:dd8e03}} 
        ld      d,a               ;{{35E5:57}} 
_real_multiplication_58:          ;{{Addr=$35e6 Code Calls/jump count: 1 Data use count: 0}}
        rr      d                 ;{{35E6:cb1a}} 
        rr      e                 ;{{35E8:cb1b}} 
        rr      h                 ;{{35EA:cb1c}} 
        rr      l                 ;{{35EC:cb1d}} 
        rr      c                 ;{{35EE:cb19}} 
        djnz    _real_multiplication_45;{{35F0:10de}}  (-&22)
        ret                       ;{{35F2:c9}} 

_real_multiplication_65:          ;{{Addr=$35f3 Code Calls/jump count: 3 Data use count: 0}}
        or      a                 ;{{35F3:b7}} 
        jr      nz,_real_multiplication_42;{{35F4:20d6}}  (-&2a)
        ld      l,h               ;{{35F6:6c}} 
        ld      h,e               ;{{35F7:63}} 
        ld      e,d               ;{{35F8:5a}} 
        ld      d,a               ;{{35F9:57}} 
        ret                       ;{{35FA:c9}} 

_real_multiplication_72:          ;{{Addr=$35fb Code Calls/jump count: 2 Data use count: 0}}
        call    REAL_copy_atHL_to_b10e_swapped;{{35FB:cd872f}} 
        ex      de,hl             ;{{35FE:eb}} 
        push    de                ;{{35FF:d5}} 
        call    REAL_ONE_to_DE    ;{{3600:cd7d2f}} 
        pop     de                ;{{3603:d1}} 

;;============================================================================================
;; REAL division
REAL_division:                    ;{{Addr=$3604 Code Calls/jump count: 5 Data use count: 1}}
        push    de                ;{{3604:d5}} 
        pop     iy                ;{{3605:fde1}} 
        push    hl                ;{{3607:e5}} 
        pop     ix                ;{{3608:dde1}} 
        xor     a                 ;{{360A:af}} 
        sub     (iy+$04)          ;{{360B:fd9604}} 
        jr      z,_real_division_54;{{360E:285a}}  (+&5a)
        call    _real_division_98 ;{{3610:cdaf36}} 
        jp      z,_process_real_at_hl_42;{{3613:cae237}} 
        jr      nc,_real_division_53;{{3616:304f}}  (+&4f)
        push    bc                ;{{3618:c5}} 
        ld      c,a               ;{{3619:4f}} 
        ld      e,(hl)            ;{{361A:5e}} 
        inc     hl                ;{{361B:23}} 
        ld      d,(hl)            ;{{361C:56}} 
        inc     hl                ;{{361D:23}} 
        ld      a,(hl)            ;{{361E:7e}} 
        inc     hl                ;{{361F:23}} 
        ld      h,(hl)            ;{{3620:66}} 
        ld      l,a               ;{{3621:6f}} 
        ex      de,hl             ;{{3622:eb}} 
        ld      b,(iy+$03)        ;{{3623:fd4603}} 
        set     7,b               ;{{3626:cbf8}} 
        call    _real_division_86 ;{{3628:cd9d36}} 
        jr      c,_real_division_29;{{362B:3806}}  (+&06)
        ld      a,c               ;{{362D:79}} 
        or      a                 ;{{362E:b7}} 
        jr      nz,_real_division_33;{{362F:2008}}  (+&08)
        jr      _real_division_52 ;{{3631:1833}}  (+&33)

_real_division_29:                ;{{Addr=$3633 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{3633:0d}} 
        add     hl,hl             ;{{3634:29}} 
        rl      e                 ;{{3635:cb13}} 
        rl      d                 ;{{3637:cb12}} 
_real_division_33:                ;{{Addr=$3639 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$04),c        ;{{3639:dd7104}} 
        call    _real_division_58 ;{{363C:cd7236}} 
        ld      (ix+$03),c        ;{{363F:dd7103}} 
        call    _real_division_58 ;{{3642:cd7236}} 
        ld      (ix+$02),c        ;{{3645:dd7102}} 
        call    _real_division_58 ;{{3648:cd7236}} 
        ld      (ix+$01),c        ;{{364B:dd7101}} 
        call    _real_division_58 ;{{364E:cd7236}} 
        ccf                       ;{{3651:3f}} 
        call    c,_real_division_86;{{3652:dc9d36}} 
        ccf                       ;{{3655:3f}} 
        sbc     a,a               ;{{3656:9f}} 
        ld      l,c               ;{{3657:69}} 
        ld      h,(ix+$01)        ;{{3658:dd6601}} 
        ld      e,(ix+$02)        ;{{365B:dd5e02}} 
        ld      d,(ix+$03)        ;{{365E:dd5603}} 
        pop     bc                ;{{3661:c1}} 
        ld      c,a               ;{{3662:4f}} 
        jp      _process_real_at_hl_18;{{3663:c3b737}} 

_real_division_52:                ;{{Addr=$3666 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{3666:c1}} 
_real_division_53:                ;{{Addr=$3667 Code Calls/jump count: 1 Data use count: 0}}
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3667:c3ea37}} 

_real_division_54:                ;{{Addr=$366a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,(ix+$03)        ;{{366A:dd4603}} 
        call    REAL_at_IX_to_max_pos_or_max_neg;{{366D:cdea37}} 
        xor     a                 ;{{3670:af}} 
        ret                       ;{{3671:c9}} 

_real_division_58:                ;{{Addr=$3672 Code Calls/jump count: 4 Data use count: 0}}
        ld      c,$01             ;{{3672:0e01}} 
_real_division_59:                ;{{Addr=$3674 Code Calls/jump count: 1 Data use count: 0}}
        jr      c,_real_division_65;{{3674:3808}}  (+&08)
        ld      a,d               ;{{3676:7a}} 
        cp      b                 ;{{3677:b8}} 
        call    z,_real_division_89;{{3678:cca036}} 
        ccf                       ;{{367B:3f}} 
        jr      nc,_real_division_78;{{367C:3013}}  (+&13)
_real_division_65:                ;{{Addr=$367e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{367E:7d}} 
        sub     (iy+$00)          ;{{367F:fd9600}} 
        ld      l,a               ;{{3682:6f}} 
        ld      a,h               ;{{3683:7c}} 
        sbc     a,(iy+$01)        ;{{3684:fd9e01}} 
        ld      h,a               ;{{3687:67}} 
        ld      a,e               ;{{3688:7b}} 
        sbc     a,(iy+$02)        ;{{3689:fd9e02}} 
        ld      e,a               ;{{368C:5f}} 
        ld      a,d               ;{{368D:7a}} 
        sbc     a,b               ;{{368E:98}} 
        ld      d,a               ;{{368F:57}} 
        scf                       ;{{3690:37}} 
_real_division_78:                ;{{Addr=$3691 Code Calls/jump count: 1 Data use count: 0}}
        rl      c                 ;{{3691:cb11}} 
        sbc     a,a               ;{{3693:9f}} 
        add     hl,hl             ;{{3694:29}} 
        rl      e                 ;{{3695:cb13}} 
        rl      d                 ;{{3697:cb12}} 
        inc     a                 ;{{3699:3c}} 
        jr      nz,_real_division_59;{{369A:20d8}}  (-&28)
        ret                       ;{{369C:c9}} 

_real_division_86:                ;{{Addr=$369d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{369D:7a}} 
        cp      b                 ;{{369E:b8}} 
        ret     nz                ;{{369F:c0}} 

_real_division_89:                ;{{Addr=$36a0 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{36A0:7b}} 
        cp      (iy+$02)          ;{{36A1:fdbe02}} 
        ret     nz                ;{{36A4:c0}} 

        ld      a,h               ;{{36A5:7c}} 
        cp      (iy+$01)          ;{{36A6:fdbe01}} 
        ret     nz                ;{{36A9:c0}} 

        ld      a,l               ;{{36AA:7d}} 
        cp      (iy+$00)          ;{{36AB:fdbe00}} 
        ret                       ;{{36AE:c9}} 

_real_division_98:                ;{{Addr=$36af Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{36AF:4f}} 
        ld      a,(ix+$03)        ;{{36B0:dd7e03}} 
        xor     (iy+$03)          ;{{36B3:fdae03}} 
        ld      b,a               ;{{36B6:47}} 
        ld      a,(ix+$04)        ;{{36B7:dd7e04}} 
        or      a                 ;{{36BA:b7}} 
        ret     z                 ;{{36BB:c8}} 

        add     a,c               ;{{36BC:81}} 
        ld      c,a               ;{{36BD:4f}} 
        rra                       ;{{36BE:1f}} 
        xor     c                 ;{{36BF:a9}} 
        ld      a,c               ;{{36C0:79}} 
        jp      p,_real_division_117;{{36C1:f2cf36}} 
        set     7,(ix+$03)        ;{{36C4:ddcb03fe}} 
        sub     $7f               ;{{36C8:d67f}} 
        scf                       ;{{36CA:37}} 
        ret     nz                ;{{36CB:c0}} 

        cp      $01               ;{{36CC:fe01}} 
        ret                       ;{{36CE:c9}} 

_real_division_117:               ;{{Addr=$36cf Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{36CF:b7}} 
        ret     m                 ;{{36D0:f8}} 

        xor     a                 ;{{36D1:af}} 
        ret                       ;{{36D2:c9}} 

_real_division_121:               ;{{Addr=$36d3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{36D3:e5}} 
        pop     ix                ;{{36D4:dde1}} 
        ld      a,(ix+$04)        ;{{36D6:dd7e04}} 
        or      a                 ;{{36D9:b7}} 
        ret     z                 ;{{36DA:c8}} 

        sub     $80               ;{{36DB:d680}} 
        scf                       ;{{36DD:37}} 
        ret                       ;{{36DE:c9}} 

;;============================================================================================
;; REAL compare

REAL_compare:                     ;{{Addr=$36df Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{36DF:e5}} 
        pop     ix                ;{{36E0:dde1}} 
_real_compare_2:                  ;{{Addr=$36e2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{36E2:d5}} 
        pop     iy                ;{{36E3:fde1}} 
        ld      a,(ix+$04)        ;{{36E5:dd7e04}} 
        cp      (iy+$04)          ;{{36E8:fdbe04}} 
        jr      c,_real_compare_25;{{36EB:382c}}  (+&2c)
        jr      nz,_real_compare_32;{{36ED:2033}}  (+&33)
        or      a                 ;{{36EF:b7}} 
        ret     z                 ;{{36F0:c8}} 

        ld      a,(ix+$03)        ;{{36F1:dd7e03}} 
        xor     (iy+$03)          ;{{36F4:fdae03}} 
        jp      m,_real_compare_32;{{36F7:fa2237}} 
        ld      a,(ix+$03)        ;{{36FA:dd7e03}} 
        sub     (iy+$03)          ;{{36FD:fd9603}} 
        jr      nz,_real_compare_25;{{3700:2017}}  (+&17)
        ld      a,(ix+$02)        ;{{3702:dd7e02}} 
        sub     (iy+$02)          ;{{3705:fd9602}} 
        jr      nz,_real_compare_25;{{3708:200f}}  (+&0f)
        ld      a,(ix+$01)        ;{{370A:dd7e01}} 
        sub     (iy+$01)          ;{{370D:fd9601}} 
        jr      nz,_real_compare_25;{{3710:2007}}  (+&07)
        ld      a,(ix+$00)        ;{{3712:dd7e00}} 
        sub     (iy+$00)          ;{{3715:fd9600}} 
        ret     z                 ;{{3718:c8}} 

_real_compare_25:                 ;{{Addr=$3719 Code Calls/jump count: 4 Data use count: 0}}
        sbc     a,a               ;{{3719:9f}} 
        xor     (iy+$03)          ;{{371A:fdae03}} 
_real_compare_27:                 ;{{Addr=$371d Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{371D:87}} 
        sbc     a,a               ;{{371E:9f}} 
        ret     c                 ;{{371F:d8}} 

        inc     a                 ;{{3720:3c}} 
        ret                       ;{{3721:c9}} 

_real_compare_32:                 ;{{Addr=$3722 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(ix+$03)        ;{{3722:dd7e03}} 
        jr      _real_compare_27  ;{{3725:18f6}}  (-&0a)

;;============================================================================================
;; REAL SGN

REAL_SGN:                         ;{{Addr=$3727 Code Calls/jump count: 7 Data use count: 1}}
        push    hl                ;{{3727:e5}} 
        pop     ix                ;{{3728:dde1}} 
        ld      a,(ix+$04)        ;{{372A:dd7e04}} 
        or      a                 ;{{372D:b7}} 
        ret     z                 ;{{372E:c8}} 

        jr      _real_compare_32  ;{{372F:18f1}}  (-&0f)

;;============================================================================================
;; REAL Negate

REAL_Negate:                      ;{{Addr=$3731 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{3731:e5}} 
        pop     ix                ;{{3732:dde1}} 
_real_negate_2:                   ;{{Addr=$3734 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,(ix+$03)        ;{{3734:dd7e03}} 
        xor     $80               ;{{3737:ee80}} 
        ld      (ix+$03),a        ;{{3739:dd7703}} 
        ret                       ;{{373C:c9}} 

;;============================================================================================
x373D_code:                       ;{{Addr=$373d Code Calls/jump count: 2 Data use count: 0}}
        cp      $21               ;{{373D:fe21}} 
        jr      c,x3743_code      ;{{373F:3802}}  (+&02)
        ld      a,$21             ;{{3741:3e21}} 
x3743_code:                       ;{{Addr=$3743 Code Calls/jump count: 2 Data use count: 0}}
        ld      e,(hl)            ;{{3743:5e}} 
        inc     hl                ;{{3744:23}} 
        ld      d,(hl)            ;{{3745:56}} 
        inc     hl                ;{{3746:23}} 
        ld      c,(hl)            ;{{3747:4e}} 
        inc     hl                ;{{3748:23}} 
        ld      h,(hl)            ;{{3749:66}} 
        ld      l,c               ;{{374A:69}} 
        ex      de,hl             ;{{374B:eb}} 
        set     7,d               ;{{374C:cbfa}} 
        ld      bc,$0000          ;{{374E:010000}} ##LIT##;WARNING: Code area used as literal
        jr      x375E_code        ;{{3751:180b}}  (+&0b)

x3753_code:                       ;{{Addr=$3753 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{3753:4f}} 
        ld      a,b               ;{{3754:78}} 
        or      l                 ;{{3755:b5}} 
        ld      b,a               ;{{3756:47}} 
        ld      a,c               ;{{3757:79}} 
        ld      c,l               ;{{3758:4d}} 
        ld      l,h               ;{{3759:6c}} 
        ld      h,e               ;{{375A:63}} 
        ld      e,d               ;{{375B:5a}} 
        ld      d,$00             ;{{375C:1600}} 
x375E_code:                       ;{{Addr=$375e Code Calls/jump count: 1 Data use count: 0}}
        sub     $08               ;{{375E:d608}} 
        jr      nc,x3753_code     ;{{3760:30f1}}  (-&0f)
        add     a,$08             ;{{3762:c608}} 
        ret     z                 ;{{3764:c8}} 

x3765_code:                       ;{{Addr=$3765 Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{3765:cb3a}} 
        rr      e                 ;{{3767:cb1b}} 
        rr      h                 ;{{3769:cb1c}} 
        rr      l                 ;{{376B:cb1d}} 
        rr      c                 ;{{376D:cb19}} 
        dec     a                 ;{{376F:3d}} 
        jr      nz,x3765_code     ;{{3770:20f3}}  (-&0d)
        ret                       ;{{3772:c9}} 

;;============================================================================================
x3773_code:                       ;{{Addr=$3773 Code Calls/jump count: 1 Data use count: 0}}
        jr      nz,x378C_code     ;{{3773:2017}}  (+&17)
        ld      d,a               ;{{3775:57}} 
        ld      a,e               ;{{3776:7b}} 
        or      h                 ;{{3777:b4}} 
        or      l                 ;{{3778:b5}} 
        or      c                 ;{{3779:b1}} 
        ret     z                 ;{{377A:c8}} 

        ld      a,d               ;{{377B:7a}} 
x377C_code:                       ;{{Addr=$377c Code Calls/jump count: 1 Data use count: 0}}
        sub     $08               ;{{377C:d608}} 
        jr      c,x379A_code      ;{{377E:381a}}  (+&1a)
        ret     z                 ;{{3780:c8}} 

        ld      d,e               ;{{3781:53}} 
        ld      e,h               ;{{3782:5c}} 
        ld      h,l               ;{{3783:65}} 
        ld      l,c               ;{{3784:69}} 
        ld      c,$00             ;{{3785:0e00}} 
        inc     d                 ;{{3787:14}} 
        dec     d                 ;{{3788:15}} 
        jr      z,x377C_code      ;{{3789:28f1}}  (-&0f)
        ret     m                 ;{{378B:f8}} 

x378C_code:                       ;{{Addr=$378c Code Calls/jump count: 2 Data use count: 0}}
        dec     a                 ;{{378C:3d}} 
        ret     z                 ;{{378D:c8}} 

        sla     c                 ;{{378E:cb21}} 
        adc     hl,hl             ;{{3790:ed6a}} 
        rl      e                 ;{{3792:cb13}} 
        rl      d                 ;{{3794:cb12}} 
        jp      p,x378C_code      ;{{3796:f28c37}} 
        ret                       ;{{3799:c9}} 

x379A_code:                       ;{{Addr=$379a Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{379A:af}} 
        ret                       ;{{379B:c9}} 

;;============================================
;;Process REAL at (HL)
Process_REAL_at_HL:               ;{{Addr=$379c Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{379C:e5}} 
        pop     ix                ;{{379D:dde1}} 
        ld      (ix+$04),b        ;{{379F:dd7004}} 
        ld      b,a               ;{{37A2:47}} 
        ld      e,(hl)            ;{{37A3:5e}} 
        inc     hl                ;{{37A4:23}} 
        ld      d,(hl)            ;{{37A5:56}} 
        inc     hl                ;{{37A6:23}} 
        ld      a,(hl)            ;{{37A7:7e}} 
        inc     hl                ;{{37A8:23}} 
        ld      h,(hl)            ;{{37A9:66}} 
        ld      l,a               ;{{37AA:6f}} 
        ex      de,hl             ;{{37AB:eb}} 
_process_real_at_hl_13:           ;{{Addr=$37ac Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$04)        ;{{37AC:dd7e04}} 
        dec     d                 ;{{37AF:15}} 
        inc     d                 ;{{37B0:14}} 
        call    p,x3773_code      ;{{37B1:f47337}} 
        ld      (ix+$04),a        ;{{37B4:dd7704}} 
_process_real_at_hl_18:           ;{{Addr=$37b7 Code Calls/jump count: 4 Data use count: 0}}
        sla     c                 ;{{37B7:cb21}} 
        jr      nc,_process_real_at_hl_31;{{37B9:3012}}  (+&12)
        inc     l                 ;{{37BB:2c}} 
        jr      nz,_process_real_at_hl_31;{{37BC:200f}}  (+&0f)
        inc     h                 ;{{37BE:24}} 
        jr      nz,_process_real_at_hl_31;{{37BF:200c}}  (+&0c)
        inc     de                ;{{37C1:13}} 
        ld      a,d               ;{{37C2:7a}} 
        or      e                 ;{{37C3:b3}} 
        jr      nz,_process_real_at_hl_31;{{37C4:2007}}  (+&07)
        inc     (ix+$04)          ;{{37C6:dd3404}} 
        jr      z,REAL_at_IX_to_max_pos_or_max_neg;{{37C9:281f}}  (+&1f)
        ld      d,$80             ;{{37CB:1680}} 
_process_real_at_hl_31:           ;{{Addr=$37cd Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{37CD:78}} 
        or      $7f               ;{{37CE:f67f}} 
        and     d                 ;{{37D0:a2}} 
        ld      (ix+$03),a        ;{{37D1:dd7703}} 
        ld      (ix+$02),e        ;{{37D4:dd7302}} 
        ld      (ix+$01),h        ;{{37D7:dd7401}} 
        ld      (ix+$00),l        ;{{37DA:dd7500}} 
_process_real_at_hl_38:           ;{{Addr=$37dd Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{37DD:dde5}} 
        pop     hl                ;{{37DF:e1}} 
        scf                       ;{{37E0:37}} 
        ret                       ;{{37E1:c9}} 

_process_real_at_hl_42:           ;{{Addr=$37e2 Code Calls/jump count: 5 Data use count: 0}}
        xor     a                 ;{{37E2:af}} 
        ld      (ix+$04),a        ;{{37E3:dd7704}} 
        jr      _process_real_at_hl_38;{{37E6:18f5}}  (-&0b)

;;============================================
;; REAL at IX to max pos
REAL_at_IX_to_max_pos:            ;{{Addr=$37e8 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$00             ;{{37E8:0600}} 

;;=REAL at IX to max pos or max neg
;;If B >= 0 store max positive real at (IX), otherwise max negative

REAL_at_IX_to_max_pos_or_max_neg: ;{{Addr=$37ea Code Calls/jump count: 6 Data use count: 0}}
        push    ix                ;{{37EA:dde5}} 
        pop     hl                ;{{37EC:e1}} 
        ld      a,b               ;{{37ED:78}} 
        or      $7f               ;{{37EE:f67f}} 
        ld      (ix+$03),a        ;{{37F0:dd7703}} 
        or      $ff               ;{{37F3:f6ff}} 
        ld      (ix+$04),a        ;{{37F5:dd7704}} 
        ld      (hl),a            ;{{37F8:77}} 
        ld      (ix+$01),a        ;{{37F9:dd7701}} 
        ld      (ix+$02),a        ;{{37FC:dd7702}} 
        ret                       ;{{37FF:c9}} 



;;***Font.asm
;; Font Graphics
;;=============================================================================
;;Font graphics
Font_graphics:                    ;{{Addr=$3800 Data Calls/jump count: 0 Data use count: 1}}
                                  
;--------------------------
;; character 0
;;
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %11000011            
        defb %11000011            
        defb %11000011            
        defb %11000011            
        defb %11111111            
;--------------------------
;; character 1
;;
        defb %11111111            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
;--------------------------
;; character 2
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111111            
;--------------------------
;; character 3
;;
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %11111111            
;--------------------------
;; character 4
;;
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %01111110            
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %00000000            
;--------------------------
;; character 5
;;
        defb %11111111            
        defb %11000011            
        defb %11100111            
        defb %11011011            
        defb %11011011            
        defb %11100111            
        defb %11000011            
        defb %11111111            
;--------------------------
;; character 6
;;
        defb %00000000            
        defb %00000001            
        defb %00000011            
        defb %00000110            
        defb %11001100            
        defb %01111000            
        defb %00110000            
        defb %00000000            
;--------------------------
;; character 7
;;
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11000011            
        defb %11111111            
        defb %00100100            
        defb %11100111            
        defb %00000000            
;--------------------------
;; character 8
;;
        defb %00000000            
        defb %00000000            
        defb %00110000            
        defb %01100000            
        defb %11111111            
        defb %01100000            
        defb %00110000            
        defb %00000000            
;--------------------------
;; character 9
;;
        defb %00000000            
        defb %00000000            
        defb %00001100            
        defb %00000110            
        defb %11111111            
        defb %00000110            
        defb %00001100            
        defb %00000000            
;--------------------------
;; character 10
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11011011            
        defb %01111110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 11
;;
        defb %00011000            
        defb %00111100            
        defb %01111110            
        defb %11011011            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 12
;;
        defb %00011000            
        defb %01011010            
        defb %00111100            
        defb %10011001            
        defb %11011011            
        defb %01111110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 13
;;
        defb %00000000            
        defb %00000011            
        defb %00110011            
        defb %01100011            
        defb %11111110            
        defb %01100000            
        defb %00110000            
        defb %00000000            
;--------------------------
;; character 14
;;
        defb %00111100            
        defb %01100110            
        defb %11111111            
        defb %11011011            
        defb %11011011            
        defb %11111111            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 15
;;
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11011011            
        defb %11011011            
        defb %11000011            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 16
;;
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %11000011            
        defb %11111111            
;--------------------------
;; character 17
;;
        defb %00111100            
        defb %01111110            
        defb %11011011            
        defb %11011011            
        defb %11011111            
        defb %11000011            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 18
;;
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11011111            
        defb %11011011            
        defb %11011011            
        defb %01111110            
        defb %00111100            
;--------------------------
;; character 19
;;
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11111011            
        defb %11011011            
        defb %11011011            
        defb %01111110            
        defb %00111100            
;--------------------------
;; character 20
;;
        defb %00111100            
        defb %01111110            
        defb %11011011            
        defb %11011011            
        defb %11111011            
        defb %11000011            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 21
;;
        defb %00000000            
        defb %00000001            
        defb %00110011            
        defb %00011110            
        defb %11001110            
        defb %01111011            
        defb %00110001            
        defb %00000000            
;--------------------------
;; character 22
;;
        defb %01111110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %11100111            
;--------------------------
;; character 23
;;
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %11111111            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000000            
;--------------------------
;; character 24
;;
        defb %11111111            
        defb %01100110            
        defb %00111100            
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %01100110            
        defb %11111111            
;--------------------------
;; character 25
;;
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %00111100            
        defb %00111100            
        defb %00111100            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 26
;;
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00110000            
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00000000            
;-------------------------
;; character 27
;;
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 28
;;
        defb %11111111            
        defb %11011011            
        defb %11011011            
        defb %11011011            
        defb %11111011            
        defb %11000011            
        defb %11000011            
        defb %11111111            
;--------------------------
;; character 29
;;
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %11111011            
        defb %11011011            
        defb %11011011            
        defb %11011011            
        defb %11111111            
;--------------------------
;; character 30
;;
        defb %11111111            
        defb %11000011            
        defb %11000011            
        defb %11011111            
        defb %11011011            
        defb %11011011            
        defb %11011011            
        defb %11111111            
;--------------------------
;; character 31
;;
        defb %11111111            
        defb %11011011            
        defb %11011011            
        defb %11011011            
        defb %11011111            
        defb %11000011            
        defb %11000011            
        defb %11111111            
;--------------------------
;; character 32
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 33
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 34
;;
        defb %01101100            
        defb %01101100            
        defb %01101100            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 35
;;
        defb %01101100            
        defb %01101100            
        defb %11111110            
        defb %01101100            
        defb %11111110            
        defb %01101100            
        defb %01101100            
        defb %00000000            
;--------------------------
;; character 36
;;
        defb %00011000            
        defb %00111110            
        defb %01011000            
        defb %00111100            
        defb %00011010            
        defb %01111100            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 37
;;
        defb %00000000            
        defb %11000110            
        defb %11001100            
        defb %00011000            
        defb %00110000            
        defb %01100110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 38
;;
        defb %00111000            
        defb %01101100            
        defb %00111000            
        defb %01110110            
        defb %11011100            
        defb %11001100            
        defb %01110110            
        defb %00000000            
;--------------------------
;; character 39
;;
        defb %00011000            
        defb %00011000            
        defb %00110000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 40
;;
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %00110000            
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00000000            
;--------------------------
;; character 41
;;
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %00000000            
;--------------------------
;; character 42
;;
        defb %00000000            
        defb %01100110            
        defb %00111100            
        defb %11111111            
        defb %00111100            
        defb %01100110            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 43
;;
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 44
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00110000            
;--------------------------
;; character 45
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 46
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 47
;;
        defb %00000110            
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %11000000            
        defb %10000000            
        defb %00000000            
;--------------------------
;; character 48
;;
        defb %01111100            
        defb %11000110            
        defb %11001110            
        defb %11010110            
        defb %11100110            
        defb %11000110            
        defb %01111100            
        defb %00000000            
;--------------------------
;; character 49
;;
        defb %00011000            
        defb %00111000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 50
;;
        defb %00111100            
        defb %01100110            
        defb %00000110            
        defb %00111100            
        defb %01100000            
        defb %01100110            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 51
;;
        defb %00111100            
        defb %01100110            
        defb %00000110            
        defb %00011100            
        defb %00000110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 52
;;
        defb %00011100            
        defb %00111100            
        defb %01101100            
        defb %11001100            
        defb %11111110            
        defb %00001100            
        defb %00011110            
        defb %00000000            
;--------------------------
;; character 53
;;
        defb %01111110            
        defb %01100010            
        defb %01100000            
        defb %01111100            
        defb %00000110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 54
;;
        defb %00111100            
        defb %01100110            
        defb %01100000            
        defb %01111100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 55
;;
        defb %01111110            
        defb %01100110            
        defb %00000110            
        defb %00001100            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 56
;;
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 57
;;
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00111110            
        defb %00000110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 58
;;
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 59
;;
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00110000            
;--------------------------
;; character 60
;;
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00000000            
;--------------------------
;; character 61
;;
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 62
;;
        defb %01100000            
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %00000000            
;--------------------------
;; character 63
;;
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00001100            
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 64
;;
        defb %01111100            
        defb %11000110            
        defb %11011110            
        defb %11011110            
        defb %11011110            
        defb %11000000            
        defb %01111100            
        defb %00000000            
;--------------------------
;; character 65
;;
        defb %00011000            
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %01111110            
        defb %01100110            
        defb %01100110            
        defb %00000000            
;--------------------------
;; character 66
;;
        defb %11111100            
        defb %01100110            
        defb %01100110            
        defb %01111100            
        defb %01100110            
        defb %01100110            
        defb %11111100            
        defb %00000000            
;--------------------------
;; character 67
;;
        defb %00111100            
        defb %01100110            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 68
;;
        defb %11111000            
        defb %01101100            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01101100            
        defb %11111000            
        defb %00000000            
;--------------------------
;; character 69
;;
        defb %11111110            
        defb %01100010            
        defb %01101000            
        defb %01111000            
        defb %01101000            
        defb %01100010            
        defb %11111110            
        defb %00000000            
;--------------------------
;; character 70
;;
        defb %11111110            
        defb %01100010            
        defb %01101000            
        defb %01111000            
        defb %01101000            
        defb %01100000            
        defb %11110000            
        defb %00000000            
;--------------------------
;; character 71
;;
        defb %00111100            
        defb %01100110            
        defb %11000000            
        defb %11000000            
        defb %11001110            
        defb %01100110            
        defb %00111110            
        defb %00000000            
;--------------------------
;; character 72
;;
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01111110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00000000            
;--------------------------
;; character 73
;;
        defb %01111110            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 74
;;
        defb %00011110            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %11001100            
        defb %11001100            
        defb %01111000            
        defb %00000000            
;--------------------------
;; character 75
;;
        defb %11100110            
        defb %01100110            
        defb %01101100            
        defb %01111000            
        defb %01101100            
        defb %01100110            
        defb %11100110            
        defb %00000000            
;--------------------------
;; character 76
;;
        defb %11110000            
        defb %01100000            
        defb %01100000            
        defb %01100000            
        defb %01100010            
        defb %01100110            
        defb %11111110            
        defb %00000000            
;--------------------------
;; character 77
;;
        defb %11000110            
        defb %11101110            
        defb %11111110            
        defb %11111110            
        defb %11010110            
        defb %11000110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 78
;;
        defb %11000110            
        defb %11100110            
        defb %11110110            
        defb %11011110            
        defb %11001110            
        defb %11000110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 79
;;
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %11000110            
        defb %11000110            
        defb %01101100            
        defb %00111000            
        defb %00000000            
;--------------------------
;; character 80
;;
        defb %11111100            
        defb %01100110            
        defb %01100110            
        defb %01111100            
        defb %01100000            
        defb %01100000            
        defb %11110000            
        defb %00000000            
;--------------------------
;; character 81
;;
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %11000110            
        defb %11011010            
        defb %11001100            
        defb %01110110            
        defb %00000000            
;--------------------------
;; character 82
;;
        defb %11111100            
        defb %01100110            
        defb %01100110            
        defb %01111100            
        defb %01101100            
        defb %01100110            
        defb %11100110            
        defb %00000000            
;--------------------------
;; character 83
;;
        defb %00111100            
        defb %01100110            
        defb %01100000            
        defb %00111100            
        defb %00000110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 84
;;
        defb %01111110            
        defb %01011010            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 85
;;
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 86
;;
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 87
;;
        defb %11000110            
        defb %11000110            
        defb %11000110            
        defb %11010110            
        defb %11111110            
        defb %11101110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 88
;;
        defb %11000110            
        defb %01101100            
        defb %00111000            
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 89
;;
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 90
;;
        defb %11111110            
        defb %11000110            
        defb %10001100            
        defb %00011000            
        defb %00110010            
        defb %01100110            
        defb %11111110            
        defb %00000000            
;--------------------------
;; character 91
;;
        defb %00111100            
        defb %00110000            
        defb %00110000            
        defb %00110000            
        defb %00110000            
        defb %00110000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 92
;;
        defb %11000000            
        defb %01100000            
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00000110            
        defb %00000010            
        defb %00000000            
;--------------------------
;; character 93
;;
        defb %00111100            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 94
;;
        defb %00011000            
        defb %00111100            
        defb %01111110            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 95
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111111            
;--------------------------
;; character 96
;;
        defb %00110000            
        defb %00011000            
        defb %00001100            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 97
;;
        defb %00000000            
        defb %00000000            
        defb %01111000            
        defb %00001100            
        defb %01111100            
        defb %11001100            
        defb %01110110            
        defb %00000000            
;--------------------------
;; character 98
;;
        defb %11100000            
        defb %01100000            
        defb %01111100            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %11011100            
        defb %00000000            
;--------------------------
;; character 99
;;
        defb %00000000            
        defb %00000000            
        defb %00111100            
        defb %01100110            
        defb %01100000            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 100
;;
        defb %00011100            
        defb %00001100            
        defb %01111100            
        defb %11001100            
        defb %11001100            
        defb %11001100            
        defb %01110110            
        defb %00000000            
;--------------------------
;; character 101
;;
        defb %00000000            
        defb %00000000            
        defb %00111100            
        defb %01100110            
        defb %01111110            
        defb %01100000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 102
;;
        defb %00011100            
        defb %00110110            
        defb %00110000            
        defb %01111000            
        defb %00110000            
        defb %00110000            
        defb %01111000            
        defb %00000000            
;--------------------------
;; character 103
;;
        defb %00000000            
        defb %00000000            
        defb %00111110            
        defb %01100110            
        defb %01100110            
        defb %00111110            
        defb %00000110            
        defb %01111100            
;--------------------------
;; character 104
;;
        defb %11100000            
        defb %01100000            
        defb %01101100            
        defb %01110110            
        defb %01100110            
        defb %01100110            
        defb %11100110            
        defb %00000000            
;--------------------------
;; character 105
;;
        defb %00011000            
        defb %00000000            
        defb %00111000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 106
;;
        defb %00000110            
        defb %00000000            
        defb %00001110            
        defb %00000110            
        defb %00000110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
;--------------------------
;; character 107
;;
        defb %11100000            
        defb %01100000            
        defb %01100110            
        defb %01101100            
        defb %01111000            
        defb %01101100            
        defb %11100110            
        defb %00000000            
;--------------------------
;; character 108
;;
        defb %00111000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 109
;;
        defb %00000000            
        defb %00000000            
        defb %01101100            
        defb %11111110            
        defb %11010110            
        defb %11010110            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 110
;;
        defb %00000000            
        defb %00000000            
        defb %11011100            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00000000            
;--------------------------
;; character 111
;;
        defb %00000000            
        defb %00000000            
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 112
;;
        defb %00000000            
        defb %00000000            
        defb %11011100            
        defb %01100110            
        defb %01100110            
        defb %01111100            
        defb %01100000            
        defb %11110000            
;--------------------------
;; character 113
;;
        defb %00000000            
        defb %00000000            
        defb %01110110            
        defb %11001100            
        defb %11001100            
        defb %01111100            
        defb %00001100            
        defb %00011110            
;--------------------------
;; character 114
;;
        defb %00000000            
        defb %00000000            
        defb %11011100            
        defb %01110110            
        defb %01100000            
        defb %01100000            
        defb %11110000            
        defb %00000000            
;--------------------------
;; character 115
;;
        defb %00000000            
        defb %00000000            
        defb %00111100            
        defb %01100000            
        defb %00111100            
        defb %00000110            
        defb %01111100            
        defb %00000000            
;--------------------------
;; character 116
;;
        defb %00110000            
        defb %00110000            
        defb %01111100            
        defb %00110000            
        defb %00110000            
        defb %00110110            
        defb %00011100            
        defb %00000000            
;--------------------------
;; character 117
;;
        defb %00000000            
        defb %00000000            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111110            
        defb %00000000            
;--------------------------
;; character 118
;;
        defb %00000000            
        defb %00000000            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 119
;;
        defb %00000000            
        defb %00000000            
        defb %11000110            
        defb %11010110            
        defb %11010110            
        defb %11111110            
        defb %01101100            
        defb %00000000            
;--------------------------
;; character 120
;;
        defb %00000000            
        defb %00000000            
        defb %11000110            
        defb %01101100            
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 121
;;
        defb %00000000            
        defb %00000000            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111110            
        defb %00000110            
        defb %01111100            
;--------------------------
;; character 122
;;
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %01001100            
        defb %00011000            
        defb %00110010            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 123
;;
        defb %00001110            
        defb %00011000            
        defb %00011000            
        defb %01110000            
        defb %00011000            
        defb %00011000            
        defb %00001110            
        defb %00000000            
;--------------------------
;; character 124
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 125
;;
        defb %01110000            
        defb %00011000            
        defb %00011000            
        defb %00001110            
        defb %00011000            
        defb %00011000            
        defb %01110000            
        defb %00000000            
;--------------------------
;; character 126
;;
        defb %01110110            
        defb %11011100            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 127
;;
        defb %11001100            
        defb %00110011            
        defb %11001100            
        defb %00110011            
        defb %11001100            
        defb %00110011            
        defb %11001100            
        defb %00110011            
;--------------------------
;; character 128
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 129
;;
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 130
;;
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 131
;;
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 132
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
;--------------------------
;; character 133
;;
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
;--------------------------
;; character 134
;;
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
;--------------------------
;; character 135
;;
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
;--------------------------
;; character 136
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
;--------------------------
;; character 137
;;
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
;--------------------------
;; character 138
;;
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
;--------------------------
;; character 139
;;
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
;--------------------------
;; character 140
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
;--------------------------
;; character 141
;;
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11110000            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
;--------------------------
;; character 142
;;
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %00001111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
;--------------------------
;; character 143
;;
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
        defb %11111111            
;--------------------------
;; character 144
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 145
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 146
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00011111            
        defb %00011111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 147
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011111            
        defb %00001111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 148
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 149
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 150
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00001111            
        defb %00011111            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 151
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011111            
        defb %00011111            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 152
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111000            
        defb %11111000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 153
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111000            
        defb %11110000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 154
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111111            
        defb %11111111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 155
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111111            
        defb %11111111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 156
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11110000            
        defb %11111000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 157
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111000            
        defb %11111000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 158
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111111            
        defb %11111111            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 159
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111111            
        defb %11111111            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 160
;;
        defb %00010000            
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 161
;;
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 162
;;
        defb %01100110            
        defb %01100110            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 163
;;
        defb %00111100            
        defb %01100110            
        defb %01100000            
        defb %11111000            
        defb %01100000            
        defb %01100110            
        defb %11111110            
        defb %00000000            
;--------------------------
;; character 164
;;
        defb %00111000            
        defb %01000100            
        defb %10111010            
        defb %10100010            
        defb %10111010            
        defb %01000100            
        defb %00111000            
        defb %00000000            
;--------------------------
;; character 165
;;
        defb %01111110            
        defb %11110100            
        defb %11110100            
        defb %01110100            
        defb %00110100            
        defb %00110100            
        defb %00110100            
        defb %00000000            
;--------------------------
;; character 166
;;
        defb %00011110            
        defb %00110000            
        defb %00111000            
        defb %01101100            
        defb %00111000            
        defb %00011000            
        defb %11110000            
        defb %00000000            
;--------------------------
;; character 167
;;
        defb %00011000            
        defb %00011000            
        defb %00001100            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 168
;;
        defb %01000000            
        defb %11000000            
        defb %01000100            
        defb %01001100            
        defb %01010100            
        defb %00011110            
        defb %00000100            
        defb %00000000            
;--------------------------
;; character 169
;;
        defb %01000000            
        defb %11000000            
        defb %01001100            
        defb %01010010            
        defb %01000100            
        defb %00001000            
        defb %00011110            
        defb %00000000            
;--------------------------
;; character 170
;;
        defb %11100000            
        defb %00010000            
        defb %01100010            
        defb %00010110            
        defb %11101010            
        defb %00001111            
        defb %00000010            
        defb %00000000            
;--------------------------
;; character 171
;;
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 172
;;
        defb %00011000            
        defb %00011000            
        defb %00000000            
        defb %01111110            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 173
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %00000110            
        defb %00000110            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 174
;;
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00110000            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 175
;;
        defb %00011000            
        defb %00000000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 176
;;
        defb %00000000            
        defb %00000000            
        defb %01110011            
        defb %11011110            
        defb %11001100            
        defb %11011110            
        defb %01110011            
        defb %00000000            
;--------------------------
;; character 177
;;
        defb %01111100            
        defb %11000110            
        defb %11000110            
        defb %11111100            
        defb %11000110            
        defb %11000110            
        defb %11111000            
        defb %11000000            
;--------------------------
;; character 178
;;
        defb %00000000            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 179
;;
        defb %00111100            
        defb %01100000            
        defb %01100000            
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 180
;;
        defb %00000000            
        defb %00000000            
        defb %00011110            
        defb %00110000            
        defb %01111100            
        defb %00110000            
        defb %00011110            
        defb %00000000            
;--------------------------
;; character 181
;;
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %11111110            
        defb %11000110            
        defb %01101100            
        defb %00111000            
        defb %00000000            
;--------------------------
;; character 182
;;
        defb %00000000            
        defb %11000000            
        defb %01100000            
        defb %00110000            
        defb %00111000            
        defb %01101100            
        defb %11000110            
        defb %00000000            
;--------------------------
;; character 183
;;
        defb %00000000            
        defb %00000000            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01111100            
        defb %01100000            
        defb %01100000            
;--------------------------
;; character 184
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111110            
        defb %01101100            
        defb %01101100            
        defb %01101100            
        defb %00000000            
;--------------------------
;; character 185
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %01111110            
        defb %11011000            
        defb %11011000            
        defb %01110000            
        defb %00000000            
;--------------------------
;; character 186
;;
        defb %00000011            
        defb %00000110            
        defb %00001100            
        defb %00111100            
        defb %01100110            
        defb %00111100            
        defb %01100000            
        defb %11000000            
;--------------------------
;; character 187
;;
        defb %00000011            
        defb %00000110            
        defb %00001100            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %01100000            
        defb %11000000            
;--------------------------
;; character 188
;;
        defb %00000000            
        defb %11100110            
        defb %00111100            
        defb %00011000            
        defb %00111000            
        defb %01101100            
        defb %11000111            
        defb %00000000            
;--------------------------
;; character 189
;;
        defb %00000000            
        defb %00000000            
        defb %01100110            
        defb %11000011            
        defb %11011011            
        defb %11011011            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 190
;;
        defb %11111110            
        defb %11000110            
        defb %01100000            
        defb %00110000            
        defb %01100000            
        defb %11000110            
        defb %11111110            
        defb %00000000            
;--------------------------
;; character 191
;;
        defb %00000000            
        defb %01111100            
        defb %11000110            
        defb %11000110            
        defb %11000110            
        defb %01101100            
        defb %11101110            
        defb %00000000            
;--------------------------
;; character 192
;;
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %11000000            
        defb %10000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 193
;;
        defb %00011000            
        defb %00001100            
        defb %00000110            
        defb %00000011            
        defb %00000001            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 194
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000001            
        defb %00000011            
        defb %00000110            
        defb %00001100            
        defb %00011000            
;--------------------------
;; character 195
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %10000000            
        defb %11000000            
        defb %01100000            
        defb %00110000            
        defb %00011000            
;--------------------------
;; character 196
;;
        defb %00011000            
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %10000001            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 197
;;
        defb %00011000            
        defb %00001100            
        defb %00000110            
        defb %00000011            
        defb %00000011            
        defb %00000110            
        defb %00001100            
        defb %00011000            
;--------------------------
;; character 198
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %10000001            
        defb %11000011            
        defb %01100110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 199
;;
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %11000000            
        defb %11000000            
        defb %01100000            
        defb %00110000            
        defb %00011000            
;--------------------------
;; character 200
;;
        defb %00011000            
        defb %00110000            
        defb %01100000            
        defb %11000001            
        defb %10000011            
        defb %00000110            
        defb %00001100            
        defb %00011000            
;--------------------------
;; character 201
;;
        defb %00011000            
        defb %00001100            
        defb %00000110            
        defb %10000011            
        defb %11000001            
        defb %01100000            
        defb %00110000            
        defb %00011000            
;--------------------------
;; character 202
;;
        defb %00011000            
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11000011            
        defb %01100110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 203
;;
        defb %11000011            
        defb %11100111            
        defb %01111110            
        defb %00111100            
        defb %00111100            
        defb %01111110            
        defb %11100111            
        defb %11000011            
;--------------------------
;; character 204
;;
        defb %00000011            
        defb %00000111            
        defb %00001110            
        defb %00011100            
        defb %00111000            
        defb %01110000            
        defb %11100000            
        defb %11000000            
;--------------------------
;; character 205
;;
        defb %11000000            
        defb %11100000            
        defb %01110000            
        defb %00111000            
        defb %00011100            
        defb %00001110            
        defb %00000111            
        defb %00000011            
;--------------------------
;; character 206
;;
        defb %11001100            
        defb %11001100            
        defb %00110011            
        defb %00110011            
        defb %11001100            
        defb %11001100            
        defb %00110011            
        defb %00110011            
;--------------------------
;; character 207
;;
        defb %10101010            
        defb %01010101            
        defb %10101010            
        defb %01010101            
        defb %10101010            
        defb %01010101            
        defb %10101010            
        defb %01010101            
;--------------------------
;; character 208
;;
        defb %11111111            
        defb %11111111            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 209
;;
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
        defb %00000011            
;--------------------------
;; character 210
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %11111111            
        defb %11111111            
;--------------------------
;; character 211
;;
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
        defb %11000000            
;--------------------------
;; character 212
;;
        defb %11111111            
        defb %11111110            
        defb %11111100            
        defb %11111000            
        defb %11110000            
        defb %11100000            
        defb %11000000            
        defb %10000000            
;--------------------------
;; character 213
;;
        defb %11111111            
        defb %01111111            
        defb %00111111            
        defb %00011111            
        defb %00001111            
        defb %00000111            
        defb %00000011            
        defb %00000001            
;--------------------------
;; character 214
;;
        defb %00000001            
        defb %00000011            
        defb %00000111            
        defb %00001111            
        defb %00011111            
        defb %00111111            
        defb %01111111            
        defb %11111111            
;--------------------------
;; character 215
;;
        defb %10000000            
        defb %11000000            
        defb %11100000            
        defb %11110000            
        defb %11111000            
        defb %11111100            
        defb %11111110            
        defb %11111111            
;--------------------------
;; character 216
;;
        defb %10101010            
        defb %01010101            
        defb %10101010            
        defb %01010101            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
;--------------------------
;; character 217
;;
        defb %00001010            
        defb %00000101            
        defb %00001010            
        defb %00000101            
        defb %00001010            
        defb %00000101            
        defb %00001010            
        defb %00000101            
;--------------------------
;; character 218
;;
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %00000000            
        defb %10101010            
        defb %01010101            
        defb %10101010            
        defb %01010101            
;--------------------------
;; character 219
;;
        defb %10100000            
        defb %01010000            
        defb %10100000            
        defb %01010000            
        defb %10100000            
        defb %01010000            
        defb %10100000            
        defb %01010000            
;--------------------------
;; character 220
;;
        defb %10101010            
        defb %01010100            
        defb %10101000            
        defb %01010000            
        defb %10100000            
        defb %01000000            
        defb %10000000            
        defb %00000000            
;--------------------------
;; character 221
;;
        defb %10101010            
        defb %01010101            
        defb %00101010            
        defb %00010101            
        defb %00001010            
        defb %00000101            
        defb %00000010            
        defb %00000001            
;--------------------------
;; character 222
;;
        defb %00000001            
        defb %00000010            
        defb %00000101            
        defb %00001010            
        defb %00010101            
        defb %00101010            
        defb %01010101            
        defb %10101010            
;--------------------------
;; character 223
;;
        defb %00000000            
        defb %10000000            
        defb %01000000            
        defb %10100000            
        defb %01010000            
        defb %10101000            
        defb %01010100            
        defb %10101010            
;--------------------------
;; character 224
;;
        defb %01111110            
        defb %11111111            
        defb %10011001            
        defb %11111111            
        defb %10111101            
        defb %11000011            
        defb %11111111            
        defb %01111110            
;--------------------------
;; character 225
;;
        defb %01111110            
        defb %11111111            
        defb %10011001            
        defb %11111111            
        defb %11000011            
        defb %10111101            
        defb %11111111            
        defb %01111110            
;--------------------------
;; character 226
;;
        defb %00111000            
        defb %00111000            
        defb %11111110            
        defb %11111110            
        defb %11111110            
        defb %00010000            
        defb %00111000            
        defb %00000000            
;--------------------------
;; character 227
;;
        defb %00010000            
        defb %00111000            
        defb %01111100            
        defb %11111110            
        defb %01111100            
        defb %00111000            
        defb %00010000            
        defb %00000000            
;--------------------------
;; character 228
;;
        defb %01101100            
        defb %11111110            
        defb %11111110            
        defb %11111110            
        defb %01111100            
        defb %00111000            
        defb %00010000            
        defb %00000000            
;--------------------------
;; character 229
;;
        defb %00010000            
        defb %00111000            
        defb %01111100            
        defb %11111110            
        defb %11111110            
        defb %00010000            
        defb %00111000            
        defb %00000000            
;--------------------------
;; character 230
;;
        defb %00000000            
        defb %00111100            
        defb %01100110            
        defb %11000011            
        defb %11000011            
        defb %01100110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 231
;;
        defb %00000000            
        defb %00111100            
        defb %01111110            
        defb %11111111            
        defb %11111111            
        defb %01111110            
        defb %00111100            
        defb %00000000            
;--------------------------
;; character 232
;;
        defb %00000000            
        defb %01111110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 233
;;
        defb %00000000            
        defb %01111110            
        defb %01111110            
        defb %01111110            
        defb %01111110            
        defb %01111110            
        defb %01111110            
        defb %00000000            
;--------------------------
;; character 234
;;
        defb %00001111            
        defb %00000111            
        defb %00001101            
        defb %01111000            
        defb %11001100            
        defb %11001100            
        defb %11001100            
        defb %01111000            
;--------------------------
;; character 235
;;
        defb %00111100            
        defb %01100110            
        defb %01100110            
        defb %01100110            
        defb %00111100            
        defb %00011000            
        defb %01111110            
        defb %00011000            
;--------------------------
;; character 236
;;
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00001100            
        defb %00111100            
        defb %01111100            
        defb %00111000            
;--------------------------
;; character 237
;;
        defb %00011000            
        defb %00011100            
        defb %00011110            
        defb %00011011            
        defb %00011000            
        defb %01111000            
        defb %11111000            
        defb %01110000            
;--------------------------
;; character 238
;;
        defb %10011001            
        defb %01011010            
        defb %00100100            
        defb %11000011            
        defb %11000011            
        defb %00100100            
        defb %01011010            
        defb %10011001            
;--------------------------
;; character 239
;;
        defb %00010000            
        defb %00111000            
        defb %00111000            
        defb %00111000            
        defb %00111000            
        defb %00111000            
        defb %01111100            
        defb %11010110            
;--------------------------
;; character 240
;;
        defb %00011000            
        defb %00111100            
        defb %01111110            
        defb %11111111            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
;--------------------------
;; character 241
;;
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %00011000            
        defb %11111111            
        defb %01111110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 242
;;
        defb %00010000            
        defb %00110000            
        defb %01110000            
        defb %11111111            
        defb %11111111            
        defb %01110000            
        defb %00110000            
        defb %00010000            
;--------------------------
;; character 243
;;
        defb %00001000            
        defb %00001100            
        defb %00001110            
        defb %11111111            
        defb %11111111            
        defb %00001110            
        defb %00001100            
        defb %00001000            
;--------------------------
;; character 244
;;
        defb %00000000            
        defb %00000000            
        defb %00011000            
        defb %00111100            
        defb %01111110            
        defb %11111111            
        defb %11111111            
        defb %00000000            
;--------------------------
;; character 245
;;
        defb %00000000            
        defb %00000000            
        defb %11111111            
        defb %11111111            
        defb %01111110            
        defb %00111100            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 246
;;
        defb %10000000            
        defb %11100000            
        defb %11111000            
        defb %11111110            
        defb %11111000            
        defb %11100000            
        defb %10000000            
        defb %00000000            
;--------------------------
;; character 247
;;
        defb %00000010            
        defb %00001110            
        defb %00111110            
        defb %11111110            
        defb %00111110            
        defb %00001110            
        defb %00000010            
        defb %00000000            
;--------------------------
;; character 248
;;
        defb %00111000            
        defb %00111000            
        defb %10010010            
        defb %01111100            
        defb %00010000            
        defb %00101000            
        defb %00101000            
        defb %00101000            
;--------------------------
;; character 249
;;
        defb %00111000            
        defb %00111000            
        defb %00010000            
        defb %11111110            
        defb %00010000            
        defb %00101000            
        defb %01000100            
        defb %10000010            
;--------------------------
;; character 250
;;
        defb %00111000            
        defb %00111000            
        defb %00010010            
        defb %01111100            
        defb %10010000            
        defb %00101000            
        defb %00100100            
        defb %00100010            
;--------------------------
;; character 251
;;
        defb %00111000            
        defb %00111000            
        defb %10010000            
        defb %01111100            
        defb %00010010            
        defb %00101000            
        defb %01001000            
        defb %10001000            
;--------------------------
;; character 252
;;
        defb %00000000            
        defb %00111100            
        defb %00011000            
        defb %00111100            
        defb %00111100            
        defb %00111100            
        defb %00011000            
        defb %00000000            
;--------------------------
;; character 253
;;
        defb %00111100            
        defb %11111111            
        defb %11111111            
        defb %00011000            
        defb %00001100            
        defb %00011000            
        defb %00110000            
        defb %00011000            
;--------------------------
;; character 254
;;
        defb %00011000            
        defb %00111100            
        defb %01111110            
        defb %00011000            
        defb %00011000            
        defb %01111110            
        defb %00111100            
        defb %00011000            
;--------------------------
;; character 255
;;
        defb %00000000            
        defb %00100100            
        defb %01100110            
        defb %11111111            
        defb %01100110            
        defb %00100100            
        defb %00000000            
        defb %00000000            
