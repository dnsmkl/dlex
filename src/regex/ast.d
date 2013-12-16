module regex.ast;


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


	override
	string toString()
	{
		import std.array:join;
		import std.algorithm:map;
		return "Seq["
			~ join
			(
				map!"a.toString()"(sequenceOfRegexASTs)
				,","
			)
			~ "]";
	}
}


/* e.g. "a|b" */
class Or:RegexAST
{
	RegexAST[] regexASTs;
	this(RegexAST regexAST1, RegexAST regexAST2)
	{
		this.regexASTs ~= regexAST1;
		this.regexASTs ~= regexAST2;
	}


	override
	string toString()
	{
		import std.array;
		import std.algorithm;
		return "Or{"
			~ join(map!"a.toString()"(regexASTs),"|")
			~ "}";
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


	override pure nothrow @safe
	string toString()
	{
		return "L("~ letter ~")";
	}
}

// TODO: Implement RepeatBounded, which can be converted to Optional + lots of copying
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
	assertASTString(new Or(new Or(new Letter('a'),new Letter('b')),new Letter('c')), "Or{Or{L(a)|L(b)}|L(c)}");
	assertASTString(
		new Sequence(
			new Sequence(new Letter('a'),new Letter('b'))
			,new Sequence(new Letter('c'),new Letter('d'))
		)
		, "Seq[L(a),L(b),L(c),L(d)]"
	);
}





