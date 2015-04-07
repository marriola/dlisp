module builtin.logic;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinNull (string name, Value[] args, string[Value] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return new Value(new BooleanToken(Token.isNil(evaluateOnce(args[0]))));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinIf (string name, Value[] args, string[Value] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    bool condition;
    Value current = evaluate(args[0]);

    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    } else {
        condition = (cast(BooleanToken)current.token).boolValue;
    }

    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Value thenClause = args[1];
    Value elseClause = args[2];
    return condition ? evaluate(thenClause) : evaluate(elseClause);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCond (string name, Value[] args, string[Value] kwargs) {
    Value result = new Value(new BooleanToken(false));

    foreach (Value variant; args) {
        Value condition = getFirst(variant);
        Value[] forms = toArray(getRest(variant));

        if (!Token.isNil(evaluateOnce(condition))) {
            foreach (Value form; forms) {
                result = evaluateOnce(form);
            }
            break;
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinAnd (string name, Value[] args, string[Value] kwargs) {
    bool result = true;

    for (int i = 0; i < args.length; i++) {
        if (!result) {
            break;
        }

        Value current = evaluate(args[i]);
        if (current.token.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current.token, "boolean");
        } else {
            result &= (cast(BooleanToken)current.token).boolValue;
        }
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOr (string name, Value[] args, string[Value] kwargs) {
    bool result = false;

    for (int i = 0; i < args.length; i++) {
        Value current = evaluate(args[i]);
        if (current.token.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current.token, "boolean");
        } else {
            result |= (cast(BooleanToken)current.token).boolValue;
        }
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinNot (string name, Value[] args, string[Value] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluate(args[0]);
    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    }

    return new Value(new BooleanToken(!(cast(BooleanToken)current.token).boolValue));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEq (string name, Value[] args, string[Value] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value obj1 = evaluate(args[0]);
    Value obj2 = evaluate(args[1]);

    return new Value(new BooleanToken(objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinNeq (string name, Value[] args, string[Value] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value obj1 = evaluate(args[0]);
    Value obj2 = evaluate(args[1]);

    return new Value(new BooleanToken(!objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["NULL"] = &builtinNull;
    builtinTable["IF"] = &builtinIf;
    builtinTable["COND"] = &builtinCond;
    builtinTable["AND"] = &builtinAnd;
    builtinTable["OR"] = &builtinOr;
    builtinTable["NOT"] = &builtinNot;
    builtinTable["EQ"] = &builtinEq;
    builtinTable["NEQ"] = &builtinNeq;
    return builtinTable;
}