module lispObject;

import token;

size_t listLength (ReferenceToken list) {
    size_t count = 0;

    while (list !is null && !Token.isNil(list)) {
        count++;
        list = cast(ReferenceToken)(list.reference.cdr);
    }

    return count;
}

bool hasMore (Token head) {
    return head !is null && !Token.isNil(head);
}

Token getFirst (Token head) {
    return (head.type == TokenType.reference) ? (cast(ReferenceToken)head).reference.car : null;
}

ReferenceToken getRest (Token head) {
    //return cast(ReferenceToken) ((head.type == TokenType.reference) ? (cast(ReferenceToken)head).reference.cdr : null);
    if (head.type == TokenType.reference) {
        return cast(ReferenceToken)(cast(ReferenceToken)head).reference.cdr;
    } else {
        return null;
    }
}

bool objectsEqual (Token obj1, Token obj2) {
    if (obj1.type != obj2.type) {
        return false;
    }

    if (obj1.type == TokenType.integer) {
        return (cast(IntegerToken)obj1).intValue == (cast(IntegerToken)obj2).intValue;

    } else if (obj1.type == TokenType.floating) {
        return (cast(FloatToken)obj1).floatValue == (cast(FloatToken)obj2).floatValue;
    } else if (obj1.type == TokenType.identifier) {
        return (cast(IdentifierToken)obj1).stringValue == (cast(IdentifierToken)obj2).stringValue;
    } else {
        return obj1 == obj2;
    }
}