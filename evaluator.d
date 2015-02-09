module evaluator;

import token;
import variables;

Token evaluate (Token token) {
    switch (token.type) {
        case TokenType.identifier:
            return getVariable((cast(IdentifierToken)token).stringValue);

        case TokenType.boolean:
        case TokenType.integer:
        case TokenType.floating:
        case TokenType.string:
            return token;

        default:
            return new BooleanToken(false);
    }
}