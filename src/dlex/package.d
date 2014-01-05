module dlex;



import dlex.regex;



alias string Tag;



struct Token
{
	bool match;
	string tokenText;
	Tag tokenTag;

	// no idea why, but without explicit opEquals comparison fails some times
	bool opEquals(Token other)
	{
		return this.match == other.match
			&& this.tokenText == other.tokenText
			&& this.tokenTag == other.tokenTag;
	}
}


struct Lexer
{
	Regex regex;
	uint rank = 0;


	void add(string regexPattern, Tag tag)
	{
		regex.appendOr(regexPattern, tag);
	}


	Token match(string text)
	{
		auto regexMatch = regex.matchStart(text);
		auto r = Token();
		r.match = regexMatch.match;
		r.tokenTag = regexMatch.tag;
		r.tokenText = regexMatch.text;
		return r;
	}
}


unittest
{
	// check if first match wins
	auto l1 = Lexer();
	l1.add("a", "1st");
	l1.add("a+", "2nd");
	assert(l1.match("a").tokenTag == "1st");
	assert(l1.match("aa").tokenTag == "1st");

	// Test if order of addition realy matters
	// Use same regexes, but in reverse order
	auto l2 = Lexer();
	l2.add("a+", "2nd");
	l2.add("a", "1st");
	assert(l2.match("a").tokenTag == "2nd");
	assert(l2.match("aa").tokenTag == "2nd");
}



/* Constructed from lexer and input text, to be iterated with foreach */
struct TokenStream
{
	private Lexer matcher;
	private string input;
	private size_t startAt=0;


	Token front()
	{
		return matcher.match(input[startAt..$]);
	}


	static import nostd.array;
	@property
	bool empty()
	{
		return nostd.array.empty(input[startAt..$]);
	}


	void popFront()
	{

		startAt += front().tokenText.length;
	}
}


unittest
{
	auto l1 = Lexer();
	l1.add("ac", "0th");
	l1.add("a", "1st");
	l1.add("b", "2nd");
	l1.add("bc", "3rd");
	l1.add("c", "4th");

	auto ts = TokenStream(l1, "babacbc");
	assert(!ts.empty);
	assert(ts.front() == Token(true,"b","2nd"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"a","1st"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"b","2nd"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"ac","0th"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"b","2nd"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"c","4th"));
	ts.popFront();
	assert(ts.empty);
}
