module dlex.regex.parser;


import dlex.regex.ast;
alias dlex.regex.ast ast;


ast.RegexAST parse(string regexText)
{
	size_t startAt = 0;
	return recursiveParse!(Par.none)(regexText, startAt);

}



// Needed to keep track what parathesis to expect during recursiveParse
enum Par{both, none, right};

/* Recursive parse, that starts at specified index
   Note: Index is incremented to notify calling frame, how much input was parsed
*/
private
RegexAST recursiveParse(Par paranthesis = Par.none)(string regexText, ref size_t currentIndex)
{
	static if(paranthesis == Par.both)
	{
		if(regexText[currentIndex] != '(') throw new UnmatchedParanthesis(regexText);
		++currentIndex;
	}
	ast.RegexAST[] resultAccumulator;
	for(; currentIndex<regexText.length; ++currentIndex)
	{
		switch(regexText[currentIndex])
		{
			/* sequence start */
			case '(':
				resultAccumulator ~= recursiveParse!(Par.both)(regexText, currentIndex);
			break;

			/* sequence end */
			case ')':
				static if(paranthesis == Par.none) throw new UnmatchedParanthesis(regexText);
				static if(paranthesis == Par.right) --currentIndex;
				return singleNode!(ast.Sequence)(resultAccumulator);
			break;

			/* repeat 0 or more times */
			case '*':
				if(resultAccumulator.length < 1) throw new MissingPreceedingToken(regexText);
				auto lastIx = resultAccumulator.length-1;

				bool laziness;
				if((currentIndex+1)<regexText.length && regexText[currentIndex+1]=='?')
				{
					++currentIndex; // eat the question mark
					laziness = true;
				}
				else laziness = false;

				resultAccumulator[lastIx] = new ast.Repeat(resultAccumulator[lastIx], laziness);
			break;

			/* repeat 1 or more times */
			case '+':
				if(resultAccumulator.length < 1) throw new MissingPreceedingToken(regexText);
				auto lastIx = resultAccumulator.length-1;
				auto last = resultAccumulator[lastIx];

				bool laziness;
				if((currentIndex+1)<regexText.length && regexText[currentIndex+1]=='?')
				{
					++currentIndex; // eat the question mark
					laziness = true;
				}
				else laziness = false;

				resultAccumulator[lastIx] = new ast.Sequence(last, new ast.Repeat(last, laziness));
			break;

			/* repeat specified amount of times */
			case '{':
				if(resultAccumulator.length < 1) throw new MissingPreceedingToken(regexText);
				auto lastIx = resultAccumulator.length-1;
				auto last = resultAccumulator[lastIx];
				auto repeatTimes = parseNumberedQuantifier(regexText, currentIndex);
				for(size_t i = 0; i<repeatTimes-1; ++i)
				{
					resultAccumulator[lastIx] = new ast.Sequence(resultAccumulator[lastIx], last);
				}
			break;

			case '}':
				throw new UnmatchedBrace(regexText);
			break;

			/* optional */
			case '?':
				if(resultAccumulator.length < 1) throw new MissingPreceedingToken(regexText);
				auto lastIx = resultAccumulator.length-1;

				bool laziness;
				if((currentIndex+1)<regexText.length && regexText[currentIndex+1]=='?')
				{
					++currentIndex; // eat the question mark
					laziness = true;
				}
				else laziness = false;

				resultAccumulator[lastIx] = new ast.Optional(resultAccumulator[lastIx], laziness);
			break;

			/* alteration */
			case '|':
				// without ".dup" it goes into infinite recursion with ast.Sequence.toString
				auto resultAsSingleNode = singleNode!(ast.Sequence)(resultAccumulator.dup);
				resultAccumulator.length = 1;
				++currentIndex; //   <<---- INDEX MANIPULATION!!!!!!!!
				resultAccumulator[0] = new ast.Or(
						resultAsSingleNode
						, recursiveParse!(Par.right)(regexText, currentIndex)
					);
			break;

			/* character classes */
			case '[':
				resultAccumulator ~= parseCharacterClass(regexText, currentIndex);
			break;

			case ']':
				throw new UnmatchedBracket(regexText);
			break;

			case '.':
				char loopChar = 0;
				ast.RegexAST anyChar;
				do
				{
					if(cast(ast.Or) anyChar || cast(ast.Letter) anyChar)
						anyChar = new ast.Or(anyChar, new ast.Letter(loopChar));
					else
						anyChar = new ast.Letter(loopChar);
					++loopChar;
				} while (loopChar != 0); // loop until 0 (char.max+1)
				resultAccumulator ~= anyChar;
			break;

			/* simple letter */
			default:
				resultAccumulator ~= new ast.Letter(regexText[currentIndex]);
		}
	}
	static if(paranthesis == Par.both) throw new UnmatchedParanthesis(regexText);
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
	++currentIndex;
	ast.RegexAST[] rs;
	for(; currentIndex<regexText.length && regexText[currentIndex] != ']'; ++currentIndex)
	{
		rs ~= new ast.Letter(regexText[currentIndex]);
	}
	if(currentIndex >= regexText.length
		|| regexText[currentIndex] != ']') throw new UnmatchedBracket(regexText);
	return singleNode!(ast.Or)(rs);
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
	assertParsedCharClass("[abc]", "Or{L(a)|L(b)|L(c)}");
}


size_t parseNumberedQuantifier(string regexText, ref size_t currentIndex)
{
	if(regexText[currentIndex] != '{') throw new UnmatchedBrace(regexText);
	++currentIndex;

	auto result = parseInteger(regexText, currentIndex);

	if(currentIndex >= regexText.length
		|| regexText[currentIndex] != '}') throw new UnmatchedBrace(regexText);
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




import utils.exception_ctor_mixin;
class ParsingException : Exception { mixin ExceptionCtorMixin; }

class UnmatchedParanthesis : ParsingException { mixin ExceptionCtorMixin; }
class UnmatchedBracket : ParsingException { mixin ExceptionCtorMixin; }
class UnmatchedBrace : ParsingException { mixin ExceptionCtorMixin; }

class MissingPreceedingToken : ParsingException { mixin ExceptionCtorMixin; }









unittest
{
	void assertParsedAST(
		string patternString
		, string expectedASTsString
		, size_t line = __LINE__
	)
	{
		import std.conv:to;
		auto ast = parse(patternString);
		assert(
			ast.toString == expectedASTsString
			, "\nTest on line(" ~ to!string(line) ~ "): "
			~ "'" ~ patternString ~ "' parses to " ~ ast.toString
			~ " vs expected " ~ expectedASTsString
		);
	}

	assertParsedAST("a"     , "L(a)");
	assertParsedAST("(a)"   , "L(a)");
	assertParsedAST("(a|b)" , "Or{L(a)|L(b)}");
	assertParsedAST("a**"   , "Rep(L(a))");
	assertParsedAST("a*?"   , "Rep(?L(a))");
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
	assertParsedAST("a+?"    , "Seq[L(a),Rep(?L(a))]");
	assertParsedAST("[ab]a" , "Seq[Or{L(a)|L(b)},L(a)]");
	assertParsedAST("a{2}"  , "Seq[L(a),L(a)]");
	assertParsedAST("a{3}"  , "Seq[L(a),L(a),L(a)]");
	assertParsedAST("."     , "Or{L(0x00)|L(0x01)|L(0x02)|L(0x03)|L(0x04)|L(0x05)|L(0x06)|L(0x07)|L(0x08)|L(0x09)|L(0x0A)|L(0x0B)|L(0x0C)|L(0x0D)|L(0x0E)|L(0x0F)|L(0x10)|L(0x11)|L(0x12)|L(0x13)|L(0x14)|L(0x15)|L(0x16)|L(0x17)|L(0x18)|L(0x19)|L(0x1A)|L(0x1B)|L(0x1C)|L(0x1D)|L(0x1E)|L(0x1F)|L( )|L(!)|L(\")|L(#)|L($)|L(%)|L(&)|L(')|L(()|L())|L(*)|L(+)|L(,)|L(-)|L(.)|L(/)|L(0)|L(1)|L(2)|L(3)|L(4)|L(5)|L(6)|L(7)|L(8)|L(9)|L(:)|L(;)|L(<)|L(=)|L(>)|L(?)|L(@)|L(A)|L(B)|L(C)|L(D)|L(E)|L(F)|L(G)|L(H)|L(I)|L(J)|L(K)|L(L)|L(M)|L(N)|L(O)|L(P)|L(Q)|L(R)|L(S)|L(T)|L(U)|L(V)|L(W)|L(X)|L(Y)|L(Z)|L([)|L(\\)|L(])|L(^)|L(_)|L(`)|L(a)|L(b)|L(c)|L(d)|L(e)|L(f)|L(g)|L(h)|L(i)|L(j)|L(k)|L(l)|L(m)|L(n)|L(o)|L(p)|L(q)|L(r)|L(s)|L(t)|L(u)|L(v)|L(w)|L(x)|L(y)|L(z)|L({)|L(|)|L(})|L(~)|L(0x7F)|L(0x80)|L(0x81)|L(0x82)|L(0x83)|L(0x84)|L(0x85)|L(0x86)|L(0x87)|L(0x88)|L(0x89)|L(0x8A)|L(0x8B)|L(0x8C)|L(0x8D)|L(0x8E)|L(0x8F)|L(0x90)|L(0x91)|L(0x92)|L(0x93)|L(0x94)|L(0x95)|L(0x96)|L(0x97)|L(0x98)|L(0x99)|L(0x9A)|L(0x9B)|L(0x9C)|L(0x9D)|L(0x9E)|L(0x9F)|L(0xA0)|L(0xA1)|L(0xA2)|L(0xA3)|L(0xA4)|L(0xA5)|L(0xA6)|L(0xA7)|L(0xA8)|L(0xA9)|L(0xAA)|L(0xAB)|L(0xAC)|L(0xAD)|L(0xAE)|L(0xAF)|L(0xB0)|L(0xB1)|L(0xB2)|L(0xB3)|L(0xB4)|L(0xB5)|L(0xB6)|L(0xB7)|L(0xB8)|L(0xB9)|L(0xBA)|L(0xBB)|L(0xBC)|L(0xBD)|L(0xBE)|L(0xBF)|L(0xC0)|L(0xC1)|L(0xC2)|L(0xC3)|L(0xC4)|L(0xC5)|L(0xC6)|L(0xC7)|L(0xC8)|L(0xC9)|L(0xCA)|L(0xCB)|L(0xCC)|L(0xCD)|L(0xCE)|L(0xCF)|L(0xD0)|L(0xD1)|L(0xD2)|L(0xD3)|L(0xD4)|L(0xD5)|L(0xD6)|L(0xD7)|L(0xD8)|L(0xD9)|L(0xDA)|L(0xDB)|L(0xDC)|L(0xDD)|L(0xDE)|L(0xDF)|L(0xE0)|L(0xE1)|L(0xE2)|L(0xE3)|L(0xE4)|L(0xE5)|L(0xE6)|L(0xE7)|L(0xE8)|L(0xE9)|L(0xEA)|L(0xEB)|L(0xEC)|L(0xED)|L(0xEE)|L(0xEF)|L(0xF0)|L(0xF1)|L(0xF2)|L(0xF3)|L(0xF4)|L(0xF5)|L(0xF6)|L(0xF7)|L(0xF8)|L(0xF9)|L(0xFA)|L(0xFB)|L(0xFC)|L(0xFD)|L(0xFE)|L(0xFF)}");



	void assertParseException(TException)(string patternString)
	{
		try
		{
			parse(patternString);
			assert(0);
		}
		catch(ParsingException e)
		{
			assert(cast(TException) e);
		}
	}

	assertParseException!UnmatchedParanthesis("(a+");
	assertParseException!UnmatchedParanthesis("a)a");
	assertParseException!UnmatchedBracket("a]a");
	assertParseException!UnmatchedBracket("[aa");
	assertParseException!UnmatchedBrace("a{3");
	assertParseException!UnmatchedBrace("a3}");
	assertParseException!MissingPreceedingToken("(+)");
	assertParseException!MissingPreceedingToken("+");
	assertParseException!MissingPreceedingToken("(*)");
	assertParseException!MissingPreceedingToken("*");
	assertParseException!MissingPreceedingToken("(?)");
	assertParseException!MissingPreceedingToken("?");
	assertParseException!MissingPreceedingToken("({1})");
	assertParseException!MissingPreceedingToken("{1}");
}
