#include <stdio.h>
#include <stdlib.h>
#include  <string.h>

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
    int hexDigits;
} BigInteger;

extern BigInteger* BigInteger_ctor(ByteLink *link, int LenHexDigits);
extern void BigInteger_free(BigInteger *link);
extern BigInteger* BigInteger_duplicate(BigInteger *link);

extern int BigInteger_getlistLen(BigInteger *bigInteger);
extern void insertByteAsHexToStringR(char *str, int b);
extern void reverse_hex_string(char *str, int len);
extern char *BigInteger_print(BigInteger *link);

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

void test_BigInteger_getlistLen(){
    BigInteger* bigInt;
    int len = -1;
    char c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
    ByteLink* blist = ByteLink_ctor(c1, NULL);
    ByteLink_addAtStart(&blist,c3);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 5);

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
    ByteLink* blist = ByteLink_ctor(c1, NULL);
    ByteLink_addAtStart(&blist,c3);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 5);


    dup = BigInteger_duplicate(bigInt);

    if(dup != NULL){
        test_same_Bytelink(blist, dup->list, "test_BigInteger_duplicate");

        if(dup->hexDigits != bigInt->hexDigits){
            printf("test_BigInteger_duplicate expect hex len %d recive %d\n", bigInt->hexDigits, dup->hexDigits);
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

void test_BigInteger_print(){
    BigInteger* bigInt;
    char *str;
    char c1 = 0x12, c2 = 0XC9, c3 = 0x0A;
    ByteLink* blist = ByteLink_ctor(c1, NULL);
    ByteLink_addAtStart(&blist,c3);
    ByteLink_addAtStart(&blist,c2);
    ByteLink_addAtStart(&blist,c1);
    bigInt = BigInteger_ctor(blist, 5);

    str = BigInteger_print(bigInt);
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
    test_ByteLink_ctor();
    test_ByteLink_addAtStart();
    test_ByteLink_duplicate();

    test_BigInteger_getlistLen();
    test_insertByteAsHexToStringR();
    test_BigInteger_duplicate();
    test_reverse_hex_string();
    test_BigInteger_print();
    return 0;
}