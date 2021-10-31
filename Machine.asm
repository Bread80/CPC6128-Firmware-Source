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





