import std.stdio;

import token;
import parser;

///////////////////////////////////////////////////////////////////////////////

void main () {
    LispParser parser = new LispParser();
    parser.parse();
    writef("You said: %s", parser.nextToken.toString());
}