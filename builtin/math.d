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

Token builtinGreaterOrEqual (string name, Token[] args) {
    bool result = true;
    float lastValue = float.min_normal;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluate(args[i]);
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
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinGreater (string name, Token[] args) {
    bool result = true;
    float lastValue = float.min_normal;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluate(args[i]);
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
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinEqual (string name, Token[] args) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluate(args[i]);
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
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinLesser (string name, Token[] args) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluate(args[i]);
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
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinLesserOrEqual (string name, Token[] args) {
    bool result = true;
    float lastValue = float.max;

    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Token current = evaluate(args[0]);
    if (current.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current).floatValue;
    } else if (current.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current).intValue;
    } else {
        throw new TypeMismatchException(name, current, "integer or floating point");
    }

    for (int i = 1; i < args.length; i++) {
        current = evaluate(args[i]);
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
    }

    return new BooleanToken(result);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinPlus (string name, Token[] args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    for (int i = 0; i < args.length; i++) {
        Token current = evaluate(args[i]);

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
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinMinus (string name, Token[] args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    if (args.length > 0) {
        Token current = evaluate(args[0]);

        if (current.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
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
                current = evaluate(args[i]);
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
            }
        }
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinTimes (string name, Token[] args) {
    bool isFloat = false;
    int intTotal = 1;
    double floatTotal = 0;

    if (args.length > 0) {
        Token current = evaluate(args[0]);
        if (current.type == TokenType.integer) {
            intTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
            isFloat = true;
        }

        for (int i = 1; i < args.length; i++) {
            current = evaluate(args[i]);

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
        }        
    }

    return isFloat ? new FloatToken(floatTotal + intTotal) : new IntegerToken(intTotal);    
}


///////////////////////////////////////////////////////////////////////////////

Token builtinDivide (string name, Token[] args) {
    bool isFloat = false;
    int intTotal = 0;
    double floatTotal = 0;

    if (args.length > 0) {
        Token current = evaluate(args[0]);

        if (current.type == TokenType.integer) {
            floatTotal = (cast(IntegerToken)current).intValue;
        } else if (current.type == TokenType.floating) {
            floatTotal = (cast(FloatToken)current).floatValue;
        }

        if (args.length < 2) {
            floatTotal = 1 / floatTotal;
        } else {
            for (int i = 1; i < args.length; i++) {
                current = evaluate(args[i]);
                if (current.type != TokenType.floating && current.type != TokenType.integer) {
                    throw new Exception(current.toString() ~ " is not a number");
                }

                floatTotal /= (current.type == TokenType.floating) ? (cast(FloatToken)current).floatValue : (cast(IntegerToken)current).intValue;
            }
        }
    }

    return new FloatToken(floatTotal);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinSqrt (string name, Token[] args) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    } else {
        Token operand = evaluate(args[0]);
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