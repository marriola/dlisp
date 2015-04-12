module builtin.io;

import std.stdio;

import evaluator;
import exceptions;
import functions;
import lispObject;
import parser;
import token;


///////////////////////////////////////////////////////////////////////////////

Value builtinPrint (string name, Value[] args, Value[string] kwargs) {
    Value lastResult;

    for (int i = 0; i < args.length; i++) {
        lastResult = evaluate(args[i]);
        std.stdio.writeln(lastResult);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLoad (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value sourceFileToken = evaluate(args[0]);
    string sourceFile;
    if (sourceFileToken.token.type == TokenType.constant) {
        sourceFile = (cast(ConstantToken)sourceFileToken.token).stringValue;
    } else if (sourceFileToken.token.type == TokenType.string) {
        sourceFile = (cast(StringToken)sourceFileToken.token).stringValue;
    } else {
        throw new TypeMismatchException(name, sourceFileToken.token, "string or constant");
    }

    File source = File(sourceFile, "r");
    LispParser parser = new LispParser(source);

    while (true) {
        try {
            Value form = parser.read();
            evaluateOnce(form);
        } catch (EndOfFile eof) {
            source.close();
            return new Value(new BooleanToken(true));
        }
    }
}


///////////////////////////////////////////////////////////////////////////////

Value builtinOpen (string name, Value[] args, Value[string] kwargs) {
    if (args.length < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Value fileSpecToken = evaluateOnce(args[0]);
    string fileSpec;
    if (fileSpecToken.token.type == TokenType.string) {
        fileSpec = (cast(StringToken)fileSpecToken.token).stringValue;
    } else if (fileSpecToken.token.type == TokenType.constant) {
        fileSpec = (cast(ConstantToken)fileSpecToken.token).stringValue;
    } else {
        throw new TypeMismatchException(name, fileSpecToken.token, "string or constant");
    }

    Value direction = null;
    if (args.length >= 2) {
        direction = evaluateOnce(args[1]);
        if (direction.token.type != TokenType.constant) {
            throw new TypeMismatchException(name, direction.token, "constant");
        }
    }

    return new Value(new FileStreamToken(fileSpec, direction));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinClose (string name, Value[] args, Value[string] kwargs) {
    if (args.length == 0) {
        throw new NotEnoughArgumentsException(name);
    }

    Value streamToken = evaluate(args[0]);
    if (streamToken.token.type != TokenType.fileStream) {
        throw new TypeMismatchException(name, streamToken.token, "file stream");
    }

    return new Value(new BooleanToken((cast(FileStreamToken)streamToken.token).close()));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRead (string name, Value[] args, Value[string] kwargs) {
    LispParser parser;

    if (args.length > 0) {
        Value streamToken = evaluate(args[0]);
        if (streamToken.token.type != TokenType.fileStream) {
            throw new TypeMismatchException(name, streamToken.token, "file stream");
        } else if (!(cast(FileStreamToken)streamToken.token).isOpen) {
            throw new BuiltinException(name, "Attempt to read from " ~ streamToken.toString());
        }

        parser = new LispParser((cast(FileStreamToken)streamToken.token).stream);
    } else {
        parser = new LispParser(stdin);
    }

    return parser.read();
}


///////////////////////////////////////////////////////////////////////////////

BuiltinFunction[string] addBuiltins (BuiltinFunction[string] builtinTable) {
    builtinTable["LOAD"] = &builtinLoad;
    builtinTable["OPEN"] = &builtinOpen;
    builtinTable["CLOSE"] = &builtinClose;
    builtinTable["READ"] = &builtinRead;
    builtinTable["PRINT"] = &builtinPrint;
    return builtinTable;
}