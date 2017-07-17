# PlatformIO IDE Debugger

A debugging front-end for [PlatformIO IDE](http://platformio.org/platformio-ide)

## Features
* Provides access to GDB/CLI
* Show current position in editor
* Basic run control functions accessible from UI
* Display breakpoints in editor
* Inspect threads, call stacks and variables
* Set up a view of target variables
* Set watchpoints on target variables
* Assign new values to target variables

## Default key bindings (with GDB/CLI equivalents)
* `F5` Resume target execution (`continue`)
* `Shift-F5` Interrupt target execution (`Ctrl-C`/`interrupt`)
* `F9` Toggle breakpoint on current line in editor (`break`/`delete`)
* `F10` Single step, over function calls (`next`)
* `F11` Single step, into function calls (`step`)
* `Shift-F11` Resume until return  of current function (`finish`)

---
A fork of [gsmcmullin/atom-gdb-debugger](https://github.com/gsmcmullin/atom-gdb-debugger).
