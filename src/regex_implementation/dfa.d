module regex_implementation.dfa;


private
struct PowersetStates(StateIdNFA)
{
	import std.container;
	alias RedBlackTree!(StateIdNFA) State;
	State[] states;
	alias size_t StateId;
	alias redBlackTree!(StateIdNFA) makeState;

	bool isStateNew(StateIdNFA[] nfaStates)
	{
		State potentialyNewState = makeState(nfaStates);
		return !exists!State(this.states, potentialyNewState);
	}


	void addState(StateIdNFA[] nfaStates)
	{
		State potentialyNewState = makeState(nfaStates);
		if(!exists!State(this.states, potentialyNewState)) states ~= potentialyNewState;
	}


	StateId getStateId(StateIdNFA[] nfaIds)
	{
		auto stateForTest = redBlackTree(nfaIds);
		foreach( StateId id, State state; states )
		{
			if( stateForTest == state ) return id;
		}
		assert(0, "dfa.getStateId - Id requested for nfaId array that does not exist yet");
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
}



/* Deterministic finate automaton - transformed from NFA */
class DFA(StateIdNFA, Tag = string, AlphaElement = char)
{
	alias size_t StateId;

	PowersetStates!StateIdNFA states;
	StateId start;

	struct TaggedEnd{ StateId stateId; Tag tag; uint rank; }
	TaggedEnd[] ends;
	StateId[AlphaElement][StateId] transitions;



	bool isStateNew(StateIdNFA[] nfaStates)
	{
		return states.isStateNew(nfaStates);
	}


	void addTransition(StateIdNFA[] sourceNFA, AlphaElement letter, StateIdNFA[] targetNFA)
	{
		states.addState(sourceNFA);
		states.addState(targetNFA);
		StateId source = states.getStateId(sourceNFA);
		StateId target = states.getStateId(targetNFA);
		transitions[source][letter] = target;
	}


	public
	void markStart(StateIdNFA[] state)
	{
		states.addState(state);
		this.start = states.getStateId(state);
	}

	public
	void markEnd(StateIdNFA[] state)
	{
		this.ends ~= TaggedEnd(states.getStateId(state), Tag.init, 0);
	}

	public
	void markEndTagged(StateIdNFA[] state, Tag tag, uint rank)
	{
		states.addState(state);
		this.ends ~= TaggedEnd(states.getStateId(state), tag, rank);
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
				r ~= "\n" ~ states.stateIdToString(sourceStateId)
					~ " : " ~ letter
					~ " -> " ~ states.stateIdToString(targetStateId);
			}
		}

		r ~= "\nEnds:";
		foreach(TaggedEnd s; this.ends) r ~= "\n  " ~ states.stateIdToString(s.stateId);

		r ~= ("\n-- ============ --");
		return r;
	}


	bool isAcceptedEnd(StateId stateId, uint rankToBeat)
	{
		foreach(TaggedEnd s; this.ends)
		{
			if(s.stateId == stateId && s.rank <= rankToBeat)
			{
				return true;
			}
		}
		return false;
	}

	Tag getEndTag(StateId stateId)
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

	uint getEndRank(StateId stateId)
	{
		foreach(TaggedEnd s; this.ends)
		{
			if(s.stateId == stateId)
			{
				return s.rank;
			}
		}
		assert(0);
	}


	struct Match
	{
		bool match;
		size_t count;
		Tag tag;

		bool opCast(T : bool)()
		{
			return match;
		}

		bool opEquals(size_t s)
		{
			return count == s;
		}
	}

	Match fullMatch(string text)
	{
		auto match = partialMatch(text);
		if(match.count == text.length) return match;
		else return Match(false,0,Tag.init);
	}

	Match partialMatch(string text)
	{
		size_t lastAccpetedAt = size_t.max; // mark for not found
		auto match = Match(false, size_t.max, Tag.init);
		uint bestRank = uint.max;

		StateId currentState = start;
		if( isAcceptedEnd(currentState, bestRank) )
		{
			match.count = 0;
			match.match = true;
			match.tag = getEndTag(currentState);
			bestRank = getEndRank(currentState);
		}

		foreach(size_t index, char c; text)
		{
			if( currentState !in transitions ) break;
			if( c !in transitions[currentState] ) break;
			currentState = transitions[currentState][c];

			// Mark possible success, but continue to find longest match
			if( isAcceptedEnd(currentState, bestRank) )
			{
				match.count = index+1; // convert to 1-based
				match.match = true;
				match.tag = getEndTag(currentState);
				bestRank = getEndRank(currentState);
			}
		}
		return match;

	}
}




unittest
{
	auto dfa = new DFA!(int,int)();

	dfa.addTransition([0], 'a', [1]);
	dfa.addTransition([1], 'b', [2]); // Already acceptable end
	dfa.addTransition([2], 'a', [1]); // Loop back

	dfa.markStart([0]);
	dfa.markEnd([2]);

	assert(!dfa.fullMatch(""));
	assert(!dfa.fullMatch("a"));
	assert(!dfa.fullMatch("b"));
	assert( dfa.fullMatch("ab"));
	assert(!dfa.fullMatch("aba"));
	assert( dfa.fullMatch("abab"));
	assert(!dfa.fullMatch("ababa"));
	assert( dfa.fullMatch("ababab"));

	assert( dfa.partialMatch("") == size_t.max);
	assert( dfa.partialMatch("a") == size_t.max);
	assert( dfa.partialMatch("b") == size_t.max);
	assert( dfa.partialMatch("ab") == 2);
	assert( dfa.partialMatch("aba") == 2);
	assert( dfa.partialMatch("abab") == 4);
	assert( dfa.partialMatch("ababa") == 4);
	assert( dfa.partialMatch("ababab") == 6);

	// test acceptability of empty string
	dfa.markEndTagged([0], 1, 0);
	assert( dfa.fullMatch(""));
	assert(!dfa.fullMatch("a"));
	assert(!dfa.fullMatch("b"));
	assert(!dfa.fullMatch("aba"));
	assert( dfa.fullMatch("abab"));
	assert(!dfa.fullMatch("ababa"));
	assert( dfa.fullMatch("ababab"));


	assert( dfa.partialMatch("") == 0);
	assert( dfa.partialMatch("a") == 0);
	assert( dfa.partialMatch("b") == 0);
	assert( dfa.partialMatch("ab") == 2);
	assert( dfa.partialMatch("aba") == 2);
	assert( dfa.partialMatch("abab") == 4);
	assert( dfa.partialMatch("ababa") == 4);
	assert( dfa.partialMatch("ababab") == 6);

	// test string tags
	assert( dfa.fullMatch("").tag  == 1);
	assert( dfa.fullMatch("a").tag != 1);
	assert( dfa.fullMatch("b").tag == 0);
	assert( dfa.fullMatch("aba").tag == 0);
	assert( dfa.fullMatch("abab").tag  == 0);
	assert( dfa.fullMatch("ababa").tag == 0);
	assert( dfa.fullMatch("ababab").tag  == 0);


	// Test that min rank wins
	auto dfa_test_minrank = new DFA!(int,int)();

	dfa_test_minrank.addTransition([0], 'a', [1]);
	dfa_test_minrank.addTransition([1], 'b', [2]);

	dfa_test_minrank.markStart([0]);
	dfa_test_minrank.markEndTagged([1],0,0);
	dfa_test_minrank.markEndTagged([2],1,1);

	assert( !dfa_test_minrank.partialMatch("") );
	assert( dfa_test_minrank.partialMatch("aba").tag == 0);
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