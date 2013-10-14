module regex_implementation.parser;


import regex_implementation.ast;
alias regex_implementation.ast ast;


ast.RegexAST parse(string regexText)
{
	size_t startAt = 0;
	return subParse(regexText, startAt);

}


private
RegexAST subParse(string regexText, ref size_t ix)
{
	ast.RegexAST[] resultAccumulator;
	for(; ix<regexText.length; ++ix)
	{
		char c = regexText[ix];

		switch(c)
		{
			/* sequence start */
			case '(':
				++ix; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator ~= subParse(regexText, ix);
			break;

			/* sequence end */
			case ')':
				return makeSeqOnlyIfNeeded(resultAccumulator);
			break;

			/* repeat */
			case '*':
				auto lastIx = resultAccumulator.length-1;
				resultAccumulator[lastIx] = new ast.Repeat(resultAccumulator[lastIx]); // transform into repeat
			break;

			/* alteration */
			case '|':
				auto lastIx = resultAccumulator.length-1;
				auto last = resultAccumulator[lastIx];
				++ix; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator[lastIx] = new ast.Or(last, subParse(regexText, ix));
			break;

			/* simple letter */
			default:
				resultAccumulator ~= new ast.Letter(c);
		}
	}
	return makeSeqOnlyIfNeeded(resultAccumulator);
}


private
ast.RegexAST makeSeqOnlyIfNeeded(ast.RegexAST[] resultAccumulator...)
{
	if(resultAccumulator.length==1) return resultAccumulator[0];
	else if(resultAccumulator.length>=2) return new ast.Sequence(resultAccumulator);
	assert(0);
}




unittest
{
	void assertParsedAST(string patternString, string expectedASTsString )
	{
		assert( parse(patternString).toString == expectedASTsString );
	}

	assertParsedAST("a"     , "L(a)");
	assertParsedAST("(a)"   , "L(a)");
	assertParsedAST("a**"   , "Rep(Rep(L(a)))");
	assertParsedAST("ab"    , "Seq[L(a),L(b)]");
	assertParsedAST("abc"   , "Seq[L(a),L(b),L(c)]");
	assertParsedAST("ab*"   , "Seq[L(a),Rep(L(b))]");
	assertParsedAST("(ab)*" , "Rep(Seq[L(a),L(b)])");
	assertParsedAST("a|b"   , "Or{L(a)|L(b)}");
	assertParsedAST("a|ba"   , "Or{L(a)|Seq[L(b),L(a)]}");

	// TODO: make alteration lower priority then sequence
	// i.e. assertParsedAST("aa|b"  , "Or{Seq[L(a),L(a)]|L(b)}");
	// or   assert( equals( parse("aa|b"), parse("(aa)|b") ) ); // deep comparison should match
	assertParsedAST("aa|b"  , "Seq[L(a),Or{L(a)|L(b)}]"); // FIXME

	assertParsedAST("(aa)|b", "Or{Seq[L(a),L(a)]|L(b)}");
}
