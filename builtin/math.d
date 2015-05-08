module builtin.math;

import std.math;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;

import std.random : uniform;

///////////////////////////////////////////////////////////////////////////////

Value builtinComparator (string name) {
    Value[] numbers = toArray(getParameter("NUMBERS"));
    if (numbers.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    bool result = true;
    float lastValue = float.min_normal;
    Value current = evaluateOnce(numbers[0]);

    if (current.token.type == TokenType.floating) {
        lastValue = (cast(FloatToken)current.token).floatValue;
    } else if (current.token.type == TokenType.integer) {
        lastValue = (cast(IntegerToken)current.token).intValue;
    } else {
        throw new TypeMismatchException(name, current.token, "integer or floating point");
    }

    for (int i = 1; i < numbers.length; i++) {
        current = evaluateOnce(numbers[i]);
        float currentValue;
        if (current.token.type == TokenType.floating) {
            currentValue = (cast(FloatToken)current.token).floatValue;
        } else if (current.token.type == TokenType.integer) {
            currentValue = (cast(IntegerToken)current.token).intValue;
        } else {
            throw new TypeMismatchException(name, current.token, "integer or floating point");
        }

        switch (name) {
            case "<":
                result = lastValue < currentValue;
                break;

            case "<=":
                result = lastValue <= currentValue;
                break;

            case "=":
                result = lastValue == currentValue;
                break;

            case "/=":
                result = lastValue != currentValue;
                break;

            case ">=":
                result = lastValue >= currentValue;;
                break;

            case ">":
                result = lastValue > currentValue;;
                break;

            default:
                throw new Exception("Invalid comparator function " ~ name);
        }
        
        lastValue = currentValue;
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinArithmeticOperation (string name) {
    Value[] numbers = toArray(getParameter("NUMBERS"));
    Value result;

    if (numbers.length == 1) {
        int initialValue = (name == "*" || name == "/") ? 1 : 0;
        result = new Value(new IntegerToken(initialValue));
    } else {
        result = evaluateOnce(numbers[0]);
        numbers = numbers[1 .. numbers.length];
    }

    foreach (Value number; numbers) {
        switch (name) {
            case "+":
                result.add(evaluateOnce(number));
                break;

            case "-":
                result.subtract(evaluateOnce(number));
                break;

            case "*":
                result.multiply(evaluateOnce(number));
                break;

            case "/":
                result.divide(evaluateOnce(number));
                break;

            default:
                throw new Exception("Invalid arithmetic operation " ~ name);
        }
        
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOnePlus (string name) {
    Value result = evaluateOnce(getParameter("NUMBER")).copy();
    result.add(new Value(new IntegerToken(1)));
    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOneMinus (string name) {
    Value result = evaluateOnce(getParameter("NUMBER")).copy();
    result.subtract(new Value(new IntegerToken(1)));
    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinIncf (string name) {
    Value place = evaluateOnce(getParameter("PLACE"));
    Value delta = evaluateOnce(getParameter("DELTA"));
    place.add(delta);
    return place;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinDecf (string name) {
    Value place = evaluateOnce(getParameter("PLACE"));
    Value delta = evaluateOnce(getParameter("DELTA"));
    place.subtract(delta);
    return place;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinSqrt (string name) {
    Value operand = evaluateOnce(getParameter("NUMBER"));
    float value = (operand.token.type == TokenType.floating) ? (cast(FloatToken)operand.token).floatValue : (cast(IntegerToken)operand.token).intValue;
    return new Value(new FloatToken(sqrt(value)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinMod (string name) {
    Value numberToken = evaluateOnce(getParameter("DIVIDEND"));
    Value divisorToken = evaluateOnce(getParameter("DIVISOR"));
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

Value builtinEven (string name) {
    Value numberToken = evaluateOnce(getParameter("NUMBER"));
    if (numberToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, numberToken.token, "integer");
    }

    long number = (cast(IntegerToken)numberToken.token).intValue;
    return new Value(new BooleanToken(number % 2 == 0));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOdd (string name) {
    Value numberToken = evaluateOnce(getParameter("NUMBER"));
    if (numberToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, numberToken.token, "integer");
    }

    long number = (cast(IntegerToken)numberToken.token).intValue;
    return new Value(new BooleanToken(number % 2 != 0));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRandom (string name) {
    Value limitToken = evaluateOnce(getParameter("LIMIT"));
    long limit;

    if (limitToken.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, limitToken.token, "integer");
    } else {
        limit = (cast(IntegerToken)limitToken.token).intValue;
    }

    return new Value(new IntegerToken(uniform(0, limit)));
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    foreach (string fun; ["<=", "<", "=", "/=", ">", ">="]) {
        addFunction(fun, &builtinComparator, null, null, null, null, Parameter("NUMBERS"));
    }

    foreach (string fun; ["+", "-", "*", "/"]) {
        addFunction(fun, &builtinArithmeticOperation, null, null, null, null, Parameter("NUMBERS"));
    }

    addFunction("1+", &builtinOnePlus, [Parameter("NUMBER")]);
    addFunction("1-", &builtinOneMinus, [Parameter("NUMBER")]);
    addFunction("INCF", &builtinIncf, [Parameter("PLACE")]);
    addFunction("DECF", &builtinDecf, [Parameter("PLACE")]);
    addFunction("SQRT", &builtinSqrt, [Parameter("NUMBER")]);
    addFunction("MOD", &builtinMod, [Parameter("DIVIDEND"), Parameter("DIVISOR")]);
    addFunction("EVEN", &builtinEven, [Parameter("NUMBER")]);
    addFunction("ODD", &builtinOdd, [Parameter("NUMBER")]);
    addFunction("RANDOM", &builtinRandom, [Parameter("LIMIT")]);
}