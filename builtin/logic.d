module builtin.logic;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinNull (string name) {
    return new Value(new BooleanToken(evaluateOnce(getParameter("OBJECT")).isNil()));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinZerop (string name) {
    bool result;
    Value obj = evaluateOnce(getParameter("OBJECT"));
    if (obj.token.type == TokenType.integer) {
        result = (cast(IntegerToken)obj.token).intValue == 0;
    } else if (obj.token.type == TokenType.floating) {
        result = (cast(FloatToken)obj.token).floatValue == 0;
    } else {
        result = false;
    }

    return new Value(new BooleanToken(result));
}



///////////////////////////////////////////////////////////////////////////////

Value builtinIf (string name) {
    bool condition;
    Value current = evaluate(getParameter("TEST"));

    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    } else {
        condition = (cast(BooleanToken)current.token).boolValue;
    }

    Value thenClause = getParameter("THEN");
    Value elseClause = getParameter("ELSE");
    return condition ? evaluateOnce(thenClause) : evaluateOnce(elseClause);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCond (string name) {
    Value[] variants = toArray(getParameter("VARIANTS"));
    Value result = Value.nil();

    foreach (Value variant; variants) {
        Value condition = getFirst(variant);
        Value[] forms = toArray(getRest(variant));

        if (!evaluateOnce(condition).isNil()) {
            foreach (Value form; forms) {
                result = evaluateOnce(form);
            }
            break;
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinAnd (string name) {
    Value[] forms = toArray(getParameter("FORMS"));
    bool result = true;

    foreach (Value form; forms) {
        if (!result) {
            break;
        }

        Value current = evaluate(form);
        if (current.token.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current.token, "boolean");
        } else {
            result &= (cast(BooleanToken)current.token).boolValue;
        }
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOr (string name) {
    Value[] forms = toArray(getParameter("FORMS"));
    bool result = false;

    foreach (Value form; forms) {
        Value current = evaluate(form);
        if (current.token.type != TokenType.boolean) {
            throw new TypeMismatchException(name, current.token, "boolean");
        } else {
            result |= (cast(BooleanToken)current.token).boolValue;
        }
    }

    return new Value(new BooleanToken(result));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinNot (string name) {
    Value current = evaluate(getParameter("FORM"));
    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    }

    return new Value(new BooleanToken(!(cast(BooleanToken)current.token).boolValue));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEq (string name) {
    Value obj1 = evaluate(getParameter("OBJ1"));
    Value obj2 = evaluate(getParameter("OBJ2"));

    return new Value(new BooleanToken(objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinNeq (string name) {
    Value obj1 = evaluate(getParameter("OBJ1"));
    Value obj2 = evaluate(getParameter("OBJ2"));

    return new Value(new BooleanToken(!objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("NULL", &builtinNull, [Parameter("OBJECT")]);
    addFunction("ZEROP", &builtinZerop, [Parameter("OBJECT")]);
    addFunction("IF", &builtinIf, [Parameter("TEST"), Parameter("THEN"), Parameter("ELSE")]);
    addFunction("COND", &builtinCond, null, null, null, null, Parameter("VARIANTS"));
    addFunction("AND", &builtinAnd, null, null, null, null, Parameter("FORMS"));
    addFunction("OR", &builtinOr, null, null, null, null, Parameter("FORMS"));
    addFunction("NOT", &builtinNot, [Parameter("FORM")]);
    addFunction("EQ", &builtinEq, [Parameter("OBJ1"), Parameter("OBJ2")]);
    addFunction("NEQ", &builtinNeq, [Parameter("OBJ1"), Parameter("OBJ2")]);
}