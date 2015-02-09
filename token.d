module token;

import node;

import std.conv;
import std.string;

enum TokenType { leftParen, rightParen, dot, boolean, reference, integer, floating, identifier, string };

string tokenTypeName (TokenType type) {
    static string typeNames[] = [ "left paren", "right paren", "dot", "boolean", "reference", "integer", "floating point", "identifier", "string" ];
    return typeNames[cast(int)type];
}

abstract class Token {
    TokenType type;

    /**
     * @return a string representation of this token
     */
    override string toString();

    /**
     * @return true if this is a lexical token, false otherwise. 
     */
    bool isLexicalToken () { return false; }

    /**
     * Constructs a reference token encapsulating a new Node object.
     * @param car the CAR of the new node
     * @param cdr the CDR of the new node
     * @return a reference token
     */
    static ReferenceToken makeReference (Token car, Token cdr = null) {
        return new ReferenceToken(new Node(car, cdr));
    }
}

class LexicalToken : Token {
    this (TokenType type) {
        this.type = type;
    }

    override bool isLexicalToken () { return true; }

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
        this.stringValue = toUpper(stringValue);
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