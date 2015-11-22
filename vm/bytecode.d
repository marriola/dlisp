module vm.bytecode;

import std.array;
import std.container.array;
import std.algorithm;
import std.conv;
import std.format;


enum Opcode : ubyte { builtin0, builtin1, builtin, fun0, fun1, fun, tailcall0, tailcall1, tailcall, pushnil1, pushnil, pushconst, pushvalue, jump, jumpif, jumpifnot, ret };

enum string[Opcode] opcodeName = [Opcode.builtin0: "builtin0", Opcode.builtin1: "builtin1", Opcode.builtin: "builtin",
                             Opcode.fun0: "fun0", Opcode.fun1: "fun1", Opcode.fun: "fun", Opcode.tailcall0: "tailcall0",
                             Opcode.tailcall1: "tailcall1", Opcode.tailcall: "tailcall", Opcode.pushnil1: "pushnil1",
                             Opcode.pushconst: "pushconst", Opcode.pushvalue: "pushvalue", Opcode.jump: "jump",
                             Opcode.jumpif: "jumpif", Opcode.jumpifnot: "jumpifnot", Opcode.ret: "ret"];

struct Instruction {
    Opcode opcode;
    uint[] operands;

    string toString () {
        return "<" ~ opcodeName[opcode] ~ (operands.length > 0 ? " " : "") ~ join(map!(x => format("%x", x))(operands), ", ") ~ ">";
    }

	Array!ubyte serialize () {
		auto output = Array!ubyte();
		
		output.insertBack(opcode);

		foreach (uint operand; operands) {
			uint upper = operand % 0x1000;
			uint lower = operand / 0x1000;
			output.insertBack(cast(ubyte)(lower % 0x100));
			output.insertBack(cast(ubyte)(lower / 0x100));
			output.insertBack(cast(ubyte)(upper % 0x100));
			output.insertBack(cast(ubyte)(upper / 0x100));
		}

		return output;
	}
}