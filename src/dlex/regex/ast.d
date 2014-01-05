module dlex.regex.ast;


interface RegexAST
{
	string toString();
}


// Base class for regex AST node (with single direct child node)
class SingleChild
{
	RegexAST regexAST;
	bool laziness;


	protected template ctorMixin(T = void)
	{
		this(RegexAST regexAST)
		{
			if(cast(typeof(this)) regexAST)
				this.regexAST = (cast(typeof(this)) regexAST).regexAST;
			else
				this.regexAST = regexAST;
		}


		this(RegexAST regexAST, bool laziness)
		{
			this(regexAST);
			this.laziness = laziness;
		}
	}


	protected template toStringMixin(string d1, string d2)
	{
		override final
		string toString()
		{
			return d1 ~ (laziness?"?":"") ~ regexAST.toString() ~ d2;
		}
	}
}


// Base class for regex AST node (with many direct children nodes)
class ManyChildren
{
	RegexAST[] regexASTs;


	protected template ctorMixin()
	{
		this(RegexAST[] _regexASTs)
		{
			regexASTs = _regexASTs;
		}


		this(RegexAST regexAST1, RegexAST regexAST2)
		{
			// Flaten result: instead of Xy[Xy[a,b],Xy[c,d]], make Xy[a,b,c,d]
			if(cast(typeof(this)) regexAST1)
				this.regexASTs ~= (cast(typeof(this)) regexAST1).regexASTs;
			else
				this.regexASTs ~= regexAST1;

			if(cast(typeof(this)) regexAST2)
				foreach(ast; (cast(typeof(this)) regexAST2).regexASTs)
					this.regexASTs ~= ast;
			else
				this.regexASTs ~= regexAST2;
		}
	}


	// DMD bug 7016 prevents moving imports inside of method body
	// http://d.puremagic.com/issues/show_bug.cgi?id=7016
	// If std join+map is used - toString is called twice for same element (bad in case of nesting)
	import nostd.array:join;
	import nostd.algorithm:map;
	protected template toStringMixin(string d1, string separator,  string d2)
	{
		override final
		string toString()
		{
			return d1 ~ map!"a.toString"(regexASTs).join(separator) ~ d2;
		}
	}
}


/* e.g. "abc" */
class Sequence: ManyChildren, RegexAST
{
	mixin ManyChildren.ctorMixin;
	mixin ManyChildren.toStringMixin!("Seq[", ",", "]");
}


/* e.g. "a|b" */
class Or: ManyChildren, RegexAST
{
	mixin ManyChildren.ctorMixin;
	mixin ManyChildren.toStringMixin!("Or{", "|", "}");
}


/* e.g. "a*" */
class Repeat: SingleChild, RegexAST
{
	mixin SingleChild.ctorMixin;
	mixin SingleChild.toStringMixin!("Rep(", ")");
}


/* e.g. "a?" */
class Optional: SingleChild, RegexAST
{
	mixin SingleChild.ctorMixin;
	mixin SingleChild.toStringMixin!("Opt(", ")");
}


/* e.g. "a" */
class Letter: RegexAST
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
	assertASTString(new Optional(new Letter('a'), true), "Opt(?L(a))");
	assertASTString(new Repeat(new Letter('a'), true), "Rep(?L(a))");
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

	// ensure that it is greedy by default
	auto x = new Repeat(new Letter('a'));
	assert(x.laziness == false);
}
