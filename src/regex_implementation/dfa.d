module regex_implementation.dfa;


import std.array;


/* Deterministic finate automaton - transformed from NFA */
class DFA(StateIdNFA)
{
	import std.container;


	alias char AlphaElement;
	alias RedBlackTree!(StateIdNFA) State;
	alias size_t StateId;
	alias redBlackTree!(StateIdNFA) makeState;

	State[] states;
	StateId start;

	struct TaggedEnd{ StateId stateId; string tag; }
	TaggedEnd[] ends;
	StateId[AlphaElement][StateId] transitions;


	this()
	{

	}



	bool isDFAStateNewFromNFA(StateIdNFA[] nfaStates)
	{
		State potentialyNewState = makeState(nfaStates);
		return !exists!State(this.states, potentialyNewState);
	}


	void addStateFromNFA(StateIdNFA[] nfaStates)
	{
		State potentialyNewState = makeState(nfaStates);
		if(!exists!State(this.states, potentialyNewState)) states ~= potentialyNewState;
	}

	void addTransitionFromNFA(StateIdNFA[] sourceNFA, AlphaElement letter, StateIdNFA[] targetNFA)
	{
		addStateFromNFA(sourceNFA);
		addStateFromNFA(targetNFA);
		StateId source = getStateId(sourceNFA);
		StateId target = getStateId(targetNFA);
		transitions[source][letter] = target;
	}


	public
	void markEnd(StateIdNFA[] reachableStates)
	{
		this.ends ~= TaggedEnd(getStateId(reachableStates),"");
	}

	public
	void markEndTagged(StateIdNFA[] reachableStates, string tag)
	{
		this.ends ~= TaggedEnd(getStateId(reachableStates), tag);
	}


	StateId getStateId(StateIdNFA[] nfaIds...)
	{
		auto stateForTest = redBlackTree(nfaIds);
		foreach( StateId id, State state; states )
		{
			if( stateForTest == state ) return id;
		}
		assert(0, "dfa.getStateId - Id requested for nfaId array that does not exist yet");
	}


	State getState(StateId id)
	{
		return states[id];
	}


	string stateIdToString(StateId id)
	{
		import std.conv;
		string r = "";
		foreach(e; states[id])
		{
			r ~= to!string(e) ~ ",";
		}
		return "RBT[" ~ r ~ "]";
	}


	override
	string toString()
	{
		import std.conv;
		string r = "\n-- DFA.toString --";
		r ~= "\nStart @ " ~ to!string(start);
		foreach(StateId sourceStateId, StateId[char] charToTargetId; transitions)
		{

			foreach(letter, targetStateId; charToTargetId)
			{
				r ~= "\n" ~ stateIdToString(sourceStateId)
					~ " : " ~ letter
					~ " -> " ~ stateIdToString(targetStateId);
			}
		}

		r ~= "\nEnds:";
		foreach(TaggedEnd s; this.ends) r ~= "\n  " ~ stateIdToString(s.stateId);

		r ~= ("\n-- ============ --");
		return r;
	}


	bool isAcceptedEnd(StateId stateId)
	{
		foreach(TaggedEnd s; this.ends)
		{
			if(s.stateId == stateId)
			{
				return true;
			}
		}
		return false;
	}

	string getEndTag(StateId stateId)
	{
		foreach(TaggedEnd s; this.ends)
		{
			if(s.stateId == stateId)
			{
				return s.tag;
			}
		}
		assert(0);
	}


	struct Match
	{
		bool match;
		size_t count;
		string tag;

		bool opCast(T : bool)()
		{
			return match;
		}

		bool opEquals(size_t s)
		{
			return count == s;
		}

		bool opEquals(string s)
		{
			return match && tag == s;
		}
	}

	Match fullMatch(string text)
	{
		auto match = countPartialMatch(text);
		if(match.count == text.length) return match;
		else return Match(false,0,"");
	}

	Match countPartialMatch(string text)
	{
		size_t lastAccpetedAt = size_t.max; // mark for not found
		auto match = Match(false, size_t.max, "");

		StateId currentState = start;
		if( isAcceptedEnd(currentState) )
		{
			match.count = 0;
			match.match = true;
			match.tag = getEndTag(currentState);
		}

		foreach(size_t index, char c; text)
		{
			if( currentState !in transitions ) break;
			if( c !in transitions[currentState] ) break;
			currentState = transitions[currentState][c];

			// Mark possible success, but continue to find longest match
			if( isAcceptedEnd(currentState) )
			{
				match.count = index+1; // convert to 1-based
				match.match = true;
				match.tag = getEndTag(currentState);
			}
		}
		return match;

	}
}




unittest
{
	auto dfa = new DFA!(int)();

	dfa.addTransitionFromNFA([0], 'a', [1]);
	dfa.addTransitionFromNFA([1], 'b', [2]); // Already acceptable end
	dfa.addTransitionFromNFA([2], 'a', [1]); // Loop back

	dfa.start = dfa.getStateId(0);
	dfa.markEnd([2]);

	assert(!dfa.fullMatch(""));
	assert(!dfa.fullMatch("a"));
	assert(!dfa.fullMatch("b"));
	assert( dfa.fullMatch("ab"));
	assert(!dfa.fullMatch("aba"));
	assert( dfa.fullMatch("abab"));
	assert(!dfa.fullMatch("ababa"));
	assert( dfa.fullMatch("ababab"));

	assert( dfa.countPartialMatch("") == size_t.max);
	assert( dfa.countPartialMatch("a") == size_t.max);
	assert( dfa.countPartialMatch("b") == size_t.max);
	assert( dfa.countPartialMatch("ab") == 2);
	assert( dfa.countPartialMatch("aba") == 2);
	assert( dfa.countPartialMatch("abab") == 4);
	assert( dfa.countPartialMatch("ababa") == 4);
	assert( dfa.countPartialMatch("ababab") == 6);

	// test acceptability of empty string
	dfa.markEndTagged([0],"Tag");
	assert( dfa.fullMatch(""));
	assert(!dfa.fullMatch("a"));
	assert(!dfa.fullMatch("b"));
	assert(!dfa.fullMatch("aba"));
	assert( dfa.fullMatch("abab"));
	assert(!dfa.fullMatch("ababa"));
	assert( dfa.fullMatch("ababab"));


	assert( dfa.countPartialMatch("") == 0);
	assert( dfa.countPartialMatch("a") == 0);
	assert( dfa.countPartialMatch("b") == 0);
	assert( dfa.countPartialMatch("ab") == 2);
	assert( dfa.countPartialMatch("aba") == 2);
	assert( dfa.countPartialMatch("abab") == 4);
	assert( dfa.countPartialMatch("ababa") == 4);
	assert( dfa.countPartialMatch("ababab") == 6);

	// test string tags
	assert( dfa.fullMatch("")  == "Tag");
	assert( dfa.fullMatch("a") != "Tag"); // when no match, then no string will match the tag
	assert( dfa.fullMatch("b") != "");    // when no match, then no string will match the tag
	assert( dfa.fullMatch("aba") != "");
	assert( dfa.fullMatch("abab")  == ""); // when end had no tag, default value is empty string
	assert( dfa.fullMatch("ababa") != "");
	assert( dfa.fullMatch("ababab")  == ""); // when end had no tag, default value is empty string
}




bool exists(T)(T[] array, T element)
{
	foreach(T el; array)
	{
		if(el == element)
		{
			return true;
		}
	}
	return false;
}