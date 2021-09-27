MoeCHIP-8 for C64
=================


C64 development
---------------

### File format: .prg

The .prg file format is very simple: the two first bytes contains an address
to where the rest of the file is to be loaded. It's common to use address
`$0801`, which is the default start address of the BASIC interpreter, and
start the file with a very small BASIC program that jumps to the machine
code program:

```basic
10 SYS 2304
```




Resources
---------

[Commodore 64 assembly coding on the command line](https://csl.name/post/c64-coding/)