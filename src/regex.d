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
		return dfa.checkWord(text);
	}

	string dumpDFA()
	{
		import std.stdio;
		writeln("regex1");
		auto r = dfa.toString();
		writeln("regex2");
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

	auto testOr = Regex("(ab)|(ba)");
	assert( testOr.matchExact("ba"));
	assert( testOr.matchExact("ab"));
	assert(!testOr.matchExact("aa"));
	assert(!testOr.matchExact("bb"));
	assert(!testOr.matchExact("baba"));
	assert(!testOr.matchExact("abab"));

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

	auto testOr2 = Regex("(ab)|ba");
	assert( testOr2.matchExact("ba"));
	assert( testOr2.matchExact("ab"));
}
