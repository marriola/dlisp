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

    Value count = loopSpec[1];
    if (count.token.type != TokenType.integer) {
        throw new TypeMismatchException(name, count.token, "integer");
    }

    Value loopVariable = loopSpec[0];
    if (loopVariable.token.type != TokenType.identifier) {
	throw new TypeMismatchException(name, loopVariable.token, "identifier");
    }
    string loopIdentifier = (cast(IdentifierToken)loopVariable.token).stringValue;

    Value result = loopSpec[2];
    Value[] loopBody = toArray(getParameter("FORMS"));

    long n = (cast(IntegerToken)count.token).intValue;
    for (long i = 0; i < n; i++) {
	addVariable(loopIdentifier, new Value(new IntegerToken(i)));
        foreach (Value form; loopBody) {
            evaluate(form);
        }
    }

    return result;
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("DOTIMES", &builtinDotimes, [Parameter("LOOPSPEC", false)], null, null, null, Parameter("FORMS", false));
}
