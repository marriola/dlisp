import std.stdio;

//import evaluator;
import exceptions;
import functions;
import node;
import parser;
import token;
import variables;
import vm.lispmacro;
import vm.machine;

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
	initializeVm();
    LispParser lisp = new LispParser(input);

    while (true) {
        if (printPrompt) {
            stdout.write("> "); stdout.flush();
        }
        
        try {
            Value tree = lisp.read();
            writef("%s\n\n", evaluate(tree));
        } catch (SyntaxErrorException e) {
            writef("Syntax error: %s\n\n", e.msg);
        } catch (UncompiledFunctionException e) {
            writef("Undefined function: %s\n\n", e.msg);
        } catch (UndefinedVariableException e) {
            writef("Undefined variable: %s\n\n", e.msg);
        } catch (VirtualMachineException e) {
            writef("Virtual machine error: %s\n\n", e.msg);
        } catch (Exception e) {
            writef("Error: %s\n\n", e.msg);            
        }
    }
}