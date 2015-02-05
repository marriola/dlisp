module node;

import value;

import std.conv;

class Node {
    Value car;
    Value cdr;

    /**
     * @param car the CAR of the new Node.
     * @param cdr the CDR of the new Node.
     * @return a Node object initialized with the given CAR and CDR. If null is passed for either argument, that part of the Node is initalized to the BooleanValue NIL.
     */
    this (Value car = null, Value cdr = null) {
        this.car = car is null ? new BooleanValue(false) : car;
        this.cdr = cdr is null ? new BooleanValue(false) : cdr;
    }

    /**
     * @param value a Value object to test.
     * @return true if the Value object is a BooleanValue representing the value NIL.
     */
    static bool isNil (Value value) {
        return value.type == ValueType.boolean && (cast(BooleanValue)value).boolValue == false;
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
                node = (cast(ReferenceValue)node.cdr).reference;
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
        if (cdr.type == ValueType.reference || isNil(cdr)) {
            return listToString(this);
            
        } else {
            return "(" ~ car.toString() ~ " . " ~ cdr.toString() ~ ")";
        }

        return builder;
    }

}