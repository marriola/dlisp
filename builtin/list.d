module builtin.list;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinMakeArray (string name, Value[] args) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    if (args[0].token.type == TokenType.integer) {
        Value lengthToken = evaluate(args[0]);
        return new Value(new VectorToken((cast(IntegerToken)lengthToken.token).intValue));

    } else if (args[0].token.type == TokenType.reference) {
        Value[] list = toArray(evaluateOnce(args[0]));
        Value vector = new Value(new VectorToken(list.length));
        for (int i = 0; i < list.length; i++) {
            (cast(VectorToken)vector.token).array[i] = list[i];
        }
        return vector;

    } else {
        throw new TypeMismatchException(name, args[0].token, "integer or list");
    }

}


///////////////////////////////////////////////////////////////////////////////

Value builtinList (string name, Value[] args) {
    if (args.length == 0) {
        return new Value(new BooleanToken(false));
    }

    Value head = Token.makeReference(evaluateOnce(args[0]));
    Value current = head;
    for (int i = 1; i < args.length; i++) {
        (cast(ReferenceToken)current.token).reference.cdr = Token.makeReference(evaluateOnce(args[i]));
        current = (cast(ReferenceToken)current.token).reference.cdr;
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDo (string name, Value[] args) {
    Value lastResult = new Value(new BooleanToken(false));

    for (int i = 0; i < args.length; i++) {
        lastResult = evaluate(args[i]);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinQuote (string name, Value[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return args[0];
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCons (string name, Value[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value car = evaluate(args[0]);
    Value cdr = evaluate(args[1]);
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCar (string name, Value[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getFirst(args[0]);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCdr (string name, Value[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getRest(args[0]);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinElt (string name, Value[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value indexToken = evaluateOnce(args[1]);
    if (indexToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, indexToken.token, "integer");
    }
    int index = (cast(IntegerToken)indexToken.token).intValue;

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

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["MAKE-ARRAY"] = &builtinMakeArray;
    builtinTable["LIST"] = &builtinList;
    builtinTable["DO"] = &builtinDo;
    builtinTable["QUOTE"] = &builtinQuote;
    builtinTable["CONS"] = &builtinCons;
    builtinTable["CAR"] = &builtinCar;
    builtinTable["FIRST"] = &builtinCar;
    builtinTable["CDR"] = &builtinCdr;
    builtinTable["REST"] = &builtinCdr;
    builtinTable["ELT"] = &builtinElt;
    return builtinTable;
}