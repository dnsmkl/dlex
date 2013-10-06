

#regex
test-regex:
	rdmd -unittest --main --force src/regex.d

debug-regex:
	dmd -of"regex" -unittest -g src/regex.d src/regex_implementation/*
	gdb regex


# ast
test-ast:
	rdmd -unittest -Isrc --main src/regex_implementation/ast.d



# nfa
test-nfa:
	rdmd -unittest -Isrc --main src/regex_implementation/nfa.d



# dfa
test-dfa:
	rdmd -unittest -Isrc --main src/regex_implementation/dfa.d



# to_nfa
test-to_nfa:
	rdmd -unittest -Isrc --main src/regex_implementation/to_nfa.d



# to_dfa
test-to_dfa:
	rdmd -unittest -Isrc --main src/regex_implementation/to_dfa.d



# parser
test-parser:
	rdmd -unittest -Isrc --main src/regex_implementation/parser.d


