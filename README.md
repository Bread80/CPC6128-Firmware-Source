Amstrad CPC464/CPC664/CPC672/CPC6128 Firmware 'Unassembly'
===

This repository is the end result of a project to 'unassemble' the Amstrad CPC firmware. I use the word 'unassemble' to mean creating a version of the firmware source code which can be modified and reassembled. This differs from 'disassembly' in that 'unassembling' involves adding (meaningful) labels to the code and converting the targets of calls, jumps, loads etc to use those labels. It's impossible to verify that the end result is 100% semantically correct but I've taken numerous steps to try and ensure these listings are as correct as possible (including checking that it assembled to the exact same bytes). For more details of the 'unassembly' process see the About Unassembly section below.

This project builds on previous disassembly and reverse engineering work which can be found at http://cpctech.cpc-live.com/docs/os.asm

What's in This Repository
---
In the associated files you will find:
* 6128ROM.asm is the unassembled code as a single file
* Other asm files are the same but broken out into separate files to make exploration, modification and re-use easier. Main.asm is the .. erm ... main file which 'includes' all the others.
* 6128ROM.disasm is the 'marked up' disassembly which serves as the input to my unassembly utility (see below)
* Amstrad CPC 6128 OS (1985).rom is a ROM image taken from a CPC6128 and used to verify (diff) the output of the unassembly process.
* rasmoutput.bin is the output of running the source files (Main.asm or 6128ROM.asm) through the RASM assembler which should be identical to the original ROM image.
* The includes folder contains various include files needed to assemble the source code. This includes lists of firmware jumpblock addresses and memory addresses used by the code.

How to Use This Code
---
That's probably a stupid statement if you know Z80 assembly, but a few points may be useful to know:
* To reassemble start with the Main.asm file.
* To adapt the code to different hardware there's probably a fair few Amstrad specific routines that can be removed. And you may be tempted to remove those sections of the jumpblocks. However, if a program calls such a jumpblock which has not been initialised then the behaviour will not be what was expected. Instead I recommend leaving the jumpblocks intact and, instead, replacing the target code (in the relevant module) with a RETurn. You may also find it's beneficial to add code to such 'stubs' to set suitable return codes so the caller behaves in a consistent way. (I.e setting flags for success or failure, returning meaningful default register values etc).

Notes on the listings themselves:
* Labels are auto-created from the preceding comment (depending on the original markup). That usually creates a meaningful label but since punctuation can't be used in labels there's a compromise to be made between a meaningful comment and a meaningful label. Some such comments are also shortened for clarity.
* If there is no immediately preceding label then one is auto-generated from the preceding one. This is done by prefixing with an underscore (_) and appending an underscore and an index. The index relates to this code being the 'nth' line after the comment. Bear in mind that such labels may not exactly relate to the function of that piece of code, but the routine as a whole.
* There are some sections of code I've not yet reversed engineered. In which case a non-meaningful label will have been auto-generated beginning with an X and the four digit hex address of the original code.
* Comments at the end of each line of code include information in double curly braces {{..}}. This includes: the original address of that line in hex (if the code was assembled to run at a different address - e.g. the high jumpblock - there will be two addresses separated by a forward slash (/), the assembly address in ROM and the target address in RAM). After a colon (:) is the bytecode of that instruction from the original ROM.
* Labels are also followed by information in curly braces: The original address of the label in hex ('Addr=xxxx'); The word 'Code' or 'Data' depending on whether the utility has determined this is a code or data section; The number of times this label is referenced as the target of a CALL/JP/JR/DJNZ ('Calls/jump count'); The number of times this label is referenced as a piece or data, whether in a LD (etc) instruction or as ROM data (DEFW etc).
* The comments may have warnings if a code address is referenced as data or a data address/segment is the target of a CALL/JP etc.
* The comments may have directives to silence the above warnings or modify the parser behaviour. ##LIT## annotates the address in the instruction as a literal value, rather than an address. ##LABEL## annotates that the value in the instruction is a pointer to code, and should be replaced with a label, rather than a literal value.

If you want to add extra functionality you'll need some space for your code. The firmware occupies every available byte of the 16Kb ROM so you'll need a way to make some space. However, there are few parts which may not be needed these days, or which can be moved.

* I'd suggest the printer related code within the Machine Pack is a good candidate for removal.
* Depending on your tastes you may consider the cassette operating system surplus to requirements.
* If desperate you could free up a few bytes by removing the regional settings, 60Hz screen options, or even removing the sign on strings - you'll find all of those near the start of Machine.asm
* Finally, you could put your new code (or move existing code) into a separate ROM. I'd suggest the floating point routines are a good candidate for this as they're self contained and only called from BASIC. If doing so you'll need to include some startup code to install the jumpblocks, and you'll need to rewrite the jumpblock calls to use the appropriate RST code. (See below for pointers on how that stuff works).

How to build this code
---

You'll want to compile rasm, from https://github.com/EdouardBERGE/rasm .

Then you can use "rasm Main.asm" to generate the ROM image.

A Primer on the Amstrad Firmware
---
If you're not familiar with the Amstrad CPC firmware then this quick primer should get you started.

The firmware on the CPC is accessed via a set of 'jumpblocks'. These are a set of jumps copied to memory on startup. A call to a jumpblock does the necessary needed to enable the firmware ROM, call the actual routine, and reset everything for the return to the caller.

In the Amstrad world it is considered bad practice to call into the firmware directly, or to directly modify the firmware's reserved memory areas. Using the jumpblocks means that the firmware can be modified without breaking any third party code which uses it.

Some of the jumps are 'indirections'. These are jumps which the firmware itself calls to access some of it's own functionality. These indirections enable other software to patch and modify built in behaviour such as drawing pixels or scanning the keyboard.

The full list of firmware routines can be found in the JumpRestore.asm file. Documentation can be found in the file http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/firmware.pdf or by searching for 'Amstrad CPC Firmware Manual'.

Any of the entries in the jumpblocks can be 'patched' to change the way the standard routines operate (or to substitute completely different behaviour). All that is needed is to overwrite the existing jump with a jump of your own. In other words, you write a JP opcode followed by the target routine address (in standard Z80 little endian format). If doing so it's best practice to copy the previous jumpblock entry so it can be restored when your software exits. You will also need to copy the original jump if you want to call the firmware routine yourself after you've run your modified behaviour. When copying you *must* copy all three bytes - the jumpblock often uses RST instructions instead of JPs (see below).

Note, however, that some of the routines are undocumented. And the jumpblock entries for these *did*, sadly, change between versions of the CPC. These undocumented routines are used by the included BASIC ROM. If modifying the firmware you will need to use the appropriate ROM/jumpblock revision for the BASIC you are using. (The code included here is compatible with the BASIC 1.1 ROM - which is also the most recent official version).

The Low Jumpblock, High Jumpblock, RSTs and ROM banking
---
To understand the next section you'll need to understand the CPCs memory map and ROM/RAM banking structure. RAM in the CPC has a 'flat' structure from &0000 to &ffff. (The 6128 has 128Kb of RAM which can be mapped in various ways, but that doesn't affect us here). Screen RAM occupies the 16Kb of space between &c000 to &ffff. The firmware ROM (which contains routines that deal with the hardware) when enabled maps into the address range &0000 to &3fff - the first 16Kb of memory. The BASIC ROM, when enabled, maps into the same address space as the screen RAM (&c000 to &ffff). You can also install extra ROMs, such as the AMSDOS disc filing system, which will also be patched into the screen RAM address range.

The ROM at addresses &0000 to &3fff is known as the 'lower ROM'. The ROM at addresses &c000 to &ffff is known as the 'upper ROM'.

Any writes to memory *always* write to RAM, even if a ROM is enabled at that address. The ROM banking described above only affects memory reads.

The first &0040 bytes of memory are the 'low jumpblock' - see the file LowJumpblock.asm. These routines include the targets called by the Z80s RST instructions (see below) and other routines to perform low level operations which often involve bank switching of ROMs. The routines here include those which handle interrupts, enable a ROM and call an address within it (as used by the jumpblocks to call the firmware), or read a byte from RAM no matter what the ROM enable status.

If are routines were called when the lower ROM is disabled then the CPC will read from RAM and the call will fail. So, on startup, this code is copied to RAM (See Setup_kernel_jumpblocks in Kernel.asm) at the same address and the code will execute properly no matter what the ROM enable state.

Since much of this code handles enabling and disabling ROMs it needs to be able to run whether ROMs are enabled or not. To allow this a section of the firmware is copied to memory on startup. This section of code is known as the 'Hi Jumpblock' - see HighJumpblock.asm

The Z80 processor has a number of 'special' call instructions known as restarts (or RST nn). These are single byte opcodes which call a fixed address in memory (in the same way that a standard CALL instruction does) but intended to operate faster and save memory. The target addresses for RST instructions are all within the low jumpblock. The CPC uses a number of these RST instructions to call firmware functions within the low jumpblock. Some of these instructions take inline parameters - i.e. data in the bytes following the RST. E.g. to directly call a routine in the lower ROM you might code:

...
RST 5       ;FIRM JUMP - enable firmware ROM and call...
defb &1234  ;...address &1234
...         ;Code returns here and continues execution

Note how the inline data is consumed and stepped over by the firmware, with execution returning to the address after the data.

RSXs and ROM support
---
The firmware is very full featured and includes routines to access pretty much all of the hardware, and you can explore the documentation in your own time. However, there are a couple of features which are worth pointing out, especially now that it's easy to add extra ROMs to a computer either using an emulator or a physical ROM board.

The first feature is RSXs - Resident System eXtensions. Commonly referred to as 'bar commands'. This is a convenient way to add extra commands to a CPC to enhance BASIC, or any other software which supports them. In BASIC the commands  are prefixed with a bar character (|) (hence the common name). These are used, for example, by the disc system (if you have it installed) which adds commands such as |DIR to get a disc directory listing and |TAPE and |DISC to switch back and forward between the disc and cassette filing systems (which it does by patching the jumpblock routines - see above).

It's relatively easy to add RSX commands from machine code or, as hinted at above, from within a ROM. And the firmware automatically does a 'ROM walk' at startup to identify all installed ROMs, call their initialisation routines (if any) and log any RSX commands contained within. Adding commands is done with the KL_LOG_EXT routine and dispatching then uses KL_FIND_COMMAND. ROM setup, including add any commands within them, is handled transparently at startup but if you want to see the details look at KL_ROM_WALK and KL_INIT_BACK.

Full instructions for adding RSXs can be found on the internet, e.g. https://www.cpcwiki.eu/index.php/Programming:An_example_to_define_a_RSX

About 'Unassembly'
---

Disassembly listings of the CPC ROMs have been available for a while. However these listings are not suitable for being assembled or for being modified and assembled. To turn them into assemble-able source code a number of steps where necessary. A simple re-arrangement of the columns and adding labels isn't sufficient.

First of all, some areas are code and some are data. Disassembled data areas will contain jumps and calls. A simple reasssembly could result in the targets of these jumps being different. So it's necessary to find all data areas and turn them into DEFB, DEFW etc directives.

It's also necessary to identify memory addresses being used a constants in the code. Addresses in calls and jumps are, pretty obviously, jumps to code but data loads are harder to resolve. As an example, if we have a ROM for addresses $0000 to $3fff, and an instruction LD HL,$01FF the value $01FF could be a numeric constant but it could also be a reference to an address containing data. Or it could be the address of a subroutine to be called later (e.g. to be passed as a parameter into another routine). There are also situations where only the high or low byte of an address is loaded into a register. In order to be able to modify and reassemble the code it is necessary to find all such constants and determine which point to addresses and which are constants, and convert those to labels.

A lot of this work had already been done in the aforementioned disassembly listings, for which a huge amount of credit is given here.

As part of the project utility software was developed perform to certain steps to massively cut the workload. The project has also involved a large amount of manual work to determine the function of various areas of code and add comments, labels and tags.

As a summary of the work undertaken to get these source files:

* Rearrange the column order to move data such as the object code into the comments.

* Determine which addresses are used as the targets of calls, jumps and data loads (since we're talking ROMs here, data writes are obviously not targeting the code!)

* Add labels as targets for calls, jumps and data reads and also use those labels where they are referenced.

* Extract and parse comments to use as meaningful labels.

* Note calls and jumps which target data areas and references to data within code areas and mark such uses for manual checking (shown as WARNINGS in the output).

* Handle manually specified ##LABEL## and ##LIT## specifiers to clarify the use of constants and remove warnings.

* Assemble the output code and diff against original ROM data.

Licence
---
The object code in this repository is the copyright of Amstrad Consumer Electronics Plc and Locomotive Software Ltd.

This repository is built on the work of those who did the original disassembly and reverse engineering. I don't know the names of those individuals or their licensing terms.

My own work is covered by the Unlicence - https://opensource.org/licenses/unlicense
