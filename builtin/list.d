module builtin.list;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinDo (string name, Token[] args) {
    Token lastResult = new BooleanToken(false);

    for (int i = 0; i < args.length; i++) {
        lastResult = evaluate(args[i]);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Token builtinQuote (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return args[0];
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCons (string name, Token[] args) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Token car = evaluate(args[0]);
    Token cdr = evaluate(args[1]);
    return Token.makeReference(car, cdr);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCar (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getFirst(args[0]);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinCdr (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    return getRest(args[0]);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinElt (string name, Token[] args) {
    Token obj = evaluate(args[0]);
    if (obj.type != TokenType.reference) {
        throw new TypeMismatchException(name, obj, "reference");
    }

    Token index = evaluate(args[1]);
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