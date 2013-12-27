module testing.benchmark;



auto comparingBenchmarkRegex(string pattern, string text)
{
	static import std.regex;
	auto regexBase = std.regex.regex(pattern);
	void base()
	{
		assert(std.regex.match(text,regexBase),text);
	}

	static import regex;
	auto regexTarget = regex.Regex(pattern);
	void target()
	{
		assert(regexTarget.matchExact(text),text);
	}

	static import std.datetime;
	return std.datetime.comparingBenchmark!(base, target, 5000);
}


void reportRegexComparison(string pattern, string text)
{
	import std.stdio:writefln;
	auto b = comparingBenchmarkRegex(pattern,text);
	writefln("%5.2f (std.regex/dlex) - %s - (%2d) %s"
		, b.point
		, pattern
		, text.length
		, text
	);
}


unittest
{
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbb");
	reportRegexComparison("(ab+)|(ba)", "abbb");
	reportRegexComparison("(ab+)|(ba)", "abb");
	reportRegexComparison("(ab+)|(ba)", "ab");
	reportRegexComparison("(ab+)|(ba)", "ba");
	reportRegexComparison("(ab+)|(ba)", "ba");
	reportRegexComparison("(ab+)|(ba)", "ab");
	reportRegexComparison("(ab+)|(ba)", "abb");
	reportRegexComparison("(ab+)|(ba)", "abbb");
	reportRegexComparison("(ab+)|(ba)", "abbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
	reportRegexComparison("(ab+)|(ba)", "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
}
