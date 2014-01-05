module nostd.array;
// Re-implementation of subset of standard library

// Reason for re-implementation:
//  Compilation is too slow, when using standart libarary (on low-end machine)

// Warning: this module is *simplified* version
//  Functionality matches only *roughly*
//  Execution performance most likely will be *worse*



string join(string[] xs, string separator)
{
	string result;
	foreach(k,v; xs)
	{
		if(k!=0) result ~= separator;
		result ~= v;
	}
	return result;
}

unittest
{
	assert(join(["a","b","c"],",") == "a,b,c");
}





bool empty(T)(T[] xs)
{
	return xs.length == 0;
}

unittest
{
	assert(![1,2].empty);
	assert(!["1,2"].empty);
	assert([].empty);
}
