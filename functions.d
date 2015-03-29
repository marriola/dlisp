module functions;


///////////////////////////////////////////////////////////////////////////////

import std.algorithm;


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

struct PairedArgument {
    string name;
    Value defaultValue;
}

struct LispFunction {
    string[] requiredArguments;
    PairedArgument[] optionalArguments;
    PairedArgument[] keywordArguments;
    string restArgument;
    PairedArgument[] auxArguments;

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
    PairedArgument[] optionalArguments = extractKeywordArguments(lambdaList, "&optional");
    PairedArgument[] keywordArguments = extractKeywordArguments(lambdaList, "&key");
    string restArgument = extractRestArgument(lambdaList);
    PairedArgument[] auxArguments = extractKeywordArguments(lambdaList, "&aux");
    string[] requiredArguments = reduce!((result, x) => result ~= (cast(IdentifierToken)x.token).stringValue)(new string[0], lambdaList);
    if (requiredArguments.length == 0) {
        requiredArguments = null;
    }

    lispFunctions[name] = LispFunction(requiredArguments, optionalArguments, keywordArguments, restArgument, auxArguments, forms);
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

string extractRestArgument (ref Value[] lambdaList) {
    int firstArgument = -1;

    // look for the &key keyword, exit if not found
    foreach (int i, Value arg; lambdaList) {
        if ((cast(IdentifierToken)arg.token).stringValue == "&rest") {
            if (i == lambdaList.length - 1) {
                throw new Exception("Missing &rest element in lambda list");
            } else if (lambdaList[i + 1].token.type != TokenType.identifier) {
                throw new InvalidLambdaListElementException(lambdaList[i + 1].token, "identifier");
            }

            return (cast(IdentifierToken)lambdaList[i + 1].token).stringValue;
        }
    }

    return null;
}

///////////////////////////////////////////////////////////////////////////////

PairedArgument[] extractKeywordArguments (ref Value[] lambdaList, string keyword) {
    int firstArgument = -1;

    // look for the &key keyword, exit if not found
    foreach (int i, Value arg; lambdaList) {
        if ((cast(IdentifierToken)arg.token).stringValue == keyword) {
            firstArgument = i + 1;
            break;
        }
    }
    
    if (firstArgument == -1) {
        return null;
    }

    PairedArgument[] keywordArguments = new PairedArgument[0];
    foreach (Value arg; lambdaList[firstArgument .. lambdaList.length]) {
        // keep going until we reach another keyword
        if ((cast(IdentifierToken)arg.token).stringValue[0] == '&') {
            break;
        }

        if (arg.token.type == TokenType.reference) {
            Value argumentName = getFirst(arg);
            Value argumentValue = evaluateOnce(getFirst(getRest(arg)));
            if (argumentName.token.type != TokenType.identifier) {
                throw new InvalidLambdaListElementException(argumentName.token, "expected identifier");
            }
            keywordArguments ~= PairedArgument((cast(IdentifierToken)argumentName.token).stringValue, argumentValue);

        } else if (arg.token.type == TokenType.identifier) {
            keywordArguments ~= PairedArgument((cast(IdentifierToken)arg.token).stringValue, null);

        } else {
            throw new InvalidLambdaListElementException(arg.token, "expected identifier or list");
        }
    }

    lambdaList = lambdaList[0 .. firstArgument - 1];
    return keywordArguments.length == 0 ? null : keywordArguments;
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