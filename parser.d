module parser;

import cstdio = core.stdc.stdio;
import std.ascii;
import std.file;
import std.stdio;

import node;
import token;
import value;

/**
 * @param a file stream to read from.
 * @return a single character.
 */
char getc (File stream) {
    return cast(char)cstdio.fgetc(stream.getFP());
}

class LispParser {
    private Token nextToken;
    private File stream;

    /**
     * @return a LispParser object that reads from standard input.
     */
    this () {
        stream = stdin;
    }

    /**
     * @param an input stream to read Lisp code from.
     * @return a LispParser object that reads from the given stream.
     */
    this (File stream) {
        this.stream = stream;
    }

    /**
     * Reads a token from the input stream. The token is placed in member variable nextToken.
     */
    private void getToken () {
        char c;

        do {
            c = getc(stream);
        } while (isWhite(c));

        if (c == '(') {
            nextToken = Token(TokenType.leftParen);

        } else if (c == ')') {
            nextToken = Token(TokenType.rightParen);

        } else if (c == '.') {
            nextToken = Token(TokenType.dot);

        } else if (isDigit(c)) {
            cstdio.ungetc(cast(int)c, stream.getFP());

            int intValue;
            stream.readf("%d", &intValue);
            nextToken = Token(TokenType.integer, intValue);

        } else if (c == '\"') {
            string stringValue;
            c = getc(stream);

            do {
                stringValue ~= c;
                c = getc(stream);
            } while (c != '\"');

            nextToken = Token(TokenType.string, stringValue);

       } else {
            string stringValue;

            do {
                stringValue ~= c;
                c = getc(stream);
            } while (!isWhite(c) && c != '(' && c != ')');

            nextToken = Token(TokenType.identifier, stringValue);
        }
    }

    /**
     * Tries to match a token from the next token from the input stream.
     *
     * @param a token to match.
     * @return true if the token matches the next token from input, false otherwise.
     */
    private bool matchToken (TokenType type) {
        if (nextToken.type != type) {
            writeln("mismatched token, expected ", Token(type), " got ", nextToken);
            return false;
        }

        writeln("matched ", nextToken);
        getToken();
        return true;
    }

    /**
     * Parses a Lisp list.
     *
     * @return a ReferenceValue object containing a reference to the first node of a list.
     */
    private ReferenceValue parseList () {
        ReferenceValue root, node;

        writeln("{ parseList");

        matchToken(TokenType.leftParen);
        root = node = Value.makeReference(Value.fromToken(nextToken));
        getToken();

        if (nextToken.type == TokenType.dot) {
            matchToken(TokenType.dot);
            root.reference.cdr = Value.fromToken(nextToken);
            getToken();
            if (!matchToken(TokenType.rightParen)) {
                return null;
            }
            return root;

        } else {
            while (true) {
                switch (nextToken.type) {
                    case TokenType.leftParen:
                        ReferenceValue newReference = Value.makeReference(parseList());
                        node.reference.cdr = newReference;
                        node = newReference;
                        break;

                    case TokenType.rightParen:
                        writeln("} parseList");
                        return root;

                    default:
                        writeln("got token ", nextToken);

                        ReferenceValue newReference = Value.makeReference(Value.fromToken(nextToken));
                        node.reference.cdr = newReference;
                        node = newReference;

                }

                getToken();
            }
        }
    }

    /**
     * @return a Value object containing the next whole Lisp object from input.
     */
    Value parse () {
        getToken();

        writeln("parse token ", nextToken.type);

        if (nextToken.type == TokenType.leftParen) {
            return parseList();

        } else if (nextToken.type == TokenType.rightParen) {
            // syntax error
            return null;

        } else {
            return Value.fromToken(nextToken);
        }
    }
}
