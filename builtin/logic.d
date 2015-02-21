module builtin.logic;

import evaluator;
import functions;
import list;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinIf (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    bool condition;
    Token current = getFirst(args);

    if (current.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current, "boolean");
    } else {
        condition = (cast(BooleanToken)evaluate(current)).boolValue;
        args = getRest(args);
    }

    if (listLength(args) < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token thenClause = getFirst(args);
    args = getRest(args);
    Token elseClause = getFirst(args);
    return condition ? evaluate(thenClause) : evaluate(elseClause);
}


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

Token builtinEq (string name, ReferenceToken args) {
    if (listLength(args) < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token obj1 = evaluate(getFirst(args));
    args = getRest(args);
    Token obj2 = evaluate(getFirst(args));

    return new BooleanToken(objectsEqual(obj1, obj2));
}


///////////////////////////////////////////////////////////////////////////////

Token builtinNeq (string name, ReferenceToken args) {
    if (listLength(args) < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token obj1 = evaluate(getFirst(args));
    args = getRest(args);
    Token obj2 = evaluate(getFirst(args));

    return new BooleanToken(!objectsEqual(obj1, obj2));
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["IF"] = &builtinIf;
    builtinTable["AND"] = &builtinAnd;
    builtinTable["OR"] = &builtinOr;
    builtinTable["NOT"] = &builtinNot;
    builtinTable["EQ"] = &builtinEq;
    builtinTable["NEQ"] = &builtinNeq;
    return builtinTable;
}