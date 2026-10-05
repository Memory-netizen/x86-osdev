      mov ax, 3
      int 0x10 ; 设置显示模式为文本模式（清屏）

      xchg bx, bx
      jmp near start

message db '1+2+3+...+100='

start:
      mov ax, 0x7c0
      mov ds, ax
      xor ax, ax

      mov ss, ax
      mov sp, 0x7c00

      mov ax, 0xb800
      mov es, ax

      mov si, message
      mov di, 0
      mov cx, start - message
@g:
      mov al, [si]
      mov [es:di], al
      inc di
      mov byte [es:di], 0x07
      inc di
      inc si
      loop @g

      xor ax, ax
      mov cx, 100
@f:
      add ax, cx
      loop @f

      mov bx, 10
@d:
      inc cx
      xor dx, dx
      div bx
      or dl, 0x30
      push dx
      cmp ax, 0
      jne @d

show:
      pop dx
      mov [es:di], dl
      inc di
      mov byte [es:di], 0x07
      inc di
      loop show

      jmp $

 times 510 - ($ - $$) db 0
      db 0x55, 0xaa

