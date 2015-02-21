module builtin.system;

import std.c.stdlib;

import functions;
import lispObject;
import token;

Token builtinExit (string name, ReferenceToken args) {
    int exitCode = 0;

    if (hasMore(args)) {
        Token exitCodeToken = getFirst(args);
        if (exitCodeToken.type != TokenType.integer) {
            throw new Exception("Exit code must be an integer");
        } else {
            exitCode = (cast(IntegerToken)exitCodeToken).intValue;
        }
    }

    exit(exitCode);
    return null;
}

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["EXIT"] = &builtinExit;
    return builtinTable;
}