########################################
# Variables

COMPILER := dmd -c
CFLAGS   := -debug -g -gc -unittest
LINKER   := dmd -v

LISPCORE := lisp.obj exceptions.obj token.obj node.obj lispObject.obj parser.obj variables.obj evaluator.obj functions.obj
LISPBUILTINS := builtin/definition.obj builtin/io.obj builtin/list.obj builtin/logic.obj builtin/loop.obj builtin/math.obj builtin/system.obj
LISPVM := vm/bytecode.obj vm/machine.obj vm/lispmacro.obj vm/compiler.obj
OBJECT_FILES := $(LISPCORE) $(LISPBUILTINS) $(LISPVM)

########################################
# Rules

lisp: $(OBJECT_FILES)

all: lisp

% : %.obj
	$(LINKER) $^ -of$@

%.obj : %.d
	$(COMPILER) $(CFLAGS) $< -of$@

########################################

.PHONY: tidy
tidy:
	rm $(OBJECT_FILES)

.PHONY: clean
clean: tidy
	rm lisp.exe
