module node;

import std.conv;

enum NodeType { reference, identifier, integer, string }

abstract class Node {
    Node car;
    Node cdr;

    this () {
        car = cdr = null;
    }

    NodeType type ();
}

class ReferenceNode : Node {
    Node value;

    override NodeType type () { return NodeType.reference; }

    override string toString () {
        return value.toString();
    }
}

class IdentifierNode : Node {
    string value;

    this (string value) {
        super();
        this.value = value;
    }

    override NodeType type () { return NodeType.string; }

    override string toString () {
        return value;
    }
}

class IntegerNode : Node {
    int value;

    this (int value) {
        super();
        this.value = value;
    }

    override NodeType type () { return NodeType.integer; }

    override string toString () {
        return to!string(value);
    }
}

class StringNode : Node {
    string value;

    this (string value) {
        super();
        this.value = value;
    }

    override NodeType type () { return NodeType.string; }

    override string toString () {
        return "\"" ~ value ~ "\"";
    }
}