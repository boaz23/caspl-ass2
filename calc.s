NULL EQU 0

TRUE EQU 1
FALSE EQU 0

STK_UNIT EQU 4

DEFAULT_STACK_SIZE EQU 5
MAX_LINE_LENGTH EQU 80

; SIGNATURE: func_entry(n = 0)
;    n - locals size (in bytes). default is 0
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
;   p_ret_val - A place to put function return value. default is eax
; DESCRIPTION: cleans stack frame before exiting the function (after function execution)
%macro func_exit 0-1 eax
    popad
    popfd
    mov eax, %1
    mov esp, ebp
    pop ebp
    ret
%endmacro

; SIGNATURE: func_call(p_ret_val, func, ... args)
;   p_ret_val   - A place to put function return value
;   func        - the function to call
;   args        - list of arguments to pass to the function
; DESCRIPTION: calls the function <func> with args <args> and puts the return value in <p_ret_val>
; EXAMPLE:
;   func_call [r], fgets, ebx, MAX_LINE_LENGTH, [stdin]
;   the above is semantically equivalent to:
;       [r] = fgets(ebx, MAX_LINE_LENGTH, [stdin])
%macro func_call 2-*
    %rep %0-2
        %rotate -1
        push dword %1
    %endrep
    %rotate -1
    call %1
    %rotate -1
    mov %1, eax
    add esp, (%0-2)*STK_UNIT
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
        add esp, (%0-1)*STK_UNIT
%endmacro

section .rodata

section .bss
    NumberStack: resb STK_UNIT

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
    extern stderr

main: ; main(int argc, char *argv[], char *envp[]): int
    %push
    ; ----- arguments -----
    %define $capacity ebp+8
    ; ----- locals -----
    ; int operations_count;
    %define $operations_count ebp-4
    ; ----- body ------

    mov ebp, esp
    sub esp, 4
    
    func_call [$operations_count], myCalc
    printf_line "%X", [$operations_count]
    mov eax, [$operations_count]

    mov esp, ebp

    mov     ebx, eax
    mov     eax, 1
    int     0x80
    nop
    %pop

myCalc: ; myCalc(): int
    %push
    ; ----- arguments -----
    %define $capacity ebp+8
    ; ----- locals -----
    ; int operations_count;
    %define $operations_count ebp-4
    ; ----- body ------
    func_entry 4

    mov dword [$operations_count], 0

    func_exit [$operations_count]
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
    ; ----- arguments -----
    %define $capacity ebp+8
    ; ----- locals -----
    ; ----- body ------

    %pop

BigIntegerStack_push: ; push(BigStackInteger* s, BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $n ebp+12
    ; ----- locals -----
    ; ----- body ------

    %pop

BigIntegerStack_pop: ; pop(BigStackInteger* s): BigInteger*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    ; ----- body ------

    %pop


BigIntegerStack_hasAtLeastItems: ; hasAtLeastItems(BigStackInteger* s, int amount): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $amount ebp+12
    ; ----- locals -----
    ; ----- body ------

    %pop
    
BigIntegerStack_isFull: ; isFull(BigStackInteger* s): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    ; ----- body ------

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
; }
%endif

; NOTE: byte cannot be passed on the stack, we pass a DWORD (4 bytes) instead
sizeof_ByteLink EQU 5
%define ByteLink_b(bl) bl+0
%define ByteLink_next(bl) bl+1

ByteLink_ctor: ; ctor(byte b, ByteLink* next): ByteLink*
    %push
    ; ----- arguments -----
    %define $b ebp+8
    %define $next ebp+12
    ; ----- locals -----
    ; ByteLink* b_link
    %define $b_link ebp-4
    ; ----- body ------
    func_entry 4

    ; eax = b_link = malloc(sizeof(ByteLink));
    func_call [$b_link], malloc, sizeof_ByteLink
    mov eax, dword [$b_link]

    ; b_link->b = b;
    mov bl, byte [$b]
    mov byte [ByteLink_b(eax)], bl
    
    ; b_link->next = next;
    mov ebx, dword [$next]
    mov dword [ByteLink_next(eax)], ebx

    func_exit [$b_link]
    %pop

ByteLink_freeList: ; freeList(ByteLink *list): void
    %push
    ; ----- arguments -----
    %define $list ebp+8
    ; ----- locals -----
    ; ByteLink* current;
    %define $current ebp-4
    ; ByteLink* next;
    %define $next ebp-8
    ; ----- body ------
    func_entry 8

    ; current = list;
    mov eax, dword [$list]
    mov dword [$current], eax

    ; while (current)
    .traverse_list_loop:
        ; if (current == NULL) { break; }
        cmp dword [$current], NULL
        je .traverse_list_loop_end

        ; next = current->next;
        mov eax, dword [$current]
        mov eax, dword [ByteLink_next(eax)]
        mov dword [$next], eax

        ; free(current);
        func_call eax, free, [$current]

        ; current = next;
        mov eax, dword [$next]
        mov dword [$current], eax
        jmp .traverse_list_loop
    .traverse_list_loop_end:

    func_exit
    %pop

ByteLink_addAtStart: ; addAtStart(ByteLink** list, byte b): void
    %push
    ; ----- arguments -----
    %define $list ebp+8
    %define $b ebp+12
    ; ----- locals -----
    ; ByteLink* b_link
    %define $b_link ebp-4
    ; ----- body ------
    func_entry 4

    ; *list = ByteLink(b, *list);

    ; b_link = ByteLink(b, *list);
    mov eax, dword [$list]
    func_call [$b_link], ByteLink_ctor, [$b], [eax]

    ; *list = b_link;
    mov eax, dword [$list]
    mov ebx, dword [$b_link]
    mov dword [eax], ebx
    
    func_exit
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
;     shiftLeft(BigInteger* n, int amount): void
;     print(BigInteger* n): void
; }
%endif

sizeof_BigInteger EQU 8
%define BigInteger_list(n) n+0
%define BigInteger_hexDigitsLength(n) n+4

BigInteger_ctor: ; ctor(ByteLink* list, int hexDigitsLen): BigInteger*
    %push
    ; ----- arguments -----
    %define $list ebp+8
    %define $hexDigitsLen ebp+12
    ; ----- locals ------
    %define $b_integer ebp-4
    ; ----- body ------
    func_entry 4

    ; eax = b_integer = malloc(sizeof(ByteLink));
    func_call [$b_integer], malloc, sizeof_BigInteger
    mov eax, dword [$b_integer]

    ;b_integer->list = list
    mov ebx, dword [$list]
    mov dword [BigInteger_list(eax)], ebx

    ;b_integer->hexDigitsLen = hexDigitsLen
    mov ebx, dword [$hexDigitsLen]
    mov dword [BigInteger_hexDigitsLength(eax)], ebx

    func_exit [$b_link]
    %pop

BigInteger_duplicate: ; duplicate(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $b_integer ebp-4
    %define $hexDigitsLength ebp-8
    ; ----- body ------
    func_entry 8
    ;TODO
    %pop

BigInteger_free: ; free(BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------
    
    ; ByteLink_freeList(n->list)
    mov ebx, dword [$n]
    func_call, eax, ByteLink_freeList, BigInteger_list(ebx)

    ; free(n)
    func_call eax, free, [$n]

    %pop

BigInteger_getHexDigitsLen: ; getHexDigitsLen(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------
    mov eax, dword [$n]
    mov eax, [BigInteger_hexDigitsLength(eax)]

    %pop

BigInteger_add: ; add(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_and: ; and(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_or: ; or(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_multiply: ; multiply(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_removeLeadingZeroes: ; removeLeadingZeroes(BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_shiftLeft: ; shiftLeft(BigInteger* n, int amount): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    %define $amount ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_print: ; print(BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------

    %pop
