import std.stdio;

import node;
import parser;

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

    LispParser parser = new LispParser(input);

    stdout.write("> "); stdout.flush();
    Node tree = parser.parse();

    if (tree) {
        writef("You said: %s", tree.toString());
    } else {
        writeln("Syntax error");
    }
}