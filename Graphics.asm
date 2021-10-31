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






