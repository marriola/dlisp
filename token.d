module token;

import std.conv;

enum TokenType { leftParen, rightParen, dot, integer, identifier, string }

struct Token {
    TokenType type;

    union {
        int intValue;
        string stringValue;
    }

    this (TokenType type) {
        this.type = type;
    }

    this (TokenType type, int value) {
        this.type = type;
        this.intValue = value;
    }

    this (TokenType type, string value) {
        this.type = type;
        this.stringValue = value;
    }

    string toString () {
        switch (type) {
            case TokenType.leftParen:
                return "(";

            case TokenType.rightParen:
                return ")";

            case TokenType.dot:
                return ".";

            case TokenType.integer:
                return to!string(intValue);

            case TokenType.string:
                return "\"" ~ stringValue ~ "\"";

            case TokenType.identifier:
                return stringValue;

            default:
                return "???";
        }
    }
}

