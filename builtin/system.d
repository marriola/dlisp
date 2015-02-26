module builtin.system;

import std.c.stdlib;

import evaluator;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinExit (string name, Token[] args) {
    int exitCode = 0;

    if (args.length > 0) {
        Token exitCodeToken = evaluate(args[0]);
        if (exitCodeToken.type != TokenType.integer) {
            throw new Exception("Exit code must be an integer");
        } else {
            exitCode = (cast(IntegerToken)exitCodeToken).intValue;
        }
    }

    exit(exitCode);
    return null;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["EXIT"] = &builtinExit;
    return builtinTable;
}