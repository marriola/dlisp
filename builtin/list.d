module builtin.list;

import functions;
import list;
import token;


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

    Token car = getFirst(args);
    Token cdr = getFirst(getRest(args));
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

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["QUOTE"] = &builtinQuote;
    builtinTable["CONS"] = &builtinCons;
    builtinTable["CAR"] = &builtinCar;
    builtinTable["FIRST"] = &builtinCar;
    builtinTable["CDR"] = &builtinCdr;
    builtinTable["REST"] = &builtinCdr;
    return builtinTable;
}