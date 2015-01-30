module node;

enum NodeType { reference, identifier, integer, string }

abstract class Node {
    Node car;
    Node cdr;

    NodeType type ();
}

class ReferenceNode : Node {
    Node value;

    override NodeType type () { return NodeType.reference; }
}

class IdentifierNode : Node {
    string value;

    override NodeType type () { return NodeType.string; }
}

class IntegerNode : Node {
    int value;

    override NodeType type () { return NodeType.integer; }
}

class StringNode : Node {
    string value;

    override NodeType type () { return NodeType.string; }
}