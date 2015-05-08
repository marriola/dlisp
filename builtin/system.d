module builtin.system;

import std.c.stdlib;

import evaluator;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinExit (string name) {
    Value exitCodeToken = evaluate(getParameter("EXIT-CODE"));
    int exitCode = cast(int)(cast(IntegerToken)exitCodeToken.token).intValue;
    exit(exitCode);
    return null;
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("EXIT", &builtinExit, null, [Parameter("EXIT-CODE", new Value(new IntegerToken(0)))]);
}