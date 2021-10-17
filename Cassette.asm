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





