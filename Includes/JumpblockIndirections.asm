;Jumblock symbols for the Amstrad CPC464/664/6128

;Auto-created from work by Dave Cantrell
;http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/

;Firmware indirections
;These are called by the firmware and can be patched to change standard behaviour
TXT_DRAW_CURSOR      EQU $BDCD
TXT_UNDRAW_CURSOR    EQU $BDD0
TXT_WRITE_CHAR       EQU $BDD3
TXT_UNWRITE          EQU $BDD6
TXT_OUT_ACTION       EQU $BDD9
GRA_PLOT             EQU $BDDC
GRA_TEST             EQU $BDDF
GRA_LINE             EQU $BDE2
SCR_READ             EQU $BDE5
SCR_WRITE            EQU $BDE8
SCR_MODE_CLEAR       EQU $BDEB
KM_TEST_BREAK        EQU $BDEE
MC_WAIT_PRINTER      EQU $BDF1
KM_SCAN_KEYS         EQU $BDF4
