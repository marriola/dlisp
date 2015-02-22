module evaluator;

import functions;
import lispObject;
import token;
import variables;

class EvaluationException : Exception {
    this (string msg) {
        super(msg);
    }
}

Token evaluate (Token token) {
    switch (token.type) {
        case TokenType.identifier:
            return getVariable((cast(IdentifierToken)token).stringValue);

        case TokenType.boolean:
        case TokenType.integer:
        case TokenType.floating:
        case TokenType.string:
        case TokenType.constant:
            return token;

        case TokenType.reference:
            ReferenceToken refToken = cast(ReferenceToken)token;

            if (refToken.reference.car.type != TokenType.identifier) {
                throw new EvaluationException(refToken.reference.car.toString() ~ " is not a function name");
            }

            return evaluateFunction((cast(IdentifierToken)getFirst(refToken)).stringValue, (cast(ReferenceToken)getRest(refToken)));
                //(cast(IdentifierToken)(refToken.reference.car)).stringValue, (cast(ReferenceToken)refToken).reference.cdr);

        default:
            return new BooleanToken(false);
    }
}