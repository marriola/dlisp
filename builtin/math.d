module builtin.math;

import std.math;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////
// TODO: factor out repeated code in these builtin functions
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////

Value builtinGreaterOrEqual (string name, Value[] args, Value[string] kwargs) {
    bool result = true;
    float lastValue = float.min_normal;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluateOnce(args[0]);
    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluateOnce(args[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        result = currentValue >= lastValue;
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinGreater (string name, Value[] args, Value[string] kwargs) {
    bool result = true;
    float lastValue = float.min_normal;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluateOnce(args[0]);
    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluateOnce(args[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        result = currentValue > lastValue;
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEqual (string name, Value[] args, Value[string] kwargs) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluateOnce(args[0]);
    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluateOnce(args[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        result = currentValue == lastValue;
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLesser (string name, Value[] args, Value[string] kwargs) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluateOnce(args[0]);
    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluateOnce(args[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        result = currentValue < lastValue;
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLesserOrEqual (string name, Value[] args, Value[string] kwargs) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value current = evaluateOnce(args[0]);
    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluateOnce(args[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        result = currentValue <= lastValue;
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinPlus (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value result = evaluateOnce(args[0]);
    foreach (Value addend; args[1 .. args.length]) {
        result.add(evaluateOnce(addend));
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMinus (string name, Value[] args, Value[string] kwargs) {
    Value result;

    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    } else if (args.length == 1) {
        result = new Value(new IntegerToken(0));
    } else {
        result = evaluateOnce(args[0]);
        args = args[1 .. args.length];
    }

    foreach (Value subtrahend; args) {
        result.subtract(evaluateOnce(subtrahend));
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinTimes (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value result = evaluateOnce(args[0]);
    foreach (Value multiplicand; args[1 .. args.length]) {
        result.multiply(evaluateOnce(multiplicand));
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDivide (string name, Value[] args, Value[string] kwargs) {
    Value result;

    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    } else if (args.length == 1) {
        result = new Value(new FloatToken(1));
    } else {
        result = evaluateOnce(args[0]);
        args = args[1 .. args.length];
    }

    foreach (Value divisor; args) {
        result.divide(evaluateOnce(divisor));
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSqrt (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    } else {
        Value operand = evaluateOnce(args[0]);
        float value = (operand.token.type == TokenType.floating) ? (cast(FloatToken)operand.token).floatValue : (cast(IntegerToken)operand.token).intValue;
        return new Value(new FloatToken(sqrt(value)));
    }
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["<="] = &builtinGreaterOrEqual;
    builtinTable["<"] = &builtinGreater;
    builtinTable["="] = &builtinEqual;
    builtinTable[">"] = &builtinLesser;
    builtinTable[">="] = &builtinLesserOrEqual;
    builtinTable["+"] = &builtinPlus;
    builtinTable["-"] = &builtinMinus;
    builtinTable["*"] = &builtinTimes;
    builtinTable["/"] = &builtinDivide;
    builtinTable["SQRT"] = &builtinSqrt;
    return builtinTable;
}