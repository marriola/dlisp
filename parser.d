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
