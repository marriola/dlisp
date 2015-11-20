module vm.compiler;

import std.algorithm;
import std.container.slist;
import std.typecons;

import exceptions;
import functions;
import lispObject;
import token;
import vm.bytecode;
import vm.lispmacro;
import vm.machine;


///////////////////////////////////////////////////////////////////////////////

abstract class LispVisitor {
    public void visit (Value value, Token token) {
        switch (token.type) {
            case TokenType.boolean:
                visit(value, cast(BooleanToken)token);
                break;

            case TokenType.reference:
                visit(value, cast(ReferenceToken)token);
                break;

            case TokenType.integer:
                visit(value, cast(IntegerToken)token);
                break;

            case TokenType.floating:
                visit(value, cast(FloatToken)token);
                break;

            case TokenType.identifier:
                visit(value, cast(IdentifierToken)token);
                break;

            case TokenType.string:
                visit(value, cast(StringToken)token);
                break;

            case TokenType.constant:
                visit(value, cast(ConstantToken)token);
                break;

            case TokenType.character:
                visit(value, cast(CharacterToken)token);
                break;

            case TokenType.fileStream:
                visit(value, cast(FileStreamToken)token);
                break;

            case TokenType.builtinFunction:
                visit(value, cast(BuiltinFunctionToken)token);
                break;

            case TokenType.compiledFunction:
                visit(value, cast(CompiledFunctionToken)token);
                break;

            default:
                assert(0);
        }
    }

    public void visit (Value value, BooleanToken token);
    public void visit (Value value, ReferenceToken token);
    public void visit (Value value, IntegerToken token);
    public void visit (Value value, FloatToken token);
    public void visit (Value value, IdentifierToken token);
    public void visit (Value value, CharacterToken token);
    public void visit (Value value, StringToken token);
    public void visit (Value value, ConstantToken token);
    public void visit (Value value, FileStreamToken token);
    public void visit (Value value, VectorToken token);
    public void visit (Value value, BuiltinFunctionToken token);
    public void visit (Value value, CompiledFunctionToken token);
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Walks through a Lisp form and builds a constants table.
 */
class ConstantsVisitor : LispVisitor {
    alias LispVisitor.visit visit;
    private Value form;
    ConstantPair[string] constants;
    int nextConstant = 0;

    private SList!bool lastWasList;
    private SList!bool firstElement;
    private bool quoted = false;
    private int level = 0;
	private CompiledFunction dummy;

    this (Value form, CompiledFunction dummy = null) {
        this.form = form;
        firstElement.insert(false);
        lastWasList.insert(true);
        quoted = false;
		this.dummy = dummy;
    }

    public void addConstant (Value value) {
        if (!value.isNil()) {
            string asString = value.toString();
            if (asString !in constants) {
                std.stdio.writef("addConstant %s %s\n", value.token.type, asString);
                constants[asString] = ConstantPair(nextConstant, value);
                nextConstant++;
            }
        }
    }

    override public void visit (Value value, BooleanToken token) {
        addConstant(value);
    }

    override public void visit (Value value, IntegerToken token) {
        addConstant(value);
    }

    override public void visit (Value value, FloatToken token) {
        addConstant(value);
    }

    override public void visit (Value value, CharacterToken token) {
        addConstant(value);
    }

    override public void visit (Value value, StringToken token) {
        addConstant(value);
    }

    override public void visit (Value value, ConstantToken token) {
        addConstant(value);
    }

    override public void visit (Value value, FileStreamToken token) {
        addConstant(value);
    }

    override public void visit (Value value, VectorToken token) {
        addConstant(value);
    }

    override public void visit (Value value, BuiltinFunctionToken token) {
        addConstant(value);
    }

    override public void visit (Value value, CompiledFunctionToken token) {
        addConstant(value);
    }


    override public void visit (Value value, IdentifierToken token) {
        if (quoted || !firstElement.front()) {
            // Don't add list initial identifier tokens in function calls. These won't be referenced.
            addConstant(value);
        }

        firstElement.removeFront();
        firstElement.insert(false);
    }

	private void evaluateArguments (string name, Value args) {
		std.stdio.writeln("evaluateArguments: " ~ name);
		Value[] argsArray = toArray(args);

		LispFunction fun;

		if (name == "DEFUN") {
			// For DEFUN we have to do something different. Instead of retrieving its
			// parameters from the table we use for other functions, we're going to
			// register the function being defined first, then use the parameters
			// generated by the CompiledFunction object to continue the process.
			if (argsArray[0].token.type != TokenType.identifier) {
				throw new TypeMismatchException("compile", argsArray[0].token, "identifier");
			}

			string funName = (cast(IdentifierToken)argsArray[0].token).stringValue;
			addFunction(funName, toArray(argsArray[1]));
			fun = getDefined(funName);

		} else {
			fun = getBuiltin(name);
			if (fun is null) {
				if (dummy !is null && dummy.name == name) {
					fun = dummy;
				} else {
					fun = getDefined(name);
				}
				if (fun is null) {
					throw new UndefinedFunctionException(name);
				}
			}
		}


		// Wrap each argument in an object that specifies whether it should be evaluated
		Evaluable[] lambdaList = annotateArguments(fun.name, fun.parameters, argsArray);

		// push lambda list elements onto the stack, evaluating where appropriate
		foreach (Evaluable argument; lambdaList) {
			if (!argument.evaluate) {
				addConstant(cast(Value)argument);
			} else {
				argument.accept(this);
			}
		}
	}

    override public void visit (Value value, ReferenceToken token) {
		// If this is inside a quote macro?
        if (quoted) {
			// Take the whole expression as a constant
            std.stdio.writeln("QUOTING:");
            addConstant(token.reference.car);
            return;
        }

        // If the first item of the list is the identifier QUOTE, add the cdr to the constants table verbatim
		level++;
        bool isFirst = lastWasList.front();
        firstElement.insert(isFirst);
        if (!quoted && isFirst && (token.reference.car.token.type == TokenType.identifier && (cast(IdentifierToken)token.reference.car.token).stringValue == "QUOTE")) {
            quoted = true;
        }

		// If this is a function call, load the parameters and decide which arguments to store as constants
		if (!quoted && isFirst && token.reference.car.token.type == TokenType.identifier) {
			firstElement.removeFront();
			firstElement.insert(false);
			evaluateArguments((cast(IdentifierToken)token.reference.car.token).stringValue, token.reference.cdr);
		} else {
			// Visit both branches
			lastWasList.insert(token.reference.car.token.type == TokenType.reference);
			if (!quoted) {
				// don't add the whole (QUOTE x) list to the constants table, just x.
				token.reference.car.accept(this);
			}
			token.reference.cdr.accept(this);
			lastWasList.removeFront();
		}

        firstElement.removeFront();
        if (level == 1) {
            quoted = false;
        }
        level--;
    }

    public ConstantPair[string] getConstantPairs () {
        form.accept(this);
        return constants;
    }

    public Value[] getConstants() {
        Value[] x = new Value[constants.length];
        foreach (ConstantPair pair; constants) {
            x[pair.index] = pair.constant;
        }

        //return std.array.array(std.algorithm.map!(x => (cast(ConstantPair)x).constant)(constants.values));
        return x;
    }
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Walks through a Lisp form and generates equivalent bytecode.
 */
class CodeEmitterVisitor : LispVisitor {
    alias LispVisitor.visit visit;
    private ConstantPair[string] constants;
    private Value form;
    private Instruction[] code;
    int nextConstant;
	private bool evaluate = true;
	private ConstantsVisitor constantsVisitor;
	private CompiledFunction dummy;

    this (ConstantsVisitor constantsVisitor, Value form, CompiledFunction dummy = null) {
		this.constantsVisitor = constantsVisitor;
        this.constants = constantsVisitor.constants;
        this.form = form;
        this.nextConstant = constantsVisitor.nextConstant;
		this.dummy = dummy;
    }

    /**
	 * Pushes a value onto the stack. If the value is not in the constants
	 * table, an exception is thrown.
	 *
	 * @param value		The value to be pushed onto the stack
	 * @param evaluate	If true, a pushvalue opcode is emitted, which causes
	 *                  the virtual machine to evaluate its value and push that
	 *                  on the stack. Otherwise, a pushconst opcode is emitted
	 *                  and only the literal value is pushed onto the stack.
	 */
	package void pushConstant (Value value, bool evaluate = false) {
        if (value.isNil()) {
            code ~= Instruction(Opcode.pushnil1);

        } else {
            string asString = value.toString();
            std.stdio.writef("pushConstant %s %s\n", value.token.type, asString);
            if (asString in constants) {
				Instruction push = Instruction(evaluate ? Opcode.pushvalue : Opcode.pushconst, [constants[asString].index]);
                //Instruction push = Instruction(Opcode.pushconst, [constants[asString].index]);
                //std.stdio.writef("%s\n", push);
                code ~= push;
            } else {
                throw new CompilerException("Can't find " ~ value.toString() ~ " in constants table");
            }
        }
    }

	package void addConstantAndPush (Value value, bool evaluate = false) {
		if (value.isNil()) {
            code ~= Instruction(Opcode.pushnil1);
		} else {
			constantsVisitor.addConstant(value);
			pushConstant(value);
		}
	}

    /**
	 * Emits bytecode to execute a function call.
	 */
	private void emitFunctionCall (string name, Value arguments) {
		Value[] argsArray = toArray(arguments);

		if (name in compilerMacros) {
			// macro looks like a function call
            compilerMacros[name].evaluate(this, name, nextConstant, constants, code, arguments, argsArray);
            return;
        }

		// retrieve function definition and choose proper opcode to emit
		uint argCount = argsArray.length;
		uint[] opcodeArgs;
        LispFunction fun;
        Instruction functionCall;

		fun = getBuiltin(name);
        if (fun !is null) {
            if (argCount == 0) {
                functionCall = Instruction(Opcode.builtin0, [cast(uint)fun.id]);
            } else if (argCount == 1) {
                functionCall = Instruction(Opcode.builtin1, [cast(uint)fun.id]);
            } else {
                functionCall = Instruction(Opcode.builtin, [cast(uint)fun.id, argCount]);
            }

        } else {
			if (dummy !is null && dummy.name == name) {
				fun = dummy;
			} else {
				fun = getDefined(name);
			}

            if (fun !is null) {
                if (argCount == 0) {
                    functionCall = Instruction(Opcode.fun0, [cast(uint)fun.id]);
                } else if (argCount == 1) {
                    functionCall = Instruction(Opcode.fun1, [cast(uint)fun.id]);
                } else {
                    functionCall = Instruction(Opcode.fun, [cast(uint)fun.id, cast(uint)argCount]);
                }
            } else {
                throw new UndefinedFunctionException(name);
            }
        }

		// Create a lambda list of the supplied arguments onto the function parameters.
		Evaluable[] lambdaList = annotateArguments(fun.name, fun.parameters, argsArray);

		// push lambda list elements onto the stack, evaluating where appropriate
		foreach_reverse (Evaluable argument; lambdaList) {
			std.stdio.writeln("arg: " ~ argument.toString());
			if (argument.evaluate) {
				evaluate = true;
				argument.accept(this);
			} else {
				pushConstant(cast(Value)argument);
			}
		}

        code ~= functionCall;
    }

    override public void visit (Value value, BooleanToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, ReferenceToken token) {
		evaluate = false;
        std.stdio.writef("ref visit %s\n", token);
        //if ((token.reference.car.token.type == TokenType.identifier && (cast(IdentifierToken)token.reference.car.token).stringValue == "QUOTE")) {
        //    std.stdio.writef("%s is quoted\n", token.reference.cdr);
        //    pushConstant(value);
        //}

        if (token.reference.car.token.type == TokenType.identifier) {
//            std.stdio.writef("function call %s\n", token.reference.car);
            emitFunctionCall((cast(IdentifierToken)token.reference.car.token).stringValue, token.reference.cdr);
        } else {
            pushConstant(value);
        }
    }

    override public void visit (Value value, IntegerToken token) {
        std.stdio.writef("visit integer %d\n", token.intValue);
        pushConstant(value);
    }

    override public void visit (Value value, FloatToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, IdentifierToken token) {
        // Don't add list initial identifier tokens in function calls. These won't be referenced.
        pushConstant(value, evaluate);
		evaluate = false;
    }

    override public void visit (Value value, CharacterToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, StringToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, ConstantToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, FileStreamToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, VectorToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, BuiltinFunctionToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, CompiledFunctionToken token) {
        pushConstant(value);
    }

    public Instruction[] compile () {
        std.stdio.writef("inner COMPILE %s\n", form);
        form.accept(this);
        return code;
    }
}


///////////////////////////////////////////////////////////////////////////////

BytecodeFunction compile (Value form, CompiledFunction dummy = null) {
    std.stdio.writef("outer COMPILE %s\n", form);

    BytecodeFunction results = new BytecodeFunction();

    results.entry = vm.machine.nextEntry;

    ConstantsVisitor constantsVisitor = new ConstantsVisitor(form, dummy);
    ConstantPair[string] constantPairs = constantsVisitor.getConstantPairs();
    results.constants = constantsVisitor.getConstants();
    std.stdio.writeln(results.constants);

    //std.stdio.writeln("code");
    CodeEmitterVisitor codeEmitterVisitor = new CodeEmitterVisitor(constantsVisitor, form, dummy);
    results.code = codeEmitterVisitor.compile();
    std.stdio.writeln(results.code);

    return results;
}    
