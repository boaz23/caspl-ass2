#include <stdio.h>
#include <stdlib.h>
#include  <string.h>

/* ByteLink */
typedef struct ByteLink{
    char b;
    struct ByteLink* next;
} ByteLink;

extern ByteLink* ByteLink_ctor(char b, ByteLink* next);

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
}

/* BigInterger */
extern void insertByteAsHexToStringR(char *str, int b);
extern void reverse_hex_string(char *str, int len);

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

/* ByteLink */


int main(int argc, char **argv){
    test_ByteLink_ctor();

    test_insertByteAsHexToStringR();
    test_reverse_hex_string();
    return 0;
}