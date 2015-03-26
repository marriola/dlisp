########################################
# Variables

COMPILER := dmd
LINKER   := dmd

LISPCORE := lisp.obj exceptions.obj token.obj node.obj lispObject.obj parser.obj variables.obj evaluator.obj functions.obj
LISPBUILTINS := builtin/definition.obj builtin/io.obj builtin/list.obj builtin/math.obj builtin/system.obj builtin/logic.obj

########################################
# Rules

lisp: $(LISPCORE) $(LISPBUILTINS)

all: lisp

% : %.obj
	$(LINKER) $^ -of$@

%.obj : %.d
	$(COMPILER) -c $< -of$@

########################################

.PHONY: tidy
tidy:
	rm $(LISPCORE) $(LISPBUILTINS)

.PHONY: clean
clean: tidy
	rm lisp.exe
