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




