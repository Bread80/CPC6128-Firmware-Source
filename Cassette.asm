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





