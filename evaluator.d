module evaluator;

import exceptions;
import functions;
import lispObject;
import token;
import variables;

Value evaluateOnce (Value value) {
    switch (value.token.type) {
        case TokenType.identifier:
            return getVariable((cast(IdentifierToken)value.token).stringValue);

        case TokenType.boolean:
        case TokenType.integer:
        case TokenType.floating:
        case TokenType.character:
        case TokenType.string:
        case TokenType.constant:
        case TokenType.fileStream:
        case TokenType.builtinFunction:
        case TokenType.definedFunction:
            return value;

        case TokenType.reference:
            ReferenceToken refToken = cast(ReferenceToken)value.token;
            Value refValue = new Value(refToken);

            if (refToken.reference.car.token.type != TokenType.identifier) {
                throw new EvaluationException(refToken.reference.car.toString() ~ " is not a function name");
            }

            return evaluateFunction((cast(IdentifierToken)getFirst(refValue).token).stringValue, toArray(getRest(refValue))); //(cast(ReferenceToken)getRest(refToken)));
                //(cast(IdentifierToken)(refToken.reference.car)).stringValue, (cast(ReferenceToken)refToken).reference.cdr);

        default:
            return new Value(new BooleanToken(false));
    }
}

Value evaluate (Value token) {
    Value lastToken;

    do {
        lastToken = token;
        token = evaluateOnce(token);
    } while (lastToken.token != token.token);

    return token;
}