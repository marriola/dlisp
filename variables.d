module variables;

import std.container;

import exceptions;
import token;


///////////////////////////////////////////////////////////////////////////////

enum VariableType { lexical, dynamic };

alias ScopeTable = Array!(Value[string]);

ScopeTable scopeTable;


///////////////////////////////////////////////////////////////////////////////

void enterScope () {
    Value[string] newScope;
    scopeTable.insertBack(newScope);
}

void enterScope (Value[string] newScope) {
    scopeTable.insertBack(newScope);
}


///////////////////////////////////////////////////////////////////////////////

void leaveScope () {
    scopeTable.removeBack();
}


///////////////////////////////////////////////////////////////////////////////

void initializeScopeTable () {
    enterScope();
    addVariable("E", new Value(new FloatToken(std.math.E)));
    addVariable("PI", new Value(new FloatToken(std.math.PI)));
}


///////////////////////////////////////////////////////////////////////////////

Value getVariable (string name) {
    foreach_reverse (Value[string] table; scopeTable) {
        if (name in table) {
            return table[name];
        }
    }

    throw new UndefinedVariableException(name);
}


///////////////////////////////////////////////////////////////////////////////

/**
 * Retrieves a parameter as passed to a function. The difference from
 * getVariable is that a colon is prepended to the name of the parameter to
 * avoid naming conflicts in case an identifier with an otherwise identical
 * name is passed as the value of the parameter.
 */

Value getParameter (string name) {
    Value[string] currentScope = scopeTable.back();
    name = ":" ~ name;
    if (name in currentScope) {
        return currentScope[name];
    }
    throw new UndefinedVariableException(name);
}


///////////////////////////////////////////////////////////////////////////////

void addVariable (string name, Value token, int scopeLevel = -1) {
    if (scopeLevel >= 0) {
        auto table = scopeTable[scopeLevel];
        table[name] = token;
    } else {
        auto table = scopeTable.back();
        table[name] = token;
    }
}


///////////////////////////////////////////////////////////////////////////////

void copyValue (Value src, Value dest) {
    dest.token = src.token;
}


///////////////////////////////////////////////////////////////////////////////

unittest {
    enterScope();

    addVariable("foo", new Value(new StringToken("bar")));
    //assert((cast(StringToken)getVariable("foo")).stringValue == "bar");

    enterScope();
    addVariable("foo", new Value(new StringToken("baz")));
    //assert((cast(StringToken)getVariable("foo")).stringValue == "baz");

    leaveScope();
    addVariable("foo", new Value(new StringToken("bar")));
    //assert((cast(StringToken)getVariable("foo")).stringValue == "bar");

    leaveScope();
}