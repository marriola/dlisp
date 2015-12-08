########################################
# Variables

COMPILER := gdc -c

CFLAGS   := # -debug -g -gc -unittest

LINKER   := gdc -v

LISPCORE := lisp.obj exceptions.obj token.obj node.obj lispObject.obj parser.obj variables.obj evaluator.obj functions.obj
LISPBUILTINS := builtin/definition.obj builtin/io.obj builtin/list.obj builtin/logic.obj builtin/loop.obj builtin/math.obj builtin/system.obj

########################################
# Rules

lisp: $(LISPCORE) $(LISPBUILTINS)

all: lisp

% : %.obj
	$(LINKER) $^ -o $@

%.obj : %.d
	$(COMPILER) $(CFLAGS) $< -o $@

########################################

.PHONY: tidy
tidy:
	rm $(LISPCORE) $(LISPBUILTINS)

.PHONY: clean
clean: tidy
	rm lisp.exe
