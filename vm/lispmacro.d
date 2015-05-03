module vm.lispmacro;

import exceptions;
import functions;
import lispObject;
import token;
import vm.bytecode;
import vm.compiler;
import vm.machine;


///////////////////////////////////////////////////////////////////////////////

alias MacroFunction = void function(string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value value);

struct CompilerMacro {
    string name;
    MacroFunction evaluate;
}

void macroDefun (string name, ref int nextConstant, ref ConstantPair[string] constants, ref Instruction[] code, Value value) {
    std.stdio.writef("macro %s:%s\n", name, value);

    Value[] arguments = toArray(value);
    Value identifier = arguments[0];
    Value lambdaList = arguments[1];

    Value[] forms = arguments[2 .. arguments.length];
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 3) {
        // remove documentation string
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

    if (identifier.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifier.token, "identifier");
    } else if (!lambdaList.isNil() && lambdaList.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaList.token, "reference");
    }

    string identifierString = (cast(IdentifierToken)identifier.token).stringValue;
    addFunction(identifierString, toArray(lambdaList), forms, docString);
    constants[identifierString] = ConstantPair(nextConstant, identifier);
    code ~= Instruction(Opcode.pushconst, [cast(uint)nextConstant]);
    nextConstant++;
}

CompilerMacro[string] compilerMacros;

void addMacro (string name, MacroFunction fun) {
    compilerMacros[name] = CompilerMacro(name, fun);
}

void initializeMacros () {
    addMacro("DEFUN", &macroDefun);
}