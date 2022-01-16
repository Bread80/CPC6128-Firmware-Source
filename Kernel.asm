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




