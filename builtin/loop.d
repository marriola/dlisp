module builtin.loop;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinDotimes (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value loopVariable = getItem(args[0], 0);
    Value count = evaluate(getItem(args[0], 1));
    Value result = evaluate(getItem(args[0], 2));
    Value[] loopBody = args[1 .. args.length];

    if (count.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, count.token, "integer");
    }

    long n = (cast(IntegerToken)count.token).intValue;
    for (long i = 0; i < n; i++) {
        foreach (Value form; loopBody) {
            evaluateOnce(form);
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["DOTIMES"] = &builtinDotimes;
    return builtinTable;
}