module vm.opcode;

import exceptions;
import functions;
import token;
import variables;
import vm.bytecode;
import vm.machine;

void runFunction(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
    int numParameters;

    switch (instr.opcode) {
    case Opcode.builtin0:
    case Opcode.fun0:
    case Opcode.tailcall0:
	numParameters = 0;
	break;

    case Opcode.builtin1:
    case Opcode.fun1:
    case Opcode.tailcall1:
	numParameters = 1;
	break;

    default:
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

    bool isBuiltin = instr.opcode == Opcode.builtin0 ||
	instr.opcode == Opcode.builtin1 ||
	instr.opcode == Opcode.builtin;

    bool isTailCall = instr.opcode == Opcode.tailcall0 ||
	instr.opcode == Opcode.tailcall1 ||
	instr.opcode == Opcode.tailcall;

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
    if (isBuiltin) {
	// Bind its parameters and execute the function.
	enterScope(bindParameters(fun.name, fun.parameters, arguments, false));
	returnValue = (cast(BuiltinFunction)fun).hook(fun.name);
	leaveScope();
    } else if (isTailCall) {
	enterScope(bindParameters(fun.name, fun.parameters, arguments.dup, false), true);
	pc.pc = -1;
    } else {
	returnValue = evaluateCompiledFunction((cast(CompiledFunction)fun), arguments, false, fun.name);
    }

    dataStack.insert(returnValue);
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
    std.stdio.writeln("pushconst: " ~ constants[operand].toString());
    dataStack.insert(constants[operand].copy());
}

void runPushvalue(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
    Value constant = dictionary[pc.entry].constants[instr.operands[0]];
    if (constant.token.type == TokenType.identifier) {
	dataStack.insert(getVariable((cast(IdentifierToken)constant.token).stringValue));
    } else {
	dataStack.insert(evaluate(constant));
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

void runStore(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
    BytecodeFunction fun = dictionary[pc.entry];
    int constantId = instr.operands[0];
    Value identifierToken = fun.constants[constantId];
    string identifier;

    if (identifierToken.token.type == TokenType.identifier) {
        identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    } else {
        throw new TypeMismatchException("runStore", identifierToken.token, "identifier");
    }

    Value value = dataStack.front();
    dataStack.removeFront();
    addVariable(identifier, value, 0);
    dataStack.insert(identifierToken);
}

void runLoad(Instruction instr, ref ProgramCounter pc, ref int level, ref bool returned) {
    BytecodeFunction fun = dictionary[pc.entry];
    int constantId = instr.operands[0];
    Value identifierToken = fun.constants[constantId];
    string identifier;

    if (identifierToken.token.type == TokenType.identifier) {
        identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    } else {
        throw new TypeMismatchException("runLoad", identifierToken.token, "identifier");
    }

    dataStack.insert(getVariable(identifier));
}

alias OpcodeFunction = void function(Instruction, ref ProgramCounter, ref int, ref bool);

OpcodeFunction[ubyte] opcodeFunctions;

void initializeOpcodeTable() {
    opcodeFunctions[Opcode.builtin0] = &runFunction;
    opcodeFunctions[Opcode.builtin1] = &runFunction;
    opcodeFunctions[Opcode.builtin] = &runFunction;
    opcodeFunctions[Opcode.fun0] = &runFunction;
    opcodeFunctions[Opcode.fun1] = &runFunction;
    opcodeFunctions[Opcode.fun] = &runFunction;
    opcodeFunctions[Opcode.tailcall0] = &runFunction;
    opcodeFunctions[Opcode.tailcall1] = &runFunction;
    opcodeFunctions[Opcode.tailcall] = &runFunction;
    opcodeFunctions[Opcode.pushnil1] = &runPushnil1;
    opcodeFunctions[Opcode.pushnil] = &runPushnil;
    opcodeFunctions[Opcode.pushconst] = &runPushconst;
    opcodeFunctions[Opcode.pushvalue] = &runPushvalue;
    opcodeFunctions[Opcode.jump] = &runJump;
    opcodeFunctions[Opcode.jumpif] = &runJumpif;
    opcodeFunctions[Opcode.jumpifnot] = &runJumpifnot;
    opcodeFunctions[Opcode.ret] = &runRet;
    opcodeFunctions[Opcode.store] = &runStore;
    opcodeFunctions[Opcode.load] = &runLoad;
}
