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
    Value[] lambdaList;
    Value[] forms;
}

alias BuiltinFunction = Value function(string, Value[], string[Value]);

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

void addFunction (string name, Value[] lambdaList, Value[] forms) {
    lispFunctions[name] = LispFunction(lambdaList, forms);
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateDefinedFunction (LispFunction fun, Value[] parameters) {
    Value[] lambdaList = fun.lambdaList;
    Value[] forms = fun.forms;
    Value returnValue;

    if (lambdaList.length > parameters.length) {
        throw new EvaluationException("Not enough arguments");
    }

    enterScope();

    for (int i = 0; i < lambdaList.length; i++) {
        string funParameter = (cast(IdentifierToken)lambdaList[i].token).stringValue;
        Value parameter = evaluateOnce(parameters[i]);
        addVariable(funParameter, parameter);
    }

    for (int i = 0; i < forms.length; i++) {
        returnValue = evaluate(forms[i]);
    }

    leaveScope();

    return returnValue;
}


///////////////////////////////////////////////////////////////////////////////

string[Value] extractKeywordArguments (ref Value[] arguments) {
    int firstKeyword = -1;

    foreach (int i, Value arg; arguments) {
        if (arg.token.type == TokenType.constant) {
            firstKeyword = i;
            break;
        }
    }

    if (firstKeyword == -1) {
        return null;
    }

    string[Value] keywordArguments;

    arguments = arguments[0 .. firstKeyword];

    return keywordArguments;
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateFunction (string name, Value[] arguments) {
    if (name in builtinFunctions) {
        return builtinFunctions[name](name, arguments, null);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    return evaluateDefinedFunction(lispFunctions[name], arguments);
}