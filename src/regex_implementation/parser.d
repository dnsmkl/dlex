module regex_implementation.parser;


import regex_implementation.ast;
alias regex_implementation.ast ast;


ast.RegexAST parse(string regexText)
{
	size_t startAt = 0;
	return recursiveParse!(Par.no)(regexText, startAt);

}



/* Recursive parse, that starts at specified index
   Note: Index is incremented to notify calling frame, how much input was parsed
*/
enum Par{yes, no}; // With paranthesis enclosing or no
private
RegexAST recursiveParse(Par paranthesis = Par.no)(string regexText, ref size_t currentChar)
{
	static if(paranthesis == Par.yes)
	{
		if(regexText[currentChar]!='(') throw new Exception("Unmatched paranthesis in " ~ regexText);
		++currentChar;
	}
	ast.RegexAST[] resultAccumulator;
	for(; currentChar<regexText.length; ++currentChar)
	{
		char c = regexText[currentChar];

		switch(c)
		{
			/* sequence start */
			case '(':
				resultAccumulator ~= recursiveParse!(Par.yes)(regexText, currentChar);
			break;

			/* sequence end */
			case ')':
				static if(paranthesis == Par.no) throw new Exception("Unmatched paranthesis in " ~ regexText);
				return singleNode!(ast.Sequence)(resultAccumulator);
			break;

			/* repeat 0 or more times */
			case '*':
				auto lastIx = resultAccumulator.length-1;
				resultAccumulator[lastIx] = new ast.Repeat(resultAccumulator[lastIx]);
			break;

			/* repeat 1 or more times */
			case '+':
				auto lastIx = resultAccumulator.length-1;
				auto last = resultAccumulator[lastIx];
				resultAccumulator[lastIx] = new ast.Sequence(last, new ast.Repeat(last));
			break;

			/* optional */
			case '?':
				auto lastIx = resultAccumulator.length-1;
				resultAccumulator[lastIx] = new ast.Optional(resultAccumulator[lastIx]);
			break;

			/* alteration */
			case '|':
				// without ".dup" it goes into infinite recursion with ast.Sequence.toString
				auto resultAsSingleNode = singleNode!(ast.Sequence)(resultAccumulator.dup);
				resultAccumulator.length = 1;
				++currentChar; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator[0] = new ast.Or(
						resultAsSingleNode
						, recursiveParse!(paranthesis.no)(regexText, currentChar)
					);
			break;

			/* character classes */
			case '[':
				resultAccumulator ~= parseCharacterClass(regexText,currentChar);
			break;

			/* simple letter */
			default:
				resultAccumulator ~= new ast.Letter(c);
		}
	}
	static if(paranthesis == Par.yes) throw new Exception("Unmatched paranthesis in " ~ regexText);
	return singleNode!(ast.Sequence)(resultAccumulator);
}


/* Output single node.  So it could be used in later composition (e.g. repeat) */
private
ast.RegexAST singleNode(ASTTypeForEnslosure)(ast.RegexAST[] resultAccumulator)
{
	if(resultAccumulator.length==1) return resultAccumulator[0];
	else if(resultAccumulator.length>=2) return new ASTTypeForEnslosure(resultAccumulator);
	assert(0);
}


ast.RegexAST parseCharacterClass(string regexText, ref size_t currentChar)
{
	assert(regexText[currentChar] == '[');
	ast.RegexAST r;
	++currentChar;

	for(; regexText[currentChar] != ']'; ++currentChar)
	{
		if(cast(ast.Or) r || cast(ast.Letter) r)
		{
			r = new ast.Or(r, new ast.Letter(regexText[currentChar]));
		}
		else
		{
			r = new ast.Letter(regexText[currentChar]);
		}
	}
	assert(regexText[currentChar] == ']');
	return r;
}
unittest
{
	void assertParsedCharClass(string patternString, string expectedASTsString )
	{
		size_t nr = 0;
		auto r = parseCharacterClass(patternString, nr);
		assert( r.toString == expectedASTsString
			, patternString
			~ " gives " ~ r.toString
			~ " vs expected " ~ expectedASTsString );
	}
	assertParsedCharClass("[a]", "L(a)");
	assertParsedCharClass("[ab]", "Or{L(a)|L(b)}");
	assertParsedCharClass("[abc]", "Or{Or{L(a)|L(b)}|L(c)}");
}


unittest
{
	void assertParsedAST(string patternString, string expectedASTsString )
	{
		assert( parse(patternString).toString == expectedASTsString
			, patternString
			~ " gives " ~ parse(patternString).toString
			~ " vs expected " ~ expectedASTsString );
	}

	assertParsedAST("a"     , "L(a)");
	assertParsedAST("(a)"   , "L(a)");
	assertParsedAST("a**"   , "Rep(Rep(L(a)))");
	assertParsedAST("ab"    , "Seq[L(a),L(b)]");
	assertParsedAST("abc"   , "Seq[L(a),L(b),L(c)]");
	assertParsedAST("ab*"   , "Seq[L(a),Rep(L(b))]");
	assertParsedAST("(ab)*" , "Rep(Seq[L(a),L(b)])");
	assertParsedAST("a|b"   , "Or{L(a)|L(b)}");
	assertParsedAST("a|ba"  , "Or{L(a)|Seq[L(b),L(a)]}");
	assertParsedAST("aa|b"  , "Or{Seq[L(a),L(a)]|L(b)}");
	assertParsedAST("(aa)|b", "Or{Seq[L(a),L(a)]|L(b)}");
	assertParsedAST("a?"    , "Opt(L(a))");
	assertParsedAST("(ab)?" , "Opt(Seq[L(a),L(b)])");
	assertParsedAST("a+"    , "Seq[L(a),Rep(L(a))]");
	assertParsedAST("[ab]a" , "Seq[Or{L(a)|L(b)},L(a)]");



	void assertParseExceptionMsg(string patternString, string expectedMsg)
	{
		try
		{
			parse(patternString);
			assert(0);
		}
		catch(Exception e)
		{
			assert(e.msg == expectedMsg);
		}
	}

	assertParseExceptionMsg("(a+", "Unmatched paranthesis in (a+");
	assertParseExceptionMsg("a)a", "Unmatched paranthesis in a)a");
}
