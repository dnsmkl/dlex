

#lexer
test-lexer:
	rdmd -unittest --main --force src/lexer.d


#regex
test-regex:
	rdmd -unittest -Isrc --main --force src/regex/package.d

debug-regex:
	dmd -of"regex" -Isrc -unittest -g src/regex/package.d src/regex/*
	gdb regex


# ast
test-ast:
	rdmd -unittest -Isrc --main src/regex/ast.d



# nfa
test-nfa:
	rdmd -unittest -Isrc --main src/regex/nfa.d



# dfa
test-dfa:
	rdmd -unittest -Isrc --main src/regex/dfa.d



# to_nfa
test-to_nfa:
	rdmd -unittest -Isrc --main src/regex/to_nfa.d



# to_dfa
test-to_dfa:
	rdmd -unittest -Isrc --main src/regex/to_dfa.d



# parser
test-parser:
	rdmd -unittest -Isrc --main src/regex/parser.d


