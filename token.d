module token;

import exceptions;
import functions;
import lispObject;
import node;
import util;
import vm.compiler;

import std.container.array;
import std.algorithm;
import std.stdio;
import std.conv;
import std.string;
import std.format;

///////////////////////////////////////////////////////////////////////////////

enum TokenType { leftParen, rightParen, leftBrack, rightBrack, dot, boolean, reference, integer, floating, identifier, character, string, constant, fileStream, vector, builtinFunction, compiledFunction };


///////////////////////////////////////////////////////////////////////////////


string tokenTypeName (TokenType type) {
    static string typeNames[] = [ "left paren", "right paren", "left bracket", "right bracket", "dot", "boolean", "reference", "integer", "floating point", "identifier", "character", "string", "constant", "file stream", "vector", "builtin function", "compiled function" ];
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
     * Constructs a Value containing a new NIL token.
     */
    static Value nil () {
        return new Value(new BooleanToken(false));
    }

    /**
     * @param value a Token object to test.
     * @return true if the Token object is a BooleanToken representing the value NIL.
     */
    bool isNil () {
        return token.type == TokenType.boolean && (cast(BooleanToken)token).boolValue == false;
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
     *
     * @param element   Element to add to the list
     * @return          The last element added to the list
     */
    Value append (Value element) {
        if (token.type == TokenType.boolean && (cast(BooleanToken)token).boolValue == false) {
            token = element.token;
	    if (element.token.type == TokenType.reference)
		return getLast(element);
	    else
		return element;

        } else if (token.type == TokenType.reference) {
            return (cast(ReferenceToken)token).append(element);

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

	if (divisor.token.type == TokenType.floating && (cast(FloatToken)divisor.token).floatValue == 0 ||
	    divisor.token.type == TokenType.integer && (cast(IntegerToken)divisor.token).intValue == 0) {
	    throw new Exception("Division by zero");
	}

        if (token.type == TokenType.floating) {
            // floating point dividend
            (cast(FloatToken)token).floatValue /= divisor.token.type == TokenType.integer ? (cast(IntegerToken)divisor.token).intValue : (cast(FloatToken)divisor.token).floatValue;
        } else if (divisor.token.type == TokenType.floating) {
            // floating point divisor
            token = new FloatToken((cast(IntegerToken)token).intValue / (cast(FloatToken)divisor.token).floatValue);
        } else if ((cast(IntegerToken)token).intValue % (cast(IntegerToken)divisor.token).intValue == 0) {
            // integer operands and integer result
            (cast(IntegerToken)token).intValue /= (cast(IntegerToken)divisor.token).intValue;
        } else {
            // integer operands and floating point result
            token = new FloatToken(cast(double)(cast(IntegerToken)token).intValue / (cast(IntegerToken)divisor.token).intValue);
        }
    }

    void accept (LispVisitor visitor) {
        visitor.visit(this, this.token);
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
     * @return true if the Token object is a BooleanToken representing the value T.
     */
    static bool isTrue (Value value) {
        return value.token.type == TokenType.boolean && (cast(BooleanToken)value.token).boolValue == true;
    }

    ubyte[] serialize() {
	throw new UnsupportedOperationException(this, "deserialize");
    }

    static ubyte[] serialize(Token token) {
	ubyte[] tokenBytes;

	switch (token.type) {
	case TokenType.string:
	    tokenBytes = (cast(StringToken)token).serialize();
	    break;

	case TokenType.constant:
	    tokenBytes = (cast(ConstantToken)token).serialize();
	    break;

	case TokenType.boolean:
	    tokenBytes = (cast(IdentifierToken)token).serialize();
	    break;

	case TokenType.integer:
	    tokenBytes = (cast(IntegerToken)token).serialize();
	    break;

	case TokenType.floating:
	    tokenBytes = (cast(FloatToken)token).serialize();
	    break;

	case TokenType.reference:
	    tokenBytes = (cast(ReferenceToken)token).serialize();
	    break;

	default:
	    throw new Exception("Invalid token type");
	}

	auto bytes = new ubyte[0];
	bytes ~= asBytes(token.type, 4);
	bytes ~= asBytes(tokenBytes.length, 4);
	bytes ~= tokenBytes;

	return bytes;
    }

    static Token deserialize (TokenType type, ubyte[] bytes) {
	Token token = null;
	switch (type) {
	case TokenType.string:
	    token = StringToken.deserialize(bytes);
	    break;

	case TokenType.constant:
	    token = ConstantToken.deserialize(bytes);
	    break;

	case TokenType.boolean:
	    token = IdentifierToken.deserialize(bytes);
	    break;

	case TokenType.integer:
	    token = IntegerToken.deserialize(bytes);
	    break;

	case TokenType.floating:
	    token = FloatToken.deserialize(bytes);
	    break;

	default:
	    throw new Exception("Invalid token type");
	}
	return token;
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

    ubyte[] serialize() {
	auto output = new ubyte[0];

	output ~= cast(ubyte)(boolValue ? 1 : 0);
	return output;
    }

    static Token deserialize (ubyte[] data) {
	return new BooleanToken(data[0] == 1);
    }
}


///////////////////////////////////////////////////////////////////////////////

class CharacterToken : Token {
    char charValue;

    this (char charValue) {
        type = TokenType.character;
        this.charValue = charValue;
    }

    override Token copy () {
        return new CharacterToken(charValue);
    }

    override string toString () {
        if (charValue == '\n') {
            return "#\\Newline";
	} else if (charValue == '\r') {
	    return "#\\Return";
	} else if (charValue == '\t') {
	    return "#\\Tab";
	} else if (charValue == 32) {
	    return "#\\Space";
	} else if (charValue == 0) {
	    return "#\\Null";
	} else if (charValue < 32 || charValue >= 127) {
	    return "#\\x" ~ format("%x", charValue); 
        } else {
            return "#\\" ~ charValue;
        }
    }

    ubyte[] serialize() {
	auto output = new ubyte[0];

	output ~= cast(ubyte)charValue;
	return output;
    }

    static Token deserialize (ubyte[] data) {
	return new CharacterToken(cast(char)data[0]);
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

    ubyte[] serialize() {
	auto output = new ubyte[0];

	foreach (char c; stringValue) {
	    output ~= cast(ubyte)c;
	}

	return output;
    }

    static Token deserialize (ubyte[] data) {
	string value = "";
	for (int i = 0; i < data.length; i++) {
	    value ~= cast(char)data[i];
	}
	return new StringToken(value);
    }
}


///////////////////////////////////////////////////////////////////////////////

class IdentifierToken : Token {
    string stringValue;
    bool barred;

    this (string stringValue, bool barred = false) {
        type = TokenType.identifier;
        this.stringValue = barred ? stringValue : toUpper(stringValue);
	this.barred = barred;
    }

    override Token copy () {
        return new IdentifierToken(stringValue);
    }

    override string toString () {
	if (barred)
	    return "|" ~ stringValue ~ "|";
	else
	    return stringValue;
    }

    ubyte[] serialize() {
	auto output = new ubyte[0];


	foreach (char c; stringValue) {
	    output ~= cast(ubyte)c;
	}

	return output;
    }

    static Token deserialize (ubyte[] data) {
	string value = "";
	for (int i = 0; i < data.length; i++) {
	    value ~= cast(char)data[i];
	}
	return new StringToken(value);
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

    ubyte[] serialize() {
	auto output = new ubyte[0];
	insertAll(output, asBytes(intValue, 8));
	return output;
    }

    static Token deserialize (ubyte[] data) {
	return new IntegerToken(fromBytes!long(data));
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

    ubyte[] serialize() {
	auto output = new ubyte[0];


	foreach (char c; stringValue) {
	    output ~= cast(ubyte)c;
	}

	return output;
    }

    static Token deserialize (ubyte[] data) {
	string value = "";
	for (int i = 0; i < data.length; i++) {
	    value ~= cast(char)data[i];
	}
	return new StringToken(value);
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

    ubyte[] serialize() {
	auto output = new ubyte[0];

	insertAll(output, asBytes(floatValue, 8));
	return output;
    }

    static Token deserialize (ubyte[] bytes) {
	return new FloatToken(fromBytes!double(bytes));
    }
}


///////////////////////////////////////////////////////////////////////////////

class ReferenceToken : Token {
    Node reference;

    this (Node reference) {
        type = TokenType.reference;
        this.reference = reference;
    }

    private this () {
	this.reference = new Node();
    }

    /**
     * Appends an element to a list
     *
     * @return a ReferenceToken containing the newly apended element in its CAR
     */
    override Value append (Value element) {
        Node last = reference;

        while (!last.cdr.isNil()) {
            last = (cast(ReferenceToken)last.cdr.token).reference;
        }

        last.cdr = element;
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

    ubyte[] serialize() {
	auto output = new ubyte[0];

	auto carBytes = reference.car.token.serialize();
	output ~= asBytes(reference.car.token.type, 4);
	output ~= asBytes(carBytes.length, 4);
	insertAll(output, carBytes);

	auto cdrBytes = reference.cdr.token.serialize();
	output ~= asBytes(reference.cdr.token.type, 4);
	output ~= asBytes(cdrBytes.length, 4);
	insertAll(output, cdrBytes);

	return output;
    }

    private static Token deserializePart(ref ubyte[] bytes) {
	TokenType type = fromBytes!TokenType(bytes[0..3]);
	bytes = bytes[4..$];
		
	int size = fromBytes!uint(bytes[0..3]);
	bytes = bytes[4..$];

	Token token = Token.deserialize(type, bytes[0 .. size - 1]);
	bytes = bytes[size..$];
	return token;
    }

    static Token deserialize(ubyte[] bytes) {
	auto token = new ReferenceToken();
	token.reference.car = new Value(ReferenceToken.deserializePart(bytes));
	token.reference.cdr = new Value(ReferenceToken.deserializePart(bytes));
	return token;
    }
}


///////////////////////////////////////////////////////////////////////////////

class FileStreamToken : Token {
    import parser;

    string direction;
    string fileSpec;
    File stream;
    bool isOpen;
    LispParser streamParser;

    this (string fileSpec, Value direction) {
        static enum char[][string] openModes = [ "INPUT" : cast(char[])"r", "OUTPUT" : cast(char[])"w", "IO" : cast(char[])"rw" ];

        type = TokenType.fileStream;
        this.direction = (cast(ConstantToken)direction.token).stringValue;
        stream = File(fileSpec, openModes[this.direction]);
        this.fileSpec = fileSpec;
        isOpen = true;
        streamParser = null;
    }

    LispParser getParser () {
        if (streamParser is null) {
            streamParser = new LispParser(stream);
        }

        return streamParser;
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
    int[] dimensions;
    Value[] array;

    /**
     * Copy constructor.
     */
    this (VectorToken vector) {
        this.dimensions = vector.dimensions.dup;
        this.array = vector.array.dup;
    }

    /**
     * Constructor for one-dimensional vector.
     */
    this (int length) {
        type = TokenType.vector;
        dimensions = [1];
        array = new Value[length];
        for (int i = 0; i < length; i++) {
            array[i] = new Value(new BooleanToken(false));
        }
    }

    /**
     * Constructor for multi-dimensional vector.
     */
    this (int[] dimensions) {
        type = TokenType.vector;
        this.dimensions = dimensions;
        int length = reduce!((result, x) => x * result)(1, dimensions);
        array = new Value[length];
        for (int i = 0; i < length; i++) {
            array[i] = new Value(new BooleanToken(false));
        }
    }

    /**
     * Converts an array of indices to a one-dimensional index.
     */
    int flatten (int[] indices) {
        int index = 1;
        for (int i = 0; i < indices.length; i++) {
            if (indices[i] < 0 || indices[i] >= dimensions[i]) {
                throw new OutOfBoundsException(indices);
            } else if (i < indices.length - 1) {
                index *= indices[i];
            } else {
                index += indices[i];
            }
        }
        return index;        
    }

    /**
     * Set item in one-dimensional vector.
     */
    void setItem (int index, Value element) {
        if (index < 0 || index >= array.length) {
            throw new OutOfBoundsException(index);
        } else if (dimensions.length > 1) {
            throw new WrongNumberOfIndicesException(dimensions.length);
        }
        array[index] = element;
    }
    
    /**
     * Set item in multi-dimensional vector.
     */
    void setItem (int[] indices, Value element) {
        if (dimensions.length != indices.length) {
            throw new WrongNumberOfIndicesException(dimensions.length);
        }        
        array[flatten(indices)] = element;
    }
    
    /**
     * Retrieve item from one-dimensional vector.
     */
    override Value getItem (int index) {
        if (index < 0 || index >= array.length) {
            throw new OutOfBoundsException(index);
        } else if (dimensions.length > 1) {
            throw new WrongNumberOfIndicesException(dimensions.length);
        }
        return array[index];
    }

    /**
     * Retrieve item from multi-dimensional vector.
     */
    Value getItem (int[] indices) {
        if (dimensions.length != indices.length) {
            throw new WrongNumberOfIndicesException(dimensions.length);
        }
        return array[flatten(indices)];
    }

    override Token copy () {
        VectorToken vectorCopy = new VectorToken(this);
        return vectorCopy;
    }

    override string toString () {
        return "#<" ~ join(map!(x => x.toString())(array), " ") ~ ">";
    }
}


///////////////////////////////////////////////////////////////////////////////

abstract class FunctionToken : Token {
    int id;
    Value evaluate (Value[] args);
}


///////////////////////////////////////////////////////////////////////////////

class BuiltinFunctionToken : FunctionToken {
    string name;

    this (string name) {
        this.type = TokenType.builtinFunction;
        this.name = name;
    }

    override Value evaluate (Value[] args) {
        return evaluateBuiltinFunction(name, args);
    }

    override Token copy () {
        return new BuiltinFunctionToken(name);
    }

    override string toString () {
        return "#<BUILTIN-FUNCTION " ~ name ~ ">";
    }
}


///////////////////////////////////////////////////////////////////////////////

class CompiledFunctionToken : FunctionToken {
    string name;
    CompiledFunction fun;

    // Constructor for a lambda function
    this (Value[] lambdaList, Value[] forms, string docString = null) {
        this.type = TokenType.compiledFunction;
        this.name = null;
        this.fun = processFunctionDefinition("<lambda>", lambdaList, forms, docString);
    }

    this (string name, CompiledFunction fun) {
        this.type = TokenType.compiledFunction;
        this.name = name;
        this.fun = fun;
    }

    this (string name) {
        this.type = TokenType.compiledFunction;
        this.name = name;
    }

    override Value evaluate (Value[] args) {
        if (name is null) {
            // evaluate a lambda function
            return evaluateCompiledFunction(fun, args, true, name);
        } else {
            // evaluate a named defined function
            return evaluateFunction(name, args);
        }
    }

    override Token copy () {
        CompiledFunctionToken functionCopy = new CompiledFunctionToken(name);
        functionCopy.fun = fun;
        return functionCopy;
    }

    override string toString () {
        return "#<FUNCTION " ~
	    (name is null ? ":LAMBDA " : name ~ " ") ~
	    "(" ~ join(map!(x => x.toString())(fun.lambdaList), " ") ~ ") " ~
	    (fun.docString is null ? "" : "\"" ~ fun.docString ~ "\" ") ~
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
