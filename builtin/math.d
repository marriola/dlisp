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

Value builtinNotEqual (string name, Value[] args, Value[string] kwargs) {
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

        result = currentValue != lastValue;
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

    Value result = evaluateOnce(args[0]).copy();
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
        result = evaluateOnce(args[0]).copy();
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

    Value result = evaluateOnce(args[0]).copy();
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
        result = evaluateOnce(args[0]).copy();
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

Value builtinMod (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 2) {
        throw new NotEnoughArgumentsException(name);
    }

    Value numberToken = evaluateOnce(args[0]);
    Value divisorToken = evaluateOnce(args[1]);
    long number, divisor;

    if (numberToken.token.type == TokenType.integer) {
        number = (cast(IntegerToken)numberToken.token).intValue;
    } else if (numberToken.token.type == TokenType.floating) {
        number = cast (int) (cast(FloatToken)numberToken.token).floatValue;
    } else {
        throw new TypeMismatchException(name, numberToken.token, "integer or floating point");
    }

    if (divisorToken.token.type == TokenType.integer) {
        divisor = (cast(IntegerToken)divisorToken.token).intValue;
    } else if (divisorToken.token.type == TokenType.floating) {
        divisor = cast (int) (cast(FloatToken)divisorToken.token).floatValue;
    } else {
        throw new TypeMismatchException(name, divisorToken.token, "integer or floating point");
    }

    return new Value(new IntegerToken(number % divisor));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEven (string name, Value[] args, Value[string] kwargs) {
    Value numberToken = evaluateOnce(args[0]);
    if (numberToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, numberToken.token, "integer");
    }

    long number = (cast(IntegerToken)numberToken.token).intValue;
    return new Value(new BooleanToken(number % 2 == 0));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOdd (string name, Value[] args, Value[string] kwargs) {
    Value numberToken = evaluateOnce(args[0]);
    if (numberToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, numberToken.token, "integer");
    }

    long number = (cast(IntegerToken)numberToken.token).intValue;
    return new Value(new BooleanToken(number % 2 != 0));
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["<="] = &builtinGreaterOrEqual;
    builtinTable["<"] = &builtinGreater;
    builtinTable["="] = &builtinEqual;
    builtinTable["/="] = &builtinNotEqual;
    builtinTable[">"] = &builtinLesser;
    builtinTable[">="] = &builtinLesserOrEqual;
    builtinTable["+"] = &builtinPlus;
    builtinTable["-"] = &builtinMinus;
    builtinTable["*"] = &builtinTimes;
    builtinTable["/"] = &builtinDivide;
    builtinTable["SQRT"] = &builtinSqrt;
    builtinTable["MOD"] = &builtinMod;
    builtinTable["EVEN"] = &builtinEven;
    builtinTable["ODD"] = &builtinOdd;
    return builtinTable;
}