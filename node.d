module node;

import value;

import std.conv;

class Node {
    Value car;
    Value cdr;

    this () {
        car = new BooleanValue(false);
        cdr = new BooleanValue(false);
    }

    this (Value car = null, Value cdr = null) {
        this.car = car is null ? new BooleanValue(false) : car;
        this.cdr = cdr is null ? new BooleanValue(false) : cdr;
    }

    static bool isNil (Value value) {
        return value.type == ValueType.boolean && (cast(BooleanValue)value).boolValue == false;
    }

    static string listToString (Node root) {
        Node node = root;
        string builder = "(";

        while (true) {
            builder ~= node.car.toString();
            if (isNil(node.cdr)) {
                break;
            } else {
                builder ~= " ";
                node = (cast(ReferenceValue)node.cdr).reference;
            }
        }

        return builder ~ ")";
    }

    override string toString () {
        string builder;

        if (cdr.type == ValueType.reference) {
            return listToString(this);
        } else {
            return "(" ~ car.toString() ~ " . " ~ cdr.toString() ~ ")";
        }

        return builder;
    }

}