module builtin.definition;


import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinLet (string name) {
    Value[] bindings = toArray(getParameter("BINDINGS"));
    Value[] forms = toArray(getParameter("FORMS"));
    string[] variables = new string[bindings.length];
    Value[] initialValues = new Value[bindings.length];

    foreach (int i, Value binding; bindings) {
        Value bindingName = getFirst(binding);
        Value bindingValue = getFirst(getRest(binding));

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
        lastResult = form;
    }
    leaveScope();

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLetStar (string name) {
    Value[] bindings = toArray(getParameter("BINDINGS"));
    Value[] forms = toArray(getParameter("FORMS"));

    enterScope();
    foreach (Value bindingReference; bindings) {
        Value bindingName = getFirst(bindingReference);
        Value bindingValue = getFirst(getRest(bindingReference));

        if (bindingName.token.type != TokenType.identifier) {
            throw new TypeMismatchException(name, bindingName.token, "identifier");
        }

        addVariable((cast(IdentifierToken)bindingName.token).stringValue, bindingValue);
    }

    Value lastResult = new Value(new BooleanToken(false));
    foreach (Value form; forms) {
        lastResult = form;
    }
    leaveScope();

    return lastResult;
}

///////////////////////////////////////////////////////////////////////////////

Value builtinSetq (string name) {
    Value identifierToken = getParameter("IDENTIFIER");
    string identifier;
    if (identifierToken.token.type == TokenType.identifier) {
        identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    } else {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");
    }

    Value value = getParameter("VALUE");
    addVariable(identifier, value, 0);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSetf (string name) {
    Value place = getParameter("PLACE");
    Value value = getParameter("VALUE");
    copyValue(value, place);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLambda (string name) {
    Value[] lambdaList = toArray(getParameter("LAMBDA-LIST"));
    Value[] forms = toArray(getParameter("FORMS"));
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 1) {
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

    return new Value(new DefinedFunctionToken(lambdaList, forms, docString));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinFuncall (string name) {
    Value fun = getParameter("IDENTIFIER");
    Value[] funArgs = toArray(getParameter("ARGUMENTS"));

    if (fun.token.type == TokenType.identifier) {
        return evaluateFunction((cast(IdentifierToken)fun.token).stringValue, funArgs);

    } else if (fun.token.type == TokenType.definedFunction || fun.token.type == TokenType.builtinFunction) {
        return (cast(FunctionToken)fun.token).evaluate(funArgs);

    } else {
        throw new TypeMismatchException(name, fun.token, "identifier or function");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDefun (string name) {
    Value identifier = getParameter("IDENTIFIER");
    Value lambdaList = getParameter("LAMBDA-LIST");

    Value[] forms = toArray(getParameter("FORMS"));
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 3) {
        // remove documentation string
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

    if (identifier.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifier.token, "identifier");
    } else if (!lambdaList.isNil() && lambdaList.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaList.token, "reference");
    }

    addFunction((cast(IdentifierToken)identifier.token).stringValue, toArray(lambdaList), forms, docString);

    return identifier;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinFunction (string name) {
    Value identifierToken = getParameter("IDENTIFIER");

    if (identifierToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");

    } else {
        return getFunction((cast(IdentifierToken)identifierToken.token).stringValue);
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEval (string name) {
    return getParameter("FORM");
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("LET", &builtinLet, [Parameter("BINDINGS")], null, null, null, Parameter("FORMS"));
    addFunction("LET*", &builtinLetStar, [Parameter("BINDINGS")], null, null, null, Parameter("FORMS"));
    addFunction("SETF", &builtinSetf, [Parameter("PLACE"), Parameter("VALUE")]);
    addFunction("SETQ", &builtinSetq, [Parameter("IDENTIFIER", false), Parameter("VALUE")]);
    addFunction("LAMBDA", &builtinLambda, [Parameter("LAMBDA-LIST", false)], null, null, null, Parameter("FORMS"));
    addFunction("FUNCALL", &builtinFuncall, [Parameter("IDENTIFIER")], null, null, null, Parameter("ARGUMENTS"));
    addFunction("DEFUN", &builtinDefun, [Parameter("IDENTIFIER"), Parameter("LAMBDA-LIST")], null, null, null, Parameter("FORMS"));
    addFunction("FUNCTION", &builtinFunction, [Parameter("IDENTIFIER")]);
    addFunction("EVAL", &builtinEval, [Parameter("FORM")]);

}