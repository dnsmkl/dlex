module regex;

import regex_implementation.parser;
import regex_implementation.ast;
import regex_implementation.to_nfa;
import regex_implementation.nfa;
import regex_implementation.to_dfa;
import regex_implementation.dfa;



struct Regex
{
	alias regex_implementation.dfa.DFA!(regex_implementation.nfa.NFA.StateId) Dfa;
	Dfa dfa;
	NFA nfa;
	RegexAST ast;

	this(string regexPattern)
	{
		this.ast = parse(regexPattern);
		this.nfa = getNFA(ast);
		this.dfa = toDfa(nfa);
	}

	bool matchExact(string text)
	{
		return dfa.fullMatch(text);
	}

	string dumpDFA()
	{
		import std.stdio;
		auto r = dfa.toString();
		return r;
	}

	string dumpNFA()
	{
		return nfa.toString();
	}

	string dumpAST()
	{
		return ast.toString();
	}
}


unittest
{
	auto testSequence = Regex("aaab");
	assert( testSequence.matchExact("aaab"));
	assert(!testSequence.matchExact("aaa"));
	assert(!testSequence.matchExact("aaaba"));

	auto testRepeat = Regex("(ab)*");
	assert( testRepeat.matchExact(""));
	assert(!testRepeat.matchExact("a"));
	assert( testRepeat.matchExact("ab"));
	assert(!testRepeat.matchExact("aba"));
	assert( testRepeat.matchExact("abab"));
	assert(!testRepeat.matchExact("ababa"));
	assert( testRepeat.matchExact("ababab"));
	assert(!testRepeat.matchExact("abababa"));

	auto testOrWithParanthesis = Regex("(ab)|(ba)");
	assert( testOrWithParanthesis.matchExact("ba"));
	assert( testOrWithParanthesis.matchExact("ab"));
	assert(!testOrWithParanthesis.matchExact("aa"));
	assert(!testOrWithParanthesis.matchExact("bb"));
	assert(!testOrWithParanthesis.matchExact("baba"));
	assert(!testOrWithParanthesis.matchExact("abab"));

	auto testOrWithoutParanthesis = Regex("ab|ba");
	assert( testOrWithoutParanthesis.matchExact("ba"));
	assert( testOrWithoutParanthesis.matchExact("ab"));
	assert(!testOrWithoutParanthesis.matchExact("aa"));
	assert(!testOrWithoutParanthesis.matchExact("bb"));
	assert(!testOrWithoutParanthesis.matchExact("baba"));
	assert(!testOrWithoutParanthesis.matchExact("abab"));

	auto testMix = Regex("((ab*)|b)*aaa");
	assert(!testMix.matchExact(""));
	assert( testMix.matchExact("aaa"));
	assert( testMix.matchExact("baaa"));
	assert( testMix.matchExact("abaaa"));
	assert( testMix.matchExact("abbaaa"));
	assert( testMix.matchExact("babaaa"));
	assert( testMix.matchExact("babbaaa"));
	assert( testMix.matchExact("bbbaaa"));


	/* Following tests are just to capture current behaviour.
	   Such behaviour could/should be improved */
	auto testUnfinishedSequence = Regex("((aaab");
	assert( testUnfinishedSequence.matchExact("aaab"));
	assert(!testUnfinishedSequence.matchExact("aaa"));
	assert(!testUnfinishedSequence.matchExact("aaaba"));
}
