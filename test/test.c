#include <stdio.h>
#include <stdlib.h>
#include  <string.h>

extern void set_run_settings_from_args(int argc, char *argv[]);
extern int is_arg_debug(char *arg);
extern int try_parse_arg_hex_string_num(char *arg);
extern char* str_last_char(char *s);

extern int DebugMode;
extern int NumbersStackCapacity;

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
        "filler", "-d"
    };
    test_set_run_settings_from_args_args(2, s);
}

/* ByteLink */
typedef struct ByteLink{
    char b;
    struct ByteLink* next;
} __attribute__((packed, aligned(1))) ByteLink;

extern ByteLink* ByteLink_ctor(char b, ByteLink* next);
extern void ByteLink_addAtStart(ByteLink** link, char b);
extern char * ByteLink_freeList(ByteLink* list);
extern ByteLink* ByteLink_duplicate(ByteLink* list);

void test_same_Bytelink(ByteLink *current, ByteLink *dupCurrent, char *funcName);

void test_ByteLink_ctor(){
    char c = 65; //A
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
    char c1 = 0x0A, c2 = 0XC9;
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

void test_ByteLink_duplicate(){
    char c1 = 65, c2 = 99; //A, c
    ByteLink* bl = ByteLink_ctor(c1, NULL);
    ByteLink* dup;
    int bloop = 0;

    ByteLink_addAtStart(&bl, c2);

    dup = ByteLink_duplicate(bl);

    test_same_Bytelink(bl, dup, "test_ByteLink_duplicate");

    ByteLink_freeList(bl);
    ByteLink_freeList(dup);
}

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

/* BigInterger */
typedef struct BigInteger{
    struct ByteLink* list;
    int len;
} BigInteger;

extern BigInteger* BigInteger_ctor(ByteLink *link, int LenHexDigits);
extern void BigInteger_free(BigInteger *link);
extern BigInteger* BigInteger_duplicate(BigInteger *link);

extern int BigInteger_getlistLen(BigInteger *bigInteger);
extern BigInteger* BigInteger_add(BigInteger *n1, BigInteger *n2);
extern BigInteger* BigInteger_and(BigInteger *n1, BigInteger *n2);
extern BigInteger* BigInteger_or(BigInteger *n1, BigInteger *n2);
extern void BigInteger_removeLeadingZeroes(BigInteger *bigInteger);
extern void insertByteAsHexToStringR(char *str, int b);
extern void reverse_hex_string(char *str, int len);
extern char *BigInteger_toString(BigInteger *link);

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

void test_BigInteger_add1(){
    BigInteger *n1, *n2, *add;
    ByteLink* n1list, *n2list; 
    char n1c1 = 0x12, n1c2 = 0XC9;
    char n2c1 = 0x00;

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
    char n1c1 = 0xB0;
    char n2c1 = 0xB0;

    n1list = ByteLink_ctor(n1c1, NULL);
    n1 = BigInteger_ctor(n1list, 1);


    n2list = ByteLink_ctor(n2c1, NULL);
    n2 = BigInteger_ctor(n2list, 1);

    add = BigInteger_add(n1, n2);

    if(add != NULL){
        if(add->len == 2){
            if(add->list != NULL){
                if(add->list->b != (char)0x60){
                    printf("test_BigInteger_add expect add->list->b: %c recive %c\n", n1c1, add->list->b);
                } else {
                    if(add->list->next != NULL){
                        if(add->list->next->b != (char)0x01){
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
    char n1c1 = 0x12, n1c2 = 0XC9;
    char n2c1 = 0x00;

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
    char n1c1 = 0xB0, n1c2 = 0xC0;
    char n2c1 = 0xB0, n2c2 = 0x0C;

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
                if(and->list->b != (char)0xB0){
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
    char n1c1 = 0xB0, n1c2 = 0xC0;
    char n2c1 = 0x00, n2c2 = 0x01;

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
                if(or->list->b != (char)0xB0){
                    printf("test_BigInteger_or expect add->list->b: %x recive %x\n", 0xB0, or->list->b);
                } else {
                    if(or->list->next != NULL){
                        if(or->list->next->b != (char)0xC1){
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
    char c1 = 0x65, c2 = 0X00, c3 = 0x00;
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
    char c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
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
    char c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
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
    char c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
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



/* ByteLink */


int main(int argc, char **argv){
    test_set_run_settings_from_args();
    test_stack_mng();

    test_ByteLink_ctor();
    test_ByteLink_addAtStart();
    test_ByteLink_duplicate();

    test_BigInteger_getlistLen();
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