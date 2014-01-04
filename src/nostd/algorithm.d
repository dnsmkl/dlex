module nostd.algorithm;
// Re-implementation of subset of standard library

// Reason for re-implementation:
//  Compilation is too slow, when using standart libarary (on low-end machine)

// Warning: this module is *simplified* version
//  Functionality matches only *roughly*
//  Execution performance most likely will be *worse*



string[] map(alias fn, TIn)(TIn[] xs)
{
	string[] result;
	foreach(a; xs) result ~= mixin(fn);
	return result;
}


unittest
{
	struct T
	{
		string s;
		string toString()
		{
			return "<" ~ s ~ ">";
		}
	}
	auto t = T("1");
	assert(t.toString() == "<1>");

	alias map!("a.toString", T) mapToString;
	assert(mapToString([T("1"),T("2")]) == ["<1>", "<2>"]);
}
