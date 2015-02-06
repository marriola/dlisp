module node;

import token;

import std.conv;

class Node {
    Token car;
    Token cdr;

    /**
     * @param car the CAR of the new Node.
     * @param cdr the CDR of the new Node.
     * @return a Node object initialized with the given CAR and CDR. If null is passed for either argument, that part of the Node is initalized to the BooleanToken NIL.
     */
    this (Token car = null, Token cdr = null) {
        this.car = car is null ? new BooleanToken(false) : car;
        this.cdr = cdr is null ? new BooleanToken(false) : cdr;
    }

    /**
     * @param value a Token object to test.
     * @return true if the Token object is a BooleanToken representing the value NIL.
     */
    static bool isNil (Token value) {
        return value.type == TokenType.boolean && (cast(BooleanToken)value).boolValue == false;
    }

    /**
     * @param root the root of a list.
     * @return the string representation of the list.
     */
    private static string listToString (Node root) {
        Node node = root;
        string builder = "(";

        while (true) {
            // Add the string representation of the value in the CAR to the builder.
            builder ~= node.car.toString();

            // If the CDR is NIL, this is the last element of the list.
            if (isNil(node.cdr)) {
                break;

            } else {
                builder ~= " ";
                node = (cast(ReferenceToken)node.cdr).reference;
            }
        }

        return builder ~ ")";
    }

    /**
     * @return the string representation of this Node.
     */
    override string toString () {
        string builder;

        // If the CDR is a reference-type value or NIL, this is a list.
        if (cdr.type == TokenType.reference || isNil(cdr)) {
            return listToString(this);
            
        } else {
            return "(" ~ car.toString() ~ " . " ~ cdr.toString() ~ ")";
        }

        return builder;
    }

}