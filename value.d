module value;

import node;
import token;

import std.conv;

enum ValueType { boolean, reference, integer, identifier, string };

abstract class Value {
    ValueType type;

    override string toString();

    static ReferenceValue makeReference (Value value) {
        return new ReferenceValue(new Node(value));
    }

    static Value fromToken (Token token) {
        switch (token.type) {
            case TokenType.boolean:
                return new BooleanValue(token.boolValue);

            case TokenType.string:
                return new StringValue(token.stringValue);

            case TokenType.identifier:
                return new IdentifierValue(token.stringValue);

            case TokenType.integer:
                return new IntegerValue(token.intValue);

            default:
                return null;
        }
    }
}

class BooleanValue : Value {
    bool boolValue;

    this (bool boolValue) {
        type = ValueType.boolean;
        this.boolValue = boolValue;
    }

    override string toString () {
        return boolValue ? "T" : "NIL";
    }
}

class StringValue : Value {
    string stringValue;

    this (string stringValue) {
        type = ValueType.string;
        this.stringValue = stringValue;
    }

    override string toString () {
        return "\"" ~ stringValue ~ "\"";
    }
}

class IdentifierValue : Value {
    string stringValue;

    this (string stringValue) {
        type = ValueType.identifier;
        this.stringValue = stringValue;
    }

    override string toString () {
        return stringValue;
    }
}

class IntegerValue : Value {
    int intValue;

    this (int intValue) {
        type = ValueType.integer;
        this.intValue = intValue;
    }

    override string toString () {
        return to!string(intValue);
    }
}

class ReferenceValue : Value {
    Node reference;

    this (Node reference) {
        type = ValueType.reference;
        this.reference = reference;
    }

    override string toString () {
        return reference.toString();
    }
}