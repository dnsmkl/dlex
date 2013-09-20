module regex_implementation.parser;


import regex_implementation.ast;
alias regex_implementation.ast ast;

ast.RegexAST parse(string regexText)
{
	size_t startAt = 0;
	return subParse(regexText, startAt);
}

ast.RegexAST subParse(string regexText, ref size_t ix)
{
	ast.RegexAST[] accumulator;

	//foreach(ix, c; regexText)
	for(; ix<regexText.length; ++ix)
	{
		char c = regexText[ix];

		if(isLetter(c))
		{
			ast.RegexAST newSubAst = new ast.Letter(c);
			accumulator ~= newSubAst ;
		}
		else if(isRepeat(c))
		{
			auto lastIx = accumulator.length-1;
			accumulator[lastIx] = new ast.Repeat(accumulator[lastIx]); // transform into repeat
		}
		else if(isGroupStart(c))
		{
			ix++; //   <<---- INDEX MANIPULDATION!!!!!!!!
			accumulator ~= subParse(regexText, ix);
		}
		else if(isGroupEnd(c))
		{
			return makeSeqOnlyIfNeeded(accumulator);
		}
	}
	return makeSeqOnlyIfNeeded(accumulator);
}


ast.RegexAST makeSeqOnlyIfNeeded(ast.RegexAST[] accumulator...)
{
	if(accumulator.length==1) return accumulator[0];
	else if(accumulator.length>=2) return new ast.Sequence(accumulator);
	assert(0);
}


bool isRepeat(char c)
{
	return c=='*';
}

bool isGroupStart(char c)
{
	return c=='(';
}

bool isGroupEnd(char c)
{
	return c==')';
}

bool isLetter(char c)
{
	return c!='*' && c!='(' && c!=')';
}



unittest
{
	import std.stdio;


	writeln( "\n" );
	writeln( "---------------------------------------" );
	writeln( "-- regex_parser - unittest --" );
	writeln( "\n" );

	//auto pattern = "a";
	auto pattern = "(a)**a";
	writeln("Patern='" ~ pattern ~ "' parses into:");
	writeln(parse(pattern));

	writeln( "\n" );
	writeln( "-- regex_parser - unittest --" );
	writeln( "---------------------------------------" );
	writeln( "\n" );
}






/+
struct Tokenizer
{
	string inputText;

	@property
	bool empty()
	{
		import std.array:empty;
		return empty(inputText);
	}

	string front()
	{
		return [inputText[0]];
	}

	void popFront()
	{
		inputText = inputText[1 .. $];
	}

}
unittest
{
	import std.stdio;

	import std.range:isInputRange;
	assert(isInputRange!(Tokenizer),"isInputRange!(Tokenizer) failed");

	writeln( "\n" );
	writeln( "---------------------------------------" );
	writeln( "-- regex_parser.Tokenizer - unittest --" );
	writeln( "\n" );


	foreach(x; Tokenizer("(a(b)+)*"))
	{
		writeln(x);
	}


	writeln( "\n" );
	writeln( "-- regex_parser.Tokenizer - unittest --" );
	writeln( "---------------------------------------" );
	writeln( "\n" );
}
+/


