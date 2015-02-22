module functions;


///////////////////////////////////////////////////////////////////////////////

import evaluator;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

import builtin.definition;
import builtin.io;
import builtin.list;
import builtin.logic;
import builtin.math;
import builtin.system;


///////////////////////////////////////////////////////////////////////////////

struct LispFunction {
    Token parameters;
    ReferenceToken forms;
}

alias BuiltinFunction = Token function(string, ReferenceToken);

LispFunction[string] lispFunctions;
BuiltinFunction[string] builtinFunctions;


///////////////////////////////////////////////////////////////////////////////

class BuiltinException : Exception {
    this (string caller, string msg) {
        super(caller ~ ": " ~ msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class UndefinedFunctionException : Exception {
    this (string msg) {
        super(msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class NotEnoughArgumentsException : Exception {
    this (string caller) {
        super(caller ~ ": Not enough arguments");
    }
}


///////////////////////////////////////////////////////////////////////////////

class TypeMismatchException : Exception {
    this (string caller, Token token, string expectedType) {
        super(caller ~ ": " ~ token.toString() ~ " is not " ~ expectedType);
    }
}


///////////////////////////////////////////////////////////////////////////////

void initializeBuiltins () {
    builtinFunctions = builtin.definition.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.io.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.list.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.logic.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.math.addBuiltins(builtinFunctions);
    builtinFunctions = builtin.system.addBuiltins(builtinFunctions);
}

///////////////////////////////////////////////////////////////////////////////

void addFunction (string name, Token parameters, ReferenceToken forms) {
    lispFunctions[name] = LispFunction(parameters, forms);
}


///////////////////////////////////////////////////////////////////////////////

Token evaluateFunction (string name, Token parameters) {
    if (name in builtinFunctions) {
        if (!hasMore(parameters)) {
            parameters = null;
        }
        return builtinFunctions[name](name, cast(ReferenceToken)parameters);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    LispFunction fun = lispFunctions[name];
    Token funParameters = fun.parameters;
    ReferenceToken forms = fun.forms;
    Token returnValue;

    enterScope();
    while (hasMore(funParameters)) {
        if (!hasMore(parameters)) {
            throw new EvaluationException("Not enough parameters");
        }

        addVariable((cast(IdentifierToken)getFirst(funParameters)).stringValue, getFirst(parameters));
        funParameters = getRest(funParameters);
        parameters = getRest(parameters);
    }

    while (hasMore(forms)) {
        returnValue = evaluate(getFirst(forms));
        forms = getRest(forms);
    }
    leaveScope();

    return returnValue;
}