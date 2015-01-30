import std.stdio;

import token;
import parser;

///////////////////////////////////////////////////////////////////////////////

void main () {
    LispParser parser = new LispParser();
    writef("You said: %s", parser.parse().toString());
}