module parser;

import cstdio = core.stdc.stdio;
import std.ascii;
import std.file;
import std.stdio;

import token;
import node;

char getc () {
    return cast(char)cstdio.fgetc(cstdio.stdin);
}

class LispParser {
    private Token nextToken;
    private File stream;

    this () {
        stream = stdin;
    }

    this (File stream) {
        this.stream = stream;
    }

    private void getToken () {
        char c;

        do {
            c = getc();
        } while (isWhite(c));

        if (c == '(') {
            nextToken = Token(TokenType.leftParen);

        } else if (c == ')') {
            nextToken = Token(TokenType.rightParen);

        } else if (c == '.') {
            nextToken = Token(TokenType.dot);

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

       } else {
            string stringValue;

            do {
                stringValue ~= c;
                c = getc();
            } while (!isWhite(c) && c != '(' && c != ')');

            nextToken = Token(TokenType.identifier, stringValue);
        }
    }

    private Node makeNode (Token token) {
        writeln("new node from ", token);

        switch (token.type) {
            case TokenType.string:
                return new StringNode(token.stringValue);

            case TokenType.identifier:
                return new IdentifierNode(token.stringValue);

            case TokenType.integer:
                return new IntegerNode(token.intValue);

            default:
                return null;
        }
    }

    private bool matchToken (TokenType type) {
        if (nextToken.type != type) {
            writeln("mismatched token, expected ", Token(type), " got ", nextToken);
            return false;
        }

        writeln("matched ", nextToken);
        getToken();
        return true;
    }

    private Node parseList () {
        Node root, node;

        writeln("{ parseList");

        matchToken(TokenType.leftParen);
        root = node = new Node(makeNode(nextToken));
        getToken();

        if (nextToken.type == TokenType.dot) {
            matchToken(TokenType.dot);
            root.cdr = makeNode(nextToken);
            getToken();
            if (!matchToken(TokenType.rightParen)) {
                return null;
            }
            return root;

        } else {
            while (true) {
                switch (nextToken.type) {
                    case TokenType.leftParen:
                        node.cdr = parseList();
                        node = node.cdr;
                        break;

                    case TokenType.rightParen:
                        writeln("} parseList");
                        return root;

                    default:
                        writeln("got token ", nextToken);

                        node.cdr = new Node(makeNode(nextToken));
                        node = node.cdr;

                }

                getToken();
            }
        }
    }

    Node parse () {
        getToken();

        writeln("parse token ", nextToken.type);

        if (nextToken.type == TokenType.leftParen) {
            return parseList();

        } else if (nextToken.type == TokenType.rightParen) {
            // syntax error
            return null;

        } else {
            return makeNode(nextToken);
        }
    }
}
