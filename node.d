module node;

import exceptions;
import token;

import std.conv;

class Node {
    Value car;
    Value cdr;

    /**
     * @param car the CAR of the new Node.
     * @param cdr the CDR of the new Node.
     * @return a Node object initialized with the given CAR and CDR. If null is passed for either argument, that part of the Node is initalized to the BooleanToken NIL.
     */
    this (Value car = null, Value cdr = null) {
        this.car = car is null ? new Value(new BooleanToken(false)) : car;
        this.cdr = cdr is null ? new Value(new BooleanToken(false)) : cdr;
    }

    /**
     * Return's the CAR's token.
     */
    Value getCar () {
        return car;
    }

    /**
     * Return's the CDR's token.
     */
    Value getCdr () {
        return cdr;
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
            builder ~= node.car.token.toString();

            // If the CDR is NIL, this is the last element of the list.
            if (Token.isNil(node.cdr)) {
                break;

            } else {
                builder ~= " ";
                if (node.cdr.token.type == TokenType.reference) {
                    // if CDR is a reference token, retrieve the reference
                    node = (cast(ReferenceToken)node.cdr.token).reference;

                } else {
                    // otherwise indicate that it is part of a dotted pair and finish
                    builder ~= ". " ~ node.cdr.token.toString();
                    break;
                }
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
        if (cdr.token.type == TokenType.reference || Token.isNil(cdr)) {
            return listToString(this);
            
        } else {
            return "(" ~ car.toString() ~ " . " ~ cdr.toString() ~ ")";
        }

        return builder;
    }
}