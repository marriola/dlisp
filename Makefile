########################################
# Variables

COMPILER := dmd -c
CFLAGS   := -debug -g -unittest
LINKER   := dmd -v

LISPCORE := lisp.o exceptions.o token.o node.o lispObject.o parser.o variables.o evaluator.o funspec.o typespec.o functions.o util.o
LISPBUILTINS := builtin/definition.o builtin/io.o builtin/list.o builtin/logic.o builtin/loop.o builtin/math.o builtin/system.o
LISPVM := vm/bytecode.o vm/machine.o vm/lispmacro.o vm/compiler.o vm/opcode.o
OBJECT_FILES := $(LISPCORE) $(LISPBUILTINS) $(LISPVM)

########################################
# Rules

lisp: $(OBJECT_FILES)

all: lisp

% : %.o
	$(LINKER) $^ -of$@

%.o : %.d
	$(COMPILER) $(CFLAGS) $< -of$@

########################################

.PHONY: tidy
tidy:
	rm $(OBJECT_FILES)

.PHONY: clean
clean: tidy
	rm lisp.exe
