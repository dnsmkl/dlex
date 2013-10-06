module regex_implementation.to_nfa;


import regex_implementation.ast;
import regex_implementation.nfa;
alias regex_implementation.ast ast;
alias regex_implementation.nfa nfa;
/* dispatcher for interace */
NFA getNFA(ast.RegexAST rast)
{
	alias ast a;
	if(  cast(a.Letter   ) rast  ) return getNFA(cast(a.Letter  ) rast);
	if(  cast(a.Or       ) rast  ) return getNFA(cast(a.Or      ) rast);
	if(  cast(a.Repeat   ) rast  ) return getNFA(cast(a.Repeat  ) rast);
	if(  cast(a.Optional ) rast  ) return getNFA(cast(a.Optional) rast);
	if(  cast(a.Sequence ) rast  ) return getNFA(cast(a.Sequence) rast);
	assert(0);
}





NFA getNFA(ast.Letter rast)
{
	return NFA(rast.letter);
}

NFA getNFA(ast.Sequence rasts)
{
	auto result = NFA.createNFA();
	foreach(rast; rasts.sequenceOfRegexASTs)
	{
		result.append( getNFA(rast) );
	}
	return result;
}

NFA getNFA(ast.Optional rast)
{
	auto r = getNFA( rast.optionalRegexAST );
	r.makeOptional();
	return r;
}

NFA getNFA(ast.Repeat rast)
{
	auto r = getNFA( rast.repeatableRegexAST );
	r.makeRepeat();
	r.makeOptional();
	return r;
}

NFA getNFA(ast.Or rasts)
{
	auto result = NFA.createNFA();
	foreach(rast; rasts.regexASTs)
	{
		result.addUnion( getNFA(rast) );
	}
	return result;
}



version(none)
unittest
{
	import std.stdio:writeln;

	alias ast.Sequence S;
	alias ast.Letter L;
	alias ast.Optional O;
	alias ast.Repeat R;


	// (ab)*(ab)
	auto rast = new S(
			new R(new S(new L('a'), new L('b')))
			,new S(new L('a'), new L('b'))
			);
	//auto rast = new ast.Letter('a');
	auto nfa = getNFA(rast);



	writeln( "\n" );
	writeln( "---------------------------------------" );
	writeln( "-- ConverterRegexASTToNFA - unittest --" );
	writeln( "\n" );


	writeln(rast);
	writeln();
	writeln(nfa);

	writeln( "\n" );
	writeln( "-- ConverterRegexASTToNFA - unittest --" );
	writeln( "---------------------------------------" );
	writeln( "\n" );

}
