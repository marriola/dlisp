module builtin.definition;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinLet (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    } else if (args[0].token.type != TokenType.reference) {
        throw new TypeMismatchException(name, args[0].token, "reference");
    }

    Value[] bindings = toArray(args[0]);
    Value[] forms = args[1 .. args.length];
    string[] variables = new string[bindings.length];
    Value[] initialValues = new Value[bindings.length];

    foreach (int i, Value binding; bindings) {
        Value bindingName = getFirst(binding);
        Value bindingValue = evaluateOnce(getFirst(getRest(binding)));

        if (bindingName.token.type != TokenType.identifier) {
            throw new TypeMismatchException(name, binding.token, "identifier");
        }
        variables[i] = (cast(IdentifierToken)bindingName.token).stringValue;
        initialValues[i] = bindingValue;
    }

    Value[string] newScope;
    for (int i = 0; i < bindings.length; i++) {
        newScope[variables[i]] = initialValues[i];
    }

    enterScope(newScope);
    Value lastResult = new Value(new BooleanToken(false));
    foreach (Value form; forms) {
        lastResult = evaluateOnce(form);
    }
    leaveScope();

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLetStar (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    } else if (args[0].token.type != TokenType.reference) {
        throw new TypeMismatchException(name, args[0].token, "reference");
    }

    Value[] bindings = toArray(args[0]);
    Value[] forms = args[1 .. args.length];

    enterScope();
    foreach (Value bindingReference; bindings) {
        Value bindingName = getFirst(bindingReference);
        Value bindingValue = evaluateOnce(getFirst(getRest(bindingReference)));

        if (bindingName.token.type != TokenType.identifier) {
            throw new TypeMismatchException(name, bindingName.token, "identifier");
        }

        addVariable((cast(IdentifierToken)bindingName.token).stringValue, bindingValue);
    }

    Value lastResult = new Value(new BooleanToken(false));
    foreach (Value form; forms) {
        lastResult = evaluateOnce(form);
    }
    leaveScope();

    return lastResult;
}

///////////////////////////////////////////////////////////////////////////////

Value builtinSetq (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    string identifier;
    if (args[0].token.type == TokenType.identifier) {
        identifier = (cast(IdentifierToken)args[0].token).stringValue;
    } else {
        throw new TypeMismatchException(name, args[0].token, "identifier");
    }

    Value value = evaluateOnce(args[1]);
    addVariable(identifier, value, 0);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSetf (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value reference = evaluateOnce(args[0]);
    Value value = evaluateOnce(args[1]);

    copyValue(value, reference);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLambda (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value[] lambdaList = toArray(args[0]);
    Value[] forms = args[1 .. args.length];
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 1) {
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

    return new Value(new DefinedFunctionToken(lambdaList, forms, docString));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinFuncall (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value fun = evaluateOnce(args[0]);
    Value[] funArgs = args[1 .. args.length];

    if (fun.token.type == TokenType.identifier) {
        return evaluateFunction((cast(IdentifierToken)fun.token).stringValue, funArgs);

    } else if (fun.token.type == TokenType.definedFunction || fun.token.type == TokenType.builtinFunction) {
        return (cast(FunctionToken)fun.token).evaluate(funArgs);

    } else {
        throw new TypeMismatchException(name, fun.token, "identifier or function");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDefun (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Value identifierToken = args[0];
    Value lambdaListToken = args[1];

    Value[] forms;
    string docString = null;

    if (args[2].token.type == TokenType.string && args.length > 3) {
        // remove documentation string
        docString = (cast(StringToken)args[2].token).stringValue;
        forms = args[3 .. args.length];
    } else {
        forms = args[2 .. args.length];
    }

    if (identifierToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");
    } else if (!Token.isNil(lambdaListToken) && lambdaListToken.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaListToken.token, "reference");
    }

    string identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    Value[] lambdaList = toArray(lambdaListToken);

    addFunction(identifier, lambdaList, forms, docString);

    return identifierToken;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinFunction (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value identifierToken = args[0];

    if (identifierToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");

    } else {
        return getFunction((cast(IdentifierToken)identifierToken.token).stringValue);
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEval (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    return evaluateOnce(evaluateOnce(args[0]));
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["LET"] = &builtinLet;
    builtinTable["LET*"] = &builtinLetStar;
    builtinTable["SETF"] = &builtinSetf;
    builtinTable["SETQ"] = &builtinSetq;
    builtinTable["LAMBDA"] = &builtinLambda;
    builtinTable["FUNCALL"] = &builtinFuncall;
    builtinTable["DEFUN"] = &builtinDefun;
    builtinTable["FUNCTION"] = &builtinFunction;
    builtinTable["EVAL"] = &builtinEval;
    return builtinTable;
}