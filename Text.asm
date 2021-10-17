;; TEXT ROUTINES
;;===========================================================================
;; TXT INITIALISE

TXT_INITIALISE:                   ;{{Addr=$1074 Code Calls/jump count: 1 Data use count: 1}}
        call    TXT_RESET         ;{{1074:cd8410}} ; TXT RESET
        xor     a                 ;{{1077:af}} 
        ld      (UDG_matrix_table_flag_),a;{{1078:3235b7}} 
        ld      hl,$0001          ;{{107B:210100}} ##LIT##;WARNING: Code area used as literal
        call    initialise_a_stream;{{107E:cd3911}} 
        jp      clear_txt_streams_area;{{1081:c39f10}} 

;;===========================================================================
;; TXT RESET

TXT_RESET:                        ;{{Addr=$1084 Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,_txt_reset_3   ;{{1084:218d10}} ; table used to initialise text vdu indirections
        call    initialise_firmware_indirections;{{1087:cdb40a}} ; initialise text vdu indirections
        jp      initialise_control_code_functions;{{108A:c36414}} ; initialise control code handler functions

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
        ld      a,$08             ;{{109F:3e08}} 
        ld      de,RAM_b6b6       ;{{10A1:11b6b6}} 
_clear_txt_streams_area_2:        ;{{Addr=$10a4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,Current_Stream_;{{10A4:2126b7}} 
        ld      bc,$000e          ;{{10A7:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{10AA:edb0}} 
        dec     a                 ;{{10AC:3d}} 
        jr      nz,_clear_txt_streams_area_2;{{10AD:20f5}}  (-&0b)
        ld      (current_stream_number),a;{{10AF:32b5b6}} 
        ret                       ;{{10B2:c9}} 

;;==================================================================================
;; clean up streams?
clean_up_streams:                 ;{{Addr=$10b3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_stream_number);{{10B3:3ab5b6}} 
        ld      c,a               ;{{10B6:4f}} 
        ld      b,$08             ;{{10B7:0608}} 

_clean_up_streams_3:              ;{{Addr=$10b9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10B9:78}} 
        dec     a                 ;{{10BA:3d}} 
        call    TXT_STR_SELECT    ;{{10BB:cde410}}  TXT STR SELECT
        call    TXT_UNDRAW_CURSOR ;{{10BE:cdd0bd}}  IND: TXT UNDRAW CURSOR
        call    TXT_GET_PAPER     ;{{10C1:cdc012}}  TXT GET PAPER
        ld      (current_PAPER_number_),a;{{10C4:3230b7}} 
        call    TXT_GET_PEN       ;{{10C7:cdba12}}  TXT GET PEN
        ld      (current_PEN_number_),a;{{10CA:322fb7}} 
        djnz    _clean_up_streams_3;{{10CD:10ea}}  (-&16)
        ld      a,c               ;{{10CF:79}} 
        ret                       ;{{10D0:c9}} 

;;==================================================================================
;; initialise txt streams
initialise_txt_streams:           ;{{Addr=$10d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{10D1:4f}} 
        ld      b,$08             ;{{10D2:0608}} 
_initialise_txt_streams_2:        ;{{Addr=$10d4 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{10D4:78}} 
        dec     a                 ;{{10D5:3d}} 
        call    TXT_STR_SELECT    ;{{10D6:cde410}}  TXT STR SELECT
        push    bc                ;{{10D9:c5}} 
        ld      hl,(current_PEN_number_);{{10DA:2a2fb7}} 
        call    initialise_a_stream;{{10DD:cd3911}} 
        pop     bc                ;{{10E0:c1}} 
        djnz    _initialise_txt_streams_2;{{10E1:10f1}}  (-&0f)
        ld      a,c               ;{{10E3:79}} 

;;==================================================================================
;; TXT STR SELECT
TXT_STR_SELECT:                   ;{{Addr=$10e4 Code Calls/jump count: 4 Data use count: 1}}
        and     $07               ;{{10E4:e607}} 
        ld      hl,current_stream_number;{{10E6:21b5b6}} 
        cp      (hl)              ;{{10E9:be}} 
        ret     z                 ;{{10EA:c8}} 

        push    bc                ;{{10EB:c5}} 
        push    de                ;{{10EC:d5}} 
        ld      c,(hl)            ;{{10ED:4e}} 
        ld      (hl),a            ;{{10EE:77}} 
        ld      b,a               ;{{10EF:47}} 
        ld      a,c               ;{{10F0:79}} 
        call    _txt_swap_streams_19;{{10F1:cd2611}} 
        call    _txt_swap_streams_14;{{10F4:cd1e11}} 
        ld      a,b               ;{{10F7:78}} 
        call    _txt_swap_streams_19;{{10F8:cd2611}} 
        ex      de,hl             ;{{10FB:eb}} 
        call    _txt_swap_streams_14;{{10FC:cd1e11}} 
        ld      a,c               ;{{10FF:79}} 
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
        ld      a,b               ;{{110B:78}} 
        ld      (current_stream_number),a;{{110C:32b5b6}} 
        call    _txt_swap_streams_19;{{110F:cd2611}} 
        push    de                ;{{1112:d5}} 
        ld      a,c               ;{{1113:79}} 
        call    _txt_swap_streams_19;{{1114:cd2611}} 
        pop     hl                ;{{1117:e1}} 
        call    _txt_swap_streams_14;{{1118:cd1e11}} 
        pop     af                ;{{111B:f1}} 
        jr      TXT_STR_SELECT    ;{{111C:18c6}}  (-&3a)
;;--------------------------------------------------------------
_txt_swap_streams_14:             ;{{Addr=$111e Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{111E:c5}} 
        ld      bc,$000e          ;{{111F:010e00}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{1122:edb0}} 
        pop     bc                ;{{1124:c1}} 
        ret                       ;{{1125:c9}} 

;;--------------------------------------------------------------
_txt_swap_streams_19:             ;{{Addr=$1126 Code Calls/jump count: 4 Data use count: 0}}
        and     $07               ;{{1126:e607}} 
        ld      e,a               ;{{1128:5f}} 
        add     a,a               ;{{1129:87}} 
        add     a,e               ;{{112A:83}} 
        add     a,a               ;{{112B:87}} 
        add     a,e               ;{{112C:83}} 
        add     a,a               ;{{112D:87}} 
        add     a,$b6             ;{{112E:c6b6}} 
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
        ld      a,$83             ;{{113A:3e83}} 
        ld      (cursor_flag_),a  ;{{113C:322eb7}} 
        ld      a,d               ;{{113F:7a}} 
        call    TXT_SET_PAPER     ;{{1140:cdab12}}  TXT SET PAPER
        ld      a,e               ;{{1143:7b}} 
        call    TXT_SET_PEN_      ;{{1144:cda612}}  TXT SET PEN
        xor     a                 ;{{1147:af}} 
        call    TXT_SET_GRAPHIC   ;{{1148:cda813}}  TXT SET GRAPHIC
        call    TXT_SET_BACK      ;{{114B:cd7b13}}  TXT SET BACK
        ld      hl,$0000          ;{{114E:210000}} ##LIT##;WARNING: Code area used as literal
        ld      de,$7f7f          ;{{1151:117f7f}} 
        call    TXT_WIN_ENABLE    ;{{1154:cd0812}}  TXT WIN ENABLE
        jp      TXT_VDU_ENABLE    ;{{1157:c35914}}  TXT VDU ENABLE

;;===========================================================================
;; TXT SET COLUMN

TXT_SET_COLUMN:                   ;{{Addr=$115a Code Calls/jump count: 1 Data use count: 1}}
        dec     a                 ;{{115A:3d}} 
        ld      hl,window_left_column_;{{115B:212ab7}} 
        add     a,(hl)            ;{{115E:86}} 
        ld      hl,(Current_Stream_);{{115F:2a26b7}} 
        ld      h,a               ;{{1162:67}} 
        jr      _txt_set_cursor_1 ;{{1163:180e}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; TXT SET ROW

TXT_SET_ROW:                      ;{{Addr=$1165 Code Calls/jump count: 0 Data use count: 1}}
        dec     a                 ;{{1165:3d}} 
        ld      hl,window_top_line_;{{1166:2129b7}} 
        add     a,(hl)            ;{{1169:86}} 
        ld      hl,(Current_Stream_);{{116A:2a26b7}} 
        ld      l,a               ;{{116D:6f}} 
        jr      _txt_set_cursor_1 ;{{116E:1803}} ; undraw cursor, set cursor position and draw it

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
        ld      hl,(Current_Stream_);{{117C:2a26b7}} 
        call    _txt_get_cursor_13;{{117F:cd9311}} 
        ld      a,(scroll_count)  ;{{1182:3a2db7}} 
        ret                       ;{{1185:c9}} 

;;----------------------------------------------------------------
_txt_get_cursor_4:                ;{{Addr=$1186 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_top_line_);{{1186:3a29b7}} 
        dec     a                 ;{{1189:3d}} 
        add     a,l               ;{{118A:85}} 
        ld      l,a               ;{{118B:6f}} 
        ld      a,(window_left_column_);{{118C:3a2ab7}} 
        dec     a                 ;{{118F:3d}} 
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
        ld      l,a               ;{{119A:6f}} 
        ld      a,(window_left_column_);{{119B:3a2ab7}} 
        sub     h                 ;{{119E:94}} 
        cpl                       ;{{119F:2f}} 
        inc     a                 ;{{11A0:3c}} 
        inc     a                 ;{{11A1:3c}} 
        ld      h,a               ;{{11A2:67}} 
        ret                       ;{{11A3:c9}} 

;;====================================================================
;; scroll window?
scroll_window:                    ;{{Addr=$11a4 Code Calls/jump count: 8 Data use count: 0}}
        call    TXT_UNDRAW_CURSOR ;{{11A4:cdd0bd}} ; IND: TXT UNDRAW CURSOR

;;--------------------------------------------------------------------
_scroll_window_1:                 ;{{Addr=$11a7 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(Current_Stream_);{{11A7:2a26b7}} 
        call    _txt_validate_6   ;{{11AA:cdd611}} 
        ld      (Current_Stream_),hl;{{11AD:2226b7}} 
        ret     c                 ;{{11B0:d8}} 

        push    hl                ;{{11B1:e5}} 
        ld      hl,scroll_count   ;{{11B2:212db7}} 
        ld      a,b               ;{{11B5:78}} 
        add     a,a               ;{{11B6:87}} 
        inc     a                 ;{{11B7:3c}} 
        add     a,(hl)            ;{{11B8:86}} 
        ld      (hl),a            ;{{11B9:77}} 
        call    TXT_GET_WINDOW    ;{{11BA:cd5212}} ; TXT GET WINDOW
        ld      a,(current_PAPER_number_);{{11BD:3a30b7}} 
        push    af                ;{{11C0:f5}} 
        call    c,SCR_SW_ROLL     ;{{11C1:dc440e}} ; SCR SW ROLL
        pop     af                ;{{11C4:f1}} 
        call    nc,SCR_HW_ROLL    ;{{11C5:d4000e}} ; SCR HW ROLL
        pop     hl                ;{{11C8:e1}} 
        ret                       ;{{11C9:c9}} 


;;===========================================================================
;; TXT VALIDATE

TXT_VALIDATE:                     ;{{Addr=$11ca Code Calls/jump count: 8 Data use count: 1}}
        call    _txt_get_cursor_4 ;{{11CA:cd8611}} 
        call    _txt_validate_6   ;{{11CD:cdd611}} 
        push    af                ;{{11D0:f5}} 
        call    _txt_get_cursor_13;{{11D1:cd9311}} 
        pop     af                ;{{11D4:f1}} 
        ret                       ;{{11D5:c9}} 
;;------------------------------------------------------------------
_txt_validate_6:                  ;{{Addr=$11d6 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(window_right_colwnn_);{{11D6:3a2cb7}} 
        cp      h                 ;{{11D9:bc}} 
        jp      p,_txt_validate_12;{{11DA:f2e211}} 
        ld      a,(window_left_column_);{{11DD:3a2ab7}} 
        ld      h,a               ;{{11E0:67}} 
        inc     l                 ;{{11E1:2c}} 
_txt_validate_12:                 ;{{Addr=$11e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_left_column_);{{11E2:3a2ab7}} 
        dec     a                 ;{{11E5:3d}} 
        cp      h                 ;{{11E6:bc}} 
        jp      m,_txt_validate_19;{{11E7:faef11}} 
        ld      a,(window_right_colwnn_);{{11EA:3a2cb7}} 
        ld      h,a               ;{{11ED:67}} 
        dec     l                 ;{{11EE:2d}} 
_txt_validate_19:                 ;{{Addr=$11ef Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(window_top_line_);{{11EF:3a29b7}} 
        dec     a                 ;{{11F2:3d}} 
        cp      l                 ;{{11F3:bd}} 
        jp      p,_txt_validate_31;{{11F4:f20212}} 
        ld      a,(window_bottom_line_);{{11F7:3a2bb7}} 
        cp      l                 ;{{11FA:bd}} 
        scf                       ;{{11FB:37}} 
        ret     p                 ;{{11FC:f0}} 

        ld      l,a               ;{{11FD:6f}} 
        ld      b,$ff             ;{{11FE:06ff}} 
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
        ld      a,h               ;{{120B:7c}} 
        call    _txt_win_enable_33;{{120C:cd4012}} 
        ld      h,a               ;{{120F:67}} 
        ld      a,d               ;{{1210:7a}} 
        call    _txt_win_enable_33;{{1211:cd4012}} 
        ld      d,a               ;{{1214:57}} 
        cp      h                 ;{{1215:bc}} 
        jr      nc,_txt_win_enable_11;{{1216:3002}}  (+&02)
        ld      d,h               ;{{1218:54}} 
        ld      h,a               ;{{1219:67}} 
_txt_win_enable_11:               ;{{Addr=$121a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,l               ;{{121A:7d}} 
        call    _txt_win_enable_40;{{121B:cd4912}} 
        ld      l,a               ;{{121E:6f}} 
        ld      a,e               ;{{121F:7b}} 
        call    _txt_win_enable_40;{{1220:cd4912}} 
        ld      e,a               ;{{1223:5f}} 
        cp      l                 ;{{1224:bd}} 
        jr      nc,_txt_win_enable_21;{{1225:3002}}  (+&02)
        ld      e,l               ;{{1227:5d}} 
        ld      l,a               ;{{1228:6f}} 
_txt_win_enable_21:               ;{{Addr=$1229 Code Calls/jump count: 1 Data use count: 0}}
        ld      (window_top_line_),hl;{{1229:2229b7}} 
        ld      (window_bottom_line_),de;{{122C:ed532bb7}} 
        ld      a,h               ;{{1230:7c}} 
        or      l                 ;{{1231:b5}} 
        jr      nz,_txt_win_enable_31;{{1232:2006}}  (+&06)
        ld      a,d               ;{{1234:7a}} 
        xor     b                 ;{{1235:a8}} 
        jr      nz,_txt_win_enable_31;{{1236:2002}}  (+&02)
        ld      a,e               ;{{1238:7b}} 
        xor     c                 ;{{1239:a9}} 
_txt_win_enable_31:               ;{{Addr=$123a Code Calls/jump count: 2 Data use count: 0}}
        ld      (RAM_b728),a      ;{{123A:3228b7}} 
        jp      _txt_set_cursor_1 ;{{123D:c37311}} ; undraw cursor, set cursor position and draw it

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
        jp      p,_txt_win_enable_43;{{124A:f24e12}} 
        xor     a                 ;{{124D:af}} 
_txt_win_enable_43:               ;{{Addr=$124e Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{124E:b9}} 
        ret     c                 ;{{124F:d8}} 

        ld      a,c               ;{{1250:79}} 
        ret                       ;{{1251:c9}} 

;;===========================================================================
;; TXT GET WINDOW

TXT_GET_WINDOW:                   ;{{Addr=$1252 Code Calls/jump count: 3 Data use count: 1}}
        ld      hl,(window_top_line_);{{1252:2a29b7}} 
        ld      de,(window_bottom_line_);{{1255:ed5b2bb7}} 
        ld      a,(RAM_b728)      ;{{1259:3a28b7}} 
        add     a,$ff             ;{{125C:c6ff}} 
        ret                       ;{{125E:c9}} 

;;===========================================================================
;; IND: TXT UNDRAW CURSOR
IND_TXT_UNDRAW_CURSOR:            ;{{Addr=$125f Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(cursor_flag_)  ;{{125F:3a2eb7}} 
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
        ld      bc,(current_PEN_number_);{{126B:ed4b2fb7}} 
        call    SCR_CHAR_INVERT   ;{{126F:cde50d}} ; SCR CHAR INVERT
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
        pop     af                ;{{127C:f1}} 
        ret                       ;{{127D:c9}} 

;;===========================================================================
;; TXT CUR OFF

TXT_CUR_OFF:                      ;{{Addr=$127e Code Calls/jump count: 2 Data use count: 1}}
        push    af                ;{{127E:f5}} 
        ld      a,$02             ;{{127F:3e02}} 
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
        pop     af                ;{{128C:f1}} 
        push    hl                ;{{128D:e5}} 
        ld      hl,cursor_flag_   ;{{128E:212eb7}} 
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
        call    TXT_UNDRAW_CURSOR ;{{129A:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{129D:f1}} 
        push    hl                ;{{129E:e5}} 
        ld      hl,cursor_flag_   ;{{129F:212eb7}} 
        or      (hl)              ;{{12A2:b6}} 
        ld      (hl),a            ;{{12A3:77}} 
        pop     hl                ;{{12A4:e1}} 
        ret                       ;{{12A5:c9}} 

;;===========================================================================
;; TXT SET PEN 
TXT_SET_PEN_:                     ;{{Addr=$12a6 Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PEN_number_;{{12A6:212fb7}} 
        jr      _txt_set_paper_1  ;{{12A9:1803}}  (+&03)

;;===========================================================================
;; TXT SET PAPER
TXT_SET_PAPER:                    ;{{Addr=$12ab Code Calls/jump count: 1 Data use count: 2}}
        ld      hl,current_PAPER_number_;{{12AB:2130b7}} 
;;---------------------------------------------------------------------------
_txt_set_paper_1:                 ;{{Addr=$12ae Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12AE:f5}} 
        call    TXT_UNDRAW_CURSOR ;{{12AF:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        pop     af                ;{{12B2:f1}} 
        call    SCR_INK_ENCODE    ;{{12B3:cd8e0c}} ; SCR INK ENCODE
        ld      (hl),a            ;{{12B6:77}} 
_txt_set_paper_6:                 ;{{Addr=$12b7 Code Calls/jump count: 1 Data use count: 0}}
        jp      TXT_DRAW_CURSOR   ;{{12B7:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; TXT GET PEN
TXT_GET_PEN:                      ;{{Addr=$12ba Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PEN_number_);{{12BA:3a2fb7}} 
        jp      SCR_INK_DECODE    ;{{12BD:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT GET PAPER
TXT_GET_PAPER:                    ;{{Addr=$12c0 Code Calls/jump count: 1 Data use count: 1}}
        ld      a,(current_PAPER_number_);{{12C0:3a30b7}} 
        jp      SCR_INK_DECODE    ;{{12C3:c3a70c}}  SCR INK DECODE

;;===========================================================================
;; TXT INVERSE
TXT_INVERSE:                      ;{{Addr=$12c6 Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{12C6:cdd0bd}} ; IND: TXT UNDRAW CURSOR
        ld      hl,(current_PEN_number_);{{12C9:2a2fb7}} 
        ld      a,h               ;{{12CC:7c}} 
        ld      h,l               ;{{12CD:65}} 
        ld      l,a               ;{{12CE:6f}} 
        ld      (current_PEN_number_),hl;{{12CF:222fb7}} 
        jr      _txt_set_paper_6  ;{{12D2:18e3}}  (-&1d)

;;===========================================================================
;; TXT GET MATRIX
TXT_GET_MATRIX:                   ;{{Addr=$12d4 Code Calls/jump count: 5 Data use count: 1}}
        push    de                ;{{12D4:d5}} 
        ld      e,a               ;{{12D5:5f}} 
        call    TXT_GET_M_TABLE   ;{{12D6:cd2b13}}  TXT GET M TABLE
        jr      nc,get_font_glyph_address;{{12D9:3009}}  get pointer to character graphics
        ld      d,a               ;{{12DB:57}} 
        ld      a,e               ;{{12DC:7b}} 
        sub     d                 ;{{12DD:92}} 
        ccf                       ;{{12DE:3f}} 
        jr      nc,get_font_glyph_address;{{12DF:3003}}  get pointer to character graphics
        ld      e,a               ;{{12E1:5f}} 
        jr      _get_font_glyph_address_1;{{12E2:1803}}  (+&03)

;;=============================================================
;; get font glyph address
;;
;; Entry conditions:
;; A = character code
;; Exit conditions:
;; HL = pointer to graphics for character

get_font_glyph_address:           ;{{Addr=$12e4 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,Font_graphics  ;{{12E4:210038}}  font graphics
_get_font_glyph_address_1:        ;{{Addr=$12e7 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{12E7:f5}} 
        ld      d,$00             ;{{12E8:1600}} 
        ex      de,hl             ;{{12EA:eb}} 
        add     hl,hl             ;{{12EB:29}}  x2
        add     hl,hl             ;{{12EC:29}}  x4
        add     hl,hl             ;{{12ED:29}}  x8
        add     hl,de             ;{{12EE:19}} 
        pop     af                ;{{12EF:f1}} 
        pop     de                ;{{12F0:d1}} 
        ret                       ;{{12F1:c9}} 

;;===========================================================================
;; TXT SET MATRIX
TXT_SET_MATRIX:                   ;{{Addr=$12f2 Code Calls/jump count: 1 Data use count: 1}}
        ex      de,hl             ;{{12F2:eb}} 
        call    TXT_GET_MATRIX    ;{{12F3:cdd412}}  TXT GET MATRIX
        ret     nc                ;{{12F6:d0}} 

        ex      de,hl             ;{{12F7:eb}} 

;;---------------------------------------------------------------------------
_txt_set_matrix_4:                ;{{Addr=$12f8 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0008          ;{{12F8:010800}} ##LIT##;WARNING: Code area used as literal
        ldir                      ;{{12FB:edb0}} 
        ret                       ;{{12FD:c9}} 

;;===========================================================================
;; TXT SET M TABLE
TXT_SET_M_TABLE:                  ;{{Addr=$12fe Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{12FE:e5}} 
        ld      a,d               ;{{12FF:7a}} 
        or      a                 ;{{1300:b7}} 
        ld      d,$00             ;{{1301:1600}} 
        jr      nz,_txt_set_m_table_23;{{1303:2019}}  (+&19)
        dec     d                 ;{{1305:15}} 
        push    de                ;{{1306:d5}} 
        ld      c,e               ;{{1307:4b}} 
        ex      de,hl             ;{{1308:eb}} 
_txt_set_m_table_9:               ;{{Addr=$1309 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{1309:79}} 
        call    TXT_GET_MATRIX    ;{{130A:cdd412}}  TXT GET MATRIX
        ld      a,h               ;{{130D:7c}} 
        xor     d                 ;{{130E:aa}} 
        jr      nz,_txt_set_m_table_17;{{130F:2004}}  (+&04)
        ld      a,l               ;{{1311:7d}} 
        xor     e                 ;{{1312:ab}} 
        jr      z,_txt_set_m_table_22;{{1313:2808}}  (+&08)
_txt_set_m_table_17:              ;{{Addr=$1315 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{1315:c5}} 
        call    _txt_set_matrix_4 ;{{1316:cdf812}} 
        pop     bc                ;{{1319:c1}} 
        inc     c                 ;{{131A:0c}} 
        jr      nz,_txt_set_m_table_9;{{131B:20ec}}  (-&14)
_txt_set_m_table_22:              ;{{Addr=$131d Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{131D:d1}} 
_txt_set_m_table_23:              ;{{Addr=$131e Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_M_TABLE   ;{{131E:cd2b13}}  TXT GET M TABLE
        ld      (ASCII_number_of_the_first_character_in_U),de;{{1321:ed5334b7}} 
        pop     de                ;{{1325:d1}} 
        ld      (address_of_UDG_matrix_table),de;{{1326:ed5336b7}} 
        ret                       ;{{132A:c9}} 

;;===========================================================================
;; TXT GET M TABLE
TXT_GET_M_TABLE:                  ;{{Addr=$132b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,(ASCII_number_of_the_first_character_in_U);{{132B:2a34b7}} 
        ld      a,h               ;{{132E:7c}} 
        rrca                      ;{{132F:0f}} 
        ld      a,l               ;{{1330:7d}} 
        ld      hl,(address_of_UDG_matrix_table);{{1331:2a36b7}} 
        ret                       ;{{1334:c9}} 

;;===========================================================================
;; TXT WR CHAR

TXT_WR_CHAR:                      ;{{Addr=$1335 Code Calls/jump count: 3 Data use count: 2}}
        ld      b,a               ;{{1335:47}} 
        ld      a,(cursor_flag_)  ;{{1336:3a2eb7}} 
        rlca                      ;{{1339:07}} 
        ret     c                 ;{{133A:d8}} 

        push    bc                ;{{133B:c5}} 
        call    scroll_window     ;{{133C:cda411}} 
        inc     h                 ;{{133F:24}} 
        ld      (Current_Stream_),hl;{{1340:2226b7}} 
        dec     h                 ;{{1343:25}} 
        pop     af                ;{{1344:f1}} 
        call    TXT_WRITE_CHAR    ;{{1345:cdd3bd}} ; IND: TXT WRITE CURSOR
        jp      TXT_DRAW_CURSOR   ;{{1348:c3cdbd}} ; IND: TXT DRAW CURSOR

;;===========================================================================
;; IND: TXT WRITE CHAR
IND_TXT_WRITE_CHAR:               ;{{Addr=$134b Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{134B:e5}} 
        call    TXT_GET_MATRIX    ;{{134C:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{134F:1138b7}} 
        push    de                ;{{1352:d5}} 
        call    SCR_UNPACK        ;{{1353:cdf90e}}  SCR UNPACK
        pop     de                ;{{1356:d1}} 
        pop     hl                ;{{1357:e1}} 
        call    SCR_CHAR_POSITION ;{{1358:cd6a0b}}  SCR CHAR POSITION
        ld      c,$08             ;{{135B:0e08}} 
_ind_txt_write_char_9:            ;{{Addr=$135d Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135D:c5}} 
        push    hl                ;{{135E:e5}} 
_ind_txt_write_char_11:           ;{{Addr=$135f Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{135F:c5}} 
        push    de                ;{{1360:d5}} 
        ex      de,hl             ;{{1361:eb}} 
        ld      c,(hl)            ;{{1362:4e}} 
        call    _ind_txt_write_char_27;{{1363:cd7713}} 
        call    SCR_NEXT_BYTE     ;{{1366:cd050c}}  SCR NEXT BYTE
        pop     de                ;{{1369:d1}} 
        inc     de                ;{{136A:13}} 
        pop     bc                ;{{136B:c1}} 
        djnz    _ind_txt_write_char_11;{{136C:10f1}}  (-&0f)
        pop     hl                ;{{136E:e1}} 
        call    SCR_NEXT_LINE     ;{{136F:cd1f0c}}  SCR NEXT LINE
        pop     bc                ;{{1372:c1}} 
        dec     c                 ;{{1373:0d}} 
        jr      nz,_ind_txt_write_char_9;{{1374:20e7}}  (-&19)
        ret                       ;{{1376:c9}} 

;;------------------------------------------------------------------
_ind_txt_write_char_27:           ;{{Addr=$1377 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_text_background_routine_opaq);{{1377:2a31b7}} 
        jp      (hl)              ;{{137A:e9}} 
;;===========================================================================
;; TXT SET BACK
TXT_SET_BACK:                     ;{{Addr=$137b Code Calls/jump count: 2 Data use count: 1}}
        ld      hl,write_opaque   ;{{137B:219213}} ##LABEL##
        or      a                 ;{{137E:b7}} 
        jr      z,_txt_set_back_4 ;{{137F:2803}}  (+&03)
        ld      hl,write_transparent;{{1381:21a013}} ##LABEL##
_txt_set_back_4:                  ;{{Addr=$1384 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_text_background_routine_opaq),hl;{{1384:2231b7}} 
        ret                       ;{{1387:c9}} 

;;===========================================================================
;; TXT GET BACK
TXT_GET_BACK:                     ;{{Addr=$1388 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_of_text_background_routine_opaq);{{1388:2a31b7}} 
        ld      de,$10000 - write_opaque;{{138B:116eec}} ;was &ec6e ##LABEL##
        add     hl,de             ;{{138E:19}} 
        ld      a,h               ;{{138F:7c}} 
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
        and     l                 ;{{139A:a5}} 
        or      b                 ;{{139B:b0}} 
        ld      c,$ff             ;{{139C:0eff}} 
        jr      _write_transparent_1;{{139E:1803}}  (+&03)

;;===========================================================================
;;write transparent
write_transparent:                ;{{Addr=$13a0 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(current_PEN_number_);{{13A0:3a2fb7}} 
;;---------------------------------------------------------------------------
_write_transparent_1:             ;{{Addr=$13a3 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{13A3:47}} 
        ex      de,hl             ;{{13A4:eb}} 
        jp      SCR_PIXELS        ;{{13A5:c3740c}}  SCR PIXELS

;;===========================================================================
;; TXT SET GRAPHIC

TXT_SET_GRAPHIC:                  ;{{Addr=$13a8 Code Calls/jump count: 1 Data use count: 1}}
        ld      (graphics_character_writing_flag_),a;{{13A8:3233b7}} 
        ret                       ;{{13AB:c9}} 

;;===========================================================================
;; TXT RD CHAR

TXT_RD_CHAR:                      ;{{Addr=$13ac Code Calls/jump count: 1 Data use count: 1}}
        push    hl                ;{{13AC:e5}} 
        push    de                ;{{13AD:d5}} 
        push    bc                ;{{13AE:c5}} 
        call    scroll_window     ;{{13AF:cda411}} 
        call    TXT_UNWRITE       ;{{13B2:cdd6bd}}  IND: TXT UNWRITE
        push    af                ;{{13B5:f5}} 
        call    TXT_DRAW_CURSOR   ;{{13B6:cdcdbd}}  IND: TXT DRAW CURSOR
        pop     af                ;{{13B9:f1}} 
        pop     bc                ;{{13BA:c1}} 
        pop     de                ;{{13BB:d1}} 
        pop     hl                ;{{13BC:e1}} 
        ret                       ;{{13BD:c9}} 

;;===========================================================================
;; IND: TXT UNWRITE

IND_TXT_UNWRITE:                  ;{{Addr=$13be Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{13BE:3a30b7}} 
        ld      de,RAM_b738       ;{{13C1:1138b7}} 
        push    hl                ;{{13C4:e5}} 
        push    de                ;{{13C5:d5}} 
        call    SCR_REPACK        ;{{13C6:cd2a0f}}  SCR REPACK
        pop     de                ;{{13C9:d1}} 
        push    de                ;{{13CA:d5}} 
        ld      b,$08             ;{{13CB:0608}} 
_ind_txt_unwrite_8:               ;{{Addr=$13cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13CD:1a}} 
        cpl                       ;{{13CE:2f}} 
        ld      (de),a            ;{{13CF:12}} 
        inc     de                ;{{13D0:13}} 
        djnz    _ind_txt_unwrite_8;{{13D1:10fa}}  (-&06)
        call    _ind_txt_unwrite_20;{{13D3:cde113}} 
        pop     de                ;{{13D6:d1}} 
        pop     hl                ;{{13D7:e1}} 
        jr      nc,_ind_txt_unwrite_18;{{13D8:3001}}  (+&01)
        ret     nz                ;{{13DA:c0}} 

_ind_txt_unwrite_18:              ;{{Addr=$13db Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_PEN_number_);{{13DB:3a2fb7}} 
        call    SCR_REPACK        ;{{13DE:cd2a0f}}  SCR REPACK
_ind_txt_unwrite_20:              ;{{Addr=$13e1 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$00             ;{{13E1:0e00}} 
_ind_txt_unwrite_21:              ;{{Addr=$13e3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{13E3:79}} 
        call    TXT_GET_MATRIX    ;{{13E4:cdd412}}  TXT GET MATRIX
        ld      de,RAM_b738       ;{{13E7:1138b7}} 
        ld      b,$08             ;{{13EA:0608}} 
_ind_txt_unwrite_25:              ;{{Addr=$13ec Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{13EC:1a}} 
        cp      (hl)              ;{{13ED:be}} 
        jr      nz,_ind_txt_unwrite_35;{{13EE:2009}}  (+&09)
        inc     hl                ;{{13F0:23}} 
        inc     de                ;{{13F1:13}} 
        djnz    _ind_txt_unwrite_25;{{13F2:10f8}}  (-&08)
        ld      a,c               ;{{13F4:79}} 
        cp      $8f               ;{{13F5:fe8f}} 
        scf                       ;{{13F7:37}} 
        ret                       ;{{13F8:c9}} 

_ind_txt_unwrite_35:              ;{{Addr=$13f9 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{13F9:0c}} 
        jr      nz,_ind_txt_unwrite_21;{{13FA:20e7}}  (-&19)
        xor     a                 ;{{13FC:af}} 
        ret                       ;{{13FD:c9}} 

;;===========================================================================
;; TXT OUTPUT

TXT_OUTPUT:                       ;{{Addr=$13fe Code Calls/jump count: 5 Data use count: 1}}
        push    af                ;{{13FE:f5}} 
        push    bc                ;{{13FF:c5}} 
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
        ld      c,a               ;{{140A:4f}} 
        ld      a,(graphics_character_writing_flag_);{{140B:3a33b7}} 
        or      a                 ;{{140E:b7}} 
        ld      a,c               ;{{140F:79}} 
        jp      nz,GRA_WR_CHAR    ;{{1410:c24019}}  GRA WR CHAR

        ld      hl,RAM_b758       ;{{1413:2158b7}} 
        ld      b,(hl)            ;{{1416:46}} 
        ld      a,b               ;{{1417:78}} 
        cp      $0a               ;{{1418:fe0a}} 
        jr      nc,_ind_txt_out_action_42;{{141A:3031}}  (+&31)
        or      a                 ;{{141C:b7}} 
        jr      nz,_ind_txt_out_action_15;{{141D:2006}}  (+&06)
        ld      a,c               ;{{141F:79}} 
        cp      $20               ;{{1420:fe20}} 
        jp      nc,TXT_WR_CHAR    ;{{1422:d23513}}  TXT WR CHAR
_ind_txt_out_action_15:           ;{{Addr=$1425 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{1425:04}} 
        ld      (hl),b            ;{{1426:70}} 
        ld      e,b               ;{{1427:58}} 
        ld      d,$00             ;{{1428:1600}} 
        add     hl,de             ;{{142A:19}} 
        ld      (hl),c            ;{{142B:71}} 


;; b759 = control code character
        ld      a,(RAM_b759)      ;{{142C:3a59b7}} 
        ld      e,a               ;{{142F:5f}} 

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
        ret     nc                ;{{143A:d0}} 

        ld      a,(cursor_flag_)  ;{{143B:3a2eb7}} 
        and     (hl)              ;{{143E:a6}} 
        rlca                      ;{{143F:07}} 
        jr      c,_ind_txt_out_action_42;{{1440:380b}}  (+&0b)

        inc     hl                ;{{1442:23}} 
        ld      e,(hl)            ;{{1443:5e}} ; function to execute
        inc     hl                ;{{1444:23}} 
        ld      d,(hl)            ;{{1445:56}} 
        ld      hl,RAM_b759       ;{{1446:2159b7}} 
        ld      a,c               ;{{1449:79}} 
        call    LOW_PCDE_INSTRUCTION;{{144A:cd1600}}  LOW: PCDE INSTRUCTION
_ind_txt_out_action_42:           ;{{Addr=$144d Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{144D:af}} 
        ld      (RAM_b758),a      ;{{144E:3258b7}} 
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
        call    _txt_cur_enable_1 ;{{145B:cd8812}} 
        jr      _ind_txt_out_action_42;{{145E:18ed}}  (-&13)

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
        ld      de,ASC_0_801513_NUL;{{146B:1163b7}} 
        ld      bc,$0060          ;{{146E:016000}} ##LIT##;WARNING: Code area used as literal
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
        ld      hl,ASC_0_801513_NUL;{{14D4:2163b7}} 
        ret                       ;{{14D7:c9}} 

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
        push    ix                ;{{14E1:dde5}} 
        ld      hl,data_for_control_character_BEL_sound;{{14E3:21d814}}  
        call    SOUND_QUEUE       ;{{14E6:cd1421}}  SOUND QUEUE
        pop     ix                ;{{14E9:dde1}} 

;;=============================================================================
;;performs control character 'ESC' function
performs_control_character_ESC_function:;{{Addr=$14eb Code Calls/jump count: 0 Data use count: 1}}
        ret                       ;{{14EB:c9}} 

;;=============================================================================
;; performs control character 'SYN' function
performs_control_character_SYN_function:;{{Addr=$14ec Code Calls/jump count: 0 Data use count: 1}}
        rrca                      ;{{14EC:0f}} 
        sbc     a,a               ;{{14ED:9f}} 
        jp      TXT_SET_BACK      ;{{14EE:c37b13}}  TXT SET BACK

;;=============================================================================
;; performs control character 'FS' function
performs_control_character_FS_function:;{{Addr=$14f1 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14F1:23}} 
        ld      a,(hl)            ;{{14F2:7e}}  pen number
        inc     hl                ;{{14F3:23}} 
        ld      b,(hl)            ;{{14F4:46}}  ink 1
        inc     hl                ;{{14F5:23}} 
        ld      c,(hl)            ;{{14F6:4e}}  ink 2
        jp      SCR_SET_INK       ;{{14F7:c3f20c}}  SCR SET INK

;;====================================================================
;; performs control character 'GS' instruction
performs_control_character_GS_instruction:;{{Addr=$14fa Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{14FA:23}} 
        ld      b,(hl)            ;{{14FB:46}}  ink 1
        inc     hl                ;{{14FC:23}} 
        ld      c,(hl)            ;{{14FD:4e}}  ink 2
        jp      SCR_SET_BORDER    ;{{14FE:c3f70c}}  SCR SET BORDER

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
        jp      TXT_WIN_ENABLE    ;{{150A:c30812}}  TXT WIN ENABLE

;;====================================================================
;; performs control character 'EM' function
performs_control_character_EM_function:;{{Addr=$150d Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{150D:23}} 
        ld      a,(hl)            ;{{150E:7e}}  character index
        inc     hl                ;{{150F:23}} 
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
        jr      _performs_control_character_vt_function_1;{{151C:180d}}  (+&0d)

;;====================================================================
;; performs control character 'TAB' function
performs_control_character_TAB_function:;{{Addr=$151e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$0100          ;{{151E:110001}} ##LIT##;WARNING: Code area used as literal
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
        push    de                ;{{152B:d5}} 
        call    scroll_window     ;{{152C:cda411}} 
        pop     de                ;{{152F:d1}} 

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
        jp      _txt_set_cursor_1 ;{{153C:c37311}} ; undraw cursor, set cursor position and draw it

;;===========================================================================
;; performs control character 'CR' function
performs_control_character_CR_function:;{{Addr=$153f Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{153F:cda411}} 
        ld      a,(window_left_column_);{{1542:3a2ab7}} 
        jr      _performs_control_character_vt_function_9;{{1545:18ee}}  (-&12)

;;===========================================================================
;; performs control character 'US' function
performs_control_character_US_function:;{{Addr=$1547 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{1547:23}} 
        ld      d,(hl)            ;{{1548:56}}  column
        inc     hl                ;{{1549:23}} 
        ld      e,(hl)            ;{{154A:5e}}  row
        ex      de,hl             ;{{154B:eb}} 
        jp      TXT_SET_CURSOR    ;{{154C:c37011}}  TXT SET CURSOR

;;===========================================================================
;; TXT CLEAR WINDOW

TXT_CLEAR_WINDOW:                 ;{{Addr=$154f Code Calls/jump count: 0 Data use count: 2}}
        call    TXT_UNDRAW_CURSOR ;{{154F:cdd0bd}}  IND: TXT UNDRAW CURSOR
        ld      hl,(window_top_line_);{{1552:2a29b7}} 
        ld      (Current_Stream_),hl;{{1555:2226b7}} 
        ld      de,(window_bottom_line_);{{1558:ed5b2bb7}} 
        jr      _performs_control_character_dc1_function_5;{{155C:1844}}  (+&44)

;;===========================================================================
;; performs control character 'DLE' function
performs_control_character_DLE_function:;{{Addr=$155e Code Calls/jump count: 0 Data use count: 1}}
        call    scroll_window     ;{{155E:cda411}} 
        ld      d,h               ;{{1561:54}} 
        ld      e,l               ;{{1562:5d}} 
        jr      _performs_control_character_dc1_function_5;{{1563:183d}}  (+&3d)

;;===========================================================================
;; performs control character 'DC4' function
performs_control_character_DC4_function:;{{Addr=$1565 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC2_function;{{1565:cd8f15}}  control character 'DC2'
        ld      hl,(window_top_line_);{{1568:2a29b7}} 
        ld      de,(window_bottom_line_);{{156B:ed5b2bb7}} 
        ld      a,(Current_Stream_);{{156F:3a26b7}} 
        ld      l,a               ;{{1572:6f}} 
        inc     l                 ;{{1573:2c}} 
        cp      e                 ;{{1574:bb}} 
        ret     nc                ;{{1575:d0}} 

        jr      _performs_control_character_dc3_function_9;{{1576:1811}}  (+&11)

;;===========================================================================
;; performs control character 'DC3' function
performs_control_character_DC3_function:;{{Addr=$1578 Code Calls/jump count: 0 Data use count: 1}}
        call    performs_control_character_DC1_function;{{1578:cd9915}}  control character 'DC1' function
        ld      hl,(window_top_line_);{{157B:2a29b7}} 
        ld      a,(window_right_colwnn_);{{157E:3a2cb7}} 
        ld      d,a               ;{{1581:57}} 
        ld      a,(Current_Stream_);{{1582:3a26b7}} 
        dec     a                 ;{{1585:3d}} 
        ld      e,a               ;{{1586:5f}} 
        cp      l                 ;{{1587:bd}} 
        ret     c                 ;{{1588:d8}} 

_performs_control_character_dc3_function_9:;{{Addr=$1589 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(current_PAPER_number_);{{1589:3a30b7}} 
        jp      SCR_FILL_BOX      ;{{158C:c3b90d}}  SCR FILL BOX

;;===========================================================================
;; performs control character 'DC2' function
performs_control_character_DC2_function:;{{Addr=$158f Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{158F:cda411}} 
        ld      e,l               ;{{1592:5d}} 
        ld      a,(window_right_colwnn_);{{1593:3a2cb7}} 
        ld      d,a               ;{{1596:57}} 
        jr      _performs_control_character_dc1_function_5;{{1597:1809}}  (+&09)

;;===========================================================================
;; performs control character 'DC1' function
performs_control_character_DC1_function:;{{Addr=$1599 Code Calls/jump count: 1 Data use count: 1}}
        call    scroll_window     ;{{1599:cda411}} 
        ex      de,hl             ;{{159C:eb}} 
        ld      l,e               ;{{159D:6b}} 
        ld      a,(window_left_column_);{{159E:3a2ab7}} 
        ld      h,a               ;{{15A1:67}} 

;;---------------------------------------------------------------------------
_performs_control_character_dc1_function_5:;{{Addr=$15a2 Code Calls/jump count: 3 Data use count: 0}}
        call    _performs_control_character_dc3_function_9;{{15A2:cd8915}} 
        jp      TXT_DRAW_CURSOR   ;{{15A5:c3cdbd}}  IND: TXT DRAW CURSOR




