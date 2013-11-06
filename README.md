DLEX - personal attempt on creating a simple lexer (or lexer generator) in dlang



Why?
----
Personal challenge



What?
----
Lexer (or lexer generator).
Configurable during runtime. (so userdefined lexer could be usable without recompilation)

Usage will be something along the lines:

        auto lexer = makeLexer();
        lexer.add(regexstr1, name1, action1);
        lexer.add(regexstr2, name2, action2);
        lexer.setInput(input);

        foreach(auto tokenObject; lexer)
        {
            writeln(tokekenObject.name);
            writeln(tokekenObject.regexText);
            writeln(tokekenObject.matchedText);
            tokekenObject.associatedAction.execute();
        }



How?
----
To implement lexer, regular expression matcher will be needed.

Plan:
- implement regular expression
- make adjustments to regular expressions till it becomes lexer
    (many regular expressions will have to be melted into same NFA/DFA. Similar, but not exactly as normal union)



Examples of internal representations (just a reminder)
----
For regular expression dataflow will look like this:
    RegexString -> RegexAST -> NFA -> DFA -> match
    (instead of arrows there will be parsers/converters)

Example of RegexString
    "ab*b"

Example of RegexAST
    Sequence(Letter("a"), Repeat(Letter("b")), Letter("b"))

Example of NFA
    start:state1
    transitions:
        state1 | 'a' -> state2
        state2 | 'b' -> state2
        state2 | 'b' -> state3
    final:state3

Example of DFA
    start:state1
    transitions:
        state1  | 'a' -> state2
        state2  | 'b' -> state23
        state23 | 'b' -> state23
    final:state23
