#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char byte;

/* ByteLink */
typedef struct ByteLink{
    byte b;
    struct ByteLink* next;
} __attribute__((packed, aligned(1))) ByteLink;

extern ByteLink* ByteLink_ctor(byte b, ByteLink* next);
extern void ByteLink_addAtStart(ByteLink** link, byte b);
extern void ByteLink_freeList(ByteLink* list);
extern ByteLink* ByteLink_duplicate(ByteLink* list);

/* BigInterger */
typedef struct BigInteger {
    struct ByteLink* list;
    int len;
} BigInteger;

extern BigInteger* BigInteger_ctor(ByteLink *link, int LenHexDigits);
extern void BigInteger_free(BigInteger *link);
extern BigInteger* BigInteger_duplicate(BigInteger *link);

extern BigInteger* BigInteger_parse(char *s);
extern int BigInteger_getlistLen(BigInteger *bigInteger);
extern BigInteger* BigInteger_fromInt(int n);
extern BigInteger* BigInteger_calcHexDigitsInteger(BigInteger *bigInteger);
extern BigInteger* BigInteger_add(BigInteger *n1, BigInteger *n2);
extern BigInteger* BigInteger_and(BigInteger *n1, BigInteger *n2);
extern BigInteger* BigInteger_or(BigInteger *n1, BigInteger *n2);
extern void BigInteger_removeLeadingZeroes(BigInteger *bigInteger);
extern void insertByteAsHexToStringR(char *str, int b);
extern void reverse_hex_string(char *str, int len);
extern char *BigInteger_toString(BigInteger *link);

/* BigIntegerStack */
typedef struct BigIntegerStack {
    BigInteger **numbers;
    int capacity;
    int sp;
} BigIntegerStack;

extern BigIntegerStack* BigIntegerStack_ctor(int capacity);
extern void BigIntegerStack_free(BigIntegerStack* s);
extern void BigIntegerStack_push(BigIntegerStack* s, BigInteger* n);
extern BigInteger* BigIntegerStack_pop(BigIntegerStack* s);
extern BigInteger* BigIntegerStack_peek(BigIntegerStack* s);
extern int BigIntegerStack_hasAtLeastItems(BigIntegerStack* s, int amount);
extern int BigIntegerStack_isFull(BigIntegerStack* s);

extern int DebugMode;
extern int NumbersStackCapacity;
extern BigIntegerStack *NumbersStack;

extern void set_run_settings_from_args(int argc, char *argv[]);
extern int is_arg_debug(char *arg);
extern int try_parse_arg_hex_string_num(char *arg);
extern char* str_last_char(char *s);

int test_stack_mng() {
    int a = 5;
    int b = a + 3;
    int c = b + 3;
    int d = c + 8;
    return d;
}

void test_str_last_char() {
    char *s = "";
    char *p = str_last_char(s);
    if (p >= s) {
        printf("%c\n",*p);
    }
    else {
        printf("empty string\n");
    }
}

void test_try_parse_arg_hex_string_num_num(char *s) {
    int n = try_parse_arg_hex_string_num(s);
    // int n = test_1(s);
    if (n < 0) {
        printf("invalid number\n");
    }
    else {
        printf("%d\n", n);
    }
}
void test_try_parse_arg_hex_string_num() {
    test_try_parse_arg_hex_string_num_num("A");
    test_try_parse_arg_hex_string_num_num("05");
    test_try_parse_arg_hex_string_num_num("3A");
    test_try_parse_arg_hex_string_num_num("00000");
    test_try_parse_arg_hex_string_num_num("5Ag");
    test_try_parse_arg_hex_string_num_num("");
}

void test_is_arg_dbg_s(char *s) {
    int b = is_arg_debug(s);
    if (b) {
        printf("is debug\n");
    }
    else {
        printf("not debug\n");
    }
}
void test_is_arg_dbg() {
    test_is_arg_dbg_s("-d");
    test_is_arg_dbg_s("-");
    test_is_arg_dbg_s("-A");
    test_is_arg_dbg_s("-D");
    test_is_arg_dbg_s("-db");
    test_is_arg_dbg_s("-Db");
    test_is_arg_dbg_s("hi");
    test_is_arg_dbg_s("");
}

void test_set_run_settings_from_args_args(int argc, char *argv[]) {
    set_run_settings_from_args(argc, argv);
    if (DebugMode) {
        printf("Debug mode\n");
    }
    else {
        printf("Normal mode\n");
    }
    printf("stack cap: %d\n", NumbersStackCapacity);
}
void test_set_run_settings_from_args() {
    char *s[] = {
        "filler", "1A", "-d"
    };
    test_set_run_settings_from_args_args(2, s);
}

void test_same_Bytelink(ByteLink *current, ByteLink *dupCurrent, char *funcName);

void test_ByteLink_ctor(){
    byte c = 65; //A
    ByteLink* bl = ByteLink_ctor(c, NULL);
    if(bl == NULL){
        printf("test_ByteLink_ctor ctor return null\n");
        return;
    }

    if(bl->b != c){
        printf("test_ByteLink_ctor expect byte %c recive %c\n",c, bl->b);
    }

    ByteLink_freeList(bl);
}

/* Assume ByteLink_ctor works */
extern void test_ByteLink_addAtStart(){
    byte c1 = 0x0A, c2 = 0XC9;
    ByteLink* blist = ByteLink_ctor(c1, NULL);
    if(blist == NULL){
        printf("ByteLink_addAtStart error at malloc\n");
        return;
    }
    ByteLink_addAtStart(&blist, c2);

    if(blist != NULL){
        if(blist->b != c2){
            printf("ByteLink_addAtStart expect byte %c recive %c\n",c2, blist->b);
        } else {
            if(blist->next != NULL){
                if(blist->next->b != c1){
                    printf("ByteLink_addAtStart expect byte %c recive %c\n",c1, blist->next->b);
                }
            } else {
                printf("ByteLink_addAtStart expect blist->next not to be null\n");
            }
        }
    } else {
        printf("ByteLink_addAtStart expect blist not to be null\n");
    }

    ByteLink_freeList(blist);
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
void test_ByteLink_duplicate(){
    byte c1 = 65, c2 = 99; //A, c
    ByteLink* bl = ByteLink_ctor(c1, NULL);
    ByteLink* dup;
    int bloop = 0;

    ByteLink_addAtStart(&bl, c2);

    dup = ByteLink_duplicate(bl);

    test_same_Bytelink(bl, dup, "test_ByteLink_duplicate");

    ByteLink_freeList(bl);
    ByteLink_freeList(dup);
}
#pragma GCC diagnostic pop

void test_same_Bytelink(ByteLink *current, ByteLink *dupCurrent, char *funcName){
    int bloop = 0;
    while(current->next != NULL){
        if(dupCurrent == NULL){
            printf("%s the dup is shorter from the original\n", funcName);
            bloop = 1;
            break;
        }

        if(current->b != dupCurrent->b){
            printf("%s expect dup->c: %c reseve %c\n", funcName, current->b, dupCurrent->b);
            bloop = 1;
            break;
        }

        current = current->next;
        dupCurrent = dupCurrent->next;

    }

    if(bloop == 0){
        if(dupCurrent->next != NULL){
            printf("%s the dup list is longer from the original, its f\n", funcName);
        }
    }
}

void test_insertByteAsHexToStringR(){
    char *str = (char *)malloc(2);
    int c;
    str[1] = '\0';
    
    c = 0x01;
    insertByteAsHexToStringR(str,c);
    if(str[0] != '1'){
        printf("test_insertByteAsHexToStringR at c=0x01");
    }
    

    c = 0x0A;
    insertByteAsHexToStringR(str,c);
    if(str[0] != ('A')){
        printf("test_insertByteAsHexToStringR at c=0x0A");
    }

    free(str);
}

void test_BigInteger_fromInt1(){
    BigInteger *fromInt;
    int n = 0x65;

    fromInt = BigInteger_fromInt(n);

    if(fromInt != NULL){
        if(fromInt->len == 1){
            if(fromInt->list != NULL){
                if(fromInt->list->b != (char)n){
                    printf("test_BigInteger_fromInt expect fromInt->list->b = %c recive: %x\n", (char)n, fromInt->list->b); 
                }
                if(fromInt->list->next != NULL){
                    printf("test_BigInteger_fromInt expect fromInt->list->next to be null \n"); 
                }
            } else {
                printf("test_BigInteger_fromInt expect fromInt->list not to be null \n"); 
            }
        } else {
            printf("test_BigInteger_fromInt expect len = 1 recive: %d\n", fromInt->len); 
        }
    } else {
        printf("test_BigInteger_fromInt return null BigInteger\n"); 
    }

    if(fromInt != NULL){
        BigInteger_free(fromInt);
    }
}

void test_BigInteger_fromInt2(){
    BigInteger *fromInt;
    int n = 0x6512;

    fromInt = BigInteger_fromInt(n);

    if(fromInt != NULL){
        if(fromInt->len == 2){
            if(fromInt->list != NULL){
                if(fromInt->list->b != (char)0x12){
                    printf("test_BigInteger_fromInt expect fromInt->list->b = %c recive: %x\n", (char)0x12, fromInt->list->b); 
                }
                if(fromInt->list->next == NULL){
                    printf("test_BigInteger_fromInt expect fromInt->list->next not to be null \n"); 
                } else {
                    if(fromInt->list->next->b != (char)0x65){
                        printf("test_BigInteger_fromInt expect fromInt->list->b = %c recive: %x\n", (char)0x65, fromInt->list->b); 
                    }
                    if(fromInt->list->next->next != NULL){
                        printf("test_BigInteger_fromInt expect fromInt->list->next->next to be null \n"); 
                    }  
                }
            } else {
                printf("test_BigInteger_fromInt expect fromInt->list not to be null \n"); 
            }
        } else {
            printf("test_BigInteger_fromInt expect len = 1 recive: %d\n", fromInt->len); 
        }
    } else {
        printf("test_BigInteger_fromInt return null BigInteger\n"); 
    }

    if(fromInt != NULL){
        BigInteger_free(fromInt);
    }
}

void test_BigInteger_calcHexDigitsInteger1(){
    BigInteger *bigInt, *calcBigInt;
    ByteLink* list;
    int c = 0x12, len = 1;
    list = ByteLink_ctor(0, NULL);

    bigInt = BigInteger_ctor(list, len);
    calcBigInt = BigInteger_calcHexDigitsInteger(bigInt);

    if(calcBigInt != NULL){
        if(calcBigInt->list != NULL){
            if(calcBigInt->list->b != (char)len){
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->b %c recive %c\n", (char)len, calcBigInt->list->b); 
            }
            if(calcBigInt->list->next != NULL){
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->next to be null \n"); 
            }
        } else {
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list not to be null \n"); 
        }

        if(calcBigInt->len != 1){
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->len to 1 \n");
        }
    } else {
        printf("test_BigInteger_calcHexDigitsInteger return null BigInteger\n"); 
    }

    BigInteger_free(bigInt);
    if(calcBigInt != NULL){
        BigInteger_free(calcBigInt);
    }
}

void test_BigInteger_calcHexDigitsInteger2(){
    BigInteger *bigInt, *calcBigInt;
    ByteLink* list;
    int c = 0x12, index = 1, len = 3;
    list = ByteLink_ctor(c, NULL);

    for(;index < len; index++){
        ByteLink_addAtStart(&list, c);
    }
    bigInt = BigInteger_ctor(list, len);
    calcBigInt = BigInteger_calcHexDigitsInteger(bigInt);

    if(calcBigInt != NULL){
        if(calcBigInt->list != NULL){
            if(calcBigInt->list->b != (char)len){
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->b %c recive %c\n", (char)len, calcBigInt->list->b); 
            }
            if(calcBigInt->list->next != NULL){
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->next to be null \n"); 
            }
        } else {
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list not to be null \n"); 
        }

        if(calcBigInt->len != 1){
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->len to 1 \n");
        }
    } else {
        printf("test_BigInteger_calcHexDigitsInteger return null BigInteger\n"); 
    }

    BigInteger_free(bigInt);
    if(calcBigInt != NULL){
        BigInteger_free(calcBigInt);
    }
}

void test_BigInteger_calcHexDigitsInteger3(){
    BigInteger *bigInt, *calcBigInt;
    ByteLink* list;
    int c = 0x12, index = 1, len = 0x162;
    list = ByteLink_ctor(c, NULL);

    for(;index < len; index++){
        ByteLink_addAtStart(&list, c);
    }
    bigInt = BigInteger_ctor(list, len);
    calcBigInt = BigInteger_calcHexDigitsInteger(bigInt);

    if(calcBigInt != NULL){
        if(calcBigInt->list != NULL){
            if(calcBigInt->list->b != (char)0x62){
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->b %c recive %x\n", (char)0x62, calcBigInt->list->b); 
            }
            if(calcBigInt->list->next != NULL){
                if(calcBigInt->list->next->b != (char)0x01){
                    printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->b %c recive %x\n", (char)0x01, calcBigInt->list->next->b); 
                }
                if(calcBigInt->list->next->next != NULL){
                    printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->next to be null \n"); 
                }
            } else {
                printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list->next not to be null \n"); 
            }
        } else {
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->list not to be null \n"); 
        }

        if(calcBigInt->len != 2){
            printf("test_BigInteger_calcHexDigitsInteger expect calcBigInt->len to 1 \n");
        }
    } else {
        printf("test_BigInteger_calcHexDigitsInteger return null BigInteger\n"); 
    }

    BigInteger_free(bigInt);
    if(calcBigInt != NULL){
        BigInteger_free(calcBigInt);
    }
}



void parse_big_integer_tests(char *s) {
    BigInteger *n = BigInteger_parse(s);
    BigInteger_free(n);
}
void test_BigInteger_parse() {
    parse_big_integer_tests("F3");
    parse_big_integer_tests("000F3");
    parse_big_integer_tests("0000F3");
    parse_big_integer_tests("A");
    parse_big_integer_tests("000A");
    parse_big_integer_tests("0000A");
    parse_big_integer_tests("1F2");
    parse_big_integer_tests("0001F2");
    parse_big_integer_tests("00001F2");
    parse_big_integer_tests("21F1");
    parse_big_integer_tests("00021F1");
    parse_big_integer_tests("000021F1");
    parse_big_integer_tests("100");
    parse_big_integer_tests("000100");
    parse_big_integer_tests("0000100");
    parse_big_integer_tests("0");
    parse_big_integer_tests("00000");
    parse_big_integer_tests("000000");
    parse_big_integer_tests("2F56DC013");
    parse_big_integer_tests("0002F56DC013");
    parse_big_integer_tests("00002F56DC013");
    parse_big_integer_tests("32F56DC013");
    parse_big_integer_tests("00032F56DC013");
    parse_big_integer_tests("000032F56DC013");
}

void test_BigInteger_add1(){
    BigInteger *n1, *n2, *add;
    ByteLink* n1list, *n2list; 
    byte n1c1 = 0x12, n1c2 = 0XC9;
    byte n2c1 = 0x00;

    n1list = ByteLink_ctor(n1c2, NULL);
    ByteLink_addAtStart(&n1list, n1c1);
    n1 = BigInteger_ctor(n1list, 2);


    n2list = ByteLink_ctor(n2c1, NULL);
    n2 = BigInteger_ctor(n2list, 1);

    add = BigInteger_add(n1, n2);

    if(add != NULL){
        if(add->len == 2){
            if(add->list != NULL){
                if(add->list->b != n1c1){
                    printf("test_BigInteger_add expect add->list->b: %c recive %c\n", n1c1, add->list->b);
                } else {
                    if(add->list->next != NULL){
                        if(add->list->next->b != n1c2){
                            printf("test_BigInteger_add expect add->list->b: %c recive %c\n", n2c1, add->list->next->b);   
                        }
                    } else {
                        printf("test_BigInteger_add senond link is null\n");  
                    }
                }
            } else {
                printf("test_BigInteger_add first link is null\n"); 
            }
        } else {
            printf("test_BigInteger_add expect expect %d recive %d\n", 2, add->len); 
        }
    } else {
        printf("test_BigInteger_add return null BigInteger\n"); 
    }

    BigInteger_free(n1); BigInteger_free(n2);
    if(add != NULL){
        BigInteger_free(add);
    }
}

void test_BigInteger_add2(){
    BigInteger *n1, *n2, *add;
    ByteLink* n1list, *n2list; 
    byte n1c1 = 0xB0;
    byte n2c1 = 0xB0;

    n1list = ByteLink_ctor(n1c1, NULL);
    n1 = BigInteger_ctor(n1list, 1);


    n2list = ByteLink_ctor(n2c1, NULL);
    n2 = BigInteger_ctor(n2list, 1);

    add = BigInteger_add(n1, n2);

    if(add != NULL){
        if(add->len == 2){
            if(add->list != NULL){
                if(add->list->b != (byte)0x60){
                    printf("test_BigInteger_add expect add->list->b: %c recive %c\n", n1c1, add->list->b);
                } else {
                    if(add->list->next != NULL){
                        if(add->list->next->b != (byte)0x01){
                            printf("test_BigInteger_add expect add->list->b: %c recive %c\n", n2c1, add->list->next->b);
                        }
                    } else {
                        printf("test_BigInteger_add senond link is null\n");  
                    }
                }
            } else {
                printf("test_BigInteger_add first link is null\n"); 
            }
        } else {
            printf("test_BigInteger_add expect expect %d recive %d\n", 2, add->len); 
        }
    } else {
        printf("test_BigInteger_add return null BigInteger\n"); 
    }

    BigInteger_free(n1); BigInteger_free(n2);
    if(add != NULL){
        BigInteger_free(add);
    }
}

void test_BigInteger_and1(){
    BigInteger *n1, *n2, *and;
    ByteLink* n1list, *n2list; 
    byte n1c1 = 0x12, n1c2 = 0XC9;
    byte n2c1 = 0x00;

    n1list = ByteLink_ctor(n1c2, NULL);
    ByteLink_addAtStart(&n1list, n1c1);
    n1 = BigInteger_ctor(n1list, 2);


    n2list = ByteLink_ctor(n2c1, NULL);
    n2 = BigInteger_ctor(n2list, 1);

    and = BigInteger_and(n1, n2);

    if(and != NULL){
        if(and->len == 1){
            if(and->list != NULL){
                if(and->list->b != 0){
                    printf("test_BigInteger_and1 expect and->list->b: %c recive %c\n", 0, and->list->b);
                } else {
                    if(and->list->next != NULL){
                        printf("test_BigInteger_add2 senond link is null\n"); 
                    } 
                }
            } else {
                printf("test_BigInteger_and1 first link is null\n"); 
            }
        } else {
            printf("test_BigInteger_and1 expect expect %d recive %d\n", 1, and->len); 
        }
    } else {
        printf("test_BigInteger_and1 return null BigInteger\n"); 
    }

    BigInteger_free(n1); BigInteger_free(n2);
    if(and != NULL){
        BigInteger_free(and);
    }
}

void test_BigInteger_and2(){
    BigInteger *n1, *n2, *and;
    ByteLink* n1list, *n2list; 
    byte n1c1 = 0xB0, n1c2 = 0xC0;
    byte n2c1 = 0xB0, n2c2 = 0x0C;

    n1list = ByteLink_ctor(n1c2, NULL);
    ByteLink_addAtStart(&n1list, n1c1);
    n1 = BigInteger_ctor(n1list, 2);


    n2list = ByteLink_ctor(n2c2, NULL);
    ByteLink_addAtStart(&n2list, n2c1);
    n2 = BigInteger_ctor(n2list, 2);

    and = BigInteger_and(n1, n2);

    if(and != NULL){
        if(and->len == 1){
            if(and->list != NULL){
                if(and->list->b != (byte)0xB0){
                    printf("test_BigInteger_add2 expect add->list->b: %x recive %x\n", 0xB0, and->list->b);
                } else {
                    if(and->list->next != NULL){
                        printf("test_BigInteger_add2 senond link is null\n"); 
                    } 
                }
            } else {
                printf("test_BigInteger_add2 first link is null\n"); 
            }
        } else {
            printf("test_BigInteger_add2 expect expect %d recive %d\n", 1, and->len); 
        }
    } else {
        printf("test_BigInteger_add2 return null BigInteger\n"); 
    }

    BigInteger_free(n1); BigInteger_free(n2);
    if(and != NULL){
        BigInteger_free(and);
    }
}

void test_BigInteger_or(){
    BigInteger *n1, *n2, *or;
    ByteLink* n1list, *n2list; 
    byte n1c1 = 0xB0, n1c2 = 0xC0;
    byte n2c1 = 0x00, n2c2 = 0x01;

    n1list = ByteLink_ctor(n1c2, NULL);
    ByteLink_addAtStart(&n1list, n1c1);
    n1 = BigInteger_ctor(n1list, 2);


    n2list = ByteLink_ctor(n2c2, NULL);
    ByteLink_addAtStart(&n2list, n2c1);
    n2 = BigInteger_ctor(n2list, 2);

    or = BigInteger_or(n1, n2);

    if(or != NULL){
        if(or->len == 2){
            if(or->list != NULL){
                if(or->list->b != (byte)0xB0){
                    printf("test_BigInteger_or expect add->list->b: %x recive %x\n", 0xB0, or->list->b);
                } else {
                    if(or->list->next != NULL){
                        if(or->list->next->b != (byte)0xC1){
                            printf("test_BigInteger_or expect add->list->b: %x recive %x\n", 0xC1, or->list->next->b);
                        }
                    } else {
                        printf("test_BigInteger_or senond link not to be null\n"); 
                    }
                }
            } else {
                printf("test_BigInteger_or first link is null\n"); 
            }
        } else {
            printf("test_BigInteger_or expect expect %d recive %d\n", 1, or->len); 
        }
    } else {
        printf("test_BigInteger_or return null BigInteger\n"); 
    }

    BigInteger_free(n1); BigInteger_free(n2);
    if(or != NULL){
        BigInteger_free(or);
    }
}

void test_BigInteger_removeLeadingZeroes(){
    BigInteger* bigInt;
    byte c1 = 0x65, c2 = 0X00, c3 = 0x00;
    ByteLink* blist = ByteLink_ctor(c3, NULL);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 3);

    BigInteger_removeLeadingZeroes(bigInt);
    
    if(bigInt->len != 1){
        printf("test_BigInteger_removeLeadingZeroes expect len 1 recive %d\n", bigInt->len);
        BigInteger_free(bigInt);
        return;
    }

    if(bigInt->list == NULL){
        printf("test_BigInteger_removeLeadingZeroes expect the list not to be null\n");
        BigInteger_free(bigInt);
        return;
    }

    if(bigInt->list->b != c1){
        printf("test_BigInteger_removeLeadingZeroes expect start byte at list: %c recive %c\n",c1, bigInt->list->b);
    }

    if(bigInt->list->next != NULL){
        printf("test_BigInteger_removeLeadingZeroes expect list->next to be null\n");
    }

    BigInteger_free(bigInt);
    
}

void test_BigInteger_getlistLen(){
    BigInteger* bigInt;
    int len = -1;
    byte c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
    ByteLink* blist = ByteLink_ctor(c3, NULL);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 3);

    len = BigInteger_getlistLen(bigInt);
    if(len != 3){
        printf("test_BigInteger_getlistLen expect len 3 recive %d\n", len);
        return;
    }

    BigInteger_free(bigInt);
    
}


void test_BigInteger_duplicate(){
    BigInteger* bigInt, *dup;
    int len = -1;
    byte c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
    ByteLink* blist = ByteLink_ctor(c3, NULL);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 3);


    dup = BigInteger_duplicate(bigInt);

    if(dup != NULL){
        test_same_Bytelink(blist, dup->list, "test_BigInteger_duplicate");

        if(dup->len != bigInt->len){
            printf("test_BigInteger_duplicate expect hex len %d recive %d\n", bigInt->len, dup->len);
        }

    } else {
        printf("test_BigInteger_duplicate return null %d\n", len);
    }

    BigInteger_free(bigInt);
    BigInteger_free(dup);
    
}

void test_reverse_hex_string(){
    char *str = (char *)malloc(4);
    str[3] = 0;
    strcpy(str, "ABC");
    
    reverse_hex_string(str, strlen(str));
    if(strncmp(str, "CBA", 3) != 0){
        printf("test_reverse_hex_string expect %s recive %s\n", "CBA", str);
    }

    str[2] = 0;
    strcpy(str, "AB");
    reverse_hex_string(str, strlen(str));
    if(strncmp(str, "BA", 2) != 0){
        printf("test_reverse_hex_string expect %s recive %s\n", "BA", str);
    }

    free(str);
}

void test_BigInteger_toString(){
    BigInteger* bigInt;
    char *str;
    byte c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
    ByteLink* blist = ByteLink_ctor(c3, NULL);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 3);

    str = BigInteger_toString(bigInt);
    if(str == NULL){
        printf("test_BigInteger_print expect char * not null\n");
        return;
    }

    if(strcmp("AC912", str) != 0){
        printf("test_BigInteger_print execpt AC912 recive: %s\n", str);
    }
    free(str);
    BigInteger_free(bigInt);
}

BigInteger* mock_big_integer(byte c) {
    ByteLink *b_link = ByteLink_ctor(c, NULL);
    BigInteger *n = BigInteger_ctor(b_link, 1);
    return n;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
void test_BigIntegerStack() {
    BigInteger *n = NULL;
    int res;
    BigIntegerStack *s = BigIntegerStack_ctor(2);

    res = 1;
    res = BigIntegerStack_isFull(s); // res = 0
    res = 1;
    res = BigIntegerStack_hasAtLeastItems(s, 1); // res = 0
    BigIntegerStack_push(s, mock_big_integer(0x56));

    res = 1;
    res = BigIntegerStack_isFull(s); // res = 0;
    res = BigIntegerStack_hasAtLeastItems(s, 1); // res = 1
    res = BigIntegerStack_hasAtLeastItems(s, 2); // res = 0
    BigIntegerStack_push(s, mock_big_integer(0x10));

    res = 0;
    res = BigIntegerStack_hasAtLeastItems(s, 2); // res = 1
    res = 0;
    res = BigIntegerStack_hasAtLeastItems(s, 1); // res = 1
    res = 0;
    res = BigIntegerStack_isFull(s); // res = 1

    res = 0;
    n = BigIntegerStack_peek(s);
    res = BigIntegerStack_isFull(s); // res = 1
    res = 0;
    res = BigIntegerStack_hasAtLeastItems(s, 2); // res = 1

    n = NULL;
    n = BigIntegerStack_pop(s);
    res = 1;
    res = BigIntegerStack_isFull(s); // res = 0
    res = 1;
    res = BigIntegerStack_hasAtLeastItems(s, 2); // res = 0
    res = BigIntegerStack_hasAtLeastItems(s, 1); // res = 1
    
    n = NULL;
    n = BigIntegerStack_pop(s);
    res = 1;
    res = BigIntegerStack_isFull(s); // res = 0
    res = 1;
    res = BigIntegerStack_hasAtLeastItems(s, 2); // res = 0
    res = 1;
    res = BigIntegerStack_hasAtLeastItems(s, 1); // res = 0

    BigIntegerStack_free(s);
}
#pragma GCC diagnostic pop

int main(int argc, char **argv){
    test_set_run_settings_from_args();
    test_BigIntegerStack();
    test_stack_mng();

    test_ByteLink_ctor();
    test_ByteLink_addAtStart();
    test_ByteLink_duplicate();

    test_BigInteger_parse();

    test_BigInteger_getlistLen();
    test_BigInteger_fromInt1();
    test_BigInteger_fromInt2();
    test_BigInteger_calcHexDigitsInteger1();
    test_BigInteger_calcHexDigitsInteger2();
    test_BigInteger_calcHexDigitsInteger3();
    test_BigInteger_add1();
    test_BigInteger_add2();
    test_BigInteger_and1();
    test_BigInteger_and2();
    test_BigInteger_or();
    test_BigInteger_removeLeadingZeroes();
    test_insertByteAsHexToStringR();
    test_BigInteger_duplicate();
    test_reverse_hex_string();
    test_BigInteger_toString();
    return 0;
}