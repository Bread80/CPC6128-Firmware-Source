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






