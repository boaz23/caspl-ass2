CC			:=	gcc
CC_FLAGS	:=	-Wall -g -m32
ASM			:=	nasm
ASM_FLAGS	:=	-f elf -g -w+all
LINK		:=	ld
LINK_FLAGS	:=	-g -m elf_i386

SRC_DIR		:=	.
OBJ_DIR		:=	.
LIST_DIR	:=	.
BIN_DIR		:=	.

TEST_DIR	:= test

PRG_NAME	:= calc
OBJECTS		:= $(OBJ_DIR)/$(PRG_NAME).o

all: $(PRG_NAME)

test_c:
	$(ASM) $(ASM_FLAGS) -DTEST_C $(SRC_DIR)/calc.s -o $(TEST_DIR)/calc.o -l $(TEST_DIR)/calc-test.lst
	$(CC) $(CC_FLAGS) -c $(TEST_DIR)/test.c -o $(TEST_DIR)/test.o
	$(CC) $(CC_FLAGS) $(TEST_DIR)/test.o $(TEST_DIR)/calc.o -o $(TEST_DIR)/test

$(PRG_NAME): $(OBJECTS)
	$(CC) -o $(PRG_NAME) $(CC_FLAGS) $(OBJECTS)

# .c/.s compile rulesint
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) -c $(CC_FLAGS) $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	$(ASM) $(ASM_FLAGS) $< -o $@ -l $(subst .o,.lst,$(subst $(OBJ_DIR),$(LIST_DIR),$@))

clean:
	rm -f $(BIN_DIR)/$(PRG_NAME)\
		  $(BIN_DIR)/*.bin\
		  $(OBJ_DIR)/*.o\
		  $(LIST_DIR)/*.lst\
		  test/test test/*.o test/*.lst
