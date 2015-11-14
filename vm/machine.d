module vm.machine;

import exceptions;
import functions;
import token;
import variables;
import vm.bytecode;
import vm.compiler;

import std.container.dlist : DList;
import std.container.slist : SList;


///////////////////////////////////////////////////////////////////////////////

struct ConstantPair {
    uint index;
    Value constant;
}

struct BytecodeFunction {
    int entry;
    Value[] constants;
    Instruction[] code;

    Value evaluate () {
        run(entry);
        Value result = dataStack.front();
        dataStack.removeFront();
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
		//                    std.stdio.writef("argument %s\n", dataStack.front());
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
		throw new Exception(std.conv.to!string(funID) ~ " is not a function");
	}

	// Bind its parameters and execute the function.
	enterScope(bindParameters(fun.name, fun.parameters, arguments, false));
	std.stdio.writef("%s %x\n", fun.name, fun.id);
	Value returnValue;
	if (builtin)
		returnValue = (cast(BuiltinFunction)fun).hook(fun.name);
	else
		returnValue = evaluateCompiledFunction((cast(CompiledFunction)fun), arguments, fun.name);

	dataStack.insert(returnValue);
	leaveScope();
}

void runPushnil1(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	dataStack.insert(Value.nil());
}

void runPushnil(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	for (int i = 0; i < instr.operands[0]; i++) {
		dataStack.insert(Value.nil());
	}
}

void runPushconst(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	BytecodeFunction fun = dictionary[pc.entry];
	Value[] constants = fun.constants;
	int operand = instr.operands[0];
	dataStack.insert(constants[operand].copy());
}

void runPushvalue(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	Value constant = dictionary[pc.entry].constants[instr.operands[0]];
	if (constant.token.type != TokenType.identifier) {
		throw new VirtualMachineException(constant.toString() ~ " is not an identifier");
	} else {
		dataStack.insert(getVariable((cast(IdentifierToken)constant.token).stringValue));
	}
}

void runJump(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	pc.pc = instr.operands[0] - 1;
	std.stdio.writef("jump to %x\n", pc.pc);
}

void runJumpif(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	Value value = dataStack.front();
	dataStack.removeFront();
	if (!value.isNil()) {
		pc.pc = instr.operands[0] - 1;
		std.stdio.writef("jumpif to %x\n", pc.pc);
	}
}

void runJumpifnot(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	Value value = dataStack.front();
	dataStack.removeFront();
	if (value.isNil()) {
		pc.pc = instr.operands[0] - 1;
		std.stdio.writef("jumpifnot to %x\n", pc.pc);
	}
}

void runRet(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
	pc = callStack.front();
	callStack.removeFront();
	level--;
	returned = true;
}

alias OpcodeFunction = void function(Instruction, ref ProgramCounter, ref int, ref bool);

OpcodeFunction[ubyte] opcodeFunctions;

void initializeVm() {
	opcodeFunctions[Opcode.builtin0] = &runFunction;
	opcodeFunctions[Opcode.builtin1] = &runFunction;
	opcodeFunctions[Opcode.builtin] = &runFunction;
	opcodeFunctions[Opcode.fun0] = &runFunction;
	opcodeFunctions[Opcode.fun1] = &runFunction;
	opcodeFunctions[Opcode.fun] = &runFunction;
	opcodeFunctions[Opcode.pushnil1] = &runPushnil1;
	opcodeFunctions[Opcode.pushnil] = &runPushnil;
	opcodeFunctions[Opcode.pushconst] = &runPushconst;
	opcodeFunctions[Opcode.pushvalue] = &runPushvalue;
	opcodeFunctions[Opcode.jump] = &runJump;
	opcodeFunctions[Opcode.jumpif] = &runJumpif;
	opcodeFunctions[Opcode.jumpifnot] = &runJumpifnot;
	opcodeFunctions[Opcode.ret] = &runRet;
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