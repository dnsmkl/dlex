module regex_implementation.ast;


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
		this.sequenceOfRegexASTs ~= regexAST1;
		this.sequenceOfRegexASTs ~= regexAST2;
	}

	void add(RegexAST regexAST)
	{
		this.sequenceOfRegexASTs ~= regexAST;
	}


	override
	string toString()
	{
		import std.array;
		import std.algorithm;
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
		this.repeatableRegexAST = repeatableRegexAST;
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
		this.optionalRegexAST = optionalRegexAST;
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
version(none)
unittest
{
	import std.stdio;

	writeln( "\n" );
	writeln( "-------------------------" );
	writeln( "-- RegexAST - unittest --" );
	writeln( "\n" );

	writeln(new Letter('a'));
	writeln(new Sequence(new Letter('a'), new Letter('b'), new Letter('c')));
	writeln(new Or(new Repeat(new Optional(new Sequence(new Letter('a'), new Letter('b'), new Letter('c')))), new Letter('x')));
	writeln(new Sequence(new Repeat(new Sequence(new Letter('a'), new Letter('b'))), new Letter('a'), new Letter('b')));

	writeln( "\n" );
	writeln( "-- RegexAST - unittest --" );
	writeln( "-------------------------" );
	writeln( "\n" );
}






