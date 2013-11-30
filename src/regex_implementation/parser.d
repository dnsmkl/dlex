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
RegexAST recursiveParse(Par paranthesis = Par.no)(string regexText, ref size_t currentIndex)
{
	static if(paranthesis == Par.yes)
	{
		if(regexText[currentIndex] != '(') throw new Exception("Unmatched paranthesis in " ~ regexText);
		++currentIndex;
	}
	ast.RegexAST[] resultAccumulator;
	for(; currentIndex<regexText.length; ++currentIndex)
	{
		switch(regexText[currentIndex])
		{
			/* sequence start */
			case '(':
				resultAccumulator ~= recursiveParse!(Par.yes)(regexText, currentIndex);
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

			/* repeat specified amount of times */
			case '{':
				auto lastIx = resultAccumulator.length-1;
				auto last = resultAccumulator[lastIx];
				auto repeatTimes = parseNumberedQuantifier(regexText, currentIndex);
				for(size_t i = 0; i<repeatTimes-1; ++i)
				{
					resultAccumulator[lastIx] = new ast.Sequence(resultAccumulator[lastIx], last);
				}
			break;

			case '}':
				throw new Exception("Unmatched curly braces in " ~ regexText);
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
				++currentIndex; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator[0] = new ast.Or(
						resultAsSingleNode
						, recursiveParse!(paranthesis.no)(regexText, currentIndex)
					);
			break;

			/* character classes */
			case '[':
				resultAccumulator ~= parseCharacterClass(regexText, currentIndex);
			break;

			case ']':
				throw new Exception("Unmatched bracket in " ~ regexText);
			break;

			/* simple letter */
			default:
				resultAccumulator ~= new ast.Letter(regexText[currentIndex]);
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


ast.RegexAST parseCharacterClass(string regexText, ref size_t currentIndex)
{
	assert(regexText[currentIndex] == '[');
	ast.RegexAST r;
	++currentIndex;

	for(; currentIndex<regexText.length && regexText[currentIndex] != ']'; ++currentIndex)
	{
		if(cast(ast.Or) r || cast(ast.Letter) r)
		{
			r = new ast.Or(r, new ast.Letter(regexText[currentIndex]));
		}
		else
		{
			r = new ast.Letter(regexText[currentIndex]);
		}
	}
	if(currentIndex >= regexText.length
		|| regexText[currentIndex] != ']') throw new Exception("Unmatched bracket in " ~ regexText);
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


size_t parseNumberedQuantifier(string regexText, ref size_t currentIndex)
{
	if(regexText[currentIndex] != '{') throw new Exception("Unmatched curly braces in " ~ regexText);
	++currentIndex;

	auto result = parseInteger(regexText, currentIndex);

	if(regexText[currentIndex] != '}') throw new Exception("Unmatched curly braces in " ~ regexText);
	++currentIndex;

	return result;
}
unittest
{
	void assertNumberedQuantifier(string regexText, size_t expectedNumber, size_t expectedIndex)
	{
		size_t index = 0;
		assert(
			parseNumberedQuantifier(regexText, index) == expectedNumber
			,"regexText:" ~ regexText
		);
		assert(index == expectedIndex, "regexText:" ~ regexText);
	}
	assertNumberedQuantifier("{2}", 2, 3);
	assertNumberedQuantifier("{2},text", 2, 3);
	assertNumberedQuantifier("{123},text", 123, 5);
}


size_t parseInteger(string regexText, ref size_t currentIndex)
{
	size_t result = 0;
	while(currentIndex < regexText.length
		&& isDigit(regexText[currentIndex]))
	{
		auto digit = digitToInt(regexText[currentIndex]);
		result *= 10;
		result += digit;
		++currentIndex;
	}
	return result;
}
unittest
{
	void assertInteger(string regexText, size_t expectedInteger)
	{
		size_t index = 0;
		assert(
			parseInteger(regexText, index) == expectedInteger
			,"regexText:" ~ regexText
		);
	}
	assertInteger("000",0);
	assertInteger("10",10);
	assertInteger("197532,",197532);
}


bool isDigit(char c)
{
	return c >= '0' && c <= '9';
}
unittest
{
	assert(isDigit('0'));
	assert(isDigit('1'));
	assert(isDigit('9'));
	assert(!isDigit('u'));
	assert(!isDigit('-'));
}


size_t digitToInt(char c)
{
	return c - '0';
}
unittest
{
	assert(digitToInt('0') == 0);
	assert(digitToInt('1') == 1);
	assert(digitToInt('9') == 9);
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
	assertParsedAST("a{2}"  , "Seq[L(a),L(a)]");
	assertParsedAST("a{3}"  , "Seq[L(a),L(a),L(a)]");



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
	assertParseExceptionMsg("a]a", "Unmatched bracket in a]a");
	assertParseExceptionMsg("[aa", "Unmatched bracket in [aa");
}
