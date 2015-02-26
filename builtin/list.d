module builtin.list;

import evaluator;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinDo (string name, ReferenceToken args) {
    Token lastResult = new BooleanToken(false);

    while (hasMore(args)) {
        lastResult = evaluate(getFirst(args));
        args = getRest(args);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Token builtinQuote (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    return getFirst(args);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCons (string name, ReferenceToken args) {
    if (listLength(args) < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token car = evaluate(getFirst(args));
    Token cdr = evaluate(getFirst(getRest(args)));
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCar (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    return getFirst(getFirst(args));
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCdr (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    return getRest(getFirst(args));
}


///////////////////////////////////////////////////////////////////////////////

Token builtinElt (string name, ReferenceToken args) {
    Token obj = evaluate(getFirst(args));
    if (obj.type != TokenType.reference) {
        throw new TypeMismatchException(name, obj, "reference");
    }

    args = getRest(args);
    Token index = evaluate(getFirst(args));
    if (index.type != TokenType.integer) {
        throw new TypeMismatchException(name, index, "integer");
    }

    return getItem(cast(ReferenceToken)obj, (cast(IntegerToken)index).intValue);
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
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