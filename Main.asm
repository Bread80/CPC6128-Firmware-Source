;#dialect=RASM

;'Unassembled'[1] Amstrad CPC6128 Source Code

;[1] 'Unassembled' meaning that this code can be modified and reassembled.
;(As far as I can tell) all links etc have been converted to labels etc in
;such a way that the code can be assembled at a different target address
;and still function correctly (excepting code which must run at a specific
;address).

;Based on the riginal commented disassembly at:
; http://cpctech.cpc-live.com/docs/os.asm

;There are two versions of this file: a single monolithic version and
;one which has been broken out into separate 'includes'. The latter may
;prove better for modification, assembly and re-use. The former for 
;exploration and reverse engineering.

;For more details see: https://github.com/Bread80/CPC6128-Firmware-Source
;and http://Bread80.com


;; KERNEL ROUTINES
include "LowJumpblock.asm"
include "Kernel.asm"

;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<END OF DATA COPIED TO HI JUMPBLOCK
include "HighJumpblock.asm"
include "Machine.asm"
include "JumpRestore.asm"
include "Screen.asm"
include "Text.asm"
include "Graphics.asm"
include "Keyboard.asm"
include "Sound.asm"
include "Cassette.asm"
include "LineEditor.asm"
include "FPMaths.asm"
include "Font.asm"
