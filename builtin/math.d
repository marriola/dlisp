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

Value builtinGreaterOrEqual (string name, Value[] args, string[Value] kwargs) {
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

Value builtinGreater (string name, Value[] args, string[Value] kwargs) {
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

Value builtinEqual (string name, Value[] args, string[Value] kwargs) {
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

Value builtinLesser (string name, Value[] args, string[Value] kwargs) {
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

Value builtinLesserOrEqual (string name, Value[] args, string[Value] kwargs) {
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

Value builtinPlus (string name, Value[] args, string[Value] kwargs) {
    bool isFloat = false;
    long intTotal = 0;
    double floatTotal = 0;

    for (int i = 0; i < args.length; i++) {
        Value current = evaluateOnce(args[i]);

        if (!isFloat && current.token.type == TokenType.floating) {
            isFloat = true;
        } else if (current.token.type != TokenType.floating && current.token.type != TokenType.integer) {
            throw new Exception(current.toString() ~ " is not a number");
        }

        if (isFloat) {
            floatTotal += (current.token.type == TokenType.floating) ? (cast(FloatToken)current.token).floatValue : (cast(IntegerToken)current.token).intValue;
        } else {
            intTotal += (cast(IntegerToken)current.token).intValue;
        }
    }

    return new Value(isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMinus (string name, Value[] args, string[Value] kwargs) {
    bool isFloat = false;
    long intTotal = 0;
    double floatTotal = 0;

    if (args.length > 0) {
        Value current = evaluateOnce(args[0]);

        if (current.token.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current.token).intValue;
        } else if (current.token.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current.token).floatValue;
            isFloat = true;
        }

        if (args.length < 2) {
            if (isFloat) {
                floatTotal *= -1;
            } else {
                intTotal *= -1;
            }
        } else {
            for (int i = 1; i < args.length; i++) {
                current = evaluateOnce(args[i]);
                if (!isFloat && current.token.type == TokenType.floating) {
                    isFloat = true;
                } else if (current.token.type != TokenType.floating && current.token.type != TokenType.integer) {
                    throw new Exception(current.toString() ~ " is not a number");
                }

                if (isFloat) {
                    floatTotal -= (current.token.type == TokenType.floating) ? (cast(FloatToken)current.token).floatValue : (cast(IntegerToken)current.token).intValue;
                } else {
                    intTotal -= (cast(IntegerToken)current.token).intValue;
                }
            }
        }
    }

    return new Value(isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinTimes (string name, Value[] args, string[Value] kwargs) {
    bool isFloat = false;
    long intTotal = 1;
    double floatTotal = 0;

    if (args.length > 0) {
        Value current = evaluateOnce(args[0]);
        if (current.token.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current.token).intValue;
        } else if (current.token.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current.token).floatValue;
            isFloat = true;
        } else {
            throw new TypeMismatchException(name, args[0].token, "integer or floating point");
        }

        for (int i = 1; i < args.length; i++) {
            current = evaluateOnce(args[i]);

            if (!isFloat && current.token.type == TokenType.floating) {
                isFloat = true;
            } else if (current.token.type != TokenType.floating && current.token.type != TokenType.integer) {
                throw new Exception(current.toString() ~ " is not a number");
            }

            if (isFloat) {
                floatTotal *= (current.token.type == TokenType.floating) ? (cast(FloatToken)current.token).floatValue : (cast(IntegerToken)current.token).intValue;
            } else {
                intTotal *= (cast(IntegerToken)current.token).intValue;
            }
        }        
    }

    return new Value(isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal)); 
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDivide (string name, Value[] args, string[Value] kwargs) {
    bool isFloat = false;
    long intTotal = 0;
    double floatTotal = 0;

    if (args.length > 0) {
        Value current = evaluateOnce(args[0]);

        if (current.token.type == TokenType.integer) {
            floatTotal = (cast(IntegerToken)current.token).intValue;
        } else if (current.token.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current.token).floatValue;
        }

        if (args.length < 2) {
            floatTotal = 1 / floatTotal;
        } else {
            for (int i = 1; i < args.length; i++) {
                current = evaluateOnce(args[i]);
                if (current.token.type != TokenType.floating && current.token.type != TokenType.integer) {
                    throw new Exception(current.toString() ~ " is not a number");
                }

                floatTotal /= (current.token.type == TokenType.floating) ? (cast(FloatToken)current.token).floatValue : (cast(IntegerToken)current.token).intValue;
            }
        }
    }

    return new Value(new FloatToken(floatTotal));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSqrt (string name, Value[] args, string[Value] kwargs) {
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