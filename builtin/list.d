module builtin.list;

import std.container.array;
import std.array : array;
import std.conv : to;

import evaluator;
import exceptions;
import functions;
import lispObject;
import node;
import token;
import util;
import variables;

import std.zlib;

///////////////////////////////////////////////////////////////////////////////

Value builtinMakeArray (string name) {
    Value size = getParameter("SIZE");

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
    Value sizeToken = getParameter("SIZE");
    Value initialElement = getParameter("INITIAL-ELEMENT");

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
    Value list = getParameter("LIST");
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
    Value[] objects = toArray(getParameter("OBJECTS"));
    if (objects.length == 0){
        return Value.nil();
    }

    Value head = Token.makeReference(objects[0]);
    for (int i = 1; i < objects.length; i++) {
        (cast(ReferenceToken)head.token).append(Token.makeReference(objects[i]));
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLength (string name) {
    Value list = getParameter("LIST");
    return new Value(new IntegerToken(listLength(list)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinProgn (string name) {
    Value[] forms = toArray(getParameter("FORMS"));
    Value lastResult = Value.nil();
    foreach (Value form; forms) {
        lastResult = form;

    }
    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinQuote (string name) {
    return getParameter("OBJECT");
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCons (string name) {
    Value car = getParameter("CAR");
    Value cdr = getParameter("CDR");
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCar (string name) {
    return getFirst(getParameter("LIST"));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCdr (string name) {
    return getRest(getParameter("LIST"));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCompoundAccessor (string name) {
    string accessPath = name[1 .. name.length - 1];
    Value x = getParameter("LIST");

    foreach_reverse (char c; accessPath) {
        if (x.token.type != TokenType.reference) {
            throw new TypeMismatchException(name, x.token, "reference");
        }

        if (c == 'A') {
            x = (cast(ReferenceToken)x.token).reference.car;

        } else if (c == 'D') {
            x = (cast(ReferenceToken)x.token).reference.cdr;
        }
    }

    return x;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinElt (string name) {
    Value list = getParameter("LIST");
    Value indexToken = getParameter("INDEX");

    if (list.token.type != TokenType.reference) {
        throw new TypeMismatchException(name, list.token, "list");
    }

    if (indexToken.token.type == TokenType.integer) {
        int index = to!int((cast(IntegerToken)indexToken.token).intValue);
        return getItem(list, index);

    } else {
        throw new TypeMismatchException(name, indexToken.token, "integer");
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinAref (string name) {
    Value vector = getParameter("ARRAY");
    Value indexToken = getParameter("INDEX");

    if (vector.token.type != TokenType.vector) {
        throw new TypeMismatchException(name, vector.token, "vector");

    } else if (indexToken.token.type == TokenType.integer) {
        int index = to!int((cast(IntegerToken)indexToken.token).intValue);
        return (cast(VectorToken)vector.token).getItem(index);

    } else if (indexToken.token.type == TokenType.reference) {
        Value[] indicesArray = toArray(indexToken);
        int[] indices = map!(x => to!int((cast(IntegerToken)x.token).intValue))(indicesArray).array();
        return (cast(VectorToken)vector.token).getItem(indices);
    }

    assert(0);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinAppend (string name) {
    Value result = Value.nil();
    Value lastItem = result;
    Value[] lists = toArray(getParameter("LISTS"));

    foreach (int i, Value item; lists) {
        item = item.copy();

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
    Value[] sequences = toArray(getParameter("SEQUENCES"));
    Value result = sequences[0].copy();
    if (result.token.type != TokenType.string) {
        throw new TypeMismatchException(name, result.token, "string");
    }

    foreach (Value sequence; sequences[1 .. sequences.length]) {
        Value str = sequence;
        if (str.token.type != TokenType.string) {
            throw new TypeMismatchException(name, str.token, "string");
        }

        (cast(StringToken)result.token).stringValue ~= (cast(StringToken)str.token).stringValue;
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinString (string name) {
    Value character = getParameter("CHARACTER");
    if (character.token.type != TokenType.character) {
        throw new TypeMismatchException(name, character.token, "character");
    }

    return new Value(new StringToken("" ~ (cast(CharacterToken)character.token).charValue));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMap (string name) {
    Value resultTypeToken = getParameter("RESULT-TYPE");
    Value mapFunction = getParameter("FUNCTION");
    Value[] sequences = toArray(getParameter("SEQUENCES"));

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
    if (mapFunction.token.type != TokenType.compiledFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }

    return map(resultType, mapFunction, sequences);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMapcar (string name) {
    Value mapFunction = getParameter("FUNCTION");
    Value[] sequences = toArray(getParameter("SEQUENCES"));
    if (mapFunction.token.type != TokenType.compiledFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }
    return map(TokenType.reference, mapFunction, sequences);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRemoveIf (string name) {
    Value predicateToken = getParameter("PREDICATE");
    Value list = getParameter("LIST");

    FunctionToken predicate;
    Value result = Value.nil();

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.compiledFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!list.isNil()) {
        Value item = getFirst(list);
        Value testResult = predicate.evaluate([item]);
        if (!Token.isTrue(testResult)) {
            result.append(Token.makeReference(item));
        }
        list = getRest(list);
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRemoveIfNot (string name) {
    Value predicateToken = getParameter("PREDICATE");
    Value list = getParameter("LIST");

    FunctionToken predicate;
    Value result = Value.nil();

    if (predicateToken.token.type != TokenType.builtinFunction && predicateToken.token.type != TokenType.compiledFunction) {
        throw new TypeMismatchException(name, predicateToken.token, "function");
    } else {
        predicate = cast(FunctionToken)predicateToken.token;
    }

    while (!list.isNil()) {
        Value item = getFirst(list);
        Value testResult = predicate.evaluate([item]);
        if (Token.isTrue(testResult)) {
            result.append(Token.makeReference(item));
        }
        list = getRest(list);
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSerializeFunction(string name) {
	Value streamToken = getParameter("STREAM");
	std.stdio.File stream = (cast(FileStreamToken)streamToken.token).stream;

	Value form = getParameter("FORM");
	ubyte[] bytes = [cast(ubyte)'F'] ~ cast(ubyte[])compress((cast(CompiledFunctionToken)form.token).fun.bytecode.serialize());

	stream.rawWrite(asBytes(bytes.length, 4));
	stream.rawWrite(bytes);

	return Value.nil();
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSerialize(string name) {
	Value streamToken = getParameter("STREAM");
	std.stdio.File stream = (cast(FileStreamToken)streamToken.token).stream;

	Value form = getParameter("FORM");
	ubyte[] bytes = [cast(ubyte)'T'] ~ cast(ubyte[])compress(Token.serialize(form.token));

	stream.rawWrite(asBytes(bytes.length, 4));
	stream.rawWrite(bytes);

	return Value.nil();
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDeserialize(string name) {
	Value streamToken = getParameter("STREAM");
	std.stdio.File stream = (cast(FileStreamToken)streamToken.token).stream;
	auto objectSize = fromBytes!uint(stream, 4);
	auto bytes = new ubyte[objectSize];
	stream.rawRead(bytes);
	bytes = cast(ubyte[])uncompress(bytes);

	auto type = cast(char)bytes[0];

	switch (type) {
		case 'T':
			auto tokenType = fromBytes!TokenType(bytes[1..4]);
			auto size = fromBytes!uint(bytes[5..8]);
			bytes = bytes[9..$];
			auto token = Token.deserialize(tokenType, bytes[0 .. size - 1]);
			return new Value(token);

		default:
			throw new Exception("Invalid object type");
	}
}

///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("MAKE-ARRAY", &builtinMakeArray, [Parameter("SIZE")]);
    addFunction("MAKE-LIST", &builtinMakeList, [Parameter("SIZE")], null, [Parameter("INITIAL-ELEMENT", Value.nil())]);
    addFunction("COPY-LIST", &builtinMakeArray, [Parameter("LIST")]);
    addFunction("LIST", &builtinList, null, null, null, null, Parameter("OBJECTS"));
    addFunction("LENGTH", &builtinLength, [Parameter("LIST")]);
    addFunction("PROGN", &builtinProgn, null, null, null, null, Parameter("FORMS"));
    addFunction("QUOTE", &builtinQuote, [Parameter("OBJECT")]);
    addFunction("CONS", &builtinCons, [Parameter("CAR"), Parameter("CDR")]);
    addFunction("CAR", &builtinCar, [Parameter("LIST")]);
    addFunction("FIRST", &builtinCar, [Parameter("LIST")]);
    addFunction("CDR", &builtinCdr, [Parameter("LIST")]);
    addFunction("REST", &builtinCdr, [Parameter("LIST")]);

    foreach (string fun; ["CAAR", "CADR", "CDAR", "CDDR", "CAAAR", "CAADR",
                          "CADAR", "CADDR", "CDAAR", "CDADR", "CDDAR",
                          "CDDDR", "CAAAAR", "CAAADR", "CAADAR", "CAADDR",
                          "CADAAR", "CADADR", "CADDAR", "CADDDR", "CDAAAR",
                          "CDAADR", "CDADAR", "CDADDR", "CDDAAR", "CDDADR",
                          "CDDDAR", "CDDDDR"]) {
        addFunction(fun, &builtinCompoundAccessor, [Parameter("LIST")]);
    }

    addFunction("ELT", &builtinElt, [Parameter("LIST"), Parameter("INDEX")]);
    addFunction("AREF", &builtinAref, [Parameter("ARRAY"), Parameter("INDEX")]);
    addFunction("APPEND", &builtinAppend, null, null, null, null, Parameter("LISTS"));
    addFunction("CONCATENATE", &builtinConcatenate, [Parameter("RESULT-TYPE")], null, null, null, Parameter("SEQUENCES"));
    addFunction("STRING", &builtinString, [Parameter("CHARACTER")]);
    addFunction("MAP", &builtinMap, [Parameter("RESULT-TYPE"), Parameter("FUNCTION")], null, null, null, Parameter("SEQUENCES"));
    addFunction("MAPCAR", &builtinMapcar, [Parameter("FUNCTION")], null, null, null, Parameter("SEQUENCES"));
    addFunction("REMOVE-IF", &builtinRemoveIf, [Parameter("PREDICATE"), Parameter("LIST")]);
    addFunction("REMOVE-IF-NOT", &builtinRemoveIfNot, [Parameter("PREDICATE"), Parameter("LIST")]);
	addFunction("SERIALIZE-FUNCTION", &builtinSerializeFunction, [Parameter("STREAM"), Parameter("FORM")]);
	addFunction("SERIALIZE", &builtinSerialize, [Parameter("STREAM"), Parameter("FORM", false)]);
	addFunction("DESERIALIZE", &builtinDeserialize, [Parameter("STREAM")]);
}