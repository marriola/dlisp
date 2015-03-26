module lispObject;

import std.conv;

import exceptions;
import token;


///////////////////////////////////////////////////////////////////////////////

size_t listLength (Value list) {
    size_t count = 0;

    while (list !is null && !Token.isNil(list)) {
        count++;
        list = (cast(ReferenceToken)list.token).reference.cdr;
    }

    return count;
}


///////////////////////////////////////////////////////////////////////////////

bool hasMore (Value head) {
    return head !is null && !Token.isNil(head);
}


///////////////////////////////////////////////////////////////////////////////

Value getItemReference (Value head, int index) {
    for (int i = 0; i < index; i++) {
        if (!hasMore(head)) {
            throw new OutOfBoundsException(index);
        }
        head = getRest(head);
    }

    if (!hasMore(head)) {
        throw new OutOfBoundsException(index);
    }

    return head;
}


///////////////////////////////////////////////////////////////////////////////

Value getItem (Value head, int index) {
    return getFirst(getItemReference(head, index));
}


///////////////////////////////////////////////////////////////////////////////

Value getFirst (Value head) {
    return (head.token.type == TokenType.reference) ? (cast(ReferenceToken)head.token).reference.car : null;
}


///////////////////////////////////////////////////////////////////////////////

Value getRest (Value head) {
    //return cast(ReferenceToken) ((head.type == TokenType.reference) ? (cast(ReferenceToken)head).reference.cdr : null);
    if (head.token.type == TokenType.reference) {
        return (cast(ReferenceToken)head.token).reference.cdr;
    } else {
        return null;
    }
}


///////////////////////////////////////////////////////////////////////////////

Value[] toArray (Value list) {
    if (!hasMore(list)) {
        return null;
    }

    //ReferenceToken head = cast(ReferenceToken)list.token;
    if (list.token.type != TokenType.reference) {
        throw new TypeMismatchException("toArray", list.token, "reference");
    }

    int length = listLength(list);
    Value[] array = new Value[length];

    for (int i = 0; i < length; i++) {
        array[i] = getFirst(list);
        list = getRest(list);
    }

    return array;
}


///////////////////////////////////////////////////////////////////////////////

bool objectsEqual (Value obj1, Value obj2) {
    if (obj1.token.type != obj2.token.type) {
        return false;
    }

    if (obj1.token.type == TokenType.integer) {
        return (cast(IntegerToken)obj1.token).intValue == (cast(IntegerToken)obj2.token).intValue;

    } else if (obj1.token.type == TokenType.floating) {
        return (cast(FloatToken)obj1.token).floatValue == (cast(FloatToken)obj2.token).floatValue;

    } else if (obj1.token.type == TokenType.identifier) {
        return (cast(IdentifierToken)obj1.token).stringValue == (cast(IdentifierToken)obj2.token).stringValue;

    } else {
        return obj1 == obj2;
    }
}
