module functions;


///////////////////////////////////////////////////////////////////////////////

import std.algorithm;
import std.typecons;


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

// Evaluable objects are passed to the code emitter. evaluate comes from a
// function parameter's value for evaluate, which determines whether the
// code emitter pushes the argument on the stack verbatim, or emits code to
// get its value at runtime.

class Evaluable {
	bool evaluate;
	Value value;

	this (bool evaluate, Value value) {
		this.evaluate = evaluate;
		this.value = value;
	}
}

struct Parameter {
	string name;
    Value defaultValue;
	bool evaluate;

    this (string name, Value defaultValue, bool evaluate = true) {
        this.name = name;
        this.defaultValue = defaultValue;
		this.evaluate = evaluate;
    }

    this (string name, bool evaluate = true) {
        this.name = name;
        this.defaultValue = null;
		this.evaluate = evaluate;
    }
}

struct Parameters {
    Parameter[] required;
    Parameter[] optional;
    Parameter[] keyword;
    Parameter[] auxiliary;
    Parameter rest;
	bool hasRest;

    this (Parameter[] required, Parameter[] optional, Parameter[] keyword, Parameter[] auxiliary, Parameter rest) {
        this.required = required;
        this.optional = optional;
        this.keyword = keyword;
        this.auxiliary = auxiliary;
        this.rest = rest;
		this.hasRest = true;
    }

    this (Parameter[] required, Parameter[] optional = null, Parameter[] keyword = null, Parameter[] auxiliary = null) {
        this.required = required;
        this.optional = optional;
        this.keyword = keyword;
        this.auxiliary = auxiliary;
		this.hasRest = false;
    }
}

class LispFunction {
	uint id;
	string name;
	string docString;
	Parameters parameters;
	bool[] shouldBeEvaluated;

	this (uint id, string name, string docString, Parameters parameters) {
		this.id = id;
		this.name = name;
		this.docString = docString;
		this.parameters = parameters;

		foreach (Parameter param; parameters.required ~ parameters.optional ~ parameters.keyword ~ parameters.rest) {
			shouldBeEvaluated ~= param.evaluate;
		}
	}

	public bool isCompiled() {
		return false;
	}
}

class BuiltinFunction : LispFunction {
    FunctionHook hook;

	this (uint id, string name, FunctionHook hook, string docString, Parameters parameters) {
		super(id, name, docString, parameters);
		this.hook = hook;
	}

}

class CompiledFunction : LispFunction {
    Value[] lambdaList;
    Value[] forms;

	this (uint id, string name, string docString, Value[] lambdaList, Parameters parameters, Value[] forms) {
		super(id, name, docString, parameters);
		this.lambdaList = lambdaList;
		this.forms = forms;
	}

	public override bool isCompiled() {
		return true;
	}}

BuiltinFunction[int] builtinTable;
BuiltinFunction[string] builtinFunctions;
CompiledFunction[int] compiledTable;
CompiledFunction[string] lispFunctions;


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

Nullable!Parameter extractRestArgument (ref Value[] lambdaList) {
    int firstArgument = -1;
	Nullable!Parameter rest;

    // look for the &key keyword, exit if not found
    foreach (int i, Value arg; lambdaList) {
        if (arg.token.type == TokenType.identifier && (cast(IdentifierToken)arg.token).stringValue == "&REST") {
            if (i == lambdaList.length - 1) {
                throw new Exception("Missing &rest element in lambda list");
            } else if (lambdaList[i + 1].token.type != TokenType.identifier) {
                throw new InvalidLambdaListElementException(lambdaList[i + 1].token, "identifier");
            }

            rest = Parameter((cast(IdentifierToken)lambdaList[i + 1].token).stringValue);
            lambdaList = remove(lambdaList, i, i + 1);
			break;
        }
    }

    return rest;
}


///////////////////////////////////////////////////////////////////////////////

Parameter[] extractKeywordArguments (ref Value[] lambdaList, string keyword) {
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

    Parameter[] keywordArguments;
    foreach (int i, Value arg; lambdaList[firstArgument .. lambdaList.length]) {
        // keep going until we reach another keyword
        if (arg.token.type == TokenType.identifier && (cast(IdentifierToken)arg.token).stringValue[0] == '&') {
            lastArgument = i + firstArgument;
            break;
        }

        if (arg.token.type == TokenType.reference) {
			// if this parameter is a reference, it's a pair of parameter name and default value
            Value argumentName = getFirst(arg);
            Value argumentValue = evaluate(getFirst(getRest(arg)));
            if (argumentName.token.type != TokenType.identifier) {
                throw new InvalidLambdaListElementException(argumentName.token, "expected identifier");
            }
            keywordArguments ~= Parameter((cast(IdentifierToken)argumentName.token).stringValue, argumentValue);

        } else if (arg.token.type == TokenType.identifier) {
            keywordArguments ~= Parameter((cast(IdentifierToken)arg.token).stringValue, null);

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
 *
 * @param	name		The name of the function
 * @param	hook		A pointer to a function to call when this function is invoked
 * @param	required	Required parameters
 * @param	optional	Optional parameters
 * @param	keyword		Keyword parameters
 * @param	auxiliary	Auxiliary parameters
 * @param	rest		A rest parameter
 * @param	docString	Documentation string
 */

void addFunction (string name, FunctionHook hook, Parameter[] required, Parameter[] optional = null, Parameter[] keyword = null, Parameter[] auxiliary = null, Parameter rest = null, string docString = null) {
    // Add colons to the beginning of each parameter's name to prevent naming conflicts in case an
    // identifier with an otherwise identical name is passed for that parameter.
    required = map!(x => Parameter(":" ~ x.name))(required).array();
    optional = map!(x => Parameter(":" ~ x.name, x.defaultValue))(optional).array();
    keyword = map!(x => Parameter(":" ~ x.name, x.defaultValue))(keyword).array();
    rest = Parameter(":" ~ rest.name);
    
    BuiltinFunction fun = new BuiltinFunction(hash(name), name, hook, docString, Parameters(required, optional, keyword, auxiliary, rest));
    builtinFunctions[name] = fun;
    builtinTable[fun.id] = fun;
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Constructs a CompiledFunction object from a lambda list and list of forms.
 */

CompiledFunction processFunctionDefinition (string name, Value[] lambdaList, Value[] forms, string docString = null) {
    Value[] oldLambdaList = lambdaList[];
    Parameter[] optional = extractKeywordArguments(lambdaList, "&OPTIONAL");
    Parameter[] keyword = extractKeywordArguments(lambdaList, "&KEY");
    Nullable!Parameter rest = extractRestArgument(lambdaList);
    Parameter[] auxiliary = extractKeywordArguments(lambdaList, "&AUX");
    Parameter[] required = reduce!((result, x) => result ~= Parameter((cast(IdentifierToken)x.token).stringValue))(new Parameter[0], lambdaList);
    if (required.length == 0) {
        required = null;
    }

    if (rest.isNull) {
		return new CompiledFunction(lispFunctions.length, name, docString, oldLambdaList,
									Parameters(required, optional, keyword, auxiliary), forms);
	} else {
		return new CompiledFunction(lispFunctions.length, name, docString, oldLambdaList,
									Parameters(required, optional, keyword, auxiliary, rest), forms);
	}
}


///////////////////////////////////////////////////////////////////////////////

void addFunction (string name, Value[] lambdaList, Value[] forms, string docString = null) {
    CompiledFunction fun = processFunctionDefinition(name, lambdaList, forms, docString);
	lispFunctions[name] = fun;
	compiledTable[fun.id] = fun;
}


///////////////////////////////////////////////////////////////////////////////

Evaluable[] bindParametersList (string name, Parameters parameters, Value[] arguments, bool evaluateArguments = true) {
    Evaluable[] newScope = new Evaluable[0];

    // extract and bind required arguments
    foreach (Parameter requiredParam; parameters.required) {
        if (arguments.length == 0) {
            throw new Exception("Too few arguments given to " ~ name);
        }

        newScope ~= new Evaluable(requiredParam.evaluate, arguments[0]);
        arguments = remove(arguments, 0);
    }

    // extract and bind optional arguments
    foreach (Parameter optArg; parameters.optional) {
        Value value;
        if (arguments.length == 0) {
			continue; // don't emit code for this parameter
        } else {
            // otherwise use and remove the next one
            value = arguments[0];
            arguments = remove(arguments, 0);
        }

		newScope ~= new Evaluable(false, new Value(new IdentifierToken(":" ~ optArg.name)));
		newScope ~= new Evaluable(optArg.evaluate, value);
    }

    // extract and bind keyword arguments
    foreach (Parameter kwArg; parameters.keyword) {
		std.stdio.writeln(arguments[0].toString());
		std.stdio.writeln(arguments[1].toString());
		std.stdio.writeln(arguments[0].token.type);

		int kwIndex = -1;
		for (kwIndex = 0; kwIndex < arguments.length; kwIndex++) {
			TokenType type = arguments[kwIndex].token.type;
			string constantName = type == TokenType.constant ? (cast(ConstantToken)arguments[kwIndex].token).stringValue : "";
			string param = kwArg.name[1..$];

			std.stdio.writef("'%s'\n", type);
			if (arguments[kwIndex].token.type == TokenType.constant)
				std.stdio.writef("'%s'\n", constantName);
			std.stdio.writef("'%s'\n", param);
			if (type == TokenType.constant &&
				constantName == param) {
				break;
			}
		}

        Value value;
        if (kwIndex == -1 || kwIndex >= arguments.length - 1) {
            // not found, or doesn't have a value after it
            if (kwArg.defaultValue is null && arguments.length == 0) {
                // no default value
                throw new Exception("Missing keyword argument " ~ kwArg.name);
            } else {
				continue; // don't emit code for this parameter
            }
        } else {
            // grab value following keyword argument and remove both
            value = arguments[kwIndex + 1];
            arguments = remove(arguments, kwIndex, kwIndex + 1);
        }

		newScope ~= new Evaluable(false, new Value(new IdentifierToken(kwArg.name)));
		newScope ~= new Evaluable(kwArg.evaluate, value);
    }

    return newScope;
}

Value[string] bindParameters (string name, Parameters parameters, Value[] arguments, bool evaluateArguments = true) {
    Value[string] newScope;

    // extract and bind required arguments
    foreach (Parameter requiredParam; parameters.required) {
        if (arguments.length == 0) {
            throw new Exception("Too few arguments given to " ~ name);
        }

        newScope[requiredParam.name] = arguments[0];
        arguments = remove(arguments, 0);
    }

    // extract and bind optional arguments
    foreach (Parameter optArg; parameters.optional) {
        Value value;
        if (arguments.length == 0) {
            // use default value if we're out of arguments
            value = optArg.defaultValue is null ? Value.nil() : optArg.defaultValue.copy();
        } else {
            // otherwise use and remove the next one
            value = arguments[0];
            arguments = remove(arguments, 0);
        }

        newScope[optArg.name] = value;
    }

    // if fun wants a rest parameter, grab all remaining arguments
    if (parameters.hasRest) {
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

        newScope[parameters.rest.name] = restArguments;
    }

    // extract and bind keyword arguments
    foreach (Parameter kwArg; parameters.keyword) {
		int kwIndex = -1;
		for (kwIndex = 0; kwIndex < arguments.length; kwIndex++) {
			TokenType type = arguments[kwIndex].token.type;
			string constantName = type == TokenType.constant ? (cast(ConstantToken)arguments[kwIndex].token).stringValue : "";
			string param = kwArg.name[1..$];

			std.stdio.writef("'%s'\n", type);
			if (arguments[kwIndex].token.type == TokenType.constant)
				std.stdio.writef("'%s'\n", constantName);
			std.stdio.writef("'%s'\n", param);
			if (type == TokenType.constant &&
				constantName == param) {
					break;
				}
		}

        Value value;
        if (kwIndex == -1 || kwIndex == arguments.length - 1) {
            // not found, or doesn't have a value after it
            if (kwArg.defaultValue is null) {
                // no default value
                throw new Exception("Missing keyword argument " ~ kwArg.name);
            } else {
                // use the default value
                value = kwArg.defaultValue.copy();
            }
        } else {
            // grab value following keyword argument and remove both
            value = arguments[kwIndex + 1];
            arguments = remove(arguments, kwIndex, kwIndex + 1);
        }

        newScope[kwArg.name] = value;
    }

    // bind auxiliary arguments
    foreach (Parameter auxArg; parameters.auxiliary) {
        newScope[auxArg.name] = auxArg.defaultValue is null ? Value.nil() : auxArg.defaultValue.copy();
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

Value evaluateCompiledFunction (CompiledFunction fun, Value[] parameters, string name = "lambda") {
    Value[] forms = fun.forms;
    Value returnValue;

    enterScope(bindParameters(name, fun.parameters, parameters.dup));
    foreach (Value form; forms) {
        returnValue = evaluate(form);
    }
    leaveScope();

    return returnValue;
}


///////////////////////////////////////////////////////////////////////////////

Value evaluateFunction (string name, Value[] arguments) {
    if (name in builtinFunctions) {
        return evaluateBuiltinFunction(name, arguments);
    } else if (name in lispFunctions) {
        return evaluateCompiledFunction(lispFunctions[name], arguments, name);
    }
    throw new UncompiledFunctionException(name);
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction getBuiltin (string name) {
    if (name in builtinFunctions) {
        return builtinFunctions[name];
    }

    return null;
}


///////////////////////////////////////////////////////////////////////////////

CompiledFunction getDefined (string name) {
    if (name in lispFunctions) {
        return lispFunctions[name];
    }

    return null;
}


///////////////////////////////////////////////////////////////////////////////

Value getFunction (string name) {
    if (name in builtinFunctions) {
        return new Value(new BuiltinFunctionToken(name));
 
    } else if (name in lispFunctions) {
        return new Value(new CompiledFunctionToken(name, lispFunctions[name]));
 
    } else {
        throw new Exception("Undefined function " ~ name);
    }
}