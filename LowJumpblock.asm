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






