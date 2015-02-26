module builtin.io;

import std.stdio;

import evaluator;
import functions;
import lispObject;
import parser;
import token;


///////////////////////////////////////////////////////////////////////////////

Token builtinPrint (string name, ReferenceToken args) {
    Token lastResult;

    while (hasMore(args)) {
        lastResult = evaluate(getFirst(args));
        std.stdio.writeln(lastResult);
        args = getRest(args);
    }

    return lastResult;
}


///////////////////////////////////////////////////////////////////////////////

Token builtinLoad (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token sourceFileToken = getFirst(args);
    string sourceFile;
    if (sourceFileToken.type == TokenType.constant) {
        sourceFile = (cast(ConstantToken)sourceFileToken).stringValue;
    } else if (sourceFileToken.type == TokenType.string) {
        sourceFile = (cast(StringToken)sourceFileToken).stringValue;
    } else {
        throw new TypeMismatchException(name, args, "string or constant");
    }

    File source = File(sourceFile, "r");
    LispParser parser = new LispParser(source);

    while (true) {
        try {
            Token form = parser.read();
            evaluateOnce(form);
        } catch (EndOfFile eof) {
            source.close();
            return new BooleanToken(true);
        }
    }
}


///////////////////////////////////////////////////////////////////////////////

Token builtinOpen (string name, ReferenceToken args) {
    if (listLength(args) < 1) {
        throw new NotEnoughArgumentsException(name);
    }

    Token fileSpecToken = evaluate(getItem(args, 0));
    string fileSpec;
    if (fileSpecToken.type == TokenType.string) {
        fileSpec = (cast(StringToken)fileSpecToken).stringValue;
    } else if (fileSpecToken.type == TokenType.constant) {
        fileSpec = (cast(ConstantToken)fileSpecToken).stringValue;
    } else {
        throw new TypeMismatchException(name, fileSpecToken, "string or constant");
    }

    Token direction = null;
    if (listLength(args) >= 2) {
        direction = evaluate(getItem(args, 1));
        if (direction.type != TokenType.constant) {
            throw new TypeMismatchException(name, direction, "constant");
        }
    }

    return new FileStreamToken(fileSpec, cast(ConstantToken)direction);
}


///////////////////////////////////////////////////////////////////////////////

Token builtinClose (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token streamToken = evaluate(getFirst(args));
    if (streamToken.type != TokenType.fileStream) {
        throw new TypeMismatchException(name, streamToken, "file stream");
    }

    return new BooleanToken((cast(FileStreamToken)streamToken).close());
}


///////////////////////////////////////////////////////////////////////////////

Token builtinRead (string name, ReferenceToken args) {
    if (!hasMore(args)) {
        throw new NotEnoughArgumentsException(name);
    }

    Token streamToken = evaluate(getFirst(args));
    if (streamToken.type != TokenType.fileStream) {
        throw new TypeMismatchException(name, streamToken, "file stream");
    } else if (!(cast(FileStreamToken)streamToken).isOpen) {
        throw new BuiltinException(name, "Attempt to read from " ~ streamToken.toString());
    }

    LispParser parser = new LispParser((cast(FileStreamToken)streamToken).stream);
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