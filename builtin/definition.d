module builtin.definition;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinLet (string name) {
    Value[] bindings = toArray(getVariable("BINDINGS"));
    Value[] forms = toArray(getVariable("FORMS"));
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

Value builtinLetStar (string name) {
    Value[] bindings = toArray(getVariable("BINDINGS"));
    Value[] forms = toArray(getVariable("FORMS"));

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

Value builtinSetq (string name) {
    Value identifierToken = getVariable("IDENTIFIER");
    string identifier;
    if (identifierToken.token.type == TokenType.identifier) {
        identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    } else {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");
    }

    Value value = evaluateOnce(getVariable("VALUE"));
    addVariable(identifier, value, 0);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSetf (string name) {
    Value place = evaluateOnce(getVariable("PLACE"));
    Value value = evaluateOnce(getVariable("VALUE"));
    copyValue(value, place);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLambda (string name) {
    Value[] lambdaList = toArray(getVariable("LAMBDA-LIST"));
    Value[] forms = toArray(getVariable("FORMS"));
    string docString = null;

    if (forms[0].token.type == TokenType.string && forms.length > 1) {
        docString = (cast(StringToken)forms[0].token).stringValue;
        forms = forms[1 .. forms.length];
    }

    return new Value(new DefinedFunctionToken(lambdaList, forms, docString));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinFuncall (string name) {
    Value fun = evaluateOnce(getVariable("FUNCTION"));
    Value[] funArgs = toArray(getVariable("ARGUMENTS"));

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
    Value identifier = getVariable("IDENTIFIER");
    Value lambdaList = getVariable("LAMBDA-LIST");

    Value[] forms = toArray(getVariable("FORMS"));
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
    Value identifierToken = getVariable("IDENTIFIER");

    if (identifierToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");

    } else {
        return getFunction((cast(IdentifierToken)identifierToken.token).stringValue);
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEval (string name) {
    return evaluateOnce(evaluateOnce(getVariable("FORM")));
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("LET", &builtinLet, Parameters(["BINDINGS", "FORMS"]));
    addFunction("LET*", &builtinLetStar, Parameters(["BINDINGS", "FORMS"]));
    addFunction("SETF", &builtinSetf, Parameters(["PLACE", "VALUE"]));
    addFunction("SETQ", &builtinSetq, Parameters(["IDENTIFIER", "VALUE"]));
    addFunction("LAMBDA", &builtinLambda, Parameters(["LAMBDA-LIST"], null, null, null, "FORMS"));
    addFunction("FUNCALL", &builtinFuncall, Parameters(["IDENTIFIER", "ARGUMENTS"]));
    addFunction("DEFUN", &builtinDefun, Parameters(["IDENTIFIER", "LAMBDA-LIST"], null, null, null, "FORMS"));
    addFunction("FUNCTION", &builtinFunction, Parameters(["IDENTIFIER"]));
    addFunction("EVAL", &builtinEval, Parameters(["FORM"]));

}