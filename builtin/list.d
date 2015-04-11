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
        Value lengthToken = evaluate(arg);
        return new Value(new VectorToken(to!int((cast(IntegerToken)lengthToken.token).intValue)));

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
        lastResult = evaluate(args[i]);
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

    Value car = evaluate(args[0]);
    Value cdr = evaluate(args[1]);
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

Value builtinMapcar (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    // type check list arguments and get length of shortest one
    int shortestList = int.max;

    for (int i = 1; i < args.length; i++) {
        Value argument;
        argument = args[i] = evaluateOnce(args[i]);
        if (argument.token.type != TokenType.reference) {
            throw new TypeMismatchException(name, argument.token, "reference");
        }

        int len = listLength(argument);
        if (len < shortestList) {
            shortestList = len;
        }
    }

    // type check function argument
    Value mapFunction = evaluateOnce(args[0]);
    if (mapFunction.token.type != TokenType.definedFunction && mapFunction.token.type != TokenType.builtinFunction) {
        throw new TypeMismatchException(name, mapFunction.token, "function");
    }

    Value result = new Value(new BooleanToken(false));
    Value[] lists = args[1 .. args.length];
    for (int i = 0; i < shortestList; i++) {
        Value[] crossSection;
        for (int j = 0; j < lists.length; j++) {
            crossSection ~= getFirst(lists[j]);
            lists[j] = getRest(lists[j]);
        }
        result.append((cast(FunctionToken)mapFunction.token).evaluate(crossSection));
    }

    return result;
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
    builtinTable["MAPCAR"] = &builtinMapcar;
    return builtinTable;
}