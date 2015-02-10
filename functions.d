module functions;

import evaluator;
import token;
import variables;

import builtin.math;
import builtin.system;

struct LispFunction {
    Token parameters;
    ReferenceToken commands;
}

alias BuiltinFunction = Token function(string, Token);

LispFunction[string] lispFunctions;
BuiltinFunction[string] builtinFunctions;

class UndefinedFunctionException : Exception {
    this (string msg) {
        super(msg);
    }
}

void initializeBuiltins () {
    builtin.math.addBuiltins(builtinFunctions);
    builtin.system.addBuiltins(builtinFunctions);
}

void addFunction (string name, Token parameters, ReferenceToken commands) {
    lispFunctions[name] = LispFunction(parameters, commands);
}

Token evaluateFunction (string name, Token parameters) {
    if (name in builtinFunctions) {
        return builtinFunctions[name](name, parameters);
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