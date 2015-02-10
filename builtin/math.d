module builtin.math;

import functions;
import token;

Token builtinPlus (string name, Token args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    while (args.type == TokenType.reference) {
        Token current = (cast(ReferenceToken)args).reference.car;
        if (!isFloat && current.type == TokenType.floating) {
            isFloat = true;
        } else if (current.type != TokenType.floating && current.type != TokenType.integer) {
            throw new Exception(current.toString() ~ " is not a number");
        }

        if (isFloat) {
            floatTotal += (current.type == TokenType.floating) ? (cast(FloatToken)current).floatValue : (cast(IntegerToken)current).intValue;
        } else {
            intTotal += (cast(IntegerToken)current).intValue;
        }

        args = (cast(ReferenceToken)args).reference.cdr;
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);
}

void addBuiltins (out BuiltinFunction[string] builtinTable) {
    builtinTable["+"] = &builtinPlus;
}