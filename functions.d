module functions;

import evaluator;
import token;
import variables;

import builtin.list;
import builtin.logic;
import builtin.math;
import builtin.system;

struct LispFunction {
    Token parameters;
    ReferenceToken commands;
}

alias BuiltinFunction = Token function(string, ReferenceToken);

LispFunction[string] lispFunctions;
BuiltinFunction[string] builtinFunctions;

class BuiltinException : Exception {
    this (string caller, string msg) {
        super(caller ~ ": " ~ msg);
    }
}

class UndefinedFunctionException : Exception {
    this (string msg) {
        super(msg);
    }
}

class NotEnoughArgumentsException : Exception {
    this (string caller) {
        super(caller ~ ": Not enough arguments");
    }
}

class TypeMismatchException : Exception {
    this (string caller, Token token, string expectedType) {
        super(caller ~ ": " ~ token.toString() ~ " is not " ~ expectedType);
    }
}

void initializeBuiltins () {
    builtinFunctions = builtin.list.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.logic.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.math.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.system.addBuiltins(builtinFunctions);
}

void addFunction (string name, Token parameters, ReferenceToken commands) {
    lispFunctions[name] = LispFunction(parameters, commands);
}

Token evaluateFunction (string name, Token parameters) {
    if (name in builtinFunctions) {
        if (Token.isNil(parameters)) {
            parameters = null;
        }
        return builtinFunctions[name](name, cast(ReferenceToken)parameters);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    LispFunction fun = lispFunctions[name];
    Token funParameters = fun.parameters;
    ReferenceToken funCommands = fun.commands;
    Token returnValue;

    enterScope();
    while (!Token.isNil(funParameters)) {
        if (Token.isNil(parameters)) {
            throw new EvaluationException("Not enough parameters");
        }

        addVariable((cast(IdentifierToken)(cast(ReferenceToken)parameters).reference.car).stringValue, (cast(ReferenceToken)parameters).reference.car);
        funParameters = (cast(ReferenceToken)funParameters).reference.cdr;
        parameters = (cast(ReferenceToken)parameters).reference.cdr;
    }

    while (!Token.isNil(funCommands)) { 
        returnValue = evaluate(funCommands.reference.car);
        funCommands = cast(ReferenceToken)(funCommands.reference.cdr);
    }
    leaveScope();

    return returnValue;
}