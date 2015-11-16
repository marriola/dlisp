module vm.machine;

import core.vararg;

import exceptions;
import functions;
import token;
import variables;
import vm.bytecode;
import vm.opcode;
import vm.compiler;

import std.container.dlist : DList;
import std.container.slist : SList;


///////////////////////////////////////////////////////////////////////////////

struct ConstantPair {
    uint index;
    Value constant;
}

class BytecodeFunction {
    int entry;
    Value[] constants;
    Instruction[] code;

	public this() {
		entry = 0;
		constants = new Value[0];
		code = new Instruction[0];
	}

	public this(int entry, Value[] constants, Instruction[] code) {
		this.entry = entry;
		this.constants = constants;
		this.code = code;
	}

    public Value evaluate () {
        run(entry);
        Value result = dataStack.front();
        dataStack.removeFront();
        return result;
    }

	public static BytecodeFunction concatenate (BytecodeFunction[] code) {
		BytecodeFunction result = new BytecodeFunction();
		int constantOffset = 0;
		int codeOffset = 0;
		result.constants = new Value[0];
		result.code = new Instruction[0];

		for (int i = 0; i < code.length; i++) {
			BytecodeFunction fun = code[i];
			result.constants ~= fun.constants;

			for (int k = 0; k < fun.code.length; k++) {
				Opcode opcode = fun.code[k].opcode;
				result.code ~= fun.code[k];

				switch (opcode) {
					case Opcode.pushconst:
					case Opcode.pushvalue:
						result.code[result.code.length - 1].operands[0] += constantOffset;
						break;

					case Opcode.jump:
					case Opcode.jumpif:
					case Opcode.jumpifnot:
						result.code[result.code.length - 1].operands[0] += codeOffset;
						break;

					default:
						break;
				}
			}

			constantOffset += fun.constants.length;
			codeOffset += fun.code.length;
		}

		return result;
	}
}

struct ProgramCounter {
    uint entry;
    uint pc;
}


///////////////////////////////////////////////////////////////////////////////

BytecodeFunction[uint] dictionary;
int nextEntry = 0;
SList!Value dataStack;
SList!ProgramCounter callStack;

void runFunction(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	int numParameters;
	if (instr.opcode == Opcode.builtin0 || instr.opcode == Opcode.fun0) {
		numParameters = 0;
	} else if (instr.opcode == Opcode.builtin1 || instr.opcode == Opcode.fun1) {
		numParameters = 1;
	} else {
		numParameters = instr.operands[1];
	}

	// Retrieve arguments from stack
	Value[] arguments;
	for (int i = 0; i < numParameters; i++) {
		if (dataStack.empty()) {
			throw new Exception("Data stack is empty!");
		}
		arguments ~= dataStack.front();
		dataStack.removeFront();
	}

	bool builtin = instr.opcode == Opcode.builtin0 ||
				   instr.opcode == Opcode.builtin1 ||
				   instr.opcode == Opcode.builtin;

	// Get the function object for the specified function.
	uint funID = instr.operands[0];
	LispFunction fun;
	if (funID in builtinTable) {
		fun = builtinTable[funID];
	} else if (funID in compiledTable) {
		fun = compiledTable[funID];
	} else {
		throw new Exception(std.conv.to!string(funID) ~ " is not a registered function");
	}

	Value returnValue;
	if (builtin) {
		// Bind its parameters and execute the function.
		enterScope(bindParameters(fun.name, fun.parameters, arguments, false));
		returnValue = (cast(BuiltinFunction)fun).hook(fun.name);
	} else {
		returnValue = evaluateCompiledFunction((cast(CompiledFunction)fun), arguments, false, fun.name);
	}

	dataStack.insert(returnValue);
	leaveScope();
}


/**
 * Executes the bytecodes in the given dictionary entry.
 */
void run (int entry) {
    // we push a program counter to the imaginary entry -1 so that when the
	// code we compiled terminates and attempts to return to it, the main loop
	// will exit.
	callStack.insert(ProgramCounter(-1));

    ProgramCounter pc = ProgramCounter(entry, 0);
    int level = 0;

    while (level >= 0) {
        //std.stdio.writef("%d level = %d, pc = %d\n", dictionary.length, level, pc.pc);
        Instruction instr = dictionary[pc.entry].code[pc.pc];
        bool returned = false;
		OpcodeFunction opfun = opcodeFunctions[instr.opcode];
		if (opfun is null) {
			throw new Exception("Invalid opcode");
		}
		opfun(instr, pc, level, returned);

        pc.pc++;
        if (pc.pc >= dictionary[pc.entry].code.length && !returned) {
            pc = callStack.front();
            callStack.removeFront();
            level--;
        }
    }
}

/**
 * Compiles a Lisp form to bytecode, adds it to the dictionary and returns
 * its entry number.
 */
int addEntry (Value form) {
    dictionary[nextEntry] = compile(form);
    return nextEntry++;
}

int addEntry (BytecodeFunction fun) {
	dictionary[nextEntry] = fun;
	return nextEntry++;
}

/**
 * Compiles a Lisp form, executes the resulting bytecode and returns its
 * result.
 */
Value evaluate (Value form) {
	std.stdio.writeln(form.toString());
    run(addEntry(form));
    Value result = dataStack.front();
    dataStack.removeFront();
    nextEntry--;
    return result;
}

/**
 * Executes precompiled bytecode and returns the result.
 */
Value run (BytecodeFunction fun) {
	std.stdio.writeln(fun.code);
	run(addEntry(fun));
    Value result = dataStack.front();
    dataStack.removeFront();
    nextEntry--;
    return result;
}
