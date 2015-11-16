module exceptions;

import std.array : array, join;
import std.algorithm : map;
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

class WrongNumberOfIndicesException : Exception {
    this (int rank) {
        super("Wrong number of indices given (vector has rank " ~ to!string(rank) ~ ")");
    }
}


///////////////////////////////////////////////////////////////////////////////

class OutOfBoundsException : Exception {
    this (int index) {
        super("Index " ~ to!string(index) ~ " is out of bounds");
    }

    this (int[] indices) {
        super("Index (" ~ join(map!(x => to!string(x))(indices).array(), ", ") ~ ") is out of bounds");
    }
}


///////////////////////////////////////////////////////////////////////////////

class TypeMismatchException : Exception {
    this (string caller, Token token, string expectedType) {
        super(caller ~ ": " ~ token.toString() ~ " is not " ~ expectedType);
    }
}


///////////////////////////////////////////////////////////////////////////////

class InvalidLambdaListElementException : Exception {
    this (Token token, string reason) {
        super("Invalid lambda list element " ~ token.toString() ~ ", " ~ reason);
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
        super(operation ~ " operation is not supported on " ~ tokenTypeName(token.type) ~ " token");
    }
}


///////////////////////////////////////////////////////////////////////////////

class CompilerException : Exception {
	this (string message) {
		super(message);
	}
}


///////////////////////////////////////////////////////////////////////////////

class VirtualMachineException : Exception {
	this (string message) {
		super(message);
	}
}