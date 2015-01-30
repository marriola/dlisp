import cstdio = core.stdc.stdio;
import std.ascii;
import std.conv;
import std.file;
import std.stdio;

char getc () {
    return cast(char)cstdio.fgetc(cstdio.stdin);
}

enum TokenType { leftParen, rightParen, integer, identifier, string }

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

///////////////////////////////////////////////////////////////////////////////
// Node types
///////////////////////////////////////////////////////////////////////////////

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


///////////////////////////////////////////////////////////////////////////////
// Parser
///////////////////////////////////////////////////////////////////////////////

class LispParser {
    Node root;
    Token nextToken;
    private File stream;

    this () {
        stream = stdin;
        getToken();
    }

    this (File stream) {
        this.stream = stream;
        getToken();
    }

    void getToken () {
        char c = getc();

        if (c == '(') {
            nextToken = Token(TokenType.leftParen);

        } else if (c == ')') {
            nextToken = Token(TokenType.rightParen);

        } else if (isDigit(c)) {
            cstdio.ungetc(cast(int)c, cstdio.stdin);

            int intValue;
            stdin.readf("%d", &intValue);
            nextToken = Token(TokenType.integer, intValue);

        } else if (c == '\"') {
            string stringValue;
            c = getc();

            do {
                stringValue ~= c;
                c = getc();
            } while (c != '\"');

            nextToken = Token(TokenType.string, stringValue);

       } else if (!isWhite(c)) {
            string stringValue;

            do {
                stringValue ~= c;
                c = getc();
            } while (!isWhite(c) && c != '(' && c != ')');

            nextToken = Token(TokenType.identifier, stringValue);
        }
    }

    void parse () {
        getToken();
    }
}

///////////////////////////////////////////////////////////////////////////////

void main () {
    LispParser parser = new LispParser();
    parser.parse();
    writef("You said: %s", parser.nextToken.toString());
}