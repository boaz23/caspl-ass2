DEFAULT_STACK_SIZE EQU 5
MAX_LINE_LENGTH EQU 80

; SIGNATURE: func_entry(n)
;    n - locals size (in bytes)
; DESCRIPTION: Prepares the stack frame before executing the function

; esp -= n
%macro func_entry 0-1 0
    push ebp
    mov ebp, esp
    sub esp, %1
    pushfd
    pushad
%endmacro

; SIGNATURE: func_exit(p_ret_val = eax)
;   p_ret_val - A place to put function return value. default = eax
; DESCRIPTION: cleans stack frame before exiting the function (after function execution)
%macro func_exit 0-1 eax
    popad
    popfd
    mov eax, %1
    mov esp, ebp
    ret
%endmacro

; SIGNATURE: call_func(p_ret_val, func, ... args)
;   p_ret_val   - A place to put function return value
;   func        - the function to call
;   args        - list of arguments to pass to the function
; DESCRIPTION: calls the function <func> with args <args> and puts the return value in <p_ret_val>
; EXAMPLE:
;   call_func [r], fgets, ebx, MAX_LINE_LENGTH, [stdin]
;   the above is semantically equivalent to:
;       [r] = fgets(ebx, MAX_LINE_LENGTH, [stdin])
%macro call_func 2-*
    %rep %0-2
        %rotate -1
        push dword %1
    %endrep
    %rotate -1
    call %1
    %rotate -1
    mov %1, eax
    add esp, (%0-2)*4
%endmacro

; SIGNATURE: printf_line(format_str, ... args)
; DESCRIPTION: calls printf with format_str followed by new line and null terminator with the specified args
; EXAMPLE:
;   printf_line "%d", [r]
;   the above is semantically equivalent to:
;       printf("%d\n", [r])
%macro printf_line 1-*
    section	.rodata
        %%format: db %1, 10, 0
    section	.text
        %rep %0-1
            %rotate -1
            push dword %1
        %endrep
        push %%format
        call printf
        add esp, (%0-1)*4
%endmacro

section .rodata

section .bss
    NumberStack: resb 4

section .data
    DebugMode: db 0

section .text
    align 16
    global main
    extern printf
    extern fprintf
    extern fflush
    extern malloc
    extern calloc
    extern free
    extern gets
    extern getchar
    extern fgets

    extern stdin
    extern stdout
    extern stderr

main:
    %push
    %define buf ebp-MAX_LINE_LENGTH
    %define r ebp-MAX_LINE_LENGTH-4

    mov ebp, esp
    sub esp, MAX_LINE_LENGTH+4

    lea ebx, [buf]
    call_func [r], fgets, ebx, MAX_LINE_LENGTH, [stdin]
    call_func eax, printf, [r]
    printf_line "%d", [r]

    ; push dword [stdin]
    ; push dword MAX_LINE_LENGTH
    ; push dword ebx
    ; call fgets
    ; mov [ebp-MAX_LINE_LENGTH-4], eax
    ; add esp, 12

    ; lea ebx, [ebp-MAX_LINE_LENGTH]
    ; push dword ebx
    ; call printf
    ; add esp, 4

    mov esp, ebp

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop

    %pop

;------------------- class BigIntegerStack -------------------
%ifdef COMMENT
; class BigIntegerStack {
;     BigInteger[] numbers;
;     int capacity;
;     int sp;
; 
;     ctor(int capacity): BigIntegerStack*
;     push(BigStackInteger* s, BigInteger* n): void
;     pop(BigStackInteger* s): BigInteger*
;     hasAtLeastItems(BigStackInteger* s, int amount): boolean
;     isFull(BigStackInteger* s): boolean
; }
%endif

sizeof_BigIntegerStack EQU 12
%define BigIntegerStack_numbers(s) s+0
%define BigIntegerStack_capacity(s) s+4
%define BigIntegerStack_sp(s) s+8

BigIntegerStack_ctor: ; ctor(int capacity): BigInteger*
    %push
    %define capacity ebp+8

    %pop

BigIntegerStack_push: ; push(BigStackInteger* s, BigInteger* n): void
    %push
    %define s ebp+8
    %define n ebp+12

    %pop

BigIntegerStack_pop: ; pop(BigStackInteger* s): BigInteger*
    %push
    %define s ebp+8

    %pop


BigIntegerStack_hasAtLeastItems: ; hasAtLeastItems(BigStackInteger* s, int amount): boolean
    %push
    %define s ebp+8
    %define amount ebp+12

    %pop
    
BigIntegerStack_isFull: ; isFull(BigStackInteger* s): boolean
    %push
    %define s ebp+8

    %pop

;------------------- class ByteLink -------------------
%ifdef COMMENT
; class ByteLink {
;     byte b;
;     ByteLink* next;
; 
;     ctor(byte b, ByteLink* next): ByteLink*
;     freeList(ByteLink *list): void
;     addAtStart(ByteLink** list, byte b): void
;     padStartWithZeros(ByteLink* list, int count): void
; }
%endif

; NOTE: byte cannot be passed on the stack, we pass a DWORD (4 bytes) instead
sizeof_ByteLink EQU 5
%define ByteLink_b(bl) bl+0
%define ByteLink_next(bl) bl+1

ByteLink_ctor: ; ctor(byte b, ByteLink* next): ByteLink*
    %push
    %define b ebp+8
    %define next ebp+12

    %pop

ByteLink_freeList: ; freeList(ByteLink *list): void
    %push
    %define list ebp+8

    %pop

ByteLink_addAtStart: ; addAtStart(ByteLink** list, byte b): void
    %push
    %define list ebp+8
    %define b ebp+12

    %pop

ByteLink_padStartWithZeros: ; padStartWithZeros(ByteLink* list, int count): void
    %push
    %define list ebp+8
    %define count ebp+12

    %pop

;------------------- class BigInteger -------------------
%ifdef COMMENT
; class BigInteger {
;     ByteLink* list;
;     int hexDigitsLength;
; 
;     ctor(ByteLink* list, int hexDigitsLen): BigInteger*
;     duplicate(BigInteger* n): BigInteger*
;     free(BigInteger* n): void
; 
;     getHexDigitsLen(BigInteger* n): BigInteger*
;     
;     add(BigInteger* n1, BigInteger* n2): BigInteger*
;     and(BigInteger* n1, BigInteger* n2): BigInteger*
;     or(BigInteger* n1, BigInteger* n2): BigInteger*
;     multiply(BigInteger* n1, BigInteger* n2): BigInteger*
;
;     removeLeadingZeroes(BigInteger* n): void
;     print(BigInteger* n): void
; }
%endif

sizeof_BigInteger EQU 8
%define BigInteger_list(n) n+0
%define BigInteger_hexDigitsLength(n) n+4

BigInteger_ctor: ; ctor(ByteLink* list, int hexDigitsLen): BigInteger*
    %push
    %define list ebp+8
    %define hexDigitsLen ebp+12

    %pop

BigInteger_duplicate: ; duplicate(BigInteger* n): BigInteger*
    %push
    %define n ebp+8

    %pop

BigInteger_free: ; free(BigInteger* n): void
    %push
    %define n ebp+8

    %pop

BigInteger_getHexDigitsLen: ; getHexDigitsLen(BigInteger* n): BigInteger*
    %push
    %define n ebp+8

    %pop

BigInteger_add: ; add(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    %define n1 ebp+8
    %define n2 ebp+12

    %pop

BigInteger_and: ; and(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    %define n1 ebp+8
    %define n2 ebp+12

    %pop

BigInteger_or: ; or(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    %define n1 ebp+8
    %define n2 ebp+12

    %pop

BigInteger_multiply: ; multiply(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    %define n1 ebp+8
    %define n2 ebp+12

    %pop

BigInteger_removeLeadingZeroes: ; removeLeadingZeroes(BigInteger* n): void
    %push
    %define n ebp+8

    %pop

BigInteger_print: ; print(BigInteger* n): void
    %push
    %define n ebp+8

    %pop

;silly_swap: 
;
;    %push                       ; save the current context 
;    %stacksize small            ; tell NASM to use bp 
;    %assign %$localsize 0       ; see text for explanation 
;    %local old_ax:word, old_dx:word 
;
;        enter   %$localsize,0   ; see text for explanation 
;        mov     [old_ax],ax     ; swap ax & bx 
;        mov     [old_dx],dx     ; and swap dx & cx 
;        mov     ax,bx 
;        mov     dx,cx 
;        mov     bx,[old_ax] 
;        mov     cx,[old_dx] 
;        leave                   ; restore old bp 
;        ret                     ; 
;
;    %pop                        ; restore original context