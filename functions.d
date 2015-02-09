module functions;

import evaluator;
import token;

struct LispFunction {
    Token parameters;
    Token commands;
}

LispFunction[string] functions;

class UndefinedFunctionException : Exception {
    this (string msg) {
        super(msg);
    }
}

void addFunction (string name, Token parameters, Token commands) {
    functions[name] = LispFunction(parameters, commands);
}

LispFunction getFunction (string name) {
    if (name !in functions) {
        throw new UndefinedFunctionException(name);
    }

    return functions[name];
}

Token evaluateFunction (IdentifierToken identifier, ReferenceToken parameters) {
    LispFunction fun = getFunction(identifier.stringValue);
    return new BooleanToken(false);
}