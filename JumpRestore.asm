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




