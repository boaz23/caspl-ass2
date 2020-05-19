#include <stdio.h>
#include <stdlib.h>

extern void insertByteAsHexToStringR(char *str, int b);

void test_insertByteAsHexToStringR(){
    char *str = (char *)malloc(2);
    int c;
    str[1] = '\0';
    
    c = 0x01;
    insertByteAsHexToStringR(str,c);
    if(str[0] != (c + 48)){
        printf("test_insertByteAsHexToStringR at c=0x01");
    }
    

    c = 0x0A;
    insertByteAsHexToStringR(str,c);
    if(str[0] != (c + 55)){
        printf("test_insertByteAsHexToStringR at c=0x0A");
    }
    free(str);
}


int main(int argc, char **argv){
    test_insertByteAsHexToStringR();
    return 0;
}