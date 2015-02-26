module builtin.definition;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Token builtinSetq (string name, Token[] args) {
    if (args.length < 2) {
        return NotEnoughArgumentsException(name);
    }

    string identifier;
    if (args[0].type != TokenType.string) {
        identifier = (cast(StringToken)args[0]).stringValue;
    } else {
        throw new TypeMismatchException(name, args[0], "string");
    }

    Token 

    return value;
}


///////////////////////////////////////////////////////////////////////////////

Token builtinDefun (string name, Token[] args) {
    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Token identifierToken = args[0];
    Token lambdaListToken = args[1];
    Token[] forms = args[2 .. args.length];

    if (identifierToken.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifierToken, "identifier");
    } else if (!Token.isNil(lambdaListToken) && lambdaListToken.type != TokenType.reference) {
        throw new TypeMismatchException(name, lambdaListToken, "reference");
    }

    string identifier = (cast(IdentifierToken)identifierToken).stringValue;
    Token[] lambdaList = toArray(lambdaListToken);

    addFunction(identifier, lambdaList, forms);

    return identifierToken;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["DEFUN"] = &builtinDefun;
    builtinTable["SETQ"] = &builtinSetq;
    return builtinTable;
}