module parser;

import cstdio = core.stdc.stdio;
import std.ascii;
import std.file;
import std.stdio;

import node;
import token;

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
            nextToken = new LexicalToken(TokenType.leftParen);

        } else if (c == ')') {
            nextToken = new LexicalToken(TokenType.rightParen);

        } else if (c == '.') {
            nextToken = new LexicalToken(TokenType.dot);

        } else if (isDigit(c)) {
            cstdio.ungetc(cast(int)c, stream.getFP());

            int intValue;
            stream.readf("%d", &intValue);
            nextToken = new IntegerToken(intValue);

        } else if (c == '\"') {
            string stringValue;
            c = getc(stream);

            do {
                stringValue ~= c;
                c = getc(stream);
            } while (c != '\"');

            nextToken = new StringToken(stringValue);

       } else {
            string stringValue;

            do {
                stringValue ~= c;
                c = getc(stream);

                if (c == '(' || c == ')') {
                    cstdio.ungetc(cast(int)c, stream.getFP());;
                    break;
                }
            } while (!isWhite(c));

            nextToken = new IdentifierToken(stringValue);
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
            writeln("mismatched token, expected ", type, " got ", nextToken);
            return false;
        }

        getToken();
        return true;
    }

    /**
     * Parses a Lisp list.
     *
     * @return a ReferenceToken object containing a reference to the first node of a list.
     */
    private ReferenceToken parseList () {
        ReferenceToken root, node;

        matchToken(TokenType.leftParen);
        root = node = Token.makeReference(nextToken);
        getToken();

        if (nextToken.type == TokenType.dot) {
            matchToken(TokenType.dot);
            root.reference.cdr = nextToken;
            getToken();
            if (!matchToken(TokenType.rightParen)) {
                return null;
            }
            return root;

        } else {
            while (true) {
                switch (nextToken.type) {
                    case TokenType.leftParen:
                        ReferenceToken newReference = Token.makeReference(parseList());
                        node.reference.cdr = newReference;
                        node = newReference;
                        break;

                    case TokenType.rightParen:
                        return root;

                    default:
                        ReferenceToken newReference = Token.makeReference(nextToken);
                        node.reference.cdr = newReference;
                        node = newReference;

                }

                getToken();
            }
        }
    }

    /**
     * @return a Token object containing the next whole Lisp object from input.
     */
    Token parse () {
        getToken();

        if (nextToken.type == TokenType.leftParen) {
            return parseList();

        } else if (nextToken.type == TokenType.rightParen) {
            // syntax error
            return null;

        } else {
            return nextToken;
        }
    }
}
