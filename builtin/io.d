module builtin.io;

import std.stdio;

import evaluator;
import exceptions;
import functions;
import lispObject;
import parser;
import token;
import variables;


///////////////////////////////////////////////////////////////////////////////

Value builtinPrint (string name) {
    Value result = evaluateOnce(getParameter("OBJECT"));
    std.stdio.writeln(result);
    return result;
}


///////////////////////////////////////////////////////////////////////////////

Value builtinLoad (string name) {
    Value sourceFileToken = evaluate(getParameter("FILESPEC"));
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

Value builtinOpen (string name) {
    Value fileSpecToken = evaluateOnce(getParameter("FILESPEC"));
    string fileSpec;
    if (fileSpecToken.token.type == TokenType.string) {
        fileSpec = (cast(StringToken)fileSpecToken.token).stringValue;
    } else if (fileSpecToken.token.type == TokenType.constant) {
        fileSpec = (cast(ConstantToken)fileSpecToken.token).stringValue;
    } else {
        throw new TypeMismatchException(name, fileSpecToken.token, "string or constant");
    }

    Value direction = evaluateOnce(getParameter("DIRECTION"));
    if (direction.token.type != TokenType.constant) {
        throw new TypeMismatchException(name, direction.token, "constant");
    }

    return new Value(new FileStreamToken(fileSpec, direction));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinClose (string name) {
    Value streamToken = evaluate(getParameter("STREAM"));
    if (streamToken.token.type != TokenType.fileStream) {
        throw new TypeMismatchException(name, streamToken.token, "file stream");
    }

    return new Value(new BooleanToken((cast(FileStreamToken)streamToken.token).close()));
}


///////////////////////////////////////////////////////////////////////////////

Value builtinRead (string name) {
    LispParser parser;
    Value stream = getParameter("STREAM");

    if (stream.isNil()) {
        Value streamToken = evaluate(stream);
        if (streamToken.token.type != TokenType.fileStream) {
            throw new TypeMismatchException(name, streamToken.token, "file stream");
        } else if (!(cast(FileStreamToken)streamToken.token).isOpen) {
            throw new BuiltinException(name, "Attempt to read from " ~ streamToken.toString());
        }

        parser = (cast(FileStreamToken)streamToken.token).getParser();
    } else {
        parser = new LispParser(stdin);
    }

    return parser.read();
}


///////////////////////////////////////////////////////////////////////////////

string format (string formatString, Value[] args) {
    string outString = "";

    for (int i = 0; i < formatString.length; i++) {
        if (formatString[i] == '~') {
            // encountering format directive
            i++;

            // process repeat parameter
            string repeatStr = "";
            while (std.ascii.isDigit(formatString[i])) {
                repeatStr ~= formatString[i++];
            }
            int repeatLength = (repeatStr.length > 0) ? std.conv.to!int(repeatStr) : 1;

            // process directive
            string directiveOut;
            switch (formatString[i]) {
                case '~':
                    directiveOut = "~";
                    break;

                case '%':
                    directiveOut = "\n";
                    break;

                // strings and numbers can all just be converted to strings and added to the output string
                case 'A':
                case 'D':
                    Value param = evaluateOnce(args[0]);
                    directiveOut = param.toString();
                    args = args[1 .. args.length];
                    break;

                case 'C':
                    Value param = evaluateOnce(args[0]);
                    if (param.token.type != TokenType.character) {
                        throw new TypeMismatchException("format", param.token, "character");
                    }
                    directiveOut = "" ~ (cast(CharacterToken)param.token).charValue;
                    args = args[1 .. args.length];
                    break;

                default:
                    throw new Exception("Invalid format directive character '" ~ formatString[i] ~ "'");
            }

            // append directive to output string
            for (int j = 0; j < repeatLength; j++) {
                outString ~= directiveOut;
            }

        } else {
            // append everything else to output string
            outString ~= formatString[i];
        }
    }

    return outString;
}

Value builtinFormat (string name) {
    Value destination = evaluateOnce(getParameter("DESTINATION"));
    Value formatString = evaluateOnce(getParameter("FORMAT-STRING"));
    Value[] args = toArray(getParameter("ARGS"));

    if (formatString.token.type != TokenType.string) {
        throw new TypeMismatchException(name, formatString.token, "string");
    }

    string output = format((cast(StringToken)formatString.token).stringValue, args);

    if (destination.isNil()) {
        return new Value(new StringToken(output));

    } else if (destination.token.type == TokenType.fileStream) {
        (cast(FileStreamToken)destination.token).stream.write(output);

    } else {
        std.stdio.write(output);
    }

    return Value.nil();
}


///////////////////////////////////////////////////////////////////////////////

void addBuiltins () {
    addFunction("LOAD", &builtinLoad, Parameters(["FILESPEC"]));
    addFunction("OPEN", &builtinOpen, Parameters(["FILESPEC"], [PairedArgument("DIRECTION", new Value(new ConstantToken("INPUT")))]));
    addFunction("CLOSE", &builtinClose, Parameters(["STREAM"]));
    addFunction("READ", &builtinRead, Parameters(null, [PairedArgument("STREAM", Value.nil())]));
    addFunction("PRINT", &builtinPrint, Parameters(["OBJECT"]));
    addFunction("FORMAT", &builtinFormat, Parameters(["DESTINATION", "FORMAT-STRING"], null, null, null, "ARGS"));
}