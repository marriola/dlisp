import std.stdio;

import evaluator;
import exceptions;
import functions;
import node;
import parser;
import token;
import variables;
import vm.compiler;
import vm.machine;
import vm.lispmacro;

void main (string args[]) {
    File input;
    bool printPrompt = true;

    if (args.length < 2) {
        input = stdin;
    } else {
        try {
            input = File(args[1]);
            printPrompt = false;
        } catch (Exception e) {
            writeln("Error: ", e.msg);
            return;
        }
    }

    initializeScopeTable();
    initializeBuiltins();
    initializeMacros();
    LispParser lisp = new LispParser(input);

    while (true) {
        if (printPrompt) {
            stdout.write("> "); stdout.flush();
        }
        
        try {
            Value tree = lisp.read();
            //BytecodeFunction fun = compile(tree);
            //writef("%s\n\n", evaluateOnce(tree));
            //writef("Constants: %s\n%s\n\n", fun.constants, fun.code);
            writef("%s\n\n", vm.machine.evaluate(tree));
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