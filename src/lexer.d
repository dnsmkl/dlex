module lexer;

import regex_implementation.parser;
import regex_implementation.ast;
import regex_implementation.to_nfa;
import regex_implementation.nfa;
import regex_implementation.to_dfa;
import regex_implementation.dfa;



struct Lexer
{
	alias regex_implementation.dfa.DFA!(regex_implementation.nfa.NFA.StateId) Dfa;
	NFA nfa;
	alias string Tag;




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


	Tag getTag(string text)
	{
		auto dfa = toDfa(nfa);
		return dfa.partialMatch(text).tag;
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