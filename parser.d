module parser;

import std.ascii;
import std.conv;
import std.file;
import std.stdio;
import std.string;

import node;
import token;

class EndOfFile : Exception {
    this () {
        super("");
    }
}

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
    char c = cast(char)core.stdc.stdio.fgetc(stream.getFP());
    if (c == 255) {
        throw new EndOfFile();
    }
    return c;
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
    private bool grabNext = true;

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

        if (!grabNext) {
            // If we checked that the current token began an m-expression, but it didn't, then we want to keep it.
            grabNext = true;
            return;
        }

        do {
            c = getc(stream);
        } while (isWhite(c));

        if (c == '(') {
            nextToken = new LexicalToken(TokenType.leftParen);
            return;

        } else if (c == ')') {
            nextToken = new LexicalToken(TokenType.rightParen);
            return;

        } else if (c == '[') {
            nextToken = new LexicalToken(TokenType.leftBrack);
            return;

        } else if (c == ']') {
            nextToken = new LexicalToken(TokenType.rightBrack);
            return;

        } else if (c == '.') {
            nextToken = new LexicalToken(TokenType.dot);
            return;

        } else if (c == '\'') {
            // Encapsulate the next token in a quote.
            // We grab the next token, and throw it in a new list with the identifier QUOTE as the first item, and it as the second.
            getToken();

            Token quotedItem;
            if (nextToken.isLexicalToken()) {
                if (nextToken.type != TokenType.leftParen) {
                    throw new SyntaxErrorException("Expected non-lexical token or left paren, got " ~ nextToken.toString());
                } else {
                    quotedItem = parseList(false);
                }
            } else {
                quotedItem = nextToken;
            }

            nextToken = Token.makeReference(new IdentifierToken("QUOTE"), Token.makeReference(quotedItem));
            return;

        } else if (isDigit(c) || c == '-') {
            bool giveUp = false;

            // is this a negative number or an identifier starting with a hyphen?
            if (c == '-') {
                // get the next character and put it back
                char next = getc(stream);
                ungetc(next, stream);

                if (!isDigit(next)) {
                    // if not a digit, this is an identifier. skip the next block.
                    giveUp = true;
                }
            }

            if (!giveUp) {
                bool isFloat = false;
                string literal;

                do {
                    literal ~= c;
                    c = getc(stream);

                    if (c == '.' || c == 'e' || c == 'E') {
                        isFloat = true;

                    } else if (c == '(' || c == ')' || c == '[' || c == ']') {
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
                return;
            }

        } else if (c == '\"') {
            string stringValue;
            c = getc(stream);

            do {
                stringValue ~= c;
                c = getc(stream);
            } while (c != '\"');

            nextToken = new StringToken(stringValue);
            return;
       }

       {
            string stringValue;

            do {
                stringValue ~= c;
                c = getc(stream);

                if (c == '(' || c == ')' || c == '[' || c == ']') {
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
    private Token parseList (bool mExpression, Token identifier = null) {
        ReferenceToken root, node;

        matchToken(mExpression ? TokenType.leftBrack : TokenType.leftParen);
        if ((mExpression && nextToken.type == TokenType.rightBrack) ||
            nextToken.type == TokenType.rightParen) {
            return new BooleanToken(false);
        }

        root = node = Token.makeReference(mExpression ? identifier : nextToken);
        if (!mExpression) {
            getToken();
        }

        if (!mExpression && nextToken.type == TokenType.dot) {
            matchToken(TokenType.dot);
            root.reference.cdr = nextToken;
            getToken();
            matchToken(TokenType.rightParen, false);
            return root;

        } else {
            while (true) {
                switch (nextToken.type) {
                    case TokenType.leftParen:
                        ReferenceToken newReference = Token.makeReference(parseList(false));
                        node.reference.cdr = newReference;
                        node = newReference;
                        break;

                    case TokenType.rightBrack:
                        if (!mExpression) {
                            throw new SyntaxErrorException("Expected right paren");
                        }

                        matchToken(TokenType.rightBrack, false);
                        return root;

                    case TokenType.rightParen:
                        if (mExpression) {
                            throw new SyntaxErrorException("Expected right bracket");
                        }

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
            return parseList(false);


        } else if (nextToken.type == TokenType.rightParen) {
            throw new SyntaxErrorException("Expected left paren or non-lexical token");

        //} else if (nextToken.type == TokenType.identifier) {
        //    // check if this is an m-expression
        //    Token identifier = nextToken;
        //    getToken();

        //    if (nextToken.type == TokenType.leftBrack) {
        //        // yes, parse m-expression
        //        return parseList(true, identifier);

        //    } else {
        //        // no, return the identifier we grabbed and leave the next token queued up
        //        grabNext = false;
        //        return identifier;
        //    }

        } else {
            return nextToken;
        }
    }
}
