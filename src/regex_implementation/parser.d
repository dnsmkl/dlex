module regex_implementation.parser;


import regex_implementation.ast;
alias regex_implementation.ast ast;


ast.RegexAST parse(string regexText)
{
	size_t startAt = 0;
	return recursiveParse(regexText, startAt);

}



/* Recursive parse, that starts at specified index
   Note: Index is incremented to notify calling frame, how much input was parsed
*/
private
RegexAST recursiveParse(string regexText, ref size_t currentChar)
{
	bool insideParanthesis = false;

	ast.RegexAST[] resultAccumulator;
	for(; currentChar<regexText.length; ++currentChar)
	{
		char c = regexText[currentChar];

		switch(c)
		{
			/* sequence start */
			case '(':
				++currentChar; //   <<---- INDEX MANIPULATION!!!!!!!!
				insideParanthesis = true;
				resultAccumulator ~= recursiveParse(regexText, currentChar);
				if(currentChar < regexText.length && regexText[currentChar] == ')')
				{
					insideParanthesis = false;
				}
			break;

			/* sequence end */
			case ')':
				goto exitFor;
			break;

			/* repeat 0 or more times */
			case '*':
				auto lastIx = resultAccumulator.length-1;
				resultAccumulator[lastIx] = new ast.Repeat(resultAccumulator[lastIx]); // transform into repeat
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
				auto resultAsSingleNode = makeSeqOnlyIfNeeded(resultAccumulator.dup);
				resultAccumulator.length = 1;
				++currentChar; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator[0] = new ast.Or(resultAsSingleNode, recursiveParse(regexText, currentChar));
			break;

			/* simple letter */
			default:
				resultAccumulator ~= new ast.Letter(c);
		}
	}
	exitFor:
	if(insideParanthesis) throw new Exception("Unmatched paranthesis in " ~ regexText);
	return makeSeqOnlyIfNeeded(resultAccumulator);
}


private
ast.RegexAST makeSeqOnlyIfNeeded(ast.RegexAST[] resultAccumulator)
{
	if(resultAccumulator.length==1) return resultAccumulator[0];
	else if(resultAccumulator.length>=2) return new ast.Sequence(resultAccumulator);
	assert(0);
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
}
