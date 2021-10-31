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



