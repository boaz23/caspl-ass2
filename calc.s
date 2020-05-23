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

section .data
    %ifdef TEST_C
    global DebugMode
    global NumberStack
    global NumbersStackCapacity
    %endif
    DebugMode: dd 0
    NumberStack: dd NULL
    NumbersStackCapacity: dd DEFAULT_NUMBERS_STACK_SIZE

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

%ifdef TEST_C
    global set_run_settings_from_args
    global is_arg_debug
    global try_parse_arg_hex_string_num
    global str_last_char
    
main_1:
%else
main: ; main(int argc, char *argv[], char *envp[]): int
%endif
    %push
    ; ----- arguments -----
    %define $argc ebp+8
    %define $argv ebp+12
    %define $envp ebp+16
    ; ----- locals -----
    ; int operations_count;
    %define $operations_count ebp-4
    ; ----- body ------
    func_entry 4

    func_call eax, set_run_settings_from_args, [$argc], [$argv]
    func_call [NumberStack], BigIntegerStack_ctor, [NumbersStackCapacity]
    
    func_call [$operations_count], myCalc
    printf_line "%X %d %d", [$operations_count], [DebugMode], [NumbersStackCapacity]

    func_call eax, free, [NumberStack]

    func_exit [$operations_count]
    %pop

; cmp_char(str, i, c, else)
; if (str[i] != c) goto else;
%macro cmp_char 4
    mov eax, %1
    mov bl, byte [eax+%2]
    cmp bl, %3
    jne %4
%endmacro

; cmp_char_in_range(c, c_start, c_end, then)
; if (c_start <= c && c <= c_end) goto then;
%macro cmp_char_in_range 4
    ; if (c_start < c) goto else;
    cmp %1, %2
    jl %%else
    ; if (c > c_end) goto else;
    cmp %1, %3
    jg %%else

    jmp %4 ; goto then;
    %%else:
%endmacro

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

set_run_settings_from_args: ; set_run_settings_from_args(int argc, char *argv[]): void
    %push
    ; ----- arguments -----
    %define $argc ebp+8
    %define $argv ebp+12
    ; ----- locals -----
    ; int i;
    ; char *arg;
    %define $i ebp-4
    %define $arg ebp-8
    %define $is_match ebp-12
    %define $stack_size ebp-16
    ; ----- body ------
    func_entry 16

    mov dword [$i], 1
    .args_loop: ; for(i = 1; i < argc; i++)
    ; if (i >= argc) break;
    mov eax, dword [$argc]
    cmp dword [$i], eax
    jge .args_loop_end
    
    ; arg = argv[i];
    mov eax, dword [$argv]
    mov ebx, dword [$i]
    mem_mov ecx, [$arg], [eax+4*ebx]

    .check_dbg:
    ; is_match = is_arg_dbg(arg);
    func_call [$is_match], is_arg_debug, [$arg]
    ; if (!is_match) goto check_stack_size;
    cmp dword [$is_match], FALSE
    je .check_stack_size
    ; DebugMode = TRUE;
    mov dword [DebugMode], TRUE
    ; continue;
    jmp .continue

    .check_stack_size:
        ; stack_size = try_parse_arg_hex_string_num(arg);
        func_call [$stack_size], try_parse_arg_hex_string_num, [$arg]
        ; if (stack_size < 0) continue; (invalid hex number)
        cmp dword [$stack_size], 0
        jl .continue
        
        ; NumbersStackCapacity = stack_size;
        mem_mov eax, [NumbersStackCapacity], [$stack_size]
        jmp .continue

    .continue:
    ; i++
    inc dword [$i]
    jmp .args_loop
    .args_loop_end:

    func_exit
    %pop

is_arg_debug: ; is_arg_debug(char *arg): boolean
    %push
    ; ----- arguments -----
    %define $arg ebp+8
    ; ----- locals -----
    ; boolean is_dbg
    %define $is_dbg ebp-4
    ; ----- body ------
    func_entry 4

    ; is_dbg = false;
    mov dword [$is_dbg], FALSE

    cmp_char dword [$arg], 0, '-', .exit    ; if (arg[0] != '-')  goto exit;
    cmp_char dword [$arg], 1, 'd', .exit    ; if (arg[1] != 'd')  goto exit;
    cmp_char dword [$arg], 2, 0,   .exit    ; if (arg[2] != '\0') goto exit;

    ; is_dbg = true;
    mov dword [$is_dbg], TRUE

    .exit:
    func_exit [$is_dbg]
    %pop

try_parse_arg_hex_string_num: ; try_parse_arg_hex_string_num(char *arg): int
    %push
    ; ----- arguments -----
    %define $arg ebp+8
    ; ----- locals -----
    ; boolean is_hex_num
    %define $num ebp-4
    %define $plc ebp-8
    %define $pc ebp-12
    %define $c ebp-13
    %define $c_num_val ebp-14
    ; ----- body ------
    func_entry 14

    ; num = 0;
    mov dword [$num], 0
    
    ; plc = str_last_char(arg);
    func_call [$plc], str_last_char, [$arg]
    ; pc = arg;
    mem_mov eax, [$pc], [$arg]

    ; if (plc < pc) goto invalid_num;
    mov eax, [$pc]
    cmp [$plc], eax
    jl .invalid_num

    .conversion_loop: ; do { ... } while(pc >= arg);
        ; c = *pc;
        mov eax, dword [$pc]
        mem_mov al, byte [$c], byte [eax]
        
        shl dword [$num], 4
        
        cmp_char_in_range byte [$c], 'A', 'F', .convert_hex_letter  ; if ('A' <= c && c <= 'F') goto convert_hex_letter;
        cmp_char_in_range byte [$c], '0', '9', .convert_dec_digit   ; else if ('0' <= c && c <= '9') goto convert_dec_digit;
        jmp .invalid_num                                            ; else { goto invalid_num; }

        .convert_hex_letter:
            ; c_num_val = c - ('A' - 10);
            mov al, byte [$c]
            sub al, 'A'-10
            mov byte [$c_num_val], al
            jmp .add_digit
        .convert_dec_digit:
            ; c_num_val = c - '0';
            mov al, byte [$c]
            sub al, '0'
            mov byte [$c_num_val], al
            jmp .add_digit

        .add_digit:
            ; num |= c_num_val;
            mov al, byte [$c_num_val]
            or byte [$num+0], al

        .conversion_loop_increment:
        inc dword [$pc] ; pc--;

        .conversion_loop_condition:
        ; if (pc <= plc) loop;
        mov eax, dword [$plc]
        cmp dword [$pc], eax
        jle .conversion_loop
    .conversion_loop_end:
    jmp .exit

    .invalid_num:
    mov dword [$num], -1

    .exit:
    func_exit [$num]
    %pop

str_last_char: ; str_last_char(char *s): char*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $pc ebp-4
    ; ----- body ------
    func_entry 4
    
    mem_mov eax, [$pc], [$s] ; ps = s;

    .loop: ; while (*pc != 0)
        ; if (*pc == 0) break;
        mov eax, dword [$pc]
        cmp byte [eax], 0
        je .loop_end

        ; pc++;
        inc dword [$pc]
        jmp .loop
    .loop_end:

    ; pc--;
    dec dword [$pc]
    func_exit [$pc]
    %pop

%unmacro cmp_char 4
%unmacro cmp_char_in_range 4

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
    func_call eax, malloc, 1
    ret
    %pop

BigIntegerStack_push: ; push(BigStackInteger* s, BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $n ebp+12
    ; ----- locals -----
    ; ----- body ------
    func_entry

    func_exit
    %pop

BigIntegerStack_pop: ; pop(BigStackInteger* s): BigInteger*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    ; ----- body ------
    func_entry

    func_exit
    %pop


BigIntegerStack_hasAtLeastItems: ; hasAtLeastItems(BigStackInteger* s, int amount): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $amount ebp+12
    ; ----- locals -----
    ; ----- body ------
    func_entry

    func_exit
    %pop
    
BigIntegerStack_isFull: ; isFull(BigStackInteger* s): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    ; ----- body ------
    func_entry

    func_exit
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
;    chainAdd(ByteLink *link, byte b): ByteLink*
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
    mem_mov ebx, [eax], [$b_link]
    
    func_exit
    %pop

ByteLink_chainAdd: ; chainAdd(ByteLink *link, byte b): ByteLink*
    %push
    ; ----- arguments -----
    %define $link ebp+8
    %define $b ebp+12
    ; ----- locals -----
    ; ----- body ------

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
;     getHexDigitsLen(BigInteger* n): int
;     getByte(BigInteger* n): byte
;
;     add(BigInteger* n1, BigInteger* n2): BigInteger*
;     and(BigInteger* n1, BigInteger* n2): BigInteger*
;     or(BigInteger* n1, BigInteger* n2): BigInteger*
;     multiply(BigInteger* n1, BigInteger* n2): BigInteger*
;
;    getHexDigitsLen(BigInteger* n): BigInteger*
;    
;    add(BigInteger* n1, BigInteger* n2): BigInteger*
;    and(BigInteger* n1, BigInteger* n2): BigInteger*
;    or(BigInteger* n1, BigInteger* n2): BigInteger*
;    multiply(BigInteger* n1, BigInteger* n2): BigInteger*
;
;    removeLeadingZeroes(BigInteger* n): void
;    shiftLeft(BigInteger* n, int amount): void
;    print(BigInteger* n): void
;}
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
    mem_mov ebx, [BigInteger_list(eax)], [$list]

    ;b_integer->hexDigitsLen = hexDigitsLen
    mem_mov ebx, [BigInteger_hexDigitsLength(eax)], [$hexDigitsLen]


    func_exit [$b_integer]
    %pop

BigInteger_duplicate: ; duplicate(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $b_integer ebp-4
    %define $hexDigitsLength ebp-8
    %define $duplist ebp-12
    ; ----- body ------
    func_entry 12
    
    ;eax =  n->list
    mov eax, [$n]
    mov eax, [BigInteger_list(eax)]

    ;duplist = ByteLink_duplicate(n->list)
    func_call [$duplist], ByteLink_duplicate, eax
    
    ;hexDigitsLength = n->hexDigitsLength
    mov eax, [$n]
    mem_mov ebx, [$hexDigitsLength], [BigInteger_hexDigitsLength(eax)]
    
    ;b_integer = BigInteger_ctor(duplist, hexDigitsLength)
    func_call [$b_integer], BigInteger_ctor, [$duplist], [$hexDigitsLength]


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

BigInteger_getHexDigitsLen: ; getHexDigitsLen(BigInteger* n): int
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $len ebp-4
    ; ----- body ------
    func_entry 4

    mov ebx, dword [$n]
    mov eax, [BigInteger_hexDigitsLength(ebx)]
    mov dword [$len], eax

    func_exit [$len]
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
    mov eax, [BigInteger_hexDigitsLength(ebx)]

    ; if eax is even ret eax else ret eax + 1
    ; eax = eax /2 = BigInteger_hexDigitsLength / 2
    mov edx, 0
    mov ecx, 2
    div ecx

    cmp edx, 0
    je .ret_eax
        add eax, 1
    .ret_eax:
    mov dword [$len], eax

    func_exit [$len]
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

BigInteger_print: ; print(BigInteger* n): char *
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $str ebp-4
    %define $strSize ebp-8
    %define $hex_len ebp-12
    %define $index ebp-16
    %define $tmpBigInt ebp-20
    %define $rs ebp-24
    ; ----- body ------
    func_entry 24

    ; strSize = BigInteger_getHexDigitsLen(n) + 1
    ; str = calloc(strSize ,1)
    func_call [$hex_len], BigInteger_getlistLen, [$n]
    mov ebx, dword [$hex_len]
    shl ebx, 1
    mov dword [$strSize], ebx
    add ebx, 1
    mov eax, 1
    func_call [$str], calloc, ebx, eax

    ; tmpBigInt = *n
    mov ebx, dword [$n]
    mov eax, [ebx]
    mov dword [$tmpBigInt], eax
;
    ;while(index < strSize) write in str the hex in the link
    mov dword [$index], 0
    .set_str_start:
       
        mov ebx, dword [$tmpBigInt]
    ;    ; ebx = ebx->b = n->list->b
        mov al, byte [ByteLink_b(ebx)]
;
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
;
        mov ebx, 0
        mov bl, al
        and bl, 0xF0
        shr bl, 4
        mov ecx, dword [$index]
        add ecx, dword [$str]
        func_call [$rs], insertByteAsHexToStringR, ecx ,ebx
;
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
;
    .set_str_end:
;
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