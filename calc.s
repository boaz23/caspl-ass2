NULL EQU 0

TRUE EQU 1
FALSE EQU 0

NEW_LINE_TERMINATOR EQU 10
NULL_TERMINATOR EQU 0

STK_UNIT EQU 4

DEFAULT_NUMBERS_STACK_SIZE EQU 5
MAX_LINE_LENGTH EQU 84

%define align_on(n, base) (((n)-1)-(((n)-1)%(base)))+(base)
%define align_on_16(n) align_on(n, 16)

; SIGNATURE: func_entry(n = 0)
;    n - locals size (in bytes). default is 0
; DESCRIPTION: Prepares the stack frame before executing the function

; esp -= n
%macro func_entry 0-1 0
    push ebp
    mov ebp, esp
    %if align_on_16(%1)
    sub esp, align_on_16(%1)
    %endif
    pushfd
    pushad
%endmacro

; SIGNATURE: func_exit(p_ret_val = eax)
;   p_ret_val - A place to put function return value. default is eax
; DESCRIPTION: cleans stack frame before exiting the function (after function execution)
%macro func_exit 0-1 eax
    popad
    popfd
    %ifidn %1, eax
    %else
    mov eax, %1
    %endif
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
    %push
    %define $args_size (%0-2)*STK_UNIT
    %define $args_size_aligned align_on_16($args_size)
    %define $align_push_size ($args_size_aligned - $args_size)
    
    %if $align_push_size
    sub esp, $align_push_size
    %endif
    %rep %0-2
        %rotate -1
        push dword %1
    %endrep
    %rotate -1
    call %1
    %rotate -1
    %ifidn %1, eax
    %else
    mov %1, eax
    %endif
    %if $args_size_aligned
    add esp, $args_size_aligned
    %endif
    %pop
%endmacro

%macro void_call 1-*
    func_call eax, %{1:-1}
%endmacro

; SIGNATURE: printf_inline(format_str, ... args)
; DESCRIPTION: calls printf with format_str followed by a null terminator with the specified args
; EXAMPLE:
;   printf_inline "%d", [r]
;   the above is semantically equivalent to:
;       printf("%d", [r])
%macro printf_inline 1-*
    section	.rodata
        %%format: db %1, NULL_TERMINATOR
    section	.text
        %if %0-1
            void_call printf, %%format, %{2:-1}
        %else
            void_call printf, %%format
        %endif
%endmacro

; SIGNATURE: printf_line(format_str, ... args)
; DESCRIPTION: calls printf with format_str followed by new line and null terminator with the specified args
; EXAMPLE:
;   printf_line "%d", [r]
;   the above is semantically equivalent to:
;       printf("%d\n", [r])
%macro printf_line 1-*
    %if %0-1
        printf_inline {%1, NEW_LINE_TERMINATOR}, %{2:-1}
    %else
        printf_inline {%1, NEW_LINE_TERMINATOR}
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
    Err_StackOverflow: db 'Error: Operand Stack Overflow', NEW_LINE_TERMINATOR, NULL_TERMINATOR
    Err_StackUnderflow: db 'Error: Insufficient Number of Arguments on Stack', NEW_LINE_TERMINATOR, NULL_TERMINATOR

section .bss

section .data
    %ifdef TEST_C
    global DebugMode
    global NumbersStack
    global NumbersStackCapacity
    %endif
    DebugMode: dd 0
    NumbersStack: dd NULL
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

    global BigIntegerStack_ctor
    global BigIntegerStack_free
    global BigIntegerStack_push
    global BigIntegerStack_pop
    global BigIntegerStack_peek
    global BigIntegerStack_hasAtLeastItems
    global BigIntegerStack_isFull

    global BigInteger_ctor
    global BigInteger_free
    global BigInteger_duplicate
    global BigInteger_fromInt
    global BigInteger_calcHexDigitsInteger
    global BigInteger_parse
    global BigInteger_getlistLen
    global BigInteger_add
    global BigInteger_and
    global BigInteger_or
    global BigInteger_removeLeadingZeroes
    global insertByteAsHexToStringR
    global reverse_hex_string
    global BigInteger_toString

    global ByteLink_ctor
    global ByteLink_addAtStart
    global ByteLink_freeList
    global ByteLink_duplicate
    
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
    func_call [NumbersStack], BigIntegerStack_ctor, [NumbersStackCapacity]
    
    func_call [$operations_count], myCalc
    printf_line "%X", [$operations_count]

    func_call eax, BigIntegerStack_free, [NumbersStack]

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

; cmp_char(c, ccmp, else)
; if (c != ccmp) goto else;
%macro cmp_char 3
    cmp %1, %2
    jne %3
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

; can_pop_numbers(stack, amount, if_can, if_cant)
%macro can_pop_numbers 4
    ; eax = hasAtLeastItems(NumbersStack, amount);
    func_call eax, BigIntegerStack_hasAtLeastItems, %1, %2

    ; if (eax) goto if_can
    cmp eax, FALSE
    jne %3

    %%err_underflow:
        func_call eax, printf, Err_StackUnderflow
        jmp %4
%endmacro

; can_push_number(stack, if_can, if_cant)
%macro can_push_number 3
    ; eax = isFull(stack);
    func_call eax, BigIntegerStack_isFull, %1

    ; if (!eax) goto if_can
    cmp eax, FALSE
    je %2

    %%err_overflow:
        func_call eax, printf, Err_StackOverflow
        jmp %3
%endmacro

; dbg_print_big_integer(n, ... dbg_print)
%macro dbg_print_big_integer 1-*
    ; if (DebugMode) print_big_integer(n);
    cmp dword [DebugMode], FALSE
    je %%else
    ; print info
    %if %0-1
        printf_inline %{2:-1}
    %endif
    ; print_big_integer(n)
    func_call eax, print_big_integer, %1

    %%else:
%endmacro

%macro dbg_printf_line 1-*
    ; if (DebugMode) printf(args);
    cmp dword [DebugMode], FALSE
    je %%else
    ; print info
    printf_line %{1:-1}
    %%else:
%endmacro

%macro big_integers_do_op_two_top_of_stack 1
    %push
    ; ----- arguments -----
    ; ----- locals -----
    %define $n1 ebp-4
    %define $n2 ebp-8
    %define $n_res ebp-12
    ; ----- body ------
    func_entry 12

    %%check_can_pop:
    can_pop_numbers [NumbersStack], 2, %%do_op, %%exit

    %%do_op:
    ; n1 = pop(NumbersStack);
    func_call [$n1], BigIntegerStack_pop, [NumbersStack]
    ; n2 = pop(NumbersStack);
    func_call [$n2], BigIntegerStack_pop, [NumbersStack]
    ; n_res = add(n1, n2);
    func_call [$n_res], %1, [$n1], [$n2]
    ; push(NumbersStack, n_res);
    func_call eax, BigIntegerStack_push, [NumbersStack], [$n_res]
    ; free(n1);
    func_call eax, BigInteger_free, [$n1]
    ; free(n2);
    func_call eax, BigInteger_free, [$n2]

    %%exit:
    func_exit
    %pop
%endmacro

myCalc: ; myCalc(): int
    %push
    ; ----- arguments -----
    ; ----- locals -----
    ; int operations_count;
    %define $buf ebp-MAX_LINE_LENGTH
    %define $operations_count ebp-(MAX_LINE_LENGTH+4)
    %define $p_last_char ebp-(MAX_LINE_LENGTH+8)
    %define $c ebp-(MAX_LINE_LENGTH+9)
    ; ----- body ------
    func_entry MAX_LINE_LENGTH+9

    ; operations_count = 0;
    mov dword [$operations_count], 0

    .input_loop: ;while (true)
        printf_inline "calc: "

        ; input_line(buf, arr_len(buf));
        lea eax, [$buf]
        func_call [$p_last_char], input_line, eax, MAX_LINE_LENGTH

        .act:
        ; c = buf[0]
        lea eax, [$buf]
        mem_mov al, byte [$c], byte [eax+0]

        ; information and input actions
        .inp_quit:
            cmp_char byte [$c], 'q', .inp_print
            jmp .input_loop_end
            
        .inp_print:
            cmp_char byte [$c], 'p', .inp_hex_digits_len
            dbg_printf_line "Print number"
            func_call eax, print_top_stack_number
            jmp .inp_loop_continue

        .inp_hex_digits_len:
            cmp_char byte [$c], 'n', .inp_duplicate
            dbg_printf_line "Print number of hex digits"
            func_call eax, push_top_stack_number_hex_digits_amount
            jmp .inp_loop_continue

        .inp_duplicate:
            cmp_char byte [$c], 'd', .inp_add
            dbg_printf_line "Duplicate"
            func_call eax, duplicate_top_stack_number
            jmp .inp_loop_continue

        ; number operations
        .inp_add:
            cmp_char byte [$c], '+', .inp_multiply
            dbg_printf_line "Add"
            func_call eax, add_two_top_of_stack
            jmp .inp_loop_continue

        .inp_multiply:
            cmp_char byte [$c], '*', .inp_bitwise_and
            dbg_printf_line "Multiplication is not supported"
            jmp .inp_loop_continue

        .inp_bitwise_and:
            cmp_char byte [$c], '&', .inp_bitwise_or
            dbg_printf_line "Bitwise and"
            func_call eax, and_two_top_of_stack
            jmp .inp_loop_continue

        .inp_bitwise_or:
            cmp_char byte [$c], '|', .inp_parse_number
            dbg_printf_line "Bitwise or"
            func_call eax, or_two_top_of_stack
            jmp .inp_loop_continue
            
        .inp_parse_number:
            dbg_printf_line "Parse number"
            lea eax, [$buf]
            func_call eax, parse_push_big_integer, eax
            jmp .input_loop

        .inp_loop_continue:
        inc dword [$operations_count]
        jmp .input_loop
    .input_loop_end:

    func_exit [$operations_count]
    %pop

input_line: ; input_line(char *buf, int buf_size): char*
    %push
    ; ----- arguments -----
    %define $buf ebp+8
    %define $buf_size ebp+12
    ; ----- locals -----
    ; int operations_count;
    %define $p_last_char ebp-4
    ; ----- body ------
    func_entry 4

    ; fgets(buf, buf_size, stdin);
    func_call eax, fgets, [$buf], [$buf_size], [stdin]

    ; p_last_char = str_last_char(buf);
    func_call [$p_last_char], str_last_char, [$buf]

    ; if (*p_last_char == '\n') *p_last_char = '\0';
    mov eax, dword [$p_last_char]
    cmp byte [eax], NEW_LINE_TERMINATOR
    jne .exit
    mov byte [eax], NULL_TERMINATOR
    dec dword [$p_last_char]

    .exit:
    func_exit [$p_last_char]
    %pop

print_top_stack_number: ; print_number_stack_top(): void
    %push
    ; ----- arguments -----
    ; ----- locals -----
    %define $n ebp-4
    ; ----- body ------
    func_entry 4

    .check_can_pop:
    can_pop_numbers [NumbersStack], 1, .print, .exit

    .print:
    ; n = pop(NumbersStack);
    func_call [$n], BigIntegerStack_pop, [NumbersStack]
    ; print_big_integer(n);
    func_call eax, print_big_integer, [$n]
    ; free(n);
    func_call eax, BigInteger_free, [$n]

    .exit:
    func_exit
    %pop

push_top_stack_number_hex_digits_amount: ; print_number_stack_top_hex_digits_len(): void
    %push
    ; ----- arguments -----
    ; ----- locals -----
    %define $n ebp-4
    %define $n_num_hex_digits ebp-8
    ; ----- body ------
    func_entry 8

    .check_can_pop:
    can_pop_numbers [NumbersStack], 1, .push_hex_digits_amount, .exit

    .push_hex_digits_amount:
    ; n = pop(NumbersStack);
    func_call [$n], BigIntegerStack_pop, [NumbersStack]
    ; n_num_hex_digits = BigInteger.calcHexDigitsInteger(n);
    func_call [$n_num_hex_digits], BigInteger_calcHexDigitsInteger, [$n]
    ; push(NumbersStack, n_num_hex_digits);
    func_call eax, BigIntegerStack_push, [NumbersStack], [$n_num_hex_digits]
    ; free(n);
    func_call eax, BigInteger_free, [$n]

    .exit:
    func_exit
    %pop

duplicate_top_stack_number: ; duplicate_top_stack_number(): void
    %push
    ; ----- arguments -----
    ; ----- locals -----
    %define $n ebp-4
    %define $n_dup ebp-8
    ; ----- body ------
    func_entry 8

    .check_can_pop:
    can_pop_numbers [NumbersStack], 1, .check_can_push, .exit
    .check_can_push:
    can_push_number [NumbersStack], .duplicate, .exit

    .duplicate:
    ; n = pop(NumbersStack);
    func_call [$n], BigIntegerStack_peek, [NumbersStack]
    ; n_dup = duplicate(n);
    func_call [$n_dup], BigInteger_duplicate, [$n]
    ; push(NumbersStack, n_dup);
    func_call eax, BigIntegerStack_push, [NumbersStack], [$n_dup]

    .exit:
    func_exit
    %pop

add_two_top_of_stack: ; add_two_top_of_stack(): void
    big_integers_do_op_two_top_of_stack BigInteger_add

and_two_top_of_stack: ; and_two_top_of_stack(): void
    big_integers_do_op_two_top_of_stack BigInteger_and

or_two_top_of_stack: ; or_two_top_of_stack(): void
    big_integers_do_op_two_top_of_stack BigInteger_or

parse_push_big_integer: ; parse_push_big_integer(char *s): void
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $n ebp-4
    ; ----- body ------
    func_entry 4

    .parse:
    ; n = BigInteger.parse(s);
    func_call [$n], BigInteger_parse, [$s]

    ; if (n) goto number_parsed_successful;
    cmp dword [$n], NULL
    jne .number_parsed_successful
    printf_line "The input is not a hex number"
    jmp .exit

    .number_parsed_successful:
    dbg_print_big_integer [$n], "Parsed number: "

    .check_can_push:
    can_push_number [NumbersStack], .push_num, .free_big_int

    .free_big_int:
    func_call eax, BigInteger_free, [$n]
    jmp .exit

    .push_num:
    ; push(NumbersStack, n);
    func_call eax, BigIntegerStack_push, [NumbersStack], [$n]

    .exit:
    func_exit
    %pop

print_big_integer: ; print_big_integer(BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals -----
    %define $s ebp-4
    ; ----- body ------
    func_entry 4

    ; s = print(n);
    func_call [$s], BigInteger_toString, [$n]
    ; printf("%s\n", s);
    printf_line "%s", [$s]
    ; free(s);
    func_call eax, free, [$s]

    func_exit
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

    cmp_char dword [$arg], 0, '-', .exit                ; if (arg[0] != '-')  goto exit;
    cmp_char dword [$arg], 1, 'd', .exit                ; if (arg[1] != 'd')  goto exit;
    cmp_char dword [$arg], 2, NULL_TERMINATOR, .exit    ; if (arg[2] != '\0') goto exit;

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
    %define $num ebp-4
    %define $plc ebp-8
    ; ----- body ------
    func_entry 8

    ; num = 0;
    mov dword [$num], 0
    
    ; plc = str_last_char(arg);
    func_call [$plc], str_last_char, [$arg]
    ; num = parse_hex_string_to_num(arg, plc);
    func_call [$num], parse_hex_string_to_num, [$arg], [$plc]

    .exit:
    func_exit [$num]
    %pop

parse_hex_string_to_num: ; parse_hex_string_to_num(char *p_start, char *p_end): int
    %push
    ; ----- arguments -----
    %define $p_start ebp+8
    %define $p_end ebp+12
    ; ----- locals -----
    %define $num ebp-4
    %define $pc ebp-8
    %define $c_num_val ebp-12
    ; ----- body ------
    func_entry 12
    
    ; if (p_end < p_start) goto invalid_num;
    mov eax, dword [$p_start]
    cmp dword [$p_end], eax
    jl .invalid_num

    ; num = 0;
    mov dword [$num], 0
    ; pc = p_start;
    mem_mov eax, [$pc], [$p_start]

    .conversion_loop: ; do { ... } while(pc <= plc);
        shl dword [$num], 4

        ; c_num_val = convert_char_hex_digit_to_byte(pc);
        func_call [$c_num_val], convert_char_hex_digit_to_byte, [$pc]

        ; if (c_num_val < 0) goto invalid_num;
        cmp dword [$c_num_val], 0
        jl .invalid_num

        .add_digit:
            ; num |= c_num_val;
            mov al, byte [$c_num_val]
            or byte [$num], al

        .conversion_loop_increment:
        inc dword [$pc] ; pc++;

        .conversion_loop_condition:
        ; if (pc <= p_end) continue;
        mov eax, dword [$p_end]
        cmp dword [$pc], eax
        jle .conversion_loop
    .conversion_loop_end:
    jmp .exit

    .invalid_num:
    mov dword [$num], -1

    .exit:
    func_exit [$num]
    %pop

convert_char_hex_digit_to_byte: ; convert_char_hex_digit_to_byte(char *pc): byte
    %push
    ; ----- arguments -----
    %define $pc ebp+8
    ; ----- locals -----
    %define $c ebp-1
    %define $c_num_val ebp-5
    ; ----- body ------
    func_entry 5
    
    ; c_num_val = 0;
    mov dword [$c_num_val], 0

    ; c = *pc;
    mov eax, dword [$pc]
    mem_mov al, byte [$c], byte [eax]
    
    ; if      ('A' <= c && c <= 'F') goto convert_hex_letter;
    ; else if ('a' <= c && c <= 'f') goto convert_hex_lowercase_letter;
    ; else if ('0' <= c && c <= '9') goto convert_dec_digit;
    ; else { goto invalid_char; }
    cmp_char_in_range byte [$c], 'A', 'F', .convert_hex_uppercase_letter
    cmp_char_in_range byte [$c], 'A', 'F', .convert_hex_lowercase_letter
    cmp_char_in_range byte [$c], '0', '9', .convert_dec_digit
    jmp .invalid_char

    .convert_hex_uppercase_letter:
        ; c_num_val = c - ('A' - 10);
        mov al, byte [$c]
        sub al, 'A'-10
        mov byte [$c_num_val], al
        jmp .exit
    .convert_hex_lowercase_letter:
        ; c_num_val = c - ('a' - 10);
        mov al, byte [$c]
        sub al, 'a'-10
        mov byte [$c_num_val], al
        jmp .exit
    .convert_dec_digit:
        ; c_num_val = c - '0';
        mov al, byte [$c]
        sub al, '0'
        mov byte [$c_num_val], al
        jmp .exit

    .invalid_char:
    ; c_num_val = -1;
    mov dword [$c_num_val], -1

    .exit:
    func_exit [$c_num_val]
    %pop

convert_two_hex_digits_to_byte: ; convert_two_hex_digits_to_byte(char *pc): byte
    %push
    ; ----- arguments -----
    %define $pc ebp+8
    ; ----- locals ------
    %define $b_val ebp-4
    ; ----- body ------
    func_entry 4

    ; eax = pc + 1;
    mov eax, dword [$pc]
    inc dword eax

    ; b_val = parse_hex_string_to_num(pc, eax);
    func_call [$b_val], parse_hex_string_to_num, [$pc], eax

    func_exit [$b_val]
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
        cmp byte [eax], NULL_TERMINATOR
        je .loop_end

        ; pc++;
        inc dword [$pc]
        jmp .loop
    .loop_end:

    ; pc--;
    dec dword [$pc]
    func_exit [$pc]
    %pop

str_ignore_leading_zeroes: ; str_ignore_leading_zeroes(char *p_start, char *p_end): char*
    %push
    ; ----- arguments -----
    %define $p_start ebp+8
    %define $p_end ebp+12
    ; ----- locals ------
    %define $p_c ebp-4
    ; ----- body ------
    func_entry 4

    ; p_c = s;
    mem_mov eax, [$p_c], [$p_start]
    .ignore_leading_zeroes_loop: ; while (p_c <= p_end && *p_c == '0')
        ; loop condition
        ; if (p_c > p_end) break;
        mov eax, [$p_c]
        cmp eax, dword [$p_end]
        jg .ignore_leading_zeroes_loop_end
        ; if (*p_c != '0') break;
        mov eax, dword [$p_c]
        cmp byte [eax], '0'
        jne .ignore_leading_zeroes_loop_end

        ; loop increment
        inc dword [$p_c] ; p_c++;
        jmp .ignore_leading_zeroes_loop
    .ignore_leading_zeroes_loop_end:

    func_exit [$p_c]
    %pop

;------------------- class BigIntegerStack -------------------
%ifdef COMMENT
;class BigIntegerStack {
;    BigInteger[] numbers;
;    int capacity;
;    int sp;
;
;    ctor(int capacity): BigIntegerStack*
;    free(BigIntegerStack* s): void;
;    push(BigIntegerStack* s, BigInteger* n): void
;    pop(BigIntegerStack* s): BigInteger*
;    peek(BigIntegerStack* s): BigInteger*
;    hasAtLeastItems(BigIntegerStack* s, int amount): boolean
;    isFull(BigIntegerStack* s): boolean
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
    %define $s ebp-4
    %define $n_arr_bytes_size ebp-8
    %define $n_arr ebp-12
    ; ----- body ------
    func_entry 12

    ; n_arr_bytes_size = capacity;
    mem_mov eax, [$n_arr_bytes_size], [$capacity]
    ; n_arr_bytes_size *= 4;
    shl dword [$n_arr_bytes_size], 2
    ; n_arr = malloc(n_arr_bytes_size);
    func_call [$n_arr], malloc, [$n_arr_bytes_size]
    
    ; s = malloc(sizeof(BigIntegerStack))
    func_call [$s], malloc, sizeof_BigIntegerStack
    mov eax, [$s]

    ; s->numbers = n_arr;
    mem_mov ebx, [BigIntegerStack_numbers(eax)], [$n_arr]
    ; s->capacity = capacity;
    mem_mov ebx, [BigIntegerStack_capacity(eax)], [$capacity]
    ; s->sp = 0;
    mov dword [BigIntegerStack_sp(eax)], 0

    func_exit [$s]
    %pop

BigIntegerStack_free: ; free(BigIntegerStack* s): void
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    ; ----- body ------
    func_entry

    ; free all big integers in the stack
    ; s->free_arr();
    func_call eax, BigIntegerStack_free_arr, [$s]

    ; free(s->numbers);
    mov eax, [$s]
    func_call eax, free, [BigIntegerStack_numbers(eax)]

    ; free(s);
    func_call eax, free, [$s]

    func_exit
    %pop

BigIntegerStack_push: ; push(BigStackInteger* s, BigInteger* n): void
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $n ebp+12
    ; ----- locals -----
    ; ----- body ------
    func_entry

    ; s->numbers[s->sp] = n;
    mov eax, [$s]
    mov ebx, [BigIntegerStack_numbers(eax)]
    mov eax, [BigIntegerStack_sp(eax)]
    mem_mov ecx, [ebx+4*eax], [$n]
    
    ; s->sp++;
    mov eax, [$s]
    inc dword [BigIntegerStack_sp(eax)]

    dbg_print_big_integer [$n], "Pushed number: "

    func_exit
    %pop

BigIntegerStack_pop: ; pop(BigStackInteger* s): BigInteger*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $n ebp-4
    ; ----- body ------
    func_entry 4

    ; n = BigIntegerStack.peek(s);
    func_call [$n], BigIntegerStack_peek, [$s]
    
    ; s->sp--;
    mov eax, [$s]
    dec dword [BigIntegerStack_sp(eax)]

    dbg_print_big_integer [$n], "Popped number: "

    func_exit [$n]
    %pop

BigIntegerStack_peek: ; peek(BigStackInteger* s): BigInteger*
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $n ebp-4
    ; ----- body ------
    func_entry 4

    ; n = s->numbers[s->sp]
    mov eax, [$s]
    mov ebx, [BigIntegerStack_numbers(eax)]
    mov eax, [BigIntegerStack_sp(eax)]
    dec eax
    mem_mov ecx, [$n], [ebx+4*eax]

    func_exit [$n]
    %pop


BigIntegerStack_hasAtLeastItems: ; hasAtLeastItems(BigStackInteger* s, int amount): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    %define $amount ebp+12
    ; ----- locals -----
    %define $enough_for_pop ebp-4
    ; ----- body ------
    func_entry 4
    
    ; eax = s->sp;
    mov eax, dword [$s]
    mov eax, dword [BigIntegerStack_sp(eax)]

    ; if (s->sp < amount) goto less_items;
    cmp eax, dword [$amount]
    jl .less_items

    .enough:
        ; enough_for_pop = true;
        mov dword [$enough_for_pop], TRUE
        jmp .exit
    .less_items:
        ; enough_for_pop = false;
        mov dword [$enough_for_pop], FALSE
        jmp .exit

    .exit:
    func_exit [$enough_for_pop]
    %pop
    
BigIntegerStack_isFull: ; isFull(BigStackInteger* s): boolean
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $is_full ebp-4
    ; ----- body ------
    func_entry 4
    
    ; eax = s; ebx = s->sp;
    mov eax, dword [$s]
    mov ebx, dword [BigIntegerStack_sp(eax)]

    ; if (s->sp < s->capacity) goto less_items;
    cmp ebx, dword [BigIntegerStack_capacity(eax)]
    jl .free

    .full:
        ; enough_for_pop = true;
        mov dword [$enough_for_pop], TRUE
        jmp .exit
    .free:
        ; enough_for_pop = false;
        mov dword [$enough_for_pop], FALSE
        jmp .exit

    .exit:
    func_exit [$is_full]
    %pop

BigIntegerStack_free_arr: ; BigIntegerStack_free_arr(BigIntegerStack *s)
    %push
    ; ----- arguments -----
    %define $s ebp+8
    ; ----- locals -----
    %define $p_number ebp-4
    %define $has_items ebp-8
    ; ----- body ------
    func_entry 8
    
    .pop_loop: ; while (s->hasAtLeastItems(1))
        ; if (s->hasAtLeastItems(1) != false) break;
        func_call [$has_items], BigIntegerStack_hasAtLeastItems, [$s], 1
        cmp dword [$has_items], FALSE
        je .pop_loop_end

        ; p_number = s->pop();
        func_call [$p_number], BigIntegerStack_pop, [$s]
        ; delete p_number;
        func_call eax, BigInteger_free, [$p_number]

        jmp .pop_loop
    .pop_loop_end:

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
;    addAsNext(ByteLink *link, byte b): ByteLink*
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

ByteLink_addAtStart: ; ByteLink_addAtStart(ByteLink** list, byte b): void
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
;}
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
    %define $big_int ebp-4
    %define $b_list ebp-8
    %define $b_list_len ebp-12
    %define $ps_last_c ebp-16
    %define $ps_start_c ebp-20
    %define $pc ebp-24
    %define $c_num_val ebp-28
    %define $b_val ebp-32
    ; ----- body ------
    func_entry 32
    
    ; b_list = null;
    mov dword [$b_list], NULL
    ; b_list_len = 0;
    mov dword [$b_list_len], 0

    ; ps_last_c = str_last_char(s);
    func_call [$ps_last_c], str_last_char, [$s]

    ; ignore leading zeroes
    ; ps_start_c = str_ignore_leading_zeroes(s, ps_last_c)
    func_call [$ps_start_c], str_ignore_leading_zeroes, [$s], [$ps_last_c]
    ; pc = ps_start_c;
    mem_mov eax, [$pc], [$ps_start_c]

    ; if (ps_start_c <= ps_last_c) goto non_zero;
    mov eax, [$ps_start_c]
    cmp eax, dword [$ps_last_c]
    jle .non_zero
    
    .zero:
        ; b_list = new ByteLink(0, null);
        func_call [$b_list], ByteLink_ctor, 0, NULL
        mov dword [$b_list_len], 1
        jmp .construct_big_int

    .non_zero:
    ; remember that ps_last_c is the pointer to the last character,
    ; so the length of the string is (ps_last_c - ps_start_c + 1)
    ; if ((ps_last_c - ps_start_c) % 2 == 1) goto even_len_inp
    mov eax, dword [$ps_last_c]
    sub eax, dword [$ps_start_c]
    test eax, 1
    jz .odd_len_inp

    .even_len_inp:
        jmp .parse_loop

    .odd_len_inp:
        ; c_num_val = convert_char_hex_digit_to_byte(pc);
        func_call [$c_num_val], convert_char_hex_digit_to_byte, [$ps_start_c]
        ; if (c_num_val < 0) goto invalid_num;
        cmp dword [$c_num_val], 0
        jl .invalid_num

        ; pc++;
        inc dword [$pc]
        ; b_val = c_num_val;
        mem_mov eax, [$b_val], [$c_num_val]
    
    .create_first_link:
    ; b_list = new ByteLink(b_val, null);
    func_call [$b_list], ByteLink_ctor, [$b_val], NULL
    ; b_list_len++;
    inc dword [$b_list_len]

    .parse_loop: ; while (pc < ps_last_c)
        ; loop condition
        ; if (pc >= ps_last_c) break;
        mov eax, dword [$ps_last_c]
        cmp dword [$pc], eax
        jge .parse_loop_end

        ; loop body
        ; b_val = convert_two_hex_digits_to_byte(pc);
        func_call [$b_val], convert_two_hex_digits_to_byte, [$pc]
        ; if (b_val < 0) goto invalid_num;
        cmp dword [$b_val], 0
        jl .invalid_num
        
        ; b_list = ByteLink.addAtStart(&b_list, b_val);
        lea eax, [$b_list]
        func_call eax, ByteLink_addAtStart, eax, [$b_val]
        ; b_list_len++;
        inc dword [$b_list_len]

        ; loop increment
        add dword [$pc], 2
        jmp .parse_loop
    .parse_loop_end:
    
    .construct_big_int:
    func_call [$big_int], BigInteger_ctor, [$b_list], [$b_list_len]
    jmp .exit

    .invalid_num:
    mov dword [$big_int], NULL

    .exit:
    func_exit [$big_int]
    %pop

BigInteger_fromInt: ; fromInt(int n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $link ebp-4
    %define $BigInt ebp-8
    ; ----- body ------
    func_entry 8

    mov eax, dword [$n]
    and eax, 0xFF000000
    shr eax, 24
    func_call [$link], ByteLink_ctor, eax, NULL

    mov eax, dword [$n]
    and eax, 0x00FF0000
    shr eax, 16
    lea ebx, [$link]
    func_call ebx, ByteLink_addAtStart, ebx, eax

    mov eax, dword [$n]
    and eax, 0x0000FF00
    shr eax, 8
    lea ebx, [$link]
    func_call ebx, ByteLink_addAtStart, ebx, eax

    mov eax, dword [$n]
    and eax, 0x000000FF
    lea ebx, [$link]
    func_call ebx, ByteLink_addAtStart, ebx, eax

    func_call [$BigInt], BigInteger_ctor, [$link] , 4
    func_call eax, BigInteger_removeLeadingZeroes, [$BigInt]

    func_exit [$BigInt]
    %pop

BigInteger_calcHexDigitsInteger: ; calcHexDigitsInteger(BigInteger* n): BigInteger*
    %push
    ; ----- arguments -----
    %define $n ebp+8
    ; ----- locals ------
    %define $hexlen ebp-4
    %define $currentlink ebp-8
    %define $BigInt ebp-12
    ; ----- body ------
    func_entry 12

    func_call [$hexlen], BigInteger_getlistLen, dword [$n]

    ;current = n->list
    mov eax, dword [$n]
    mem_mov ebx, [$currentlink], [BigInteger_list(eax)]

    ;if len = 1 and the byte is 0
    cmp dword [$hexlen], 1
    jne .len_bigger_than_1
        mov ebx, [$currentlink]
        cmp byte [ByteLink_b(ebx)], 0
        je .create_BigInt

    .len_bigger_than_1:

    ;hexlen = hexlen * 2
    shl dword [$hexlen], 1

    ;while(current->next != NULL)
    .get_to_last_link_loop_start:
        mov eax, dword [$currentlink]
        cmp dword [ByteLink_next(eax)], 0
        je .get_to_last_link_loop_end

        ; current = current->next
        mov eax, dword [$currentlink]
        mem_mov ebx, [$currentlink], [ByteLink_next(eax)]
        jmp .get_to_last_link_loop_start
    .get_to_last_link_loop_end:

    ;if b is in form of 0x0.. dec hexlen
    mov eax, dword [$currentlink]
    mov bl, byte [ByteLink_b(eax)]
    and bl, 0xF0
    cmp bl, 0
    jne .create_BigInt
    dec dword [$hexlen]

    .create_BigInt:

    ;create BigInt
    func_call [$BigInt], BigInteger_fromInt, [$hexlen]

    func_exit [$BigInt]
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

        ;resLen = resLen + 1
        inc dword [$resLen]

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
    %define $Andedlist ebp-4
    %define $currentAddedLink ebp-8
    %define $currentShorter ebp-12
    %define $currentLonger ebp-16
    %define $resBigInt ebp-20
    %define $resLen ebp-24
    ; ----- body ------
    func_entry 24

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

    ;currentAddedLink = ByteLink_ctor(currentShorter.b and currentLonger.b, NULL)
    ; cl = currentShorter->b
    mov ecx, dword [$currentShorter]
    mov cl, byte [ByteLink_b(ecx)]

    ; bl = currentShorter->b
    mov ebx, dword [$currentLonger]
    mov bl, byte [ByteLink_b(ebx)]

    and cl, bl
    func_call [$currentAddedLink], ByteLink_ctor, ecx, NULL
    mem_mov ecx, [$Andedlist], [$currentAddedLink]

    ;resLen = resLen + 1
    inc dword [$resLen]

    ;currents to next
    mov ecx, dword [$currentShorter]
    mem_mov ebx, [$currentShorter], [ByteLink_next(ecx)]

    mov ecx, dword [$currentLonger]
    mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]

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

        ;cl = cl and bl = currentShorter->b and currentShorter->b
        and cl, bl

        ;resLen = resLen + 1
        inc dword [$resLen]

        ;currentAddedLink = ByteLink_AddAsLast(currentAddedLink, ecx)
        func_call [$currentAddedLink], ByteLink_addAsNext, [$currentAddedLink], ecx

        ;currents to next
        mov ecx, dword [$currentShorter]
        mem_mov ebx, [$currentShorter], [ByteLink_next(ecx)]

        mov ecx, dword [$currentLonger]
        mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]
        jmp .add_with_short_loop_start

    .add_with_short_loop_end:

    func_call [$resBigInt], BigInteger_ctor, [$Andedlist], [$resLen]
    func_call eax, BigInteger_removeLeadingZeroes, [$resBigInt]

    func_exit [$resBigInt]
    %pop

BigInteger_or: ; or(BigInteger* n1, BigInteger* n2): BigInteger*
    %push
    ; ----- arguments -----
    %define $n1 ebp+8
    %define $n2 ebp+12
    ; ----- locals ------
    %define $orlist ebp-4
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

    ; cl = cl or bl
    ; save flags
    or cl, bl
    func_call [$currentAddedLink], ByteLink_ctor, ecx, NULL
    mem_mov ecx, [$orlist], [$currentAddedLink]

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

        ;cl = cl + bl = currentShorter->b + currentShorter->b + carray
        or cl, bl

        ;resLen = resLen + 1
        inc dword [$resLen]

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

        ;cl = cl + bl = currentShorter->b + currentShorter->b + carray
        or cl, bl

        ;resHexDgits = resHexDgits + 1
        inc dword [$resLen]

        ;currentAddedLink = ByteLink_AddAsLast(currentAddedLink, currentLonger.b add with carray 0)
        func_call [$currentAddedLink], ByteLink_addAsNext, [$currentAddedLink], ecx

        ;current longer next
        mov ecx, dword [$currentLonger]
        mem_mov ebx, [$currentLonger], [ByteLink_next(ecx)]
        jmp .add_with_long_loop_start

    .add_with_long_loop_end:

    func_call [$resBigInt], BigInteger_ctor, [$orlist], [$resLen]
    func_call eax, BigInteger_removeLeadingZeroes, [$resBigInt]

    func_exit [$resBigInt]
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
	.reverse_hex_string_loop: ; while (i < k)
		; condition check
		; if (eax < ebx) break;
        mov [$index], eax
		cmp eax, ebx
		jl .reverse_hex_string_loop_end
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
		jmp .reverse_hex_string_loop
	.reverse_hex_string_loop_end:

    func_exit
    %pop
