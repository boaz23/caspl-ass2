#include <stdio.h>

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

int main(int argc, char *argv[]) {
    test_set_run_settings_from_args();
    test_stack_mng();
    return 0;
}