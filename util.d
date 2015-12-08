module util;

import std.stdio;
import std.typecons;

/// Reads numBytes bytes from file, casts the bytes read as the indicated type and returns the value.
T fromBytes(T)(File file, int numBytes) {
	auto input = new ubyte[numBytes];
	file.rawRead(input);

	T* p = cast(T*)&input;
	return *p;
}

T fromBytes(T)(ubyte[] bytes) {
	T* p = cast(T*)&bytes;
	return *p;
}

ubyte[] asBytes(T)(T value, int len) {
	ubyte* p = cast(ubyte*)&value;
	ubyte[] bytes = new ubyte[len];
	for (int i = 0; i < len; i++) {
		bytes[i] = p[i];
	}
	return bytes;
}

void insertAll(ref ubyte[] dest, ubyte[] src) {
	foreach (ubyte theByte; src) {
		dest ~= theByte;
	}
}

T tokenTo (T) (Token token) {
	string typeInfo[TypeInfo] =
	[
		typeid(IntegerToken): tuple(TokenType.integer, "Integer"),
		typeid(FloatToken): tuple(TokenType.floating, "Float"),
		typeid(StringToken): tuple(TokenType.string, "String"),
		typeid(ConstantToken): tuple(TokenType.constant, "Constant"),
		typeid(IdentifierToken): tuple(TokenType.identifier, "Identifier"),
		typeid(CharacterToken): tuple(TokenType.character, "Character"),
		typeid(FileStreamToken): tuple(TokenType.fileStream, "File stream"),
		typeid(VectorToken): tuple(TokenType.vector, "vector"),
		typeid(BuiltinFunctionToken): tuple(TokenType.builtinFunction, "Builtin function"),
		typeid(CompiledFunctionToken): tuple(TokenType.compiledFunction, "Compiled function")
	];

	auto tokenType = typeid(T);

	foreach (TypeInfo type; typeInfoToName.keys) {
		if (type == tokenType && token.type != typeInfo[type][0]) {
			throw new TypeMismatchException("tokenTo", token, typeInfo[type][1]);
		}
	}
}