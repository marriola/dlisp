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
    Token[] parameters;
    Token[] forms;
}

alias BuiltinFunction = Token function(string, Token[]);

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

void addFunction (string name, Token[] parameters, Token[] forms) {
    lispFunctions[name] = LispFunction(parameters, forms);
}


///////////////////////////////////////////////////////////////////////////////

Token evaluateFunction (string name, Token[] parameters) {
    if (name in builtinFunctions) {
        //if (!hasMore(parameters)) {
        //    parameters = null;
        //}
        return builtinFunctions[name](name, parameters);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    LispFunction fun = lispFunctions[name];
    Token[] funParameters = fun.parameters;
    Token[] forms = fun.forms;
    Token returnValue;

    if (funParameters.length > parameters.length) {
        throw new EvaluationException("Not enough arguments");
    }

    enterScope();
    for (int i = 0; i < funParameters.length; i++) {
        string funParameter = (cast(IdentifierToken)funParameters[i]).stringValue;
        Token parameter = evaluate(parameters[i]);
        addVariable(funParameter, parameter);
    }

    //while (hasMore(funParameters)) {
    //    if (!hasMore(parameters)) {
    //        throw new EvaluationException("Not enough parameters");
    //    }

    //    string funParameter = (cast(IdentifierToken)getFirst(funParameters)).stringValue;
    //    Token parameter = evaluate(getFirst(parameters));

    //    addVariable(funParameter, parameter);
    //    funParameters = getRest(funParameters);
    //    parameters = getRest(parameters);
    //}

    //while (hasMore(forms)) {
    //    Token form = getFirst(forms);
    //    returnValue = evaluate(form);
    //    forms = getRest(forms);
    //}

    for (int i = 0; i < forms.length; i++) {
        returnValue = evaluate(forms[i]);
    }
    leaveScope();

    return returnValue;
}