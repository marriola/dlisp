module builtin.list;

import std.conv;

import evaluator;
import exceptions;
import functions;
import lispObject;
import node;
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

Value builtinCopyList (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value list = evaluateOnce(args[0]);
    if (Token.isNil(list)) {
        return new Value(new BooleanToken(false));

    } else if (list.token.type == TokenType.reference) {
        return list.copy();

    } else {
        throw new TypeMismatchException(name, list.token, "list");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinList (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        return new Value(new BooleanToken(false));
    }

    Value head = Token.makeReference(evaluateOnce(args[0]));
    for (int i = 1; i < args.length; i++) {
        (cast(ReferenceToken)head.token).append(Token.makeReference(evaluateOnce(args[i])));
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLength (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value list = evaluateOnce(args[0]);
    return new Value(new IntegerToken(listLength(list)));
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

Value builtinCompoundAccessor (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    string accessPath = name[1 .. name.length - 1];
    Value x = evaluateOnce(args[0]);

    foreach_reverse (char c; accessPath) {
        if (x.token.type != TokenType.reference) {
            throw new TypeMismatchException(name, x.token, "reference");
        }

        if (c == 'A') {
            x = (cast(ReferenceToken)x.token).reference.car;

        } else if (c == 'R') {
            x = (cast(ReferenceToken)x.token).reference.cdr;
        }
    }

    return x;
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

    Value result = new Value(new BooleanToken(false));
    Value lastItem = result;

    foreach (int i, Value item; args) {
        item = evaluateOnce(item).copy();

        // skip empty lists
        if (!Token.isNil(item)) {
            if (item.token.type == TokenType.reference) {
                // added item must be a list
                lastItem = lastItem.append(item);

            } else if (i == args.length - 1) {
                // ...unless it's the last argument
                lastItem = lastItem.append(item);

            } else {
                throw new TypeMismatchException(name, item.token, "list");
            }
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinConcatenate (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value result = evaluateOnce(args[1]).copy();
    if (result.token.type != TokenType.string) {
        throw new TypeMismatchException(name, result.token, "string");
    }

    foreach (Value arg; args[2 .. args.length]) {
        Value str = evaluateOnce(arg);
        if (str.token.type != TokenType.string) {
            throw new TypeMismatchException(name, str.token, "string");
        }

        (cast(StringToken)result.token).stringValue ~= (cast(StringToken)str.token).stringValue;
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinString (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value arg = evaluateOnce(args[0]);
    if (arg.token.type != TokenType.character) {
        throw new TypeMismatchException(name, arg.token, "character");
    }

    return new Value(new StringToken("" ~ (cast(CharacterToken)arg.token).charValue));
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

Value builtinRemoveIf (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value predicateToken = evaluateOnce(args[0]);
    FunctionToken predicate;

    Value list = evaluateOnce(args[1]);
    Value result = new Value(new BooleanToken(false));

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.definedFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!Token.isNil(list)) {
        Value item = getFirst(list);
        Value testResult = predicate.evaluate([item]);
        if (!Token.isTrue(testResult)) {
            result.append(item);
        }
        list = getRest(list);
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRemoveIfNot (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value predicateToken = evaluateOnce(args[0]);
    FunctionToken predicate;

    Value list = evaluateOnce(args[1]);
    Value result = new Value(new BooleanToken(false));

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.definedFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!Token.isNil(list)) {
        Value item = getFirst(list);
        Value testResult = predicate.evaluate([item]);
        if (Token.isTrue(testResult)) {
            result.append(item);
        }
        list = getRest(list);
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["MAKE-ARRAY"] = &builtinMakeArray;
    builtinTable["COPY-LIST"] = &builtinCopyList;
    builtinTable["LIST"] = &builtinList;
    builtinTable["LENGTH"] = &builtinLength;
    builtinTable["PROGN"] = &builtinProgn;
    builtinTable["QUOTE"] = &builtinQuote;
    builtinTable["CONS"] = &builtinCons;
    builtinTable["CAR"] = &builtinCar;
    builtinTable["FIRST"] = &builtinCar;
    builtinTable["CDR"] = &builtinCdr;
    builtinTable["REST"] = &builtinCdr;

    foreach (string fun; ["CAAR", "CADR", "CDAR", "CDDR", "CAAAR", "CAADR",
                          "CADAR", "CADDR", "CDAAR", "CDADR", "CDDAR",
                          "CDDDR", "CAAAAR", "CAAADR", "CAADAR", "CAADDR",
                          "CADAAR", "CADADR", "CADDAR", "CADDDR", "CDAAAR",
                          "CDAADR", "CDADAR", "CDADDR", "CDDAAR", "CDDADR",
                          "CDDDAR", "CDDDDR"]) {
        builtinTable[fun] = &builtinCompoundAccessor;
    }

    builtinTable["ELT"] = &builtinElt;
    builtinTable["APPEND"] = &builtinAppend;
    builtinTable["CONCATENATE"] = &builtinConcatenate;
    builtinTable["STRING"] = &builtinString;
    builtinTable["MAP"] = &builtinMap;
    builtinTable["MAPCAR"] = &builtinMapcar;
    builtinTable["REMOVE-IF"] = &builtinRemoveIf;
    builtinTable["REMOVE-IF-NOT"] = &builtinRemoveIfNot;
    return builtinTable;
}