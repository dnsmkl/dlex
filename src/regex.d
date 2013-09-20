module regex;

import regex_implementation.parser;
import regex_implementation.ast;
import regex_implementation.to_nfa;
import regex_implementation.nfa;
import regex_implementation.to_dfa;
import regex_implementation.dfa;

import std.stdio;

void main()
{
	auto pattern = "(ab)*ab";
	auto ast = parse(pattern);
	auto nfa = getNFA(ast);
	auto dfa = toDfa(nfa);

	writeln(dfa.checkWord("a"));
	writeln(dfa.checkWord("ab"));
	writeln(dfa.checkWord("aba"));
	writeln(dfa.checkWord("abab"));
	writeln(dfa.checkWord("ababa"));
	writeln(dfa.checkWord("ababab"));
	writeln(dfa.checkWord("abababa"));

}
