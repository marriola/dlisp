import std.stdio;

import evaluator;
import functions;
import node;
import parser;
import token;
import variables;

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

    initializeScopeTable();
    initializeBuiltins();
    LispParser lisp = new LispParser(input);

    while (true) {
        stdout.write("> "); stdout.flush();
        try {
            Token tree = lisp.read();
            writef("%s\n\n", evaluate(tree));
        } catch (SyntaxErrorException e) {
            writef("Syntax error: %s\n\n", e.msg);
        } catch (UndefinedFunctionException e) {
            writef("Undefined function: %s\n\n", e.msg);
        } catch (UndefinedVariableException e) {
            writef("Undefined variable: %s\n\n", e.msg);
        } catch (EvaluationException e) {
            writef("Error: %s\n\n", e.msg);
        } catch (Exception e) {
            writef("Error: %s\n\n", e.msg);            
        }
    }
}