module builtin.system;

import std.c.stdlib;

import functions;
import token;

BooleanToken builtinExit (string name, Token args) {
    int exitCode = 0;

    if (args.type == TokenType.reference) {
        Token exitCodeToken = (cast(ReferenceToken)args).reference.car;
        if (exitCodeToken.type != TokenType.integer) {
            throw new Exception("Exit code must be an integer");
        } else {
            exitCode = (cast(IntegerToken)exitCodeToken).intValue;
        }
    }

    exit(exitCode);
    return null;
}

void addBuiltins (out BuiltinFunction[string] builtinTable) {
    builtinTable["EXIT"] = &builtinExit;
}