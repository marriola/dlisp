module builtin.definition;

import evaluator;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Token builtinDefun (string name, ReferenceToken args) {
    if (listLength(args) < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Token identifier = getItem(args, 0);
    Token lambdaList = getItem(args, 1);
    Token forms = getItemReference(args, 2);

    if (identifier.type != TokenType.identifier) {
        throw new TypeMismatchException(name, identifier, "identifier");
    }

    addFunction((cast(IdentifierToken)identifier).stringValue, lambdaList, cast(ReferenceToken)forms);

    return identifier;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["DEFUN"] = &builtinDefun;
    return builtinTable;
}