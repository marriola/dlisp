module builtin.logic;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinNull (string name) {
    return new Value(new BooleanToken(evaluateOnce(getVariable("OBJECT")).isNil()));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinIf (string name) {
    bool condition;
    Value current = evaluate(getVariable("TEST"));

    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    } else {
        condition = (cast(BooleanToken)current.token).boolValue;
    }

    Value thenClause = getVariable("THEN");
    Value elseClause = getVariable("ELSE");
    return condition ? evaluateOnce(thenClause) : evaluateOnce(elseClause);
}


///////////////////////////////////////////////////////////////////////////////

Value builtinCond (string name) {
    Value[] variants = toArray(getVariable("VARIANTS"));
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
    Value[] forms = toArray(getVariable("FORMS"));
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
    Value[] forms = toArray(getVariable("FORMS"));
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
    Value current = evaluate(getVariable("FORM"));
    if (current.token.type != TokenType.boolean) {
        throw new TypeMismatchException(name, current.token, "boolean");
    }

    return new Value(new BooleanToken(!(cast(BooleanToken)current.token).boolValue));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinEq (string name) {
    Value obj1 = evaluate(getVariable("OBJ1"));
    Value obj2 = evaluate(getVariable("OBJ2"));

    return new Value(new BooleanToken(objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinNeq (string name) {
    Value obj1 = evaluate(getVariable("OBJ1"));
    Value obj2 = evaluate(getVariable("OBJ2"));

    return new Value(new BooleanToken(!objectsEqual(obj1, obj2)));
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("NULL", &builtinNull, Parameters(["OBJECT"]));
    addFunction("IF", &builtinIf, Parameters(["TEST", "THEN", "ELSE"]));
    addFunction("COND", &builtinCond, Parameters(null, null, null, null, "VARIANTS"));
    addFunction("AND", &builtinAnd, Parameters(null, null, null, null, "FORMS"));
    addFunction("OR", &builtinOr, Parameters(null, null, null, null, "FORMS"));
    addFunction("NOT", &builtinNot, Parameters(["FORM"]));
    addFunction("EQ", &builtinEq, Parameters(["OBJ1", "OBJ2"]));
    addFunction("NEQ", &builtinNeq, Parameters(["OBJ1", "OBJ2"]));
}