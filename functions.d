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
import builtin.loop;
import builtin.math;
import builtin.system;


///////////////////////////////////////////////////////////////////////////////

alias FunctionHook = Value function(string);

struct PairedArgument {
    string name;
    Value defaultValue;

    this (string name, Value defaultValue = null) {
        this.name = name;
        this.defaultValue = defaultValue;
    }
}

struct Parameters {
    string[] required;
    PairedArgument[] optional;
    PairedArgument[] keyword;
    PairedArgument[] auxiliary;
    string rest;

    this (string[] required, PairedArgument[] optional = null, PairedArgument[] keyword = null, PairedArgument[] auxiliary = null, string rest = null) {
        this.required = required;
        this.optional = optional;
        this.keyword = keyword;
        this.auxiliary = auxiliary;
        this.rest = rest;
    }
}

struct BuiltinFunction {
    uint id;
    string name;
    FunctionHook hook;
    string docString;
    Parameters parameters;
}

struct LispFunction {
    uint id;
    string docString;
    Value[] lambdaList;
    Parameters parameters;
    Value[] forms;
}

BuiltinFunction[int] builtinTable;
BuiltinFunction[string] builtinFunctions;
LispFunction[string] lispFunctions;


///////////////////////////////////////////////////////////////////////////////

void initializeBuiltins () {
    builtin.definition.addBuiltins();
    builtin.io.addBuiltins();
    builtin.list.addBuiltins();
    builtin.logic.addBuiltins();
    builtin.loop.addBuiltins();
    builtin.math.addBuiltins();
    builtin.system.addBuiltins();
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

uint hash (string str) {
    uint h = 0;
    foreach (char c; str) {
        h = 37 * h + cast(uint)c;
    }

    return h;
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Adds a builtin function.
 */

void addFunction (string name, FunctionHook hook, Parameters parameters, string docString = null) {
    // Add colons to the beginning of each parameter's name to prevent naming conflicts in case an
    // identifier with an otherwise identical name is passed for that parameter.
    parameters.required = map!(x => ":" ~ x)(parameters.required).array();
    parameters.optional = map!(x => PairedArgument(":" ~ x.name, x.defaultValue))(parameters.optional).array();
    parameters.keyword = map!(x => PairedArgument(":" ~ x.name, x.defaultValue))(parameters.keyword).array();
    parameters.rest = ":" ~ parameters.rest;
    
    BuiltinFunction fun = BuiltinFunction(hash(name), name, hook, docString, parameters);
    builtinFunctions[name] = fun;
    builtinTable[fun.id] = fun;
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Constructs a LispFunction object from a lambda list and list of forms.
 */

LispFunction processFunctionDefinition (Value[] lambdaList, Value[] forms, string docString = null) {
    Value[] oldLambdaList = lambdaList[];
    PairedArgument[] optional = extractKeywordArguments(lambdaList, "&OPTIONAL");
    PairedArgument[] keyword = extractKeywordArguments(lambdaList, "&KEY");
    string rest = extractRestArgument(lambdaList);
    PairedArgument[] auxiliary = extractKeywordArguments(lambdaList, "&AUX");
    string[] required = reduce!((result, x) => result ~= (cast(IdentifierToken)x.token).stringValue)(new string[0], lambdaList);
    if (required.length == 0) {
        required = null;
    }

    return LispFunction(lispFunctions.length, docString, oldLambdaList, Parameters(required, optional, keyword, auxiliary, rest), forms);
}


///////////////////////////////////////////////////////////////////////////////

void addFunction (string name, Value[] lambdaList, Value[] forms, string docString = null) {
    lispFunctions[name] = processFunctionDefinition(lambdaList, forms, docString);
}


///////////////////////////////////////////////////////////////////////////////

Value[string] bindParameters (string name, Parameters parameters, Value[] arguments, bool evaluateArguments = true) {
    Value[string] newScope;

    if (evaluateArguments) {
        // evaluate all arguments
        for (int i = 0; i < arguments.length; i++) {
            arguments[i] = evaluateOnce(arguments[i]);
        }
    }

    // extract and bind required arguments
    foreach (string requiredArg; parameters.required) {
        if (arguments.length == 0) {
            throw new Exception("Too few arguments given to " ~ name);
        }

        newScope[requiredArg] = arguments[0];
        arguments = remove(arguments, 0);
    }

    // extract and bind optional arguments
    foreach (PairedArgument optArg; parameters.optional) {
        Value value;
        if (arguments.length == 0) {
            // use default value if we're out of arguments
            value = optArg.defaultValue is null ? Value.nil() : evaluateOnce(optArg.defaultValue.copy());
        } else {
            // otherwise use and remove the next one
            value = arguments[0];
            arguments = remove(arguments, 0);
        }

        newScope[optArg.name] = value;
    }

    // if fun wants a rest parameter, grab all remaining arguments
    if (parameters.rest !is null) {
        Value restArguments;

        if (arguments.length == 0) {
            restArguments = Value.nil();

        } else {
            restArguments = Token.makeReference(arguments[0]);
            Value lastArgument = restArguments;
            for (int i = 1; i < arguments.length; i++) {
                (cast(ReferenceToken)lastArgument.token).reference.cdr = Token.makeReference(arguments[i]);
                lastArgument = (cast(ReferenceToken)lastArgument.token).reference.cdr;
            }
        }

        newScope[parameters.rest] = restArguments;
    }

    // extract and bind keyword arguments
    foreach (PairedArgument kwArg; parameters.keyword) {
        // find matching keyword argument in arguments
        int kwIndex =
            countUntil!
                (x => x.token.type == TokenType.constant &&
                      (cast(ConstantToken)x.token).stringValue == kwArg.name)
                (arguments);

        Value value;
        if (kwIndex == -1 || kwIndex == arguments.length - 1) {
            // not found, or doesn't have a value after it
            if (kwArg.defaultValue is null) {
                // no default value
                throw new Exception("Missing keyword argument " ~ kwArg.name);
            } else {
                // use the default value
                value = evaluateOnce(kwArg.defaultValue.copy());
            }
        } else {
            // grab value following keyword argument and remove both
            value = arguments[kwIndex + 1];
            arguments = remove(arguments, kwIndex, kwIndex + 1);
        }

        newScope[kwArg.name] = value;
    }

    // bind auxiliary arguments
    foreach (PairedArgument auxArg; parameters.auxiliary) {
        newScope[auxArg.name] = auxArg.defaultValue is null ? Value.nil() : evaluateOnce(auxArg.defaultValue.copy());
    }

    return newScope;
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateBuiltinFunction (string name, Value[] arguments) {
    BuiltinFunction fun = builtinFunctions[name];
    enterScope(bindParameters(name, fun.parameters, arguments, false)); // leave evaluation of arguments up to the called function
    Value result = fun.hook(name);
    leaveScope();
    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateDefinedFunction (LispFunction fun, Value[] parameters, string name = "lambda") {
    Value[] forms = fun.forms;
    Value returnValue;

    enterScope(bindParameters(name, fun.parameters, parameters.dup));
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
    } else if (name in lispFunctions) {
        return evaluateDefinedFunction(lispFunctions[name], arguments, name);
    }
    throw new UndefinedFunctionException(name);
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction* getBuiltin (string name) {
    if (name in builtinFunctions) {
        return &builtinFunctions[name];
    }

    return null;
}


///////////////////////////////////////////////////////////////////////////////

LispFunction* getDefined (string name) {
    if (name in lispFunctions) {
        return &lispFunctions[name];
    }

    return null;
}


///////////////////////////////////////////////////////////////////////////////

Value getFunction (string name) {
    if (name in builtinFunctions) {
        return new Value(new BuiltinFunctionToken(name));
 
    } else if (name in lispFunctions) {
        return new Value(new DefinedFunctionToken(name, lispFunctions[name]));
 
    } else {
        throw new Exception("Undefined function " ~ name);
    }
}