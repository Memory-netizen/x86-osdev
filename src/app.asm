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
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es

      mov al, 0x80
      out 0x70, al
      in al, 0x71
      push ax

      mov al, 0x82
      out 0x70, al
      in al, 0x71
      push ax

      mov al, 0x84
      out 0x70, al
      in al, 0x71
      push ax

      mov al, 0x0c
      out 0x70, al
      in al, 0x71

      mov ax, 0xb800
      mov es, ax

      mov bx, 12*160 + 36*2

      pop ax
      call bcd_to_ascii
      mov [es:bx], ah
      mov [es:bx+2], al

      mov [es:bx+4], ':'
      not [es:bx+5]

      pop ax
      call bcd_to_ascii
      mov [es:bx+6], ah
      mov [es:bx+8], al

      mov [es:bx+10], ':'
      not [es:bx+11]

      pop ax
      call bcd_to_ascii
      mov [es:bx+12], ah
      mov [es:bx+14], al

      mov al, 0x20
      out 0xa0, al
      out 0x20, al

      pop es
      pop dx
      pop cx
      pop bx
      pop ax
      iret

bcd_to_ascii:
    mov ah, al
    and al, 0x0f
    or al, 0x30

    shr ah, 4
    or ah, 0x30
    ret

put_str:
        mov cl, [bx]
        or cl, cl
        jz .exit
        call put_ch
        inc bx
        jmp put_str

    .exit:
        ret

put_ch:
        push ax
        push bx
        push cx
        push dx
        push ds
        push es

        call get_cursor
		    mov bx, ax

        cmp cl, 0x0d
        jnz .put_0a
        mov bl, 80
        div bl
        mul bl
        mov bx, ax
        jmp .put_ch_end

.put_0a:
        cmp cl, 0x0a
        jnz .put_other
        add bx, 80
        jmp .rool_screen

.put_other:
        mov ax, 0xb800
        mov es, ax
        shl bx, 1
        mov [es:bx], cl
        shr bx, 1
        inc bx

.rool_screen:
        cmp bx, 2000
        jl .put_ch_end

        push bx
        mov ax, 0xb800
        mov ds, ax
        mov es, ax
        cld
        mov si, 0xa0
        xor di, di
        mov cx, 1920
        rep movsw
        mov bx, 3840
        mov cx, 80
.cls:
        mov word [es:bx], 0x0720
        add bx, 2
        loop .cls

        pop bx
        sub bx, 80

.put_ch_end:
        call set_cursor

        pop es
        pop ds
        pop dx
        pop cx
        pop bx
        pop ax
        ret

get_cursor:                              ; 获取光标位置，返回值存储在 AX 寄存器中
        push dx

        mov dx, CRT_ADDR_REG
        mov al, CRT_CURSOR_H
        out dx, al

        mov dx, CRT_DATA_REG
        in al, dx
        shl ax, 8

        mov dx, CRT_ADDR_REG
        mov al, CRT_CURSOR_L
        out dx, al

        mov dx, CRT_DATA_REG
        in al, dx
		
        pop dx
        ret

set_cursor:                            ; 设置光标位置，参数用 BX 传递
        push dx

        mov dx, CRT_ADDR_REG
        mov al, CRT_CURSOR_L
        out dx, al

        mov dx, CRT_DATA_REG
        mov al, bl
        out dx, al

        mov dx, CRT_ADDR_REG
        mov al, CRT_CURSOR_H
        out dx, al

        mov dx, CRT_DATA_REG
        mov al, bh
        out dx, al

        pop dx
        ret

start:
      mov ax, 3
      int 0x10

      mov ax, [stack_segment]
      mov ss, ax
      mov sp, stack_end

      mov ax, [data_segment]
      mov ds, ax

      mov bx, init_msg
      call put_str

      mov bx, inst_msg
      call put_str

      mov al, 0x70
      mov bl, 4
      mul bl
      mov bx, ax

      cli

      push es
      xor ax, ax
      mov es, ax
      mov word [es:bx], new_int_0x70
      mov word [es:bx+2], cs
      pop es

      mov al, 0x8b
      out 0x70, al
      mov al, 0x12
      out 0x71, al

      mov al, 0x0c
      out 0x70, al
      in al, 0x71

      in al, 0xa1
      and al, 0xfe
      out 0xa1, al

      sti

      mov bx, done_msg
      call put_str

      mov bx, tips_msg
      call put_str

      mov cx, 0xb800
      mov ds, cx
      mov byte [12*160+33*2], '@'

.idle:
      hlt
      not byte [12*160+33*2+1]
      jmp .idle

section data align=16 vstart=0
    init_msg       db 'Starting...', 0x0d, 0x0a, 0
    inst_msg       db 'Installing a new interrupt 70H...', 0x0d, 0x0a, 0
    done_msg       db 'Done.', 0x0d,0x0a, 0
    tips_msg       db 'Clock is now working.', 0

section stack align=16 vstart=0
        resb 256
stack_end:

section trail align=16
program_end:
