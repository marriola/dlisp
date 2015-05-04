module vm.compiler;

import std.container.slist;

import exceptions;
import functions;
import lispObject;
import token;
import vm.bytecode;
import vm.lispmacro;
import vm.machine;


///////////////////////////////////////////////////////////////////////////////

abstract class LispVisitor {
    public void visit (Value value, Token token) {


        switch (token.type) {
            case TokenType.boolean:
                visit(value, cast(BooleanToken)token);
                break;

            case TokenType.reference:
                visit(value, cast(ReferenceToken)token);
                break;

            case TokenType.integer:
                visit(value, cast(IntegerToken)token);
                break;

            case TokenType.floating:
                visit(value, cast(FloatToken)token);
                break;

            case TokenType.identifier:
                visit(value, cast(IdentifierToken)token);
                break;

            case TokenType.string:
                visit(value, cast(StringToken)token);
                break;

            case TokenType.constant:
                visit(value, cast(ConstantToken)token);
                break;

            case TokenType.character:
                visit(value, cast(CharacterToken)token);
                break;

            case TokenType.fileStream:
                visit(value, cast(FileStreamToken)token);
                break;

            case TokenType.builtinFunction:
                visit(value, cast(BuiltinFunctionToken)token);
                break;

            case TokenType.definedFunction:
                visit(value, cast(DefinedFunctionToken)token);
                break;

            default:
                assert(0);
        }
    }

    public void visit (Value value, BooleanToken token);
    public void visit (Value value, ReferenceToken token);
    public void visit (Value value, IntegerToken token);
    public void visit (Value value, FloatToken token);
    public void visit (Value value, IdentifierToken token);
    public void visit (Value value, CharacterToken token);
    public void visit (Value value, StringToken token);
    public void visit (Value value, ConstantToken token);
    public void visit (Value value, FileStreamToken token);
    public void visit (Value value, VectorToken token);
    public void visit (Value value, BuiltinFunctionToken token);
    public void visit (Value value, DefinedFunctionToken token);
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Walks through a Lisp form and builds a constants table.
 */
class ConstantsVisitor : LispVisitor {
    alias LispVisitor.visit visit;
    private Value form;
    ConstantPair[string] constants;
    int nextConstant = 0;

    private SList!bool lastValue;
    private SList!bool firstElement;
    private bool quoted = false;
    private int level = 0;

    this (Value form) {
        this.form = form;
        firstElement.insert(true);
        lastValue.insert(true);
        quoted = false;
    }

    private void addConstant (Value value) {
        if (!value.isNil()) {
            string asString = value.toString();
            if (asString !in constants) {
                constants[asString] = ConstantPair(nextConstant, value);
                nextConstant++;
            }
        }
    }

    override public void visit (Value value, BooleanToken token) {
        addConstant(value);
    }

    override public void visit (Value value, IntegerToken token) {
        addConstant(value);
    }

    override public void visit (Value value, FloatToken token) {
        addConstant(value);
    }

    override public void visit (Value value, CharacterToken token) {
        addConstant(value);
    }

    override public void visit (Value value, StringToken token) {
        addConstant(value);
    }

    override public void visit (Value value, ConstantToken token) {
        addConstant(value);
    }

    override public void visit (Value value, FileStreamToken token) {
        addConstant(value);
    }

    override public void visit (Value value, VectorToken token) {
        addConstant(value);
    }

    override public void visit (Value value, BuiltinFunctionToken token) {
        addConstant(value);
    }

    override public void visit (Value value, DefinedFunctionToken token) {
        addConstant(value);
    }


    override public void visit (Value value, IdentifierToken token) {
        if (quoted || !firstElement.front()) {
            // Don't add list initial identifier tokens in function calls. These won't be referenced.
            addConstant(value);
        }

        firstElement.removeFront();
        firstElement.insert(false);
    }

    override public void visit (Value value, ReferenceToken token) {
        if (quoted) {
            addConstant(token.reference.car);
            return;
        }

        level++;

        bool isFirst = lastValue.front();
        firstElement.insert(isFirst);
        if (!quoted && isFirst && (token.reference.car.token.type == TokenType.identifier && (cast(IdentifierToken)token.reference.car.token).stringValue == "QUOTE")) {
            quoted = true;
        }

        lastValue.insert(token.reference.car.token.type == TokenType.reference);
        if (!quoted) {
            token.reference.car.accept(this);
        }
        token.reference.cdr.accept(this);
        lastValue.removeFront();

        firstElement.removeFront();
        if (level == 1) {
            quoted = false;
        }
        level--;
    }

    public ConstantPair[string] getConstantPairs () {
        form.accept(this);
        return constants;
    }

    public Value[] getConstants() {
        Value[] x = new Value[constants.length];
        foreach (ConstantPair pair; constants) {
            x[pair.index] = pair.constant;
        }

        //return std.array.array(std.algorithm.map!(x => (cast(ConstantPair)x).constant)(constants.values));
        return x;
    }
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Walks through a Lisp form and generates equivalent bytecode.
 */
class CodeEmitterVisitor : LispVisitor {
    alias LispVisitor.visit visit;
    private ConstantPair[string] constants;
    private Value form;
    private Instruction[] code;
    int nextConstant;

    this (int nextConstant, ConstantPair[string] constants, Value form) {
        this.constants = constants;
        this.form = form;
        this.nextConstant = nextConstant;
    }

    private void pushConstant (Value value) {
        if (value.isNil()) {
            code ~= Instruction(Opcode.pushnil1);
        } else {
            string asString = value.toString();
            //std.stdio.writef("pushConstant %s\n", asString);
            if (asString in constants) {
                Instruction push = Instruction(Opcode.pushconst, [constants[asString].index]);
                //std.stdio.writef("%s\n", push);
                code ~= push;
            } else {
                throw new Exception("Can't find " ~ value.toString() ~ " in constants table");
            }
        }
    }

    private void pushCall (string name, Value arguments) {
        //std.stdio.writef("pushCall(%s, %s)\n", name, arguments);

        if (name in compilerMacros) {
            compilerMacros[name].evaluate(name, nextConstant, constants, code, arguments);
            return;
        }

        int argCount = 0;
        foreach_reverse (Value argument; toArray(arguments)) {
            //std.stdio.writef("next %s\n", argument);
            argument.accept(this);
            argCount++;
        }

        BuiltinFunction* builtin = getBuiltin(name);
        Instruction call;
        if (builtin !is null && builtin.id > 0) {
            if (argCount == 0) {
                call = Instruction(Opcode.builtin0, [cast(uint)builtin.id]);
            } else if (argCount == 1) {
                call = Instruction(Opcode.builtin1, [cast(uint)builtin.id]);
            } else {
                call = Instruction(Opcode.builtin, [cast(uint)builtin.id, cast(uint)argCount]);
            }

        } else {
            LispFunction* fun = getDefined(name);
            if (fun !is null) {
                if (argCount == 0) {
                    call = Instruction(Opcode.fun0, [cast(uint)fun.id]);
                } else if (argCount == 1) {
                    call = Instruction(Opcode.fun1, [cast(uint)fun.id]);
                } else {
                    call = Instruction(Opcode.fun, [cast(uint)fun.id, cast(uint)argCount]);
                }
            } else {
                throw new UndefinedFunctionException(name);
            }
        }

        code ~= call;
        //std.stdio.writef("%s\n", call.toString());
    }

    override public void visit (Value value, BooleanToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, ReferenceToken token) {
        //std.stdio.writef("visit %s\n", token);
        if ((token.reference.car.token.type == TokenType.identifier && (cast(IdentifierToken)token.reference.car.token).stringValue == "QUOTE")) {
            //std.stdio.writef("%s is quoted\n", token.reference.cdr);
            pushConstant(value);
            return;
        }

        if (token.reference.car.token.type == TokenType.identifier) {
            //std.stdio.writef("function call %s\n", token.reference.car);
            pushCall((cast(IdentifierToken)token.reference.car.token).stringValue, token.reference.cdr);
        }
    }

    override public void visit (Value value, IntegerToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, FloatToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, IdentifierToken token) {
        // Don't add list initial identifier tokens in function calls. These won't be referenced.
        pushConstant(value);
    }

    override public void visit (Value value, CharacterToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, StringToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, ConstantToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, FileStreamToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, VectorToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, BuiltinFunctionToken token) {
        pushConstant(value);
    }

    override public void visit (Value value, DefinedFunctionToken token) {
        pushConstant(value);
    }

    public Instruction[] compile () {
        form.accept(this);
        return code;
    }
}


///////////////////////////////////////////////////////////////////////////////

BytecodeFunction compile (Value form) {
    BytecodeFunction results;

    results.entry = vm.machine.nextEntry;

    ConstantsVisitor constantsVisitor = new ConstantsVisitor(form);
    ConstantPair[string] constantPairs = constantsVisitor.getConstantPairs();
    results.constants = constantsVisitor.getConstants();

    //std.stdio.writeln("code");
    CodeEmitterVisitor codeEmitterVisitor = new CodeEmitterVisitor(constantsVisitor.nextConstant, constantPairs, form);
    results.code = codeEmitterVisitor.compile();
    //std.stdio.writeln(results.code);

    return results;
}    
