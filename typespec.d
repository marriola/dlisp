module typespec;

import std.ascii;
import std.conv;
import std.file;
import std.regex;
import std.string;

import exceptions;
import token;


class Typespec {
    TokenType type;
    Value value;

    this() {
    }

    this(TokenType type) {
	this.type = type;
	this.value = null;
    }

    this(Value value) {
	this.type = value.token.type;
	this.value = value;
    }

    public override string toString() {
	string builder = "";

	if (this.value is null) {
	    return tokenTypeName(this.type);
	} else {
	    return tokenTypeName(this.type) ~ " : " ~ this.value.toString();
	}
    }
}

class CompositeSpec : Typespec {
    Typespec[] typespecs;
}

class UnionSpec : CompositeSpec {
    public override string toString() {
	return join(map!(x => tokenTypeName(x.type))(this.typespecs), ",");
    }
}

class DefiniteSpec : CompositeSpec {
    string collection;
    int size;

    this(string collection) {
	this.collection = collection;
	size = 0;
    }

    this(string collection, int size) {
	this.collection = collection;
	this.size = size;
    }

    public override string toString() {
	string builder = this.collection ~ "[" ~ std.conv.to!(string)(this.size) ~ "]<";
 	int x = this.typespecs.length;
	foreach (Typespec spec; this.typespecs) {
	    builder ~= spec.toString();
	    if (--x != 0) {
		builder ~= ";";
	    }
	}
	builder ~= ">";
	return builder;
    }
}

class IndefiniteSpec : CompositeSpec {
    string collection;

    this(string collection) {
	this.collection = collection;
    }

    public override string toString() {
	string builder = this.collection ~ "<";
 	int x = this.typespecs.length;
	foreach (Typespec spec; this.typespecs) {
	    builder ~= spec.toString();
	    if (--x != 0) {
		builder ~= ";";
	    }
	}
	builder ~= ">";
	return builder;
    }
}


///////////////////////////////////////////////////////////////////////////////

class TypespecParser {
    string typespec;
    int pos;
    int level;
    bool logging;

    void log (string str) {
	if (!logging) return;

	for (int i = 0; i < level - 1; i++) {
	    std.stdio.write("| ");
	}
	std.stdio.writeln("+-" ~ str);
    }

    this (string typespec) {
	this.typespec = typespec;
	this.pos = 0;
	this.level = 0;
	this.logging = false;
    }

    int current() {
	if (pos >= typespec.length) {
	    return -1;
	}

	return typespec[pos];
    }

    void match(char c) {
	if (current() == -1 || current() != c) {
	    throw new Exception("Expected '" ~ to!char(c) ~ "', got '" ~ to!char(current()) ~ "' at " ~ to!string(pos) ~ " in typespec '" ~ typespec ~ "'");
	}
	pos++;
    }

    string matchIdentifier() {
	string identifier = "";
	int c = current();

	if (c == -1 || indexOf(",;[]<>", cast(char)c) != -1) {
	    throw new Exception("Expected identifier at " ~ to!string(pos) ~ " in typespec '" ~ typespec ~ "'");
	}

	while (c != -1 && indexOf(",;[]<>", cast(char)c) == -1) {
	    identifier ~= cast(char)c;
	    pos++;
	    c = current();
	}

	return identifier;
    }

    int matchInteger() {
	if (current() == -1 || !isDigit(cast(char)current())) {
	    throw new Exception("Expected digit at " ~ to!string(pos) ~ " in typespec '" ~ typespec ~ "'");
	}

	string str = "";

	while (current() != -1 && isDigit(cast(char)current())) {
	    str ~= cast(char)current();
	    pos++;
	}

	return to!int(str);
    }

    Typespec[] matchTypespecList() {
	log("typespec list");
	level++;
	Typespec[] typespecs;

	while (true) {
	    Typespec t = parse();
	    log(t.toString());
	    typespecs ~= t;

	    if (current() == ';') {
		match(';');
	    } else {
		break;
	    }
	}

	level--;
	return typespecs;
    }

    DefiniteSpec matchDefiniteList(string type) {
	log("definite list");
	match('[');
	int size = matchInteger();
	match(']');

	DefiniteSpec typespec = new DefiniteSpec(type, size);
	match('<');
	typespec.typespecs = matchTypespecList();
	match('>');
	return typespec;
    }

    IndefiniteSpec matchIndefiniteList(string type) {
	log("indefinite list");
	IndefiniteSpec typespec = new IndefiniteSpec(type);
	match('<');
	typespec.typespecs = matchTypespecList();
	match('>');
	return typespec;
    }

    CompositeSpec matchList(string type) {
	if (current() == '[') {
	    return matchDefiniteList(type);
	} else if (current() == '<') {
	    return matchIndefiniteList(type);
	} else {
	    return null;
	}
    }

    UnionSpec matchUnionSpec(Typespec firstSpec) {
	UnionSpec spec = new UnionSpec();
	spec.typespecs ~= firstSpec;
	log("union spec");

	while (true) {
	    Typespec t = parse(true);
	    spec.typespecs ~= t;
	    log("OR " ~ t.toString());
	    if (current() == ',') {
		match(',');
	    } else {
		break;
	    }
	}

	return spec;
    }

    Typespec parse(bool ignoreCommas = false) {
	level++;

	string type = matchIdentifier();
	Typespec spec = null;
	log("identifier " ~ type);

	if (current() == '[' || current() == '<') {
	    spec = matchList(type);
	} else if (isValidTypeName(type)) {
	    TokenType tokenType = tokenTypeValue(type);
	    spec = new Typespec(tokenType);
	    if (current() == ',' && !ignoreCommas) {
		match(',');
		spec = matchUnionSpec(spec);
		//std.stdio.writeln("matched union " ~ spec.toString());
	    }
	} else {
	    throw new Exception(std.conv.to!string(this.pos) ~ ": unexpected token type '" ~ type ~ "'");
	}

	level--;
	return spec;
    }
}
