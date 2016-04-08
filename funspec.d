module funspec;

import std.regex;
import std.file;
import std.string;
import std.typecons;
import std.xml;

import exceptions;
import token;
import typespec;

///////////////////////////////////////////////////////////////////////////////

struct Module {
    string name;
    string file;
    Funspec[] functions;

    this (string name, string file) {
	this.name = name;
	this.file = file;
	functions = new Funspec[0];
	//std.stdio.writeln("Module " ~ name);
    }
};

struct Funspec {
    string id;
    Parameter[] required;
    Parameter[] optional;
    Parameter[] keyword;
    Parameter[] auxiliary;
    Nullable!Parameter rest;

    this (string id, Parameter[] required = null, Parameter[] optional = null, Parameter[] keyword = null, Parameter[] auxiliary = null) {
	this.id = id;
	this.required = required;
	this.optional = optional;
	this.keyword = keyword;
	this.auxiliary = auxiliary;
	//std.stdio.writeln("  Function '" ~ id ~ "'");
    }
};

struct Parameter {
    string id;
    Typespec typespec;
    string defaultValue;

    this (string id, Typespec typespec, string defaultValue) {
	this.id = id;
	this.typespec = typespec;
	this.defaultValue = defaultValue;
	//std.stdio.writeln("    Parameter '" ~ id ~ "', typespec '" ~ typespec.toString() ~ "', default '" ~ defaultValue ~ "'");
    }
};


///////////////////////////////////////////////////////////////////////////////


string attr(Tag tag, string name) {
    return name in tag.attr ? tag.attr[name] : "";
}

Module[] readFunspecFile(string file) {
    string content = cast(string)std.file.read(file);
    try {
     	//check(content);
    } catch (CheckException ex) {
	std.stdio.writeln("*** invalid XML");
	std.stdio.writeln(ex.toString());
	throw ex;
    }
    
    Module[] modules = new Module[0];
    auto doc = new Document(content);

    foreach (Element element; doc.elements) {
	if (element.tag.name != "module") {
	    throw new Exception("Invalid tag " ~ element.tag.name);
	}

	auto newModule = Module(attr(element.tag, "name"), attr(element.tag, "file"));
	modules ~= newModule;
	readFunctions(element.elements, newModule.functions);
    }

    return modules;
}

void readFunctions(Element[] elements, ref Funspec[] functions) {
    foreach (Element element; elements) {
	if (element.tag.name != "fun") {
	    throw new Exception("Invalid tag " ~ element.tag.name);
	}

	string idstr = attr(element.tag, "id");
	string[] ids;
	if (indexOf(idstr, ",") != -1) {
	    ids = split(idstr, ",");
	} else {
	    ids = new string[1];
	    ids[0] = idstr;
	}

	try {
	    foreach (string id; ids) {
		auto newFunspec = Funspec(id);

		foreach (Element param; element.elements) {
		    switch (param.tag.name) {
		    case "required":
			readParameters(param.elements, newFunspec.required);
			break;

		    case "optional":
			readParameters(param.elements, newFunspec.optional);
			break;

		    case "keyword":
			readParameters(param.elements, newFunspec.keyword);
			break;

		    case "auxiliary":
			readParameters(param.elements, newFunspec.auxiliary);
			break;

		    case "rest":
			Typespec restType = null;
			if (attr(param.tag, "type").length > 0) {
			    restType = new TypespecParser(attr(param.tag, "type")).parse();
			}
			auto restParameter = Parameter(attr(param.tag, "id"), restType, attr(param.tag, "default"));
			newFunspec.rest = restParameter;
			break;

		    default:
			throw new Exception("Invalid tag " ~ param.tag.name);
		    }
		}

		functions ~= newFunspec;
	    }
	} catch (Exception ex) {
	    std.stdio.writeln("Element '" ~ idstr ~ "' exception: ");
	    std.stdio.writeln(ex.toString());
	}
    }
}

void readParameters(Element[] elements, ref Parameter[] parameters) {
    foreach (Element param; elements) {
	Typespec paramType = null;
	if (attr(param.tag, "type").length > 0) {
	    paramType = new TypespecParser(attr(param.tag, "type")).parse();
	}
	parameters ~= Parameter(attr(param.tag, "id"), paramType, attr(param.tag, "default"));
    }
}

Nullable!Funspec findFunspec(Module[] modules, string name) {
    Nullable!Funspec outspec;

    foreach (Module mod; modules) {
	foreach (Funspec spec; mod.functions) {
	    if (spec.id == name) {
		outspec = spec;
		return outspec;
	    }
	}
    }

    return outspec;
}

void validateArguments(Module[] modules, string name, Value[] arguments) {
    auto funspec = findFunspec(modules, name);
    if (funspec.isNull) {
	throw new Exception("No funspec found for " ~ name);
    }

    foreach (Value arg; arguments) {
    }
}

unittest {
    Typespec spec;

    spec = new TypespecParser("reference").parse();
    // std.stdio.writeln("*** reference");
    // std.stdio.writeln("*** " ~ spec.toString());
    assert(spec.toString() == "reference");

    spec = new TypespecParser("list<integer,float;list<char,string>>").parse();
    // std.stdio.writeln("*** list<integer,float;list<char,string>>");
    // std.stdio.writeln("*** " ~ spec.toString());
    assert(spec.toString() == "list<integer,float;list<char,string>>");

    spec = new TypespecParser("list<list<identifier;*>>").parse();
    // std.stdio.writeln("*** list<list<identifier;*>>");
    // std.stdio.writeln("*** " ~ spec.toString());
    assert(spec.toString() == "list<list<identifier;*>>");
}
