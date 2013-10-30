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
	auto l = Lexer();

	l.add("a", "1st");
	l.add("b", "2nd");
	l.add("c", "3rd");

	assert(l.getTag("abc") == "1st");
	assert(l.getTag("bc") == "2nd");
	assert(l.getTag("c") == "3rd");
}

unittest
{
	// Test if order of addition realy matters
	auto l1 = Lexer();
	l1.add("a", "1st");
	l1.add("a+", "2nd");
	assert(l1.getTag("a") == "1st");
	assert(l1.getTag("aa") == "2nd");

	auto l2 = Lexer();
	// same regexes just switched order
	l2.add("a+", "2nd");
	l2.add("a", "1st");
	assert(l2.getTag("a") == "2nd");
	assert(l2.getTag("aa") == "2nd");
}
