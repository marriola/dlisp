module evaluator;

import exceptions;
import functions;
import lispObject;
import token;
import variables;
import vm.machine;

Value evaluateOnce (Value value) {
    return vm.machine.evaluate(value);
}

Value evaluate (Value token) {
    Value lastToken;

    do {
        lastToken = token;
        token = evaluateOnce(token);
    } while (lastToken.token != token.token);

    return token;
}