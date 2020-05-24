NULL EQU 0

TRUE EQU 1
FALSE EQU 0

STK_UNIT EQU 4

DEFAULT_NUMBERS_STACK_SIZE EQU 5
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
        %if %0-1
            func_call eax, printf, %%format, %{2:-1}
        %else
            func_call eax, printf, %%format
        %endif
%endmacro

; SIGNATURE: mem_mov(r, m1, m2)
; DESCRIPTION: m1 = r = m2
; EXAMPLE: mem_mov ebx, [ebp-4], [ebp+8]
;   This will copy the value at the memory address ebp+8 to ebp-4
;   while using ebx as an intermediate place to store the result of [ebp+8]
; NOTES:
;   * This can be used to transfer from memory to memory
;     while specifying the intermediate register used
;     (but can also be used with any arbitrary combination of registers and memory)
;   * If used for transfer for memory to memory,
;     the register implicitly determines the operand's sizes
;   * Operand sizes can also be specified explicitly
%macro mem_mov 3
    mov %1, %3
    mov %2, %1
%endmacro

; SIGNATURE: mem_swap(r1, m1, r2, m2)
; DESCRIPTION:
;   Swaps the values in m1 and m2 using r1 and r2
;   as intermediate places to store m1 and m2 respectively
; EXAMPLE: mem_mov ebx, [ebp-4], [ebp+8]
;   This will copy the value at the memory address ebp+8 to ebp-4
;   while using ebx as an intermediate place to store the result of [ebp+8]
; NOTES:
;   * This can be used to swap the values in two memory locations
;     while specifying the intermediate registers used
;     (but can also be used with any arbitrary combination of registers and memory)
;   * If used for swapping the values in two memory locations,
;     the registers implicitly determines the operand's sizes
;   * Operand sizes can also be specified explicitly
%macro mem_swap 4
    mov %1, %2
    mov %3, %4
    mov %2, %3
    mov %4, %1
%endmacro

section .rodata

section .bss
    NumberStack: resb STK_UNIT

section .data
    DebugMode: db 0
    ;TODO NumbersStackCapacity: DEFAULT_NUMBERS_STACK_SIZE create error
    NumbersStackCapacity: EQU 5

section .text
    align 16
    global main_1

    global BigInteger_ctor
    global BigInteger_free
    global BigInteger_duplicate
    global BigInteger_getlistLen
    global BigInteger_add
    global BigInteger_removeLeadingZeroes
    global insertByteAsHexToStringR
    global reverse_hex_string
    global BigInteger_toString

    global ByteLink_ctor
    global ByteLink_addAtStart
    global ByteLink_freeList
    global ByteLink_duplicate

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

main_1: ; main(int argc, char *argv[], char *envp[]): int
    %push
    ; ----- arguments -----
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
;class BigIntegerStack {
;    BigInteger[] numbers;
;    int capacity;
;    int sp;
;
;    ctor(int capacity): BigIntegerStack*
;    push(BigStackInteger* s, BigInteger* n): void
;    pop(BigStackInteger* s): BigInteger*
;    hasAtLeastItems(BigStackInteger* s, int amount): boolean
;    isFull(BigStackInteger* s): boolean
;}
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
;class ByteLink {
;    byte b;
;    ByteLink* next;
;    
;    ctor(byte b, ByteLink* next): ByteLink*
;    freeList(ByteLink *list): void
;    duplicate(ByteLink *list): ByteLink*
;    addAtStart(ByteLink** list, byte b): void
;    ByteLink_addAsNext(ByteLink *link, byte b): ByteLink*
;}
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
    mem_mov bl, byte [ByteLink_b(eax)], byte [$b]
    
    ; b_link->next = next;
    mem_mov ebx, [ByteLink_next(eax)], [$next]

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
    mem_mov eax, [$current], [$list]

    ; while (current)
    .traverse_list_loop:
        ; if (current == NULL) { break; }
        cmp dword [$current], NULL
        je .traverse_list_loop_end

        ; next = current->next;
        mov eax, dword [$current]
        mem_mov eax, [$next], [ByteLink_next(eax)]

        ; free(current);
        func_call eax, free, [$current]

        ; current = next;
        mem_mov eax, [$current], [$next]
        jmp .traverse_list_loop
    .traverse_list_loop_end:

    func_exit
    %pop

ByteLink_duplicate: ; duplicate(ByteLink *list): ByteLink*
    %push
    ; ----- arguments -----
    %define $list ebp+8
    ; ----- locals -----
    %define $duplist ebp-4
    %define $current ebp-8
    %define $next ebp-12
    %define $duplistCurrent ebp-16
    ; ----- body ------
    func_entry 16

    mov eax, 0
    mov ebx, [$list]
    mov al, byte [ByteLink_b(ebx)] 

    ; dupist = ByteLink_ctor(list->b, NULL)
    func_call [$duplist], ByteLink_ctor, eax, NULL

    ; duplistCurrent = duplist
    mem_mov ecx, [$duplistCurrent], [$duplist]

    ; current = list-> next
    mem_mov ecx, [$current], [$list]
    mov eax, dword [$current]
    mem_mov eax, [$current], [ByteLink_next(eax)]

    .dup_loop_start:
        ;if(current == NULL) jmp to dup_loop_end
        cmp dword [$current], NULL
        je .dup_loop_end

        ; next = ByteLink_ctor(current->b, NULL)
        mov eax, 0
        mov ebx, [$current]
        mov al, byte [ByteLink_b(ebx)]
        func_call [$next], ByteLink_ctor, eax, NULL

        ;duplistCurrent->next = next
        mov ebx, [$duplistCurrent]
        mem_mov ecx, [ByteLink_next(ebx)], [$next]

        ;duplistCurrent = next
        mem_mov ecx, [$duplistCurrent], [$next]

        ;current = current->next
        mov ebx, dword [$current]
        mem_mov ecx, [$current], [ByteLink_next(ebx)]

        jmp .dup_loop_start
    .dup_loop_end:

    func_exit [$duplist]
    %pop

ByteLink_addAtStart: ; ByteLink_addAsNext(ByteLink** list, byte b): void
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
    mem_mov ebx, [eax], [$b_link]
    
    func_exit
    %pop

ByteLink_addAsNext: ; ByteLink_addAsNext(ByteLink *link, byte b): ByteLink*
    %push
    ; ----- arguments -----
    %define $link ebp+8
    %define $b ebp+12
    ; ----- locals -----
    %define $b_link ebp-4
    ; ----- body ------
    func_entry 4

    ;b_link = ByteLink_ctor(b, NULL)
    func_call [$b_link], ByteLink_ctor, [$b], NULL

    ;link->next = b_link
    mov eax, dword [$link]
    mem_mov ebx, [ByteLink_next(eax)], [$b_link]

    func_exit [$b_link]
    %pop

; assume there is a next, dont remove the start link
ByteLink_setPrevLinkNull: ; setPrevLinkNull(ByteLink* list, ByteLink* link): int
    %push
    ; ----- arguments -----
    %define $list ebp+8
    %define $link ebp+12
    ; ----- locals ------
    %define $current ebp-4
    %define $lenUpTo ebp-8
    ; ----- body ------
    func_entry 8

    ;current = list
    mem_mov eax, [$current], [$list]

    ;lenUpTo = 0
    mov dword [$lenUpTo], 0

    ;while(currnet != NULL)
    .set_null_loop_start:
        cmp dword [$current], 0
        je .set_null_loop_end

        ;lenUpTo = lenUpTo + 1
        inc dword [$lenUpTo]

        ;if(currnet->next == link)
        mov eax, dword [$current]
        mov eax, dword [ByteLink_next(eax)]
        mov ebx, dword [$link]
        ;TODO check jne
        cmp eax, ebx
        jne .set_next_current
            mov eax, [$current]
            mov dword [ByteLink_next(eax)], 0
            jmp .set_null_loop_end
    
    .set_next_current:
        mov eax, dword [$current]
        mem_mov eax, [$current], [ByteLink_next(eax)]
        jmp .set_null_loop_start

    .set_null_loop_end:

    func_exit [$lenUpTo]
    %pop

;------------------- class BigInteger -------------------
%ifdef COMMENT
;class BigInteger {
;    ByteLink* list;
;    int list_len;
;
;    ctor(ByteLink* list, int list_len): BigInteger*
;    duplicate(BigInteger* n): BigInteger*
;    free(BigInteger* n): void
;
;    parse(char *s): BigInterger*
;    calcHexDigitsInteger(BigInteger* n): BigInteger*
;    getByte(BigInteger* n): byte*
;   
;    add(BigInteger* n1, BigInteger* n2): BigInteger*
;    and(BigInteger* n1, BigInteger* n2): BigInteger*
;    or(BigInteger* n1, BigInteger* n2): BigInteger*
;    multiply(BigInteger* n1, BigInteger* n2): BigInteger*
;
;    removeLeadingZeroes(BigInteger* n): void
;    shiftLeft(BigInteger* n, int amount): void
;    toString(BigInteger* n): char*
;}}
%endif

sizeof_BigInteger EQU 8
%define BigInteger_list(n) n+0
%define BigInteger_list_len(n) n+4

BigInteger_ctor: ; ctor(ByteLink* list, int list_len): BigInteger*
    %push
    ; ----- arguments -----
    %define $list ebp+8
    %define $list_len ebp+12
    ; ----- locals ------
    %define $b_integer ebp-4
    ; ----- body ------
    func_entry 4

    ; eax = b_integer = malloc(sizeof(ByteLink));
    func_call [$b_integer], malloc, sizeof_BigInteger
    mov eax, dword [$b_integer]

    ;b_integer->list = list
    mem_mov ebx, [BigInteger_list(eax)], [$list]

    ;b_integer->list_len = list_len
    mem_mov ebx, [BigInteger_list_len(eax)], [$list_len]


    func_exit [$b_integer]
    %pop

BigInteger_duplicate: ; duplicate(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $b_integer ebp-4
    %define $list_len ebp-8
    %define $duplist ebp-12
    ; ----- body ------
    func_entry 12
    
    ;eax =  n->list
    mov eax, [$n]
    mov eax, [BigInteger_list(eax)]

    ;duplist = ByteLink_duplicate(n->list)
    func_call [$duplist], ByteLink_duplicate, eax
    
    ;list_len = n->list_len
    mov eax, [$n]
    mem_mov ebx, [$list_len], [BigInteger_list_len(eax)]
    
    ;b_integer = BigInteger_ctor(duplist, list_len)
    func_call [$b_integer], BigInteger_ctor, [$duplist], [$list_len]


    func_exit [$b_integer]
    %pop

BigInteger_free: ; free(BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------
    func_entry
    
    ; ByteLink_freeList(n->list)
    mov eax, dword [$n]
    mov ebx, [BigInteger_list(eax)]
    func_call eax, ByteLink_freeList, ebx

    ; free(n)
    func_call eax, free, [$n]

    func_exit
    %pop

BigInteger_parse: ; parse(char *s): BigInteger*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_calcHexDigitsInteger: ; calcHexDigitsInteger(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    ; ----- body ------
    func_entry

    func_exit
    %pop

BigInteger_getlistLen: ; getHexDigitsLen(BigInteger* n): int
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $len ebp-4
    ; ----- body ------
    func_entry 4

    mov ebx, dword [$n]
    mov eax, [BigInteger_list_len(ebx)]
    mov dword [$len], eax

    func_exit [$len]
    %pop

BigInteger_add: ; add(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    %define $Addedlist ebp-4
    %define $currentAddedLink ebp-8
    %define $currentShorter ebp-12
    %define $currentLonger ebp-16
    %define $saveflags ebp-20
    %define $resBigInt ebp-24
    %define $resLen ebp-28
    ; ----- body ------
    func_entry 28

    ;resLen = 0
    mov dword [$resLen], 0

    ;set currentShorter and currentLonger
    mov eax, [$n1]
    mov eax, dword [BigInteger_list_len(eax)]

    mov ebx, [$n2]
    mov ebx, dword [BigInteger_list_len(ebx)]

    cmp eax, ebx
    jl .set_n2_as_longer
        mov eax, dword [$n1]
        mem_mov ecx, [$currentLonger], [BigInteger_list(eax)]
        mov eax, dword [$n2]
        mem_mov ecx, [$currentShorter], [BigInteger_list(eax)]
        jmp .set_n1_as_longer_c
    .set_n2_as_longer:
        mov eax, dword [$n2]
        mem_mov ecx, [$currentLonger], [BigInteger_list(eax)]
        mov eax, dword [$n1]
        mem_mov ecx, [$currentShorter], [BigInteger_list(eax)]
    .set_n1_as_longer_c:

    mov dword [$saveflags], 0
    ;currentAddedLink = ByteLink_ctor(currentShorter.b + currentLonger.b, NULL)
    ; cl = currentShorter->b
    mov ecx, dword [$currentShorter]
    mov cl, byte [ByteLink_b(ecx)]

    ; bl = currentShorter->b
    mov ebx, dword [$currentLonger]
    mov bl, byte [ByteLink_b(ebx)]

    ; cl = cl + bl
    ; save flags
    add cl, bl
    lahf
    mov [$saveflags], ah
    func_call [$currentAddedLink], ByteLink_ctor, ecx, NULL
    mem_mov ecx, [$Addedlist], [$currentAddedLink]

    ;currents to next
    mov ecx, dword [$currentShorter]
    mem_mov ebx, [$currentShorter], [ByteLink_next(ecx)]

    mov ecx, dword [$currentLonger]
    mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]

    ;resLen = resLen + 1
    inc dword [$resLen]
    ;while(currentShorter != NULL)
    .add_with_short_loop_start:
        cmp dword [$currentShorter], 0
        je .add_with_short_loop_end

        ; cl = currentShorter->b
        mov ecx, dword [$currentShorter]
        mov cl, byte [ByteLink_b(ecx)]

        ; bl = currentShorter->b
        mov ebx, dword [$currentLonger]
        mov bl, byte [ByteLink_b(ebx)]

        ;restore status register flags
        mov ah, [$saveflags]
        sahf
        ;cl = cl + bl = currentShorter->b + currentShorter->b + carray
        adc cl, bl
        ;save flags
        lahf
        mov [$saveflags], ah

        ;currentAddedLink = ByteLink_AddAsLast(currentAddedLink, currentShorter.b add with carray currentLonger.b)
        func_call [$currentAddedLink], ByteLink_addAsNext, [$currentAddedLink], ecx

        ;currents to next
        mov ecx, dword [$currentShorter]
        mem_mov ebx, [$currentShorter], [ByteLink_next(ecx)]

        mov ecx, dword [$currentLonger]
        mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]
        jmp .add_with_short_loop_start

    .add_with_short_loop_end:

    ;while(currentLonger != NULL)
    .add_with_long_loop_start:
        cmp dword [$currentLonger], 0
        je .add_with_long_loop_end

        mov ecx, 0
        ; bl = currentShorter->b
        mov ebx, dword [$currentLonger]
        mov bl, byte [ByteLink_b(ebx)]

        ;restore status register flags
        mov ah, [$saveflags]
        sahf
        ;cl = cl + bl = currentShorter->b + currentShorter->b + carray
        adc cl, bl
        ;save flags
        lahf
        mov [$saveflags], ah

        ;resHexDgits = resHexDgits + 1
        inc dword [$resLen]

        ;currentAddedLink = ByteLink_AddAsLast(currentAddedLink, currentLonger.b add with carray 0)
        func_call [$currentAddedLink], ByteLink_addAsNext, [$currentAddedLink], ecx

        ;current longer next
        mov ecx, dword [$currentLonger]
        mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]
        jmp .add_with_long_loop_start

    .add_with_long_loop_end:

    ;Check if carray flag is set
    mov ah, [$saveflags]
    sahf
    jnc .add_build_BigInt
    ; if carray flag is set, add 1 to the list
    mov ecx, 1
    func_call [$currentAddedLink], ByteLink_addAsNext, [$currentAddedLink], ecx
    inc dword [$resLen]

    .add_build_BigInt:
    func_call [$resBigInt], BigInteger_ctor, [$Addedlist], [$resLen]

    func_exit [$resBigInt]
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
    %define $linkToRemove ebp-4
    %define $current ebp-8
    ; ----- body ------
    func_entry 8

    ;linkToRemove = NULL
    mov dword [$linkToRemove], NULL

    ;current = n->list
    mov eax, [$n]
    mem_mov eax, [$current], [BigInteger_list(eax)]

    ;if(current->next == NULL), the list have only one link, ret
    mov eax, [$current]
    mov eax, [ByteLink_next(eax)]
    cmp eax, 0
    je .func_ret
    
    ;while(current != NULL)
    .r_loop_start:
        cmp dword [$current], 0
        je .r_loop_end

        ;if(current->b == 0)
        mov ebx, 0
        mov eax , dword [$current]
        mov bl, byte [ByteLink_b(eax)]
        cmp ebx, 0
        jne .current_b_not_z
            ;if(linkToRemove == 0) set linkToRemove = current
            cmp dword [$linkToRemove], 0
            jne .set_current_next
                mem_mov eax, [$linkToRemove], [$current]
                jmp .set_current_next
        
        ;else set linkToRemove = 0
        .current_b_not_z:
            mov dword [$linkToRemove], 0
        
        .set_current_next:
            mov eax, dword [$current]
            mem_mov eax, [$current], [ByteLink_next(eax)]
            jmp .r_loop_start
    .r_loop_end:

    cmp dword [$linkToRemove], 0
    je .func_ret
        mov ebx, dword [$n]
        func_call eax, ByteLink_setPrevLinkNull, [BigInteger_list(ebx)], [$linkToRemove]
       
        ;set BigInt list len to the return value from ByteLink_setPrevLinkNull
        mov ebx, dword [$n]
        mem_mov ecx, [BigInteger_list_len(ebx)], eax

        func_call eax, ByteLink_freeList, [$linkToRemove]
    
    .func_ret:

    func_exit
    %pop

BigInteger_shiftLeft: ; shiftLeft(BigInteger* n, int amount): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    %define $amount ebp+12
    ; ----- locals ------
    ; ----- body ------

    %pop

BigInteger_toString: ; toString(BigInteger* n): char*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $str ebp-4
    %define $strSize ebp-8
    %define $list_len ebp-12
    %define $index ebp-16
    %define $tmpBigInt ebp-20
    %define $rs ebp-24
    ; ----- body ------
    func_entry 24

    ; strSize = BigInteger_getHexDigitsLen(n)*2 + 1
    ; str = calloc(strSize ,1)
    func_call [$list_len], BigInteger_getlistLen, [$n]
    mov ebx, dword [$list_len]
    shl ebx, 1
    mov dword [$strSize], ebx
    add ebx, 1
    mov eax, 1
    func_call [$str], calloc, ebx, eax

    ; tmpBigInt = *n
    mov ebx, dword [$n]
    mov eax, [ebx]
    mov dword [$tmpBigInt], eax

    ;while(index < strSize) write in str the hex in the link
    mov dword [$index], 0
    .set_str_start:
       
        mov ebx, dword [$tmpBigInt]
        ; ebx = ebx->b = n->list->b
        mov al, byte [ByteLink_b(ebx)]

        ;00001111
        mov ebx, 0
        mov bl, al
        and bl, 0x0F
        mov ecx, dword [$index]
        add ecx, dword [$str]
        func_call [$rs], insertByteAsHexToStringR, ecx ,ebx
        ; index = index + 1
        add dword [$index], 1
        mov ecx, dword [$index]

        mov ebx, 0
        mov bl, al
        and bl, 0xF0
        shr bl, 4
        mov ecx, dword [$index]
        add ecx, dword [$str]
        func_call [$rs], insertByteAsHexToStringR, ecx ,ebx

        ; index = index + 1
        add dword [$index], 1
        ; tmpBigInt = tmpBigInt->list->next
        mov eax, dword [$tmpBigInt]
        mem_mov ebx , dword [$tmpBigInt], dword [ByteLink_next(eax)]
        ; if(index < strSize) jmp to set_str_start
        mov ecx, dword [$index]
        mov ebx, dword [$strSize]
        cmp ecx, ebx
        jl .set_str_start

    .set_str_end:

    ;if(str[strSize] == '0') set it to null byte
    mov ebx, [$str]
    add ebx, [$strSize]
    sub ebx, 1
    mov al,  byte [ebx]
    cmp al, '0'
    jne .reverse_string
        mov byte [ebx], 0
        mov eax, dword [$strSize]
        dec eax
        mov dword [$strSize], eax
    .reverse_string:
        func_call [$rs], reverse_hex_string, [$str], [$strSize]

    func_exit [$str]
    %pop

insertByteAsHexToStringR: ;insertByteAsHexToStringR(char *str, byte b)
    %push
    ; ----- arguments -----
    %define $str ebp+8
    %define $b ebp+12
    ; ----- locals ------
    ; ----- body ------
    func_entry
    
    mov eax, 10
    mov ebx, dword [$b]
    cmp eax, ebx
    jle .letter
    .digit:
        add bl, 48
        jmp .str_set_byte
    .letter:
        sub bl, 10
        add bl, 65
    .str_set_byte:
        ; str[0] = ebx
        mov eax, dword [$str]
        mov byte [eax], bl

    func_exit
    %pop

reverse_hex_string: ;reverse_hex_string(char *str, int len)
    %push
    ; ----- arguments -----
    %define $str ebp+8
    %define $len ebp+12
    ; ----- locals ------
    %define $index ebp-4
    %define $saveR ebp-8
    ; ----- body ------
    func_entry 8

    mov edx, 0
    mov ecx, 0

	mov ebx, 0 ; i = 0
	; k = hex_len - 1
	mov eax, dword [$len]
	dec eax
	reverse_hex_string_loop: ; while (i < k)
		; condition check
		; if (eax < ebx) break;
        mov [$index], eax
		cmp eax, ebx
		jl reverse_hex_string_loop_end
		; body
		; swap(&str[i], &str[k])
        
        mov edx, dword [$str]
        mov byte dl,[edx + ebx]
        mov ecx, dword [$str]
        mov byte cl, [ecx + eax]

        mov eax, dword [$str]
        add eax, ebx
        mov byte [eax], cl

        mov eax, [$index]
        mov [$saveR], ebx
        mov ebx, dword [$str]
        add ebx, eax
        mov byte [ebx], dl
        mov ebx, [$saveR]

        ;;restore eax
        mov eax, [$index]
		; loop increment
		inc ebx
		dec eax
		jmp reverse_hex_string_loop
	reverse_hex_string_loop_end:

    func_exit
    %pop

;malloc size of hex digits * 2
;for each byteadd to end, add l hex to uper and u hex to l for example 1A 0001 1010 to A1 
;r string
;print
;1A BC -> A1 CB -> BC 1A