module builtin.definition;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinLet (string name, Value[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    if (args[0].token.type != TokenType.reference) {
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

Value builtinSetq (string name, Value[] args) {
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
    addVariable(identifier, value);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSetf (string name, Value[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value reference = evaluateOnce(args[0]);
    Value value = evaluate(args[1]);

    copyValue(value, reference);
    return value;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDefun (string name, Value[] args) {
    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Value identifierToken = args[0];
    Value lambdaListToken = args[1];
    Value[] forms = args[2 .. args.length];

    if (identifierToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken.token, "identifier");
    } else if (!Token.isNil(lambdaListToken) && lambdaListToken.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaListToken.token, "reference");
    }

    string identifier = (cast(IdentifierToken)identifierToken.token).stringValue;
    Value[] lambdaList = toArray(lambdaListToken);

    addFunction(identifier, lambdaList, forms);

    return identifierToken;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["LET"] = &builtinLet;
    builtinTable["SETF"] = &builtinSetf;
    builtinTable["SETQ"] = &builtinSetq;
    builtinTable["DEFUN"] = &builtinDefun;
    return builtinTable;
}