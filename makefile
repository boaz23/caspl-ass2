CC			:=	gcc
CC_FLAGS	:=	-Wall -g -m32
ASM			:=	nasm
ASM_FLAGS	:=	-f elf -g -w+all
LINK		:=	ld
LINK_FLAGS	:= -g -m elf_i386

SRC_DIR		:=	.
OBJ_DIR		:=	.
LIST_DIR	:=	.
BIN_DIR		:=	.

PRG_NAME	:= calc
OBJECTS		:= $(OBJ_DIR)/$(PRG_NAME).o

all: $(PRG_NAME)

$(PRG_NAME): $(OBJECTS)
	$(CC) -o $(PRG_NAME) $(CC_FLAGS) $(OBJECTS)

# .c/.s compile rulesint
$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c
	$(CC) -c $(CC_FLAGS) $< -o $@

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s
	$(ASM) $(ASM_FLAGS) $< -o $@ -l $(subst .o,.lst,$(subst $(OBJ_DIR),$(LIST_DIR),$@))

clean:
	rm -f $(BIN_DIR)/*.bin $(OBJ_DIR)/*.o $(LIST_DIR)/*.lst
