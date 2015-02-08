module token;

import node;
import token;

import std.conv;

enum TokenType { leftParen, rightParen, dot, boolean, reference, integer, floating, identifier, string };

abstract class Token {
    TokenType type;

    override string toString();

    static ReferenceToken makeReference (Token car, Token cdr = null) {
        return new ReferenceToken(new Node(car, cdr));
    }
}

class LexicalToken : Token {
    this (TokenType type) {
        this.type = type;
    }

    override string toString () {
        switch (type) {
            case TokenType.leftParen:
                return "(";

            case TokenType.rightParen:
                return ")";

            case TokenType.dot:
                return ".";

            default:
                return "???";
        }
    }
}

class BooleanToken : Token {
    bool boolValue;

    this (bool boolValue) {
        type = TokenType.boolean;
        this.boolValue = boolValue;
    }

    override string toString () {
        return boolValue ? "T" : "NIL";
    }
}

class StringToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.string;
        this.stringValue = stringValue;
    }

    override string toString () {
        return "\"" ~ stringValue ~ "\"";
    }
}

class IdentifierToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.identifier;
        this.stringValue = stringValue;
    }

    override string toString () {
        return stringValue;
    }
}

class IntegerToken : Token {
    int intValue;

    this (int intValue) {
        type = TokenType.integer;
        this.intValue = intValue;
    }

    override string toString () {
        return to!string(intValue);
    }
}

class FloatToken : Token {
    double floatValue;

    this (double floatValue) {
        type = TokenType.floating;
        this.floatValue = floatValue;
    }

    override string toString () {
        return to!string(floatValue);
    }
}

class ReferenceToken : Token {
    Node reference;

    this (Node reference) {
        type = TokenType.reference;
        this.reference = reference;
    }

    override string toString () {
        return reference.toString();
    }
}