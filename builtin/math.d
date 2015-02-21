module builtin.math;

import std.math;

import evaluator;
import functions;
import lispObject;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinGreaterOrEqual (string name, ReferenceToken args) {
    bool result = true;
    float lastValue = float.min_normal;

    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }
    args = getRest(args);

    while (hasMore(args)) {
        current = evaluate(getFirst(args));
        float currentValue;
        if (current.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current).floatValue;
        } else if (current.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current).intValue;
        } else {
            throw new TypeMismatchException(name, current, "integer or floating point");
        }

        result = currentValue >= lastValue;
        lastValue = currentValue;

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinGreater (string name, ReferenceToken args) {
    bool result = true;
    float lastValue = float.min_normal;

    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }
    args = getRest(args);

    while (hasMore(args)) {
        current = evaluate(getFirst(args));
        float currentValue;
        if (current.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current).floatValue;
        } else if (current.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current).intValue;
        } else {
            throw new TypeMismatchException(name, current, "integer or floating point");
        }

        result = currentValue > lastValue;
        lastValue = currentValue;

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinEqual (string name, ReferenceToken args) {
    bool result = true;
    float lastValue = float.max;

    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }
    args = getRest(args);

    while (hasMore(args)) {
        current = evaluate(getFirst(args));
        float currentValue;
        if (current.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current).floatValue;
        } else if (current.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current).intValue;
        } else {
            throw new TypeMismatchException(name, current, "integer or floating point");
        }

        result = currentValue == lastValue;
        lastValue = currentValue;

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinLesser (string name, ReferenceToken args) {
    bool result = true;
    float lastValue = float.max;

    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }
    args = getRest(args);

    while (hasMore(args)) {
        current = evaluate(getFirst(args));
        float currentValue;
        if (current.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current).floatValue;
        } else if (current.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current).intValue;
        } else {
            throw new TypeMismatchException(name, current, "integer or floating point");
        }

        result = currentValue < lastValue;
        lastValue = currentValue;

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinLesserOrEqual (string name, ReferenceToken args) {
    bool result = true;
    float lastValue = float.max;

    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(getFirst(args));
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }
    args = getRest(args);

    while (hasMore(args)) {
        current = evaluate(getFirst(args));
        float currentValue;
        if (current.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current).floatValue;
        } else if (current.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current).intValue;
        } else {
            throw new TypeMismatchException(name, current, "integer or floating point");
        }

        result = currentValue <= lastValue;
        lastValue = currentValue;

        args = getRest(args);
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinPlus (string name, ReferenceToken args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    while (hasMore(args)) {
        Token current = evaluate(getFirst(args));

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

        args = getRest(args);
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinMinus (string name, ReferenceToken args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    if (hasMore(args)) {
        Token current = evaluate(getFirst(args));

        if (current.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
            isFloat = true;
        }

        args = getRest(args);
        if (!hasMore(args)) {
            if (isFloat) {
                floatTotal *= -1;
            } else {
                intTotal *= -1;
            }
        } else {
            while (hasMore(args)) {
                current = evaluate(getFirst(args));
                if (!isFloat && current.type == TokenType.floating) {
                    isFloat = true;
                } else if (current.type != TokenType.floating && current.type != TokenType.integer) {
                    throw new Exception(current.toString() ~ " is not a number");
                }

                if (isFloat) {
                    floatTotal -= (current.type == TokenType.floating) ? (cast(FloatToken)current).floatValue : (cast(IntegerToken)current).intValue;
                } else {
                    intTotal -= (cast(IntegerToken)current).intValue;
                }

                args = getRest(args);
            }
        }
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinTimes (string name, ReferenceToken args) {
    bool isFloat = false;
    int intTotal = 1;
    double floatTotal = 0;

    if (hasMore(args)) {
        Token current = evaluate(getFirst(args));
        if (current.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
            isFloat = true;
        }

        args = getRest(args);
        while (hasMore(args)) {
            current = evaluate(getFirst(args));

            if (!isFloat && current.type == TokenType.floating) {
                isFloat = true;
            } else if (current.type != TokenType.floating && current.type != TokenType.integer) {
                throw new Exception(current.toString() ~ " is not a number");
            }

            if (isFloat) {
                floatTotal *= (current.type == TokenType.floating) ? (cast(FloatToken)current).floatValue : (cast(IntegerToken)current).intValue;
            } else {
                intTotal *= (cast(IntegerToken)current).intValue;
            }

            args = getRest(args);
        }        
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);    
}


///////////////////////////////////////////////////////////////////////////////

Token builtinDivide (string name, ReferenceToken args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    if (hasMore(args)) {
        Token current = evaluate(getFirst(args));

        if (current.type == TokenType.integer) {
            floatTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
        }

        args = getRest(args);
        if (!hasMore(args)) {
            floatTotal = 1 / floatTotal;
        } else {
            while (hasMore(args)) {
                current = evaluate(getFirst(args));
                if (current.type != TokenType.floating && current.type != TokenType.integer) {
                    throw new Exception(current.toString() ~ " is not a number");
                }

                floatTotal /= (current.type == TokenType.floating) ? (cast(FloatToken)current).floatValue : (cast(IntegerToken)current).intValue;
                args = getRest(args);
            }
        }
    }

    return new FloatToken(floatTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinSqrt (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    } else {
        Token operand = getFirst(args);
        float value = (operand.type == TokenType.floating) ? (cast(FloatToken)operand).floatValue : (cast(IntegerToken)operand).intValue;
        return new FloatToken(sqrt(value));
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