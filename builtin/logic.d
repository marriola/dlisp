module builtin.logic;

import evaluator;
import functions;
import list;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinAnd (string name, ReferenceToken args) {
    bool result = true;

    while (result && hasMore(args)) {
        Token current = evaluate(getFirst(args));

        if (current.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current, "boolean");
        } else {
            result &= (cast(BooleanToken)current).boolValue;
        }

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinOr (string name, ReferenceToken args) {
    bool result = false;

    while (hasMore(args)) {
        Token current = evaluate(getFirst(args));

        if (current.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current, "boolean");
        } else {
            result |= (cast(BooleanToken)current).boolValue;
        }

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinNot (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current, "boolean");
    }

    return new BooleanToken(!(cast(BooleanToken)current).boolValue);
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["AND"] = &builtinAnd;
    builtinTable["OR"] = &builtinOr;
    builtinTable["NOT"] = &builtinNot;
    return builtinTable;
}