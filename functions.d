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
    Value[] lambdaList;
    string[] requiredArguments;
    PairedArgument[] optionalArguments;
    string restArgument;
    PairedArgument[] keywordArguments;
    PairedArgument[] auxArguments;

    Value[] forms;
}

alias BuiltinFunction = Value function(string, Value[], Value[string]);

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

string extractRestArgument (ref Value[] lambdaList) {
    int firstArgument = -1;

    // look for the &key keyword, exit if not found
    foreach (int i, Value arg; lambdaList) {
        if (arg.token.type == TokenType.identifier && (cast(IdentifierToken)arg.token).stringValue == "&REST") {
            if (i == lambdaList.length - 1) {
                throw new Exception("Missing &rest element in lambda list");
            } else if (lambdaList[i + 1].token.type != TokenType.identifier) {
                throw new InvalidLambdaListElementException(lambdaList[i + 1].token, "identifier");
            }

            string restArgument = (cast(IdentifierToken)lambdaList[i + 1].token).stringValue;
            lambdaList = remove(lambdaList, i, i + 1);

            return restArgument;
        }
    }

    return null;
}


///////////////////////////////////////////////////////////////////////////////

PairedArgument[] extractKeywordArguments (ref Value[] lambdaList, string keyword) {
    int firstArgument = -1;
    int lastArgument = lambdaList.length;

    // look for the given keyword, exit if not found
    foreach (int i, Value arg; lambdaList) {
        if (arg.token.type == TokenType.identifier && (cast(IdentifierToken)arg.token).stringValue == keyword) {
            firstArgument = i + 1;
            break;
        }
    }
    
    if (firstArgument == -1) {
        return null;
    }

    PairedArgument[] keywordArguments = new PairedArgument[0];
    foreach (int i, Value arg; lambdaList[firstArgument .. lambdaList.length]) {
        // keep going until we reach another keyword
        if (arg.token.type == TokenType.identifier && (cast(IdentifierToken)arg.token).stringValue[0] == '&') {
            lastArgument = i + firstArgument;
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

    lambdaList = lambdaList[0 .. firstArgument - 1] ~ lambdaList[lastArgument .. lambdaList.length];
    return keywordArguments.length == 0 ? null : keywordArguments;
}


///////////////////////////////////////////////////////////////////////////////

LispFunction processFunctionDefinition (Value[] lambdaList, Value[] forms) {
    Value[] oldLambdaList = lambdaList[];
    PairedArgument[] optionalArguments = extractKeywordArguments(lambdaList, "&OPTIONAL");
    PairedArgument[] keywordArguments = extractKeywordArguments(lambdaList, "&KEY");
    string restArgument = extractRestArgument(lambdaList);
    PairedArgument[] auxArguments = extractKeywordArguments(lambdaList, "&AUX");
    string[] requiredArguments = reduce!((result, x) => result ~= (cast(IdentifierToken)x.token).stringValue)(new string[0], lambdaList);
    if (requiredArguments.length == 0) {
        requiredArguments = null;
    }

    return LispFunction(lambdaList, requiredArguments, optionalArguments, restArgument, keywordArguments, auxArguments, forms);
}


///////////////////////////////////////////////////////////////////////////////

void addFunction (string name, Value[] lambdaList, Value[] forms) {
    lispFunctions[name] = processFunctionDefinition(lambdaList, forms);
}


///////////////////////////////////////////////////////////////////////////////

void bindParameters (string name, LispFunction fun, Value[] parameters) {
    // extract and bind required arguments
    foreach (string requiredArg; fun.requiredArguments) {
        if (parameters.length == 0) {
            throw new Exception("Too few arguments given to " ~ name);
        }

        addVariable(requiredArg, evaluateOnce(parameters[0]));
        parameters = remove(parameters, 0);
    }

    // extract and bind optional arguments
    foreach (PairedArgument optArg; fun.optionalArguments) {
        Value value;
        if (parameters.length == 0) {
            // use default value if we're out of arguments
            value = optArg.defaultValue is null ? new Value(new BooleanToken(false)) : optArg.defaultValue;
        } else {
            // otherwise use and remove the next one
            value = parameters[0];
            parameters = remove(parameters, 0);
        }

        addVariable(optArg.name, evaluateOnce(value));
    }

    // if fun wants a rest parameter, grab all remaining parameters
    if (fun.restArgument !is null) {
        Value restParameters;

        if (parameters.length == 0) {
            restParameters = new Value(new BooleanToken(false));

        } else {
            restParameters = Token.makeReference(evaluateOnce(parameters[0]));
            for (int i = 1; i < parameters.length; i++) {
                (cast(ReferenceToken)restParameters.token).append(evaluateOnce(parameters[i]));
            }
        }

        addVariable(fun.restArgument, restParameters);
    }

    // extract and bind keyword arguments
    foreach (PairedArgument kwArg; fun.keywordArguments) {
        Value value;
        // find matching keyword argument in parameters
        int kwIndex =
            countUntil!
                (x => x.token.type == TokenType.constant &&
                      (cast(ConstantToken)x.token).stringValue == kwArg.name)
                (parameters);

        if (kwIndex == -1 || kwIndex == parameters.length - 1) {
            // not found, or doesn't have a value after it
            if (kwArg.defaultValue is null) {
                // no default value
                throw new Exception("Missing keyword argument " ~ kwArg.name);
            } else {
                // use the default value
                value = kwArg.defaultValue;
            }
        } else {
            // grab value following keyword argument and remove both
            value = parameters[kwIndex + 1];
            parameters = remove(parameters, kwIndex, kwIndex + 1);
        }

        addVariable(kwArg.name, evaluateOnce(value));
    }

    // bind auxiliary arguments
    foreach (PairedArgument auxArg; fun.auxArguments) {
        addVariable(auxArg.name, auxArg.defaultValue is null ? new Value(new BooleanToken(false)) : evaluateOnce(auxArg.defaultValue));
    }
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateBuiltinFunction (string name, Value[] arguments, Value[string] kwargs = null) {
    return builtinFunctions[name](name, arguments, kwargs);
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateDefinedFunction (LispFunction fun, Value[] parameters, string name = "lambda") {
    Value[] forms = fun.forms;
    Value returnValue;

    enterScope();
    bindParameters(name, fun, parameters.dup);
    foreach (Value form; forms) {
        returnValue = evaluateOnce(form);
    }
    leaveScope();

    return returnValue;
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateFunction (string name, Value[] arguments) {
    if (name in builtinFunctions) {
        return evaluateBuiltinFunction(name, arguments);
    }

    if (name !in lispFunctions) {
        throw new UndefinedFunctionException(name);
    }

    return evaluateDefinedFunction(lispFunctions[name], arguments, name);
}


///////////////////////////////////////////////////////////////////////////////

Value getFunction (string name) {
    if (name in builtinFunctions) {
        return new Value(new BuiltinFunctionToken(name));
 
    } else if (name in lispFunctions) {
        return new Value(new DefinedFunctionToken(name));
 
    } else {
        throw new Exception("Undefined function " ~ name);
    }
}