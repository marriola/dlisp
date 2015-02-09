module variables;

import std.container;
import token;

class UndefinedVariableException : Exception {
    this (string msg) {
        super(msg);
    }
}

Array!(Token[string]) scopeTable;

void enterScope () {
    Token[string] newScope;
    scopeTable.insertBack(newScope);
}

void leaveScope () {
    scopeTable.removeBack();
}

void initializeScopeTable () {
    enterScope();
    addVariable("E", new FloatToken(std.math.E));
    addVariable("PI", new FloatToken(std.math.PI));
}

Token getVariable (string name) {
    foreach_reverse (Token[string] table; scopeTable) {
        if (name in table) {
            return table[name];
        }
    }

    throw new UndefinedVariableException(name);
}

void addVariable (string name, Token token) {
    scopeTable.back()[name] = token;
}

unittest {
    enterScope();

    addVariable("foo", new StringToken("bar"));
    assert((cast(StringToken)getVariable("foo")).stringValue == "bar");

    enterScope();
    addVariable("foo", new StringToken("baz"));
    assert((cast(StringToken)getVariable("foo")).stringValue == "baz");

    leaveScope();
    addVariable("foo", new StringToken("bar"));
    assert((cast(StringToken)getVariable("foo")).stringValue == "bar");

    leaveScope();
}