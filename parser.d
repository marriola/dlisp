module parser;

import std.ascii;
import std.conv;
import std.file;
import std.stdio;
import std.string;

import node;
import token;

class SyntaxErrorException : Exception {
    this (string msg) {
        super(msg);
    }
}

/**
 * @param a file stream to read from.
 * @return a single character.
 */
char getc (File stream) {
    return cast(char)core.stdc.stdio.fgetc(stream.getFP());
}

/**
 * Puts a character back into the input stream.
 * @param c
 * @param stream
 */
void ungetc (char c, File stream) {
    core.stdc.stdio.ungetc(cast(int)c, stream.getFP());
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

        } else if (c == '\'') {
            // Encapsulate the next token in a quote.
            // We grab the next token, and throw it in a new list with the identifier QUOTE as the first item, and it as the second.
            getToken();

            Token quotedItem;
            if (nextToken.isLexicalToken()) {
                if (nextToken.type != TokenType.leftParen) {
                    throw new SyntaxErrorException("Expected non-lexical token or left paren, got " ~ nextToken.toString());
                } else {
                    quotedItem = parseList();
                }
            } else {
                quotedItem = nextToken;
            }

            nextToken = Token.makeReference(new IdentifierToken("QUOTE"), Token.makeReference(quotedItem));

        } else if (isDigit(c)) {
            bool isFloat = false;
            string literal;

            do {
                literal ~= c;
                c = getc(stream);

                if (c == '.' || c == 'e' || c == 'E') {
                    isFloat = true;

                } else if (c == '(' || c == ')') {
                    ungetc(c, stream);
                    break;
                }
            } while (!isWhite(c));

            try {
                if (isFloat) {
                    nextToken = new FloatToken(to!double(literal));
                } else {
                    nextToken = new IntegerToken(to!int(literal));
                }
            } catch (ConvException e) {
                throw new SyntaxErrorException("malformed number literal");
            }

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
                    ungetc(c, stream);
                    break;
                }
            } while (!isWhite(c));

            if (stringValue[0] == ':') {
                nextToken = new ConstantToken(stringValue[1..$]);

            } else if (icmp(stringValue, "nil") == 0) {
                nextToken = new BooleanToken(false);

            } else if (icmp(stringValue, "t") == 0) {
                nextToken = new BooleanToken(true);

            } else {
                nextToken = new IdentifierToken(stringValue);
            }
        }
    }

    /**
     * Tries to match a token from the next token from the input stream.
     *
     * @param a token to match.
     * @return true if the token matches the next token from input, false otherwise.
     */
    private void matchToken (TokenType type, bool readNext = true) {
        if (nextToken.type != type) {
            throw new SyntaxErrorException("expected " ~ tokenTypeName(type) ~ ", got " ~ nextToken.toString());
        }

        if (readNext) {
            getToken();
        }
    }

    /**
     * Parses a Lisp list.
     *
     * @return a ReferenceToken object containing a reference to the first node of a list.
     */
    private Token parseList () {
        ReferenceToken root, node;

        matchToken(TokenType.leftParen);
        if (nextToken.type == TokenType.rightParen) {
            return new BooleanToken(false);
        }

        root = node = Token.makeReference(nextToken);
        getToken();

        if (nextToken.type == TokenType.dot) {
            matchToken(TokenType.dot);
            root.reference.cdr = nextToken;
            getToken();
            matchToken(TokenType.rightParen, false);
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
                        matchToken(TokenType.rightParen, false);
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
    Token read () {
        getToken();

        if (nextToken.type == TokenType.leftParen) {
            return parseList();

        } else if (nextToken.type == TokenType.rightParen) {
            throw new SyntaxErrorException("Expected left paren or non-lexical token");

        } else {
            return nextToken;
        }
    }
}
