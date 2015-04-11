module builtin.list;

import std.conv;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinMakeArray (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value arg = evaluateOnce(args[0]);

    if (arg.token.type == TokenType.integer) {
        return new Value(new VectorToken(to!int((cast(IntegerToken)arg.token).intValue)));

    } else if (arg.token.type == TokenType.reference) {
        Value[] list = toArray(evaluateOnce(arg));
        Value vector = new Value(new VectorToken(list.length));
        for (int i = 0; i < list.length; i++) {
            (cast(VectorToken)vector.token).array[i] = list[i];
        }
        return vector;

    } else {
        throw new TypeMismatchException(name, arg.token, "integer or list");
    }

}


///////////////////////////////////////////////////////////////////////////////

Value builtinList (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        return new Value(new BooleanToken(false));
    }

    Value head = Token.makeReference(evaluateOnce(args[0]));
    for (int i = 1; i < args.length; i++) {
        (cast(ReferenceToken)head.token).append(evaluateOnce(args[i]));
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinProgn (string name, Value[] args, Value[string] kwargs) {
    Value lastResult = new Value(new BooleanToken(false));

    for (int i = 0; i < args.length; i++) {
        lastResult = evaluateOnce(args[i]);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinQuote (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return args[0];
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCons (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value car = evaluateOnce(args[0]);
    Value cdr = evaluateOnce(args[1]);
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCar (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getFirst(evaluateOnce(args[0]));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCdr (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getRest(evaluateOnce(args[0]));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinElt (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value indexToken = evaluateOnce(args[1]);
    if (indexToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, indexToken.token, "integer");
    }
    int index = to!int((cast(IntegerToken)indexToken.token).intValue);

    Value obj = evaluateOnce(args[0]);

    if (obj.token.type == TokenType.reference) {
        return getItem(obj, index);

    } else if (obj.token.type == TokenType.vector) {
        Value[] array = (cast(VectorToken)obj.token).array;
        if (index > array.length) {
            throw new OutOfBoundsException(index);
        }
        return array[index];

    } else {
        throw new TypeMismatchException(name, obj.token, "reference or vector");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinAppend (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value result = evaluateOnce(args[0]);
    if (result.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, result.token, "reference");
    }

    Value lastItem = result;
    while (!Token.isNil((cast(ReferenceToken)lastItem.token).reference.cdr)) {
        lastItem = (cast(ReferenceToken)lastItem.token).reference.cdr;
    }

    for (int i = 1; i < args.length; i++) {
        Value list = evaluateOnce(args[i]);
        if (list.token.type == TokenType.boolean && (cast(BooleanToken)list.token).boolValue == false) {
            continue;
        } else if (list.token.type != TokenType.reference) {
            throw new TypeMismatchException(name, list.token, "reference or NIL");
        }
        (cast(ReferenceToken)lastItem.token).reference.cdr = list;
        while (!Token.isNil((cast(ReferenceToken)lastItem.token).reference.cdr)) {
            lastItem = (cast(ReferenceToken)lastItem.token).reference.cdr;
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMap (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Value resultTypeToken = evaluateOnce(args[0]);
    TokenType resultType;
    if (resultTypeToken.token.type != TokenType.identifier) {
        throw new TypeMismatchException(name, resultTypeToken.token, "identifier");
    }

    switch ((cast(IdentifierToken)resultTypeToken.token).stringValue) {
        case "LIST":
            resultType = TokenType.reference;
            break;

        case "VECTOR":
            resultType = TokenType.vector;
            break;

        default:
            throw new TypeMismatchException(name, resultTypeToken.token, "list or vector");
    }

    // type check function argument
    Value mapFunction = evaluateOnce(args[1]);
    if (mapFunction.token.type != TokenType.definedFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }

    return map(resultType, mapFunction, args[2 .. args.length]);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMapcar (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    // type check function argument
    Value mapFunction = evaluateOnce(args[0]);
    if (mapFunction.token.type != TokenType.definedFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }

    return map(TokenType.reference, mapFunction, args[1 .. args.length]);
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["MAKE-ARRAY"] = &builtinMakeArray;
    builtinTable["LIST"] = &builtinList;
    builtinTable["PROGN"] = &builtinProgn;
    builtinTable["QUOTE"] = &builtinQuote;
    builtinTable["CONS"] = &builtinCons;
    builtinTable["CAR"] = &builtinCar;
    builtinTable["FIRST"] = &builtinCar;
    builtinTable["CDR"] = &builtinCdr;
    builtinTable["REST"] = &builtinCdr;
    builtinTable["ELT"] = &builtinElt;
    builtinTable["APPEND"] = &builtinAppend;
    builtinTable["MAP"] = &builtinMap;
    builtinTable["MAPCAR"] = &builtinMapcar;
    return builtinTable;
}