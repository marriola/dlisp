module vm.compilermacro;

import token;
import vm.bytecode;
import vm.machine;


///////////////////////////////////////////////////////////////////////////////

struct CompilerMacro {
    string name;
    void function(ConstantPair[string] constants, ref Instruction[] code, Value value) evaluate;
}

CompilerMacro[string] compilerMacros;
