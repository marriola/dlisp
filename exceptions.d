module exceptions;

import std.conv;

import token;

///////////////////////////////////////////////////////////////////////////////


class BuiltinException : Exception {
    this (string caller, string msg) {
        super(caller ~ ": " ~ msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class EvaluationException : Exception {
    this (string msg) {
        super(msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class NotEnoughArgumentsException : Exception {
    this (string caller) {
        super(caller ~ ": Not enough arguments");
    }
}


///////////////////////////////////////////////////////////////////////////////

class OutOfBoundsException : Exception {
    this (int index) {
        super("Index " ~ to!string(index) ~ " is out of bounds");
    }
}


///////////////////////////////////////////////////////////////////////////////

class TypeMismatchException : Exception {
    this (string caller, Token token, string expectedType) {
        super(caller ~ ": " ~ token.toString() ~ " is not " ~ expectedType);
    }
}


///////////////////////////////////////////////////////////////////////////////

class UndefinedFunctionException : Exception {
    this (string msg) {
        super(msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class UndefinedVariableException : Exception {
    this (string msg) {
        super(msg);
    }
}


///////////////////////////////////////////////////////////////////////////////

class UnsupportedOperationException : Exception {
    this (Token token, string operation) {
        super(operation ~ " operation is unsupported on " ~ tokenTypeName(token.type) ~ " token");
    }
}