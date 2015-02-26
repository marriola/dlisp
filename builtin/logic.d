module builtin.logic;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinIf (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    bool condition;
    Token current = evaluate(args[0]);

    if (current.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current, "boolean");
    } else {
        condition = (cast(BooleanToken)current).boolValue;
    }

    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Token thenClause = args[1];
    Token elseClause = args[2];
    return condition ? evaluate(thenClause) : evaluate(elseClause);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinAnd (string name, Token[] args) {
    bool result = true;

    for (int i = 0; i < args.length; i++) {
        if (!result) {
            break;
        }

        Token current = evaluate(args[i]);
        if (current.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current, "boolean");
        } else {
            result &= (cast(BooleanToken)current).boolValue;
        }
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinOr (string name, Token[] args) {
    bool result = false;

    for (int i = 0; i < args.length; i++) {
        Token current = evaluate(args[i]);
        if (current.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current, "boolean");
        } else {
            result |= (cast(BooleanToken)current).boolValue;
        }
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinNot (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current, "boolean");
    }

    return new BooleanToken(!(cast(BooleanToken)current).boolValue);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinEq (string name, Token[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token obj1 = evaluate(args[0]);
    Token obj2 = evaluate(args[1]);

    return new BooleanToken(objectsEqual(obj1, obj2));
}


///////////////////////////////////////////////////////////////////////////////

Token builtinNeq (string name, Token[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token obj1 = evaluate(args[0]);
    Token obj2 = evaluate(args[1]);

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