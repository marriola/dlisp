module token;

import exceptions;
import functions;
import lispObject;
import node;

import std.algorithm;
import std.stdio;
import std.conv;
import std.string;


///////////////////////////////////////////////////////////////////////////////

enum TokenType { leftParen, rightParen, leftBrack, rightBrack, dot, boolean, reference, integer, floating, identifier, string, constant, fileStream, vector, builtinFunction, definedFunction };


///////////////////////////////////////////////////////////////////////////////


string tokenTypeName (TokenType type) {
    static string typeNames[] = [ "left paren", "right paren", "left bracket", "right bracket", "dot", "boolean", "reference", "integer", "floating point", "identifier", "string", "constant", "file stream", "vector", "lambda" ];
    return typeNames[cast(int)type];
}


///////////////////////////////////////////////////////////////////////////////

// This is kind of an ugly hack that lets us swap in a token of a different type into a Node's CAR or CDR.
class Value {
    Token token;

    this (Token token) {
        this.token = token;
    }

    /**
     * Produces a new Value object with a copy of the encapsulated token.
     */
    Value copy () {
        return new Value(token.copy());
    }

    /**
     * Appends an element to the encapsulated Token object. If its value is not
     * '() (aka NIL) or a list, it throws an UnsupportedOperationException.
     */
    void append (Value element) {
        if (token.type == TokenType.boolean && (cast(BooleanToken)token).boolValue == false) {
            token = Token.makeReference(element).token;

        } else if (token.type == TokenType.reference) {
            (cast(ReferenceToken)token).append(element);

        } else {
            throw new UnsupportedOperationException(token, "Append");
        }
    }

    override string toString () {
        return token.toString();
    }

    void add (Value addend) {
        if (token.type != TokenType.integer && token.type != TokenType.floating) {
            throw new UnsupportedOperationException(token, "Addition");
        } else if (addend.token.type != TokenType.integer && addend.token.type != TokenType.floating) {
            throw new UnsupportedOperationException(addend.token, "Addition");
        }

        if (token.type == TokenType.floating) {
            (cast(FloatToken)token).floatValue += addend.token.type == TokenType.integer ? (cast(IntegerToken)addend.token).intValue : (cast(FloatToken)addend.token).floatValue;
        } else if (addend.token.type == TokenType.floating) {
            token = new FloatToken((cast(IntegerToken)token).intValue + (cast(FloatToken)addend.token).floatValue);
        } else {
            (cast(IntegerToken)token).intValue += (cast(IntegerToken)addend.token).intValue;
        }
    }

    void subtract (Value subtrahend) {
        if (token.type != TokenType.integer && token.type != TokenType.floating) {
            throw new UnsupportedOperationException(token, "Subtraction");
        } else if (subtrahend.token.type != TokenType.integer && subtrahend.token.type != TokenType.floating) {
            throw new UnsupportedOperationException(subtrahend.token, "Subtraction");
        }

        if (token.type == TokenType.floating) {
            (cast(FloatToken)token).floatValue -= subtrahend.token.type == TokenType.integer ? (cast(IntegerToken)subtrahend.token).intValue : (cast(FloatToken)subtrahend.token).floatValue;
        } else if (subtrahend.token.type == TokenType.floating) {
            token = new FloatToken((cast(IntegerToken)token).intValue - (cast(FloatToken)subtrahend.token).floatValue);
        } else {
            (cast(IntegerToken)token).intValue -= (cast(IntegerToken)subtrahend.token).intValue;
        }
    }

    void multiply (Value multiplicand) {
        if (token.type != TokenType.integer && token.type != TokenType.floating) {
            throw new UnsupportedOperationException(token, "Multiplication");
        } else if (multiplicand.token.type != TokenType.integer && multiplicand.token.type != TokenType.floating) {
            throw new UnsupportedOperationException(multiplicand.token, "Multiplication");
        }

        if (token.type == TokenType.floating) {
            (cast(FloatToken)token).floatValue *= multiplicand.token.type == TokenType.integer ? (cast(IntegerToken)multiplicand.token).intValue : (cast(FloatToken)multiplicand.token).floatValue;
        } else if (multiplicand.token.type == TokenType.floating) {
            token = new FloatToken((cast(IntegerToken)token).intValue * (cast(FloatToken)multiplicand.token).floatValue);
        } else {
            (cast(IntegerToken)token).intValue *= (cast(IntegerToken)multiplicand.token).intValue;
        }
    }

    void divide (Value divisor) {
        if (token.type != TokenType.integer && token.type != TokenType.floating) {
            throw new UnsupportedOperationException(token, "Division");
        } else if (divisor.token.type != TokenType.integer && divisor.token.type != TokenType.floating) {
            throw new UnsupportedOperationException(divisor.token, "Division");
        }

        if (token.type == TokenType.floating) {
            (cast(FloatToken)token).floatValue /= divisor.token.type == TokenType.integer ? (cast(IntegerToken)divisor.token).intValue : (cast(FloatToken)divisor.token).floatValue;
        } else if (divisor.token.type == TokenType.floating) {
            token = new FloatToken((cast(IntegerToken)token).intValue / (cast(FloatToken)divisor.token).floatValue);
        } else {
            (cast(IntegerToken)token).intValue /= (cast(IntegerToken)divisor.token).intValue;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////


abstract class Token {
    TokenType type;

    /**
     * Returns a copy of itself.
     */
    Token copy ();

    /**
     * @return true if this is a lexical token, false otherwise. 
     */
    bool isLexicalToken () { return false; }

    Value append (Value element) { throw new UnsupportedOperationException(this, "Append"); }

    Value getItem (int index) { throw new UnsupportedOperationException(this, "Subscript"); }

    /**
     * Constructs a reference token encapsulating a new Node object.
     * @param car the CAR of the new node
     * @param cdr the CDR of the new node
     * @return a reference token
     */
    static Value makeReference (Value car, Value cdr = null) {
        return new Value(new ReferenceToken(new Node(car, cdr)));
    }

    /**
     * @param value a Token object to test.
     * @return true if the Token object is a BooleanToken representing the value NIL.
     */
    static bool isNil (Value value) {
        return value.token.type == TokenType.boolean && (cast(BooleanToken)value.token).boolValue == false;
    }
}


///////////////////////////////////////////////////////////////////////////////

class LexicalToken : Token {
    this (TokenType type) {
        this.type = type;
    }

    override bool isLexicalToken () { return true; }

    override Token copy () {
        return this;
    }

    override string toString () {
        static enum string[TokenType] lexicalTokens =
            [ TokenType.leftParen : "(",
              TokenType.rightParen : ")",
              TokenType.leftBrack : "[",
              TokenType.rightBrack : "]",
              TokenType.dot : "." ];

        return lexicalTokens[type];
    }
}


///////////////////////////////////////////////////////////////////////////////

class BooleanToken : Token {
    bool boolValue;

    this (bool boolValue) {
        type = TokenType.boolean;
        this.boolValue = boolValue;
    }

    override Token copy () {
        return new BooleanToken(boolValue);
    }

    override string toString () {
        return boolValue ? "T" : "NIL";
    }
}


///////////////////////////////////////////////////////////////////////////////

class StringToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.string;
        this.stringValue = stringValue;
    }

    override Token copy () {
        return new StringToken(stringValue);
    }

    override string toString () {
        return "\"" ~ stringValue ~ "\"";
    }
}


///////////////////////////////////////////////////////////////////////////////

class IdentifierToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.identifier;
        this.stringValue = toUpper(stringValue);
    }

    override Token copy () {
        return new IdentifierToken(stringValue);
    }

    override string toString () {
        return stringValue;
    }
}


///////////////////////////////////////////////////////////////////////////////

class IntegerToken : Token {
    long intValue;

    this (long intValue) {
        type = TokenType.integer;
        this.intValue = intValue;
    }

    override Token copy () {
        return new IntegerToken(intValue);
    }

    override string toString () {
        return to!string(intValue);
    }
}


///////////////////////////////////////////////////////////////////////////////

class ConstantToken : Token {
    string stringValue;

    this (string stringValue) {
        type = TokenType.constant;
        this.stringValue = toUpper(stringValue);
    }

    override Token copy () {
        return new ConstantToken(stringValue);
    }

    override string toString () {
        return ":" ~ stringValue;
    }
}


///////////////////////////////////////////////////////////////////////////////

class FloatToken : Token {
    double floatValue;

    this (double floatValue) {
        type = TokenType.floating;
        this.floatValue = floatValue;
    }

    override Token copy () {
        return new FloatToken(floatValue);
    }

    override string toString () {
        return to!string(floatValue);
    }
}


///////////////////////////////////////////////////////////////////////////////

class ReferenceToken : Token {
    Node reference;

    this (Node reference) {
        type = TokenType.reference;
        this.reference = reference;
    }

    /**
     * Appends an element to a list
     *
     * @return a ReferenceToken containing the newly apended element in its CAR
     */
    override Value append (Value element) {
        Node last = reference;

        while (!Token.isNil(last.cdr)) {
            last = (cast(ReferenceToken)last.cdr.token).reference;
        }

        last.cdr = Token.makeReference(element);
        return last.cdr;
    }

    override Value getItem (int index) {
        if (index < 0) {
            throw new OutOfBoundsException(index);
        }
        return lispObject.getItem(new Value(this), index);
    }

    override Token copy () {
        return new ReferenceToken(new Node(reference.car.copy(), reference.cdr.copy()));
    }

    override string toString () {
        return reference.toString();
    }
}


///////////////////////////////////////////////////////////////////////////////

class FileStreamToken : Token {
    string direction;
    string fileSpec;
    File stream;
    bool isOpen;

    this (string fileSpec, Value direction) {
        static enum char[][string] openModes = [ "input" : cast(char[])"r", "output" : cast(char[])"w", "io" : cast(char[])"rw" ];

        type = TokenType.fileStream;
        this.direction = direction is null ? "input" : (cast(ConstantToken)direction.token).stringValue;
        stream = File(fileSpec, openModes[this.direction]);
        this.fileSpec = fileSpec;
        isOpen = true;
    }

    bool close () {
        bool wasOpen = isOpen;
        stream.close();
        return wasOpen;
    }

    // what does it mean to copy a file stream...?
    override Token copy () {
        return this;
    }

    override string toString () {
        return "#<" ~ direction ~ " file stream \"" ~ fileSpec ~ (isOpen ? "" : " (closed)") ~ "\">";
    }
}


///////////////////////////////////////////////////////////////////////////////

class VectorToken : Token {
    Value[] array;

    this (int length) {
        type = TokenType.vector;
        array = new Value[length];
        for (int i = 0; i < length; i++) {
            array[i] = new Value(new BooleanToken(false));
        }
    }

    void setItem (int index, Value element) {
        if (index < 0 || index >= array.length) {
            throw new OutOfBoundsException(index);
        }
        array[index] = element;
    }
    
    override Value getItem (int index) {
        if (index < 0 || index >= array.length) {
            throw new OutOfBoundsException(index);
        }
        return array[index];
    }

    override Token copy () {
        VectorToken vectorCopy = new VectorToken(0);
        vectorCopy.array = array[];
        return vectorCopy;
    }

    override string toString () {
        return "#<" ~ join(map!(x => x.toString())(array), " ") ~ ">";
    }
}


///////////////////////////////////////////////////////////////////////////////

abstract class FunctionToken : Token {
    Value evaluate (Value[] args, Value[string] kwargs = null);
}


///////////////////////////////////////////////////////////////////////////////

class BuiltinFunctionToken : FunctionToken {
    string name;

    this (string name) {
        this.type = TokenType.builtinFunction;
        this.name = name;
    }

    override Value evaluate (Value[] args, Value[string] kwargs = null) {
        return evaluateBuiltinFunction(name, args, kwargs);
    }

    override Token copy () {
        return new BuiltinFunctionToken(name);
    }

    override string toString () {
        return "#<BUILTIN-FUNCTION " ~ name ~ ">";
    }
}


///////////////////////////////////////////////////////////////////////////////

class DefinedFunctionToken : FunctionToken {
    string name;
    LispFunction fun;

    // Constructor for a lambda function
    this (Value[] lambdaList, Value[] forms) {
        this.type = TokenType.definedFunction;
        this.name = null;
        this.fun = processFunctionDefinition(lambdaList, forms);
    }

    this (string name) {
        this.type = TokenType.definedFunction;
        this.name = name;
    }

    override Value evaluate (Value[] args, Value[string] kwargs = null) {
        if (name is null) {
            // evaluate a lambda function
            return evaluateDefinedFunction(fun, args, name);
        } else {
            // evaluate a named defined function
            return evaluateFunction(name, args);
        }
    }

    override Token copy () {
        DefinedFunctionToken functionCopy = new DefinedFunctionToken(name);
        functionCopy.fun = fun;
        return functionCopy;
    }

    override string toString () {
        return "#<FUNCTION " ~
               (name is null ? ":LAMBDA " : "") ~
               "(" ~ join(map!(x => x.toString())(fun.lambdaList), " ") ~ ") " ~
               join(map!(x => x.toString())(fun.forms), " ") ~
               ">";
    }
}


///////////////////////////////////////////////////////////////////////////////

ReferenceToken toReference (Token token) {
    return (cast(ReferenceToken)token);
}


///////////////////////////////////////////////////////////////////////////////

IntegerToken toInteger (Token token) {
    return (cast(IntegerToken)token);
}


///////////////////////////////////////////////////////////////////////////////

FloatToken toFloat (Token token) {
    return (cast(FloatToken)token);
}


///////////////////////////////////////////////////////////////////////////////

IdentifierToken toIdentifier (Token token) {
    return (cast(IdentifierToken)token);
}
