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

	auto testRepeatStar = Regex("(ab)*");
	assert( testRepeatStar.matchExact(""));
	assert(!testRepeatStar.matchExact("a"));
	assert( testRepeatStar.matchExact("ab"));
	assert(!testRepeatStar.matchExact("aba"));
	assert( testRepeatStar.matchExact("abab"));
	assert(!testRepeatStar.matchExact("ababa"));
	assert( testRepeatStar.matchExact("ababab"));
	assert(!testRepeatStar.matchExact("abababa"));

	auto testRepeatPlus = Regex("(ab)+");
	assert(!testRepeatPlus.matchExact(""));
	assert(!testRepeatPlus.matchExact("a"));
	assert( testRepeatPlus.matchExact("ab"));
	assert(!testRepeatPlus.matchExact("aba"));
	assert( testRepeatPlus.matchExact("abab"));
	assert(!testRepeatPlus.matchExact("ababa"));
	assert( testRepeatPlus.matchExact("ababab"));
	assert(!testRepeatPlus.matchExact("abababa"));

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

	auto testOptional = Regex("a?");
	assert( testOptional.matchExact("a"));
	assert( testOptional.matchExact(""));
	assert(!testOptional.matchExact("b"));
	assert(!testOptional.matchExact("aa"));

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


	auto testAlphabet = Regex("ab``");
	assert( testAlphabet.matchExact("ab``"));
}
