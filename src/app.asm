CRT_ADDR_REG equ 0x03D4
CRT_DATA_REG equ 0x03D5

CRT_CURSOR_H equ 0X0E
CRT_CURSOR_L equ 0X0F

section header vstart=0
    program_len     dd program_end

    code_entry      dw start
                    dd section.code_1.start

    realloc_tbl_cnt dw (header_end - code_1_segment)/4

    code_1_segment  dd section.code_1.start
    code_2_segment  dd section.code_2.start
    data_1_segment  dd section.data_1.start
    data_2_segment  dd section.data_2.start
    stack_segment   dd section.stack.start

	header_end:

section code_1 align=16 vstart=0
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
        mov byte [es:bx+1], 0x07
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
        mov di, 0x00
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

      mov ax, [data_1_segment]
      mov ds, ax
	 

      mov bx, msg0
      call put_str

      push word [es:code_2_segment]
      mov ax, begin
      push ax

      retf

continue:
      mov ax, [es:data_2_segment]
      mov ds, ax

      mov bx, msg1
      call put_str

      jmp $

section code_2 align=16 vstart=0
    begin:
        push word [es:code_1_segment]
        mov ax, continue
        push ax

        retf

section data_1 align=16 vstart=0
        msg0 db 'Hello world!!!', 0x0d, 0x0a
             db 'Hello world!!!', 0x0d, 0x0a
             db 'Hello world!!!', 0x0d, 0x0a
             db 0

section data_2 align=16 vstart=0
        msg1 db 'This is a message from ye!'
             db 0

section stack align=16 vstart=0
        resb 256
stack_end:

section trail align=16
program_end:
