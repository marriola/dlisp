import std.stdio;

import node;
import parser;

void main () {
    LispParser parser = new LispParser();

    stdout.write("> "); stdout.flush();
    Node tree = parser.parse();

    if (tree) {
        writef("You said: %s", tree.toString());
    } else {
        writeln("Syntax error");
    }
}