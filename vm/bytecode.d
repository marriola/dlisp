module vm.bytecode;

import std.array;
import std.container.array;
import std.algorithm;
import std.conv;
import std.format;

import util;

enum Opcode : ubyte { builtin0, builtin1, builtin, fun0, fun1, fun, tailcall0, tailcall1, tailcall, pushnil1, pushnil, pushconst, pushvalue, jump, jumpif, jumpifnot, ret, store, load };

enum string[Opcode] opcodeName = [Opcode.builtin0: "builtin0", Opcode.builtin1: "builtin1", Opcode.builtin: "builtin",
				  Opcode.fun0: "fun0", Opcode.fun1: "fun1", Opcode.fun: "fun", Opcode.tailcall0: "tailcall0",
				  Opcode.tailcall1: "tailcall1", Opcode.tailcall: "tailcall", Opcode.pushnil1: "pushnil1",
				  Opcode.pushconst: "pushconst", Opcode.pushvalue: "pushvalue", Opcode.jump: "jump",
				  Opcode.jumpif: "jumpif", Opcode.jumpifnot: "jumpifnot", Opcode.ret: "ret",
				  Opcode.store: "store", Opcode.load: "load" ];

struct Instruction {
    Opcode opcode;
    uint[] operands;

    string toString () {
        return "<" ~ opcodeName[opcode] ~ (operands.length > 0 ? " " : "") ~ join(map!(x => format("%x", x))(operands), ", ") ~ ">";
    }

	ubyte[] serialize () {
		auto output = new ubyte[0];
		
		output ~= opcode;

		foreach (uint operand; operands) {
			output ~= asBytes(operand, 4);
		}

		return asBytes(output.length, 4) ~ output;
	}

	static Instruction deserialize(ubyte[] bytes) {
		auto instr = Instruction();
		instr.opcode = cast(Opcode)bytes[0];
		instr.operands = new uint[0];
		
		for (int i = 0; i < bytes.length; i += 4) {
			instr.operands ~= fromBytes!uint(bytes[i .. i + 3]);
		}

		return instr;
	}
}
