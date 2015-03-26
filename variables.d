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
    //if (src.type != dest.type) {
    //    throw new TypeMismatchException("copyValue", src, tokenTypeName(dest.type));
    //}

    //switch (src.type) {
    //    case TokenType.boolean:
    //        (cast(BooleanToken)dest).boolValue = (cast(BooleanToken)src).boolValue;
    //        return;

    //    case TokenType.integer:
    //        (cast(IntegerToken)dest).intValue = (cast(IntegerToken)src).intValue;
    //        return;

    //    case TokenType.floating:
    //        (cast(FloatToken)dest).floatValue = (cast(FloatToken)src).floatValue;
    //        return;

    //    case TokenType.string:
    //        (cast(StringToken)dest).stringValue = "" ~ (cast(StringToken)src).stringValue;
    //        return;

    //    case TokenType.identifier:
    //        (cast(IdentifierToken)dest).stringValue = "" ~ (cast(IdentifierToken)src).stringValue;
    //        return;

    //    case TokenType.constant:
    //        (cast(ConstantToken)dest).stringValue = "" ~ (cast(ConstantToken)src).stringValue;
    //        return;

    //    case TokenType.reference:
    //        (cast(ReferenceToken)dest).reference = (cast(ReferenceToken)src).reference;
    //        return;

    //    case TokenType.vector:
    //        (cast(VectorToken)dest).array = (cast(VectorToken)src).array;
    //        return;

    //    case TokenType.fileStream:
    //        (cast(FileStreamToken)dest).fileSpec = (cast(FileStreamToken)src).fileSpec;
    //        (cast(FileStreamToken)dest).direction = (cast(FileStreamToken)src).direction;
    //        (cast(FileStreamToken)dest).stream = (cast(FileStreamToken)src).stream;
    //        (cast(FileStreamToken)dest).isOpen = (cast(FileStreamToken)src).isOpen;
    //        return;

    //    default:
    //        return;
    //}
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