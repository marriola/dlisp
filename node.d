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

    this (Value car, Value cdr = null) {
        this.car = car;

        if (cdr is null) {
            this.cdr = new BooleanValue(false);
        } else {
            this.cdr = cdr;
        }
    }

    static bool isNil (Value value) {
        return value.type == ValueType.boolean && (cast(BooleanValue)value).boolValue == false;
    }

    override string toString () {
        string builder;

        builder ~= "(" ~ car.toString() ~ " ";

        if (cdr.type != ValueType.reference) {
            builder ~= ". " ~ cdr.toString();
        } else {
            builder ~= cdr.toString();
        }

        builder ~= ")";

        return builder;
    }
}