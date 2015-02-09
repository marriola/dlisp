import std.stdio;

import node;
import parser;
import token;

void main (string args[]) {
    File input;

    if (args.length < 2) {
        input = stdin;
    } else {
        try {
            input = File(args[1]);
        } catch (Exception e) {
            writeln("Error: ", e.msg);
            return;
        }
    }

    LispParser lisp = new LispParser(input);

    while (true) {
        stdout.write("> "); stdout.flush();
        try {
            Token tree = lisp.read();
            writef("%s\n\n", tree);
        } catch (SyntaxErrorException e) {
            writef("Syntax error: %s\n\n", e.msg);
        }
    }
}