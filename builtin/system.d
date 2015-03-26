module builtin.system;

import std.c.stdlib;

import evaluator;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinExit (string name, Value[] args) {
    int exitCode = 0;

    if (args.length > 0) {
        Value exitCodeToken = evaluate(args[0]);
        if (exitCodeToken.token.type != TokenType.integer) {
            throw new Exception("Exit code must be an integer");
        } else {
            exitCode = (cast(IntegerToken)exitCodeToken.token).intValue;
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