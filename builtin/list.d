module builtin.list;

import std.array : array;
import std.conv : to;

import evaluator;
import exceptions;
import functions;
import lispObject;
import node;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinMakeArray (string name) {
    Value size = evaluateOnce(getVariable("SIZE"));

    if (size.token.type == TokenType.integer) {
        return new Value(new VectorToken(to!int((cast(IntegerToken)size.token).intValue)));

    } else if (size.token.type == TokenType.reference) {
        return new Value(new VectorToken(map!(x => to!int((cast(IntegerToken)x.token).intValue))(toArray(size)).array()));

    } else {
        throw new TypeMismatchException(name, size.token, "integer or list");
    }

}


///////////////////////////////////////////////////////////////////////////////

Value builtinMakeList (string name) {
    Value sizeToken = evaluateOnce(getVariable("SIZE"));
    Value initialElement = evaluateOnce(getVariable("INITIAL-ELEMENT"));

    if (sizeToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, sizeToken.token, "integer");
    }

    long size = (cast(IntegerToken)sizeToken.token).intValue;

    if (size == 0) {
        return Value.nil();

    } else {
        Value head = Token.makeReference(initialElement.copy());
        Value last = head;
        size--;
        for (int i = 0; i < size; i++) {
            (cast(ReferenceToken)last.token).reference.cdr = Token.makeReference(initialElement.copy());
            last = (cast(ReferenceToken)last.token).reference.cdr;
        }
        return head;
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCopyList (string name) {
    Value list = evaluateOnce(getVariable("LIST"));
    if (list.isNil()) {
        return Value.nil();

    } else if (list.token.type == TokenType.reference) {
        return list.copy();

    } else {
        throw new TypeMismatchException(name, list.token, "list");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinList (string name) {
    Value[] objects = toArray(getVariable("OBJECTS"));
    if (objects.length == 0){
        return Value.nil();
    }

    Value head = Token.makeReference(evaluateOnce(objects[0]));
    for (int i = 1; i < objects.length; i++) {
        (cast(ReferenceToken)head.token).append(Token.makeReference(evaluateOnce(objects[i])));
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLength (string name) {
    Value list = evaluateOnce(getVariable("LIST"));
    return new Value(new IntegerToken(listLength(list)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinProgn (string name) {
    Value[] forms = toArray(getVariable("FORMS"));
    Value lastResult = Value.nil();
    foreach (Value form; forms) {
        lastResult = evaluateOnce(form);

    }
    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinQuote (string name) {
    return getVariable("OBJECT");
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCons (string name) {
    Value car = evaluateOnce(getVariable("CAR"));
    Value cdr = evaluateOnce(getVariable("CDR"));
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCar (string name) {
    return getFirst(evaluateOnce(getVariable("LIST")));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCdr (string name) {
    return getRest(evaluateOnce(getVariable("LIST")));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCompoundAccessor (string name) {
    string accessPath = name[1 .. name.length - 1];
    Value x = evaluateOnce(getVariable("LIST"));

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

Value builtinElt (string name) {
    Value object = evaluateOnce(getVariable("OBJECT"));
    Value indexToken = evaluateOnce(getVariable("INDEX"));

    if (indexToken.token.type == TokenType.integer) {
        int index = to!int((cast(IntegerToken)indexToken.token).intValue);
        if (object.token.type == TokenType.reference) {
            return getItem(object, index);
        } else if (object.token.type == TokenType.vector) {
            return (cast(VectorToken)object.token).getItem(index);
        } else {
            throw new TypeMismatchException(name, object.token, "reference or vector");
        }

    } else if (indexToken.token.type == TokenType.reference) {
        Value[] indicesArray = toArray(indexToken);
        int[] indices = map!(x => to!int((cast(IntegerToken)x.token).intValue))(indicesArray).array();
        if (object.token.type == TokenType.vector) {
            return (cast(VectorToken)object.token).getItem(indices);
        } else {
            return null;
        }

    } else {
        throw new TypeMismatchException(name, indexToken.token, "integer or list");
    }


}


///////////////////////////////////////////////////////////////////////////////

Value builtinAppend (string name) {
    Value result = Value.nil();
    Value lastItem = result;
    Value[] lists = toArray(getVariable("LISTS"));

    foreach (int i, Value item; lists) {
        item = evaluateOnce(item).copy();

        // skip empty lists
        if (!item.isNil()) {
            if (item.token.type == TokenType.reference) {
                // added item must be a list
                lastItem = lastItem.append(item);

            } else if (i == lists.length - 1) {
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

Value builtinConcatenate (string name) {
    Value[] sequences = toArray(getVariable("SEQUENCES"));
    Value result = evaluateOnce(sequences[0]).copy();
    if (result.token.type != TokenType.string) {
        throw new TypeMismatchException(name, result.token, "string");
    }

    foreach (Value sequence; sequences[1 .. sequences.length]) {
        Value str = evaluateOnce(sequence);
        if (str.token.type != TokenType.string) {
            throw new TypeMismatchException(name, str.token, "string");
        }

        (cast(StringToken)result.token).stringValue ~= (cast(StringToken)str.token).stringValue;
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinString (string name) {
    Value character = evaluateOnce(getVariable("CHARACTER"));
    if (character.token.type != TokenType.character) {
        throw new TypeMismatchException(name, character.token, "character");
    }

    return new Value(new StringToken("" ~ (cast(CharacterToken)character.token).charValue));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMap (string name) {
    Value resultTypeToken = evaluateOnce(getVariable("RESULT-TYPE"));
    Value mapFunction = evaluateOnce(getVariable("FUNCTION"));
    Value[] sequences = toArray(getVariable("SEQUENCES"));

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
    if (mapFunction.token.type != TokenType.definedFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }

    return map(resultType, mapFunction, sequences);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMapcar (string name) {
    Value mapFunction = evaluateOnce(getVariable("FUNCTION"));
    Value[] sequences = toArray(getVariable("SEQUENCES"));
    if (mapFunction.token.type != TokenType.definedFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }
    return map(TokenType.reference, mapFunction, sequences);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRemoveIf (string name) {
    Value predicateToken = evaluateOnce(getVariable("PREDICATE"));
    Value list = evaluateOnce(getVariable("LIST"));

    FunctionToken predicate;
    Value result = Value.nil();

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.definedFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!list.isNil()) {
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

Value builtinRemoveIfNot (string name) {
    Value predicateToken = evaluateOnce(getVariable("PREDICATE"));
    Value list = evaluateOnce(getVariable("LIST"));

    FunctionToken predicate;
    Value result = Value.nil();

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.definedFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!list.isNil()) {
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

void addBuiltins () {
    addFunction("MAKE-ARRAY", &builtinMakeArray, Parameters(["SIZE"]));
    addFunction("MAKE-LIST", &builtinMakeList, Parameters(["SIZE"], null, [PairedArgument("INITIAL-ELEMENT", Value.nil())]));
    addFunction("COPY-LIST", &builtinMakeArray, Parameters(["LIST"]));
    addFunction("LIST", &builtinList, Parameters(["LIST"]));
    addFunction("LENGTH", &builtinList, Parameters(["LIST"]));
    addFunction("PROGN", &builtinProgn, Parameters(null, null, null, null, "FORMS"));
    addFunction("QUOTE", &builtinQuote, Parameters(["OBJECT"]));
    addFunction("CONS", &builtinCons, Parameters(["CAR", "CDR"]));
    addFunction("CAR", &builtinCar, Parameters(["LIST"]));
    addFunction("FIRST", &builtinCar, Parameters(["LIST"]));
    addFunction("CDR", &builtinCdr, Parameters(["LIST"]));
    addFunction("REST", &builtinCdr, Parameters(["LIST"]));

    foreach (string fun; ["CAAR", "CADR", "CDAR", "CDDR", "CAAAR", "CAADR",
                          "CADAR", "CADDR", "CDAAR", "CDADR", "CDDAR",
                          "CDDDR", "CAAAAR", "CAAADR", "CAADAR", "CAADDR",
                          "CADAAR", "CADADR", "CADDAR", "CADDDR", "CDAAAR",
                          "CDAADR", "CDADAR", "CDADDR", "CDDAAR", "CDDADR",
                          "CDDDAR", "CDDDDR"]) {
        addFunction(fun, &builtinCompoundAccessor, Parameters(["LIST"]));
    }

    addFunction("ELT", &builtinElt, Parameters(["OBJECT", "INDEX"]));
    addFunction("APPEND", &builtinAppend, Parameters(null, null, null, null, "LISTS"));
    addFunction("CONCATENATE", &builtinConcatenate, Parameters(["RESULT-TYPE"], null, null, null, "SEQUENCES"));
    addFunction("STRING", &builtinString, Parameters(["CHARACTER"]));
    addFunction("MAP", &builtinMap, Parameters(["RESULT-TYPE", "FUNCTION", "LIST"]));
    addFunction("MAPCAR", &builtinMapcar, Parameters(["FUNCTION", "LIST"]));
    addFunction("REMOVE-IF", &builtinRemoveIf, Parameters(["PREDICATE", "LIST"]));
    addFunction("REMOVE-IF-NOT", &builtinRemoveIfNot, Parameters(["PREDICATE", "LIST"]));
}