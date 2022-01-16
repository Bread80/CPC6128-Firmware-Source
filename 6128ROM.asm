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
include "Includes/JumpblockHigh.asm"
include "Includes/JumpblockIndirections.asm"
include "Includes/MemoryFirmware.asm"
        ld      bc,$7f89          ;{{0000:01897f}}  select mode 1, disable upper rom, enable lower rom		
        out     (c),c             ;{{0003:ed49}}  select mode and rom configuration
        jp      STARTUP_entry_point;{{0005:c39105}} 
;;+----------------------------------------------------------------
        jp      RST_1__LOW_LOW_JUMP;{{0008:c38ab9}}  RST 1 - LOW: LOW JUMP
;;+----------------------------------------------------------------
        jp      LOW_KL_LOW_PCHL   ;{{000b:c384b9}}  LOW: KL LOW PCHL
;;+----------------------------------------------------------------
        push    bc                ;{{000e:c5}}  LOW: PCBC INSTRUCTION
        ret                       ;{{000f:c9}} 
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
        jp      LOW_KL_FAR_PCHL   ;{{001b:c3b9b9}}  LOW: KL FAR PCHL
;;+----------------------------------------------------------------
;; LOW: PCHL INSTRUCTION
LOW_PCHL_INSTRUCTION:             ;{{Addr=$001e Code Calls/jump count: 2 Data use count: 0}}
        jp      (hl)              ;{{001e:e9}}  LOW: PCHL INSTRUCTION
;;+----------------------------------------------------------------
        nop                       ;{{001f:00}} 
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
        nop                       ;{{002b:00}} 
;;+----------------------------------------------------------------     
;;do rst 6
do_rst_6:                         ;{{Addr=$002c Code Calls/jump count: 1 Data use count: 0}}
        out     (c),c             ;{{002c:ed49}} 
        exx                       ;{{002e:d9}} 
        ei                        ;{{002f:fb}} 
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
        ret                       ;{{003b:c9}}  LOW: EXT INTERRUPT
        nop                       ;{{003c:00}} 
        nop                       ;{{003d:00}} 
        nop                       ;{{003e:00}} 
        nop                       ;{{003f:00}} 

;;==================================================================
;; END OF LOW KERNEL JUMPBLOCK
;;----------------------------------------------------------------------------------------

;This is a bit more the of the RST 6 code (see above)
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
        jr      nz,_setup_kernel_jumpblocks_1;{{004a:20fb}}  

;; initialise USER RESTART in LOW KERNEL jumpblock
        ld      a,$c7             ;{{004c:3ec7}} 
        ld      (RST_6__LOW_USER_RESTART),a;{{004e:323000}} ;WARNING: Code area used as literal

;; Setup HIGH KERNEL jumpblock

        ld      hl,START_OF_DATA_COPIED_TO_HI_JUMPBLOCK;{{0051:21a603}}  copy high kernel jumpblock ##LABEL## ##NOOFFSET##
        ld      de,KL_U_ROM_ENABLE;{{0054:1100b9}} 
        ld      bc,$01e4          ;{{0057:01e401}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{005a:edb0}} 

;;==========================================================================
;; KL CHOKE OFF

KL_CHOKE_OFF:                     ;{{Addr=$005c Code Calls/jump count: 1 Data use count: 1}}
        di                        ;{{005c:f3}} 
        ld      a,(foreground_ROM_select_address_);{{005d:3ad9b8}} 
        ld      de,(entry_point_of_foreground_ROM_in_use_);{{0060:ed5bd7b8}} 
        ld      b,$cd             ;{{0064:06cd}} 
        ld      hl,RAM_b82d       ;{{0066:212db8}} 
_kl_choke_off_5:                  ;{{Addr=$0069 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0069:3600}} 
        inc     hl                ;{{006b:23}} 
        djnz    _kl_choke_off_5   ;{{006c:10fb}}  (-&05)
        ld      b,a               ;{{006e:47}} 
        ld      c,$ff             ;{{006f:0eff}} 
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
        jr      nz,_start_basic_or_program_6;{{007a:2004}}  HL=0?

;; yes, HL = 0
        ld      a,l               ;{{007c:7d}}  A = 0 (BASIC)
        ld      hl,$c006          ;{{007d:2106c0}}  execution address for BASIC

;; A = rom select 
;; HL = address to start
_start_basic_or_program_6:        ;{{Addr=$0080 Code Calls/jump count: 1 Data use count: 0}}
        ld      (Upper_ROM_status_),a;{{0080:32d6b8}} 
;; initialise three byte far address
        ld      (foreground_ROM_select_address_),a;{{0083:32d9b8}}  rom select byte
        ld      (entry_point_of_foreground_ROM_in_use_),hl;{{0086:22d7b8}}  address

        ld      hl,$abff          ;{{0089:21ffab}} last byte of free memory not used by BASIC.
        ld      de,END_OF_LOW_KERNEL_JUMPBLOCK;{{008c:114000}} start of free memory ##LABEL## 
        ld      bc,Last_byte_of_free_memory;{{008f:01ffb0}} last byte of free memory not used by firmware
        ld      sp,$c000          ;{{0092:3100c0}} 
        rst     $18               ;{{0095:df}}  RST 3 - LOW: FAR CALL
        defw entry_point_of_foreground_ROM_in_use_                
        rst     $00               ;{{0098:c7}}  RST 0 - LOW: RESET ENTRY

;;==========================================================================
;; KL TIME PLEASE

KL_TIME_PLEASE:                   ;{{Addr=$0099 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0099:f3}} 
        ld      de,($b8b6)        ;{{009a:ed5bb6b8}} 
        ld      hl,(TIME_)        ;{{009e:2ab4b8}} 
        ei                        ;{{00a1:fb}} 
        ret                       ;{{00a2:c9}} 

;;==========================================================================
;; KL TIME SET

KL_TIME_SET:                      ;{{Addr=$00a3 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{00a3:f3}} 
        xor     a                 ;{{00a4:af}} 
        ld      (RAM_b8b8),a      ;{{00a5:32b8b8}} 
        ld      ($b8b6),de        ;{{00a8:ed53b6b8}} 
        ld      (TIME_),hl        ;{{00ac:22b4b8}} 
        ei                        ;{{00af:fb}} 
        ret                       ;{{00b0:c9}} 

;;==========================================================================

;; update TIME
update_TIME:                      ;{{Addr=$00b1 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,TIME_          ;{{00b1:21b4b8}} 
_update_time_1:                   ;{{Addr=$00b4 Code Calls/jump count: 1 Data use count: 0}}
        inc     (hl)              ;{{00b4:34}} 
        inc     hl                ;{{00b5:23}} 
        jr      z,_update_time_1  ;{{00b6:28fc}}  (-&04)

;; test VSYNC state
        ld      b,$f5             ;{{00b8:06f5}} 
        in      a,(c)             ;{{00ba:ed78}} 
        rra                       ;{{00bc:1f}} 
        jr      nc,_update_time_12;{{00bd:3008}} 

;; VSYNC is set
        ld      hl,(RAM_b8b9)     ;{{00bf:2ab9b8}} ; FRAME FLY events
        ld      a,h               ;{{00c2:7c}} 
        or      a                 ;{{00c3:b7}} 
        call    nz,_queue_asynchronous_events_58;{{00c4:c45301}} 

_update_time_12:                  ;{{Addr=$00c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b8bb)     ;{{00c7:2abbb8}} ; FAST TICKER events
        ld      a,h               ;{{00ca:7c}} 
        or      a                 ;{{00cb:b7}} 
        call    nz,_queue_asynchronous_events_58;{{00cc:c45301}} 

        call    process_sound     ;{{00cf:cdd720}} ; process sound

        ld      hl,Keyboard_scan_flag_;{{00d2:21bfb8}} ; keyboard scan interrupt counter
        dec     (hl)              ;{{00d5:35}} 
        ret     nz                ;{{00d6:c0}} 

        ld      (hl),$06          ;{{00d7:3606}} ; reset keyboard scan interrupt counter

        call    KM_SCAN_KEYS      ;{{00d9:cdf4bd}}  IND: KM SCAN KEYS

        ld      hl,(address_of_the_first_ticker_block_in_cha);{{00dc:2abdb8}}  ticker list
        ld      a,h               ;{{00df:7c}} 
        or      a                 ;{{00e0:b7}} 
        ret     z                 ;{{00e1:c8}} 

        ld      hl,RAM_b831       ;{{00e2:2131b8}}  indicate there are some ticker events to process?
        set     0,(hl)            ;{{00e5:cbc6}} 
        ret                       ;{{00e7:c9}} 

;;========================================================
;; Queue asynchronous events
;; these two are for queuing up normal Asynchronous events to be processed after all others

;; normal event 
Queue_asynchronous_events:        ;{{Addr=$00e8 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{00e8:2b}} 
        ld      (hl),$00          ;{{00e9:3600}} 
        dec     hl                ;{{00eb:2b}} 
;; has list been setup?
        ld      a,(RAM_b82e)      ;{{00ec:3a2eb8}} 
        or      a                 ;{{00ef:b7}} 
        jr      nz,_queue_asynchronous_events_11;{{00f0:200c}}  (+&0c)
;; add to start of list
        ld      (RAM_b82d),hl     ;{{00f2:222db8}} 
        ld      (RAM_b82f),hl     ;{{00f5:222fb8}} 
;; signal normal event list setup
        ld      hl,RAM_b831       ;{{00f8:2131b8}} 
        set     6,(hl)            ;{{00fb:cbf6}} 
        ret                       ;{{00fd:c9}} 

;; add another event to 
_queue_asynchronous_events_11:    ;{{Addr=$00fe Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(RAM_b82f)     ;{{00fe:ed5b2fb8}} 
        ld      (RAM_b82f),hl     ;{{0102:222fb8}} 
        ex      de,hl             ;{{0105:eb}} 
        ld      (hl),e            ;{{0106:73}} 
        inc     hl                ;{{0107:23}} 
        ld      (hl),d            ;{{0108:72}} 
        ret                       ;{{0109:c9}} 

;;---------------------------------------------------
;; Queue synchronous event??
_queue_asynchronous_events_18:    ;{{Addr=$010a Code Calls/jump count: 1 Data use count: 0}}
        ld      (temporary_store_for_stack_pointer_),sp;{{010a:ed7332b8}} 
        ld      sp,TIME_          ;{{010e:31b4b8}} 
        push    hl                ;{{0111:e5}} 
        push    de                ;{{0112:d5}} 
        push    bc                ;{{0113:c5}} 
;; normal event has been setup?
        ld      hl,RAM_b831       ;{{0114:2131b8}} 
        bit     6,(hl)            ;{{0117:cb76}} 
        jr      z,_queue_asynchronous_events_42;{{0119:281e}}  (+&1e)

_queue_asynchronous_events_26:    ;{{Addr=$011b Code Calls/jump count: 1 Data use count: 0}}
        set     7,(hl)            ;{{011b:cbfe}} 
_queue_asynchronous_events_27:    ;{{Addr=$011d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b82d)     ;{{011d:2a2db8}} 
        ld      a,h               ;{{0120:7c}} 
        or      a                 ;{{0121:b7}} 
        jr      z,_queue_asynchronous_events_39;{{0122:280e}}  (+&0e)
        ld      e,(hl)            ;{{0124:5e}} 
        inc     hl                ;{{0125:23}} 
        ld      d,(hl)            ;{{0126:56}} 
        ld      (RAM_b82d),de     ;{{0127:ed532db8}} 
        inc     hl                ;{{012b:23}} 
        call    _kl_event_29      ;{{012c:cd0902}}  execute event function
        di                        ;{{012f:f3}} 
        jr      _queue_asynchronous_events_27;{{0130:18eb}}  (-&15)

;;---------------------------------------------------
_queue_asynchronous_events_39:    ;{{Addr=$0132 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_b831       ;{{0132:2131b8}} 
        bit     0,(hl)            ;{{0135:cb46}} 
        jr      z,_queue_asynchronous_events_52;{{0137:2810}}  (+&10)
_queue_asynchronous_events_42:    ;{{Addr=$0139 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0139:3600}} 
        scf                       ;{{013b:37}} 
        ex      af,af'            ;{{013c:08}} 
        call    Execute_ticker    ;{{013d:cd8901}} ; execute ticker
        or      a                 ;{{0140:b7}} 
        ex      af,af'            ;{{0141:08}} 
        ld      hl,RAM_b831       ;{{0142:2131b8}} 
        ld      a,(hl)            ;{{0145:7e}} 
        or      a                 ;{{0146:b7}} 
        jr      nz,_queue_asynchronous_events_26;{{0147:20d2}}  (-&2e)
_queue_asynchronous_events_52:    ;{{Addr=$0149 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{0149:3600}} 
        pop     bc                ;{{014b:c1}} 
        pop     de                ;{{014c:d1}} 
        pop     hl                ;{{014d:e1}} 
        ld      sp,(temporary_store_for_stack_pointer_);{{014e:ed7b32b8}} 
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

        ld      d,a               ;{{015b:57}} 
        push    de                ;{{015c:d5}} 
        call    KL_EVENT          ;{{015d:cde201}}  KL EVENT
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
        ld      de,RAM_b8b9       ;{{016a:11b9b8}} 
        jp      add_event_to_an_event_list;{{016d:c37903}} ; add event to list

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
        pop     hl                ;{{017c:e1}} 

;;==========================================================================
;; KL ADD FAST TICKER

;; HL = address of event block
KL_ADD_FAST_TICKER:               ;{{Addr=$017d Code Calls/jump count: 0 Data use count: 1}}
        ld      de,RAM_b8bb       ;{{017d:11bbb8}} 
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
        ld      a,h               ;{{018c:7c}} 
        or      a                 ;{{018d:b7}} 
        ret     z                 ;{{018e:c8}} 

        ld      e,(hl)            ;{{018f:5e}} 
        inc     hl                ;{{0190:23}} 
        ld      d,(hl)            ;{{0191:56}} 
        inc     hl                ;{{0192:23}} 
        ld      c,(hl)            ;{{0193:4e}} 
        inc     hl                ;{{0194:23}} 
        ld      b,(hl)            ;{{0195:46}} 
        ld      a,b               ;{{0196:78}} 
        or      c                 ;{{0197:b1}} 
        jr      z,_execute_ticker_33;{{0198:2816}}  (+&16)
        dec     bc                ;{{019a:0b}} 
        ld      a,b               ;{{019b:78}} 
        or      c                 ;{{019c:b1}} 
        jr      nz,_execute_ticker_30;{{019d:200e}}  (+&0e)
        push    de                ;{{019f:d5}} 
        inc     hl                ;{{01a0:23}} 
        inc     hl                ;{{01a1:23}} 
        push    hl                ;{{01a2:e5}} 
        inc     hl                ;{{01a3:23}} 
        call    KL_EVENT          ;{{01a4:cde201}}  KL EVENT
        pop     hl                ;{{01a7:e1}} 
        ld      b,(hl)            ;{{01a8:46}} 
        dec     hl                ;{{01a9:2b}} 
        ld      c,(hl)            ;{{01aa:4e}} 
        dec     hl                ;{{01ab:2b}} 
        pop     de                ;{{01ac:d1}} 
_execute_ticker_30:               ;{{Addr=$01ad Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),b            ;{{01ad:70}} 
        dec     hl                ;{{01ae:2b}} 
        ld      (hl),c            ;{{01af:71}} 
_execute_ticker_33:               ;{{Addr=$01b0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{01b0:eb}} 
        jr      _execute_ticker_1 ;{{01b1:18d9}}  (-&27)

;;==========================================================================
;; KL ADD TICKER
;; HL = event b lock
;; DE = initial value for counter
;; BC = reset count

KL_ADD_TICKER:                    ;{{Addr=$01b3 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{01b3:e5}} 
        inc     hl                ;{{01b4:23}} 
        inc     hl                ;{{01b5:23}} 
        di                        ;{{01b6:f3}} 
        ld      (hl),e            ;{{01b7:73}} ; initial counter
        inc     hl                ;{{01b8:23}} 
        ld      (hl),d            ;{{01b9:72}} 
        inc     hl                ;{{01ba:23}} 
        ld      (hl),c            ;{{01bb:71}} ; reset count
        inc     hl                ;{{01bc:23}} 
        ld      (hl),b            ;{{01bd:70}} 
        pop     hl                ;{{01be:e1}} 
        ld      de,address_of_the_first_ticker_block_in_cha;{{01bf:11bdb8}} ; ticker list
        jp      add_event_to_an_event_list;{{01c2:c37903}} ; add event to list

;;==========================================================================
;; KL DEL TICKER

KL_DEL_TICKER:                    ;{{Addr=$01c5 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,address_of_the_first_ticker_block_in_cha;{{01c5:11bdb8}} 
        call    delete_event_from_list;{{01c8:cd8803}}  remove event from list
        ret     nc                ;{{01cb:d0}} 

        ex      de,hl             ;{{01cc:eb}} 
        inc     hl                ;{{01cd:23}} 
        ld      e,(hl)            ;{{01ce:5e}} 
        inc     hl                ;{{01cf:23}} 
        ld      d,(hl)            ;{{01d0:56}} 
        ret                       ;{{01d1:c9}} 

;;==========================================================================
;; KL INIT EVENT

KL_INIT_EVENT:                    ;{{Addr=$01d2 Code Calls/jump count: 4 Data use count: 1}}
        di                        ;{{01d2:f3}} 
        inc     hl                ;{{01d3:23}} 
        inc     hl                ;{{01d4:23}} 
        ld      (hl),$00          ;{{01d5:3600}} ; tick count
        inc     hl                ;{{01d7:23}} 
        ld      (hl),b            ;{{01d8:70}} ; class
        inc     hl                ;{{01d9:23}} 
        ld      (hl),e            ;{{01da:73}} ; routine
        inc     hl                ;{{01db:23}} 
        ld      (hl),d            ;{{01dc:72}} 
        inc     hl                ;{{01dd:23}} 
        ld      (hl),c            ;{{01de:71}} ; rom
        inc     hl                ;{{01df:23}} 
        ei                        ;{{01e0:fb}} 
        ret                       ;{{01e1:c9}} 

;;==========================================================================
;; KL EVENT
;;
;; perform event
;; DE = address of next in chain
;; HL = address of current event

KL_EVENT:                         ;{{Addr=$01e2 Code Calls/jump count: 7 Data use count: 1}}
        inc     hl                ;{{01e2:23}} 
        inc     hl                ;{{01e3:23}} 
        di                        ;{{01e4:f3}} 
        ld      a,(hl)            ;{{01e5:7e}} ; count
        inc     (hl)              ;{{01e6:34}} 
        jp      m,_kl_event_22    ;{{01e7:fa0102}} ; update count 

        or      a                 ;{{01ea:b7}} 
        jr      nz,_kl_event_23   ;{{01eb:2015}}  (+&15)

        inc     hl                ;{{01ed:23}} 
        ld      a,(hl)            ;{{01ee:7e}}  class
        dec     hl                ;{{01ef:2b}} 
        or      a                 ;{{01f0:b7}} 
        jp      p,Synchronous_Event;{{01f1:f22e02}}  -ve (bit = 1) = Asynchronous, +ve (bit = 0) = synchronous

;; Asynchronous
        ex      af,af'            ;{{01f4:08}} 
        jr      nc,_kl_event_28   ;{{01f5:3011}} 
        ex      af,af'            ;{{01f7:08}} 

        add     a,a               ;{{01f8:87}}  express = -ve (bit = 1), normal = +ve (bit = 0)
        jp      p,Queue_asynchronous_events;{{01f9:f2e800}}  add to normal list

;; Asynchronous Express
        dec     (hl)              ;{{01fc:35}}  indicate it needs processing
        inc     hl                ;{{01fd:23}} 
        inc     hl                ;{{01fe:23}} 
                                  ; HL = routine address
        jr      _kl_do_sync_7     ;{{01ff:1821}}  execute event

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
        ld      a,(hl)            ;{{020a:7e}} 
        dec     a                 ;{{020b:3d}} 
        ret     m                 ;{{020c:f8}} 

_kl_event_33:                     ;{{Addr=$020d Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{020d:e5}} 
        call    _kl_do_sync_2     ;{{020e:cd1b02}}  part of KL DO SYNC
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
        inc     hl                ;{{021a:23}} 
_kl_do_sync_2:                    ;{{Addr=$021b Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{021b:23}} 

;; near or far address?
        ld      a,(hl)            ;{{021c:7e}} 
        inc     hl                ;{{021d:23}} 
        rra                       ;{{021e:1f}} 
        jp      nc,LOW_KL_FAR_ICALL;{{021f:d2c1b9}} 	 LOW: KL FAR ICALL

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
        ld      (High_byte_of_above_Address_of_the_first),hl;{{022a:22c1b8}} 
        ret                       ;{{022d:c9}} 

;;==========================================================================
;; Synchronous Event
Synchronous_Event:                ;{{Addr=$022e Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{022e:e5}} 
        ld      b,a               ;{{022f:47}} 
        ld      de,buffer_for_last_RSX_or_RSX_command_name_;{{0230:11c3b8}} 
_synchronous_event_3:             ;{{Addr=$0233 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{0233:eb}} 

        dec     hl                ;{{0234:2b}} 
        dec     hl                ;{{0235:2b}} 
        ld      d,(hl)            ;{{0236:56}} 
        dec     hl                ;{{0237:2b}} 
        ld      e,(hl)            ;{{0238:5e}} 
        ld      a,d               ;{{0239:7a}} 
        or      a                 ;{{023a:b7}} 
        jr      z,_synchronous_event_18;{{023b:2807}}  (+&07)

        inc     de                ;{{023d:13}}  count
        inc     de                ;{{023e:13}}  class
        inc     de                ;{{023f:13}} 
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
        ld      (hl),d            ;{{024a:72}} 
        dec     hl                ;{{024b:2b}} 
        ld      a,(hl)            ;{{024c:7e}} 
        ld      (de),a            ;{{024d:12}} 
        ld      (hl),e            ;{{024e:73}} 
        ex      af,af'            ;{{024f:08}} 
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
        or      a                 ;{{025a:b7}} 
        jr      z,_kl_next_sync_20;{{025b:2817}}  (+&17)
        push    hl                ;{{025d:e5}} 
        ld      e,(hl)            ;{{025e:5e}} 
        inc     hl                ;{{025f:23}} 
        ld      d,(hl)            ;{{0260:56}} 
        inc     hl                ;{{0261:23}} 
        inc     hl                ;{{0262:23}} 
        ld      a,(RAM_b8c2)      ;{{0263:3ac2b8}} 
        cp      (hl)              ;{{0266:be}} 
        jr      nc,_kl_next_sync_19;{{0267:300a}}  (+&0a)
        push    af                ;{{0269:f5}} 
        ld      a,(hl)            ;{{026a:7e}} 
        ld      (RAM_b8c2),a      ;{{026b:32c2b8}} 
        ld      (address_of_the_first_event_block_in_chai),de;{{026e:ed53c0b8}}  synchronous event list
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
        inc     hl                ;{{027a:23}} 
        dec     (hl)              ;{{027b:35}} 
        ret     z                 ;{{027c:c8}} 

        di                        ;{{027d:f3}} 
        jp      p,Synchronous_Event;{{027e:f22e02}} ; Synchronous event
        inc     (hl)              ;{{0281:34}} 
        ei                        ;{{0282:fb}} 
        ret                       ;{{0283:c9}} 

;;==========================================================================
;; KL DEL SYNCHRONOUS

KL_DEL_SYNCHRONOUS:               ;{{Addr=$0284 Code Calls/jump count: 1 Data use count: 1}}
        call    KL_DISARM_EVENT   ;{{0284:cd8d02}}  KL DISARM EVENT
        ld      de,address_of_the_first_event_block_in_chai;{{0287:11c0b8}}  synchronouse event list
        jp      delete_event_from_list;{{028a:c38803}}  remove event from list

;;==========================================================================
;; KL DISARM EVENT

KL_DISARM_EVENT:                  ;{{Addr=$028d Code Calls/jump count: 1 Data use count: 1}}
        inc     hl                ;{{028d:23}} 
        inc     hl                ;{{028e:23}} 
        ld      (hl),$c0          ;{{028f:36c0}} 
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
        ld      hl,RAM_b8c2       ;{{029a:21c2b8}} 
        res     5,(hl)            ;{{029d:cbae}} 
        ret                       ;{{029f:c9}} 

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
        push    hl                ;{{02a0:e5}} 
        ld      de,(address_of_first_ROM_or_RSX_chaining_blo);{{02a1:ed5bd3b8}} ; get head of the list
        ld      (address_of_first_ROM_or_RSX_chaining_blo),hl;{{02a5:22d3b8}} ; set new head of the list
        ld      (hl),e            ;{{02a8:73}} ; previous | command registered with KL LOG EXT or 0 if end of list
        inc     hl                ;{{02a9:23}} 
        ld      (hl),d            ;{{02aa:72}} 
        inc     hl                ;{{02ab:23}} 
        ld      (hl),c            ;{{02ac:71}} ; address of RSX's command table
        inc     hl                ;{{02ad:23}} 
        ld      (hl),b            ;{{02ae:70}} 
        pop     hl                ;{{02af:e1}} 
        ret                       ;{{02b0:c9}} 

;;==========================================================================
;; KL FIND COMMAND
;; HL = address of command name to be found.

;; NOTES: 
;; - last char must have bit 7 set to indicate the end of the string.
;; - up to 16 characters is compared. Name can be any length but first 16 characters must be unique.

KL_FIND_COMMAND:                  ;{{Addr=$02b1 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,buffer_for_last_RSX_or_RSX_command_name_;{{02b1:11c3b8}} ; destination
        ld      bc,$0010          ;{{02b4:011000}} ; length ##LIT##;WARNING: Code area used as literal
        call    HI_KL_LDIR        ;{{02b7:cda1ba}} ; HI: KL LDIR (disable upper and lower roms and perform LDIR)

;; ensure last character has bit 7 set (indicates end of string, where length of name is longer
;; than 16 characters). If name is less than 16 characters the last char will have bit 7 set anyway.
        ex      de,hl             ;{{02ba:eb}} 
        dec     hl                ;{{02bb:2b}} 
        set     7,(hl)            ;{{02bc:cbfe}} 

        ld      hl,(address_of_first_ROM_or_RSX_chaining_blo);{{02be:2ad3b8}}  points to commands registered with KL LOG EXT
        ld      a,l               ;{{02c1:7d}}  preload lower byte of address into A for comparison
        jr      _kl_find_command_23;{{02c2:1810}} 

;; search for more | commands registered with KL LOG EXT
_kl_find_command_9:               ;{{Addr=$02c4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{02c4:e5}} 
        inc     hl                ;{{02c5:23}}  skip pointer to next registered RSX
        inc     hl                ;{{02c6:23}} 
        ld      c,(hl)            ;{{02c7:4e}}  fetch address of RSX table
        inc     hl                ;{{02c8:23}} 
        ld      b,(hl)            ;{{02c9:46}} 
        call    search_for_RSX_in_commandtable;{{02ca:cdf102}}  search for command
        pop     de                ;{{02cd:d1}} 
        ret     c                 ;{{02ce:d8}} 

        ex      de,hl             ;{{02cf:eb}} 
        ld      a,(hl)            ;{{02d0:7e}}  get address of next registered RSX
        inc     hl                ;{{02d1:23}} 
        ld      h,(hl)            ;{{02d2:66}} 
        ld      l,a               ;{{02d3:6f}} 

_kl_find_command_23:              ;{{Addr=$02d4 Code Calls/jump count: 1 Data use count: 0}}
        or      h                 ;{{02d4:b4}}  if HL is zero, then this is the end of the list.
        jr      nz,_kl_find_command_9;{{02d5:20ed}}  loop if we didn't get to the end of the list


        ld      c,$ff             ;{{02d7:0eff}} 
_kl_find_command_26:              ;{{Addr=$02d9 Code Calls/jump count: 2 Data use count: 0}}
        inc     c                 ;{{02d9:0c}} 
;; C = ROM select address of ROM to probe
        call    HI_KL_PROBE_ROM   ;{{02da:cd7eba}} ; HI: KL PROBE ROM
;; A = ROM's class.
;; 0 = Foreground
;; 1 = Background
;; 2 = Extension foreground ROM
        push    af                ;{{02dd:f5}} 
        and     $03               ;{{02de:e603}} 
        ld      b,a               ;{{02e0:47}} 
        call    z,search_for_RSX_in_commandtable;{{02e1:ccf102}}  search for command

        call    c,MC_START_PROGRAM;{{02e4:dc1c06}}  MC START PROGRAM
        pop     af                ;{{02e7:f1}} 
        add     a,a               ;{{02e8:87}} 
        jr      nc,_kl_find_command_26;{{02e9:30ee}}  (-&12)
        ld      a,c               ;{{02eb:79}} 
        cp      $10               ;{{02ec:fe10}}  maximum rom selection scanned by firmware
        jr      c,_kl_find_command_26;{{02ee:38e9}}  (-&17)
        ret                       ;{{02f0:c9}} 

;;========================================================
;; search for RSX in command-table.
;; EIther RSX in RAM or RSX in ROM.

;; HL = address of command-table in ROM
search_for_RSX_in_commandtable:   ;{{Addr=$02f1 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$c004          ;{{02f1:2104c0}} 

;;B=0 for RSX in ROM, B!=0 for RSX in RAM
;; This also means that ROM class must be foreground.
        ld      a,b               ;{{02f4:78}} 
        or      a                 ;{{02f5:b7}} 
        jr      z,_search_for_rsx_in_commandtable_7;{{02f6:2804}} 

;; HL = address of RSX table
        ld      h,b               ;{{02f8:60}} 
        ld      l,c               ;{{02f9:69}} 
;; "ROM select" for RAM 
        ld      c,$ff             ;{{02fa:0eff}} 

;; C = ROM select address
_search_for_rsx_in_commandtable_7:;{{Addr=$02fc Code Calls/jump count: 1 Data use count: 0}}
        call    HI_KL_ROM_SELECT  ;{{02fc:cd79ba}} ; HI: KL ROM SELECT
;; C contains the ROM select address of the previously selected ROM.
;; B contains the previous ROM state
;; preserve previous rom selection and rom state
        push    bc                ;{{02ff:c5}} 

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
        ld      a,(bc)            ;{{030a:0a}} 
        cp      (hl)              ;{{030b:be}} 
        jr      nz,_search_for_rsx_in_commandtable_25;{{030c:2008}}  (+&08)
        inc     hl                ;{{030e:23}} 
        inc     bc                ;{{030f:03}} 
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
        inc     de                ;{{031b:13}} 
        inc     de                ;{{031c:13}} 
        inc     de                ;{{031d:13}} 

;; 0 indicates end of list.
_search_for_rsx_in_commandtable_32:;{{Addr=$031e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{031e:7e}} 
        or      a                 ;{{031f:b7}} 
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
        dec     c                 ;{{032b:0d}} 
        jp      p,_kl_rom_walk_1  ;{{032c:f22803}} 
        ret                       ;{{032f:c9}} 

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
        ld      a,($c000)         ;{{033c:3a00c0}} get ROM class. 1=background ROM
                                  ;NOTE: if no ROM at this address then we'll get ROM 0 (BASIC)
                                  ;which isn't a background ROM
        and     $03               ;{{033f:e603}} 
        dec     a                 ;{{0341:3d}} 
        jr      nz,_kl_init_back_32;{{0342:2022}}  (+&22) i=Ignore if not background ROM
        push    bc                ;{{0344:c5}} 
        scf                       ;{{0345:37}} 
        call    $c006             ;{{0346:cd06c0}} Call ROM init routine (standard address)
        jr      nc,_kl_init_back_31;{{0349:301a}}  (+&1a) ROM didn't request a data area? Or has no RSXs?

        push    de                ;{{034b:d5}} DE = address of ROMs data area (adjusted by ROM init routine)
        inc     hl                ;{{034c:23}} 
        ex      de,hl             ;{{034d:eb}} 
        ld      hl,Background_ROM_data_address_table;{{034e:21dab8}} 
        ld      bc,(Upper_ROM_status_);{{0351:ed4bd6b8}} C=ROM number
        ld      b,$00             ;{{0355:0600}} 
        add     hl,bc             ;{{0357:09}} Calc address in ROM table
        add     hl,bc             ;{{0358:09}} 
        ld      (hl),e            ;{{0359:73}} Store DE into table entry
        inc     hl                ;{{035a:23}} 
        ld      (hl),d            ;{{035b:72}} 
        ld      hl,$fffc          ;{{035c:21fcff}} 
        add     hl,de             ;{{035f:19}} DE=DE-4 - reserve bytes for RSX linked list??
        call    KL_LOG_EXT        ;{{0360:cda002}}  KL LOG EXT - log the RSXs in the ROM
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
        cp      e                 ;{{036a:bb}} 
        inc     hl                ;{{036b:23}} 
        ld      a,(hl)            ;{{036c:7e}} 
        dec     hl                ;{{036d:2b}} 
        jr      nz,_find_event_in_list_9;{{036e:2003}}  (+&03)
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
        di                        ;{{037a:f3}} 
        call    find_event_in_list;{{037b:cd6903}} ; find event in list
        jr      c,_add_event_to_an_event_list_10;{{037e:3806}}  event found
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
        call    find_event_in_list;{{038a:cd6903}} ; find event in list
        jr      nc,_delete_event_from_list_10;{{038d:3006}}  (+&06)
        ld      a,(de)            ;{{038f:1a}} 
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
; Change RAM bank setting
;;
;; A = new configuration (0-31)
;;
;; Allows any configuration to be used, so compatible with ALL Dk'Tronics RAM sizes.

KL_BANK_SWITCH_:                  ;{{Addr=$0397 Code Calls/jump count: 0 Data use count: 1}}
        di                        ;{{0397:f3}} 
        exx                       ;{{0398:d9}} 
        ld      hl,RAM_bank_number;{{0399:21d5b8}}  current bank selection
        ld      d,(hl)            ;{{039c:56}}  get previous
        ld      (hl),a            ;{{039d:77}}  set new
        or      $c0               ;{{039e:f6c0}}  bit 7 = 1, bit 6 = 1, selection in lower bits.
        out     (c),a             ;{{03a0:ed79}} 
        ld      a,d               ;{{03a2:7a}}  previous bank selection
        exx                       ;{{03a3:d9}} 
        ei                        ;{{03a4:fb}} 
        ret                       ;{{03a5:c9}} 




;;***HighJumpblock.asm
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
        out     (c),c             ;{{059a:ed49}} 

        ld      bc,$f600          ;{{059c:0100f6}} ; initialise PPI port C data 
                                  ;; - select keyboard line 0
                                  ;; - PSG control inactive
                                  ;; - cassette motor off
                                  ;; - cassette write data "0"
        out     (c),c             ;{{059f:ed49}} ; set PPI port C data

        ld      bc,$ef7f          ;{{05a1:017fef}} 
        out     (c),c             ;{{05a4:ed49}} 

        ld      b,$f5             ;{{05a6:06f5}} ; PPI port B inputs
        in      a,(c)             ;{{05a8:ed78}} Bits 4..1 are factory set links for (sales) region
        and     $10               ;{{05aa:e610}} bit4 = 50/60Hz config (60Hz if installed)
        ld      hl,_startup_entry_point_26;{{05ac:21d505}} ; **end** of CRTC data for 50Hz display
        jr      nz,_startup_entry_point_15;{{05af:2003}} 
        ld      hl,_startup_entry_point_27;{{05b1:21e505}} ; **end** of CRTC data for 60Hz display ##LABEL##

;; initialise display
;; starting with register 15, then down to 0
_startup_entry_point_15:          ;{{Addr=$05b4 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$bc0f          ;{{05b4:010fbc}} 
_startup_entry_point_16:          ;{{Addr=$05b7 Code Calls/jump count: 1 Data use count: 0}}
        out     (c),c             ;{{05b7:ed49}}  select CRTC register
        dec     hl                ;{{05b9:2b}} 
        ld      a,(hl)            ;{{05ba:7e}}  get data from table 
        inc     b                 ;{{05bb:04}} 
        out     (c),a             ;{{05bc:ed79}}  write data to selected CRTC register
        dec     b                 ;{{05be:05}} 
        dec     c                 ;{{05bf:0d}} 
        jp      p,_startup_entry_point_16;{{05c0:f2b705}} 

;; continue with setup...
        jr      _startup_entry_point_27;{{05c3:1820}}  (+&20)

;; CRTC data for 50Hz display
        defb $3f, $28, $2e, $8e, $26, $00, $19, $1e, $00, $07, $00,$00,$30,$00,$c0,$00
;; CRTC data for 60Hz display
_startup_entry_point_26:          ;{{Addr=$05d5 Data Calls/jump count: 0 Data use count: 1}}
        defb $3f, $28, $2e, $8e, $1f, $06, $19, $1b, $00, $07, $00,$00,$30,$00,$c0,$00

;;-------------------------------------------------------
;; continue with setup...

_startup_entry_point_27:          ;{{Addr=$05e5 Code Calls/jump count: 1 Data use count: 1}}
        ld      de,display_boot_message;{{05e5:117706}}  this is executed by execution address ##LABEL##
        ld      hl,$0000          ;{{05e8:210000}}  this will force MC START PROGRAM to start BASIC ##LIT##;WARNING: Code area used as literal
        jr      _mc_start_program_1;{{05eb:1832}}  mc start program

;;========================================================
;; MC BOOT PROGRAM
;; 
;; HL = execute address

MC_BOOT_PROGRAM:                  ;{{Addr=$05ed Code Calls/jump count: 0 Data use count: 1}}
        ld      sp,$c000          ;{{05ed:3100c0}} 
        push    hl                ;{{05f0:e5}} 
        call    SOUND_RESET       ;{{05f1:cde91f}} ; SOUND RESET
        di                        ;{{05f4:f3}} 

        ld      bc,$f8ff          ;{{05f5:01fff8}} ; reset all peripherals
        out     (c),c             ;{{05f8:ed49}} 

        call    KL_CHOKE_OFF      ;{{05fa:cd5c00}} ; KL CHOKE OFF
        pop     hl                ;{{05fd:e1}} 
        push    de                ;{{05fe:d5}} 
        push    bc                ;{{05ff:c5}} 
        push    hl                ;{{0600:e5}} 
        call    KM_RESET          ;{{0601:cd981b}} ; KM RESET
        call    TXT_RESET         ;{{0604:cd8410}} ; TXT RESET
        call    SCR_RESET         ;{{0607:cdd00a}} ; SCR RESET
        call    HI_KL_U_ROM_ENABLE;{{060a:cd5fba}} ; HI: KL U ROM ENABLE
        pop     hl                ;{{060d:e1}} 
        call    LOW_PCHL_INSTRUCTION;{{060e:cd1e00}} ; LOW: PCHL INSTRUCTION
        pop     bc                ;{{0611:c1}} 
        pop     de                ;{{0612:d1}} 
        jr      c,MC_START_PROGRAM;{{0613:3807}}  MC START PROGRAM


;; display program load failed message
        ex      de,hl             ;{{0615:eb}} 
        ld      c,b               ;{{0616:48}} 
        ld      de,_boot_message_1;{{0617:11f906}}  program load failed ##LABEL##
        jr      _mc_start_program_1;{{061a:1803}}  

;;=========================================================
;; MC START PROGRAM
;; HL = entry address, or zero to start the default ROM
;; DE = address of code to run prior to program to (e.g) display system boot message
;; C = rom select (unless HL==0)

MC_START_PROGRAM:                 ;{{Addr=$061c Code Calls/jump count: 2 Data use count: 1}}
        ld      de,_get_a_pointer_to_the_machine_name_13;{{061c:113707}}  RET (no message) ##LABEL##
                                  ; this is executed by: LOW: PCHL INSTRUCTION

;;---------------------------------------------------------

_mc_start_program_1:              ;{{Addr=$061f Code Calls/jump count: 2 Data use count: 0}}
        di                        ;{{061f:f3}}  disable interrupts
        im      1                 ;{{0620:ed56}}  Z80 interrupt mode 1
        exx                       ;{{0622:d9}} 

        ld      bc,$df00          ;{{0623:0100df}}  select upper ROM 0
        out     (c),c             ;{{0626:ed49}} 

        ld      bc,$f8ff          ;{{0628:01fff8}}  reset all peripherals
        out     (c),c             ;{{062b:ed49}} 

        ld      bc,$7fc0          ;{{062d:01c07f}}  select ram configuration 0
        out     (c),c             ;{{0630:ed49}} 

        ld      bc,$fa7e          ;{{0632:017efa}}  stop disc motor
        xor     a                 ;{{0635:af}} 
        out     (c),a             ;{{0636:ed79}} 

        ld      hl,Last_byte_of_free_memory + 1;{{0638:2100b1}}  clear memory block which will hold 
        ld      de,Last_byte_of_free_memory + 2;{{063b:1101b1}}  firmware jumpblock
        ld      bc,$07f9          ;{{063e:01f907}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),a            ;{{0641:77}} 
        ldir                      ;{{0642:edb0}} 

        ld      bc,$7f89          ;{{0644:01897f}}  select mode 1, lower rom on, upper rom off
        out     (c),c             ;{{0647:ed49}} 

        exx                       ;{{0649:d9}} 
        xor     a                 ;{{064a:af}} 
        ex      af,af'            ;{{064b:08}} 
        ld      sp,$c000          ;{{064c:3100c0}} ; initial stack location
        push    hl                ;{{064f:e5}} 
        push    bc                ;{{0650:c5}} 
        push    de                ;{{0651:d5}} 

        call    Setup_KERNEL_jumpblocks;{{0652:cd4400}} ; initialise LOW KERNEL and HIGH KERNEL jumpblocks
        call    JUMP_RESTORE      ;{{0655:cdbd08}} ; JUMP RESTORE
        call    KM_INITIALISE     ;{{0658:cd5c1b}} ; KM INITIALISE
        call    SOUND_RESET       ;{{065b:cde91f}} ; SOUND RESET
        call    SCR_INITIALISE    ;{{065e:cdbf0a}} ; SCR INITIALISE
        call    TXT_INITIALISE    ;{{0661:cd7410}} ; TXT INITIALISE
        call    GRA_INITIALISE    ;{{0664:cda815}} ; GRA INITIALISE
        call    CAS_INITIALISE    ;{{0667:cdbc24}} ; CAS INITIALISE
        call    MC_RESET_PRINTER  ;{{066a:cde007}} ; MC RESET PRINTER
        ei                        ;{{066d:fb}} 
        pop     hl                ;{{066e:e1}} 
        call    LOW_PCHL_INSTRUCTION;{{066f:cd1e00}} ; LOW: PCHL INSTRUCTION
        pop     bc                ;{{0672:c1}} 
        pop     hl                ;{{0673:e1}} 
        jp      Start_BASIC_or_program;{{0674:c37700}} ; start BASIC or program

;;======================================================================
;; display boot message
display_boot_message:             ;{{Addr=$0677 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,$0202          ;{{0677:210202}} ##LIT##;WARNING: Code area used as literal
        call    TXT_SET_CURSOR    ;{{067a:cd7011}}  TXT SET CURSOR

        call    get_a_pointer_to_the_machine_name;{{067d:cd2307}}  get pointer to machine name (based on LK1-LK3 on PCB)

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
        ld      hl,program_load_failed_message;{{06f9:210507}}  "*** PROGRAM LOAD FAILED ***" message

;;+-----------------------------------------------------------------------
;; display a null terminated string
display_a_null_terminated_string: ;{{Addr=$06fc Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{06fc:7e}}  get message character
        inc     hl                ;{{06fd:23}} 
        or      a                 ;{{06fe:b7}} 
        ret     z                 ;{{06ff:c8}} 

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
        rrca                      ;{{072a:0f}} 
;; A = machine name number
        ld      hl,startup_name_table;{{072b:213807}}  table of names
        inc     a                 ;{{072e:3c}} 
        ld      b,a               ;{{072f:47}} 

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
        exx                       ;{{077a:d9}} 
        res     1,c               ;{{077b:cb89}} ; clear mode bits (bit 1 and bit 0)
        res     0,c               ;{{077d:cb81}} 

        or      c                 ;{{077f:b1}} ; set mode bits to new mode value
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
        jr      _mc_set_inks_2    ;{{078a:1804}} 

;;====================================================================
;; MC SET INKS

MC_SET_INKS:                      ;{{Addr=$078c Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{078c:e5}} 
        ld      hl,$0001          ;{{078d:210100}} ##LIT##;WARNING: Code area used as literal

;;--------------------------------------------------------------------
;; HL = 0 for clear, 1 for set
_mc_set_inks_2:                   ;{{Addr=$0790 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{0790:d5}} 
        push    bc                ;{{0791:c5}} 
        ex      de,hl             ;{{0792:eb}} 

        ld      bc,$7f10          ;{{0793:01107f}}  set border colour
        call    set_colour_for_a_pen;{{0796:cdaa07}}  set colour for PEN/border direct to hardware
        inc     hl                ;{{0799:23}} 
        ld      c,$00             ;{{079a:0e00}} 

_mc_set_inks_9:                   ;{{Addr=$079c Code Calls/jump count: 1 Data use count: 0}}
        call    set_colour_for_a_pen;{{079c:cdaa07}}  set colour for PEN/border direct to hardware
        add     hl,de             ;{{079f:19}} 
        inc     c                 ;{{07a0:0c}} 
        ld      a,c               ;{{07a1:79}} 
        cp      $10               ;{{07a2:fe10}}  maximum number of colours (mode 0 has 16 colours)
        jr      nz,_mc_set_inks_9 ;{{07a4:20f6}}  (-&0a)

        pop     bc                ;{{07a6:c1}} 
        pop     de                ;{{07a7:d1}} 
        pop     hl                ;{{07a8:e1}} 
        ret                       ;{{07a9:c9}} 

;;====================================================================
;; set colour for a pen
;;
;; HL = address of colour for pen
;; C = pen index

set_colour_for_a_pen:             ;{{Addr=$07aa Code Calls/jump count: 2 Data use count: 0}}
        out     (c),c             ;{{07aa:ed49}}  select pen 
        ld      a,(hl)            ;{{07ac:7e}} 
        and     $1f               ;{{07ad:e61f}} 
        or      $40               ;{{07af:f640}} 
        out     (c),a             ;{{07b1:ed79}}  set colour for pen
        ret                       ;{{07b3:c9}} 


;;====================================================================
;; MC WAIT FLYBACK

MC_WAIT_FLYBACK:                  ;{{Addr=$07b4 Code Calls/jump count: 3 Data use count: 1}}
        push    af                ;{{07b4:f5}} 
        push    bc                ;{{07b5:c5}} 

        ld      b,$f5             ;{{07b6:06f5}}  PPI port B I/O address
_mc_wait_flyback_3:               ;{{Addr=$07b8 Code Calls/jump count: 1 Data use count: 0}}
        in      a,(c)             ;{{07b8:ed78}}  read PPI port B input
        rra                       ;{{07ba:1f}}  transfer bit 0 (VSYNC signal from CRTC) into carry flag
        jr      nc,_mc_wait_flyback_3;{{07bb:30fb}}  wait until VSYNC=1

        pop     bc                ;{{07bd:c1}} 
        pop     af                ;{{07be:f1}} 
        ret                       ;{{07bf:c9}} 

;;====================================================================
;; MC SCREEN OFFSET
;;
;; HL = offset
;; A = base

MC_SCREEN_OFFSET:                 ;{{Addr=$07c0 Code Calls/jump count: 1 Data use count: 1}}
        push    bc                ;{{07c0:c5}} 
        rrca                      ;{{07c1:0f}} 
        rrca                      ;{{07c2:0f}} 
        and     $30               ;{{07c3:e630}} 
        ld      c,a               ;{{07c5:4f}} 
        ld      a,h               ;{{07c6:7c}} 
        rra                       ;{{07c7:1f}} 
        and     $03               ;{{07c8:e603}} 
        or      c                 ;{{07ca:b1}} 

;; CRTC register 12 and 13 define screen base and offset

        ld      bc,$bc0c          ;{{07cb:010cbc}} 
        out     (c),c             ;{{07ce:ed49}}  select CRTC register 12
        inc     b                 ;{{07d0:04}}  BC = bd0c
        out     (c),a             ;{{07d1:ed79}}  set CRTC register 12 data
        dec     b                 ;{{07d3:05}}  BC = bc0c
        inc     c                 ;{{07d4:0c}}  BC = bc0d
        out     (c),c             ;{{07d5:ed49}}  select CRTC register 13
        inc     b                 ;{{07d7:04}}  BC = bd0d

        ld      a,h               ;{{07d8:7c}} 
        rra                       ;{{07d9:1f}} 
        ld      a,l               ;{{07da:7d}} 
        rra                       ;{{07db:1f}} 

        out     (c),a             ;{{07dc:ed79}}  set CRTC register 13 data
        pop     bc                ;{{07de:c1}} 
        ret                       ;{{07df:c9}} 


;;====================================================================
;; MC RESET PRINTER

MC_RESET_PRINTER:                 ;{{Addr=$07e0 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,_mc_reset_printer_8;{{07e0:21f707}} ##LABEL##
        ld      de,number_of_entries_in_the_Printer_Transla;{{07e3:1104b8}} 
        ld      bc,$0015          ;{{07e6:011500}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{07e9:edb0}} 

        ld      hl,_mc_reset_printer_6;{{07eb:21f107}} ; table used to initialise printer indirections
        jp      initialise_firmware_indirections;{{07ee:c3b40a}} ; initialise printer indirections

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
        rst     $20               ;{{080c:e7}}  RST 4 - LOW: RAM LAM
        add     a,a               ;{{080d:87}} 
        inc     a                 ;{{080e:3c}} 
        ld      c,a               ;{{080f:4f}} 
        ld      b,$00             ;{{0810:0600}} 
        ld      de,number_of_entries_in_the_Printer_Transla;{{0812:1104b8}} 
        cp      $2a               ;{{0815:fe2a}} 
        call    c,HI_KL_LDIR      ;{{0817:dca1ba}} ; HI: KL LDIR
        ret                       ;{{081a:c9}} 

;;===========================================================================
;; MC PRINT CHAR

MC_PRINT_CHAR:                    ;{{Addr=$081b Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{081b:c5}} 
        push    hl                ;{{081c:e5}} 
        ld      hl,number_of_entries_in_the_Printer_Transla;{{081d:2104b8}} 
        ld      b,(hl)            ;{{0820:46}} 
        inc     b                 ;{{0821:04}} 
_mc_print_char_5:                 ;{{Addr=$0822 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{0822:05}} 
        jr      z,_mc_print_char_14;{{0823:280a}}  (+&0a)
        inc     hl                ;{{0825:23}} 
        cp      (hl)              ;{{0826:be}} 
        inc     hl                ;{{0827:23}} 
        jr      nz,_mc_print_char_5;{{0828:20f8}}  (-&08)
        ld      a,(hl)            ;{{082a:7e}} 
        cp      $ff               ;{{082b:feff}} 
        jr      z,_mc_print_char_15;{{082d:2803}}  (+&03)
_mc_print_char_14:                ;{{Addr=$082f Code Calls/jump count: 1 Data use count: 0}}
        call    MC_WAIT_PRINTER   ;{{082f:cdf1bd}}  IND: MC WAIT PRINTER
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
        jr      nc,MC_SEND_PRINTER;{{083b:3007}}  MC SEND PRINTER
        djnz    _ind_mc_wait_printer_1;{{083d:10f9}} 
        dec     c                 ;{{083f:0d}} 
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
        or      $80               ;{{084b:f680}}  set bit 7 (/STROBE)
        di                        ;{{084d:f3}} 
        out     (c),a             ;{{084e:ed79}}  write data with /STROBE=0
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
        ld      b,$f5             ;{{085a:06f5}}  PPI port B I/O address
        in      a,(c)             ;{{085c:ed78}}  read PPI port B input
        rla                       ;{{085e:17}}  transfer bit 6 into carry (BUSY input from printer)						
        rla                       ;{{085f:17}} 
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
        in      a,(c)             ;{{086a:ed78}}  get current outputs of PPI port C I/O port
        or      $c0               ;{{086c:f6c0}}  bit 7,6: PSG register select
        out     (c),a             ;{{086e:ed79}}  write control to PSG. PSG will select register
                                  ; referenced by data at PPI port A output
        and     $3f               ;{{0870:e63f}}  bit 7,6: PSG inactive
        out     (c),a             ;{{0872:ed79}}  write control to PSG.

        ld      b,$f4             ;{{0874:06f4}}  PPI port A I/O address
        out     (c),c             ;{{0876:ed49}}  write register data

        ld      b,$f6             ;{{0878:06f6}}  PPI port C I/O address
        ld      c,a               ;{{087a:4f}} 
        or      $80               ;{{087b:f680}}  bit 7,6: PSG write data to selected register
        out     (c),a             ;{{087d:ed79}}  write control to PSG. PSG will write the data
                                  ; at PPI port A into the currently selected register
; bit 7,6: PSG inactive
        out     (c),c             ;{{087f:ed49}}  write control to PSG
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
        in      a,(c)             ;{{088a:ed78}}  get current port C data
        and     $30               ;{{088c:e630}} 
        ld      c,a               ;{{088e:4f}} 

        or      $c0               ;{{088f:f6c0}}  PSG operation: select register
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

        push    bc                ;{{089a:c5}} 
        set     6,c               ;{{089b:cbf1}}  PSG: operation: read data from selected register


_scan_keyboard_14:                ;{{Addr=$089d Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f6             ;{{089d:06f6}}  B = I/O address for PPI port C
        out     (c),c             ;{{089f:ed49}} 
        ld      b,$f4             ;{{08a1:06f4}}  B = I/O address for PPI port A
        in      a,(c)             ;{{08a3:ed78}}  read selected keyboard line
                                  ; (keyboard data->PSG port A->PPI port A)

        ld      b,(hl)            ;{{08a5:46}}  get previous keyboard line state
                                  ; "0" indicates a pressed key
                                  ; "1" indicates a released key
        ld      (hl),a            ;{{08a6:77}}  store new keyboard line state

        and     b                 ;{{08a7:a0}}  a bit will be 1 where a key was not pressed
                                  ; in the previous keyboard scan and the current keyboard scan.
                                  ; a bit will be 0 where a key has been:
                                  ; - pressed in previous keyboard scan, released in this keyboard scan
                                  ; - not pressed in previous keyboard scan, pressed in this keyboard scan
                                  ; - key has been held for previous and this keyboard scan.
        cpl                       ;{{08a8:2f}}  change so a '1' now indicates held/pressed key
                                  ; '0' indicates a key that has not been pressed/held
        ld      (de),a            ;{{08a9:12}}  store keybaord line data

        inc     hl                ;{{08aa:23}} 
        inc     de                ;{{08ab:13}} 
        inc     c                 ;{{08ac:0c}} 

        ld      a,c               ;{{08ad:79}} 
        and     $0f               ;{{08ae:e60f}}  current keyboard line
        cp      $0a               ;{{08b0:fe0a}}  10 keyboard lines
        jr      nz,_scan_keyboard_14;{{08b2:20e9}} 

        pop     bc                ;{{08b4:c1}} 
;; B = I/O address of PPI control register
        ld      a,$82             ;{{08b5:3e82}}  PPI port A: output
                                  ; PPI port B: input
                                  ; PPI port C (upper and lower): output
        out     (c),a             ;{{08b7:ed79}} 
;; B = I/O address of PPI port C lower

        dec     b                 ;{{08b9:05}} 
        out     (c),c             ;{{08ba:ed49}} 
        ret                       ;{{08bc:c9}} 





;;***JumpRestore.asm
;;==============================================================
;; JUMP RESTORE
;;
;; (restore all the firmware jump routines)

;; main firmware jumpblock
JUMP_RESTORE:                     ;{{Addr=$08bd Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,main_firmware_jumpblock;{{08bd:21de08}}  table of addressess for firmware functions
        ld      de,Key_Manager_Jumpblock;{{08c0:1100bb}}  start of firmware jumpblock
        ld      bc,$cbcf          ;{{08c3:01cfcb}}  B = 203 entries, C = 0x0cf -> RST 1 -> LOW: LOW JUMP
        call    _jump_restore_5   ;{{08c6:cdcc08}} 

        ld      bc,$20ef          ;{{08c9:01ef20}}  B = number of entries: 32 entries ##LIT##;WARNING: Code area used as literal
                                  ; C=  0x0ef -> RST 5 -> LOW: FIRM JUMP
;;-------------------------------------------------------------------------------------
; C = 0x0cf -> RST 1 -> LOW: LOW JUMP
; OR
; C=  0x0ef -> RST 5 -> LOW: FIRM JUMP

_jump_restore_5:                  ;{{Addr=$08cc Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{08cc:79}}  write RST instruction 			
        ld      (de),a            ;{{08cd:12}} 
        inc     de                ;{{08ce:13}} 
        ldi                       ;{{08cf:eda0}}  write low byte of address in ROM
        inc     bc                ;{{08d1:03}} 
        cpl                       ;{{08d2:2f}} 
        rlca                      ;{{08d3:07}} 
        rlca                      ;{{08d4:07}} 
        and     $80               ;{{08d5:e680}} 
        or      (hl)              ;{{08d7:b6}} 
        ld      (de),a            ;{{08d8:12}}  write high byte of address in ROM
        inc     de                ;{{08d9:13}} 
        inc     hl                ;{{08da:23}} 
        djnz    _jump_restore_5   ;{{08db:10ef}} 
        ret                       ;{{08dd:c9}} 

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
        ld      c,(hl)            ;{{0ab4:4e}} 
        ld      b,$00             ;{{0ab5:0600}} 
        inc     hl                ;{{0ab7:23}} 
        ld      e,(hl)            ;{{0ab8:5e}} 
        inc     hl                ;{{0ab9:23}} 
        ld      d,(hl)            ;{{0aba:56}} 
        inc     hl                ;{{0abb:23}} 
        ldir                      ;{{0abc:edb0}} 
        ret                       ;{{0abe:c9}} 




;;***Screen.asm
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



;;***Text.asm
;; TEXT ROUTINES
;;===========================================================================
;; TXT INITIALISE

TXT_INITIALISE:                   ;{{Addr=$1074 Code Calls/jump count: 1 Data use count: 1}}
        call    TXT_RESET         ;{{1074:cd8410}} ; TXT RESET
        xor     a                 ;{{1077:af}} 
        ld      (UDG_matrix_table_flag_),a;{{1078:3235b7}} 
        ld      hl,$0001          ;{{107b:210100}} ##LIT##;WARNING: Code area used as literal
        call    initialise_a_stream;{{107e:cd3911}} 
        jp      clear_txt_streams_area;{{1081:c39f10}} 

;;===========================================================================
;; TXT RESET

TXT_RESET:                        ;{{Addr=$1084 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,_txt_reset_3   ;{{1084:218d10}} ; table used to initialise text vdu indirections
        call    initialise_firmware_indirections;{{1087:cdb40a}} ; initialise text vdu indirections
        jp      initialise_control_code_functions;{{108a:c36414}} ; initialise control code handler functions

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
        ld      a,$08             ;{{109f:3e08}} 
        ld      de,RAM_b6b6       ;{{10a1:11b6b6}} 
_clear_txt_streams_area_2:        ;{{Addr=$10a4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,Current_Stream_;{{10a4:2126b7}} 
        ld      bc,$000e          ;{{10a7:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{10aa:edb0}} 
        dec     a                 ;{{10ac:3d}} 
        jr      nz,_clear_txt_streams_area_2;{{10ad:20f5}}  (-&0b)
        ld      (current_stream_number),a;{{10af:32b5b6}} 
        ret                       ;{{10b2:c9}} 

;;==================================================================================
;; clean up streams?
clean_up_streams:                 ;{{Addr=$10b3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_stream_number);{{10b3:3ab5b6}} 
        ld      c,a               ;{{10b6:4f}} 
        ld      b,$08             ;{{10b7:0608}} 

_clean_up_streams_3:              ;{{Addr=$10b9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10b9:78}} 
        dec     a                 ;{{10ba:3d}} 
        call    TXT_STR_SELECT    ;{{10bb:cde410}}  TXT STR SELECT
        call    TXT_UNDRAW_CURSOR ;{{10be:cdd0bd}}  IND: TXT UNDRAW CURSOR
        call    TXT_GET_PAPER     ;{{10c1:cdc012}}  TXT GET PAPER
        ld      (current_PAPER_number_),a;{{10c4:3230b7}} 
        call    TXT_GET_PEN       ;{{10c7:cdba12}}  TXT GET PEN
        ld      (current_PEN_number_),a;{{10ca:322fb7}} 
        djnz    _clean_up_streams_3;{{10cd:10ea}}  (-&16)
        ld      a,c               ;{{10cf:79}} 
        ret                       ;{{10d0:c9}} 

;;==================================================================================
;; initialise txt streams
initialise_txt_streams:           ;{{Addr=$10d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{10d1:4f}} 
        ld      b,$08             ;{{10d2:0608}} 
_initialise_txt_streams_2:        ;{{Addr=$10d4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10d4:78}} 
        dec     a                 ;{{10d5:3d}} 
        call    TXT_STR_SELECT    ;{{10d6:cde410}}  TXT STR SELECT
        push    bc                ;{{10d9:c5}} 
        ld      hl,(current_PEN_number_);{{10da:2a2fb7}} 
        call    initialise_a_stream;{{10dd:cd3911}} 
        pop     bc                ;{{10e0:c1}} 
        djnz    _initialise_txt_streams_2;{{10e1:10f1}}  (-&0f)
        ld      a,c               ;{{10e3:79}} 

;;==================================================================================
;; TXT STR SELECT
TXT_STR_SELECT:                   ;{{Addr=$10e4 Code Calls/jump count: 4 Data use count: 1}}
        and     $07               ;{{10e4:e607}} 
        ld      hl,current_stream_number;{{10e6:21b5b6}} 
        cp      (hl)              ;{{10e9:be}} 
        ret     z                 ;{{10ea:c8}} 

        push    bc                ;{{10eb:c5}} 
        push    de                ;{{10ec:d5}} 
        ld      c,(hl)            ;{{10ed:4e}} 
        ld      (hl),a            ;{{10ee:77}} 
        ld      b,a               ;{{10ef:47}} 
        ld      a,c               ;{{10f0:79}} 
        call    _txt_swap_streams_19;{{10f1:cd2611}} 
        call    _txt_swap_streams_14;{{10f4:cd1e11}} 
        ld      a,b               ;{{10f7:78}} 
        call    _txt_swap_streams_19;{{10f8:cd2611}} 
        ex      de,hl             ;{{10fb:eb}} 
        call    _txt_swap_streams_14;{{10fc:cd1e11}} 
        ld      a,c               ;{{10ff:79}} 
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
        ld      a,b               ;{{110b:78}} 
        ld      (current_stream_number),a;{{110c:32b5b6}} 
        call    _txt_swap_streams_19;{{110f:cd2611}} 
        push    de                ;{{1112:d5}} 
        ld      a,c               ;{{1113:79}} 
        call    _txt_swap_streams_19;{{1114:cd2611}} 
        pop     hl                ;{{1117:e1}} 
        call    _txt_swap_streams_14;{{1118:cd1e11}} 
        pop     af                ;{{111b:f1}} 
        jr      TXT_STR_SELECT    ;{{111c:18c6}}  (-&3a)
;;--------------------------------------------------------------
_txt_swap_streams_14:             ;{{Addr=$111e Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{111e:c5}} 
        ld      bc,$000e          ;{{111f:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1122:edb0}} 
        pop     bc                ;{{1124:c1}} 
        ret                       ;{{1125:c9}} 

;;--------------------------------------------------------------
_txt_swap_streams_19:             ;{{Addr=$1126 Code Calls/jump count: 4 Data use count: 0}}
        and     $07               ;{{1126:e607}} 
        ld      e,a               ;{{1128:5f}} 
        add     a,a               ;{{1129:87}} 
        add     a,e               ;{{112a:83}} 
        add     a,a               ;{{112b:87}} 
        add     a,e               ;{{112c:83}} 
        add     a,a               ;{{112d:87}} 
        add     a,$b6             ;{{112e:c6b6}} 
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
        ld      a,$83             ;{{113a:3e83}} 
        ld      (cursor_flag_),a  ;{{113c:322eb7}} 
        ld      a,d               ;{{113f:7a}} 
        call    TXT_SET_PAPER     ;{{1140:cdab12}}  TXT SET PAPER
        ld      a,e               ;{{1143:7b}} 
        call    TXT_SET_PEN_      ;{{1144:cda612}}  TXT SET PEN
        xor     a                 ;{{1147:af}} 
        call    TXT_SET_GRAPHIC   ;{{1148:cda813}}  TXT SET GRAPHIC
        call    TXT_SET_BACK      ;{{114b:cd7b13}}  TXT SET BACK
        ld      hl,$0000          ;{{114e:210000}} ##LIT##;WARNING: Code area used as literal
        ld      de,$7f7f          ;{{1151:117f7f}} 
        call    TXT_WIN_ENABLE    ;{{1154:cd0812}}  TXT WIN ENABLE
        jp      TXT_VDU_ENABLE    ;{{1157:c35914}}  TXT VDU ENABLE

;;===========================================================================
;; TXT SET COLUMN

TXT_SET_COLUMN:                   ;{{Addr=$115a Code Calls/jump count: 1 Data use count: 1}}
        dec     a                 ;{{115a:3d}} 
        ld      hl,window_left_column_;{{115b:212ab7}} 
        add     a,(hl)            ;{{115e:86}} 
        ld      hl,(Current_Stream_);{{115f:2a26b7}} 
        ld      h,a               ;{{1162:67}} 
        jr      _txt_set_cursor_1 ;{{1163:180e}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; TXT SET ROW

TXT_SET_ROW:                      ;{{Addr=$1165 Code Calls/jump count: 0 Data use count: 1}}
        dec     a                 ;{{1165:3d}} 
        ld      hl,window_top_line_;{{1166:2129b7}} 
        add     a,(hl)            ;{{1169:86}} 
        ld      hl,(Current_Stream_);{{116a:2a26b7}} 
        ld      l,a               ;{{116d:6f}} 
        jr      _txt_set_cursor_1 ;{{116e:1803}} ; undraw cursor, set cursor position and draw it

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
        ld      hl,(Current_Stream_);{{117c:2a26b7}} 
        call    _txt_get_cursor_13;{{117f:cd9311}} 
        ld      a,(scroll_count)  ;{{1182:3a2db7}} 
        ret                       ;{{1185:c9}} 

;;----------------------------------------------------------------
_txt_get_cursor_4:                ;{{Addr=$1186 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_top_line_);{{1186:3a29b7}} 
        dec     a                 ;{{1189:3d}} 
        add     a,l               ;{{118a:85}} 
        ld      l,a               ;{{118b:6f}} 
        ld      a,(window_left_column_);{{118c:3a2ab7}} 
        dec     a                 ;{{118f:3d}} 
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
        ld      l,a               ;{{119a:6f}} 
        ld      a,(window_left_column_);{{119b:3a2ab7}} 
        sub     h                 ;{{119e:94}} 
        cpl                       ;{{119f:2f}} 
        inc     a                 ;{{11a0:3c}} 
        inc     a                 ;{{11a1:3c}} 
        ld      h,a               ;{{11a2:67}} 
        ret                       ;{{11a3:c9}} 

;;====================================================================
;; scroll window?
scroll_window:                    ;{{Addr=$11a4 Code Calls/jump count: 8 Data use count: 0}}
        call    TXT_UNDRAW_CURSOR ;{{11a4:cdd0bd}} ; IND: TXT UNDRAW CURSOR

;;--------------------------------------------------------------------
_scroll_window_1:                 ;{{Addr=$11a7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(Current_Stream_);{{11a7:2a26b7}} 
        call    _txt_validate_6   ;{{11aa:cdd611}} 
        ld      (Current_Stream_),hl;{{11ad:2226b7}} 
        ret     c                 ;{{11b0:d8}} 

        push    hl                ;{{11b1:e5}} 
        ld      hl,scroll_count   ;{{11b2:212db7}} 
        ld      a,b               ;{{11b5:78}} 
        add     a,a               ;{{11b6:87}} 
        inc     a                 ;{{11b7:3c}} 
        add     a,(hl)            ;{{11b8:86}} 
        ld      (hl),a            ;{{11b9:77}} 
        call    TXT_GET_WINDOW    ;{{11ba:cd5212}} ; TXT GET WINDOW
        ld      a,(current_PAPER_number_);{{11bd:3a30b7}} 
        push    af                ;{{11c0:f5}} 
        call    c,SCR_SW_ROLL     ;{{11c1:dc440e}} ; SCR SW ROLL
        pop     af                ;{{11c4:f1}} 
        call    nc,SCR_HW_ROLL    ;{{11c5:d4000e}} ; SCR HW ROLL
        pop     hl                ;{{11c8:e1}} 
        ret                       ;{{11c9:c9}} 


;;===========================================================================
;; TXT VALIDATE

TXT_VALIDATE:                     ;{{Addr=$11ca Code Calls/jump count: 8 Data use count: 1}}
        call    _txt_get_cursor_4 ;{{11ca:cd8611}} 
        call    _txt_validate_6   ;{{11cd:cdd611}} 
        push    af                ;{{11d0:f5}} 
        call    _txt_get_cursor_13;{{11d1:cd9311}} 
        pop     af                ;{{11d4:f1}} 
        ret                       ;{{11d5:c9}} 
;;------------------------------------------------------------------
_txt_validate_6:                  ;{{Addr=$11d6 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_right_colwnn_);{{11d6:3a2cb7}} 
        cp      h                 ;{{11d9:bc}} 
        jp      p,_txt_validate_12;{{11da:f2e211}} 
        ld      a,(window_left_column_);{{11dd:3a2ab7}} 
        ld      h,a               ;{{11e0:67}} 
        inc     l                 ;{{11e1:2c}} 
_txt_validate_12:                 ;{{Addr=$11e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_left_column_);{{11e2:3a2ab7}} 
        dec     a                 ;{{11e5:3d}} 
        cp      h                 ;{{11e6:bc}} 
        jp      m,_txt_validate_19;{{11e7:faef11}} 
        ld      a,(window_right_colwnn_);{{11ea:3a2cb7}} 
        ld      h,a               ;{{11ed:67}} 
        dec     l                 ;{{11ee:2d}} 
_txt_validate_19:                 ;{{Addr=$11ef Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_top_line_);{{11ef:3a29b7}} 
        dec     a                 ;{{11f2:3d}} 
        cp      l                 ;{{11f3:bd}} 
        jp      p,_txt_validate_31;{{11f4:f20212}} 
        ld      a,(window_bottom_line_);{{11f7:3a2bb7}} 
        cp      l                 ;{{11fa:bd}} 
        scf                       ;{{11fb:37}} 
        ret     p                 ;{{11fc:f0}} 

        ld      l,a               ;{{11fd:6f}} 
        ld      b,$ff             ;{{11fe:06ff}} 
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
        ld      a,h               ;{{120b:7c}} 
        call    _txt_win_enable_33;{{120c:cd4012}} 
        ld      h,a               ;{{120f:67}} 
        ld      a,d               ;{{1210:7a}} 
        call    _txt_win_enable_33;{{1211:cd4012}} 
        ld      d,a               ;{{1214:57}} 
        cp      h                 ;{{1215:bc}} 
        jr      nc,_txt_win_enable_11;{{1216:3002}}  (+&02)
        ld      d,h               ;{{1218:54}} 
        ld      h,a               ;{{1219:67}} 
_txt_win_enable_11:               ;{{Addr=$121a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{121a:7d}} 
        call    _txt_win_enable_40;{{121b:cd4912}} 
        ld      l,a               ;{{121e:6f}} 
        ld      a,e               ;{{121f:7b}} 
        call    _txt_win_enable_40;{{1220:cd4912}} 
        ld      e,a               ;{{1223:5f}} 
        cp      l                 ;{{1224:bd}} 
        jr      nc,_txt_win_enable_21;{{1225:3002}}  (+&02)
        ld      e,l               ;{{1227:5d}} 
        ld      l,a               ;{{1228:6f}} 
_txt_win_enable_21:               ;{{Addr=$1229 Code Calls/jump count: 1 Data use count: 0}}
        ld      (window_top_line_),hl;{{1229:2229b7}} 
        ld      (window_bottom_line_),de;{{122c:ed532bb7}} 
        ld      a,h               ;{{1230:7c}} 
        or      l                 ;{{1231:b5}} 
        jr      nz,_txt_win_enable_31;{{1232:2006}}  (+&06)
        ld      a,d               ;{{1234:7a}} 
        xor     b                 ;{{1235:a8}} 
        jr      nz,_txt_win_enable_31;{{1236:2002}}  (+&02)
        ld      a,e               ;{{1238:7b}} 
        xor     c                 ;{{1239:a9}} 
_txt_win_enable_31:               ;{{Addr=$123a Code Calls/jump count: 2 Data use count: 0}}
        ld      (RAM_b728),a      ;{{123a:3228b7}} 
        jp      _txt_set_cursor_1 ;{{123d:c37311}} ; undraw cursor, set cursor position and draw it

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
        jp      p,_txt_win_enable_43;{{124a:f24e12}} 
        xor     a                 ;{{124d:af}} 
_txt_win_enable_43:               ;{{Addr=$124e Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{124e:b9}} 
        ret     c                 ;{{124f:d8}} 

        ld      a,c               ;{{1250:79}} 
        ret                       ;{{1251:c9}} 

;;===========================================================================
;; TXT GET WINDOW

TXT_GET_WINDOW:                   ;{{Addr=$1252 Code Calls/jump count: 3 Data use count: 1}}
        ld      hl,(window_top_line_);{{1252:2a29b7}} 
        ld      de,(window_bottom_line_);{{1255:ed5b2bb7}} 
        ld      a,(RAM_b728)      ;{{1259:3a28b7}} 
        add     a,$ff             ;{{125c:c6ff}} 
        ret                       ;{{125e:c9}} 

;;===========================================================================
;; IND: TXT UNDRAW CURSOR
IND_TXT_UNDRAW_CURSOR:            ;{{Addr=$125f Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(cursor_flag_)  ;{{125f:3a2eb7}} 
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
        ld      bc,(current_PEN_number_);{{126b:ed4b2fb7}} 
        call    SCR_CHAR_INVERT   ;{{126f:cde50d}} ; SCR CHAR INVERT
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
        pop     af                ;{{127c:f1}} 
        ret                       ;{{127d:c9}} 

;;===========================================================================
;; TXT CUR OFF

TXT_CUR_OFF:                      ;{{Addr=$127e Code Calls/jump count: 2 Data use count: 1}}
        push    af                ;{{127e:f5}} 
        ld      a,$02             ;{{127f:3e02}} 
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
        pop     af                ;{{128c:f1}} 
        push    hl                ;{{128d:e5}} 
        ld      hl,cursor_flag_   ;{{128e:212eb7}} 
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
        call    TXT_UNDRAW_CURSOR ;{{129a:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{129d:f1}} 
        push    hl                ;{{129e:e5}} 
        ld      hl,cursor_flag_   ;{{129f:212eb7}} 
        or      (hl)              ;{{12a2:b6}} 
        ld      (hl),a            ;{{12a3:77}} 
        pop     hl                ;{{12a4:e1}} 
        ret                       ;{{12a5:c9}} 

;;===========================================================================
;; TXT SET PEN 
TXT_SET_PEN_:                     ;{{Addr=$12a6 Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PEN_number_;{{12a6:212fb7}} 
        jr      _txt_set_paper_1  ;{{12a9:1803}}  (+&03)

;;===========================================================================
;; TXT SET PAPER
TXT_SET_PAPER:                    ;{{Addr=$12ab Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PAPER_number_;{{12ab:2130b7}} 
;;---------------------------------------------------------------------------
_txt_set_paper_1:                 ;{{Addr=$12ae Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12ae:f5}} 
        call    TXT_UNDRAW_CURSOR ;{{12af:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{12b2:f1}} 
        call    SCR_INK_ENCODE    ;{{12b3:cd8e0c}} ; SCR INK ENCODE
        ld      (hl),a            ;{{12b6:77}} 
_txt_set_paper_6:                 ;{{Addr=$12b7 Code Calls/jump count: 1 Data use count: 0}}
        jp      TXT_DRAW_CURSOR   ;{{12b7:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; TXT GET PEN
TXT_GET_PEN:                      ;{{Addr=$12ba Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PEN_number_);{{12ba:3a2fb7}} 
        jp      SCR_INK_DECODE    ;{{12bd:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT GET PAPER
TXT_GET_PAPER:                    ;{{Addr=$12c0 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PAPER_number_);{{12c0:3a30b7}} 
        jp      SCR_INK_DECODE    ;{{12c3:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT INVERSE
TXT_INVERSE:                      ;{{Addr=$12c6 Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{12c6:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        ld      hl,(current_PEN_number_);{{12c9:2a2fb7}} 
        ld      a,h               ;{{12cc:7c}} 
        ld      h,l               ;{{12cd:65}} 
        ld      l,a               ;{{12ce:6f}} 
        ld      (current_PEN_number_),hl;{{12cf:222fb7}} 
        jr      _txt_set_paper_6  ;{{12d2:18e3}}  (-&1d)

;;===========================================================================
;; TXT GET MATRIX
TXT_GET_MATRIX:                   ;{{Addr=$12d4 Code Calls/jump count: 5 Data use count: 1}}
        push    de                ;{{12d4:d5}} 
        ld      e,a               ;{{12d5:5f}} 
        call    TXT_GET_M_TABLE   ;{{12d6:cd2b13}}  TXT GET M TABLE
        jr      nc,get_font_glyph_address;{{12d9:3009}}  get pointer to character graphics
        ld      d,a               ;{{12db:57}} 
        ld      a,e               ;{{12dc:7b}} 
        sub     d                 ;{{12dd:92}} 
        ccf                       ;{{12de:3f}} 
        jr      nc,get_font_glyph_address;{{12df:3003}}  get pointer to character graphics
        ld      e,a               ;{{12e1:5f}} 
        jr      _get_font_glyph_address_1;{{12e2:1803}}  (+&03)

;;=============================================================
;; get font glyph address
;;
;; Entry conditions:
;; A = character code
;; Exit conditions:
;; HL = pointer to graphics for character

get_font_glyph_address:           ;{{Addr=$12e4 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,Font_graphics  ;{{12e4:210038}}  font graphics
_get_font_glyph_address_1:        ;{{Addr=$12e7 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12e7:f5}} 
        ld      d,$00             ;{{12e8:1600}} 
        ex      de,hl             ;{{12ea:eb}} 
        add     hl,hl             ;{{12eb:29}}  x2
        add     hl,hl             ;{{12ec:29}}  x4
        add     hl,hl             ;{{12ed:29}}  x8
        add     hl,de             ;{{12ee:19}} 
        pop     af                ;{{12ef:f1}} 
        pop     de                ;{{12f0:d1}} 
        ret                       ;{{12f1:c9}} 

;;===========================================================================
;; TXT SET MATRIX
TXT_SET_MATRIX:                   ;{{Addr=$12f2 Code Calls/jump count: 1 Data use count: 1}}
        ex      de,hl             ;{{12f2:eb}} 
        call    TXT_GET_MATRIX    ;{{12f3:cdd412}}  TXT GET MATRIX
        ret     nc                ;{{12f6:d0}} 

        ex      de,hl             ;{{12f7:eb}} 

;;---------------------------------------------------------------------------
_txt_set_matrix_4:                ;{{Addr=$12f8 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0008          ;{{12f8:010800}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{12fb:edb0}} 
        ret                       ;{{12fd:c9}} 

;;===========================================================================
;; TXT SET M TABLE
TXT_SET_M_TABLE:                  ;{{Addr=$12fe Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{12fe:e5}} 
        ld      a,d               ;{{12ff:7a}} 
        or      a                 ;{{1300:b7}} 
        ld      d,$00             ;{{1301:1600}} 
        jr      nz,_txt_set_m_table_23;{{1303:2019}}  (+&19)
        dec     d                 ;{{1305:15}} 
        push    de                ;{{1306:d5}} 
        ld      c,e               ;{{1307:4b}} 
        ex      de,hl             ;{{1308:eb}} 
_txt_set_m_table_9:               ;{{Addr=$1309 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{1309:79}} 
        call    TXT_GET_MATRIX    ;{{130a:cdd412}}  TXT GET MATRIX
        ld      a,h               ;{{130d:7c}} 
        xor     d                 ;{{130e:aa}} 
        jr      nz,_txt_set_m_table_17;{{130f:2004}}  (+&04)
        ld      a,l               ;{{1311:7d}} 
        xor     e                 ;{{1312:ab}} 
        jr      z,_txt_set_m_table_22;{{1313:2808}}  (+&08)
_txt_set_m_table_17:              ;{{Addr=$1315 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{1315:c5}} 
        call    _txt_set_matrix_4 ;{{1316:cdf812}} 
        pop     bc                ;{{1319:c1}} 
        inc     c                 ;{{131a:0c}} 
        jr      nz,_txt_set_m_table_9;{{131b:20ec}}  (-&14)
_txt_set_m_table_22:              ;{{Addr=$131d Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{131d:d1}} 
_txt_set_m_table_23:              ;{{Addr=$131e Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_M_TABLE   ;{{131e:cd2b13}}  TXT GET M TABLE
        ld      (ASCII_number_of_the_first_character_in_U),de;{{1321:ed5334b7}} 
        pop     de                ;{{1325:d1}} 
        ld      (address_of_UDG_matrix_table),de;{{1326:ed5336b7}} 
        ret                       ;{{132a:c9}} 

;;===========================================================================
;; TXT GET M TABLE
TXT_GET_M_TABLE:                  ;{{Addr=$132b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,(ASCII_number_of_the_first_character_in_U);{{132b:2a34b7}} 
        ld      a,h               ;{{132e:7c}} 
        rrca                      ;{{132f:0f}} 
        ld      a,l               ;{{1330:7d}} 
        ld      hl,(address_of_UDG_matrix_table);{{1331:2a36b7}} 
        ret                       ;{{1334:c9}} 

;;===========================================================================
;; TXT WR CHAR

TXT_WR_CHAR:                      ;{{Addr=$1335 Code Calls/jump count: 3 Data use count: 2}}
        ld      b,a               ;{{1335:47}} 
        ld      a,(cursor_flag_)  ;{{1336:3a2eb7}} 
        rlca                      ;{{1339:07}} 
        ret     c                 ;{{133a:d8}} 

        push    bc                ;{{133b:c5}} 
        call    scroll_window     ;{{133c:cda411}} 
        inc     h                 ;{{133f:24}} 
        ld      (Current_Stream_),hl;{{1340:2226b7}} 
        dec     h                 ;{{1343:25}} 
        pop     af                ;{{1344:f1}} 
        call    TXT_WRITE_CHAR    ;{{1345:cdd3bd}} ; IND: TXT WRITE CURSOR
        jp      TXT_DRAW_CURSOR   ;{{1348:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; IND: TXT WRITE CHAR
IND_TXT_WRITE_CHAR:               ;{{Addr=$134b Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{134b:e5}} 
        call    TXT_GET_MATRIX    ;{{134c:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{134f:1138b7}} 
        push    de                ;{{1352:d5}} 
        call    SCR_UNPACK        ;{{1353:cdf90e}}  SCR UNPACK
        pop     de                ;{{1356:d1}} 
        pop     hl                ;{{1357:e1}} 
        call    SCR_CHAR_POSITION ;{{1358:cd6a0b}}  SCR CHAR POSITION
        ld      c,$08             ;{{135b:0e08}} 
_ind_txt_write_char_9:            ;{{Addr=$135d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135d:c5}} 
        push    hl                ;{{135e:e5}} 
_ind_txt_write_char_11:           ;{{Addr=$135f Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135f:c5}} 
        push    de                ;{{1360:d5}} 
        ex      de,hl             ;{{1361:eb}} 
        ld      c,(hl)            ;{{1362:4e}} 
        call    _ind_txt_write_char_27;{{1363:cd7713}} 
        call    SCR_NEXT_BYTE     ;{{1366:cd050c}}  SCR NEXT BYTE
        pop     de                ;{{1369:d1}} 
        inc     de                ;{{136a:13}} 
        pop     bc                ;{{136b:c1}} 
        djnz    _ind_txt_write_char_11;{{136c:10f1}}  (-&0f)
        pop     hl                ;{{136e:e1}} 
        call    SCR_NEXT_LINE     ;{{136f:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{1372:c1}} 
        dec     c                 ;{{1373:0d}} 
        jr      nz,_ind_txt_write_char_9;{{1374:20e7}}  (-&19)
        ret                       ;{{1376:c9}} 

;;------------------------------------------------------------------
_ind_txt_write_char_27:           ;{{Addr=$1377 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_text_background_routine_opaq);{{1377:2a31b7}} 
        jp      (hl)              ;{{137a:e9}} 
;;===========================================================================
;; TXT SET BACK
TXT_SET_BACK:                     ;{{Addr=$137b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,write_opaque   ;{{137b:219213}} ##LABEL##
        or      a                 ;{{137e:b7}} 
        jr      z,_txt_set_back_4 ;{{137f:2803}}  (+&03)
        ld      hl,write_transparent;{{1381:21a013}} ##LABEL##
_txt_set_back_4:                  ;{{Addr=$1384 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_text_background_routine_opaq),hl;{{1384:2231b7}} 
        ret                       ;{{1387:c9}} 

;;===========================================================================
;; TXT GET BACK
TXT_GET_BACK:                     ;{{Addr=$1388 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_text_background_routine_opaq);{{1388:2a31b7}} 
        ld      de,$10000 - write_opaque;{{138b:116eec}} ;was &ec6e ##LABEL##
        add     hl,de             ;{{138e:19}} 
        ld      a,h               ;{{138f:7c}} 
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
        and     l                 ;{{139a:a5}} 
        or      b                 ;{{139b:b0}} 
        ld      c,$ff             ;{{139c:0eff}} 
        jr      _write_transparent_1;{{139e:1803}}  (+&03)

;;===========================================================================
;;write transparent
write_transparent:                ;{{Addr=$13a0 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(current_PEN_number_);{{13a0:3a2fb7}} 
;;---------------------------------------------------------------------------
_write_transparent_1:             ;{{Addr=$13a3 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{13a3:47}} 
        ex      de,hl             ;{{13a4:eb}} 
        jp      SCR_PIXELS        ;{{13a5:c3740c}}  SCR PIXELS

;;===========================================================================
;; TXT SET GRAPHIC

TXT_SET_GRAPHIC:                  ;{{Addr=$13a8 Code Calls/jump count: 1 Data use count: 1}}
        ld      (graphics_character_writing_flag_),a;{{13a8:3233b7}} 
        ret                       ;{{13ab:c9}} 

;;===========================================================================
;; TXT RD CHAR

TXT_RD_CHAR:                      ;{{Addr=$13ac Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{13ac:e5}} 
        push    de                ;{{13ad:d5}} 
        push    bc                ;{{13ae:c5}} 
        call    scroll_window     ;{{13af:cda411}} 
        call    TXT_UNWRITE       ;{{13b2:cdd6bd}}  IND: TXT UNWRITE
        push    af                ;{{13b5:f5}} 
        call    TXT_DRAW_CURSOR   ;{{13b6:cdcdbd}}  IND: TXT DRAW CURSOR
        pop     af                ;{{13b9:f1}} 
        pop     bc                ;{{13ba:c1}} 
        pop     de                ;{{13bb:d1}} 
        pop     hl                ;{{13bc:e1}} 
        ret                       ;{{13bd:c9}} 

;;===========================================================================
;; IND: TXT UNWRITE

IND_TXT_UNWRITE:                  ;{{Addr=$13be Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{13be:3a30b7}} 
        ld      de,RAM_b738       ;{{13c1:1138b7}} 
        push    hl                ;{{13c4:e5}} 
        push    de                ;{{13c5:d5}} 
        call    SCR_REPACK        ;{{13c6:cd2a0f}}  SCR REPACK
        pop     de                ;{{13c9:d1}} 
        push    de                ;{{13ca:d5}} 
        ld      b,$08             ;{{13cb:0608}} 
_ind_txt_unwrite_8:               ;{{Addr=$13cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13cd:1a}} 
        cpl                       ;{{13ce:2f}} 
        ld      (de),a            ;{{13cf:12}} 
        inc     de                ;{{13d0:13}} 
        djnz    _ind_txt_unwrite_8;{{13d1:10fa}}  (-&06)
        call    _ind_txt_unwrite_20;{{13d3:cde113}} 
        pop     de                ;{{13d6:d1}} 
        pop     hl                ;{{13d7:e1}} 
        jr      nc,_ind_txt_unwrite_18;{{13d8:3001}}  (+&01)
        ret     nz                ;{{13da:c0}} 

_ind_txt_unwrite_18:              ;{{Addr=$13db Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PEN_number_);{{13db:3a2fb7}} 
        call    SCR_REPACK        ;{{13de:cd2a0f}}  SCR REPACK
_ind_txt_unwrite_20:              ;{{Addr=$13e1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$00             ;{{13e1:0e00}} 
_ind_txt_unwrite_21:              ;{{Addr=$13e3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{13e3:79}} 
        call    TXT_GET_MATRIX    ;{{13e4:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{13e7:1138b7}} 
        ld      b,$08             ;{{13ea:0608}} 
_ind_txt_unwrite_25:              ;{{Addr=$13ec Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13ec:1a}} 
        cp      (hl)              ;{{13ed:be}} 
        jr      nz,_ind_txt_unwrite_35;{{13ee:2009}}  (+&09)
        inc     hl                ;{{13f0:23}} 
        inc     de                ;{{13f1:13}} 
        djnz    _ind_txt_unwrite_25;{{13f2:10f8}}  (-&08)
        ld      a,c               ;{{13f4:79}} 
        cp      $8f               ;{{13f5:fe8f}} 
        scf                       ;{{13f7:37}} 
        ret                       ;{{13f8:c9}} 

_ind_txt_unwrite_35:              ;{{Addr=$13f9 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{13f9:0c}} 
        jr      nz,_ind_txt_unwrite_21;{{13fa:20e7}}  (-&19)
        xor     a                 ;{{13fc:af}} 
        ret                       ;{{13fd:c9}} 

;;===========================================================================
;; TXT OUTPUT

TXT_OUTPUT:                       ;{{Addr=$13fe Code Calls/jump count: 5 Data use count: 1}}
        push    af                ;{{13fe:f5}} 
        push    bc                ;{{13ff:c5}} 
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
        ld      c,a               ;{{140a:4f}} 
        ld      a,(graphics_character_writing_flag_);{{140b:3a33b7}} 
        or      a                 ;{{140e:b7}} 
        ld      a,c               ;{{140f:79}} 
        jp      nz,GRA_WR_CHAR    ;{{1410:c24019}}  GRA WR CHAR

        ld      hl,RAM_b758       ;{{1413:2158b7}} 
        ld      b,(hl)            ;{{1416:46}} 
        ld      a,b               ;{{1417:78}} 
        cp      $0a               ;{{1418:fe0a}} 
        jr      nc,_ind_txt_out_action_42;{{141a:3031}}  (+&31)
        or      a                 ;{{141c:b7}} 
        jr      nz,_ind_txt_out_action_15;{{141d:2006}}  (+&06)
        ld      a,c               ;{{141f:79}} 
        cp      $20               ;{{1420:fe20}} 
        jp      nc,TXT_WR_CHAR    ;{{1422:d23513}}  TXT WR CHAR
_ind_txt_out_action_15:           ;{{Addr=$1425 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{1425:04}} 
        ld      (hl),b            ;{{1426:70}} 
        ld      e,b               ;{{1427:58}} 
        ld      d,$00             ;{{1428:1600}} 
        add     hl,de             ;{{142a:19}} 
        ld      (hl),c            ;{{142b:71}} 


;; b759 = control code character
        ld      a,(RAM_b759)      ;{{142c:3a59b7}} 
        ld      e,a               ;{{142f:5f}} 

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
        ret     nc                ;{{143a:d0}} 

        ld      a,(cursor_flag_)  ;{{143b:3a2eb7}} 
        and     (hl)              ;{{143e:a6}} 
        rlca                      ;{{143f:07}} 
        jr      c,_ind_txt_out_action_42;{{1440:380b}}  (+&0b)

        inc     hl                ;{{1442:23}} 
        ld      e,(hl)            ;{{1443:5e}} ; function to execute
        inc     hl                ;{{1444:23}} 
        ld      d,(hl)            ;{{1445:56}} 
        ld      hl,RAM_b759       ;{{1446:2159b7}} 
        ld      a,c               ;{{1449:79}} 
        call    LOW_PCDE_INSTRUCTION;{{144a:cd1600}}  LOW: PCDE INSTRUCTION
_ind_txt_out_action_42:           ;{{Addr=$144d Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{144d:af}} 
        ld      (RAM_b758),a      ;{{144e:3258b7}} 
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
        call    _txt_cur_enable_1 ;{{145b:cd8812}} 
        jr      _ind_txt_out_action_42;{{145e:18ed}}  (-&13)

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
        ld      de,ASC_0_801513_NUL;{{146b:1163b7}} 
        ld      bc,$0060          ;{{146e:016000}} ##LIT##;WARNING: Code area used as literal
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
        ld      hl,ASC_0_801513_NUL;{{14d4:2163b7}} 
        ret                       ;{{14d7:c9}} 

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
        push    ix                ;{{14e1:dde5}} 
        ld      hl,data_for_control_character_BEL_sound;{{14e3:21d814}}  
        call    SOUND_QUEUE       ;{{14e6:cd1421}}  SOUND QUEUE
        pop     ix                ;{{14e9:dde1}} 

;;=============================================================================
;;performs control character 'ESC' function
performs_control_character_ESC_function:;{{Addr=$14eb Code Calls/jump count: 0 Data use count: 1}}
        ret                       ;{{14eb:c9}} 

;;=============================================================================
;; performs control character 'SYN' function
performs_control_character_SYN_function:;{{Addr=$14ec Code Calls/jump count: 0 Data use count: 1}}
        rrca                      ;{{14ec:0f}} 
        sbc     a,a               ;{{14ed:9f}} 
        jp      TXT_SET_BACK      ;{{14ee:c37b13}}  TXT SET BACK

;;=============================================================================
;; performs control character 'FS' function
performs_control_character_FS_function:;{{Addr=$14f1 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14f1:23}} 
        ld      a,(hl)            ;{{14f2:7e}}  pen number
        inc     hl                ;{{14f3:23}} 
        ld      b,(hl)            ;{{14f4:46}}  ink 1
        inc     hl                ;{{14f5:23}} 
        ld      c,(hl)            ;{{14f6:4e}}  ink 2
        jp      SCR_SET_INK       ;{{14f7:c3f20c}}  SCR SET INK

;;====================================================================
;; performs control character 'GS' instruction
performs_control_character_GS_instruction:;{{Addr=$14fa Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14fa:23}} 
        ld      b,(hl)            ;{{14fb:46}}  ink 1
        inc     hl                ;{{14fc:23}} 
        ld      c,(hl)            ;{{14fd:4e}}  ink 2
        jp      SCR_SET_BORDER    ;{{14fe:c3f70c}}  SCR SET BORDER

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
        jp      TXT_WIN_ENABLE    ;{{150a:c30812}}  TXT WIN ENABLE

;;====================================================================
;; performs control character 'EM' function
performs_control_character_EM_function:;{{Addr=$150d Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{150d:23}} 
        ld      a,(hl)            ;{{150e:7e}}  character index
        inc     hl                ;{{150f:23}} 
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
        jr      _performs_control_character_vt_function_1;{{151c:180d}}  (+&0d)

;;====================================================================
;; performs control character 'TAB' function
performs_control_character_TAB_function:;{{Addr=$151e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0100          ;{{151e:110001}} ##LIT##;WARNING: Code area used as literal
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
        push    de                ;{{152b:d5}} 
        call    scroll_window     ;{{152c:cda411}} 
        pop     de                ;{{152f:d1}} 

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
        jp      _txt_set_cursor_1 ;{{153c:c37311}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; performs control character 'CR' function
performs_control_character_CR_function:;{{Addr=$153f Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{153f:cda411}} 
        ld      a,(window_left_column_);{{1542:3a2ab7}} 
        jr      _performs_control_character_vt_function_9;{{1545:18ee}}  (-&12)

;;===========================================================================
;; performs control character 'US' function
performs_control_character_US_function:;{{Addr=$1547 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{1547:23}} 
        ld      d,(hl)            ;{{1548:56}}  column
        inc     hl                ;{{1549:23}} 
        ld      e,(hl)            ;{{154a:5e}}  row
        ex      de,hl             ;{{154b:eb}} 
        jp      TXT_SET_CURSOR    ;{{154c:c37011}}  TXT SET CURSOR

;;===========================================================================
;; TXT CLEAR WINDOW

TXT_CLEAR_WINDOW:                 ;{{Addr=$154f Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{154f:cdd0bd}}  IND: TXT UNDRAW CURSOR
        ld      hl,(window_top_line_);{{1552:2a29b7}} 
        ld      (Current_Stream_),hl;{{1555:2226b7}} 
        ld      de,(window_bottom_line_);{{1558:ed5b2bb7}} 
        jr      _performs_control_character_dc1_function_5;{{155c:1844}}  (+&44)

;;===========================================================================
;; performs control character 'DLE' function
performs_control_character_DLE_function:;{{Addr=$155e Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{155e:cda411}} 
        ld      d,h               ;{{1561:54}} 
        ld      e,l               ;{{1562:5d}} 
        jr      _performs_control_character_dc1_function_5;{{1563:183d}}  (+&3d)

;;===========================================================================
;; performs control character 'DC4' function
performs_control_character_DC4_function:;{{Addr=$1565 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC2_function;{{1565:cd8f15}}  control character 'DC2'
        ld      hl,(window_top_line_);{{1568:2a29b7}} 
        ld      de,(window_bottom_line_);{{156b:ed5b2bb7}} 
        ld      a,(Current_Stream_);{{156f:3a26b7}} 
        ld      l,a               ;{{1572:6f}} 
        inc     l                 ;{{1573:2c}} 
        cp      e                 ;{{1574:bb}} 
        ret     nc                ;{{1575:d0}} 

        jr      _performs_control_character_dc3_function_9;{{1576:1811}}  (+&11)

;;===========================================================================
;; performs control character 'DC3' function
performs_control_character_DC3_function:;{{Addr=$1578 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC1_function;{{1578:cd9915}}  control character 'DC1' function
        ld      hl,(window_top_line_);{{157b:2a29b7}} 
        ld      a,(window_right_colwnn_);{{157e:3a2cb7}} 
        ld      d,a               ;{{1581:57}} 
        ld      a,(Current_Stream_);{{1582:3a26b7}} 
        dec     a                 ;{{1585:3d}} 
        ld      e,a               ;{{1586:5f}} 
        cp      l                 ;{{1587:bd}} 
        ret     c                 ;{{1588:d8}} 

_performs_control_character_dc3_function_9:;{{Addr=$1589 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{1589:3a30b7}} 
        jp      SCR_FILL_BOX      ;{{158c:c3b90d}}  SCR FILL BOX

;;===========================================================================
;; performs control character 'DC2' function
performs_control_character_DC2_function:;{{Addr=$158f Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{158f:cda411}} 
        ld      e,l               ;{{1592:5d}} 
        ld      a,(window_right_colwnn_);{{1593:3a2cb7}} 
        ld      d,a               ;{{1596:57}} 
        jr      _performs_control_character_dc1_function_5;{{1597:1809}}  (+&09)

;;===========================================================================
;; performs control character 'DC1' function
performs_control_character_DC1_function:;{{Addr=$1599 Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{1599:cda411}} 
        ex      de,hl             ;{{159c:eb}} 
        ld      l,e               ;{{159d:6b}} 
        ld      a,(window_left_column_);{{159e:3a2ab7}} 
        ld      h,a               ;{{15a1:67}} 

;;---------------------------------------------------------------------------
_performs_control_character_dc1_function_5:;{{Addr=$15a2 Code Calls/jump count: 3 Data use count: 0}}
        call    _performs_control_character_dc3_function_9;{{15a2:cd8915}} 
        jp      TXT_DRAW_CURSOR   ;{{15a5:c3cdbd}}  IND: TXT DRAW CURSOR




;;***Graphics.asm
;; GRAPHICS ROUTINES
;;===========================================================================
;; GRA INITIALISE
GRA_INITIALISE:                   ;{{Addr=$15a8 Code Calls/jump count: 1 Data use count: 1}}
        call    GRA_RESET         ;{{15a8:cdd715}}  GRA RESET
        ld      hl,$0001          ;{{15ab:210100}} ##LIT##;WARNING: Code area used as literal
_gra_initialise_2:                ;{{Addr=$15ae Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{15ae:7c}} 
        call    GRA_SET_PAPER     ;{{15af:cd6e17}}  GRA SET PAPER
        ld      a,l               ;{{15b2:7d}} 
        call    GRA_SET_PEN       ;{{15b3:cd6717}}  GRA SET PEN
        ld      hl,$0000          ;{{15b6:210000}} ##LIT##;WARNING: Code area used as literal
        ld      d,h               ;{{15b9:54}} 
        ld      e,l               ;{{15ba:5d}} 
        call    GRA_SET_ORIGIN    ;{{15bb:cd0e16}}  GRA SET ORIGIN
        ld      de,$8000          ;{{15be:110080}} 
        ld      hl,$7fff          ;{{15c1:21ff7f}} 
        push    hl                ;{{15c4:e5}} 
        push    de                ;{{15c5:d5}} 
        call    GRA_WIN_WIDTH     ;{{15c6:cda516}}  GRA WIN WIDTH
        pop     hl                ;{{15c9:e1}} 
        pop     de                ;{{15ca:d1}} 
        jp      GRA_WIN_HEIGHT    ;{{15cb:c3ea16}}  GRA WIN HEIGHT
;;===========================================================================

x15ce_code:                       ;{{Addr=$15ce Code Calls/jump count: 1 Data use count: 0}}
        call    GRA_GET_PAPER     ;{{15ce:cd7a17}}  GRA GET PAPER
        ld      h,a               ;{{15d1:67}} 
        call    GRA_GET_PEN       ;{{15d2:cd7517}}  GRA GET PEN
        ld      l,a               ;{{15d5:6f}} 
        ret                       ;{{15d6:c9}} 

;;===========================================================================
;; GRA RESET
GRA_RESET:                        ;{{Addr=$15d7 Code Calls/jump count: 1 Data use count: 1}}
        call    _gra_default_2    ;{{15d7:cdf015}} 
        ld      hl,_gra_reset_3   ;{{15da:21e015}} ; table used to initialise graphics pack indirections
        jp      initialise_firmware_indirections;{{15dd:c3b40a}} ; initialise graphics pack indirections

_gra_reset_3:                     ;{{Addr=$15e0 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $09                  
        defw GRA_PLOT                
        jp      IND_GRA_PLOT      ; IND: GRA PLOT
        jp      IND_GRA_TEXT      ; IND: GRA TEXT
        jp      IND_GRA_LINE      ; IND: GRA LINE

;;===========================================================================
;; GRA DEFAULT

GRA_DEFAULT:                      ;{{Addr=$15ec Code Calls/jump count: 0 Data use count: 1}}
        xor     a                 ;{{15ec:af}} 
        call    SCR_ACCESS        ;{{15ed:cd550c}}  SCR ACCESS

_gra_default_2:                   ;{{Addr=$15f0 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{15f0:af}} 
        call    GRA_SET_BACK      ;{{15f1:cdd519}}  GRA SET BACK
        cpl                       ;{{15f4:2f}} 
        call    GRA_SET_FIRST     ;{{15f5:cdb017}}  GRA SET FIRST
        jp      GRA_SET_LINE_MASK ;{{15f8:c3ac17}}  GRA SET LINE MASK

;;===========================================================================
;; GRA MOVE RELATIVE
GRA_MOVE_RELATIVE:                ;{{Addr=$15fb Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{15fb:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate


;;==========================================================================
;; GRA MOVE ABSOLUTE
GRA_MOVE_ABSOLUTE:                ;{{Addr=$15fe Code Calls/jump count: 3 Data use count: 1}}
        ld      (graphics_text_x_position_),de;{{15fe:ed5397b6}}  absolute x
        ld      (graphics_text_y_position),hl;{{1602:2299b6}}  absolute y
        ret                       ;{{1605:c9}} 

;;===========================================================================
;; GRA ASK CURSOR
GRA_ASK_CURSOR:                   ;{{Addr=$1606 Code Calls/jump count: 2 Data use count: 1}}
        ld      de,(graphics_text_x_position_);{{1606:ed5b97b6}}  absolute x
        ld      hl,(graphics_text_y_position);{{160a:2a99b6}}  absolute y
        ret                       ;{{160d:c9}} 

;;===========================================================================
;; GRA SET ORIGIN
GRA_SET_ORIGIN:                   ;{{Addr=$160e Code Calls/jump count: 1 Data use count: 1}}
        ld      (ORIGIN_x),de     ;{{160e:ed5393b6}}  origin x
        ld      (ORIGIN_y),hl     ;{{1612:2295b6}}  origin y


;;===========================================================================
;; set absolute position to origin
set_absolute_position_to_origin:  ;{{Addr=$1615 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0000          ;{{1615:110000}}  x = 0 ##LIT##;WARNING: Code area used as literal
        ld      h,d               ;{{1618:62}} 
        ld      l,e               ;{{1619:6b}}  y = 0
        jr      GRA_MOVE_ABSOLUTE ;{{161a:18e2}}  GRA MOVE ABSOLUTE

;;===========================================================================
;; GRA GET ORIGIN
GRA_GET_ORIGIN:                   ;{{Addr=$161c Code Calls/jump count: 0 Data use count: 1}}
        ld      de,(ORIGIN_x)     ;{{161c:ed5b93b6}}  origin x	
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
        push    hl                ;{{162a:e5}} 
        call    SCR_GET_MODE      ;{{162b:cd0c0b}}  SCR GET MODE
        neg                       ;{{162e:ed44}} 
        sbc     a,$fd             ;{{1630:defd}} 
        ld      h,$00             ;{{1632:2600}} 
        ld      l,a               ;{{1634:6f}} 
        bit     7,d               ;{{1635:cb7a}} 
        jr      z,_gra_from_user_11;{{1637:2803}}  (+&03)
        ex      de,hl             ;{{1639:eb}} 
        add     hl,de             ;{{163a:19}} 
        ex      de,hl             ;{{163b:eb}} 
_gra_from_user_11:                ;{{Addr=$163c Code Calls/jump count: 1 Data use count: 0}}
        cpl                       ;{{163c:2f}} 
        and     e                 ;{{163d:a3}} 
        ld      e,a               ;{{163e:5f}} 
        ld      a,l               ;{{163f:7d}} 
        ld      hl,(ORIGIN_x)     ;{{1640:2a93b6}}  origin x
        add     hl,de             ;{{1643:19}} 
        rrca                      ;{{1644:0f}} 
        call    c,HL_div_2        ;{{1645:dce516}}  HL = HL/2
        rrca                      ;{{1648:0f}} 
        call    c,HL_div_2        ;{{1649:dce516}}  HL = HL/2
        pop     de                ;{{164c:d1}} 
        push    hl                ;{{164d:e5}} 
        ld      a,d               ;{{164e:7a}} 
        rlca                      ;{{164f:07}} 
        jr      nc,_gra_from_user_27;{{1650:3001}} 
        inc     de                ;{{1652:13}} 
_gra_from_user_27:                ;{{Addr=$1653 Code Calls/jump count: 1 Data use count: 0}}
        res     0,e               ;{{1653:cb83}} 
        ld      hl,(ORIGIN_y)     ;{{1655:2a95b6}}  origin y
        add     hl,de             ;{{1658:19}} 
        pop     de                ;{{1659:d1}} 
        jp      HL_div_2          ;{{165a:c3e516}}  HL = HL/2

;;==================================================================================
;; graph coord relative to absolute
;; convert relative graphics coordinate to absolute graphics coordinate
;; DE = relative X
;; HL = relative Y
graph_coord_relative_to_absolute: ;{{Addr=$165d Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{165d:e5}} 
        ld      hl,(graphics_text_x_position_);{{165e:2a97b6}}  absolute x		
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
        ld      hl,(graphics_window_x_of_one_edge_);{{166a:2a9bb6}}  graphics window left edge
        scf                       ;{{166d:37}} 
        sbc     hl,de             ;{{166e:ed52}} 
        jp      p,_x_graphics_coordinate_within_window_11;{{1670:f27e16}} 

        ld      hl,(graphics_window_x_of_other_edge_);{{1673:2a9db6}}  graphics window right edge
        or      a                 ;{{1676:b7}} 
        sbc     hl,de             ;{{1677:ed52}} 
        scf                       ;{{1679:37}} 
        ret     p                 ;{{167a:f0}} 

_x_graphics_coordinate_within_window_9:;{{Addr=$167b Code Calls/jump count: 1 Data use count: 0}}
        or      $ff               ;{{167b:f6ff}} 
        ret                       ;{{167d:c9}} 

_x_graphics_coordinate_within_window_11:;{{Addr=$167e Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{167e:af}} 
        ret                       ;{{167f:c9}} 

;;==================================================================================
;; y graphics coordinate within window
;; DE = y coordinate
y_graphics_coordinate_within_window:;{{Addr=$1680 Code Calls/jump count: 4 Data use count: 0}}
        ld      hl,(graphics_window_y_of_one_side_);{{1680:2a9fb6}}  graphics window top edge
        or      a                 ;{{1683:b7}} 
        sbc     hl,de             ;{{1684:ed52}} 
        jp      m,_x_graphics_coordinate_within_window_9;{{1686:fa7b16}} 
        ld      hl,(graphics_window_y_of_other_side_);{{1689:2aa1b6}}  graphics window bottom edge
        scf                       ;{{168c:37}} 
        sbc     hl,de             ;{{168d:ed52}} 
        jp      p,_x_graphics_coordinate_within_window_11;{{168f:f27e16}} 
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
        pop     hl                ;{{169b:e1}} 
        ret     nc                ;{{169c:d0}} 

        push    de                ;{{169d:d5}} 
        ex      de,hl             ;{{169e:eb}} 
        call    y_graphics_coordinate_within_window;{{169f:cd8016}}  Y graphics coordinate within window
        ex      de,hl             ;{{16a2:eb}} 
        pop     de                ;{{16a3:d1}} 
        ret                       ;{{16a4:c9}} 

;;==================================================================================
;; GRA WIN WIDTH
;; DE = left edge
;; HL = right edge
GRA_WIN_WIDTH:                    ;{{Addr=$16a5 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{16a5:e5}} 
        call    Make_X_coordinate_within_range_0639;{{16a6:cdd116}} ; Make X coordinate within range 0-639
        pop     de                ;{{16a9:d1}} 
        push    hl                ;{{16aa:e5}} 
        call    Make_X_coordinate_within_range_0639;{{16ab:cdd116}} ; Make X coordinate within range 0-639
        pop     de                ;{{16ae:d1}} 
        ld      a,e               ;{{16af:7b}} 
        sub     l                 ;{{16b0:95}} 
        ld      a,d               ;{{16b1:7a}} 
        sbc     a,h               ;{{16b2:9c}} 
        jr      c,_gra_win_width_12;{{16b3:3801}} 

        ex      de,hl             ;{{16b5:eb}} 
_gra_win_width_12:                ;{{Addr=$16b6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{16b6:7b}} 
        and     $f8               ;{{16b7:e6f8}} 
        ld      e,a               ;{{16b9:5f}} 
        ld      a,l               ;{{16ba:7d}} 
        or      $07               ;{{16bb:f607}} 
        ld      l,a               ;{{16bd:6f}} 
        call    SCR_GET_MODE      ;{{16be:cd0c0b}}  SCR GET MODE
        dec     a                 ;{{16c1:3d}} 
        call    m,DE_div_2_HL_div_2;{{16c2:fce116}}  DE = DE/2 and HL = HL/2
        dec     a                 ;{{16c5:3d}} 
        call    m,DE_div_2_HL_div_2;{{16c6:fce116}}  DE = DE/2 and HL = HL/2
        ld      (graphics_window_x_of_one_edge_),de;{{16c9:ed539bb6}}  graphics window left edge
        ld      (graphics_window_x_of_other_edge_),hl;{{16cd:229db6}}  graphics window right edge
        ret                       ;{{16d0:c9}} 

;;==================================================================================
;; Make X coordinate within range 0-639
Make_X_coordinate_within_range_0639:;{{Addr=$16d1 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{16d1:7a}} 
        or      a                 ;{{16d2:b7}} 
        ld      hl,$0000          ;{{16d3:210000}} ##LIT##;WARNING: Code area used as literal
        ret     m                 ;{{16d6:f8}} 

        ld      hl,$027f          ;{{16d7:217f02}}  639 ##LIT##;WARNING: Code area used as literal
        ld      a,e               ;{{16da:7b}} 
        sub     l                 ;{{16db:95}} 
        ld      a,d               ;{{16dc:7a}} 
        sbc     a,h               ;{{16dd:9c}} 
        ret     nc                ;{{16de:d0}} 

        ex      de,hl             ;{{16df:eb}} 
        ret                       ;{{16e0:c9}} 

;;==================================================================================
;; DE div 2 HL div 2
;; DE = DE/2
;; HL = HL/2
DE_div_2_HL_div_2:                ;{{Addr=$16e1 Code Calls/jump count: 2 Data use count: 0}}
        sra     d                 ;{{16e1:cb2a}} 
        rr      e                 ;{{16e3:cb1b}} 

;;+----------------------------------------------------------------------------------
;; HL div 2
;; HL = HL/2
HL_div_2:                         ;{{Addr=$16e5 Code Calls/jump count: 5 Data use count: 0}}
        sra     h                 ;{{16e5:cb2c}} 
        rr      l                 ;{{16e7:cb1d}} 
        ret                       ;{{16e9:c9}} 

;;==================================================================================
;; GRA WIN HEIGHT
GRA_WIN_HEIGHT:                   ;{{Addr=$16ea Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{16ea:e5}} 
        call    make_Y_coordinate_in_range_0199;{{16eb:cd0317}} ; make Y coordinate in range 0-199
        pop     de                ;{{16ee:d1}} 
        push    hl                ;{{16ef:e5}} 
        call    make_Y_coordinate_in_range_0199;{{16f0:cd0317}} ; make Y coordinate in range 0-199
        pop     de                ;{{16f3:d1}} 
        ld      a,l               ;{{16f4:7d}} 
        sub     e                 ;{{16f5:93}} 
        ld      a,h               ;{{16f6:7c}} 
        sbc     a,d               ;{{16f7:9a}} 
        jr      c,_gra_win_height_12;{{16f8:3801}}  (+&01)
        ex      de,hl             ;{{16fa:eb}} 
_gra_win_height_12:               ;{{Addr=$16fb Code Calls/jump count: 1 Data use count: 0}}
        ld      (graphics_window_y_of_one_side_),de;{{16fb:ed539fb6}}  graphics window top edge
        ld      (graphics_window_y_of_other_side_),hl;{{16ff:22a1b6}}  graphics window bottom edge
        ret                       ;{{1702:c9}} 

;;==================================================================================
;; make Y coordinate in range 0-199

make_Y_coordinate_in_range_0199:  ;{{Addr=$1703 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{1703:7a}} 
        or      a                 ;{{1704:b7}} 
        ld      hl,$0000          ;{{1705:210000}} ##LIT##;WARNING: Code area used as literal
        ret     m                 ;{{1708:f8}} 

        srl     d                 ;{{1709:cb3a}} 
        rr      e                 ;{{170b:cb1b}} 
        ld      hl,$00c7          ;{{170d:21c700}}  199 ##LIT##;WARNING: Code area used as literal
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
        ld      hl,(graphics_window_x_of_other_edge_);{{171b:2a9db6}}  graphics window right edge
        call    SCR_GET_MODE      ;{{171e:cd0c0b}}  SCR GET MODE
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
        add     hl,hl             ;{{172a:29}} 
        ex      de,hl             ;{{172b:eb}} 

        ret                       ;{{172c:c9}} 
;;==================================================================================
;; GRA GET W HEIGHT
GRA_GET_W_HEIGHT:                 ;{{Addr=$172d Code Calls/jump count: 0 Data use count: 1}}
        ld      de,(graphics_window_y_of_one_side_);{{172d:ed5b9fb6}}  graphics window top edge
        ld      hl,(graphics_window_y_of_other_side_);{{1731:2aa1b6}}  graphics window bottom edge
        jr      _gra_get_w_width_7;{{1734:18f1}} 
;;==================================================================================
;; GRA CLEAR WINDOW
GRA_CLEAR_WINDOW:                 ;{{Addr=$1736 Code Calls/jump count: 0 Data use count: 1}}
        call    GRA_GET_W_WIDTH   ;{{1736:cd1717}}  GRA GET W WIDTH
        or      a                 ;{{1739:b7}} 
        sbc     hl,de             ;{{173a:ed52}} 
        inc     hl                ;{{173c:23}} 
        call    HL_div_2          ;{{173d:cde516}}  HL = HL/2
        call    HL_div_2          ;{{1740:cde516}}  HL = HL/2
        srl     l                 ;{{1743:cb3d}} 
        ld      b,l               ;{{1745:45}} 
        ld      de,(graphics_window_y_of_other_side_);{{1746:ed5ba1b6}}  graphics window bottom edge
        ld      hl,(graphics_window_y_of_one_side_);{{174a:2a9fb6}}  graphics window top edge
        push    hl                ;{{174d:e5}} 
        or      a                 ;{{174e:b7}} 
        sbc     hl,de             ;{{174f:ed52}} 
        inc     hl                ;{{1751:23}} 
        ld      c,l               ;{{1752:4d}} 
        ld      de,(graphics_window_x_of_one_edge_);{{1753:ed5b9bb6}}  graphics window left edge
        pop     hl                ;{{1757:e1}} 
        push    bc                ;{{1758:c5}} 
        call    SCR_DOT_POSITION  ;{{1759:cdaf0b}} ; SCR DOT POSITION
        pop     de                ;{{175c:d1}} 
        ld      a,(GRAPHICS_PAPER);{{175d:3aa4b6}}  graphics paper
        ld      c,a               ;{{1760:4f}} 
        call    SCR_FLOOD_BOX     ;{{1761:cdbd0d}} ; SCR FLOOD BOX
        jp      set_absolute_position_to_origin;{{1764:c31516}} ; set absolute position to origin

;;==================================================================================
;; GRA SET PEN
GRA_SET_PEN:                      ;{{Addr=$1767 Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_INK_ENCODE    ;{{1767:cd8e0c}} ; SCR INK ENCODE
        ld      (GRAPHICS_PEN),a  ;{{176a:32a3b6}}  graphics pen
        ret                       ;{{176d:c9}} 

;;==================================================================================
;; GRA SET PAPER
GRA_SET_PAPER:                    ;{{Addr=$176e Code Calls/jump count: 1 Data use count: 1}}
        call    SCR_INK_ENCODE    ;{{176e:cd8e0c}} ; SCR INK ENCODE
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
        ld      a,(GRAPHICS_PAPER);{{177a:3aa4b6}}  graphics paper
_gra_get_paper_1:                 ;{{Addr=$177d Code Calls/jump count: 1 Data use count: 0}}
        jp      SCR_INK_DECODE    ;{{177d:c3a70c}} ; SCR INK DECODE

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

        call    SCR_DOT_POSITION  ;{{178a:cdaf0b}} ; SCR DOT POSITION
        ld      a,(GRAPHICS_PEN)  ;{{178d:3aa3b6}}  graphics pen
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
        call    current_point_within_graphics_window;{{179a:cd9416}}  test if current coordinate within graphics window
        jp      nc,GRA_GET_PAPER  ;{{179d:d27a17}}  GRA GET PAPER
        call    SCR_DOT_POSITION  ;{{17a0:cdaf0b}}  SCR DOT POSITION
        jp      SCR_READ          ;{{17a3:c3e5bd}}  IND: SCR READ

;;===========================================================================
;; GRA LINE RELATIVE
GRA_LINE_RELATIVE:                ;{{Addr=$17a6 Code Calls/jump count: 0 Data use count: 1}}
        call    graph_coord_relative_to_absolute;{{17a6:cd5d16}}  convert relative graphics coordinate to
                                  ; absolute graphics coordinate

;;===========================================================================
;; GRA LINE ABSOLUTE
GRA_LINE_ABSOLUTE:                ;{{Addr=$17a9 Code Calls/jump count: 0 Data use count: 1}}
        jp      GRA_LINE          ;{{17a9:c3e2bd}}  IND: GRA LINE

;;===========================================================================
;; GRA SET LINE MASK

GRA_SET_LINE_MASK:                ;{{Addr=$17ac Code Calls/jump count: 1 Data use count: 1}}
        ld      (line_MASK),a     ;{{17ac:32b3b6}}  gra line mask
        ret                       ;{{17af:c9}} 

;;===========================================================================
;; GRA SET FIRST

GRA_SET_FIRST:                    ;{{Addr=$17b0 Code Calls/jump count: 1 Data use count: 1}}
        ld      (first_point_on_drawn_line_flag_),a;{{17b0:32b2b6}} 
        ret                       ;{{17b3:c9}} 

;;===========================================================================
;; IND: GRA LINE
IND_GRA_LINE:                     ;{{Addr=$17b4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{17b4:e5}} 
        call    gra_line_sub_1    ;{{17b5:cd8b18}}  get cursor absolute position
        pop     hl                ;{{17b8:e1}} 
        call    _get_cursor_absolute_user_coordinate_1;{{17b9:cd2716}}  get absolute user coordinate

;; remember Y coordinate
        push    hl                ;{{17bc:e5}} 

;; DE = X coordinate

;;-------------------------------------------

;; calculate dx
        ld      hl,(RAM_b6a5)     ;{{17bd:2aa5b6}}  absolute user X coordinate
        or      a                 ;{{17c0:b7}} 
        sbc     hl,de             ;{{17c1:ed52}} 

;; this will record the fact of dx is +ve or negative
        ld      a,h               ;{{17c3:7c}} 
        ld      (RAM_b6ad),a      ;{{17c4:32adb6}} 

;; if dx is negative, make it positive
        call    m,invert_HL       ;{{17c7:fc3919}}  HL = -HL

;; HL = abs(dx)

;;-------------------------------------------

;; calculate dy
        pop     de                ;{{17ca:d1}} 
;; DE = Y coordinate
        push    hl                ;{{17cb:e5}} 
        ld      hl,(x1)           ;{{17cc:2aa7b6}}  absolute user Y coordinate
        or      a                 ;{{17cf:b7}} 
        sbc     hl,de             ;{{17d0:ed52}} 

;; this stores the fact of dy is +ve or negative
        ld      a,h               ;{{17d2:7c}} 
        ld      ($b6ae),a         ;{{17d3:32aeb6}} 

;; if dy is negative, make it positive
        call    m,invert_HL       ;{{17d6:fc3919}}  HL = -HL

;; HL = abs(dy)


        pop     de                ;{{17d9:d1}} 
;; DE = abs(dx)
;; HL = abs(dy)

;;-------------------------------------------

;; is dx or dy largest?
        or      a                 ;{{17da:b7}} 
        sbc     hl,de             ;{{17db:ed52}}  dy-dx
        add     hl,de             ;{{17dd:19}}  and return it back to their original values

        sbc     a,a               ;{{17de:9f}} 
        ld      (RAM_b6af),a      ;{{17df:32afb6}}  remembers which of dy/dx was largest

        ld      a,($b6ae)         ;{{17e2:3aaeb6}}  dy is negative
        jr      z,_ind_gra_line_29;{{17e5:2804}}  depends on result of dy-dx

;; if yes, then swap dx/dy
        ex      de,hl             ;{{17e7:eb}} 
;; DE = abs(dy)
;; HL = abs(dx)

        ld      a,(RAM_b6ad)      ;{{17e8:3aadb6}}  dx is negative

;;-------------------------------------------

_ind_gra_line_29:                 ;{{Addr=$17eb Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{17eb:f5}} 
        ld      (y2x),de          ;{{17ec:ed53abb6}} 
        ld      b,h               ;{{17f0:44}} 
        ld      c,l               ;{{17f1:4d}} 
        ld      a,(first_point_on_drawn_line_flag_);{{17f2:3ab2b6}} 
        or      a                 ;{{17f5:b7}} 
        jr      z,_ind_gra_line_37;{{17f6:2801}}  (+&01)
        inc     bc                ;{{17f8:03}} 
_ind_gra_line_37:                 ;{{Addr=$17f9 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6b0),bc     ;{{17f9:ed43b0b6}} 
        call    invert_HL         ;{{17fd:cd3919}}  HL = -HL
        push    hl                ;{{1800:e5}} 
        add     hl,de             ;{{1801:19}} 
        ld      (y21),hl          ;{{1802:22a9b6}} 
        pop     hl                ;{{1805:e1}} 
        sra     h                 ;{{1806:cb2c}} ; /2 for y coordinate (0-400 GRA coordinates, 0-200 actual number of lines)
        rr      l                 ;{{1808:cb1d}} 
        pop     af                ;{{180a:f1}} 
        rlca                      ;{{180b:07}} 
        jr      c,_ind_gra_line_59;{{180c:3812}}  (+&12)
        push    hl                ;{{180e:e5}} 
        call    gra_line_sub_1    ;{{180f:cd8b18}}  get cursor absolute position
        ld      hl,(RAM_b6ad)     ;{{1812:2aadb6}} 
        ld      a,h               ;{{1815:7c}} 
        cpl                       ;{{1816:2f}} 
        ld      h,a               ;{{1817:67}} 
        ld      a,l               ;{{1818:7d}} 
        cpl                       ;{{1819:2f}} 
        ld      l,a               ;{{181a:6f}} 
        ld      (RAM_b6ad),hl     ;{{181b:22adb6}} 
        jr      _ind_gra_line_68  ;{{181e:1812}}  (+&12)


_ind_gra_line_59:                 ;{{Addr=$1820 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(first_point_on_drawn_line_flag_);{{1820:3ab2b6}} 
        or      a                 ;{{1823:b7}} 
        jr      nz,_ind_gra_line_69;{{1824:200d}}  (+&0d)
        add     hl,de             ;{{1826:19}} 
        push    hl                ;{{1827:e5}} 

        ld      a,(RAM_b6af)      ;{{1828:3aafb6}}  dy or dx was biggest?
        rlca                      ;{{182b:07}} 
        call    c,_gra_line_sub_2_33;{{182c:dcda18}}  plot a pixel moving up
        call    nc,_clip_coords_to_be_within_range_31;{{182f:d42819}}  plot a pixel moving right

_ind_gra_line_68:                 ;{{Addr=$1832 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{1832:e1}} 
_ind_gra_line_69:                 ;{{Addr=$1833 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{1833:7a}} 
        or      e                 ;{{1834:b3}} 
        jp      z,gra_line_sub_2  ;{{1835:ca9818}} 
        push    ix                ;{{1838:dde5}} 
        ld      bc,$0000          ;{{183a:010000}} ##LIT##;WARNING: Code area used as literal
        push    bc                ;{{183d:c5}} 
        pop     ix                ;{{183e:dde1}} 
_ind_gra_line_76:                 ;{{Addr=$1840 Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{1840:dde5}} 
        pop     de                ;{{1842:d1}} 
        or      a                 ;{{1843:b7}} 
        adc     hl,de             ;{{1844:ed5a}} 
        ld      de,(y2x)          ;{{1846:ed5babb6}} 
        jp      p,_ind_gra_line_86;{{184a:f25318}} 
_ind_gra_line_82:                 ;{{Addr=$184d Code Calls/jump count: 1 Data use count: 0}}
        inc     bc                ;{{184d:03}} 
        add     ix,de             ;{{184e:dd19}} 
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
        jr      nc,_ind_gra_line_97;{{185a:3005}}  (+&05)
        add     ix,de             ;{{185c:dd19}} 
        dec     bc                ;{{185e:0b}} 
        jr      _ind_gra_line_92  ;{{185f:18f8}}  (-&08)


_ind_gra_line_97:                 ;{{Addr=$1861 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(y21)          ;{{1861:ed5ba9b6}} 
        add     hl,de             ;{{1865:19}} 
        push    bc                ;{{1866:c5}} 
        push    hl                ;{{1867:e5}} 
        ld      hl,(RAM_b6b0)     ;{{1868:2ab0b6}} 
        or      a                 ;{{186b:b7}} 
        sbc     hl,bc             ;{{186c:ed42}} 
        jr      nc,_ind_gra_line_109;{{186e:3006}}  (+&06)

        add     hl,bc             ;{{1870:09}} 
        ld      b,h               ;{{1871:44}} 
        ld      c,l               ;{{1872:4d}} 
        ld      hl,$0000          ;{{1873:210000}} ##LIT##;WARNING: Code area used as literal

_ind_gra_line_109:                ;{{Addr=$1876 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6b0),hl     ;{{1876:22b0b6}} 
        call    gra_line_sub_2    ;{{1879:cd9818}}  plot with clip
        pop     hl                ;{{187c:e1}} 
        pop     bc                ;{{187d:c1}} 
        jr      nc,_ind_gra_line_118;{{187e:3008}}  (+&08)
        ld      de,(RAM_b6b0)     ;{{1880:ed5bb0b6}} 
        ld      a,d               ;{{1884:7a}} 
        or      e                 ;{{1885:b3}} 
        jr      nz,_ind_gra_line_76;{{1886:20b8}}  (-&48)
_ind_gra_line_118:                ;{{Addr=$1888 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{1888:dde1}} 
        ret                       ;{{188a:c9}} 
    
;;==================================================================================
;; gra line sub 1

gra_line_sub_1:                   ;{{Addr=$188b Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{188b:d5}} 
        call    get_cursor_absolute_user_coordinate;{{188c:cd2416}} ; get cursor absolute user coordinate
        ld      (RAM_b6a5),de     ;{{188f:ed53a5b6}} 
        ld      (x1),hl           ;{{1893:22a7b6}} 
        pop     de                ;{{1896:d1}} 
        ret                       ;{{1897:c9}} 

;;==================================================================================
;; gra line sub 2

gra_line_sub_2:                   ;{{Addr=$1898 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_b6af)      ;{{1898:3aafb6}} 
        rlca                      ;{{189b:07}} 
        jr      c,clip_coords_to_be_within_range;{{189c:384d}}  (+&4d)
        ld      a,b               ;{{189e:78}} 
        or      c                 ;{{189f:b1}} 
        jr      z,_gra_line_sub_2_33;{{18a0:2838}}  (+&38)
        ld      hl,(x1)           ;{{18a2:2aa7b6}} 
        add     hl,bc             ;{{18a5:09}} 
        dec     hl                ;{{18a6:2b}} 
        ld      b,h               ;{{18a7:44}} 
        ld      c,l               ;{{18a8:4d}} 
        ex      de,hl             ;{{18a9:eb}} 
        call    y_graphics_coordinate_within_window;{{18aa:cd8016}}  Y graphics coordinate within window
        ld      hl,(x1)           ;{{18ad:2aa7b6}} 
        ex      de,hl             ;{{18b0:eb}} 
        inc     hl                ;{{18b1:23}} 
        ld      (x1),hl           ;{{18b2:22a7b6}} 
        jr      c,_gra_line_sub_2_20;{{18b5:3806}}  
        jr      z,_gra_line_sub_2_33;{{18b7:2821}}  
        ld      bc,(graphics_window_y_of_one_side_);{{18b9:ed4b9fb6}}  graphics window top edge
_gra_line_sub_2_20:               ;{{Addr=$18bd Code Calls/jump count: 1 Data use count: 0}}
        call    y_graphics_coordinate_within_window;{{18bd:cd8016}}  Y graphics coordinate within window
        jr      c,_gra_line_sub_2_24;{{18c0:3805}}  (+&05)
        ret     nz                ;{{18c2:c0}} 

        ld      de,(graphics_window_y_of_other_side_);{{18c3:ed5ba1b6}}  graphics window bottom edge
_gra_line_sub_2_24:               ;{{Addr=$18c7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{18c7:d5}} 
        ld      de,(RAM_b6a5)     ;{{18c8:ed5ba5b6}} 
        call    X_graphics_coordinate_within_window;{{18cc:cd6a16}}  graphics x coordinate within window
        pop     hl                ;{{18cf:e1}} 
        jr      c,_gra_line_sub_2_32;{{18d0:3805}}  (+&05)
        ld      hl,RAM_b6ad       ;{{18d2:21adb6}} 
        xor     (hl)              ;{{18d5:ae}} 
        ret     p                 ;{{18d6:f0}} 

_gra_line_sub_2_32:               ;{{Addr=$18d7 Code Calls/jump count: 1 Data use count: 0}}
        call    c,_scr_vertical_67;{{18d7:dc1610}}  plot a pixel, going up a line


_gra_line_sub_2_33:               ;{{Addr=$18da Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(RAM_b6a5)     ;{{18da:2aa5b6}} 
        ld      a,(RAM_b6ad)      ;{{18dd:3aadb6}} 
        rlca                      ;{{18e0:07}} 
        inc     hl                ;{{18e1:23}} 
        jr      c,_gra_line_sub_2_40;{{18e2:3802}}  (+&02)
        dec     hl                ;{{18e4:2b}} 
        dec     hl                ;{{18e5:2b}} 
_gra_line_sub_2_40:               ;{{Addr=$18e6 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b6a5),hl     ;{{18e6:22a5b6}} 
        scf                       ;{{18e9:37}} 
        ret                       ;{{18ea:c9}} 

;;=============================
;; clip coords to be within range
;; we work with coordinates...

;; this performs the clipping to find if the coordinates are within range

clip_coords_to_be_within_range:   ;{{Addr=$18eb Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{18eb:78}} 
        or      c                 ;{{18ec:b1}} 
        jr      z,_clip_coords_to_be_within_range_31;{{18ed:2839}}  (+&39)
        ld      hl,(RAM_b6a5)     ;{{18ef:2aa5b6}} 
        add     hl,bc             ;{{18f2:09}} 
        dec     hl                ;{{18f3:2b}} 
        ld      b,h               ;{{18f4:44}} 
        ld      c,l               ;{{18f5:4d}} 
        ex      de,hl             ;{{18f6:eb}} 
        call    X_graphics_coordinate_within_window;{{18f7:cd6a16}}  x graphics coordinate within window
        ld      hl,(RAM_b6a5)     ;{{18fa:2aa5b6}} 
        ex      de,hl             ;{{18fd:eb}} 
        inc     hl                ;{{18fe:23}} 
        ld      (RAM_b6a5),hl     ;{{18ff:22a5b6}} 
        jr      c,_clip_coords_to_be_within_range_17;{{1902:3806}} 
        jr      z,_clip_coords_to_be_within_range_31;{{1904:2822}} 
        ld      bc,(graphics_window_x_of_other_edge_);{{1906:ed4b9db6}}  graphics window right edge
_clip_coords_to_be_within_range_17:;{{Addr=$190a Code Calls/jump count: 1 Data use count: 0}}
        call    X_graphics_coordinate_within_window;{{190a:cd6a16}}  x graphics coordinate within window
        jr      c,_clip_coords_to_be_within_range_21;{{190d:3805}} 
        ret     nz                ;{{190f:c0}} 

        ld      de,(graphics_window_x_of_one_edge_);{{1910:ed5b9bb6}}  graphics window left edge
_clip_coords_to_be_within_range_21:;{{Addr=$1914 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{1914:d5}} 
        ld      de,(x1)           ;{{1915:ed5ba7b6}} 
        call    y_graphics_coordinate_within_window;{{1919:cd8016}}  Y graphics coordinate within window
        pop     hl                ;{{191c:e1}} 
        jr      c,_clip_coords_to_be_within_range_29;{{191d:3805}}  (+&05)

        ld      hl,$b6ae          ;{{191f:21aeb6}} 
        xor     (hl)              ;{{1922:ae}} 
        ret     p                 ;{{1923:f0}} 

_clip_coords_to_be_within_range_29:;{{Addr=$1924 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{1924:eb}} 
        call    c,_scr_vertical_18;{{1925:dcc20f}}  plot a pixel moving right

_clip_coords_to_be_within_range_31:;{{Addr=$1928 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(x1)           ;{{1928:2aa7b6}} 
        ld      a,($b6ae)         ;{{192b:3aaeb6}} 
        rlca                      ;{{192e:07}} 
        inc     hl                ;{{192f:23}} 
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
        sub     l                 ;{{193a:95}} 
        ld      l,a               ;{{193b:6f}} 
        sbc     a,a               ;{{193c:9f}} 
        sub     h                 ;{{193d:94}} 
        ld      h,a               ;{{193e:67}} 
        ret                       ;{{193f:c9}} 

;;===========================================================================
;; GRA WR CHAR

GRA_WR_CHAR:                      ;{{Addr=$1940 Code Calls/jump count: 1 Data use count: 2}}
        push    ix                ;{{1940:dde5}} 
        call    TXT_GET_MATRIX    ;{{1942:cdd412}}  TXT GET MATRIX
        push    hl                ;{{1945:e5}} 
        pop     ix                ;{{1946:dde1}} 
        call    get_cursor_absolute_user_coordinate;{{1948:cd2416}} ; get cursor absolute user coordinate
        call    _current_point_within_graphics_window_1;{{194b:cd9716}} ; point in graphics window
        jr      nc,gra_wr_char_sub_2;{{194e:304b}}  (+&4b)
        push    hl                ;{{1950:e5}} 
        push    de                ;{{1951:d5}} 
        ld      bc,$0007          ;{{1952:010700}} ##LIT##;WARNING: Code area used as literal
        ex      de,hl             ;{{1955:eb}} 
        add     hl,bc             ;{{1956:09}} 
        ex      de,hl             ;{{1957:eb}} 
        or      a                 ;{{1958:b7}} 
        sbc     hl,bc             ;{{1959:ed42}} 
        call    _current_point_within_graphics_window_1;{{195b:cd9716}} ; point in graphics window
        pop     de                ;{{195e:d1}} 
        pop     hl                ;{{195f:e1}} 
        jr      nc,gra_wr_char_sub_2;{{1960:3039}}  (+&39)
        call    SCR_DOT_POSITION  ;{{1962:cdaf0b}} ; SCR DOT POSITION
        ld      d,$08             ;{{1965:1608}} 
_gra_wr_char_21:                  ;{{Addr=$1967 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1967:e5}} 
        ld      e,(ix+$00)        ;{{1968:dd5e00}} 
        scf                       ;{{196b:37}} 
        rl      e                 ;{{196c:cb13}} 
_gra_wr_char_25:                  ;{{Addr=$196e Code Calls/jump count: 1 Data use count: 0}}
        call    gra_wr_char_sub_3 ;{{196e:cdc419}} 
        rrc     c                 ;{{1971:cb09}} 
        call    c,SCR_NEXT_BYTE   ;{{1973:dc050c}}  SCR NEXT BYTE
        sla     e                 ;{{1976:cb23}} 
        jr      nz,_gra_wr_char_25;{{1978:20f4}}  (-&0c)
        pop     hl                ;{{197a:e1}} 
        call    SCR_NEXT_LINE     ;{{197b:cd1f0c}}  SCR NEXT LINE
        inc     ix                ;{{197e:dd23}} 
        dec     d                 ;{{1980:15}} 
        jr      nz,_gra_wr_char_21;{{1981:20e4}}  (-&1c)
_gra_wr_char_35:                  ;{{Addr=$1983 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{1983:dde1}} 
        call    GRA_ASK_CURSOR    ;{{1985:cd0616}}  GRA ASK CURSOR
        ex      de,hl             ;{{1988:eb}} 
        call    SCR_GET_MODE      ;{{1989:cd0c0b}}  SCR GET MODE
        ld      bc,$0008          ;{{198c:010800}} ##LIT##;WARNING: Code area used as literal
        jr      z,_gra_wr_char_44 ;{{198f:2804}}  (+&04)
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
        ld      b,$08             ;{{199b:0608}} 
_gra_wr_char_sub_2_1:             ;{{Addr=$199d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{199d:c5}} 
        push    de                ;{{199e:d5}} 
        ld      a,(ix+$00)        ;{{199f:dd7e00}} 
        scf                       ;{{19a2:37}} 
        adc     a,a               ;{{19a3:8f}} 
_gra_wr_char_sub_2_6:             ;{{Addr=$19a4 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{19a4:e5}} 
        push    de                ;{{19a5:d5}} 
        push    af                ;{{19a6:f5}} 
        call    _current_point_within_graphics_window_1;{{19a7:cd9716}} ; point in graphics window
        jr      nc,_gra_wr_char_sub_2_15;{{19aa:3008}}  (+&08)
        call    SCR_DOT_POSITION  ;{{19ac:cdaf0b}} ; SCR DOT POSITION
        pop     af                ;{{19af:f1}} 
        push    af                ;{{19b0:f5}} 
        call    gra_wr_char_sub_3 ;{{19b1:cdc419}} 
_gra_wr_char_sub_2_15:            ;{{Addr=$19b4 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{19b4:f1}} 
        pop     de                ;{{19b5:d1}} 
        pop     hl                ;{{19b6:e1}} 
        inc     de                ;{{19b7:13}} 
        add     a,a               ;{{19b8:87}} 
        jr      nz,_gra_wr_char_sub_2_6;{{19b9:20e9}}  (-&17)
        pop     de                ;{{19bb:d1}} 
        dec     hl                ;{{19bc:2b}} 
        inc     ix                ;{{19bd:dd23}} 
        pop     bc                ;{{19bf:c1}} 
        djnz    _gra_wr_char_sub_2_1;{{19c0:10db}}  (-&25)
        jr      _gra_wr_char_35   ;{{19c2:18bf}}  (-&41)

;;==================================================================================
;; gra wr char sub 3

gra_wr_char_sub_3:                ;{{Addr=$19c4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(GRAPHICS_PEN)  ;{{19c4:3aa3b6}}  graphics pen
        jr      c,_gra_wr_char_sub_3_6;{{19c7:3808}}  (+&08)
        ld      a,(RAM_b6b4)      ;{{19c9:3ab4b6}} 
        or      a                 ;{{19cc:b7}} 
        ret     nz                ;{{19cd:c0}} 

        ld      a,(GRAPHICS_PAPER);{{19ce:3aa4b6}}  graphics paper
_gra_wr_char_sub_3_6:             ;{{Addr=$19d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{19d1:47}} 
        jp      SCR_WRITE         ;{{19d2:c3e8bd}}  IND: SCR WRITE

;;===========================================================================
;; GRA SET BACK

GRA_SET_BACK:                     ;{{Addr=$19d5 Code Calls/jump count: 1 Data use count: 1}}
        ld      (RAM_b6b4),a      ;{{19d5:32b4b6}} 
        ret                       ;{{19d8:c9}} 

;;===========================================================================
;; GRA FILL
;; HL = buffer
;; A = pen to fill
;; DE = length of buffer

GRA_FILL:                         ;{{Addr=$19d9 Code Calls/jump count: 0 Data use count: 1}}
        ld      (RAM_b6a5),hl     ;{{19d9:22a5b6}} 
        ld      (hl),$01          ;{{19dc:3601}} 
        dec     de                ;{{19de:1b}} 
        ld      (x1),de           ;{{19df:ed53a7b6}} 
        call    SCR_INK_ENCODE    ;{{19e3:cd8e0c}} ; SCR INK ENCODE
        ld      ($b6aa),a         ;{{19e6:32aab6}} 
        call    get_cursor_absolute_user_coordinate;{{19e9:cd2416}} ; get cursor absolute user coordinate
        call    _current_point_within_graphics_window_1;{{19ec:cd9716}} ; point in graphics window
        call    c,gra_fill_sub_5  ;{{19ef:dc421b}} 
        ret     nc                ;{{19f2:d0}} 

        push    hl                ;{{19f3:e5}} 
        call    _gra_fill_sub_2_83;{{19f4:cde71a}} 
        ex      (sp),hl           ;{{19f7:e3}} 
        call    _gra_fill_sub_3_23;{{19f8:cd151b}} 
        pop     bc                ;{{19fb:c1}} 
        ld      a,$ff             ;{{19fc:3eff}} 
        ld      (y21),a           ;{{19fe:32a9b6}} 
        push    hl                ;{{1a01:e5}} 
        push    de                ;{{1a02:d5}} 
        push    bc                ;{{1a03:c5}} 
        call    _gra_fill_25      ;{{1a04:cd0b1a}} 
        pop     bc                ;{{1a07:c1}} 
        pop     de                ;{{1a08:d1}} 
        pop     hl                ;{{1a09:e1}} 
        xor     a                 ;{{1a0a:af}} 
_gra_fill_25:                     ;{{Addr=$1a0b Code Calls/jump count: 1 Data use count: 0}}
        ld      (y2x),a           ;{{1a0b:32abb6}} 
_gra_fill_26:                     ;{{Addr=$1a0e Code Calls/jump count: 1 Data use count: 0}}
        call    _gra_fill_sub_2_76;{{1a0e:cdde1a}} 
_gra_fill_27:                     ;{{Addr=$1a11 Code Calls/jump count: 1 Data use count: 0}}
        call    _current_point_within_graphics_window_1;{{1a11:cd9716}} ; point in graphics window
        call    c,gra_fill_sub_2  ;{{1a14:dc501a}} 
        jr      c,_gra_fill_26    ;{{1a17:38f5}}  (-&0b)
        ld      hl,(RAM_b6a5)     ;{{1a19:2aa5b6}}  graphics fill buffer
        rst     $20               ;{{1a1c:e7}}  RST 4 - LOW: RAM LAM
        cp      $01               ;{{1a1d:fe01}} 
        jr      z,_gra_fill_65    ;{{1a1f:282a}}  (+&2a)
        ld      (y2x),a           ;{{1a21:32abb6}} 
        ex      de,hl             ;{{1a24:eb}} 
        ld      hl,(x1)           ;{{1a25:2aa7b6}} 
        ld      bc,$0007          ;{{1a28:010700}} ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{1a2b:09}} 
        ld      (x1),hl           ;{{1a2c:22a7b6}} 
        ex      de,hl             ;{{1a2f:eb}} 
        dec     hl                ;{{1a30:2b}} 
        rst     $20               ;{{1a31:e7}}  RST 4 - LOW: RAM LAM
        ld      b,a               ;{{1a32:47}} 
        dec     hl                ;{{1a33:2b}} 
        rst     $20               ;{{1a34:e7}}  RST 4 - LOW: RAM LAM
        ld      c,a               ;{{1a35:4f}} 
        dec     hl                ;{{1a36:2b}} 
        rst     $20               ;{{1a37:e7}}  RST 4 - LOW: RAM LAM
        ld      d,a               ;{{1a38:57}} 
        dec     hl                ;{{1a39:2b}} 
        rst     $20               ;{{1a3a:e7}}  RST 4 - LOW: RAM LAM
        ld      e,a               ;{{1a3b:5f}} 
        push    de                ;{{1a3c:d5}} 
        dec     hl                ;{{1a3d:2b}} 
        rst     $20               ;{{1a3e:e7}}  RST 4 - LOW: RAM LAM
        ld      d,a               ;{{1a3f:57}} 
        dec     hl                ;{{1a40:2b}} 
        rst     $20               ;{{1a41:e7}}  RST 4 - LOW: RAM LAM
        ld      e,a               ;{{1a42:5f}} 
        dec     hl                ;{{1a43:2b}} 
        ld      (RAM_b6a5),hl     ;{{1a44:22a5b6}}  graphics fill buffer
        ex      de,hl             ;{{1a47:eb}} 
        pop     de                ;{{1a48:d1}} 
        jr      _gra_fill_27      ;{{1a49:18c6}}  (-&3a)
_gra_fill_65:                     ;{{Addr=$1a4b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(y21)           ;{{1a4b:3aa9b6}} 
        rrca                      ;{{1a4e:0f}} 
        ret                       ;{{1a4f:c9}} 

;;==================================================================================
;; gra fill sub 2

gra_fill_sub_2:                   ;{{Addr=$1a50 Code Calls/jump count: 1 Data use count: 0}}
        ld      ($b6ac),bc        ;{{1a50:ed43acb6}} 
        call    gra_fill_sub_5    ;{{1a54:cd421b}} 
        jr      c,_gra_fill_sub_2_7;{{1a57:3809}}  (+&09)
        call    gra_fill_sub_3    ;{{1a59:cdf11a}} 
        ret     nc                ;{{1a5c:d0}} 

        ld      ($b6ae),hl        ;{{1a5d:22aeb6}} 
        jr      _gra_fill_sub_2_18;{{1a60:1811}}  (+&11)
_gra_fill_sub_2_7:                ;{{Addr=$1a62 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1a62:e5}} 
        call    _gra_fill_sub_3_23;{{1a63:cd151b}} 
        ld      ($b6ae),hl        ;{{1a66:22aeb6}} 
        pop     bc                ;{{1a69:c1}} 
        ld      a,l               ;{{1a6a:7d}} 
        sub     c                 ;{{1a6b:91}} 
        ld      a,h               ;{{1a6c:7c}} 
        sbc     a,b               ;{{1a6d:98}} 
        call    c,_gra_fill_sub_2_69;{{1a6e:dccb1a}} 
        ld      h,b               ;{{1a71:60}} 
        ld      l,c               ;{{1a72:69}} 
_gra_fill_sub_2_18:               ;{{Addr=$1a73 Code Calls/jump count: 1 Data use count: 0}}
        call    _gra_fill_sub_2_83;{{1a73:cde71a}} 
        ld      (RAM_b6b0),hl     ;{{1a76:22b0b6}} 
        ld      bc,($b6ac)        ;{{1a79:ed4bacb6}} 
        or      a                 ;{{1a7d:b7}} 
        sbc     hl,bc             ;{{1a7e:ed42}} 
        add     hl,bc             ;{{1a80:09}} 
        jr      z,_gra_fill_sub_2_34;{{1a81:2811}}  (+&11)
        jr      nc,_gra_fill_sub_2_29;{{1a83:3008}}  (+&08)
        call    gra_fill_sub_3    ;{{1a85:cdf11a}} 
        call    c,_gra_fill_sub_2_38;{{1a88:dc9d1a}} 
        jr      _gra_fill_sub_2_34;{{1a8b:1807}}  (+&07)
_gra_fill_sub_2_29:               ;{{Addr=$1a8d Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{1a8d:e5}} 
        ld      h,b               ;{{1a8e:60}} 
        ld      l,c               ;{{1a8f:69}} 
        pop     bc                ;{{1a90:c1}} 
        call    _gra_fill_sub_2_69;{{1a91:cdcb1a}} 
_gra_fill_sub_2_34:               ;{{Addr=$1a94 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,($b6ae)        ;{{1a94:2aaeb6}} 
        ld      bc,(RAM_b6b0)     ;{{1a97:ed4bb0b6}} 
        scf                       ;{{1a9b:37}} 
        ret                       ;{{1a9c:c9}} 

_gra_fill_sub_2_38:               ;{{Addr=$1a9d Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{1a9d:d5}} 
        push    hl                ;{{1a9e:e5}} 
        ld      hl,(x1)           ;{{1a9f:2aa7b6}} 
        ld      de,$fff9          ;{{1aa2:11f9ff}} 
        add     hl,de             ;{{1aa5:19}} 
        pop     de                ;{{1aa6:d1}} 
        jr      nc,_gra_fill_sub_2_65;{{1aa7:301c}}  (+&1c)
        ld      (x1),hl           ;{{1aa9:22a7b6}} 
        ld      hl,(RAM_b6a5)     ;{{1aac:2aa5b6}}  graphics fill buffer
        inc     hl                ;{{1aaf:23}} 
        ld      (hl),e            ;{{1ab0:73}} 
        inc     hl                ;{{1ab1:23}} 
        ld      (hl),d            ;{{1ab2:72}} 
        inc     hl                ;{{1ab3:23}} 
        pop     de                ;{{1ab4:d1}} 
        ld      (hl),e            ;{{1ab5:73}} 
        inc     hl                ;{{1ab6:23}} 
        ld      (hl),d            ;{{1ab7:72}} 
        inc     hl                ;{{1ab8:23}} 
        ld      (hl),c            ;{{1ab9:71}} 
        inc     hl                ;{{1aba:23}} 
        ld      (hl),b            ;{{1abb:70}} 
        inc     hl                ;{{1abc:23}} 
        ld      a,(y2x)           ;{{1abd:3aabb6}} 
        ld      (hl),a            ;{{1ac0:77}} 
        ld      (RAM_b6a5),hl     ;{{1ac1:22a5b6}}  graphics fill buffer
        ret                       ;{{1ac4:c9}} 

_gra_fill_sub_2_65:               ;{{Addr=$1ac5 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{1ac5:af}} 
        ld      (y21),a           ;{{1ac6:32a9b6}} 
        pop     de                ;{{1ac9:d1}} 
        ret                       ;{{1aca:c9}} 

_gra_fill_sub_2_69:               ;{{Addr=$1acb Code Calls/jump count: 2 Data use count: 0}}
        call    _gra_fill_sub_2_73;{{1acb:cdd71a}} 
        call    gra_fill_sub_5    ;{{1ace:cd421b}} 
        call    nc,gra_fill_sub_3 ;{{1ad1:d4f11a}} 
        call    c,_gra_fill_sub_2_38;{{1ad4:dc9d1a}} 
_gra_fill_sub_2_73:               ;{{Addr=$1ad7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(y2x)           ;{{1ad7:3aabb6}} 
        cpl                       ;{{1ada:2f}} 
        ld      (y2x),a           ;{{1adb:32abb6}} 
_gra_fill_sub_2_76:               ;{{Addr=$1ade Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{1ade:1b}} 
        ld      a,(y2x)           ;{{1adf:3aabb6}} 
        or      a                 ;{{1ae2:b7}} 
        ret     z                 ;{{1ae3:c8}} 

        inc     de                ;{{1ae4:13}} 
        inc     de                ;{{1ae5:13}} 
        ret                       ;{{1ae6:c9}} 

_gra_fill_sub_2_83:               ;{{Addr=$1ae7 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{1ae7:af}} 
        ld      bc,(graphics_window_y_of_one_side_);{{1ae8:ed4b9fb6}}  graphics window top edge
        call    _gra_fill_sub_3_1 ;{{1aec:cdf31a}} 
        dec     hl                ;{{1aef:2b}} 
        ret                       ;{{1af0:c9}} 

;;==================================================================================
;; gra fill sub 3

gra_fill_sub_3:                   ;{{Addr=$1af1 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$ff             ;{{1af1:3eff}} 
_gra_fill_sub_3_1:                ;{{Addr=$1af3 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{1af3:c5}} 
        push    de                ;{{1af4:d5}} 
        push    hl                ;{{1af5:e5}} 
        push    af                ;{{1af6:f5}} 
        call    gra_fill_sub_6    ;{{1af7:cd4f1b}} 
        pop     af                ;{{1afa:f1}} 
        ld      b,a               ;{{1afb:47}} 
_gra_fill_sub_3_8:                ;{{Addr=$1afc Code Calls/jump count: 1 Data use count: 0}}
        call    gra_fill_sub_4    ;{{1afc:cd341b}} 
        inc     b                 ;{{1aff:04}} 
        djnz    _gra_fill_sub_3_14;{{1b00:1004}}  (+&04)
        jr      nc,_gra_fill_sub_5_5;{{1b02:3047}}  (+&47)
        xor     (hl)              ;{{1b04:ae}} 
        ld      (hl),a            ;{{1b05:77}} 
_gra_fill_sub_3_14:               ;{{Addr=$1b06 Code Calls/jump count: 1 Data use count: 0}}
        jr      c,_gra_fill_sub_5_5;{{1b06:3843}}  (+&43)
        ex      (sp),hl           ;{{1b08:e3}} 
        inc     hl                ;{{1b09:23}} 
        ex      (sp),hl           ;{{1b0a:e3}} 
        sbc     hl,de             ;{{1b0b:ed52}} 
        jr      z,_gra_fill_sub_5_5;{{1b0d:283c}}  (+&3c)
        add     hl,de             ;{{1b0f:19}} 
        call    SCR_PREV_LINE     ;{{1b10:cd390c}}  SCR PREV LINE
        jr      _gra_fill_sub_3_8 ;{{1b13:18e7}}  (-&19)
_gra_fill_sub_3_23:               ;{{Addr=$1b15 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{1b15:c5}} 
        push    de                ;{{1b16:d5}} 
        push    hl                ;{{1b17:e5}} 
        ld      bc,(graphics_window_y_of_other_side_);{{1b18:ed4ba1b6}}  graphics window bottom edge
        call    gra_fill_sub_6    ;{{1b1c:cd4f1b}} 
_gra_fill_sub_3_28:               ;{{Addr=$1b1f Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{1b1f:b7}} 
        sbc     hl,de             ;{{1b20:ed52}} 
        jr      z,_gra_fill_sub_5_5;{{1b22:2827}}  (+&27)
        add     hl,de             ;{{1b24:19}} 
        call    SCR_NEXT_LINE     ;{{1b25:cd1f0c}}  SCR NEXT LINE
        call    gra_fill_sub_4    ;{{1b28:cd341b}} 
        jr      z,_gra_fill_sub_5_5;{{1b2b:281e}}  (+&1e)
        xor     (hl)              ;{{1b2d:ae}} 
        ld      (hl),a            ;{{1b2e:77}} 
        ex      (sp),hl           ;{{1b2f:e3}} 
        dec     hl                ;{{1b30:2b}} 
        ex      (sp),hl           ;{{1b31:e3}} 
        jr      _gra_fill_sub_3_28;{{1b32:18eb}}  (-&15)

;;==================================================================================
;; gra fill sub 4

gra_fill_sub_4:                   ;{{Addr=$1b34 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(GRAPHICS_PEN)  ;{{1b34:3aa3b6}}  graphics pen
        xor     (hl)              ;{{1b37:ae}} 
        and     c                 ;{{1b38:a1}} 
        ret     z                 ;{{1b39:c8}} 

        ld      a,($b6aa)         ;{{1b3a:3aaab6}} 
        xor     (hl)              ;{{1b3d:ae}} 
        and     c                 ;{{1b3e:a1}} 
        ret     z                 ;{{1b3f:c8}} 

        scf                       ;{{1b40:37}} 
        ret                       ;{{1b41:c9}} 

;;==================================================================================
;; gra fill sub 5

gra_fill_sub_5:                   ;{{Addr=$1b42 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{1b42:c5}} 
        push    de                ;{{1b43:d5}} 
        push    hl                ;{{1b44:e5}} 
        call    SCR_DOT_POSITION  ;{{1b45:cdaf0b}} ; SCR DOT POSITION
        call    gra_fill_sub_4    ;{{1b48:cd341b}} 
_gra_fill_sub_5_5:                ;{{Addr=$1b4b Code Calls/jump count: 5 Data use count: 0}}
        pop     hl                ;{{1b4b:e1}} 
        pop     de                ;{{1b4c:d1}} 
        pop     bc                ;{{1b4d:c1}} 
        ret                       ;{{1b4e:c9}} 

;;==================================================================================
;; gra fill sub 6

gra_fill_sub_6:                   ;{{Addr=$1b4f Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{1b4f:c5}} 
        push    de                ;{{1b50:d5}} 
        call    SCR_DOT_POSITION  ;{{1b51:cdaf0b}} ; SCR DOT POSITION
        pop     de                ;{{1b54:d1}} 
        ex      (sp),hl           ;{{1b55:e3}} 
        call    SCR_DOT_POSITION  ;{{1b56:cdaf0b}} ; SCR DOT POSITION
        ex      de,hl             ;{{1b59:eb}} 
        pop     hl                ;{{1b5a:e1}} 
        ret                       ;{{1b5b:c9}} 






;;***Keyboard.asm
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
        ld      hl,used_by_sound_routines_C;{{1fe9:21edb1}}  channels active at SOUND HOLD

;; clear flags
;; b1ed - channels active at SOUND HOLD
;; b1ee - sound channels active
;; b1ef - sound timer?
;; b1f0 - ??
        ld      b,$04             ;{{1fec:0604}} 
_sound_reset_2:                   ;{{Addr=$1fee Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{1fee:3600}} 
        inc     hl                ;{{1ff0:23}} 
        djnz    _sound_reset_2    ;{{1ff1:10fb}} 

;; HL  = event block (b1f1)
        ld      de,sound_processing_function;{{1ff3:118b20}} ; sound event function ##LABEL##
        ld      b,$81             ;{{1ff6:0681}} ; asynchronous event, near address
                                  ;; C = rom select, but unused because it's a near address
        call    KL_INIT_EVENT     ;{{1ff8:cdd201}}  KL INIT EVENT

        ld      a,$3f             ;{{1ffb:3e3f}}  default mixer value (noise/tone off + I/O)
        ld      ($b2b5),a         ;{{1ffd:32b5b2}} 

        ld      hl,FSound_Channel_A_;{{2000:21f8b1}} ; data for channel A
        ld      bc,$003d          ;{{2003:013d00}} ; size of data for each channel ##LIT##;WARNING: Code area used as literal
        ld      de,$0108          ;{{2006:110801}} ; D = mixer value for tone (channel A) ##LIT##;WARNING: Code area used as literal
                                  ;; E = mixer value for noise (channel A)

;; initialise channel data
        xor     a                 ;{{2009:af}} 

_sound_reset_14:                  ;{{Addr=$200a Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{200a:77}} ; channel number
        inc     hl                ;{{200b:23}} 
        ld      (hl),d            ;{{200c:72}} ; mixer tone for channel
        inc     hl                ;{{200d:23}} 
        ld      (hl),e            ;{{200e:73}} ; mixer noise for channel
        add     hl,bc             ;{{200f:09}} ; update channel data pointer

        inc     a                 ;{{2010:3c}} ; increment channel number

        ex      de,hl             ;{{2011:eb}} ; update tone/noise mixer for next channel shifting it left once
        add     hl,hl             ;{{2012:29}} 
        ex      de,hl             ;{{2013:eb}} 

        cp      $03               ;{{2014:fe03}} ; setup all channels?
        jr      nz,_sound_reset_14;{{2016:20f2}} 

        ld      c,$07             ;{{2018:0e07}}  all channels active
_sound_reset_27:                  ;{{Addr=$201a Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{201a:dde5}} 
        push    hl                ;{{201c:e5}} 
        ld      hl,used_by_sound_routines_E;{{201d:21f0b1}} 
        inc     (hl)              ;{{2020:34}} 
        push    hl                ;{{2021:e5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2022:dd21b9b1}} 
        ld      a,c               ;{{2026:79}}  channels active

_sound_reset_34:                  ;{{Addr=$2027 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{2027:cd0922}} ; get next active channel
        push    af                ;{{202a:f5}} 
        push    bc                ;{{202b:c5}} 
        call    _sound_unknown_function_2;{{202c:cd8622}} ; update channels that are active
        call    disable_channel   ;{{202f:cde723}} ; disable channel
        push    ix                ;{{2032:dde5}} 
        pop     de                ;{{2034:d1}} 
        inc     de                ;{{2035:13}} 
        inc     de                ;{{2036:13}} 
        inc     de                ;{{2037:13}} 
        ld      l,e               ;{{2038:6b}} 
        ld      h,d               ;{{2039:62}} 
        inc     de                ;{{203a:13}} 
        ld      bc,$003b          ;{{203b:013b00}} ##LIT##;WARNING: Code area used as literal
        ld      (hl),$00          ;{{203e:3600}} 
        ldir                      ;{{2040:edb0}} 
        ld      (ix+$1c),$04      ;{{2042:dd361c04}} ; number of spaces in queue
        pop     bc                ;{{2046:c1}} 
        pop     af                ;{{2047:f1}} 
        jr      nz,_sound_reset_34;{{2048:20dd}}  (-&23)


        pop     hl                ;{{204a:e1}} 
        dec     (hl)              ;{{204b:35}} 
        pop     hl                ;{{204c:e1}} 
        pop     ix                ;{{204d:dde1}} 
        ret                       ;{{204f:c9}} 

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

        dec     hl                ;{{205a:2b}} 
        ld      (hl),a            ;{{205b:77}} ; channels held

;; set all AY volume registers to zero to silence sound
        ld      l,$03             ;{{205c:2e03}} 
        ld      c,$00             ;{{205e:0e00}}  set zero volume

_sound_hold_11:                   ;{{Addr=$2060 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$07             ;{{2060:3e07}}  AY Mixer register
        add     a,l               ;{{2062:85}}  add on value to get volume register
                                  ; A = AY volume register (10,9,8)
        call    MC_SOUND_REGISTER ;{{2063:cd6308}}  MC SOUND REGISTER
        dec     l                 ;{{2066:2d}} 
        jr      nz,_sound_hold_11 ;{{2067:20f7}} 
 
        scf                       ;{{2069:37}} 
        ret                       ;{{206a:c9}} 


;;==========================================================================
;; SOUND CONTINUE

SOUND_CONTINUE:                   ;{{Addr=$206b Code Calls/jump count: 2 Data use count: 1}}
        ld      de,used_by_sound_routines_C;{{206b:11edb1}} ; channels active at SOUND HELD
        ld      a,(de)            ;{{206e:1a}} 
        or      a                 ;{{206f:b7}} 
        ret     z                 ;{{2070:c8}} 

;; at least one channel was held

        push    de                ;{{2071:d5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2072:dd21b9b1}} 
_sound_continue_6:                ;{{Addr=$2076 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{2076:cd0922}}  get next active channel
        push    af                ;{{2079:f5}} 
        ld      a,(ix+$0f)        ;{{207a:dd7e0f}}  volume for channel
        call    c,set_volume_for_channel;{{207d:dcde23}}  set channel volume
        pop     af                ;{{2080:f1}} 
        jr      nz,_sound_continue_6;{{2081:20f3}} repeat next held channel

        ex      (sp),hl           ;{{2083:e3}} 
        ld      a,(hl)            ;{{2084:7e}} 
        ld      (hl),$00          ;{{2085:3600}} 
        inc     hl                ;{{2087:23}} 
        ld      (hl),a            ;{{2088:77}} 
        pop     hl                ;{{2089:e1}} 
        ret                       ;{{208a:c9}} 

;;===============================================================================
;; sound processing function

sound_processing_function:        ;{{Addr=$208b Code Calls/jump count: 0 Data use count: 1}}
        push    ix                ;{{208b:dde5}} 
        ld      a,(used_by_sound_routines_D);{{208d:3aeeb1}}  sound channels active
        or      a                 ;{{2090:b7}} 
        jr      z,_sound_processing_function_33;{{2091:283d}} 

;; A = channel to process
        push    af                ;{{2093:f5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2094:dd21b9b1}} 
_sound_processing_function_6:     ;{{Addr=$2098 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$003f          ;{{2098:013f00}} ##LIT##;WARNING: Code area used as literal
_sound_processing_function_7:     ;{{Addr=$209b Code Calls/jump count: 1 Data use count: 0}}
        add     ix,bc             ;{{209b:dd09}} 
        srl     a                 ;{{209d:cb3f}} 
        jr      nc,_sound_processing_function_7;{{209f:30fa}} 

        push    af                ;{{20a1:f5}} 
        ld      a,(ix+$04)        ;{{20a2:dd7e04}} 
        rra                       ;{{20a5:1f}} 
        call    c,tone_envelope_function;{{20a6:dc1f24}}  update tone envelope

        ld      a,(ix+$07)        ;{{20a9:dd7e07}} 
        rra                       ;{{20ac:1f}} 
        call    c,update_volume_envelope;{{20ad:dc1f23}}  update volume envelope

        call    c,process_queue_item;{{20b0:dc1322}}  process queue
        pop     af                ;{{20b3:f1}} 
        jr      nz,_sound_processing_function_6;{{20b4:20e2}} ; process next..?

        pop     bc                ;{{20b6:c1}} 
        ld      a,(used_by_sound_routines_D);{{20b7:3aeeb1}}  sound channels active
        cpl                       ;{{20ba:2f}} 
        and     b                 ;{{20bb:a0}} 
        jr      z,_sound_processing_function_33;{{20bc:2812}}  (+&12)

        ld      ix,base_address_for_calculating_relevant_So;{{20be:dd21b9b1}} 
        ld      de,$003f          ;{{20c2:113f00}} ##LIT##;WARNING: Code area used as literal
_sound_processing_function_27:    ;{{Addr=$20c5 Code Calls/jump count: 1 Data use count: 0}}
        add     ix,de             ;{{20c5:dd19}} 
        srl     a                 ;{{20c7:cb3f}} 
        push    af                ;{{20c9:f5}} 
        call    c,disable_channel ;{{20ca:dce723}}  mixer
        pop     af                ;{{20cd:f1}} 
        jr      nz,_sound_processing_function_27;{{20ce:20f5}}  (-&0b)

;; ???
_sound_processing_function_33:    ;{{Addr=$20d0 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{20d0:af}} 
        ld      (used_by_sound_routines_E),a;{{20d1:32f0b1}} 
        pop     ix                ;{{20d4:dde1}} 
        ret                       ;{{20d6:c9}} 

;;====================================================
;; process sound

process_sound:                    ;{{Addr=$20d7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,used_by_sound_routines_D;{{20d7:21eeb1}} ; sound active flag?
        ld      a,(hl)            ;{{20da:7e}} 
        or      a                 ;{{20db:b7}} 
        ret     z                 ;{{20dc:c8}} 
;; sound is active

        inc     hl                ;{{20dd:23}} ; sound timer?
        dec     (hl)              ;{{20de:35}} 
        ret     nz                ;{{20df:c0}} 

        ld      b,a               ;{{20e0:47}} 
        inc     (hl)              ;{{20e1:34}} 
        inc     hl                ;{{20e2:23}} 

        ld      a,(hl)            ;{{20e3:7e}} ; b1f0
        or      a                 ;{{20e4:b7}} 
        ret     nz                ;{{20e5:c0}} 

        dec     hl                ;{{20e6:2b}} 
        ld      (hl),$03          ;{{20e7:3603}} 

        ld      hl,RAM_b1be       ;{{20e9:21beb1}} 
        ld      de,$003f          ;{{20ec:113f00}} ##LIT##;WARNING: Code area used as literal
        xor     a                 ;{{20ef:af}} 
_process_sound_18:                ;{{Addr=$20f0 Code Calls/jump count: 2 Data use count: 0}}
        add     hl,de             ;{{20f0:19}} 
        srl     b                 ;{{20f1:cb38}} 
        jr      nc,_process_sound_18;{{20f3:30fb}}  (-&05)

        dec     (hl)              ;{{20f5:35}} 
        jr      nz,_process_sound_27;{{20f6:2005}}  (+&05)
        dec     hl                ;{{20f8:2b}} 
        rlc     (hl)              ;{{20f9:cb06}} 
        adc     a,d               ;{{20fb:8a}} 
        inc     hl                ;{{20fc:23}} 
_process_sound_27:                ;{{Addr=$20fd Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{20fd:23}} 
        dec     (hl)              ;{{20fe:35}} 
        jr      nz,_process_sound_34;{{20ff:2005}}  (+&05)
        inc     hl                ;{{2101:23}} 
        rlc     (hl)              ;{{2102:cb06}} 
        adc     a,d               ;{{2104:8a}} 
        dec     hl                ;{{2105:2b}} 
_process_sound_34:                ;{{Addr=$2106 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{2106:2b}} 
        inc     b                 ;{{2107:04}} 
        djnz    _process_sound_18 ;{{2108:10e6}}  (-&1a)
        or      a                 ;{{210a:b7}} 
        ret     z                 ;{{210b:c8}} 

        ld      hl,used_by_sound_routines_E;{{210c:21f0b1}} 
        ld      (hl),a            ;{{210f:77}} 
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
        scf                       ;{{211a:37}} 
        ret     z                 ;{{211b:c8}} 

        ld      c,a               ;{{211c:4f}} 
        or      (hl)              ;{{211d:b6}} 
        call    m,_sound_reset_27 ;{{211e:fc1a20}} 
        ld      b,c               ;{{2121:41}} 
        ld      ix,base_address_for_calculating_relevant_So;{{2122:dd21b9b1}} 
;; get channel address
        ld      de,$003f          ;{{2126:113f00}} ##LIT##;WARNING: Code area used as literal
        xor     a                 ;{{2129:af}} 

_sound_queue_12:                  ;{{Addr=$212a Code Calls/jump count: 2 Data use count: 0}}
        add     ix,de             ;{{212a:dd19}} 
        srl     b                 ;{{212c:cb38}} 
        jr      nc,_sound_queue_12;{{212e:30fa}}  (-&06)

        ld      (ix+$1e),d        ;{{2130:dd721e}} ; disarm event
        cp      (ix+$1c)          ;{{2133:ddbe1c}} ; number of spaces in queue
        ccf                       ;{{2136:3f}} 
        sbc     a,a               ;{{2137:9f}} 
        inc     b                 ;{{2138:04}} 
        djnz    _sound_queue_12   ;{{2139:10ef}} 

        or      a                 ;{{213b:b7}} 
        ret     nz                ;{{213c:c0}} 

        ld      b,c               ;{{213d:41}} 
        ld      a,(hl)            ;{{213e:7e}} ; channel status
        rra                       ;{{213f:1f}} 
        rra                       ;{{2140:1f}} 
        rra                       ;{{2141:1f}} 
        or      b                 ;{{2142:b0}} 
        and     $0f               ;{{2143:e60f}} 
        ld      c,a               ;{{2145:4f}} 
        push    hl                ;{{2146:e5}} 
        ld      hl,used_by_sound_routines_E;{{2147:21f0b1}} 
        inc     (hl)              ;{{214a:34}} 
        ex      (sp),hl           ;{{214b:e3}} 
        inc     hl                ;{{214c:23}} 
        ld      ix,base_address_for_calculating_relevant_So;{{214d:dd21b9b1}} 

_sound_queue_37:                  ;{{Addr=$2151 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$003f          ;{{2151:113f00}} ##LIT##;WARNING: Code area used as literal
_sound_queue_38:                  ;{{Addr=$2154 Code Calls/jump count: 1 Data use count: 0}}
        add     ix,de             ;{{2154:dd19}} 
        srl     b                 ;{{2156:cb38}} 
        jr      nc,_sound_queue_38;{{2158:30fa}}  (-&06)

        push    hl                ;{{215a:e5}} 
        push    bc                ;{{215b:c5}} 
        ld      a,(ix+$1b)        ;{{215c:dd7e1b}}  write pointer in queue
        inc     (ix+$1b)          ;{{215f:dd341b}}  increment for next item
        dec     (ix+$1c)          ;{{2162:dd351c}} ; number of spaces in queue
        ex      de,hl             ;{{2165:eb}} 
        call    _sound_queue_84   ;{{2166:cd9c21}} ; get sound queue slot
        push    hl                ;{{2169:e5}} 
        ex      de,hl             ;{{216a:eb}} 
        ld      a,(ix+$01)        ;{{216b:dd7e01}} ; channel's active flag
        cpl                       ;{{216e:2f}} 
        and     c                 ;{{216f:a1}} 
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
        inc     hl                ;{{217a:23}} 
        and     $0f               ;{{217b:e60f}} 
        or      b                 ;{{217d:b0}} 
        ld      (de),a            ;{{217e:12}} 
        inc     de                ;{{217f:13}} 
        ld      bc,$0006          ;{{2180:010600}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2183:edb0}} 
        pop     hl                ;{{2185:e1}} 
        ld      a,(ix+$1a)        ;{{2186:dd7e1a}} ; number of items in the queue
        inc     (ix+$1a)          ;{{2189:dd341a}} 
        or      (ix+$03)          ;{{218c:ddb603}} ; status
        call    z,_process_queue_item_5;{{218f:cc1f22}} 
        pop     bc                ;{{2192:c1}} 
        pop     hl                ;{{2193:e1}} 
        inc     b                 ;{{2194:04}} 
        djnz    _sound_queue_37   ;{{2195:10ba}} 

        ex      (sp),hl           ;{{2197:e3}} 
        dec     (hl)              ;{{2198:35}} 
        pop     hl                ;{{2199:e1}} 
        scf                       ;{{219a:37}} 
        ret                       ;{{219b:c9}} 

;; A = index in queue
_sound_queue_84:                  ;{{Addr=$219c Code Calls/jump count: 2 Data use count: 0}}
        and     $03               ;{{219c:e603}} 
        add     a,a               ;{{219e:87}} 
        add     a,a               ;{{219f:87}} 
        add     a,a               ;{{21a0:87}} 
        add     a,$1f             ;{{21a1:c61f}} 
        push    ix                ;{{21a3:dde5}} 
        pop     hl                ;{{21a5:e1}} 
        add     a,l               ;{{21a6:85}} 
        ld      l,a               ;{{21a7:6f}} 
        adc     a,h               ;{{21a8:8c}} 
        sub     l                 ;{{21a9:95}} 
        ld      h,a               ;{{21aa:67}} 
        ret                       ;{{21ab:c9}} 

;;==========================================================================
;; SOUND RELEASE

SOUND_RELEASE:                    ;{{Addr=$21ac Code Calls/jump count: 0 Data use count: 1}}
        ld      l,a               ;{{21ac:6f}} 
        call    SOUND_CONTINUE    ;{{21ad:cd6b20}}  SOUND CONTINUE
        ld      a,l               ;{{21b0:7d}} 
        and     $07               ;{{21b1:e607}} 
        ret     z                 ;{{21b3:c8}} 

        ld      hl,used_by_sound_routines_E;{{21b4:21f0b1}} 
        inc     (hl)              ;{{21b7:34}} 
        push    hl                ;{{21b8:e5}} 
        ld      ix,base_address_for_calculating_relevant_So;{{21b9:dd21b9b1}} 
_sound_release_9:                 ;{{Addr=$21bd Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_active_channel;{{21bd:cd0922}}  get next active channel
        push    af                ;{{21c0:f5}} 
        bit     3,(ix+$03)        ;{{21c1:ddcb035e}}  held?
        call    nz,_process_queue_item_3;{{21c5:c41922}}  process queue item
        pop     af                ;{{21c8:f1}} 
        jr      nz,_sound_release_9;{{21c9:20f2}}  (-&0e)
        pop     hl                ;{{21cb:e1}} 
        dec     (hl)              ;{{21cc:35}} 
        ret                       ;{{21cd:c9}} 


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
        and     $07               ;{{21ce:e607}} 
        ret     z                 ;{{21d0:c8}} 

        ld      hl,base_address_for_calculating_relevant_so_B;{{21d1:21bcb1}} ; sound data - 63
        ld      de,$003f          ;{{21d4:113f00}} ; 63 ##LIT##;WARNING: Code area used as literal

_sound_check_4:                   ;{{Addr=$21d7 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,de             ;{{21d7:19}} 
        rra                       ;{{21d8:1f}} 
        jr      nc,_sound_check_4 ;{{21d9:30fc}} ; bit a zero?

        di                        ;{{21db:f3}} 
        ld      a,(hl)            ;{{21dc:7e}} 
        add     a,a               ;{{21dd:87}} ; x2
        add     a,a               ;{{21de:87}} ; x4
        add     a,a               ;{{21df:87}} ; x8
        ld      de,$0019          ;{{21e0:111900}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{21e3:19}} 
        or      (hl)              ;{{21e4:b6}} 
        inc     hl                ;{{21e5:23}} 
        inc     hl                ;{{21e6:23}} 
        ld      (hl),$00          ;{{21e7:3600}} 
        ei                        ;{{21e9:fb}} 
        ret                       ;{{21ea:c9}} 

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
        and     $07               ;{{21eb:e607}} 
        ret     z                 ;{{21ed:c8}} 

        ex      de,hl             ;{{21ee:eb}} ; DE = event function

;; get address of data
        ld      hl,base_address_for_calculating_relevant_so_D;{{21ef:21d5b1}} 
        ld      bc,$003f          ;{{21f2:013f00}} ##LIT##;WARNING: Code area used as literal
_sound_arm_event_5:               ;{{Addr=$21f5 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{21f5:09}} 
        rra                       ;{{21f6:1f}} 
        jr      nc,_sound_arm_event_5;{{21f7:30fc}} 

        xor     a                 ;{{21f9:af}} ; 0=no space in queue. !=0  space in the queue
        di                        ;{{21fa:f3}} ; stop event processing changing the value (this is a data fence)
        cp      (hl)              ;{{21fb:be}} ; +&1c -> number of events remaining in queue
        jr      nz,_sound_arm_event_13;{{21fc:2001}} ; if it has space, disarm and call

;; no space in the queue, arm the event
        ld      a,d               ;{{21fe:7a}} 

;; write function
_sound_arm_event_13:              ;{{Addr=$21ff Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{21ff:23}} 
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
        add     ix,de             ;{{220c:dd19}} 
        srl     a                 ;{{220e:cb3f}} 
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
        call    _sound_queue_84   ;{{221c:cd9c21}}  get sound queue slot

;;----------------------------
_process_queue_item_5:            ;{{Addr=$221f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{221f:7e}}  channel status byte
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
        call    process_rendezvous;{{222a:cd9022}}  process rendezvous
        pop     hl                ;{{222d:e1}} 
        jr      nc,_sound_unknown_function_2;{{222e:3056}} 

_process_queue_item_15:           ;{{Addr=$2230 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$03),$10      ;{{2230:dd360310}}  playing

        inc     hl                ;{{2234:23}} 
        ld      a,(hl)            ;{{2235:7e}}  	
        and     $f0               ;{{2236:e6f0}} 
        push    af                ;{{2238:f5}} 
        xor     (hl)              ;{{2239:ae}} 
        ld      e,a               ;{{223a:5f}}  tone envelope number
        inc     hl                ;{{223b:23}} 
        ld      c,(hl)            ;{{223c:4e}}  tone low
        inc     hl                ;{{223d:23}} 
        ld      d,(hl)            ;{{223e:56}}  tone period high
        inc     hl                ;{{223f:23}} 

        or      d                 ;{{2240:b2}}  tone period set?
        or      c                 ;{{2241:b1}} 
        jr      z,_process_queue_item_34;{{2242:2808}} 
;; 
        push    hl                ;{{2244:e5}} 
        call    set_tone_and_get_tone_envelope;{{2245:cd0824}}  set tone and tone envelope	
        ld      d,(ix+$01)        ;{{2248:dd5601}}  tone mixer value
        pop     hl                ;{{224b:e1}} 

_process_queue_item_34:           ;{{Addr=$224c Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{224c:4e}}  noise
        inc     hl                ;{{224d:23}} 
        ld      e,(hl)            ;{{224e:5e}}  start volume
        inc     hl                ;{{224f:23}} 
        ld      a,(hl)            ;{{2250:7e}}  duration of sound or envelope repeat count
        inc     hl                ;{{2251:23}} 
        ld      h,(hl)            ;{{2252:66}} 
        ld      l,a               ;{{2253:6f}} 
        pop     af                ;{{2254:f1}} 
        call    set_initial_values;{{2255:cdde22}} ; set noise

        ld      hl,used_by_sound_routines_D;{{2258:21eeb1}} ; channel active flag
        ld      b,(ix+$01)        ;{{225b:dd4601}} ; channels' active flag
        ld      a,(hl)            ;{{225e:7e}} 
        or      b                 ;{{225f:b0}} 
        ld      (hl),a            ;{{2260:77}} 
        xor     b                 ;{{2261:a8}} 
        jr      nz,_process_queue_item_53;{{2262:2003}}  (+&03)

        inc     hl                ;{{2264:23}} 
        ld      (hl),$03          ;{{2265:3603}} 

_process_queue_item_53:           ;{{Addr=$2267 Code Calls/jump count: 1 Data use count: 0}}
        inc     (ix+$19)          ;{{2267:dd3419}} ; increment read position in queue
        dec     (ix+$1a)          ;{{226a:dd351a}} ; number of items in the queue
;; 
        inc     (ix+$1c)          ;{{226d:dd341c}} ; increase space in the queue

;; there is a space in the queue...
        ld      a,(ix+$1e)        ;{{2270:dd7e1e}} ; high byte of event (0=disarmed)
        ld      (ix+$1e),$00      ;{{2273:dd361e00}} ; disarm event
        or      a                 ;{{2277:b7}} 
        ret     z                 ;{{2278:c8}} 

;; event is armed, kick it off.
        ld      h,a               ;{{2279:67}} 
        ld      l,(ix+$1d)        ;{{227a:dd6e1d}} 
        jp      KL_EVENT          ;{{227d:c3e201}}  KL EVENT

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
        cpl                       ;{{228c:2f}} 
        and     (hl)              ;{{228d:a6}} 
        ld      (hl),a            ;{{228e:77}} 
        ret                       ;{{228f:c9}} 

;;==============================================================
;; process rendezvous
process_rendezvous:               ;{{Addr=$2290 Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{2290:dde5}} 
        ld      b,a               ;{{2292:47}} 
        ld      c,(ix+$01)        ;{{2293:dd4e01}} ; channels' active flag
        ld      ix,FSound_Channel_A_;{{2296:dd21f8b1}} ; channel A's data
        bit     0,a               ;{{229a:cb47}} 
        jr      nz,_process_rendezvous_10;{{229c:200c}} 

        ld      ix,FSound_Channel_B_;{{229e:dd2137b2}} ; channel B's data
        bit     1,a               ;{{22a2:cb4f}} 
        jr      nz,_process_rendezvous_10;{{22a4:2004}} 
        ld      ix,FSound_Channel_C_;{{22a6:dd2176b2}} ; channel C's data

_process_rendezvous_10:           ;{{Addr=$22aa Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$03)        ;{{22aa:dd7e03}}  channels' rendezvous flags
        and     c                 ;{{22ad:a1}}  ignore rendezvous with self.
        jr      z,_process_rendezvous_31;{{22ae:2827}} 
          
        ld      a,b               ;{{22b0:78}} 
        cp      (ix+$01)          ;{{22b1:ddbe01}}  channels' active flag
        jr      z,_process_rendezvous_26;{{22b4:2819}}  ignore rendezvous with self (process own queue)

        push    ix                ;{{22b6:dde5}} 
        ld      ix,FSound_Channel_C_;{{22b8:dd2176b2}}  channel C's data
        bit     2,a               ;{{22bc:cb57}}  rendezvous channel C
        jr      nz,_process_rendezvous_21;{{22be:2004}} 
        ld      ix,FSound_Channel_B_;{{22c0:dd2137b2}}  channel B's data

_process_rendezvous_21:           ;{{Addr=$22c4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(ix+$03)        ;{{22c4:dd7e03}}  channels' rendezvous flags
        and     c                 ;{{22c7:a1}}  ignore rendezvous with self.
        jr      z,_process_rendezvous_30;{{22c8:280c}} 
;; process us/other

        call    _process_queue_item_3;{{22ca:cd1922}}  process queue item
        pop     ix                ;{{22cd:dde1}} 
_process_rendezvous_26:           ;{{Addr=$22cf Code Calls/jump count: 1 Data use count: 0}}
        call    _process_queue_item_3;{{22cf:cd1922}}  process queue item
        pop     ix                ;{{22d2:dde1}} 
        scf                       ;{{22d4:37}} 
        ret                       ;{{22d5:c9}} 

_process_rendezvous_30:           ;{{Addr=$22d6 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{22d6:e1}} 
_process_rendezvous_31:           ;{{Addr=$22d7 Code Calls/jump count: 1 Data use count: 0}}
        pop     ix                ;{{22d7:dde1}} 
        ld      (ix+$03),b        ;{{22d9:dd7003}}  status
        or      a                 ;{{22dc:b7}} 
        ret                       ;{{22dd:c9}} 


;;=================================================================================

;; set initial values
;; C = noise value
;; E = initial volume
;; HL = duration of sound or envelope repeat count
set_initial_values:               ;{{Addr=$22de Code Calls/jump count: 1 Data use count: 0}}
        set     7,e               ;{{22de:cbfb}} 
        ld      (ix+$0f),e        ;{{22e0:dd730f}} ; volume for channel?
        ld      e,a               ;{{22e3:5f}} 

;; duration of sound or envelope repeat count
        ld      a,l               ;{{22e4:7d}} 
        or      h                 ;{{22e5:b4}} 
        jr      nz,_set_initial_values_7;{{22e6:2001}} 

        dec     hl                ;{{22e8:2b}} 
_set_initial_values_7:            ;{{Addr=$22e9 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$08),l        ;{{22e9:dd7508}}  duration of sound or envelope repeat count
        ld      (ix+$09),h        ;{{22ec:dd7409}} 

        ld      a,c               ;{{22ef:79}}  if zero do not set noise
        or      a                 ;{{22f0:b7}} 
        jr      z,_set_initial_values_15;{{22f1:2808}} 

        ld      a,$06             ;{{22f3:3e06}}  PSG noise register
        call    MC_SOUND_REGISTER ;{{22f5:cd6308}}  MC SOUND REGISTER
        ld      a,(ix+$02)        ;{{22f8:dd7e02}} 

_set_initial_values_15:           ;{{Addr=$22fb Code Calls/jump count: 1 Data use count: 0}}
        or      d                 ;{{22fb:b2}} 
        call    update_mixer_for_channel;{{22fc:cde823}}  mixer for channel
        ld      a,e               ;{{22ff:7b}} 
        or      a                 ;{{2300:b7}} 
        jr      z,_set_initial_values_26;{{2301:280a}} 

        ld      hl,base_address_for_calculating_relevant_EN;{{2303:21a6b2}} 
        ld      d,$00             ;{{2306:1600}} 
        add     hl,de             ;{{2308:19}} 
        ld      a,(hl)            ;{{2309:7e}} 
        or      a                 ;{{230a:b7}} 
        jr      nz,_set_initial_values_27;{{230b:2003}} 

_set_initial_values_26:           ;{{Addr=$230d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,default_volume_envelope;{{230d:211b23}}  default volume envelope	
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
        ld      l,(ix+$0d)        ;{{231f:dd6e0d}}  volume envelope pointer
        ld      h,(ix+$0e)        ;{{2322:dd660e}} 
        ld      e,(ix+$10)        ;{{2325:dd5e10}}  step count	

_update_volume_envelope_3:        ;{{Addr=$2328 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{2328:7b}} 
        cp      $ff               ;{{2329:feff}} 
        jr      z,clear_sound_data;{{232b:2875}}  no tone/volume envelopes active


        add     a,a               ;{{232d:87}} 
        ld      a,(hl)            ;{{232e:7e}}  reload envelope shape/step count
        inc     hl                ;{{232f:23}} 
        jr      c,_update_volume_envelope_49;{{2330:3849}}  set hardware envelope (HL) = hardware envelope value
        jr      z,_update_volume_envelope_18;{{2332:280c}}  set volume

        dec     e                 ;{{2334:1d}}  decrease step count

        ld      c,(ix+$0f)        ;{{2335:dd4e0f}} ; 
        or      a                 ;{{2338:b7}} 
        jr      nz,_update_volume_envelope_17;{{2339:2004}} 

        bit     7,c               ;{{233b:cb79}}  has noise
        jr      z,_update_volume_envelope_20;{{233d:2806}}        

;; 
_update_volume_envelope_17:       ;{{Addr=$233f Code Calls/jump count: 1 Data use count: 0}}
        add     a,c               ;{{233f:81}} 


_update_volume_envelope_18:       ;{{Addr=$2340 Code Calls/jump count: 1 Data use count: 0}}
        and     $0f               ;{{2340:e60f}} 
        call    write_volume_     ;{{2342:cddb23}}  write volume for channel and store

_update_volume_envelope_20:       ;{{Addr=$2345 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{2345:4e}} 
        ld      a,(ix+$09)        ;{{2346:dd7e09}} 
        ld      b,a               ;{{2349:47}} 
        add     a,a               ;{{234a:87}} 
        jr      c,_update_volume_envelope_39;{{234b:381b}}  (+&1b)
        xor     a                 ;{{234d:af}} 
        sub     c                 ;{{234e:91}} 
        add     a,(ix+$08)        ;{{234f:dd8608}} 
        jr      c,_update_volume_envelope_35;{{2352:380c}}  (+&0c)
        dec     b                 ;{{2354:05}} 
        jp      p,_update_volume_envelope_34;{{2355:f25d23}} 
        ld      c,(ix+$08)        ;{{2358:dd4e08}} 
        xor     a                 ;{{235b:af}} 
        ld      b,a               ;{{235c:47}} 
_update_volume_envelope_34:       ;{{Addr=$235d Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$09),b        ;{{235d:dd7009}} 
_update_volume_envelope_35:       ;{{Addr=$2360 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$08),a        ;{{2360:dd7708}} 
        or      b                 ;{{2363:b0}} 
        jr      nz,_update_volume_envelope_39;{{2364:2002}}  (+&02)
        ld      e,$ff             ;{{2366:1eff}} 
_update_volume_envelope_39:       ;{{Addr=$2368 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,e               ;{{2368:7b}} 
        or      a                 ;{{2369:b7}} 
        call    z,unknown_sound_function;{{236a:ccae23}} 
        ld      (ix+$10),e        ;{{236d:dd7310}} 
        di                        ;{{2370:f3}} 
        ld      (ix+$06),c        ;{{2371:dd7106}} 
        ld      (ix+$07),$80      ;{{2374:dd360780}}  has tone envelope
        ei                        ;{{2378:fb}} 
        or      a                 ;{{2379:b7}} 
        ret                       ;{{237a:c9}} 

;; E = hardware envelope shape
;; D = hardware envelope period low
;; (HL) = hardware envelope period high

;; DE = hardware envelope period
_update_volume_envelope_49:       ;{{Addr=$237b Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{237b:57}} 
        ld      c,e               ;{{237c:4b}} 
        ld      a,$0d             ;{{237d:3e0d}}  PSG hardware volume shape register
        call    MC_SOUND_REGISTER ;{{237f:cd6308}}  MC SOUND REGISTER
        ld      c,d               ;{{2382:4a}} 
        ld      a,$0b             ;{{2383:3e0b}}  PSG hardware volume period low
        call    MC_SOUND_REGISTER ;{{2385:cd6308}}  MC SOUND REGISTER
        ld      c,(hl)            ;{{2388:4e}} 
        ld      a,$0c             ;{{2389:3e0c}}  PSG hardware volume period high
        call    MC_SOUND_REGISTER ;{{238b:cd6308}}  MC SOUND REGISTER
        ld      a,$10             ;{{238e:3e10}}  use hardware envelope
        call    write_volume_     ;{{2390:cddb23}}  write volume for channel and store

        call    unknown_sound_function;{{2393:cdae23}} 
        ld      a,e               ;{{2396:7b}} 
        inc     a                 ;{{2397:3c}} 
        jr      nz,_update_volume_envelope_3;{{2398:208e}} 

        ld      hl,default_volume_envelope;{{239a:211b23}}  default volume envelope
        call    _unknown_sound_function_13;{{239d:cdcd23}}  set volume envelope
        jr      _update_volume_envelope_3;{{23a0:1886}} 

;;=======================================================================
;; clear sound data?
clear_sound_data:                 ;{{Addr=$23a2 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{23a2:af}} 
        ld      (ix+$03),a        ;{{23a3:dd7703}}  no rendezvous/hold and not playing
        ld      (ix+$07),a        ;{{23a6:dd7707}}  no tone envelope active
        ld      (ix+$04),a        ;{{23a9:dd7704}}  no volume envelope active
        scf                       ;{{23ac:37}} 
        ret                       ;{{23ad:c9}} 

;;=======================================================================
;; unknown sound function
unknown_sound_function:           ;{{Addr=$23ae Code Calls/jump count: 2 Data use count: 0}}
        dec     (ix+$0c)          ;{{23ae:dd350c}} 
        jr      nz,_unknown_sound_function_15;{{23b1:201e}}  (+&1e)

        ld      a,(ix+$09)        ;{{23b3:dd7e09}} 
        add     a,a               ;{{23b6:87}} 
        ld      hl,default_volume_envelope;{{23b7:211b23}}  
        jr      nc,_unknown_sound_function_13;{{23ba:3011}}  set volume envelope

        inc     (ix+$08)          ;{{23bc:dd3408}} 
        jr      nz,_unknown_sound_function_11;{{23bf:2006}}  (+&06)
        inc     (ix+$09)          ;{{23c1:dd3409}} 
        ld      e,$ff             ;{{23c4:1eff}} 
        ret     z                 ;{{23c6:c8}} 

;; reload?
_unknown_sound_function_11:       ;{{Addr=$23c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,(ix+$0a)        ;{{23c7:dd6e0a}} 
        ld      h,(ix+$0b)        ;{{23ca:dd660b}} 

;; set volume envelope
_unknown_sound_function_13:       ;{{Addr=$23cd Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{23cd:7e}} 
        ld      (ix+$0c),a        ;{{23ce:dd770c}} ; step count
_unknown_sound_function_15:       ;{{Addr=$23d1 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{23d1:23}} 
        ld      e,(hl)            ;{{23d2:5e}} ; step size
        inc     hl                ;{{23d3:23}} 
        ld      (ix+$0d),l        ;{{23d4:dd750d}} ; current volume envelope pointer
        ld      (ix+$0e),h        ;{{23d7:dd740e}} 
        ret                       ;{{23da:c9}} 

;;============================================
;; write volume 
;;0 = channel, 15 = value
write_volume_:                    ;{{Addr=$23db Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$0f),a        ;{{23db:dd770f}} 

;;+----------------------------
;; set volume for channel
;; IX = pointer to channel data
;;
;; A = volume
set_volume_for_channel:           ;{{Addr=$23de Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{23de:4f}} 
        ld      a,(ix+$00)        ;{{23df:dd7e00}} 
        add     a,$08             ;{{23e2:c608}}  PSG volume register for channel A
        jp      MC_SOUND_REGISTER ;{{23e4:c36308}}  MC SOUND REGISTER

;;==================================
;; disable channel
disable_channel:                  ;{{Addr=$23e7 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{23e7:af}} 

;;+-------------------------
;; update mixer for channel
update_mixer_for_channel:         ;{{Addr=$23e8 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{23e8:47}} 
        ld      a,(ix+$01)        ;{{23e9:dd7e01}}  tone mixer value
        or      (ix+$02)          ;{{23ec:ddb602}}  noise mixer value

        ld      hl,$b2b5          ;{{23ef:21b5b2}}  mixer value
        di                        ;{{23f2:f3}} 
        or      (hl)              ;{{23f3:b6}}  combine with current
        xor     b                 ;{{23f4:a8}} 
        cp      (hl)              ;{{23f5:be}} 
        ld      (hl),a            ;{{23f6:77}} 
        ei                        ;{{23f7:fb}} 
        jr      nz,_update_mixer_for_channel_14;{{23f8:2003}}  this means tone and noise disabled

        ld      a,b               ;{{23fa:78}} 
        or      a                 ;{{23fb:b7}} 
        ret     nz                ;{{23fc:c0}} 

_update_mixer_for_channel_14:     ;{{Addr=$23fd Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{23fd:af}}  silence sound
        call    set_volume_for_channel;{{23fe:cdde23}}  set channel volume
        di                        ;{{2401:f3}} 
        ld      c,(hl)            ;{{2402:4e}} 
        ld      a,$07             ;{{2403:3e07}}  PSG mixer register
        jp      MC_SOUND_REGISTER ;{{2405:c36308}}  MC SOUND REGISTER

;;==========================================================
;; set tone and get tone envelope
;; E = tone envelope number
set_tone_and_get_tone_envelope:   ;{{Addr=$2408 Code Calls/jump count: 1 Data use count: 0}}
        call    write_tone_to_PSG ;{{2408:cd8124}}  write tone to psg registers
        ld      a,e               ;{{240b:7b}} 
        call    SOUND_T_ADDRESS   ;{{240c:cdab24}}  SOUND T ADDRESS
        ret     nc                ;{{240f:d0}} 

        ld      a,(hl)            ;{{2410:7e}}  number of sections in tone
        and     $7f               ;{{2411:e67f}} 
        ret     z                 ;{{2413:c8}} 

        ld      (ix+$11),l        ;{{2414:dd7511}}  set tone envelope pointer reload
        ld      (ix+$12),h        ;{{2417:dd7412}} 
        call    steps_remaining   ;{{241a:cd7024}} 
        jr      _tone_envelope_function_3;{{241d:1809}}  initial update tone envelope            

;;====================================================================================
;; tone envelope function
tone_envelope_function:           ;{{Addr=$241f Code Calls/jump count: 1 Data use count: 0}}
        ld      l,(ix+$14)        ;{{241f:dd6e14}}  current tone pointer?
        ld      h,(ix+$15)        ;{{2422:dd6615}} 

        ld      e,(ix+$18)        ;{{2425:dd5e18}}  step count

;; update tone envelope
_tone_envelope_function_3:        ;{{Addr=$2428 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{2428:4e}}  step size
        inc     hl                ;{{2429:23}} 
        ld      a,e               ;{{242a:7b}} 
        sub     $f0               ;{{242b:d6f0}} 
        jr      c,_tone_envelope_function_10;{{242d:3804}}  increase/decrease tone

        ld      e,$00             ;{{242f:1e00}} 
        jr      _tone_envelope_function_20;{{2431:180e}} 

;;-------------------------------------

_tone_envelope_function_10:       ;{{Addr=$2433 Code Calls/jump count: 1 Data use count: 0}}
        dec     e                 ;{{2433:1d}}  decrease step count
        ld      a,c               ;{{2434:79}} 
        add     a,a               ;{{2435:87}} 
        sbc     a,a               ;{{2436:9f}} 
        ld      d,a               ;{{2437:57}} 
        ld      a,(ix+$16)        ;{{2438:dd7e16}} ; low byte tone
        add     a,c               ;{{243b:81}} 
        ld      c,a               ;{{243c:4f}} 
        ld      a,(ix+$17)        ;{{243d:dd7e17}} ; high byte tone
        adc     a,d               ;{{2440:8a}} 

_tone_envelope_function_20:       ;{{Addr=$2441 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{2441:57}} 
        call    write_tone_to_PSG ;{{2442:cd8124}}  write tone to psg registers
        ld      c,(hl)            ;{{2445:4e}}  pause time
        ld      a,e               ;{{2446:7b}} 
        or      a                 ;{{2447:b7}} 
        jr      nz,_pause_sound_1 ;{{2448:2019}}  (+&19)

;; step count done..

        ld      a,(ix+$13)        ;{{244a:dd7e13}}  number of tone sections remaining..
        dec     a                 ;{{244d:3d}} 
        jr      nz,pause_sound    ;{{244e:2010}} 

;; reload
        ld      l,(ix+$11)        ;{{2450:dd6e11}} 
        ld      h,(ix+$12)        ;{{2453:dd6612}} 

        ld      a,(hl)            ;{{2456:7e}}  number of sections.
        add     a,$80             ;{{2457:c680}} 
        jr      c,pause_sound     ;{{2459:3805}} 

        ld      (ix+$04),$00      ;{{245b:dd360400}}  no volume envelope
        ret                       ;{{245f:c9}} 

;;====================================================
;; pause sound?
pause_sound:                      ;{{Addr=$2460 Code Calls/jump count: 2 Data use count: 0}}
        call    steps_remaining   ;{{2460:cd7024}} 
_pause_sound_1:                   ;{{Addr=$2463 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$18),e        ;{{2463:dd7318}} 
        di                        ;{{2466:f3}} 
        ld      (ix+$05),c        ;{{2467:dd7105}}  pause
        ld      (ix+$04),$80      ;{{246a:dd360480}}  has volume envelope
        ei                        ;{{246e:fb}} 
        ret                       ;{{246f:c9}} 

;;=====================================================================
;; steps remaining?

steps_remaining:                  ;{{Addr=$2470 Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$13),a        ;{{2470:dd7713}} ; number of sections remaining in envelope
        inc     hl                ;{{2473:23}} 
        ld      e,(hl)            ;{{2474:5e}} ; step count
        inc     hl                ;{{2475:23}} 
        ld      (ix+$14),l        ;{{2476:dd7514}} 
        ld      (ix+$15),h        ;{{2479:dd7415}} 
        ld      a,e               ;{{247c:7b}} 
        or      a                 ;{{247d:b7}} 
        ret     nz                ;{{247e:c0}} 

        inc     e                 ;{{247f:1c}} 
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
        pop     af                ;{{248c:f1}} 
        inc     a                 ;{{248d:3c}} 
                                  ;; A = 1/3/5
        ld      c,d               ;{{248e:4a}} 
        ld      (ix+$17),c        ;{{248f:dd7117}} 
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
        ld      de,ENV_15         ;{{249a:1196b3}} 
_sound_tone_envelope_1:           ;{{Addr=$249d Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{249d:eb}} 
        call    _sound_t_address_1;{{249e:cdae24}} ; get envelope
        ex      de,hl             ;{{24a1:eb}} 
        ret     nc                ;{{24a2:d0}} 

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
        ldir                      ;{{24a3:edb0}} 
        ret                       ;{{24a5:c9}} 

;;==========================================================================
;; SOUND A ADDRESS
;; Gets the address of the data block associated with the amplitude/volume envelope
;; A = envelope number (1-15)

SOUND_A_ADDRESS:                  ;{{Addr=$24a6 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,base_address_for_calculating_relevant_EN;{{24a6:21a6b2}}  first amplitude envelope - &10
        jr      _sound_t_address_1;{{24a9:1803}}  get envelope

;;==========================================================================
;; SOUND T ADDRESS
;; Gets the address of the data block associated with the tone envelope
;; A = envelope number (1-15)
 
SOUND_T_ADDRESS:                  ;{{Addr=$24ab Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,ENV_15         ;{{24ab:2196b3}} ; first tone envelope - &10

;; get envelope
_sound_t_address_1:               ;{{Addr=$24ae Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{24ae:b7}} ; 0 = invalid envelope number
        ret     z                 ;{{24af:c8}} 

        cp      $10               ;{{24b0:fe10}} ; >=16 invalid envelope number
        ret     nc                ;{{24b2:d0}} 

        ld      bc,$0010          ;{{24b3:011000}} ; 16 bytes per envelope (5 sections + count) ##LIT##;WARNING: Code area used as literal
_sound_t_address_6:               ;{{Addr=$24b6 Code Calls/jump count: 1 Data use count: 0}}
        add     hl,bc             ;{{24b6:09}} 
        dec     a                 ;{{24b7:3d}} 
        jr      nz,_sound_t_address_6;{{24b8:20fc}}  (-&04)
        scf                       ;{{24ba:37}} 
        ret                       ;{{24bb:c9}} 



;;***Cassette.asm
;;CASSETTE ROUTINES
;;============================================================================
;; CAS INITIALISE

CAS_INITIALISE:                   ;{{Addr=$24bc Code Calls/jump count: 1 Data use count: 1}}
        call    CAS_IN_ABANDON    ;{{24bc:cd5725}}  CAS IN ABANDON
        call    CAS_OUT_ABANDON   ;{{24bf:cd9925}}  CAS OUT ABANDON

;; enable cassette messages
        xor     a                 ;{{24c2:af}} 
        call    CAS_NOISY         ;{{24c3:cde124}}  CAS NOISY

;; stop cassette motor
        call    CAS_STOP_MOTOR    ;{{24c6:cdbf2b}}  CAS STOP MOTOR

;; set default speed for writing
        ld      hl,$014d          ;{{24c9:214d01}} ##LIT##;WARNING: Code area used as literal
        ld      a,$19             ;{{24cc:3e19}} 

;;============================================================================
;; CAS SET SPEED

CAS_SET_SPEED:                    ;{{Addr=$24ce Code Calls/jump count: 0 Data use count: 1}}
        add     hl,hl             ;{{24ce:29}}  x2
        add     hl,hl             ;{{24cf:29}}  x4
        add     hl,hl             ;{{24d0:29}}  x8
        add     hl,hl             ;{{24d1:29}}  x32
        add     hl,hl             ;{{24d2:29}}  x64
        add     hl,hl             ;{{24d3:29}}  x128
        rrca                      ;{{24d4:0f}} 
        rrca                      ;{{24d5:0f}} 
        and     $3f               ;{{24d6:e63f}} 
        ld      l,a               ;{{24d8:6f}} 
        ld      (cassette_precompensation_),hl;{{24d9:22e9b1}} 
        ld      a,($b1e7)         ;{{24dc:3ae7b1}} 
        scf                       ;{{24df:37}} 
        ret                       ;{{24e0:c9}} 

;;============================================================================
;; CAS NOISY

CAS_NOISY:                        ;{{Addr=$24e1 Code Calls/jump count: 2 Data use count: 1}}
        ld      (cassette_handling_messages_flag_),a;{{24e1:3218b1}} 
        ret                       ;{{24e4:c9}} 

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
        ld      ix,file_IN_flag_  ;{{24e5:dd211ab1}} ; input header

        call    _cas_out_open_1   ;{{24e9:cd0225}} ; initialise header
        push    hl                ;{{24ec:e5}} 
        call    c,read_a_block    ;{{24ed:dcac26}} ; read a block
        pop     hl                ;{{24f0:e1}} 
        ret     nc                ;{{24f1:d0}} 

        ld      de,(address_to_load_this_or_the_next_block_a);{{24f2:ed5b34b1}} ; load address
        ld      bc,(total_length_of_file_);{{24f6:ed4b37b1}} ; execution address
        ld      a,(file_type_)    ;{{24fa:3a31b1}} ; file type from header
        ret                       ;{{24fd:c9}} 

;;============================================================================
;; CAS OUT OPEN

CAS_OUT_OPEN:                     ;{{Addr=$24fe Code Calls/jump count: 0 Data use count: 1}}
        ld      ix,file_OUT_flag_ ;{{24fe:dd215fb1}} 

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
        ex      (sp),hl           ;{{250b:e3}} 
        inc     (hl)              ;{{250c:34}} 
        inc     hl                ;{{250d:23}} 
        ld      (hl),e            ;{{250e:73}} 
        inc     hl                ;{{250f:23}} 
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
        xor     a                 ;{{251b:af}} 
_cas_out_open_22:                 ;{{Addr=$251c Code Calls/jump count: 1 Data use count: 0}}
        ld      (de),a            ;{{251c:12}} 
        inc     de                ;{{251d:13}} 
        dec     c                 ;{{251e:0d}} 
        jr      nz,_cas_out_open_22;{{251f:20fb}}  (-&05)

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
        inc     b                 ;{{252a:04}} 
        ld      c,b               ;{{252b:48}} 
        jr      _cas_out_open_40  ;{{252c:1807}}  (+&07)

;; read character from RAM
_cas_out_open_35:                 ;{{Addr=$252e Code Calls/jump count: 1 Data use count: 0}}
        rst     $20               ;{{252e:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{252f:23}} 
        call    convert_character_to_upper_case;{{2530:cd2629}}  convert character to upper case
        ld      (de),a            ;{{2533:12}}  store character
        inc     de                ;{{2534:13}} 
_cas_out_open_40:                 ;{{Addr=$2535 Code Calls/jump count: 1 Data use count: 0}}
        djnz    _cas_out_open_35  ;{{2535:10f7}} 

;; pad with spaces
_cas_out_open_41:                 ;{{Addr=$2537 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{2537:0d}} 
        jr      z,_cas_out_open_49;{{2538:2809}}  (+&09)
        dec     de                ;{{253a:1b}} 
        ld      a,(de)            ;{{253b:1a}} 
        xor     $20               ;{{253c:ee20}} 
        jr      nz,_cas_out_open_49;{{253e:2003}}  

        ld      (de),a            ;{{2540:12}}  write character
        jr      _cas_out_open_41  ;{{2541:18f4}}  

;;------------------------------------------------------

_cas_out_open_49:                 ;{{Addr=$2543 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{2543:e1}} 
        inc     (ix+$15)          ;{{2544:dd3415}}  set block index
        ld      (ix+$17),$16      ;{{2547:dd361716}}  set initial file type
        dec     (ix+$1c)          ;{{254b:dd351c}}  set first block flag
        scf                       ;{{254e:37}} 
        ret                       ;{{254f:c9}} 

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
        ld      b,$01             ;{{255a:0601}} 
_cas_in_abandon_2:                ;{{Addr=$255c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{255c:7e}} 
        ld      (hl),$00          ;{{255d:3600}}  clear function allowing other functions to proceed
        push    bc                ;{{255f:c5}} 
        call    cleanup_after_abandon;{{2560:cd6d25}} 
        pop     af                ;{{2563:f1}} 

        ld      hl,RAM_b1e4       ;{{2564:21e4b1}} 
        xor     (hl)              ;{{2567:ae}} 
        scf                       ;{{2568:37}} 
        ret     nz                ;{{2569:c0}} 
        ld      (hl),a            ;{{256a:77}} 
        sbc     a,a               ;{{256b:9f}} 
        ret                       ;{{256c:c9}} 

;;============================================================================
;;cleanup after abandon?
;; A = function code
;; HL = ?
cleanup_after_abandon:            ;{{Addr=$256d Code Calls/jump count: 2 Data use count: 0}}
        cp      $04               ;{{256d:fe04}} 
        ret     c                 ;{{256f:d8}} 

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
        jp      HI_KL_LDIR        ;{{257c:c3a1ba}} ; HI: KL LDIR			

;;============================================================================
;; CAS OUT CLOSE

CAS_OUT_CLOSE:                    ;{{Addr=$257f Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(file_OUT_flag_);{{257f:3a5fb1}} 
        cp      $03               ;{{2582:fe03}} 
        jr      z,CAS_OUT_ABANDON ;{{2584:2813}}  (+&13)
        add     a,$ff             ;{{2586:c6ff}} 
        ld      a,$0e             ;{{2588:3e0e}} 
        ret     nc                ;{{258a:d0}} 

        ld      hl,last_block_flag__B;{{258b:2175b1}} 
        dec     (hl)              ;{{258e:35}} 
        inc     hl                ;{{258f:23}} 
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
        ld      b,$02             ;{{259c:0602}} 
        jr      _cas_in_abandon_2 ;{{259e:18bc}}  (-&44)

;;============================================================================
;; CAS IN CHAR

CAS_IN_CHAR:                      ;{{Addr=$25a0 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{25a0:e5}} 
        push    de                ;{{25a1:d5}} 
        push    bc                ;{{25a2:c5}} 
        ld      b,$05             ;{{25a3:0605}} 
        call    attempt_to_set_cassette_input_function;{{25a5:cdf625}} ; set cassette input function
        jr      nz,_cas_in_char_19;{{25a8:201a}}  (+&1a)
        ld      hl,(length_of_this_block);{{25aa:2a32b1}} 
        ld      a,h               ;{{25ad:7c}} 
        or      l                 ;{{25ae:b5}} 
        scf                       ;{{25af:37}} 
        call    z,read_a_block    ;{{25b0:ccac26}} ; read a block
        jr      nc,_cas_in_char_19;{{25b3:300f}}  (+&0f)
        ld      hl,(length_of_this_block);{{25b5:2a32b1}} 
        dec     hl                ;{{25b8:2b}} 
        ld      (length_of_this_block),hl;{{25b9:2232b1}} 
        ld      hl,(address_of_2K_buffer_for_loading_blocks_);{{25bc:2a1db1}} 
        rst     $20               ;{{25bf:e7}}  RST 4 - LOW: RAM LAM
        inc     hl                ;{{25c0:23}} 
        ld      (address_of_2K_buffer_for_loading_blocks_),hl;{{25c1:221db1}} 
_cas_in_char_19:                  ;{{Addr=$25c4 Code Calls/jump count: 2 Data use count: 0}}
        jr      _cas_out_char_22  ;{{25c4:182c}}  (+&2c)

;;============================================================================
;; CAS OUT CHAR

CAS_OUT_CHAR:                     ;{{Addr=$25c6 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{25c6:e5}} 
        push    de                ;{{25c7:d5}} 
        push    bc                ;{{25c8:c5}} 
        ld      c,a               ;{{25c9:4f}} 
        ld      hl,file_OUT_flag_ ;{{25ca:215fb1}} 
        ld      b,$05             ;{{25cd:0605}} 
        call    _attempt_to_set_cassette_input_function_1;{{25cf:cdf925}} 
        jr      nz,_cas_out_char_22;{{25d2:201e}}  (+&1e)
        ld      hl,(length_saved_so_far);{{25d4:2a77b1}} 
        ld      de,$0800          ;{{25d7:110008}} ##LIT##;WARNING: Code area used as literal
        sbc     hl,de             ;{{25da:ed52}} 
        push    bc                ;{{25dc:c5}} 
        call    nc,write_a_block  ;{{25dd:d48627}} ; write a block
        pop     bc                ;{{25e0:c1}} 
        jr      nc,_cas_out_char_22;{{25e1:300f}}  (+&0f)
        ld      hl,(length_saved_so_far);{{25e3:2a77b1}} 
        inc     hl                ;{{25e6:23}} 
        ld      (length_saved_so_far),hl;{{25e7:2277b1}} 
        ld      hl,(address_of_start_of_the_last_block_saved);{{25ea:2a62b1}} 
        ld      (hl),c            ;{{25ed:71}} 
        inc     hl                ;{{25ee:23}} 
        ld      (address_of_start_of_the_last_block_saved),hl;{{25ef:2262b1}} 
_cas_out_char_22:                 ;{{Addr=$25f2 Code Calls/jump count: 3 Data use count: 0}}
        pop     bc                ;{{25f2:c1}} 
        pop     de                ;{{25f3:d1}} 
        pop     hl                ;{{25f4:e1}} 
        ret                       ;{{25f5:c9}} 


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
        ld      hl,file_IN_flag_  ;{{25f6:211ab1}} 

_attempt_to_set_cassette_input_function_1:;{{Addr=$25f9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{25f9:7e}} ; get current function code
        cp      b                 ;{{25fa:b8}} ; same as existing code?
        ret     z                 ;{{25fb:c8}} 
;; function codes are different
        xor     $01               ;{{25fc:ee01}} ; just opened?
        ld      a,$0e             ;{{25fe:3e0e}} 
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
        inc     hl                ;{{260b:23}} 
        ld      (length_of_this_block),hl;{{260c:2232b1}} 
        ld      hl,(address_of_2K_buffer_for_loading_blocks_);{{260f:2a1db1}} 
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
        call    attempt_to_set_cassette_input_function;{{261b:cdf625}} ; set cassette input function
        ret     nz                ;{{261e:c0}} 

;; set initial load address
        ld      (address_to_load_this_or_the_next_block_a),de;{{261f:ed5334b1}} 

;; transfer first block to destination
        call    transfer_loaded_block_to_destination_location;{{2623:cd3c26}} ; transfer loaded block to destination location


;; update load address
_cas_in_direct_6:                 ;{{Addr=$2626 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_to_load_this_or_the_next_block_a);{{2626:2a34b1}} ; load address from in memory header
        ld      de,(length_of_this_block);{{2629:ed5b32b1}} ; length from loaded header
        add     hl,de             ;{{262d:19}} 
        ld      (address_to_load_this_or_the_next_block_a),hl;{{262e:2234b1}} 

        call    read_a_block      ;{{2631:cdac26}} ; read a block
        jr      c,_cas_in_direct_6;{{2634:38f0}}  (-&10)

        ret     z                 ;{{2636:c8}} 
        ld      hl,(RAM_b1be)     ;{{2637:2abeb1}} ; execution address
        scf                       ;{{263a:37}} 
        ret                       ;{{263b:c9}} 

;;============================================================================
;; transfer loaded block to destination location

transfer_loaded_block_to_destination_location:;{{Addr=$263c Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_2K_buffer_for_directories);{{263c:2a1bb1}} 
        ld      bc,(length_of_this_block);{{263f:ed4b32b1}} 
        ld      a,e               ;{{2643:7b}} 
        sub     l                 ;{{2644:95}} 
        ld      a,d               ;{{2645:7a}} 
        sbc     a,h               ;{{2646:9c}} 
        jp      c,HI_KL_LDIR      ;{{2647:daa1ba}} ; HI: KL LDIR
        add     hl,bc             ;{{264a:09}} 
        dec     hl                ;{{264b:2b}} 
        ex      de,hl             ;{{264c:eb}} 
        add     hl,bc             ;{{264d:09}} 
        dec     hl                ;{{264e:2b}} 
        ex      de,hl             ;{{264f:eb}} 
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
        call    _attempt_to_set_cassette_input_function_1;{{265b:cdf925}} 
        jr      nz,_cas_out_direct_28;{{265e:202d}}  (+&2d)

        ld      a,c               ;{{2660:79}} 
        pop     bc                ;{{2661:c1}} 
        pop     hl                ;{{2662:e1}} 

;; setup header
        ld      (file_type__B),a  ;{{2663:3276b1}} 
        ld      (total_length_of_file_to_be_saved),de;{{2666:ed537cb1}}  length
        ld      (execution_address_for_bin_files__B),bc;{{266a:ed437eb1}}  execution address

_cas_out_direct_13:               ;{{Addr=$266e Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_to_start_the_next_block_save_fro),hl;{{266e:2260b1}}  load address
        ld      (length_saved_so_far),de;{{2671:ed5377b1}}  length
        ld      hl,$f7ff          ;{{2675:21fff7}}  &f7ff = -&800
        add     hl,de             ;{{2678:19}} 
        ccf                       ;{{2679:3f}} 
        ret     c                 ;{{267a:d8}} 

        ld      hl,$0800          ;{{267b:210008}} ##LIT##;WARNING: Code area used as literal
        ld      (length_saved_so_far),hl;{{267e:2277b1}}  length of this block

        ex      de,hl             ;{{2681:eb}} 
        sbc     hl,de             ;{{2682:ed52}} 
        push    hl                ;{{2684:e5}} 
        ld      hl,(address_to_start_the_next_block_save_fro);{{2685:2a60b1}} 
        add     hl,de             ;{{2688:19}} 
        push    hl                ;{{2689:e5}} 
        call    write_a_block     ;{{268a:cd8627}}  write block
	
_cas_out_direct_28:               ;{{Addr=$268d Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{268d:e1}} 
        pop     de                ;{{268e:d1}} 
        ret     nc                ;{{268f:d0}} 

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

        ld      (hl),$04          ;{{269a:3604}}  set catalog function

        ld      (address_of_2K_buffer_for_directories),de;{{269c:ed531bb1}}  buffer to load blocks to
        xor     a                 ;{{26a0:af}} 
        call    CAS_NOISY         ;{{26a1:cde124}} ; CAS NOISY
_cas_catalog_9:                   ;{{Addr=$26a4 Code Calls/jump count: 1 Data use count: 0}}
        call    _read_a_block_4   ;{{26a4:cdb326}}  read block
        jr      c,_cas_catalog_9  ;{{26a7:38fb}}  loop if cassette not pressed

        jp      CAS_IN_ABANDON    ;{{26a9:c35725}} ; CAS IN ABANDON


;;=================================================================================
;; read a block
;; 
;; 
;; notes:
;;

read_a_block:                     ;{{Addr=$26ac Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(last_block_flag_);{{26ac:3a30b1}}  last block flag
        or      a                 ;{{26af:b7}} 
        ld      a,$0f             ;{{26b0:3e0f}}  "hard end of file"
        ret     nz                ;{{26b2:c0}} 

_read_a_block_4:                  ;{{Addr=$26b3 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$8301          ;{{26b3:010183}}  Press PLAY then any key
        call    wait_key_start_motor;{{26b6:cde527}}  display message if required
        jr      nc,handle_read_error;{{26b9:305f}} 

_read_a_block_7:                  ;{{Addr=$26bb Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,used_to_construct_IN_Channel_header;{{26bb:21a4b1}}  location to load header
        ld      de,$0040          ;{{26be:114000}}  header length ##LIT##;WARNING: Code area used as literal
        ld      a,$2c             ;{{26c1:3e2c}}  header marker byte
        call    CAS_READ          ;{{26c3:cda629}}  cas read: read header
        jr      nc,handle_read_error;{{26c6:3052}} 

        ld      b,$8b             ;{{26c8:068b}}  no message
        call    test_if_read_function_is_CATALOG;{{26ca:cd2f29}}  catalog?
        jr      z,_read_a_block_18;{{26cd:2807}} 

;; not catalog, so compare filenames
        call    compare_filenames ;{{26cf:cd3727}}  compare filenames
        jr      nz,block_found    ;{{26d2:2053}}  if nz, display "Found xxx block x"

        ld      b,$89             ;{{26d4:0689}}  "Loading"
_read_a_block_18:                 ;{{Addr=$26d6 Code Calls/jump count: 1 Data use count: 0}}
        call    _test_and_delay_6 ;{{26d6:cd0428}}  display "Loading xxx block x"

        ld      de,(RAM_b1b7)     ;{{26d9:ed5bb7b1}}  length from loaded header
        ld      hl,(address_to_load_this_or_the_next_block_a);{{26dd:2a34b1}}  location from in-memory header

        ld      a,(file_IN_flag_) ;{{26e0:3a1ab1}}  
        cp      $02               ;{{26e3:fe02}}  in direct?
        jr      z,_read_a_block_30;{{26e5:280e}}  

;; not in direct, so is:
;; 1. catalog
;; 2. opening file for read
;; 3. reading file char by char
;;
;; check the block is no longer than &800 bytes
;; if it is report a "read error d"
        ld      hl,$f7ff          ;{{26e7:21fff7}}  &f7ff = -&800
        add     hl,de             ;{{26ea:19}}  add length from header

        ld      a,$04             ;{{26eb:3e04}}  code for 'read error d'
        jr      c,handle_read_error;{{26ed:382b}}  (+&2b)

        ld      hl,(address_of_2K_buffer_for_directories);{{26ef:2a1bb1}}  2k buffer
        ld      (address_of_2K_buffer_for_loading_blocks_),hl;{{26f2:221db1}} 

_read_a_block_30:                 ;{{Addr=$26f5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$16             ;{{26f5:3e16}}  data marker
        call    CAS_READ          ;{{26f7:cda629}}  cas read: read data

        jr      nc,handle_read_error;{{26fa:301e}} 

;; increment block number in internal header
        ld      hl,number_of_block_being_loaded_or_next_to;{{26fc:212fb1}}  block number
        inc     (hl)              ;{{26ff:34}}  increment block number

;; get last block flag from loaded header and store into
;; internal header
        ld      a,(RAM_b1b5)      ;{{2700:3ab5b1}} 
        inc     hl                ;{{2703:23}} 
        ld      (hl),a            ;{{2704:77}} 

;; clear first block flag
        xor     a                 ;{{2705:af}} 
        ld      (first_block_flag_),a;{{2706:3236b1}} 

        ld      hl,(RAM_b1b7)     ;{{2709:2ab7b1}}  get length from loaded header
        ld      (length_of_this_block),hl;{{270c:2232b1}}  store in internal header

        call    test_if_read_function_is_CATALOG;{{270f:cd2f29}}  catalog?

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
        or      a                 ;{{271a:b7}} 
        ld      hl,file_IN_flag_  ;{{271b:211ab1}} 
        jr      z,abandon         ;{{271e:2858}}  

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
        call    _test_and_delay_6 ;{{272a:cd0428}}  "Found xxx block x"
        pop     af                ;{{272d:f1}} 
        jr      nc,_read_a_block_7;{{272e:308b}}  (-&75)

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
        or      a                 ;{{273a:b7}} 
        jr      z,compare_name_and_block_number;{{273b:281b}} 

        ld      a,($b1bb)         ;{{273d:3abbb1}}  first block flag in loaded header?
        cpl                       ;{{2740:2f}} 
        or      a                 ;{{2741:b7}} 
        ret     nz                ;{{2742:c0}} 

;; if user specified a filename, compare it against the filename in the loaded
;; header, otherwise accept the file

        ld      a,(IN_Channel_header);{{2743:3a1fb1}}  did user specify a filename?
                                  ; e.g. LOAD"bob
        or      a                 ;{{2746:b7}} 

        call    nz,compare_two_filenames;{{2747:c46027}}  compare filenames and block number
        ret     nz                ;{{274a:c0}}  if filenames do not match, quit

;; gets here if:

;; 1. if a filename was specified by user and filename matches with 
;; filename in loaded header
;;
;; 2. no filename was specified by user

;; copy loaded header to in-memory header
        ld      hl,used_to_construct_IN_Channel_header;{{274b:21a4b1}} 
        ld      de,IN_Channel_header;{{274e:111fb1}} 
        ld      bc,$0040          ;{{2751:014000}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2754:edb0}} 

        xor     a                 ;{{2756:af}} 
        ret                       ;{{2757:c9}} 

;;=========================================================================
;; compare name and block number

compare_name_and_block_number:    ;{{Addr=$2758 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_two_filenames;{{2758:cd6027}}  compare filenames
        ret     nz                ;{{275b:c0}} 

;; compare block number
        ex      de,hl             ;{{275c:eb}} 
        ld      a,(de)            ;{{275d:1a}} 
        cp      (hl)              ;{{275e:be}} 
        ret                       ;{{275f:c9}} 

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
        ld      c,a               ;{{276c:4f}} 
        ld      a,(hl)            ;{{276d:7e}}  get character from in-memory header
        call    convert_character_to_upper_case;{{276e:cd2629}}  convert character to upper case

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
        call    cleanup_after_abandon;{{277b:cd6d25}} 
        or      a                 ;{{277e:b7}} 

;;----------------------------------------------------------------------------
;; quit loading block
_abandon_4:                       ;{{Addr=$277f Code Calls/jump count: 2 Data use count: 0}}
        sbc     a,a               ;{{277f:9f}} 
        push    af                ;{{2780:f5}} 
        call    CAS_STOP_MOTOR    ;{{2781:cdbf2b}}  CAS STOP MOTOR
        pop     af                ;{{2784:f1}} 
        ret                       ;{{2785:c9}} 

;;============================================================================
;; write a block

write_a_block:                    ;{{Addr=$2786 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,$8402          ;{{2786:010284}}  press rec
        call    wait_key_start_motor;{{2789:cde527}}   display message if required
        jr      nc,handle_write_error;{{278c:304a}}  (+&4a)
        ld      b,$8a             ;{{278e:068a}} 
        ld      de,OUT_Channel_Header_;{{2790:1164b1}} 
        call    _test_and_delay_7 ;{{2793:cd0728}} 
        ld      hl,first_block_flag__B;{{2796:217bb1}} 
        call    test_and_delay    ;{{2799:cdfa27}} 
        jr      nc,handle_write_error;{{279c:303a}}  (+&3a)
_write_a_block_9:                 ;{{Addr=$279e Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_to_start_the_next_block_save_fro);{{279e:2a60b1}} 
        ld      (address_of_start_of_the_last_block_saved),hl;{{27a1:2262b1}} 
        ld      (address_of_start_of_area_to_save_or_add),hl;{{27a4:2279b1}} 
        push    hl                ;{{27a7:e5}} 

;; write header for this block
        ld      hl,OUT_Channel_Header_;{{27a8:2164b1}} 
        ld      de,$0040          ;{{27ab:114000}} ##LIT##;WARNING: Code area used as literal
        ld      a,$2c             ;{{27ae:3e2c}}  header marker
        call    CAS_WRITE         ;{{27b0:cdaf29}}  cas write: write header

        pop     hl                ;{{27b3:e1}} 
        jr      nc,handle_write_error;{{27b4:3022}}  (+&22)

;; write data for this block
        ld      de,(length_saved_so_far);{{27b6:ed5b77b1}} 
        ld      a,$16             ;{{27ba:3e16}}  data marker
        call    CAS_WRITE         ;{{27bc:cdaf29}}  cas write: write data block
        ld      hl,last_block_flag__B;{{27bf:2175b1}} 
        call    c,test_and_delay  ;{{27c2:dcfa27}} 
        jr      nc,handle_write_error;{{27c5:3011}}  (+&11)
        ld      hl,$0000          ;{{27c7:210000}} ##LIT##;WARNING: Code area used as literal
        ld      (length_saved_so_far),hl;{{27ca:2277b1}} 
        ld      hl,number_of_the_block_being_saved_or_next;{{27cd:2174b1}} 
        inc     (hl)              ;{{27d0:34}} 
        xor     a                 ;{{27d1:af}} 
        ld      (first_block_flag__B),a;{{27d2:327bb1}} 
        scf                       ;{{27d5:37}} 
        jr      _abandon_4        ;{{27d6:18a7}}  (-&59)

;;=======================================================================
;;handle write error?
;; A = code (A=0: no error; A<>0: error)
handle_write_error:               ;{{Addr=$27d8 Code Calls/jump count: 4 Data use count: 0}}
        or      a                 ;{{27d8:b7}} 
        ld      hl,file_OUT_flag_ ;{{27d9:215fb1}} 
        jr      z,abandon         ;{{27dc:289a}}  (-&66)

;; a = code
        ld      b,$86             ;{{27de:0686}}  "Write error"
        call    display_message_with_code_on_end;{{27e0:cd8528}}  display message with code
        jr      _write_a_block_9  ;{{27e3:18b9}}  (-&47)

;;========================================================================
;; wait key start motor
;; C = message code
;; exit:
;; A = 0: no error
;; A <>0: error

wait_key_start_motor:             ;{{Addr=$27e5 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_b1e4       ;{{27e5:21e4b1}} 
        ld      a,c               ;{{27e8:79}} 
        cp      (hl)              ;{{27e9:be}} 
        ld      (hl),c            ;{{27ea:71}} 
        scf                       ;{{27eb:37}} 

        push    hl                ;{{27ec:e5}} 
        push    bc                ;{{27ed:c5}} 
        call    nz,prepare_display_for_message;{{27ee:c4d228}}  Press play then any key
        pop     bc                ;{{27f1:c1}} 
        pop     hl                ;{{27f2:e1}} 

        sbc     a,a               ;{{27f3:9f}} 
        ret     nc                ;{{27f4:d0}} 

        call    CAS_START_MOTOR   ;{{27f5:cdbb2b}}  CAS START MOTOR
        sbc     a,a               ;{{27f8:9f}} 
        ret                       ;{{27f9:c9}} 

;;========================================================================
;; test and delay?
test_and_delay:                   ;{{Addr=$27fa Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{27fa:7e}} 
        or      a                 ;{{27fb:b7}} 
        scf                       ;{{27fc:37}} 
        ret     z                 ;{{27fd:c8}} 

        ld      bc,$012c          ;{{27fe:012c01}}  delay in 1/100ths of a second ##LIT##;WARNING: Code area used as literal
        jp      delay__check_for_escape;{{2801:c3e22b}}  delay for 3 seconds

;;-===================================================================================

_test_and_delay_6:                ;{{Addr=$2804 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,used_to_construct_IN_Channel_header;{{2804:11a4b1}} 

_test_and_delay_7:                ;{{Addr=$2807 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(cassette_handling_messages_flag_);{{2807:3a18b1}}  cassette messages enabled?
        or      a                 ;{{280a:b7}} 
        ret     nz                ;{{280b:c0}} 

        ld      (RAM_b119),a      ;{{280c:3219b1}} 
        call    set_column_1      ;{{280f:cdf328}} 

        call    x2898_code        ;{{2812:cd9828}}  display message

        ld      a,(de)            ;{{2815:1a}}  is first character of filename = 0?
        or      a                 ;{{2816:b7}} 
        jr      nz,_test_and_delay_20;{{2817:200a}}  

;; unnamed file

        ld      a,$8e             ;{{2819:3e8e}}  "Unnamed file"
        call    display_message   ;{{281b:cd9928}}  display message

        ld      bc,$0010          ;{{281e:011000}} ##LIT##;WARNING: Code area used as literal
        jr      _test_and_delay_48;{{2821:182e}}  (+&2e)

;;-----------------------------
;; named file
_test_and_delay_20:               ;{{Addr=$2823 Code Calls/jump count: 1 Data use count: 0}}
        call    test_if_read_function_is_CATALOG;{{2823:cd2f29}} 

        ld      bc,$1000          ;{{2826:010010}} ##LIT##;WARNING: Code area used as literal
        jr      z,_test_and_delay_34;{{2829:280d}}  (+&0d)
        ld      l,e               ;{{282b:6b}} 
        ld      h,d               ;{{282c:62}} 
_test_and_delay_25:               ;{{Addr=$282d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{282d:7e}} 
        or      a                 ;{{282e:b7}} 
        jr      z,_test_and_delay_31;{{282f:2804}}  (+&04)
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
        ld      a,(de)            ;{{283b:1a}}  get character from filename
        call    convert_character_to_upper_case;{{283c:cd2629}}  convert character to upper case

        or      a                 ;{{283f:b7}}  zero?
        jr      nz,_test_and_delay_40;{{2840:2002}} 

;; display a space if a zero is found

        ld      a,$20             ;{{2842:3e20}}  display a space

_test_and_delay_40:               ;{{Addr=$2844 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{2844:c5}} 
        push    de                ;{{2845:d5}} 
        call    TXT_WR_CHAR       ;{{2846:cd3513}}  TXT WR CHAR
        pop     de                ;{{2849:d1}} 
        pop     bc                ;{{284a:c1}} 
        inc     de                ;{{284b:13}} 
        djnz    _test_and_delay_35;{{284c:10ed}}  (-&13)

        call    _display_message_with_word_wrap_15;{{284e:cdce28}}  display space

_test_and_delay_48:               ;{{Addr=$2851 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2851:eb}} 
        add     hl,bc             ;{{2852:09}} 
        ex      de,hl             ;{{2853:eb}} 

        ld      a,$8d             ;{{2854:3e8d}}  "block "
        call    display_message   ;{{2856:cd9928}}  display message

        ld      b,$02             ;{{2859:0602}}  length of word
        call    determine_if_word_can_be_displayed_on_this_line;{{285b:cdfd28}}  insert new-line if word
                                  ; can't fit onto current-line

        ld      a,(de)            ;{{285e:1a}} 
        call    divide_by_10      ;{{285f:cd1429}}  display decimal number

        call    _display_message_with_word_wrap_15;{{2862:cdce28}}  display space

        inc     de                ;{{2865:13}} 
        call    test_if_read_function_is_CATALOG;{{2866:cd2f29}} 
        jr      nz,x2876_code     ;{{2869:200b}}  (+&0b)
        inc     de                ;{{286b:13}} 
        ld      a,(de)            ;{{286c:1a}} 
        and     $0f               ;{{286d:e60f}} 
        add     a,$24             ;{{286f:c624}} 
        call    _prepare_display_for_message_14;{{2871:cdf028}} 

        jr      _display_message_with_word_wrap_15;{{2874:1858}}  display space

;;=========================================================================

x2876_code:                       ;{{Addr=$2876 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{2876:1a}} 
        ld      hl,RAM_b119       ;{{2877:2119b1}} 
        or      (hl)              ;{{287a:b6}} 
        ret     z                 ;{{287b:c8}} 
        jr      _prepare_display_for_message_12;{{287c:186d}}  (+&6d)

;;=========================================================================
;; A = message code

A__message_code:                  ;{{Addr=$287e Code Calls/jump count: 1 Data use count: 0}}
        call    display_message   ;{{287e:cd9928}}  display message
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
        add     a,$60             ;{{288a:c660}}  'a'-1
        call    nc,_prepare_display_for_message_14;{{288c:d4f028}}  display character
        jr      _prepare_display_for_message_12;{{288f:185a}} 

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

        and     $7f               ;{{289a:e67f}}  get message index (0-127)
        ld      b,a               ;{{289c:47}} 

        ld      hl,cassette_messages;{{289d:213529}}  start of message list (points to first message)

;; first message in list? (message 0?)
        jr      z,_display_message_10;{{28a0:2807}} 

;; not first. 
;; 
;; - each message is terminated by a zero byte
;; - keep fetching bytes until a zero is found.
;; - if a zero is found, decrement count. If count reaches zero, then 
;; the first byte following the zero, is the start of the message we want

_display_message_5:               ;{{Addr=$28a2 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{28a2:7e}}  get byte
        inc     hl                ;{{28a3:23}}  increment pointer

        or      a                 ;{{28a4:b7}}  is it zero (0) ?
        jr      nz,_display_message_5;{{28a5:20fb}}  if zero, it is the end of this string

;; got a zero byte, so at end of the current string

        djnz    _display_message_5;{{28a7:10f9}}  decrement message count

;; HL = start of message to display

;; this part is looped; message may contain multiple strings

;; end of message?
_display_message_10:              ;{{Addr=$28a9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{28a9:7e}} 
        or      a                 ;{{28aa:b7}} 
        jr      z,_display_message_15;{{28ab:2805}}  (+&05)

;; display message
        call    display_message_with_word_wrap;{{28ad:cdb528}}  display message with word-wrap

;; at this point there might be a end of string marker (0), the start
;; of another string (next byte will have bit 7=0) or a continuation string
;; (next byte will have bit 7=1)
        jr      _display_message_10;{{28b0:18f7}}  continue displaying string 

;; finished displaying complete string , or displayed part of string sequence
_display_message_15:              ;{{Addr=$28b2 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{28b2:e1}} 

        inc     hl                ;{{28b3:23}}  if part of a complete message, go to next sub-string or word
        ret                       ;{{28b4:c9}} 

;;=========================================================================
;; display message with word wrap

;; HL = address of message
;; A = first character in message

;; if -ve, then bit 7 is set. Bit 6..0 define the ID of the message to display
;; if +ve, then this is the first character in the message
display_message_with_word_wrap:   ;{{Addr=$28b5 Code Calls/jump count: 1 Data use count: 0}}
        jp      m,display_message ;{{28b5:fa9928}} 


;;-------------------------------------
;; count number of letters in word

        push    hl                ;{{28b8:e5}} ; store start of word

;; count number of letters in world
        ld      b,$00             ;{{28b9:0600}} 
_display_message_with_word_wrap_3:;{{Addr=$28bb Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{28bb:04}} 

        ld      a,(hl)            ;{{28bc:7e}} ; get character
        inc     hl                ;{{28bd:23}} ; increment pointer
        rlca                      ;{{28be:07}} ; if bit 7 is set, then this is the last character of the current word
        jr      nc,_display_message_with_word_wrap_3;{{28bf:30fa}} 

;; B = number of letters

;; if word will not fit onto end of current line, insert
;; a line break, and display on next line
        call    determine_if_word_can_be_displayed_on_this_line;{{28c1:cdfd28}} 

        pop     hl                ;{{28c4:e1}} ; restore start of word 

;;------------------------------------
;; display word

;; HL = location of characters
;; B = number of characters 
_display_message_with_word_wrap_10:;{{Addr=$28c5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{28c5:7e}}  get byte
        inc     hl                ;{{28c6:23}}  increment counter
        and     $7f               ;{{28c7:e67f}}  isolate byte
        call    _prepare_display_for_message_14;{{28c9:cdf028}}  display char (txt output?)
        djnz    _display_message_with_word_wrap_10;{{28cc:10f7}} 

;; display space
_display_message_with_word_wrap_15:;{{Addr=$28ce Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$20             ;{{28ce:3e20}}  " " (space) character
        jr      _prepare_display_for_message_14;{{28d0:181e}}  display character

;;=========================================================================
;; prepare display for message
prepare_display_for_message:      ;{{Addr=$28d2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(cassette_handling_messages_flag_);{{28d2:3a18b1}}  cassette messages enabled?
        or      a                 ;{{28d5:b7}} 
        scf                       ;{{28d6:37}} 
        ret     nz                ;{{28d7:c0}} 

        call    x2891_code        ;{{28d8:cd9128}}  display message

        call    KM_FLUSH          ;{{28db:cdfe1b}}  KM FLUSH
        call    TXT_CUR_ON        ;{{28de:cd7612}}  TXT CUR ON
        call    KM_WAIT_KEY       ;{{28e1:cddb1c}}  KM WAIT KEY
        call    TXT_CUR_OFF       ;{{28e4:cd7e12}}  TXT CUR OFF
        cp      $fc               ;{{28e7:fefc}} 
        ret     z                 ;{{28e9:c8}} 

        scf                       ;{{28ea:37}} 

;;-----------------------------------------------------------------------

_prepare_display_for_message_12:  ;{{Addr=$28eb Code Calls/jump count: 5 Data use count: 0}}
        call    set_column_1      ;{{28eb:cdf328}} 

;; display cr
        ld      a,$0a             ;{{28ee:3e0a}} 
_prepare_display_for_message_14:  ;{{Addr=$28f0 Code Calls/jump count: 5 Data use count: 0}}
        jp      TXT_OUTPUT        ;{{28f0:c3fe13}}  TXT OUTPUT

;;==========================================================================
;; set column 1
set_column_1:                     ;{{Addr=$28f3 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{28f3:f5}} 
        push    hl                ;{{28f4:e5}} 
        ld      a,$01             ;{{28f5:3e01}} 
        call    TXT_SET_COLUMN    ;{{28f7:cd5a11}}  TXT SET COLUMN
        pop     hl                ;{{28fa:e1}} 
        pop     af                ;{{28fb:f1}} 
        ret                       ;{{28fc:c9}} 

;;==========================================================================
;; determine if word can be displayed on this line
determine_if_word_can_be_displayed_on_this_line:;{{Addr=$28fd Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{28fd:d5}} 
        call    TXT_GET_WINDOW    ;{{28fe:cd5212}}  TXT GET WINDOW
        ld      e,h               ;{{2901:5c}} 
        call    TXT_GET_CURSOR    ;{{2902:cd7c11}}  TXT GET CURSOR
        ld      a,h               ;{{2905:7c}} 
        dec     a                 ;{{2906:3d}} 
        add     a,e               ;{{2907:83}} 
        add     a,b               ;{{2908:80}} 
        dec     a                 ;{{2909:3d}} 
        cp      d                 ;{{290a:ba}} 
        pop     de                ;{{290b:d1}} 
        ret     c                 ;{{290c:d8}} 

        ld      a,$ff             ;{{290d:3eff}} 
        ld      (RAM_b119),a      ;{{290f:3219b1}} 
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

        add     a,$3a             ;{{291b:c63a}}  convert to ASCII digit
			
        push    af                ;{{291d:f5}} 
        ld      a,b               ;{{291e:78}} 
        or      a                 ;{{291f:b7}} 
        call    nz,divide_by_10   ;{{2920:c41429}}  continue with division

        pop     af                ;{{2923:f1}} 
        jr      _prepare_display_for_message_14;{{2924:18ca}}  display character

;;============================================================================
;; convert character to upper case
convert_character_to_upper_case:  ;{{Addr=$2926 Code Calls/jump count: 4 Data use count: 0}}
        cp      $61               ;{{2926:fe61}}  "a"
        ret     c                 ;{{2928:d8}} 

        cp      $7b               ;{{2929:fe7b}}  "z"
        ret     nc                ;{{292b:d0}} 

        add     a,$e0             ;{{292c:c6e0}} 
        ret                       ;{{292e:c9}} 

;;============================================================================
;; test if read function is CATALOG
;;
;; zero set = catalog
;; zero clear = not catalog
test_if_read_function_is_CATALOG: ;{{Addr=$292f Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(file_IN_flag_) ;{{292f:3a1ab1}}  get current read function
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
        call    enable_key_checking_and_start_the_cassette_motor;{{29a6:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29a9:f5}} 
        ld      hl,Read_block_of_data;{{29aa:21282a}}  read block of data ##LABEL##
        jr      _cas_check_3      ;{{29ad:1819}}  do read

;;=========================================================================
;; CAS WRITE

;; A = sync byte
;; HL = destination location for data
;; DE = length of data

CAS_WRITE:                        ;{{Addr=$29af Code Calls/jump count: 2 Data use count: 1}}
        call    enable_key_checking_and_start_the_cassette_motor;{{29af:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29b2:f5}} 
        call    write_start_of_block;{{29b3:cdd42a}} ; write start of block (pilot and syncs)
        ld      hl,write_block_of_data_;{{29b6:21672a}} ; write block of data ##LABEL##
        call    c,readwrite_blocks;{{29b9:dc0d2a}} ; read/write 256 byte blocks
        call    c,write_trailer__33_1_bits;{{29bc:dce92a}} ; write trailer
        jr      _cas_check_7      ;{{29bf:180f}} ; 

;;=========================================================================
;; CAS CHECK

CAS_CHECK:                        ;{{Addr=$29c1 Code Calls/jump count: 0 Data use count: 1}}
        call    enable_key_checking_and_start_the_cassette_motor;{{29c1:cde329}}  enable key checking and start the cassette motor
        push    af                ;{{29c4:f5}} 
        ld      hl,check_stored_block_with_block_in_memory;{{29c5:21372a}} ; check stored block with block in memory ##LABEL##

;;------------------------------------------------------
;; do read
;; cas check or cas read
_cas_check_3:                     ;{{Addr=$29c8 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{29c8:e5}} 
        call    read_pilot_and_sync;{{29c9:cd892a}} ; read pilot and sync
        pop     hl                ;{{29cc:e1}} 
        call    c,readwrite_blocks;{{29cd:dc0d2a}} ; read/write 256 byte blocks


;;----------------------------------------------------------------
;; cas check, cas read or cas write
_cas_check_7:                     ;{{Addr=$29d0 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{29d0:d1}} 
        push    af                ;{{29d1:f5}} 

        ld      bc,$f782          ;{{29d2:0182f7}} ; set PPI port A to output
        out     (c),c             ;{{29d5:ed49}} 

        ld      bc,$f610          ;{{29d7:0110f6}} ; cassette motor on
        out     (c),c             ;{{29da:ed49}} 

;; if cassette motor is stopped, then it will stop immediatly
;; if cassette motor is running, then there will not be any pause.

        ei                        ;{{29dc:fb}} ; enable interrupts

        ld      a,d               ;{{29dd:7a}} 
        call    CAS_RESTORE_MOTOR ;{{29de:cdc12b}} ; CAS RESTORE MOTOR
        pop     af                ;{{29e1:f1}} 
        ret                       ;{{29e2:c9}} 

;;=========================================================================
;; enable key checking and start the cassette motor

;; store marker
enable_key_checking_and_start_the_cassette_motor:;{{Addr=$29e3 Code Calls/jump count: 3 Data use count: 0}}
        ld      (synchronisation_byte),a;{{29e3:32e5b1}} 

        dec     de                ;{{29e6:1b}} 
        inc     e                 ;{{29e7:1c}} 

        push    hl                ;{{29e8:e5}} 
        push    de                ;{{29e9:d5}} 
        call    SOUND_RESET       ;{{29ea:cde91f}}  SOUND RESET
        pop     de                ;{{29ed:d1}} 
        pop     ix                ;{{29ee:dde1}} 

        call    CAS_START_MOTOR   ;{{29f0:cdbb2b}}  CAS START MOTOR


        di                        ;{{29f3:f3}} ; disable interrupts

;; select PSG register 14 (PSG port A)
;; (keyboard data is connected to PSG port A)
        ld      bc,$f40e          ;{{29f4:010ef4}} ; select keyboard line 14
        out     (c),c             ;{{29f7:ed49}} 

        ld      bc,$f6d0          ;{{29f9:01d0f6}} ; cassette motor on + PSG select register operation
        out     (c),c             ;{{29fc:ed49}} 

        ld      c,$10             ;{{29fe:0e10}} 
        out     (c),c             ;{{2a00:ed49}} ; cassette motor on + PSG inactive operation

        ld      bc,$f792          ;{{2a02:0192f7}} ; set PPI port A to input
        out     (c),c             ;{{2a05:ed49}} 
                                  ;; PSG port A data can be read through PPI port A now

        ld      bc,$f658          ;{{2a07:0158f6}} ; cassette motor on + PSG read data operation + select keyboard line 8
        out     (c),c             ;{{2a0a:ed49}} 
        ret                       ;{{2a0c:c9}} 

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
        ld      a,d               ;{{2a0d:7a}} 
        or      a                 ;{{2a0e:b7}} 
        jr      z,_readwrite_blocks_12;{{2a0f:280d}}  (+&0d)

;; do each complete 256 byte block
_readwrite_blocks_3:              ;{{Addr=$2a11 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{2a11:e5}} 
        push    de                ;{{2a12:d5}} 
        ld      e,$00             ;{{2a13:1e00}}  number of bytes
        call    _readwrite_blocks_12;{{2a15:cd1e2a}}  read/write block
        pop     de                ;{{2a18:d1}} 
        pop     hl                ;{{2a19:e1}} 
        ret     nc                ;{{2a1a:d0}} 

        dec     d                 ;{{2a1b:15}} 
        jr      nz,_readwrite_blocks_3;{{2a1c:20f3}}  (-&0d)

;; E = number of bytes in last block to write

;;------------------------------------
;; initialise crc
_readwrite_blocks_12:             ;{{Addr=$2a1e Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$ffff          ;{{2a1e:01ffff}} 
        ld      (RAM_b1eb),bc     ;{{2a21:ed43ebb1}}  crc 

;; do function
        ld      d,$01             ;{{2a25:1601}} 
        jp      (hl)              ;{{2a27:e9}} 

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
        call    read_databyte     ;{{2a28:cd202b}}  read byte from cassette
        ret     nc                ;{{2a2b:d0}} 

        ld      (ix+$00),a        ;{{2a2c:dd7700}}  store byte
        inc     ix                ;{{2a2f:dd23}}  increment pointer

        dec     d                 ;{{2a31:15}}  decrement block count

        dec     e                 ;{{2a32:1d}} 
        jr      nz,Read_block_of_data;{{2a33:20f3}}  decrement actual data count

;; D = number of bytes remaining in block

;; read remaining bytes in block; but ignore
        jr      _check_stored_block_with_block_in_memory_11;{{2a35:1812}}  (+&12)

;;========================================================================================
;; check stored block with block in memory
check_stored_block_with_block_in_memory:;{{Addr=$2a37 Code Calls/jump count: 1 Data use count: 1}}
        call    read_databyte     ;{{2a37:cd202b}}  read byte from cassette
        ret     nc                ;{{2a3a:d0}} 

        ld      b,a               ;{{2a3b:47}} 
        call    read_byte_from_address_pointed_to_IX_with_roms_disabled;{{2a3c:cdd7ba}}  get byte from IX with roms disabled
        xor     b                 ;{{2a3f:a8}} 


        ld      a,$03             ;{{2a40:3e03}}  
        ret     nz                ;{{2a42:c0}} 

        inc     ix                ;{{2a43:dd23}} 
        dec     d                 ;{{2a45:15}} 
        dec     e                 ;{{2a46:1d}} 
        jr      nz,check_stored_block_with_block_in_memory;{{2a47:20ee}}  (-&12)

;; any more bytes remaining in block??
_check_stored_block_with_block_in_memory_11:;{{Addr=$2a49 Code Calls/jump count: 2 Data use count: 0}}
        dec     d                 ;{{2a49:15}} 
        jr      z,_check_stored_block_with_block_in_memory_16;{{2a4a:2806}}  

;; bytes remaining
;; read the remaining bytes but ignore

        call    read_databyte     ;{{2a4c:cd202b}}  read byte from cassette	
        ret     nc                ;{{2a4f:d0}} 

        jr      _check_stored_block_with_block_in_memory_11;{{2a50:18f7}}  

;;-----------------------------------------------------

_check_stored_block_with_block_in_memory_16:;{{Addr=$2a52 Code Calls/jump count: 1 Data use count: 0}}
        call    get_stored_data_crc_and_1s_complement_it;{{2a52:cd162b}}  get 1's complemented crc

        call    read_databyte     ;{{2a55:cd202b}}  read crc byte1 from cassette
        ret     nc                ;{{2a58:d0}} 

        xor     d                 ;{{2a59:aa}} 
        jr      nz,_check_stored_block_with_block_in_memory_26;{{2a5a:2007}} 

        call    read_databyte     ;{{2a5c:cd202b}}  read crc byte2 from cassette
        ret     nc                ;{{2a5f:d0}} 

        xor     e                 ;{{2a60:ab}} 
        scf                       ;{{2a61:37}} 
        ret     z                 ;{{2a62:c8}} 

_check_stored_block_with_block_in_memory_26:;{{Addr=$2a63 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$02             ;{{2a63:3e02}} 
        or      a                 ;{{2a65:b7}} 
        ret                       ;{{2a66:c9}} 

;;========================================================================================
;; write block of data 
;; (pad with 0's if less than block size)
;; IX = address of data
;; E = actual byte count
;; D = block size count
 
write_block_of_data_:             ;{{Addr=$2a67 Code Calls/jump count: 1 Data use count: 1}}
        call    read_byte_from_address_pointed_to_IX_with_roms_disabled;{{2a67:cdd7ba}}  get byte from IX with roms disabled
        call    write_data_byte_to_cassette;{{2a6a:cd682b}}  write data byte
        ret     nc                ;{{2a6d:d0}} 

        inc     ix                ;{{2a6e:dd23}}  increment pointer

        dec     d                 ;{{2a70:15}}  decrement block size count
        dec     e                 ;{{2a71:1d}}  decrement actual count
        jr      nz,write_block_of_data_;{{2a72:20f3}}  (-&0d)

;; actual byte count = block size count?
_write_block_of_data__7:          ;{{Addr=$2a74 Code Calls/jump count: 1 Data use count: 0}}
        dec     d                 ;{{2a74:15}} 
        jr      z,_write_block_of_data__13;{{2a75:2807}} 

;; no, actual byte count was less than block size
;; pad up to block size with zeros

        xor     a                 ;{{2a77:af}} 
        call    write_data_byte_to_cassette;{{2a78:cd682b}}  write data byte
        ret     nc                ;{{2a7b:d0}} 

        jr      _write_block_of_data__7;{{2a7c:18f6}}  (-&0a)


;; get 1's complemented crc
_write_block_of_data__13:         ;{{Addr=$2a7e Code Calls/jump count: 1 Data use count: 0}}
        call    get_stored_data_crc_and_1s_complement_it;{{2a7e:cd162b}} 

;; write crc 1
        call    write_data_byte_to_cassette;{{2a81:cd682b}}  write data byte
        ret     nc                ;{{2a84:d0}} 

;; write crc 2
        ld      a,e               ;{{2a85:7b}} 
        jp      write_data_byte_to_cassette;{{2a86:c3682b}}  write data byte

;;========================================================================================
;; read pilot and sync

read_pilot_and_sync:              ;{{Addr=$2a89 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{2a89:d5}} 
        call    read_pilot_and_sync_B;{{2a8a:cd932a}}  read pilot and sync
        pop     de                ;{{2a8d:d1}} 

        ret     c                 ;{{2a8e:d8}} 

        or      a                 ;{{2a8f:b7}} 
        ret     z                 ;{{2a90:c8}} 

        jr      read_pilot_and_sync;{{2a91:18f6}}  (-&0a)

;;==========================================================================
;; read pilot and sync

;;---------------------------------
;; wait for start of leader/pilot

read_pilot_and_sync_B:            ;{{Addr=$2a93 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,$55             ;{{2a93:2e55}}  %01010101
                                  ; this is used to generate the cassette input data comparison 
                                  ; used in the edge detection

        call    sample_edge_and_check_for_escape;{{2a95:cd3d2b}}  sample edge
        ret     nc                ;{{2a98:d0}} 

;;------------------------------------------
;; get 256 pulses of leader/pilot
        ld      de,$0000          ;{{2a99:110000}}  initial total ##LIT##;WARNING: Code area used as literal

        ld      h,d               ;{{2a9c:62}} 

_read_pilot_and_sync_b_5:         ;{{Addr=$2a9d Code Calls/jump count: 1 Data use count: 0}}
        call    sample_edge_and_check_for_escape;{{2a9d:cd3d2b}}  sample edge
        ret     nc                ;{{2aa0:d0}} 

        ex      de,hl             ;{{2aa1:eb}} 
;; C = measured time
;; add measured time to total
        ld      b,$00             ;{{2aa2:0600}} 
        add     hl,bc             ;{{2aa4:09}} 
        ex      de,hl             ;{{2aa5:eb}} 

        dec     h                 ;{{2aa6:25}} 
        jr      nz,_read_pilot_and_sync_b_5;{{2aa7:20f4}}  (-&0c)


;; C = duration of last pulse read

;; look for sync bit
;; and adjust the average for every non-sync

;; DE = sum of 256 edges
;; D:E forms a 8.8 fixed point number
;; D = integer part of number (integer average of 256 pulses)
;; E = fractional part of number

_read_pilot_and_sync_b_13:        ;{{Addr=$2aa9 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,c               ;{{2aa9:61}}  time of last pulse

        ld      a,c               ;{{2aaa:79}} 
        sub     d                 ;{{2aab:92}}  subtract initial average 
        ld      c,a               ;{{2aac:4f}} 
        sbc     a,a               ;{{2aad:9f}} 
        ld      b,a               ;{{2aae:47}} 

;; if C>D then BC is +ve; BC = +ve delta
;; if C<D then BC is -ve; BC = -ve delta

;; adjust average
        ex      de,hl             ;{{2aaf:eb}} 
        add     hl,bc             ;{{2ab0:09}}  DE = DE + BC
        ex      de,hl             ;{{2ab1:eb}} 

        call    sample_edge_and_check_for_escape;{{2ab2:cd3d2b}}  sample edge
        ret     nc                ;{{2ab5:d0}} 

; A = D * 5/4
        ld      a,d               ;{{2ab6:7a}}  average so far			
        srl     a                 ;{{2ab7:cb3f}}  /2
        srl     a                 ;{{2ab9:cb3f}}  /4
                                  ; A = D * 1/4
        adc     a,d               ;{{2abb:8a}}  A = D + (D*1/4)

;; sync pulse will have a duration which is half that of a pulse in a 1 bit
;; average<previous 


        sub     h                 ;{{2abc:94}}  time of last pulse
        jr      c,_read_pilot_and_sync_b_13;{{2abd:38ea}}  carry set if H>A

;; average>=previous (possibly read first pulse of sync or second of sync)

        sub     c                 ;{{2abf:91}}  time of current pulse
        jr      c,_read_pilot_and_sync_b_13;{{2ac0:38e7}}  carry set if C>(A-H)

;; to get here average>=(previous*2)
;; and this means we have just read the second pulse of the sync bit


;; calculate bit 1 timing
        ld      a,d               ;{{2ac2:7a}}  average
        rra                       ;{{2ac3:1f}}  /2
                                  ; A = D/2
        adc     a,d               ;{{2ac4:8a}}  A = D + (D/2)
                                  ; A = D * (3/2)
        ld      h,a               ;{{2ac5:67}} 
                                  ; this is the middle time
                                  ; to calculate difference between 0 and 1 bit

;; if pulse measured is > this time, then we have a 1 bit
;; if pulse measured is < this time, then we have a 0 bit

;; H = timing constant
;; L = initial cassette data input state
        ld      (RAM_b1e6),hl     ;{{2ac6:22e6b1}} 

;; read marker
        call    read_databyte     ;{{2ac9:cd202b}}  read data-byte
        ret     nc                ;{{2acc:d0}} 

        ld      hl,synchronisation_byte;{{2acd:21e5b1}}  marker
        xor     (hl)              ;{{2ad0:ae}} 
        ret     nz                ;{{2ad1:c0}} 

        scf                       ;{{2ad2:37}} 
        ret                       ;{{2ad3:c9}} 

;;========================================================================================
;; write start of block
write_start_of_block:             ;{{Addr=$2ad4 Code Calls/jump count: 1 Data use count: 0}}
        call    tenth_of_a_second_delay;{{2ad4:cdf92b}} ; 1/100th of a second delay

;; write leader
        ld      hl,$0801          ;{{2ad7:210108}} ; 2049 ##LIT##;WARNING: Code area used as literal
        call    _write_trailer__33_1_bits_1;{{2ada:cdec2a}} ; write leader (2049 1 bits; 4096 pulses)
        ret     nc                ;{{2add:d0}} 

;; write sync bit
        or      a                 ;{{2ade:b7}} 
        call    write_bit_to_cassette;{{2adf:cd782b}} ; write data-bit
        ret     nc                ;{{2ae2:d0}} 

;; write marker
        ld      a,(synchronisation_byte);{{2ae3:3ae5b1}} 
        jp      write_data_byte_to_cassette;{{2ae6:c3682b}} ; write data byte

;;=============================================================================
;; write trailer = 33 "1" bits
;;
;; carry set = trailer written successfully
;; zero set = escape was pressed

write_trailer__33_1_bits:         ;{{Addr=$2ae9 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,$0021          ;{{2ae9:212100}} ; 33 ##LIT##;WARNING: Code area used as literal

;; check for escape
_write_trailer__33_1_bits_1:      ;{{Addr=$2aec Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$f4             ;{{2aec:06f4}} ; PPI port A
        in      a,(c)             ;{{2aee:ed78}} ; read keyboard data through PPI port A (connected to PSG port A)
        and     $04               ;{{2af0:e604}} ; escape key pressed?
                                  ;; bit 2 is 0 if escape key pressed
        ret     z                 ;{{2af2:c8}} 

;; write trailer bit
        push    hl                ;{{2af3:e5}} 
        scf                       ;{{2af4:37}} ; a "1" bit   
        call    write_bit_to_cassette;{{2af5:cd782b}} ; write data-bit
        pop     hl                ;{{2af8:e1}} 
        dec     hl                ;{{2af9:2b}} ; decrement trailer bit count

        ld      a,h               ;{{2afa:7c}} 
        or      l                 ;{{2afb:b5}} 
        jr      nz,_write_trailer__33_1_bits_1;{{2afc:20ee}} ;

        scf                       ;{{2afe:37}} 
        ret                       ;{{2aff:c9}} 
;;=============================================================================

;; update crc
update_crc:                       ;{{Addr=$2b00 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(RAM_b1eb)     ;{{2b00:2aebb1}} ; get crc
        xor     h                 ;{{2b03:ac}} 
        jp      p,_update_crc_10  ;{{2b04:f2102b}} 

        ld      a,h               ;{{2b07:7c}} 
        xor     $08               ;{{2b08:ee08}} 
        ld      h,a               ;{{2b0a:67}} 
        ld      a,l               ;{{2b0b:7d}} 
        xor     $10               ;{{2b0c:ee10}} 
        ld      l,a               ;{{2b0e:6f}} 
        scf                       ;{{2b0f:37}} 

_update_crc_10:                   ;{{Addr=$2b10 Code Calls/jump count: 1 Data use count: 0}}
        adc     hl,hl             ;{{2b10:ed6a}} 
        ld      (RAM_b1eb),hl     ;{{2b12:22ebb1}} ; store crc
        ret                       ;{{2b15:c9}} 

;;========================================================================================
;; get stored data crc and 1's complement it
;; initialise ready to write to cassette or to compare against crc from cassette

get_stored_data_crc_and_1s_complement_it:;{{Addr=$2b16 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(RAM_b1eb)     ;{{2b16:2aebb1}} ; block crc

;; 1's complement crc
        ld      a,l               ;{{2b19:7d}} 
        cpl                       ;{{2b1a:2f}} 
        ld      e,a               ;{{2b1b:5f}} 
        ld      a,h               ;{{2b1c:7c}} 
        cpl                       ;{{2b1d:2f}} 
        ld      d,a               ;{{2b1e:57}} 
        ret                       ;{{2b1f:c9}} 

;;========================================================================================
;; read data-byte

read_databyte:                    ;{{Addr=$2b20 Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{2b20:d5}} 
        ld      e,$08             ;{{2b21:1e08}} ; number of data-bits

_read_databyte_2:                 ;{{Addr=$2b23 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_b1e6)     ;{{2b23:2ae6b1}} 
;; H = timing constant
;; L = initial cassette data input state

        call    _sample_edge_and_check_for_escape_4;{{2b26:cd442b}} ; get edge

        call    c,_sample_edge_and_check_for_escape_10;{{2b29:dc4d2b}} ; get edge
        jr      nc,_read_databyte_15;{{2b2c:300d}} 

        ld      a,h               ;{{2b2e:7c}} ; ideal time
        sub     c                 ;{{2b2f:91}} ; subtract measured time
                                  ;; -ve (1 pulse) or +ve (0 pulse)
        sbc     a,a               ;{{2b30:9f}} 
                                  ;; if -ve, set carry
                                  ;; if +ve, clear carry

;; carry flag = bit state: carry set = 1 bit, carry clear = 0 bit

        rl      d                 ;{{2b31:cb12}} ; shift carry state into bit 0
                                  ;; updating data-byte
										
        call    update_crc        ;{{2b33:cd002b}} ; update crc
        dec     e                 ;{{2b36:1d}} 
        jr      nz,_read_databyte_2;{{2b37:20ea}}  

        ld      a,d               ;{{2b39:7a}} 
        scf                       ;{{2b3a:37}} 
_read_databyte_15:                ;{{Addr=$2b3b Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{2b3b:d1}} 
        ret                       ;{{2b3c:c9}} 

;;========================================================================================
;; sample edge and check for escape
;; L = bit-sequence which is shifted after each edge detected
;; starts of as &55 (%01010101)

;; check for escape
sample_edge_and_check_for_escape: ;{{Addr=$2b3d Code Calls/jump count: 3 Data use count: 0}}
        ld      b,$f4             ;{{2b3d:06f4}} ; PPI port A
        in      a,(c)             ;{{2b3f:ed78}} ; read keyboard data through PPI port A (connected to PSG port A)
        and     $04               ;{{2b41:e604}} ; escape key pressed?
                                  ;; bit 2 is 0 if escape key pressed
        ret     z                 ;{{2b43:c8}} 


;; precompensation?
_sample_edge_and_check_for_escape_4:;{{Addr=$2b44 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,r               ;{{2b44:ed5f}} 

;; round up to divisible by 4
;; i.e.
;; 0->0, 
;; 1->4, 
;; 2->4, 
;; 3->4, 
;; 4->8, 
;; 5->8
;; etc

        add     a,$03             ;{{2b46:c603}} 
        rrca                      ;{{2b48:0f}} ; /2
        rrca                      ;{{2b49:0f}} ; /4

        and     $1f               ;{{2b4a:e61f}} ; 

        ld      c,a               ;{{2b4c:4f}} 

_sample_edge_and_check_for_escape_10:;{{Addr=$2b4d Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f5             ;{{2b4d:06f5}}  PPI port B input (includes cassette data input)

;; -----------------------------------------------------
;; loop to count time between edges
;; C = time in 17us units (68T states)
;; carry set = edge arrived within time
;; carry clear = edge arrived too late

_sample_edge_and_check_for_escape_11:;{{Addr=$2b4f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{2b4f:79}}  [1] update edge timer
        add     a,$02             ;{{2b50:c602}}  [2]
        ld      c,a               ;{{2b52:4f}}  [1]
        jr      c,_sample_edge_and_check_for_escape_24;{{2b53:380e}}  [3] overflow?

        in      a,(c)             ;{{2b55:ed78}}  [4] read cassette input data
        xor     l                 ;{{2b57:ad}}  [1]
        and     $80               ;{{2b58:e680}}  [2] isolate cassette input in bit 7
        jr      nz,_sample_edge_and_check_for_escape_11;{{2b5a:20f3}}  [3] has bit 7 (cassette data input) changed state?

;; pulse successfully read

        xor     a                 ;{{2b5c:af}} 
        ld      r,a               ;{{2b5d:ed4f}} 

        rrc     l                 ;{{2b5f:cb0d}}  toggles between 0 and 1 

        scf                       ;{{2b61:37}} 
        ret                       ;{{2b62:c9}} 

;; time-out
_sample_edge_and_check_for_escape_24:;{{Addr=$2b63 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{2b63:af}} 
        ld      r,a               ;{{2b64:ed4f}} 
        inc     a                 ;{{2b66:3c}}  "read error a"
        ret                       ;{{2b67:c9}} 

;;========================================================================================
;; write data byte to cassette
;; A = data byte
write_data_byte_to_cassette:      ;{{Addr=$2b68 Code Calls/jump count: 5 Data use count: 0}}
        push    de                ;{{2b68:d5}} 
        ld      e,$08             ;{{2b69:1e08}} ; number of bits
        ld      d,a               ;{{2b6b:57}} 

_write_data_byte_to_cassette_3:   ;{{Addr=$2b6c Code Calls/jump count: 1 Data use count: 0}}
        rlc     d                 ;{{2b6c:cb02}} ; shift bit state into carry
        call    write_bit_to_cassette;{{2b6e:cd782b}} ; write bit to cassette
        jr      nc,_write_data_byte_to_cassette_8;{{2b71:3003}} 

        dec     e                 ;{{2b73:1d}} 
        jr      nz,_write_data_byte_to_cassette_3;{{2b74:20f6}} ; loop for next bit

_write_data_byte_to_cassette_8:   ;{{Addr=$2b76 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{2b76:d1}} 
        ret                       ;{{2b77:c9}} 

;;========================================================================================
;; write bit to cassette
;;
;; carry flag = state of bit
;; carry set = 1 data bit
;; carry clear = 0 data bit

write_bit_to_cassette:            ;{{Addr=$2b78 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,(RAM_b1e8)     ;{{2b78:ed4be8b1}} 
        ld      hl,(cassette_Half_a_Zero_duration_);{{2b7c:2aeab1}} 
        sbc     a,a               ;{{2b7f:9f}} 
        ld      h,a               ;{{2b80:67}} 
        jr      z,_write_bit_to_cassette_12;{{2b81:2807}}  (+&07)
        ld      a,l               ;{{2b83:7d}} 
        add     a,a               ;{{2b84:87}} 
        add     a,b               ;{{2b85:80}} 
        ld      l,a               ;{{2b86:6f}} 
        ld      a,c               ;{{2b87:79}} 
        sub     b                 ;{{2b88:90}} 
        ld      c,a               ;{{2b89:4f}} 
_write_bit_to_cassette_12:        ;{{Addr=$2b8a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{2b8a:7d}} 
        ld      (RAM_b1e8),a      ;{{2b8b:32e8b1}} 

;; write a low level
        ld      l,$0a             ;{{2b8e:2e0a}}  %00001010 = clear bit 5 (cassette write data)
        call    write_level_to_cassette;{{2b90:cda72b}} 

        jr      c,_write_bit_to_cassette_22;{{2b93:3806}}  (+&06)
        sub     c                 ;{{2b95:91}} 
        jr      nc,_write_bit_to_cassette_26;{{2b96:300c}}  (+&0c)
        cpl                       ;{{2b98:2f}} 
        inc     a                 ;{{2b99:3c}} 
        ld      c,a               ;{{2b9a:4f}} 
_write_bit_to_cassette_22:        ;{{Addr=$2b9b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{2b9b:7c}} 
        call    update_crc        ;{{2b9c:cd002b}}  update crc

;; write a high level
        ld      l,$0b             ;{{2b9f:2e0b}}  %00001011 = set bit 5 (cassette write data)
        call    write_level_to_cassette;{{2ba1:cda72b}} 

_write_bit_to_cassette_26:        ;{{Addr=$2ba4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$01             ;{{2ba4:3e01}} 
        ret                       ;{{2ba6:c9}} 


;;=====================================================================
;; write level to cassette
;; uses PPI control bit set/clear function
;; L = PPI Control byte 
;;   bit 7 = 0
;;   bit 3,2,1 = bit index
;;   bit 0: 1=bit set, 0=bit clear

write_level_to_cassette:          ;{{Addr=$2ba7 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,r               ;{{2ba7:ed5f}} 
        srl     a                 ;{{2ba9:cb3f}} 
        sub     c                 ;{{2bab:91}} 
        jr      nc,_write_level_to_cassette_6;{{2bac:3003}}  

;; delay in 4us (16T-state) units
;; total delay = ((A-1)*4) + 3

_write_level_to_cassette_4:       ;{{Addr=$2bae Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{2bae:3c}}  [1]
        jr      nz,_write_level_to_cassette_4;{{2baf:20fd}}  [3] 

;; set low/high level
_write_level_to_cassette_6:       ;{{Addr=$2bb1 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f7             ;{{2bb1:06f7}}  PPI control 
        out     (c),l             ;{{2bb3:ed69}}  set control

        push    af                ;{{2bb5:f5}} 
        xor     a                 ;{{2bb6:af}} 
        ld      r,a               ;{{2bb7:ed4f}} 
        pop     af                ;{{2bb9:f1}} 
        ret                       ;{{2bba:c9}} 

;;=====================================================================
;; CAS START MOTOR
;;
;; start cassette motor (if cassette motor was previously off
;; allow to to achieve full rotational speed)
CAS_START_MOTOR:                  ;{{Addr=$2bbb Code Calls/jump count: 2 Data use count: 1}}
        ld      a,$10             ;{{2bbb:3e10}}  start cassette motor
        jr      CAS_RESTORE_MOTOR ;{{2bbd:1802}}  CAS RESTORE MOTOR 

;;=====================================================================
;; CAS STOP MOTOR

CAS_STOP_MOTOR:                   ;{{Addr=$2bbf Code Calls/jump count: 2 Data use count: 1}}
        ld      a,$ef             ;{{2bbf:3eef}}  stop cassette motor

;;=====================================================================
;; CAS RESTORE MOTOR
;;
;; - if motor was switched from off->on, delay for a time to allow
;; cassette motor to achieve full rotational speed
;; - if motor was switched from on->off, do nothing

;; bit 4 of register A = cassette motor state
CAS_RESTORE_MOTOR:                ;{{Addr=$2bc1 Code Calls/jump count: 2 Data use count: 1}}
        push    bc                ;{{2bc1:c5}} 

        ld      b,$f6             ;{{2bc2:06f6}}  B = I/O address for PPI port C 
        in      c,(c)             ;{{2bc4:ed48}}  read current inputs (includes cassette input data)
        inc     b                 ;{{2bc6:04}}  B = I/O address for PPI control		

        and     $10               ;{{2bc7:e610}}  isolate cassette motor state from requested
                                  ; cassette motor status
									
        ld      a,$08             ;{{2bc9:3e08}}  %00001000	= cassette motor off
        jr      z,_cas_restore_motor_8;{{2bcb:2801}} 

        inc     a                 ;{{2bcd:3c}}  %00001001 = cassette motor on

_cas_restore_motor_8:             ;{{Addr=$2bce Code Calls/jump count: 1 Data use count: 0}}
        out     (c),a             ;{{2bce:ed79}}  set the requested motor state
                                  ; (uses PPI Control bit set/reset feature)

        scf                       ;{{2bd0:37}} 
        jr      z,_cas_restore_motor_18;{{2bd1:280c}} 

        ld      a,c               ;{{2bd3:79}} 
        and     $10               ;{{2bd4:e610}}  previous state

        push    bc                ;{{2bd6:c5}} 
        ld      bc,$00c8          ;{{2bd7:01c800}}  delay in 1/100ths of a second ##LIT##;WARNING: Code area used as literal
        scf                       ;{{2bda:37}} 
        call    z,delay__check_for_escape;{{2bdb:cce22b}}  delay for 2 seconds
        pop     bc                ;{{2bde:c1}} 

_cas_restore_motor_18:            ;{{Addr=$2bdf Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{2bdf:79}} 
        pop     bc                ;{{2be0:c1}} 
        ret                       ;{{2be1:c9}} 

;;=================================================================
;; delay & check for escape
;; allows cassette motor to achieve full rotational speed

;; entry conditions:
;; B = delay factor in 1/100ths of a second

;; exit conditions:
;; c = delay completed and escape was not pressed
;; nc = escape was pressed

delay__check_for_escape:          ;{{Addr=$2be2 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{2be2:c5}} 
        push    hl                ;{{2be3:e5}} 
        call    tenth_of_a_second_delay;{{2be4:cdf92b}} ; 1/100th of a second delay

        ld      a,$42             ;{{2be7:3e42}} ; keycode for escape key 
        call    KM_TEST_KEY       ;{{2be9:cd451e}} ; check for escape pressed (km test key)
                                  ;; if non-zero then escape key has been pressed
                                  ;; if zero, then escape key is not pressed
        pop     hl                ;{{2bec:e1}} 
        pop     bc                ;{{2bed:c1}} 
        jr      nz,_delay__check_for_escape_14;{{2bee:2007}} ; escape key pressed?

;; continue delay
        dec     bc                ;{{2bf0:0b}} 
        ld      a,b               ;{{2bf1:78}} 
        or      c                 ;{{2bf2:b1}} 
        jr      nz,delay__check_for_escape;{{2bf3:20ed}} 

;; delay completed successfully and escape was not pressed
        scf                       ;{{2bf5:37}} 
        ret                       ;{{2bf6:c9}} 

;; escape was pressed
_delay__check_for_escape_14:      ;{{Addr=$2bf7 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{2bf7:af}} 
        ret                       ;{{2bf8:c9}} 

;;========================================================================================
;; tenth of a second delay

tenth_of_a_second_delay:          ;{{Addr=$2bf9 Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$0682          ;{{2bf9:018206}}  [3] ##LIT##;WARNING: Code area used as literal

;; total delay is ((BC-1)*(2+1+1+3)) + (2+1+1+2) + 3 + 3 = 11667 microseconds
;; there are 1000000 microseconds in a second
;; therefore delay is 11667/1000000 = 0.01 seconds or 1/100th of a second

_tenth_of_a_second_delay_1:       ;{{Addr=$2bfc Code Calls/jump count: 1 Data use count: 0}}
        dec     bc                ;{{2bfc:0b}}  [2]
        ld      a,b               ;{{2bfd:78}}  [1]
        or      c                 ;{{2bfe:b1}}  [1]
        jr      nz,_tenth_of_a_second_delay_1;{{2bff:20fb}}  [3]

        ret                       ;{{2c01:c9}}  [3]





;;***LineEditor.asm
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




;;***FPMaths.asm
;; MATHS ROUTINES
;;=============================================================================
;;
;;Limited documentation for these can be found at
;;https://www.cpcwiki.eu/index.php/BIOS_Function_Summary

;;=============================================================================
;; REAL: PI to DE
REAL_PI_to_DE:                    ;{{Addr=$2f73 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,PI_const       ;{{2f73:11782f}} 
        jr      REAL_copy_atDE_to_atHL;{{2f76:1819}} 

;;+
;;PI const
PI_const:                         ;{{Addr=$2f78 Data Calls/jump count: 0 Data use count: 1}}
        defb $a2,$da,$0f,$49,$82  ; PI in floating point format 3.14159265

;;===========================================================================================
;; REAL: ONE to DE
REAL_ONE_to_DE:                   ;{{Addr=$2f7d Code Calls/jump count: 4 Data use count: 0}}
        ld      de,ONE_const      ;{{2f7d:11822f}} 
        jr      REAL_copy_atDE_to_atHL;{{2f80:180f}}  (+&0f)

;;+
;;ONE const
ONE_const:                        ;{{Addr=$2f82 Data Calls/jump count: 0 Data use count: 2}}
        defb $00,$00,$00,$00,$81  ; 1 in floating point format

;;===========================================================================================
;;REAL copy atHL to b10e swapped
REAL_copy_atHL_to_b10e_swapped:   ;{{Addr=$2f87 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{2f87:eb}} 

;;= REAL move DE to b10e
REAL_move_DE_to_b10e:             ;{{Addr=$2f88 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,internal_REAL_store_3;{{2f88:210eb1}} 
        jr      REAL_copy_atDE_to_atHL;{{2f8b:1804}}  (+&04)

;;---------------------------------------
;;REAL copy atHL to b104
_real_move_de_to_b10e_2:          ;{{Addr=$2f8d Code Calls/jump count: 3 Data use count: 0}}
        ld      de,internal_REAL_store_1;{{2f8d:1104b1}} 

;;= REAL copy atHL to atDE swapped
REAL_copy_atHL_to_atDE_swapped:   ;{{Addr=$2f90 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{2f90:eb}} 

;;=---------------------------------------
;; REAL copy atDE to atHL
;; HL = points to address to write floating point number to
;; DE = points to address of a floating point number

REAL_copy_atDE_to_atHL:           ;{{Addr=$2f91 Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{2f91:e5}} 
        push    de                ;{{2f92:d5}} 
        push    bc                ;{{2f93:c5}} 
        ex      de,hl             ;{{2f94:eb}} 
        ld      bc,$0005          ;{{2f95:010500}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{2f98:edb0}} 
        pop     bc                ;{{2f9a:c1}} 
        pop     de                ;{{2f9b:d1}} 
        pop     hl                ;{{2f9c:e1}} 
        scf                       ;{{2f9d:37}} 
        ret                       ;{{2f9e:c9}} 

;;============================================================================================
;; REAL: INT to real
REAL_INT_to_real:                 ;{{Addr=$2f9f Code Calls/jump count: 2 Data use count: 1}}
        push    de                ;{{2f9f:d5}} 
        push    bc                ;{{2fa0:c5}} 
        or      $7f               ;{{2fa1:f67f}} 
        ld      b,a               ;{{2fa3:47}} 
        xor     a                 ;{{2fa4:af}} 
        ld      (de),a            ;{{2fa5:12}} 
        inc     de                ;{{2fa6:13}} 
        ld      (de),a            ;{{2fa7:12}} 
        inc     de                ;{{2fa8:13}} 
        ld      c,$90             ;{{2fa9:0e90}} 
        or      h                 ;{{2fab:b4}} 
        jr      nz,_real_int_to_real_21;{{2fac:200d}}  (+&0d)
        ld      c,a               ;{{2fae:4f}} 
        or      l                 ;{{2faf:b5}} 
        jr      z,_real_int_to_real_23;{{2fb0:280d}}  (+&0d)
        ld      l,h               ;{{2fb2:6c}} 
        ld      c,$88             ;{{2fb3:0e88}} 
        jr      _real_int_to_real_21;{{2fb5:1804}}  (+&04)
_real_int_to_real_18:             ;{{Addr=$2fb7 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{2fb7:0d}} 
        sla     l                 ;{{2fb8:cb25}} 
        adc     a,a               ;{{2fba:8f}} 
_real_int_to_real_21:             ;{{Addr=$2fbb Code Calls/jump count: 2 Data use count: 0}}
        jp      p,_real_int_to_real_18;{{2fbb:f2b72f}} 
        and     b                 ;{{2fbe:a0}} 
_real_int_to_real_23:             ;{{Addr=$2fbf Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{2fbf:eb}} 
        ld      (hl),e            ;{{2fc0:73}} 
        inc     hl                ;{{2fc1:23}} 
        ld      (hl),a            ;{{2fc2:77}} 
        inc     hl                ;{{2fc3:23}} 
        ld      (hl),c            ;{{2fc4:71}} 
        pop     bc                ;{{2fc5:c1}} 
        pop     hl                ;{{2fc6:e1}} 
        ret                       ;{{2fc7:c9}} 

;;============================================================================================
;; REAL: BIN to real
REAL_BIN_to_real:                 ;{{Addr=$2fc8 Code Calls/jump count: 0 Data use count: 1}}
        push    bc                ;{{2fc8:c5}} 
        ld      bc,$a000          ;{{2fc9:0100a0}} 
        call    _real_5byte_to_real_1;{{2fcc:cdd32f}} 
        pop     bc                ;{{2fcf:c1}} 
        ret                       ;{{2fd0:c9}} 

;;============================================================================================
;; REAL 5-byte to real
REAL_5byte_to_real:               ;{{Addr=$2fd1 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$a8             ;{{2fd1:06a8}} 
_real_5byte_to_real_1:            ;{{Addr=$2fd3 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{2fd3:d5}} 
        call    Process_REAL_at_HL;{{2fd4:cd9c37}} 
        pop     de                ;{{2fd7:d1}} 
        ret                       ;{{2fd8:c9}} 

;;============================================================================================
;; REAL to int
REAL_to_int:                      ;{{Addr=$2fd9 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{2fd9:e5}} 
        pop     ix                ;{{2fda:dde1}} 
        xor     a                 ;{{2fdc:af}} 
        sub     (ix+$04)          ;{{2fdd:dd9604}} 
        jr      z,_real_to_int_22 ;{{2fe0:281b}}  (+&1b)
        add     a,$90             ;{{2fe2:c690}} 
        ret     nc                ;{{2fe4:d0}} 

        push    de                ;{{2fe5:d5}} 
        push    bc                ;{{2fe6:c5}} 
        add     a,$10             ;{{2fe7:c610}} 
        call    x373d_code        ;{{2fe9:cd3d37}} 
        sla     c                 ;{{2fec:cb21}} 
        adc     hl,de             ;{{2fee:ed5a}} 
        jr      z,_real_to_int_20 ;{{2ff0:2808}}  (+&08)
        ld      a,(ix+$03)        ;{{2ff2:dd7e03}} 
        or      a                 ;{{2ff5:b7}} 
_real_to_int_16:                  ;{{Addr=$2ff6 Code Calls/jump count: 1 Data use count: 0}}
        ccf                       ;{{2ff6:3f}} 
        pop     bc                ;{{2ff7:c1}} 
        pop     de                ;{{2ff8:d1}} 
        ret                       ;{{2ff9:c9}} 

_real_to_int_20:                  ;{{Addr=$2ffa Code Calls/jump count: 1 Data use count: 0}}
        sbc     a,a               ;{{2ffa:9f}} 
        jr      _real_to_int_16   ;{{2ffb:18f9}}  (-&07)
_real_to_int_22:                  ;{{Addr=$2ffd Code Calls/jump count: 1 Data use count: 0}}
        ld      l,a               ;{{2ffd:6f}} 
        ld      h,a               ;{{2ffe:67}} 
        scf                       ;{{2fff:37}} 
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
        inc     hl                ;{{300b:23}} 
        dec     a                 ;{{300c:3d}} 
        jr      nz,_real_to_bin_5 ;{{300d:20f9}}  (-&07)
        inc     (hl)              ;{{300f:34}} 
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
        sub     (ix+$04)          ;{{301a:dd9604}} 
        jr      nz,_real_fix_13   ;{{301d:200a}}  (+&0a)
        ld      b,$04             ;{{301f:0604}} 
_real_fix_8:                      ;{{Addr=$3021 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{3021:77}} 
        inc     hl                ;{{3022:23}} 
        djnz    _real_fix_8       ;{{3023:10fc}}  (-&04)
        ld      c,$01             ;{{3025:0e01}} 
        jr      _real_fix_45      ;{{3027:1828}}  (+&28)

_real_fix_13:                     ;{{Addr=$3029 Code Calls/jump count: 1 Data use count: 0}}
        add     a,$a0             ;{{3029:c6a0}} 
        jr      nc,_real_fix_46   ;{{302b:3025}}  (+&25)
        push    hl                ;{{302d:e5}} 
        call    x373d_code        ;{{302e:cd3d37}} 
        xor     a                 ;{{3031:af}} 
        cp      b                 ;{{3032:b8}} 
        adc     a,a               ;{{3033:8f}} 
        or      c                 ;{{3034:b1}} 
        ld      c,l               ;{{3035:4d}} 
        ld      b,h               ;{{3036:44}} 
        pop     hl                ;{{3037:e1}} 
        ld      (hl),c            ;{{3038:71}} 
        inc     hl                ;{{3039:23}} 
        ld      (hl),b            ;{{303a:70}} 
        inc     hl                ;{{303b:23}} 
        ld      (hl),e            ;{{303c:73}} 
        inc     hl                ;{{303d:23}} 
        ld      e,a               ;{{303e:5f}} 
        ld      a,(hl)            ;{{303f:7e}} 
        ld      (hl),d            ;{{3040:72}} 
        and     $80               ;{{3041:e680}} 
        ld      b,a               ;{{3043:47}} 
        ld      c,$04             ;{{3044:0e04}} 
        xor     a                 ;{{3046:af}} 
_real_fix_37:                     ;{{Addr=$3047 Code Calls/jump count: 1 Data use count: 0}}
        or      (hl)              ;{{3047:b6}} 
        jr      nz,_real_fix_43   ;{{3048:2005}}  (+&05)
        dec     hl                ;{{304a:2b}} 
        dec     c                 ;{{304b:0d}} 
        jr      nz,_real_fix_37   ;{{304c:20f9}}  (-&07)
        inc     c                 ;{{304e:0c}} 
_real_fix_43:                     ;{{Addr=$304f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{304f:7b}} 
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

        bit     7,b               ;{{305a:cb78}} 
        ret     z                 ;{{305c:c8}} 

        jr      _real_to_bin_3    ;{{305d:18a7}}  (-&59)

;;================================================================
;; REAL prepare for decimal

REAL_prepare_for_decimal:         ;{{Addr=$305f Code Calls/jump count: 0 Data use count: 1}}
        call    REAL_SGN          ;{{305f:cd2737}} 
        ld      b,a               ;{{3062:47}} 
        jr      z,_real_prepare_for_decimal_55;{{3063:2852}}  (+&52)
        call    m,_real_negate_2  ;{{3065:fc3437}} 
        push    hl                ;{{3068:e5}} 
        ld      a,(ix+$04)        ;{{3069:dd7e04}} 
        sub     $80               ;{{306c:d680}} 
        ld      e,a               ;{{306e:5f}} 
        sbc     a,a               ;{{306f:9f}} 
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
        add     hl,hl             ;{{307a:29}} 
        add     hl,de             ;{{307b:19}} 
        ld      a,h               ;{{307c:7c}} 
        sub     $09               ;{{307d:d609}} 
        ld      c,a               ;{{307f:4f}} 
        pop     hl                ;{{3080:e1}} 
        push    bc                ;{{3081:c5}} 
        call    nz,_real_exp_a_2  ;{{3082:c4c830}} 
_real_prepare_for_decimal_27:     ;{{Addr=$3085 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,Jumpblock_BD76_constant_a;{{3085:11bc30}} 
        call    _real_compare_2   ;{{3088:cde236}} 
        jr      nc,_real_prepare_for_decimal_36;{{308b:300b}}  (+&0b)
        ld      de,powers_of_10_constants;{{308d:11f530}}  start of power's of ten
        call    REAL_multiplication;{{3090:cd7735}} 
        pop     de                ;{{3093:d1}} 
        dec     e                 ;{{3094:1d}} 
        push    de                ;{{3095:d5}} 
        jr      _real_prepare_for_decimal_27;{{3096:18ed}}  (-&13)
_real_prepare_for_decimal_36:     ;{{Addr=$3098 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,Jumpblock_BD76_constant_b;{{3098:11c130}} 
        call    _real_compare_2   ;{{309b:cde236}} 
        jr      c,_real_prepare_for_decimal_45;{{309e:380b}}  (+&0b)
        ld      de,powers_of_10_constants;{{30a0:11f530}}  start of power's of ten
        call    REAL_division     ;{{30a3:cd0436}} 
        pop     de                ;{{30a6:d1}} 
        inc     e                 ;{{30a7:1c}} 
        push    de                ;{{30a8:d5}} 
        jr      _real_prepare_for_decimal_36;{{30a9:18ed}}  (-&13)
_real_prepare_for_decimal_45:     ;{{Addr=$30ab Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_to_bin       ;{{30ab:cd0130}} 
        ld      a,c               ;{{30ae:79}} 
        pop     de                ;{{30af:d1}} 
        ld      b,d               ;{{30b0:42}} 
        dec     a                 ;{{30b1:3d}} 
        add     a,l               ;{{30b2:85}} 
        ld      l,a               ;{{30b3:6f}} 
        ret     nc                ;{{30b4:d0}} 

        inc     h                 ;{{30b5:24}} 
        ret                       ;{{30b6:c9}} 

_real_prepare_for_decimal_55:     ;{{Addr=$30b7 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{30b7:5f}} 
        ld      (hl),a            ;{{30b8:77}} 
        ld      c,$01             ;{{30b9:0e01}} 
        ret                       ;{{30bb:c9}} 

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
        cpl                       ;{{30c6:2f}} 
        inc     a                 ;{{30c7:3c}} 
_real_exp_a_2:                    ;{{Addr=$30c8 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{30c8:b7}} 
        scf                       ;{{30c9:37}} 
        ret     z                 ;{{30ca:c8}} 

        ld      c,a               ;{{30cb:4f}} 
        jp      p,_real_exp_a_9   ;{{30cc:f2d130}} 
        cpl                       ;{{30cf:2f}} 
        inc     a                 ;{{30d0:3c}} 
_real_exp_a_9:                    ;{{Addr=$30d1 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,_powers_of_10_constants_12;{{30d1:113131}} 
        sub     $0d               ;{{30d4:d60d}} 
        jr      z,_real_exp_a_28  ;{{30d6:2815}}  (+&15)
        jr      c,_real_exp_a_19  ;{{30d8:3809}}  (+&09)
        push    bc                ;{{30da:c5}} 
        push    af                ;{{30db:f5}} 
        call    _real_exp_a_28    ;{{30dc:cded30}} 
        pop     af                ;{{30df:f1}} 
        pop     bc                ;{{30e0:c1}} 
        jr      _real_exp_a_9     ;{{30e1:18ee}}  (-&12)
_real_exp_a_19:                   ;{{Addr=$30e3 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{30e3:47}} 
        add     a,a               ;{{30e4:87}} 
        add     a,a               ;{{30e5:87}} 
        add     a,b               ;{{30e6:80}} 
        add     a,e               ;{{30e7:83}} 
        ld      e,a               ;{{30e8:5f}} 
        ld      a,$ff             ;{{30e9:3eff}} 
        adc     a,d               ;{{30eb:8a}} 
        ld      d,a               ;{{30ec:57}} 
_real_exp_a_28:                   ;{{Addr=$30ed Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{30ed:79}} 
        or      a                 ;{{30ee:b7}} 
        jp      p,REAL_division   ;{{30ef:f20436}} 
        jp      REAL_multiplication;{{30f2:c37735}} 

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
        ld      hl,$6c07          ;{{313c:21076c}} 
        ld      (C6_last_random_number),hl;{{313f:2200b1}} 
        ret                       ;{{3142:c9}} 

;;============================================================================================
;; REAL: RANDOMIZE seed
REAL_RANDOMIZE_seed:              ;{{Addr=$3143 Code Calls/jump count: 0 Data use count: 1}}
        ex      de,hl             ;{{3143:eb}} 
        call    REAL_init_random_number_generator;{{3144:cd3631}} 
        ex      de,hl             ;{{3147:eb}} 
        call    REAL_SGN          ;{{3148:cd2737}} 
        ret     z                 ;{{314b:c8}} 

        ld      de,C6_last_random_number;{{314c:1100b1}} 
        ld      b,$04             ;{{314f:0604}} 
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
        ld      hl,(last_random_number);{{315a:2a02b1}} 
        ld      bc,$6c07          ;{{315d:01076c}} 
        call    _real_rnd0_7      ;{{3160:cd9c31}} 
        push    hl                ;{{3163:e5}} 
        ld      hl,(C6_last_random_number);{{3164:2a00b1}} 
        ld      bc,$8965          ;{{3167:016589}} 
        call    _real_rnd0_7      ;{{316a:cd9c31}} 
        push    de                ;{{316d:d5}} 
        push    hl                ;{{316e:e5}} 
        ld      hl,(last_random_number);{{316f:2a02b1}} 
        call    _real_rnd0_7      ;{{3172:cd9c31}} 
        ex      (sp),hl           ;{{3175:e3}} 
        add     hl,bc             ;{{3176:09}} 
        ld      (C6_last_random_number),hl;{{3177:2200b1}} 
        pop     hl                ;{{317a:e1}} 
        ld      bc,$6c07          ;{{317b:01076c}} 
        adc     hl,bc             ;{{317e:ed4a}} 
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
        ld      hl,(C6_last_random_number);{{318b:2a00b1}} 
        ld      de,(last_random_number);{{318e:ed5b02b1}} 
        ld      bc,$0000          ;{{3192:010000}} ##LIT##;WARNING: Code area used as literal
        ld      (ix+$04),$80      ;{{3195:dd360480}} 
        jp      _process_real_at_hl_13;{{3199:c3ac37}} 

_real_rnd0_7:                     ;{{Addr=$319c Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{319c:eb}} 
        ld      hl,$0000          ;{{319d:210000}} ##LIT##;WARNING: Code area used as literal
        ld      a,$11             ;{{31a0:3e11}} 
_real_rnd0_10:                    ;{{Addr=$31a2 Code Calls/jump count: 3 Data use count: 0}}
        dec     a                 ;{{31a2:3d}} 
        ret     z                 ;{{31a3:c8}} 

        add     hl,hl             ;{{31a4:29}} 
        rl      e                 ;{{31a5:cb13}} 
        rl      d                 ;{{31a7:cb12}} 
        jr      nc,_real_rnd0_10  ;{{31a9:30f7}}  (-&09)
        add     hl,bc             ;{{31ab:09}} 
        jr      nc,_real_rnd0_10  ;{{31ac:30f4}}  (-&0c)
        inc     de                ;{{31ae:13}} 
        jr      _real_rnd0_10     ;{{31af:18f1}}  (-&0f)

;;============================================================================================
;; REAL log10
REAL_log10:                       ;{{Addr=$31b1 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,const_0301029996;{{31b1:112a32}} 
        jr      _real_log_1       ;{{31b4:1803}}  (+&03)

;;============================================================================================
;; REAL log
REAL_log:                         ;{{Addr=$31b6 Code Calls/jump count: 1 Data use count: 1}}
        ld      de,const_0693147181;{{31b6:112532}} 
_real_log_1:                      ;{{Addr=$31b9 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_SGN          ;{{31b9:cd2737}} 
        dec     a                 ;{{31bc:3d}} 
        cp      $01               ;{{31bd:fe01}} 
        ret     nc                ;{{31bf:d0}} 

        push    de                ;{{31c0:d5}} 
        call    _real_division_121;{{31c1:cdd336}} 
        push    af                ;{{31c4:f5}} 
        ld      (ix+$04),$80      ;{{31c5:dd360480}} 
        ld      de,const_0707106781;{{31c9:112032}} 
        call    REAL_compare      ;{{31cc:cddf36}} 
        jr      nc,_real_log_16   ;{{31cf:3006}}  (+&06)
        inc     (ix+$04)          ;{{31d1:dd3404}} 
        pop     af                ;{{31d4:f1}} 
        dec     a                 ;{{31d5:3d}} 
        push    af                ;{{31d6:f5}} 
_real_log_16:                     ;{{Addr=$31d7 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_copy_atHL_to_b10e_swapped;{{31d7:cd872f}} 
        push    de                ;{{31da:d5}} 
        ld      de,ONE_const      ;{{31db:11822f}} 
        push    de                ;{{31de:d5}} 
        call    REAL_addition     ;{{31df:cda234}} 
        pop     de                ;{{31e2:d1}} 
        ex      (sp),hl           ;{{31e3:e3}} 
        call    x349a_code        ;{{31e4:cd9a34}} 
        pop     de                ;{{31e7:d1}} 
        call    REAL_division     ;{{31e8:cd0436}} 
        call    process_inline_parameters;{{31eb:cd4034}} Code takes inline parameter block

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
        or      a                 ;{{320a:b7}} 
        jp      p,_real_log_41    ;{{320b:f21032}} 
        cpl                       ;{{320e:2f}} 
        inc     a                 ;{{320f:3c}} 
_real_log_41:                     ;{{Addr=$3210 Code Calls/jump count: 1 Data use count: 0}}
        ld      l,a               ;{{3210:6f}} 
        ld      a,h               ;{{3211:7c}} 
        ld      h,$00             ;{{3212:2600}} 
        call    REAL_INT_to_real  ;{{3214:cd9f2f}} 
        ex      de,hl             ;{{3217:eb}} 
        pop     hl                ;{{3218:e1}} 
        call    REAL_addition     ;{{3219:cda234}} 
        pop     de                ;{{321c:d1}} 
        jp      REAL_multiplication;{{321d:c37735}} 

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
        ld      b,$e1             ;{{322f:06e1}} 
        call    x3492_code        ;{{3231:cd9234}} 
        jp      nc,REAL_ONE_to_DE ;{{3234:d27d2f}} 
        ld      de,exp_constant_c ;{{3237:11a232}} 
        call    REAL_compare      ;{{323a:cddf36}} 
        jp      p,REAL_at_IX_to_max_pos;{{323d:f2e837}} 
        ld      de,exp_constant_d ;{{3240:11a732}} 
        call    REAL_compare      ;{{3243:cddf36}} 
        jp      m,_process_real_at_hl_42;{{3246:fae237}} 
        ld      de,exp_constant_b ;{{3249:119d32}} 
        call    x3469_code        ;{{324c:cd6934}} 
        ld      a,e               ;{{324f:7b}} 
        jp      p,_real_exp_14    ;{{3250:f25532}} 
        neg                       ;{{3253:ed44}} 
_real_exp_14:                     ;{{Addr=$3255 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{3255:f5}} 
        call    _real_addition_119;{{3256:cd7035}} 
        call    _real_move_de_to_b10e_2;{{3259:cd8d2f}} 
        push    de                ;{{325c:d5}} 
        call    _process_inline_parameters_1;{{325d:cd4334}} Code takes inline parameter block

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
        call    REAL_multiplication;{{32ff:cd7735}} 
        pop     de                ;{{3282:d1}} 
        push    hl                ;{{3283:e5}} 
        ex      de,hl             ;{{3284:eb}} 
        call    x349a_code        ;{{3285:cd9a34}} 
        ex      de,hl             ;{{3288:eb}} 
        pop     hl                ;{{3289:e1}} 
        call    REAL_division     ;{{328a:cd0436}} 
        ld      de,exp_constant_a ;{{328d:116b32}} 
        call    REAL_addition     ;{{3290:cda234}} 
        pop     af                ;{{3293:f1}} 
        scf                       ;{{3294:37}} 
        adc     a,(ix+$04)        ;{{3295:dd8e04}} 
        ld      (ix+$04),a        ;{{3298:dd7704}} 
        scf                       ;{{329b:37}} 
        ret                       ;{{329c:c9}} 

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
        ld      de,exp_constant_a ;{{32ac:116b32}} 

;;============================================================================================
;; REAL power
REAL_power:                       ;{{Addr=$32af Code Calls/jump count: 0 Data use count: 1}}
        ex      de,hl             ;{{32af:eb}} 
        call    REAL_SGN          ;{{32b0:cd2737}} 
        ex      de,hl             ;{{32b3:eb}} 
        jp      z,REAL_ONE_to_DE  ;{{32b4:ca7d2f}} 
        push    af                ;{{32b7:f5}} 
        call    REAL_SGN          ;{{32b8:cd2737}} 
        jr      z,_real_power_29  ;{{32bb:2825}}  (+&25)
        ld      b,a               ;{{32bd:47}} 
        call    m,_real_negate_2  ;{{32be:fc3437}} 
        push    hl                ;{{32c1:e5}} 
        call    _real_power_72    ;{{32c2:cd2433}} 
        pop     hl                ;{{32c5:e1}} 
        jr      c,_real_power_38  ;{{32c6:3825}}  (+&25)
        ex      (sp),hl           ;{{32c8:e3}} 
        pop     hl                ;{{32c9:e1}} 
        jp      m,_real_power_35  ;{{32ca:faea32}} 
        push    bc                ;{{32cd:c5}} 
        push    de                ;{{32ce:d5}} 
        call    REAL_log          ;{{32cf:cdb631}} 
        pop     de                ;{{32d2:d1}} 
        call    c,REAL_multiplication;{{32d3:dc7735}} 
        call    c,REAL_exp        ;{{32d6:dc2f32}} 
_real_power_22:                   ;{{Addr=$32d9 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{32d9:c1}} 
        ret     nc                ;{{32da:d0}} 

        ld      a,b               ;{{32db:78}} 
        or      a                 ;{{32dc:b7}} 
        call    m,REAL_Negate     ;{{32dd:fc3137}} 
        scf                       ;{{32e0:37}} 
        ret                       ;{{32e1:c9}} 

_real_power_29:                   ;{{Addr=$32e2 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{32e2:f1}} 
        scf                       ;{{32e3:37}} 
        ret     p                 ;{{32e4:f0}} 

        call    REAL_at_IX_to_max_pos;{{32e5:cde837}} 
        xor     a                 ;{{32e8:af}} 
        ret                       ;{{32e9:c9}} 

_real_power_35:                   ;{{Addr=$32ea Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{32ea:af}} 
        inc     a                 ;{{32eb:3c}} 
        ret                       ;{{32ec:c9}} 

_real_power_38:                   ;{{Addr=$32ed Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{32ed:4f}} 
        pop     af                ;{{32ee:f1}} 
        push    bc                ;{{32ef:c5}} 
        push    af                ;{{32f0:f5}} 
        ld      a,c               ;{{32f1:79}} 
        scf                       ;{{32f2:37}} 
_real_power_44:                   ;{{Addr=$32f3 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{32f3:8f}} 
        jr      nc,_real_power_44 ;{{32f4:30fd}}  (-&03)
        ld      b,a               ;{{32f6:47}} 
        call    _real_move_de_to_b10e_2;{{32f7:cd8d2f}} 
        ex      de,hl             ;{{32fa:eb}} 
        ld      a,b               ;{{32fb:78}} 
_real_power_50:                   ;{{Addr=$32fc Code Calls/jump count: 2 Data use count: 0}}
        add     a,a               ;{{32fc:87}} 
        jr      z,_real_power_63  ;{{32fd:2815}}  (+&15)
        push    af                ;{{32ff:f5}} 
        call    _real_addition_119;{{3300:cd7035}} 
        jr      nc,_real_power_67 ;{{3303:3016}}  (+&16)
        pop     af                ;{{3305:f1}} 
        jr      nc,_real_power_50 ;{{3306:30f4}}  (-&0c)
        push    af                ;{{3308:f5}} 
        ld      de,internal_REAL_store_1;{{3309:1104b1}} 
        call    REAL_multiplication;{{330c:cd7735}} 
        jr      nc,_real_power_67 ;{{330f:300a}}  (+&0a)
        pop     af                ;{{3311:f1}} 
        jr      _real_power_50    ;{{3312:18e8}}  (-&18)

_real_power_63:                   ;{{Addr=$3314 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{3314:f1}} 
        scf                       ;{{3315:37}} 
        call    m,_real_multiplication_72;{{3316:fcfb35}} 
        jr      _real_power_22    ;{{3319:18be}}  (-&42)

_real_power_67:                   ;{{Addr=$331b Code Calls/jump count: 2 Data use count: 0}}
        pop     af                ;{{331b:f1}} 
        pop     af                ;{{331c:f1}} 
        pop     bc                ;{{331d:c1}} 
        jp      m,_process_real_at_hl_42;{{331e:fae237}} 
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3321:c3ea37}} 

_real_power_72:                   ;{{Addr=$3324 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{3324:c5}} 
        call    REAL_move_DE_to_b10e;{{3325:cd882f}} 
        call    REAL_fix          ;{{3328:cd1430}} 
        ld      a,c               ;{{332b:79}} 
        pop     bc                ;{{332c:c1}} 
        jr      nc,_real_power_79 ;{{332d:3002}}  (+&02)
        jr      z,_real_power_82  ;{{332f:2803}}  (+&03)
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
        ld      a,c               ;{{333a:79}} 
        cp      $02               ;{{333b:fe02}} 
        sbc     a,a               ;{{333d:9f}} 
        ret     nc                ;{{333e:d0}} 

        ld      a,(hl)            ;{{333f:7e}} 
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
        call    m,_real_negate_2  ;{{334c:fc3437}} 
        or      $01               ;{{334f:f601}} 
        jr      _real_sin_1       ;{{3351:1801}}  (+&01)

;;============================================================================================
;; REAL sin
REAL_sin:                         ;{{Addr=$3353 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{3353:af}} 
_real_sin_1:                      ;{{Addr=$3354 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{3354:f5}} 
        ld      de,sin_constant_b ;{{3355:11b433}} 
        ld      b,$f0             ;{{3358:06f0}} 
        ld      a,(DEG__RAD_flag_);{{335a:3a13b1}} 
        or      a                 ;{{335d:b7}} 
        jr      z,_real_sin_9     ;{{335e:2805}}  (+&05)
        ld      de,sin_constant_c ;{{3360:11b933}} 
        ld      b,$f6             ;{{3363:06f6}} 
_real_sin_9:                      ;{{Addr=$3365 Code Calls/jump count: 1 Data use count: 0}}
        call    x3492_code        ;{{3365:cd9234}} 
        jr      nc,_sin_code_block_2_1;{{3368:303a}}  (+&3a)
        pop     af                ;{{336a:f1}} 
        call    x346a_code        ;{{336b:cd6a34}} 
        ret     nc                ;{{336e:d0}} 

        ld      a,e               ;{{336f:7b}} 
        rra                       ;{{3370:1f}} 
        call    c,_real_negate_2  ;{{3371:dc3437}} 
        ld      b,$e8             ;{{3374:06e8}} 
        call    x3492_code        ;{{3376:cd9234}} 
        jp      nc,_process_real_at_hl_42;{{3379:d2e237}} 
        inc     (ix+$04)          ;{{337c:dd3404}} 
        call    process_inline_parameters;{{337f:cd4034}} Code pops parameter block address from stack

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
        jp      REAL_multiplication;{{33a1:c37735}} 

_sin_code_block_2_1:              ;{{Addr=$33a4 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{33a4:f1}} 
        jp      nz,REAL_ONE_to_DE ;{{33a5:c27d2f}} 
        ld      a,(DEG__RAD_flag_);{{33a8:3a13b1}} 
        cp      $01               ;{{33ab:fe01}} 
        ret     c                 ;{{33ad:d8}} 

        ld      de,sin_constant_d ;{{33ae:11be33}} 
        jp      REAL_multiplication;{{33b1:c37735}} 

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
        call    _real_move_de_to_b10e_2;{{33c8:cd8d2f}} 
        push    de                ;{{33cb:d5}} 
        call    REAL_cosine       ;{{33cc:cd4933}} 
        ex      (sp),hl           ;{{33cf:e3}} 
        call    c,REAL_sin        ;{{33d0:dc5333}} 
        pop     de                ;{{33d3:d1}} 
        jp      c,REAL_division   ;{{33d4:da0436}} 
        ret                       ;{{33d7:c9}} 

;;============================================================================================
;; REAL arctan
REAL_arctan:                      ;{{Addr=$33d8 Code Calls/jump count: 0 Data use count: 1}}
        call    REAL_SGN          ;{{33d8:cd2737}} 
        push    af                ;{{33db:f5}} 
        call    m,_real_negate_2  ;{{33dc:fc3437}} 
        ld      b,$f0             ;{{33df:06f0}} 
        call    x3492_code        ;{{33e1:cd9234}} 
        jr      nc,_real_arctan_26;{{33e4:304a}}  (+&4a)
        dec     a                 ;{{33e6:3d}} 
        push    af                ;{{33e7:f5}} 
        call    p,_real_multiplication_72;{{33e8:f4fb35}} 
        call    process_inline_parameters;{{33eb:cd4034}} Code which takes an inline parameter block

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
        ld      de,sin_constant_a ;{{342a:119c33}} 
        call    p,REAL_reverse_subtract;{{342d:f49e34}} 
_real_arctan_26:                  ;{{Addr=$3430 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(DEG__RAD_flag_);{{3430:3a13b1}} 
        or      a                 ;{{3433:b7}} 
        ld      de,sin_constant_e ;{{3434:11c333}} 
        call    nz,REAL_multiplication;{{3437:c47735}} 
        pop     af                ;{{343a:f1}} 
        call    m,_real_negate_2  ;{{343b:fc3437}} 
        scf                       ;{{343e:37}} 
        ret                       ;{{343f:c9}} 


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
        inc     de                ;{{344c:13}} Advance to next parameter
        inc     de                ;{{344d:13}} 
        inc     de                ;{{344e:13}} 
        inc     de                ;{{344f:13}} 
        inc     de                ;{{3450:13}} 
        push    de                ;{{3451:d5}} Possible return address
        ld      de,internal_REAL_store_2;{{3452:1109b1}} 
        dec     b                 ;{{3455:05}} 
        ret     z                 ;{{3456:c8}} 

        push    bc                ;{{3457:c5}} 
        ld      de,internal_REAL_store_3;{{3458:110eb1}} 
        call    REAL_multiplication;{{345b:cd7735}} 
        pop     bc                ;{{345e:c1}} 
        pop     de                ;{{345f:d1}} Get back address of next parameter
        push    de                ;{{3460:d5}} 
        push    bc                ;{{3461:c5}} 
        call    REAL_addition     ;{{3462:cda234}} 
        pop     bc                ;{{3465:c1}} 
        pop     de                ;{{3466:d1}} 
        jr      _process_inline_parameters_6;{{3467:18e3}}  (-&1d)

;;=======================================================

x3469_code:                       ;{{Addr=$3469 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{3469:af}} 
x346a_code:                       ;{{Addr=$346a Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{346a:f5}} 
        call    REAL_multiplication;{{346b:cd7735}} 
        pop     af                ;{{346e:f1}} 
        ld      de,exp_constant_a ;{{346f:116b32}} 
        call    nz,REAL_addition  ;{{3472:c4a234}} 
        push    hl                ;{{3475:e5}} 
        call    REAL_to_int       ;{{3476:cdd92f}} 
        jr      nc,x348e_code     ;{{3479:3013}}  (+&13)
        pop     de                ;{{347b:d1}} 
        push    hl                ;{{347c:e5}} 
        push    af                ;{{347d:f5}} 
        push    de                ;{{347e:d5}} 
        ld      de,internal_REAL_store_2;{{347f:1109b1}} 
        call    REAL_INT_to_real  ;{{3482:cd9f2f}} 
        ex      de,hl             ;{{3485:eb}} 
        pop     hl                ;{{3486:e1}} 
        call    x349a_code        ;{{3487:cd9a34}} 
        pop     af                ;{{348a:f1}} 
        pop     de                ;{{348b:d1}} 
        scf                       ;{{348c:37}} 
        ret                       ;{{348d:c9}} 

x348e_code:                       ;{{Addr=$348e Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{348e:e1}} 
        xor     a                 ;{{348f:af}} 
        inc     a                 ;{{3490:3c}} 
        ret                       ;{{3491:c9}} 

x3492_code:                       ;{{Addr=$3492 Code Calls/jump count: 4 Data use count: 0}}
        call    _real_division_121;{{3492:cdd336}} 
        ret     p                 ;{{3495:f0}} 

        cp      b                 ;{{3496:b8}} 
        ret     z                 ;{{3497:c8}} 

        ccf                       ;{{3498:3f}} 
        ret                       ;{{3499:c9}} 

x349a_code:                       ;{{Addr=$349a Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$01             ;{{349a:3e01}} 
        jr      _real_addition_1  ;{{349c:1805}}  (+&05)

;;============================================================================================
;; REAL reverse subtract
REAL_reverse_subtract:            ;{{Addr=$349e Code Calls/jump count: 1 Data use count: 1}}
        ld      a,$80             ;{{349e:3e80}} 
        jr      _real_addition_1  ;{{34a0:1801}}  (+&01)

;;============================================================================================
;; REAL addition
REAL_addition:                    ;{{Addr=$34a2 Code Calls/jump count: 5 Data use count: 1}}
        xor     a                 ;{{34a2:af}} 

; A = function, &00, &01 or &80
_real_addition_1:                 ;{{Addr=$34a3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{34a3:e5}} 
        pop     ix                ;{{34a4:dde1}} 
        push    de                ;{{34a6:d5}} 
        pop     iy                ;{{34a7:fde1}} 
        ld      b,(ix+$03)        ;{{34a9:dd4603}} 
        ld      c,(iy+$03)        ;{{34ac:fd4e03}} 
        or      a                 ;{{34af:b7}} 
        jr      z,_real_addition_16;{{34b0:280a}}  (+&0a)
        jp      m,_real_addition_14;{{34b2:faba34}} 
        rrca                      ;{{34b5:0f}} 
        xor     c                 ;{{34b6:a9}} 
        ld      c,a               ;{{34b7:4f}} 
        jr      _real_addition_16 ;{{34b8:1802}}  (+&02)

_real_addition_14:                ;{{Addr=$34ba Code Calls/jump count: 1 Data use count: 0}}
        xor     b                 ;{{34ba:a8}} 
        ld      b,a               ;{{34bb:47}} 
_real_addition_16:                ;{{Addr=$34bc Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$04)        ;{{34bc:dd7e04}} 
        cp      (iy+$04)          ;{{34bf:fdbe04}} 
        jr      nc,_real_addition_31;{{34c2:3014}}  (+&14)
        ld      d,b               ;{{34c4:50}} 
        ld      b,c               ;{{34c5:41}} 
        ld      c,d               ;{{34c6:4a}} 
        or      a                 ;{{34c7:b7}} 
        ld      d,a               ;{{34c8:57}} 
        ld      a,(iy+$04)        ;{{34c9:fd7e04}} 
        ld      (ix+$04),a        ;{{34cc:dd7704}} 
        jr      z,_real_addition_74;{{34cf:2854}}  (+&54)
        sub     d                 ;{{34d1:92}} 
        cp      $21               ;{{34d2:fe21}} 
        jr      nc,_real_addition_74;{{34d4:304f}}  (+&4f)
        jr      _real_addition_40 ;{{34d6:1811}}  (+&11)

_real_addition_31:                ;{{Addr=$34d8 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{34d8:af}} 
        sub     (iy+$04)          ;{{34d9:fd9604}} 
        jr      z,_real_addition_80;{{34dc:2859}}  (+&59)
        add     a,(ix+$04)        ;{{34de:dd8604}} 
        cp      $21               ;{{34e1:fe21}} 
        jr      nc,_real_addition_80;{{34e3:3052}}  (+&52)
        push    hl                ;{{34e5:e5}} 
        pop     iy                ;{{34e6:fde1}} 
        ex      de,hl             ;{{34e8:eb}} 
_real_addition_40:                ;{{Addr=$34e9 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{34e9:5f}} 
        ld      a,b               ;{{34ea:78}} 
        xor     c                 ;{{34eb:a9}} 
        push    af                ;{{34ec:f5}} 
        push    bc                ;{{34ed:c5}} 
        ld      a,e               ;{{34ee:7b}} 
        call    x3743_code        ;{{34ef:cd4337}} 
        ld      a,c               ;{{34f2:79}} 
        pop     bc                ;{{34f3:c1}} 
        ld      c,a               ;{{34f4:4f}} 
        pop     af                ;{{34f5:f1}} 
        jp      m,_real_addition_83;{{34f6:fa3c35}} 
        ld      a,(iy+$00)        ;{{34f9:fd7e00}} 
        add     a,l               ;{{34fc:85}} 
        ld      l,a               ;{{34fd:6f}} 
        ld      a,(iy+$01)        ;{{34fe:fd7e01}} 
        adc     a,h               ;{{3501:8c}} 
        ld      h,a               ;{{3502:67}} 
        ld      a,(iy+$02)        ;{{3503:fd7e02}} 
        adc     a,e               ;{{3506:8b}} 
        ld      e,a               ;{{3507:5f}} 
        ld      a,(iy+$03)        ;{{3508:fd7e03}} 
        set     7,a               ;{{350b:cbff}} 
        adc     a,d               ;{{350d:8a}} 
        ld      d,a               ;{{350e:57}} 
        jp      nc,_process_real_at_hl_18;{{350f:d2b737}} 
        rr      d                 ;{{3512:cb1a}} 
        rr      e                 ;{{3514:cb1b}} 
        rr      h                 ;{{3516:cb1c}} 
        rr      l                 ;{{3518:cb1d}} 
        rr      c                 ;{{351a:cb19}} 
        inc     (ix+$04)          ;{{351c:dd3404}} 
        jp      nz,_process_real_at_hl_18;{{351f:c2b737}} 
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3522:c3ea37}} 

_real_addition_74:                ;{{Addr=$3525 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(iy+$02)        ;{{3525:fd7e02}} 
        ld      (ix+$02),a        ;{{3528:dd7702}} 
        ld      a,(iy+$01)        ;{{352b:fd7e01}} 
        ld      (ix+$01),a        ;{{352e:dd7701}} 
        ld      a,(iy+$00)        ;{{3531:fd7e00}} 
        ld      (ix+$00),a        ;{{3534:dd7700}} 
_real_addition_80:                ;{{Addr=$3537 Code Calls/jump count: 2 Data use count: 0}}
        ld      (ix+$03),b        ;{{3537:dd7003}} 
        scf                       ;{{353a:37}} 
        ret                       ;{{353b:c9}} 

_real_addition_83:                ;{{Addr=$353c Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{353c:af}} 
        sub     c                 ;{{353d:91}} 
        ld      c,a               ;{{353e:4f}} 
        ld      a,(iy+$00)        ;{{353f:fd7e00}} 
        sbc     a,l               ;{{3542:9d}} 
        ld      l,a               ;{{3543:6f}} 
        ld      a,(iy+$01)        ;{{3544:fd7e01}} 
        sbc     a,h               ;{{3547:9c}} 
        ld      h,a               ;{{3548:67}} 
        ld      a,(iy+$02)        ;{{3549:fd7e02}} 
        sbc     a,e               ;{{354c:9b}} 
        ld      e,a               ;{{354d:5f}} 
        ld      a,(iy+$03)        ;{{354e:fd7e03}} 
        set     7,a               ;{{3551:cbff}} 
        sbc     a,d               ;{{3553:9a}} 
        ld      d,a               ;{{3554:57}} 
        jr      nc,_real_addition_118;{{3555:3016}}  (+&16)
        ld      a,b               ;{{3557:78}} 
        cpl                       ;{{3558:2f}} 
        ld      b,a               ;{{3559:47}} 
        xor     a                 ;{{355a:af}} 
        sub     c                 ;{{355b:91}} 
        ld      c,a               ;{{355c:4f}} 
        ld      a,$00             ;{{355d:3e00}} 
        sbc     a,l               ;{{355f:9d}} 
        ld      l,a               ;{{3560:6f}} 
        ld      a,$00             ;{{3561:3e00}} 
        sbc     a,h               ;{{3563:9c}} 
        ld      h,a               ;{{3564:67}} 
        ld      a,$00             ;{{3565:3e00}} 
        sbc     a,e               ;{{3567:9b}} 
        ld      e,a               ;{{3568:5f}} 
        ld      a,$00             ;{{3569:3e00}} 
        sbc     a,d               ;{{356b:9a}} 
        ld      d,a               ;{{356c:57}} 
_real_addition_118:               ;{{Addr=$356d Code Calls/jump count: 1 Data use count: 0}}
        jp      _process_real_at_hl_13;{{356d:c3ac37}} 

_real_addition_119:               ;{{Addr=$3570 Code Calls/jump count: 3 Data use count: 0}}
        ld      de,internal_REAL_store_2;{{3570:1109b1}} 
        call    REAL_copy_atHL_to_atDE_swapped;{{3573:cd902f}} 
        ex      de,hl             ;{{3576:eb}} 

;;============================================================================================
;; REAL multiplication
REAL_multiplication:              ;{{Addr=$3577 Code Calls/jump count: 13 Data use count: 1}}
        push    de                ;{{3577:d5}} 
        pop     iy                ;{{3578:fde1}} 
        push    hl                ;{{357a:e5}} 
        pop     ix                ;{{357b:dde1}} 
        ld      a,(iy+$04)        ;{{357d:fd7e04}} 
        or      a                 ;{{3580:b7}} 
        jr      z,_real_multiplication_30;{{3581:282a}}  (+&2a)
        dec     a                 ;{{3583:3d}} 
        call    _real_division_98 ;{{3584:cdaf36}} 
        jr      z,_real_multiplication_30;{{3587:2824}}  (+&24)
        jr      nc,_real_multiplication_29;{{3589:301f}}  (+&1f)
        push    af                ;{{358b:f5}} 
        push    bc                ;{{358c:c5}} 
        call    _real_multiplication_31;{{358d:cdb035}} 
        ld      a,c               ;{{3590:79}} 
        pop     bc                ;{{3591:c1}} 
        ld      c,a               ;{{3592:4f}} 
        pop     af                ;{{3593:f1}} 
        bit     7,d               ;{{3594:cb7a}} 
        jr      nz,_real_multiplication_26;{{3596:200b}}  (+&0b)
        dec     a                 ;{{3598:3d}} 
        jr      z,_real_multiplication_30;{{3599:2812}}  (+&12)
        sla     c                 ;{{359b:cb21}} 
        adc     hl,hl             ;{{359d:ed6a}} 
        rl      e                 ;{{359f:cb13}} 
        rl      d                 ;{{35a1:cb12}} 
_real_multiplication_26:          ;{{Addr=$35a3 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$04),a        ;{{35a3:dd7704}} 
        or      a                 ;{{35a6:b7}} 
        jp      nz,_process_real_at_hl_18;{{35a7:c2b737}} 
_real_multiplication_29:          ;{{Addr=$35aa Code Calls/jump count: 1 Data use count: 0}}
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{35aa:c3ea37}} 

_real_multiplication_30:          ;{{Addr=$35ad Code Calls/jump count: 3 Data use count: 0}}
        jp      _process_real_at_hl_42;{{35ad:c3e237}} 

_real_multiplication_31:          ;{{Addr=$35b0 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,$0000          ;{{35b0:210000}} ##LIT##;WARNING: Code area used as literal
        ld      e,l               ;{{35b3:5d}} 
        ld      d,h               ;{{35b4:54}} 
        ld      a,(iy+$00)        ;{{35b5:fd7e00}} 
        call    _real_multiplication_65;{{35b8:cdf335}} 
        ld      a,(iy+$01)        ;{{35bb:fd7e01}} 
        call    _real_multiplication_65;{{35be:cdf335}} 
        ld      a,(iy+$02)        ;{{35c1:fd7e02}} 
        call    _real_multiplication_65;{{35c4:cdf335}} 
        ld      a,(iy+$03)        ;{{35c7:fd7e03}} 
        or      $80               ;{{35ca:f680}} 
_real_multiplication_42:          ;{{Addr=$35cc Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$08             ;{{35cc:0608}} 
        rra                       ;{{35ce:1f}} 
        ld      c,a               ;{{35cf:4f}} 
_real_multiplication_45:          ;{{Addr=$35d0 Code Calls/jump count: 1 Data use count: 0}}
        jr      nc,_real_multiplication_58;{{35d0:3014}}  (+&14)
        ld      a,l               ;{{35d2:7d}} 
        add     a,(ix+$00)        ;{{35d3:dd8600}} 
        ld      l,a               ;{{35d6:6f}} 
        ld      a,h               ;{{35d7:7c}} 
        adc     a,(ix+$01)        ;{{35d8:dd8e01}} 
        ld      h,a               ;{{35db:67}} 
        ld      a,e               ;{{35dc:7b}} 
        adc     a,(ix+$02)        ;{{35dd:dd8e02}} 
        ld      e,a               ;{{35e0:5f}} 
        ld      a,d               ;{{35e1:7a}} 
        adc     a,(ix+$03)        ;{{35e2:dd8e03}} 
        ld      d,a               ;{{35e5:57}} 
_real_multiplication_58:          ;{{Addr=$35e6 Code Calls/jump count: 1 Data use count: 0}}
        rr      d                 ;{{35e6:cb1a}} 
        rr      e                 ;{{35e8:cb1b}} 
        rr      h                 ;{{35ea:cb1c}} 
        rr      l                 ;{{35ec:cb1d}} 
        rr      c                 ;{{35ee:cb19}} 
        djnz    _real_multiplication_45;{{35f0:10de}}  (-&22)
        ret                       ;{{35f2:c9}} 

_real_multiplication_65:          ;{{Addr=$35f3 Code Calls/jump count: 3 Data use count: 0}}
        or      a                 ;{{35f3:b7}} 
        jr      nz,_real_multiplication_42;{{35f4:20d6}}  (-&2a)
        ld      l,h               ;{{35f6:6c}} 
        ld      h,e               ;{{35f7:63}} 
        ld      e,d               ;{{35f8:5a}} 
        ld      d,a               ;{{35f9:57}} 
        ret                       ;{{35fa:c9}} 

_real_multiplication_72:          ;{{Addr=$35fb Code Calls/jump count: 2 Data use count: 0}}
        call    REAL_copy_atHL_to_b10e_swapped;{{35fb:cd872f}} 
        ex      de,hl             ;{{35fe:eb}} 
        push    de                ;{{35ff:d5}} 
        call    REAL_ONE_to_DE    ;{{3600:cd7d2f}} 
        pop     de                ;{{3603:d1}} 

;;============================================================================================
;; REAL division
REAL_division:                    ;{{Addr=$3604 Code Calls/jump count: 5 Data use count: 1}}
        push    de                ;{{3604:d5}} 
        pop     iy                ;{{3605:fde1}} 
        push    hl                ;{{3607:e5}} 
        pop     ix                ;{{3608:dde1}} 
        xor     a                 ;{{360a:af}} 
        sub     (iy+$04)          ;{{360b:fd9604}} 
        jr      z,_real_division_54;{{360e:285a}}  (+&5a)
        call    _real_division_98 ;{{3610:cdaf36}} 
        jp      z,_process_real_at_hl_42;{{3613:cae237}} 
        jr      nc,_real_division_53;{{3616:304f}}  (+&4f)
        push    bc                ;{{3618:c5}} 
        ld      c,a               ;{{3619:4f}} 
        ld      e,(hl)            ;{{361a:5e}} 
        inc     hl                ;{{361b:23}} 
        ld      d,(hl)            ;{{361c:56}} 
        inc     hl                ;{{361d:23}} 
        ld      a,(hl)            ;{{361e:7e}} 
        inc     hl                ;{{361f:23}} 
        ld      h,(hl)            ;{{3620:66}} 
        ld      l,a               ;{{3621:6f}} 
        ex      de,hl             ;{{3622:eb}} 
        ld      b,(iy+$03)        ;{{3623:fd4603}} 
        set     7,b               ;{{3626:cbf8}} 
        call    _real_division_86 ;{{3628:cd9d36}} 
        jr      c,_real_division_29;{{362b:3806}}  (+&06)
        ld      a,c               ;{{362d:79}} 
        or      a                 ;{{362e:b7}} 
        jr      nz,_real_division_33;{{362f:2008}}  (+&08)
        jr      _real_division_52 ;{{3631:1833}}  (+&33)

_real_division_29:                ;{{Addr=$3633 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{3633:0d}} 
        add     hl,hl             ;{{3634:29}} 
        rl      e                 ;{{3635:cb13}} 
        rl      d                 ;{{3637:cb12}} 
_real_division_33:                ;{{Addr=$3639 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ix+$04),c        ;{{3639:dd7104}} 
        call    _real_division_58 ;{{363c:cd7236}} 
        ld      (ix+$03),c        ;{{363f:dd7103}} 
        call    _real_division_58 ;{{3642:cd7236}} 
        ld      (ix+$02),c        ;{{3645:dd7102}} 
        call    _real_division_58 ;{{3648:cd7236}} 
        ld      (ix+$01),c        ;{{364b:dd7101}} 
        call    _real_division_58 ;{{364e:cd7236}} 
        ccf                       ;{{3651:3f}} 
        call    c,_real_division_86;{{3652:dc9d36}} 
        ccf                       ;{{3655:3f}} 
        sbc     a,a               ;{{3656:9f}} 
        ld      l,c               ;{{3657:69}} 
        ld      h,(ix+$01)        ;{{3658:dd6601}} 
        ld      e,(ix+$02)        ;{{365b:dd5e02}} 
        ld      d,(ix+$03)        ;{{365e:dd5603}} 
        pop     bc                ;{{3661:c1}} 
        ld      c,a               ;{{3662:4f}} 
        jp      _process_real_at_hl_18;{{3663:c3b737}} 

_real_division_52:                ;{{Addr=$3666 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{3666:c1}} 
_real_division_53:                ;{{Addr=$3667 Code Calls/jump count: 1 Data use count: 0}}
        jp      REAL_at_IX_to_max_pos_or_max_neg;{{3667:c3ea37}} 

_real_division_54:                ;{{Addr=$366a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,(ix+$03)        ;{{366a:dd4603}} 
        call    REAL_at_IX_to_max_pos_or_max_neg;{{366d:cdea37}} 
        xor     a                 ;{{3670:af}} 
        ret                       ;{{3671:c9}} 

_real_division_58:                ;{{Addr=$3672 Code Calls/jump count: 4 Data use count: 0}}
        ld      c,$01             ;{{3672:0e01}} 
_real_division_59:                ;{{Addr=$3674 Code Calls/jump count: 1 Data use count: 0}}
        jr      c,_real_division_65;{{3674:3808}}  (+&08)
        ld      a,d               ;{{3676:7a}} 
        cp      b                 ;{{3677:b8}} 
        call    z,_real_division_89;{{3678:cca036}} 
        ccf                       ;{{367b:3f}} 
        jr      nc,_real_division_78;{{367c:3013}}  (+&13)
_real_division_65:                ;{{Addr=$367e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{367e:7d}} 
        sub     (iy+$00)          ;{{367f:fd9600}} 
        ld      l,a               ;{{3682:6f}} 
        ld      a,h               ;{{3683:7c}} 
        sbc     a,(iy+$01)        ;{{3684:fd9e01}} 
        ld      h,a               ;{{3687:67}} 
        ld      a,e               ;{{3688:7b}} 
        sbc     a,(iy+$02)        ;{{3689:fd9e02}} 
        ld      e,a               ;{{368c:5f}} 
        ld      a,d               ;{{368d:7a}} 
        sbc     a,b               ;{{368e:98}} 
        ld      d,a               ;{{368f:57}} 
        scf                       ;{{3690:37}} 
_real_division_78:                ;{{Addr=$3691 Code Calls/jump count: 1 Data use count: 0}}
        rl      c                 ;{{3691:cb11}} 
        sbc     a,a               ;{{3693:9f}} 
        add     hl,hl             ;{{3694:29}} 
        rl      e                 ;{{3695:cb13}} 
        rl      d                 ;{{3697:cb12}} 
        inc     a                 ;{{3699:3c}} 
        jr      nz,_real_division_59;{{369a:20d8}}  (-&28)
        ret                       ;{{369c:c9}} 

_real_division_86:                ;{{Addr=$369d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{369d:7a}} 
        cp      b                 ;{{369e:b8}} 
        ret     nz                ;{{369f:c0}} 

_real_division_89:                ;{{Addr=$36a0 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{36a0:7b}} 
        cp      (iy+$02)          ;{{36a1:fdbe02}} 
        ret     nz                ;{{36a4:c0}} 

        ld      a,h               ;{{36a5:7c}} 
        cp      (iy+$01)          ;{{36a6:fdbe01}} 
        ret     nz                ;{{36a9:c0}} 

        ld      a,l               ;{{36aa:7d}} 
        cp      (iy+$00)          ;{{36ab:fdbe00}} 
        ret                       ;{{36ae:c9}} 

_real_division_98:                ;{{Addr=$36af Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{36af:4f}} 
        ld      a,(ix+$03)        ;{{36b0:dd7e03}} 
        xor     (iy+$03)          ;{{36b3:fdae03}} 
        ld      b,a               ;{{36b6:47}} 
        ld      a,(ix+$04)        ;{{36b7:dd7e04}} 
        or      a                 ;{{36ba:b7}} 
        ret     z                 ;{{36bb:c8}} 

        add     a,c               ;{{36bc:81}} 
        ld      c,a               ;{{36bd:4f}} 
        rra                       ;{{36be:1f}} 
        xor     c                 ;{{36bf:a9}} 
        ld      a,c               ;{{36c0:79}} 
        jp      p,_real_division_117;{{36c1:f2cf36}} 
        set     7,(ix+$03)        ;{{36c4:ddcb03fe}} 
        sub     $7f               ;{{36c8:d67f}} 
        scf                       ;{{36ca:37}} 
        ret     nz                ;{{36cb:c0}} 

        cp      $01               ;{{36cc:fe01}} 
        ret                       ;{{36ce:c9}} 

_real_division_117:               ;{{Addr=$36cf Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{36cf:b7}} 
        ret     m                 ;{{36d0:f8}} 

        xor     a                 ;{{36d1:af}} 
        ret                       ;{{36d2:c9}} 

_real_division_121:               ;{{Addr=$36d3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{36d3:e5}} 
        pop     ix                ;{{36d4:dde1}} 
        ld      a,(ix+$04)        ;{{36d6:dd7e04}} 
        or      a                 ;{{36d9:b7}} 
        ret     z                 ;{{36da:c8}} 

        sub     $80               ;{{36db:d680}} 
        scf                       ;{{36dd:37}} 
        ret                       ;{{36de:c9}} 

;;============================================================================================
;; REAL compare

REAL_compare:                     ;{{Addr=$36df Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{36df:e5}} 
        pop     ix                ;{{36e0:dde1}} 
_real_compare_2:                  ;{{Addr=$36e2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{36e2:d5}} 
        pop     iy                ;{{36e3:fde1}} 
        ld      a,(ix+$04)        ;{{36e5:dd7e04}} 
        cp      (iy+$04)          ;{{36e8:fdbe04}} 
        jr      c,_real_compare_25;{{36eb:382c}}  (+&2c)
        jr      nz,_real_compare_32;{{36ed:2033}}  (+&33)
        or      a                 ;{{36ef:b7}} 
        ret     z                 ;{{36f0:c8}} 

        ld      a,(ix+$03)        ;{{36f1:dd7e03}} 
        xor     (iy+$03)          ;{{36f4:fdae03}} 
        jp      m,_real_compare_32;{{36f7:fa2237}} 
        ld      a,(ix+$03)        ;{{36fa:dd7e03}} 
        sub     (iy+$03)          ;{{36fd:fd9603}} 
        jr      nz,_real_compare_25;{{3700:2017}}  (+&17)
        ld      a,(ix+$02)        ;{{3702:dd7e02}} 
        sub     (iy+$02)          ;{{3705:fd9602}} 
        jr      nz,_real_compare_25;{{3708:200f}}  (+&0f)
        ld      a,(ix+$01)        ;{{370a:dd7e01}} 
        sub     (iy+$01)          ;{{370d:fd9601}} 
        jr      nz,_real_compare_25;{{3710:2007}}  (+&07)
        ld      a,(ix+$00)        ;{{3712:dd7e00}} 
        sub     (iy+$00)          ;{{3715:fd9600}} 
        ret     z                 ;{{3718:c8}} 

_real_compare_25:                 ;{{Addr=$3719 Code Calls/jump count: 4 Data use count: 0}}
        sbc     a,a               ;{{3719:9f}} 
        xor     (iy+$03)          ;{{371a:fdae03}} 
_real_compare_27:                 ;{{Addr=$371d Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{371d:87}} 
        sbc     a,a               ;{{371e:9f}} 
        ret     c                 ;{{371f:d8}} 

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
        ld      a,(ix+$04)        ;{{372a:dd7e04}} 
        or      a                 ;{{372d:b7}} 
        ret     z                 ;{{372e:c8}} 

        jr      _real_compare_32  ;{{372f:18f1}}  (-&0f)

;;============================================================================================
;; REAL Negate

REAL_Negate:                      ;{{Addr=$3731 Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{3731:e5}} 
        pop     ix                ;{{3732:dde1}} 
_real_negate_2:                   ;{{Addr=$3734 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,(ix+$03)        ;{{3734:dd7e03}} 
        xor     $80               ;{{3737:ee80}} 
        ld      (ix+$03),a        ;{{3739:dd7703}} 
        ret                       ;{{373c:c9}} 

;;============================================================================================
x373d_code:                       ;{{Addr=$373d Code Calls/jump count: 2 Data use count: 0}}
        cp      $21               ;{{373d:fe21}} 
        jr      c,x3743_code      ;{{373f:3802}}  (+&02)
        ld      a,$21             ;{{3741:3e21}} 
x3743_code:                       ;{{Addr=$3743 Code Calls/jump count: 2 Data use count: 0}}
        ld      e,(hl)            ;{{3743:5e}} 
        inc     hl                ;{{3744:23}} 
        ld      d,(hl)            ;{{3745:56}} 
        inc     hl                ;{{3746:23}} 
        ld      c,(hl)            ;{{3747:4e}} 
        inc     hl                ;{{3748:23}} 
        ld      h,(hl)            ;{{3749:66}} 
        ld      l,c               ;{{374a:69}} 
        ex      de,hl             ;{{374b:eb}} 
        set     7,d               ;{{374c:cbfa}} 
        ld      bc,$0000          ;{{374e:010000}} ##LIT##;WARNING: Code area used as literal
        jr      x375e_code        ;{{3751:180b}}  (+&0b)

x3753_code:                       ;{{Addr=$3753 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{3753:4f}} 
        ld      a,b               ;{{3754:78}} 
        or      l                 ;{{3755:b5}} 
        ld      b,a               ;{{3756:47}} 
        ld      a,c               ;{{3757:79}} 
        ld      c,l               ;{{3758:4d}} 
        ld      l,h               ;{{3759:6c}} 
        ld      h,e               ;{{375a:63}} 
        ld      e,d               ;{{375b:5a}} 
        ld      d,$00             ;{{375c:1600}} 
x375e_code:                       ;{{Addr=$375e Code Calls/jump count: 1 Data use count: 0}}
        sub     $08               ;{{375e:d608}} 
        jr      nc,x3753_code     ;{{3760:30f1}}  (-&0f)
        add     a,$08             ;{{3762:c608}} 
        ret     z                 ;{{3764:c8}} 

x3765_code:                       ;{{Addr=$3765 Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{3765:cb3a}} 
        rr      e                 ;{{3767:cb1b}} 
        rr      h                 ;{{3769:cb1c}} 
        rr      l                 ;{{376b:cb1d}} 
        rr      c                 ;{{376d:cb19}} 
        dec     a                 ;{{376f:3d}} 
        jr      nz,x3765_code     ;{{3770:20f3}}  (-&0d)
        ret                       ;{{3772:c9}} 

;;============================================================================================
x3773_code:                       ;{{Addr=$3773 Code Calls/jump count: 1 Data use count: 0}}
        jr      nz,x378c_code     ;{{3773:2017}}  (+&17)
        ld      d,a               ;{{3775:57}} 
        ld      a,e               ;{{3776:7b}} 
        or      h                 ;{{3777:b4}} 
        or      l                 ;{{3778:b5}} 
        or      c                 ;{{3779:b1}} 
        ret     z                 ;{{377a:c8}} 

        ld      a,d               ;{{377b:7a}} 
x377c_code:                       ;{{Addr=$377c Code Calls/jump count: 1 Data use count: 0}}
        sub     $08               ;{{377c:d608}} 
        jr      c,x379a_code      ;{{377e:381a}}  (+&1a)
        ret     z                 ;{{3780:c8}} 

        ld      d,e               ;{{3781:53}} 
        ld      e,h               ;{{3782:5c}} 
        ld      h,l               ;{{3783:65}} 
        ld      l,c               ;{{3784:69}} 
        ld      c,$00             ;{{3785:0e00}} 
        inc     d                 ;{{3787:14}} 
        dec     d                 ;{{3788:15}} 
        jr      z,x377c_code      ;{{3789:28f1}}  (-&0f)
        ret     m                 ;{{378b:f8}} 

x378c_code:                       ;{{Addr=$378c Code Calls/jump count: 2 Data use count: 0}}
        dec     a                 ;{{378c:3d}} 
        ret     z                 ;{{378d:c8}} 

        sla     c                 ;{{378e:cb21}} 
        adc     hl,hl             ;{{3790:ed6a}} 
        rl      e                 ;{{3792:cb13}} 
        rl      d                 ;{{3794:cb12}} 
        jp      p,x378c_code      ;{{3796:f28c37}} 
        ret                       ;{{3799:c9}} 

x379a_code:                       ;{{Addr=$379a Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{379a:af}} 
        ret                       ;{{379b:c9}} 

;;============================================
;;Process REAL at (HL)
Process_REAL_at_HL:               ;{{Addr=$379c Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{379c:e5}} 
        pop     ix                ;{{379d:dde1}} 
        ld      (ix+$04),b        ;{{379f:dd7004}} 
        ld      b,a               ;{{37a2:47}} 
        ld      e,(hl)            ;{{37a3:5e}} 
        inc     hl                ;{{37a4:23}} 
        ld      d,(hl)            ;{{37a5:56}} 
        inc     hl                ;{{37a6:23}} 
        ld      a,(hl)            ;{{37a7:7e}} 
        inc     hl                ;{{37a8:23}} 
        ld      h,(hl)            ;{{37a9:66}} 
        ld      l,a               ;{{37aa:6f}} 
        ex      de,hl             ;{{37ab:eb}} 
_process_real_at_hl_13:           ;{{Addr=$37ac Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(ix+$04)        ;{{37ac:dd7e04}} 
        dec     d                 ;{{37af:15}} 
        inc     d                 ;{{37b0:14}} 
        call    p,x3773_code      ;{{37b1:f47337}} 
        ld      (ix+$04),a        ;{{37b4:dd7704}} 
_process_real_at_hl_18:           ;{{Addr=$37b7 Code Calls/jump count: 4 Data use count: 0}}
        sla     c                 ;{{37b7:cb21}} 
        jr      nc,_process_real_at_hl_31;{{37b9:3012}}  (+&12)
        inc     l                 ;{{37bb:2c}} 
        jr      nz,_process_real_at_hl_31;{{37bc:200f}}  (+&0f)
        inc     h                 ;{{37be:24}} 
        jr      nz,_process_real_at_hl_31;{{37bf:200c}}  (+&0c)
        inc     de                ;{{37c1:13}} 
        ld      a,d               ;{{37c2:7a}} 
        or      e                 ;{{37c3:b3}} 
        jr      nz,_process_real_at_hl_31;{{37c4:2007}}  (+&07)
        inc     (ix+$04)          ;{{37c6:dd3404}} 
        jr      z,REAL_at_IX_to_max_pos_or_max_neg;{{37c9:281f}}  (+&1f)
        ld      d,$80             ;{{37cb:1680}} 
_process_real_at_hl_31:           ;{{Addr=$37cd Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{37cd:78}} 
        or      $7f               ;{{37ce:f67f}} 
        and     d                 ;{{37d0:a2}} 
        ld      (ix+$03),a        ;{{37d1:dd7703}} 
        ld      (ix+$02),e        ;{{37d4:dd7302}} 
        ld      (ix+$01),h        ;{{37d7:dd7401}} 
        ld      (ix+$00),l        ;{{37da:dd7500}} 
_process_real_at_hl_38:           ;{{Addr=$37dd Code Calls/jump count: 1 Data use count: 0}}
        push    ix                ;{{37dd:dde5}} 
        pop     hl                ;{{37df:e1}} 
        scf                       ;{{37e0:37}} 
        ret                       ;{{37e1:c9}} 

_process_real_at_hl_42:           ;{{Addr=$37e2 Code Calls/jump count: 5 Data use count: 0}}
        xor     a                 ;{{37e2:af}} 
        ld      (ix+$04),a        ;{{37e3:dd7704}} 
        jr      _process_real_at_hl_38;{{37e6:18f5}}  (-&0b)

;;============================================
;; REAL at IX to max pos
REAL_at_IX_to_max_pos:            ;{{Addr=$37e8 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$00             ;{{37e8:0600}} 

;;=REAL at IX to max pos or max neg
;;If B >= 0 store max positive real at (IX), otherwise max negative

REAL_at_IX_to_max_pos_or_max_neg: ;{{Addr=$37ea Code Calls/jump count: 6 Data use count: 0}}
        push    ix                ;{{37ea:dde5}} 
        pop     hl                ;{{37ec:e1}} 
        ld      a,b               ;{{37ed:78}} 
        or      $7f               ;{{37ee:f67f}} 
        ld      (ix+$03),a        ;{{37f0:dd7703}} 
        or      $ff               ;{{37f3:f6ff}} 
        ld      (ix+$04),a        ;{{37f5:dd7704}} 
        ld      (hl),a            ;{{37f8:77}} 
        ld      (ix+$01),a        ;{{37f9:dd7701}} 
        ld      (ix+$02),a        ;{{37fc:dd7702}} 
        ret                       ;{{37ff:c9}} 



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
