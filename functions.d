module functions;


///////////////////////////////////////////////////////////////////////////////

import evaluator;
import exceptions;
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
    Value[] parameters;
    Value[] forms;
}

alias BuiltinFunction = Value function(string, Value[]);

LispFunction[string] lispFunctions;
BuiltinFunction[string] builtinFunctions;


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

void addFunction (string name, Value[] parameters, Value[] forms) {
    lispFunctions[name] = LispFunction(parameters, forms);
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateFunction (string name, Value[] parameters) {
    if (name in builtinFunctions) {
        return builtinFunctions[name](name, parameters);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    LispFunction fun = lispFunctions[name];
    Value[] funParameters = fun.parameters;
    Value[] forms = fun.forms;
    Value returnValue;

    if (funParameters.length > parameters.length) {
        throw new EvaluationException("Not enough arguments");
    }

    enterScope();

    for (int i = 0; i < funParameters.length; i++) {
        string funParameter = (cast(IdentifierToken)funParameters[i].token).stringValue;
        Value parameter = evaluateOnce(parameters[i]);
        addVariable(funParameter, parameter);
    }

    for (int i = 0; i < forms.length; i++) {
        returnValue = evaluate(forms[i]);
    }

    leaveScope();

    return returnValue;
}