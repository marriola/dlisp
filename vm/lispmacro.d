module vm.lispmacro;

import exceptions;
import functions;
import lispObject;
import token;
import vm.bytecode;
import vm.compiler;
import vm.machine;


///////////////////////////////////////////////////////////////////////////////

alias MacroFunction = void function(CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments);

struct CompilerMacro {
    string name;
    MacroFunction evaluate;
}

void macroDefun (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
    Value identifier = arguments[0];
    Value lambdaList = arguments[1];

    Value formsReference = getItemReference(argsValue, 2);
    Value[] forms = arguments[2 .. arguments.length];
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 3) {
        // remove documentation string
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
        formsReference = getItemReference(argsValue, 3);
    }

    if (identifier.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifier.token, "identifier");
    } else if (!lambdaList.isNil() && lambdaList.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaList.token, "reference");
    }

	currentFunction.insert((cast(IdentifierToken)identifier.token).stringValue);
    string identifierString = (cast(IdentifierToken)identifier.token).stringValue;
	getDefined(identifierString).compile(forms);
	//addFunction(identifierString, toArray(lambdaList), forms, docString, true);
	currentFunction.removeFront();

	uint funConstant;
	ConstantPair* constant = identifierString in constants;
	if (constant is null) {
		constants[identifierString] = ConstantPair(nextConstant, identifier);
		funConstant = cast(uint)nextConstant;
		nextConstant++;
	} else {
		funConstant = constant.index;
	}

    //addEntry(formsReference);

    code ~= Instruction(Opcode.pushconst, [cast(uint)funConstant]);
}

void macroLambda (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
	Value[] lambdaList = toArray(arguments[0]);
	Value[] forms = arguments[1..$];
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 1) {
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

	Token lambda = new CompiledFunctionToken(lambdaList, forms, docString);
	visitor.addConstantAndPush(new Value(lambda));
}

void macroIf (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
    if (arguments.length < 2) {
        throw new NotEnoughArgumentsException("macroIf");
    }

    Value test = arguments[0];
    Value thenStatement = arguments[1];
    Value elseStatement = arguments.length > 2 ? arguments[2] : Value.nil();

    test.accept(visitor);

    Instruction* op = new Instruction(Opcode.jumpifnot, [0]);
    code ~= *op;
    thenStatement.accept(visitor);
    op.operands[0] = code.length + 1;

    op = new Instruction(Opcode.jump, [0]);
    code ~= *op;
    elseStatement.accept(visitor);
    op.operands[0] = code.length;
}

void macroCond (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
	if (arguments.length < 1) {
		throw new NotEnoughArgumentsException("macroCond");
	}

	foreach (Value branch; arguments) {
		Value[] branchAsArray = toArray(branch);
		Value test = branchAsArray[0];
		Value[] forms = branchAsArray[1..$];

		// Emit branch test and jump around if test is not satisfied.
		test.accept(visitor);
		Instruction *op = new Instruction(Opcode.jumpifnot, [0]);
		code ~= *op;

		// Emit the body of the branch
		foreach (Value form; forms) {
			form.accept(visitor);
		}

		// Substitute the position of the instruction just atfer the body for the parameter in the jmpifnot instruction above.
		op.operands[0] = code.length;
	}
}

void macroQuote (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
	visitor.pushConstant(arguments[0]);
}

void macroProgn (CodeEmitterVisitor visitor, string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value argsValue, Value[] arguments) {
	foreach (Value form; arguments) {
		form.accept(visitor);
	}
}

CompilerMacro[string] compilerMacros;

void addMacro (string name, MacroFunction fun) {
    compilerMacros[name] = CompilerMacro(name, fun);
}

void initializeMacros () {
    addMacro("DEFUN", &macroDefun);
	addMacro("LAMBDA", &macroLambda);
    addMacro("IF", &macroIf);
	addMacro("COND", &macroCond);
    addMacro("QUOTE", &macroQuote);
    addMacro("PROGN", &macroProgn);
}