module builtin.loop;

import evaluator;
import exceptions;
import functions;
import lispObject;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinDotimes (string name) {
    Value[] loopSpec = toArray(getParameter("LOOPSPEC"));
    if (loopSpec.length < 3) {
        throw new NotEnoughArgumentsException(name);
    }

    Value loopVariable = loopSpec[0];
    Value count = loopSpec[1];
    Value result = loopSpec[2];
    Value[] loopBody = toArray(getParameter("FORMS"));

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

void addBuiltins () {
    addFunction("DOTIMES", &builtinDotimes, Parameters(["LOOPSPEC"], null, null, null, "FORMS"));
}