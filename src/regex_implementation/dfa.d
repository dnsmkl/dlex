module regex_implementation.dfa;


private
struct PowersetStates(StateIdNFA)
{
	private:
	import std.container: RedBlackTree,redBlackTree;
	alias redBlackTree!(StateIdNFA) makeState;
	alias RedBlackTree!(StateIdNFA) State;

	State[] states;
	alias size_t StateId;


	// Building part
	public:
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


	// Retrieval of generated ids
	public:
	StateId getStateId(StateIdNFA[] nfaIds)
	{
		auto stateForTest = redBlackTree(nfaIds);
		foreach( StateId id, State state; states )
		{
			if( stateForTest == state ) return id;
		}
		assert(0, "dfa.getStateId - Id requested for nfaId array that does not exist yet");
	}


	// Debuging
	public:
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



private
struct TaggedEnd(StateId,Tag)
{
	StateId stateId;
	Tag tag;
	uint rank;
}



/* Deterministic finate automaton - transformed from NFA */
public
struct DFA(
	StateIdNFA
	, Tag = string
	, AlphaElement = char
	, States = PowersetStates!StateIdNFA
	, StateId = size_t
	, TaggedEnd = TaggedEnd!(StateId,Tag)
	, TransitionMap = StateId[AlphaElement][StateId]
	, Matcher = Matcher!(StateId, Tag, TaggedEnd, TransitionMap)
)
{
	States states;

	StateId start;
	TaggedEnd[] ends;
	TransitionMap transitions;


	// Building part
	public:
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

	void markStart(StateIdNFA[] state)
	{
		states.addState(state);
		this.start = states.getStateId(state);
	}

	void markEnd(StateIdNFA[] state)
	{
		this.ends ~= TaggedEnd(states.getStateId(state), Tag.init, 0);
	}

	void markEndTagged(StateIdNFA[] state, Tag tag, uint rank)
	{
		states.addState(state);
		this.ends ~= TaggedEnd(states.getStateId(state), tag, rank);
	}


	// Debuging part
	public:
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


	// Matching part
	private:
	Matcher matcher;
	bool matcherReady=false;

	void initMatcher()
	{
		if(!matcherReady) this.matcher = Matcher(start, ends, transitions);
	}

	public:
	auto partialMatch(string text)
	{
		initMatcher();
		return matcher.partialMatch(text);
	}
}



private
struct Matcher(StateId, Tag, TaggedEnd, TransitionMap)
{
	private:
	StateId start;
	TaggedEnd[] ends;
	TransitionMap transitions;


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


	public:
	Match partialMatch(string text)
	{
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

	assert( dfa.partialMatch("") == 0);
	assert( dfa.partialMatch("a") == 0);
	assert( dfa.partialMatch("b") == 0);
	assert( dfa.partialMatch("ab") == 2);
	assert( dfa.partialMatch("aba") == 2);
	assert( dfa.partialMatch("abab") == 4);
	assert( dfa.partialMatch("ababa") == 4);
	assert( dfa.partialMatch("ababab") == 6);

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
