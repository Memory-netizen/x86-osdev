CRT_ADDR_REG equ 0x03D4
CRT_DATA_REG equ 0x03D5

CRT_CURSOR_H equ 0X0E
CRT_CURSOR_L equ 0X0F

section header vstart=0
    program_len     dd program_end

    code_entry      dw start
                    dd section.code.start

    realloc_tbl_cnt dw (header_end - realloc_begin)/4

    realloc_begin:
    code_segment    dd section.code.start
    data_segment    dd section.data.start
    stack_segment   dd section.stack.start

header_end:

section code align=16 vstart=0
start:
      mov ax, 3
      int 0x10

      mov ax, [stack_segment]
      mov ss, ax
      mov sp, stack_end

      mov ax, [data_segment]
      mov ds, ax

      mov cx, msg_end - msg
      mov bx, msg

.putc:
      mov ah, 0x0e
      mov al, [bx]
      int 0x10
      inc bx
      loop .putc

.reps:
      mov ah, 0x00
      int 0x16

      mov ah, 0x0e
      mov bl, 0x07
      int 0x10

      jmp .reps

section data align=16 vstart=0
    msg   db 'Hello, friend!',0x0d,0x0a
          db 'This simple procedure used to demonstrate '
          db 'the BIOS interrupt.',0x0d,0x0a
          db 'Please press the keys on the keyboard ->'
    msg_end:

section stack align=16 vstart=0
        resb 256
stack_end:

section trail align=16
program_end:
