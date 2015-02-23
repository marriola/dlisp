module token;

import node;

import std.stdio;
import std.conv;
import std.string;

enum TokenType { leftParen, rightParen, leftBrack, rightBrack, dot, boolean, reference, integer, floating, identifier, string, constant, fileStream };

string tokenTypeName (TokenType type) {
    static string typeNames[] = [ "left paren", "right paren", "dot", "boolean", "reference", "integer", "floating point", "identifier", "string", "constant", "file stream" ];
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

    /**
     * @param value a Token object to test.
     * @return true if the Token object is a BooleanToken representing the value NIL.
     */
    static bool isNil (Token value) {
        return value.type == TokenType.boolean && (cast(BooleanToken)value).boolValue == false;
    }
}

class LexicalToken : Token {
    this (TokenType type) {
        this.type = type;
    }

    override bool isLexicalToken () { return true; }

    override string toString () {
        static enum string[TokenType] lexicalTokens =
            [ TokenType.leftParen : "(",
              TokenType.rightParen : ")",
              TokenType.leftBrack : "[",
              TokenType.rightParen : "]",
              TokenType.dot : "." ];

        return lexicalTokens[type];
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

class ConstantToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.constant;
        this.stringValue = toUpper(stringValue);
    }

    override string toString () {
        return ":" ~ stringValue;
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

class FileStreamToken : Token {
    string direction;
    string fileSpec;
    File stream;
    bool isOpen;

    this (string fileSpec, ConstantToken direction) {
        static enum char[][string] openModes = [ "input" : cast(char[])"r", "output" : cast(char[])"w", "io" : cast(char[])"rw" ];

        type = TokenType.fileStream;
        this.direction = direction is null ? "input" : direction.stringValue;
        stream = File(fileSpec, openModes[this.direction]);
        this.fileSpec = fileSpec;
        isOpen = true;
    }

    bool close () {
        bool wasOpen = isOpen;
        stream.close();
        return wasOpen;
    }

    override string toString () {
        return "#<" ~ direction ~ " file stream \"" ~ fileSpec ~ (isOpen ? "" : " (closed)") ~ "\">";
    }
}

ReferenceToken toReference (Token token) {
    return (cast(ReferenceToken)token);
}

IntegerToken toInteger (Token token) {
    return (cast(IntegerToken)token);   
}

FloatToken toFloat (Token token) {
    return (cast(FloatToken)token);   
}

IdentifierToken toIdentifier (Token token) {
    return (cast(IdentifierToken)token);
}