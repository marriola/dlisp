module variables;

import std.container;

import exceptions;
import token;


///////////////////////////////////////////////////////////////////////////////

enum VariableType { lexical, dynamic };

Array!(Value[string]) scopeTable;


///////////////////////////////////////////////////////////////////////////////

void enterScope () {
    Value[string] newScope;
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

void addVariable (string name, Value token) {
    scopeTable.back()[name] = token;
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