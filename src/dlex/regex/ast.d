module dlex.regex.ast;


interface RegexAST
{
	string toString();
}


/* e.g. "abc" */
class Sequence:RegexAST
{
	RegexAST[] sequenceOfRegexASTs;


	this(RegexAST[] sequenceOfRegexASTs)
	{
		this.sequenceOfRegexASTs = sequenceOfRegexASTs;
	}

	this(RegexAST regexAST1, RegexAST regexAST2)
	{
		// Try to flaten resulting ast
		// e.g. instead of Seq[Seq[a,b],Seq[c,d]], make Seq[a,b,c,d]
		if(cast(Sequence) regexAST1)
		{
			this.sequenceOfRegexASTs ~= (cast(Sequence) regexAST1).sequenceOfRegexASTs;
		}
		else
		{
			this.sequenceOfRegexASTs ~= regexAST1;
		}

		if(cast(Sequence) regexAST2)
		{
			foreach(ast; (cast(Sequence) regexAST2).sequenceOfRegexASTs)
			{
				this.sequenceOfRegexASTs ~= ast;
			}
		}
		else
		{
			this.sequenceOfRegexASTs ~= regexAST2;
		}
	}


	// Dmd bug prevents moving imports inside of method body
	// http://d.puremagic.com/issues/show_bug.cgi?id=7016
	import nostd.array:join;
	import nostd.algorithm:map;
	override
	string toString()
	{
		// if join+map from stdlib are used
		// then to string is called twice for same element (blows up in case of nesting)
		return "Seq[" ~ map!"a.toString"(sequenceOfRegexASTs).join(",") ~ "]";
	}
}


/* e.g. "a|b" */
class Or:RegexAST
{
	RegexAST[] regexASTs;
	this(RegexAST regexAST1, RegexAST regexAST2)
	{
		if(cast(Or)regexAST1) regexASTs ~= (cast(Or)regexAST1).regexASTs;
		else this.regexASTs ~= regexAST1;
		if(cast(Or)regexAST2) regexASTs ~= (cast(Or)regexAST2).regexASTs;
		else this.regexASTs ~= regexAST2;
	}


	this(RegexAST[] regexASTs)
	{
		this.regexASTs = regexASTs;
	}


	// Dmd bug prevents moving imports inside of method body
	// http://d.puremagic.com/issues/show_bug.cgi?id=7016
	import nostd.array:join;
	import nostd.algorithm:map;
	override
	string toString()
	{
		// if join+map from stdlib are used
		// then to string is called twice for same element (blows up in case of nesting)
		return "Or{" ~ map!"a.toString"(regexASTs).join("|") ~ "}";
	}
}


/* e.g. "a*" */
class Repeat:RegexAST
{
	RegexAST repeatableRegexAST;
	this(RegexAST repeatableRegexAST)
	{
		if(cast(Repeat) repeatableRegexAST)
		{
			this.repeatableRegexAST = (cast(Repeat) repeatableRegexAST).repeatableRegexAST;
		}
		else
		{
			this.repeatableRegexAST = repeatableRegexAST;
		}
	}


	override
	string toString()
	{
		return "Rep("~ repeatableRegexAST.toString() ~")";
	}
}


/* e.g. "a?" */
class Optional:RegexAST
{
	RegexAST optionalRegexAST;
	this(RegexAST optionalRegexAST)
	{
		if(cast(Optional) optionalRegexAST)
		{
			this.optionalRegexAST = (cast(Optional) optionalRegexAST).optionalRegexAST;
		}
		else
		{
			this.optionalRegexAST = optionalRegexAST;
		}
	}


	override
	string toString()
	{
		return "Opt("~ optionalRegexAST.toString() ~")";
	}
}


/* e.g. "a" */
class Letter:RegexAST
{
	char letter;
	this(char letter)
	{
		this.letter = letter;
	}


	static import utils.str_format;
	override pure nothrow @safe
	string toString()
	{
		if(letter>= 0x20 &&  letter < 0x7F)
			return "L("~ letter ~")"; //ascii letter
		else
			return "L("~ utils.str_format.hex(letter) ~")"; // non-ascii letter
	}
}


unittest
{
	void assertASTString(
		RegexAST ast
		, string expectedASTsString
		, size_t line = __LINE__
	)
	{
		import std.conv:to;
		assert(
			ast.toString == expectedASTsString
			, "\nTest on line(" ~ to!string(line) ~ "): "
			~ "ast.toString gives " ~ ast.toString
			~ " vs expected " ~ expectedASTsString
		);
	}
	assertASTString(new Letter('a'), "L(a)");
	assertASTString(new Optional(new Letter('a')), "Opt(L(a))");
	assertASTString(new Repeat(new Letter('a')), "Rep(L(a))");
	assertASTString(new Or(new Letter('a'),new Letter('b')), "Or{L(a)|L(b)}");
	assertASTString(new Sequence(new Letter('a'),new Letter('b')), "Seq[L(a),L(b)]");

	assertASTString(new Optional(new Optional(new Letter('a'))), "Opt(L(a))");
	assertASTString(new Repeat(new Repeat(new Letter('a'))), "Rep(L(a))");
	assertASTString(new Or(new Or(new Letter('a'),new Letter('b')),new Letter('c')), "Or{L(a)|L(b)|L(c)}");
	assertASTString(
		new Sequence(
			new Sequence(new Letter('a'),new Letter('b'))
			,new Sequence(new Letter('c'),new Letter('d'))
		)
		, "Seq[L(a),L(b),L(c),L(d)]"
	);
}
