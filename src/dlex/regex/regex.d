module dlex.regex.regex;
/* Connect all the parts of regex pattern matcher
	regexText -> AST -> NFA -> DFA -> matcher */


import dlex.regex.parser;
import dlex.regex.ast;
import dlex.regex.to_nfa;
import dlex.regex.nfa;
import dlex.regex.to_dfa;
import dlex.regex.dfa;


alias string Tag;



struct Match
{
	bool match;
	string text;
	Tag tag;

	// no idea why, but without explicit opEquals comparison fails some times
	bool opEquals(Match other)
	{
		return this.match == other.match
			&& this.text == other.text
			&& this.tag == other.tag;
	}
}



/* Tagged regex pattern matcher */
struct Regex
{
	NFA nfa;
	uint rank = 0;
	alias typeof(toDfa(this.nfa)) Matcher;
	Matcher matcher;


	this(string regexPattern)
	{
		appendOr(regexPattern, "");
	}


	void appendOr(string regexPattern, Tag tag)
	{
		auto ast = parse(regexPattern);
		auto newNFA = getNFA(ast);
		newNFA.setEndTag(tag, rank);
		++rank;

		if(nfa.empty)
		{
			nfa = newNFA;
		}
		else
		{
			nfa.addUnion(newNFA);
		}
		this.matcher = toDfa(this.nfa);
	}


	Match matchStart(string text)
	{
		auto dfaMatch = this.matcher.partialMatch(text);

		auto r = Match();
		r.match = dfaMatch.match;
		if(r.match)
		{
			r.tag = dfaMatch.tag;
			r.text = text[0 .. dfaMatch.count];
		}
		return r;
	}


	bool matchExact(string text)
	{
		auto matchResult = matchStart(text);
		return matchResult.match && matchResult.text.length == text.length;
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

	auto testAlphabet = Regex("ab``");
	assert( testAlphabet.matchExact("ab``"));


	auto testLazyPlus = Regex("[ab]+?b+");
	assert( testLazyPlus.matchStart("aabbbabb").text == "aabbb");

	auto testLazyStarLonely = Regex("a*?");
	assert( testLazyStarLonely.matchStart("aaaa").text == "");

	auto testLazyQmarkLonely = Regex("a??");
	assert( testLazyQmarkLonely.matchStart("aaa").text == "");

	auto testLonelyLazyPlusLonely = Regex("a+?");
	assert( testLonelyLazyPlusLonely.matchStart("aaa").text == "a");
}
