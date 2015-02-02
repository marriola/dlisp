module node;

import std.conv;

enum NodeType { none, boolean, reference, identifier, integer, string }

class Node {
    Node car;
    Node cdr;

    this () {
        car = cdr = null;
    }

    this (Node car, Node cdr = null) {
        this.car = car;

        if (cdr is null) {
            this.cdr = new BooleanNode(false);
        }
    }

    NodeType type () { return NodeType.none; }

    override string toString () {
        string builder;

        if (car !is null && cdr !is null) {
            builder ~= "(" ~ car.toString() ~ " ";

            if (cdr.cdr !is null) {
                builder ~= ". " ~ cdr.toString();
            } else {
                builder ~= cdr.toString();
            }

            builder ~= ")";

        } else {
            builder ~= car.toString() ~ " . " ~ cdr.toString();
        }

        return builder;
    }
}

class BooleanNode : Node {
    bool value;

    this (bool value) {
        this.value = value;
    }

    override NodeType type () { return NodeType.boolean; }

    override string toString () {
        return value ? "T" : "NIL";
    }
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