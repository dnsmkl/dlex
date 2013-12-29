

#lexer
test-lexer:
	rdmd -unittest --main --force src/dlex/lexer.d


#regex
test-regex:
	rdmd -unittest -Isrc --main --force src/dlex/regex/package.d

debug-regex:
	dmd -of"regex" -Isrc -unittest -g src/dlex/regex/package.d src/dlex/regex/*
	gdb regex


# ast
test-ast:
	rdmd -unittest -Isrc --main src/dlex/regex/ast.d



# nfa
test-nfa:
	rdmd -unittest -Isrc --main src/dlex/regex/nfa.d



# dfa
test-dfa:
	rdmd -unittest -Isrc --main src/dlex/regex/dfa.d



# to_nfa
test-to_nfa:
	rdmd -unittest -Isrc --main src/dlex/regex/to_nfa.d



# to_dfa
test-to_dfa:
	rdmd -unittest -Isrc --main src/dlex/regex/to_dfa.d



# parser
test-parser:
	rdmd -unittest -Isrc --main src/dlex/regex/parser.d


