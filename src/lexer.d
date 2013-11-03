module lexer;

import regex_implementation.parser;
import regex_implementation.ast;
import regex_implementation.to_nfa;
import regex_implementation.nfa;
import regex_implementation.to_dfa;
import regex_implementation.dfa;


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
	alias regex_implementation.dfa.DFA!(regex_implementation.nfa.NFA.StateId) Dfa;
	NFA nfa;




	void add(string regexPattern, Tag tag)
	{

		auto ast = parse(regexPattern);
		auto newNFA = getNFA(ast);
		newNFA.setEndTag(tag);

		if(nfa.empty)
		{
			nfa = newNFA;
		}
		else
		{
			nfa.addUnion(newNFA);
		}
	}


	Token match(string text)
	{
		auto dfa = toDfa(this.nfa);
		auto dfaMatch = dfa.partialMatch(text);

		auto r = Token();
		r.match = dfaMatch.match;
		r.tokenTag = dfaMatch.tag;
		r.tokenText = text[0 .. dfa.partialMatch(text).count];
		return r;
	}

	Tag getTag(string text)
	{
		return this.match(text).tokenTag;
	}

}


unittest
{
	// check if first match wins
	auto l1 = Lexer();
	l1.add("a", "1st");
	l1.add("a+", "2nd");
	assert(l1.getTag("a") == "1st");
	assert(l1.getTag("aa") == "2nd");

	// Test if order of addition realy matters
	// Use same regexes, but in reverse order
	auto l2 = Lexer();
	l2.add("a+", "2nd");
	l2.add("a", "1st");
	assert(l2.getTag("a") == "2nd");
	assert(l2.getTag("aa") == "2nd");
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


	@property
	bool empty()
	{
		return input[startAt..$].empty;
	}


	void popFront()
	{

		startAt += front().tokenText.length;
	}
}


unittest
{
	auto l1 = Lexer();
	l1.add("a", "1st");
	l1.add("b+", "2nd");

	auto ts = TokenStream(l1, "bbabb");
	assert(!ts.empty);
	assert(ts.front() == Token(true,"bb","2nd"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"a","1st"));
	ts.popFront();
	assert(!ts.empty);
	assert(ts.front() == Token(true,"bb","2nd"));
	ts.popFront();
	assert(ts.empty);
}
