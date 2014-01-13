module dlex.regex.dfa;
/* Implement deterministic finite automaton (DFA)
	DFA is to be used for doing pattern matching */


import utils.exists;



/* DFA as Dumb data object.
	Used internaly in module dlex.to pass data between Builder and Mather */
private
struct DFA(
	TStateId = size_t
	, TTaggedEnd = TaggedEnd!(TStateId,Tag)
	, TTransitionMap = StateId[AlphaElement][TStateId]
)
{
	alias TStateId StateId;
	alias TTaggedEnd TaggedEnd;
	alias TTransitionMap TransitionMap;

	StateId start;
	TaggedEnd[] ends;
	TransitionMap transitions;
}



/* Needed in DFA during matching to denote accepted end state.
	Tag will be needed for lexing to determine, which regex succeeded.
	In case more then one regex can match, rank is used to determine the winner
	Lower rank wins */
private
struct TaggedEnd(StateId, TTag)
{
	alias TTag Tag;

	StateId stateId;
	Tag tag;
	uint rank;
}



/* Used in the Builder - handles state creation from set of NFA states.
	Each distinct set of NFA states is assigned a unique state id */
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



/* Routines for building the DFA */
public
struct Builder(
	StateIdNFA
	, Tag = string
	, AlphaElement = char
	, States = PowersetStates!StateIdNFA
	, StateId = size_t
	, TaggedEnd = TaggedEnd!(StateId,Tag)
	, TransitionMap = StateId[AlphaElement][StateId]
	, DFA = DFA!(StateId, TaggedEnd, TransitionMap)
	, Matcher = Matcher!(DFA)
)
{
	States states;
	DFA dfa;


	private
	bool isEnd(StateIdNFA[] nfaStates)
	{
		auto inStateId = states.getStateId(nfaStates);
		foreach(end; dfa.ends)
		{
			if(end.stateId == inStateId) return true;
		}
		return false;
	}


	// Building part
	public:
	bool isStateNew(StateIdNFA[] nfaStates)
	{
		return states.isStateNew(nfaStates);
	}

	void addTransition(StateIdNFA[] sourceNFA, AlphaElement letter, StateIdNFA[] targetNFA
		, bool lazyTransition = false)
	{
		states.addState(sourceNFA);
		states.addState(targetNFA);
		StateId source = states.getStateId(sourceNFA);
		StateId target = states.getStateId(targetNFA);
		bool lazyFromEnd = lazyTransition && isEnd(sourceNFA);
		if(!lazyFromEnd) this.dfa.transitions[source][letter] = target;
	}

	void markStart(StateIdNFA[] state)
	{
		states.addState(state);
		this.dfa.start = states.getStateId(state);
	}

	void markEnd(StateIdNFA[] state)
	{
		foreach(end; this.dfa.ends)
			if(end.stateId == states.getStateId(state)) return; // skip adding if already marked as end
		this.dfa.ends ~= TaggedEnd(states.getStateId(state), Tag.init, 0);
	}

	void markEndTagged(StateIdNFA[] state, Tag tag, uint rank)
	{
		states.addState(state);
		foreach(end; this.dfa.ends)
			if(end.stateId == states.getStateId(state)) return; // skip adding if already marked as end
		this.dfa.ends ~= TaggedEnd(states.getStateId(state), tag, rank);
	}


	// Output of the builder is matcher
	Matcher makeMatcher()
	{
		return Matcher(this.dfa);
	}


	// Debuging part
	string toString()
	{
		import std.conv;
		string r = "\n-- DFA.toString --";
		r ~= "\nStart @ " ~ to!string(this.dfa.start);
		foreach(StateId sourceStateId, StateId[char] charToTargetId; this.dfa.transitions)
		{

			foreach(letter, targetStateId; charToTargetId)
			{
				r ~= "\n" ~ states.stateIdToString(sourceStateId)
					~ " : " ~ letter
					~ " -> " ~ states.stateIdToString(targetStateId);
			}
		}

		r ~= "\nEnds:";
		foreach(TaggedEnd s; this.dfa.ends) r ~= "\n  " ~ states.stateIdToString(s.stateId);

		r ~= ("\n-- ============ --");
		return r;
	}
}



/* Routines for making matches using the DFA */
private
struct Matcher(
	DFA
	, Tag = DFA.TaggedEnd.Tag
	, TransitionMap = DFA.TransitionMap
)
{
	private:
	DFA dfa;


	void saveOnAccept(ref Match match, ref uint bestRank
		, size_t count, DFA.StateId currentState)
	{
		if( isAcceptedEnd(currentState, bestRank) )
		{
			match.count = count;
			match.match = true;
			match.tag = getEndTag(currentState);
			bestRank = getEndRank(currentState);
		}
	}

	bool isAcceptedEnd(DFA.StateId stateId, uint rankToBeat)
	{
		foreach(s; this.dfa.ends)
		{
			if(s.stateId == stateId && s.rank <= rankToBeat)
			{
				return true;
			}
		}
		return false;
	}

	auto getEndTag(DFA.StateId stateId)
	{
		foreach(s; this.dfa.ends)
		{
			if(s.stateId == stateId)
			{
				return s.tag;
			}
		}
		assert(0);
	}

	uint getEndRank(DFA.StateId stateId)
	{
		foreach(s; this.dfa.ends)
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

		DFA.StateId currentState = this.dfa.start;
		size_t count = 0; // number of characters that went into currentState

		saveOnAccept(match, bestRank, count, currentState);

		foreach(char c; text)
		{
			if( currentState !in this.dfa.transitions ) break;
			if( c !in this.dfa.transitions[currentState] ) break;
			currentState = this.dfa.transitions[currentState][c];
			++count;

			// Mark possible success, but continue to find longest match
			saveOnAccept(match,bestRank,count,currentState);
		}
		return match;
	}
}




unittest
{
	auto dfaBuilder = new Builder!(int,int)();

	dfaBuilder.addTransition([0], 'a', [1]);
	dfaBuilder.addTransition([1], 'b', [2]); // Already acceptable end
	dfaBuilder.addTransition([2], 'a', [1]); // Loop back

	dfaBuilder.markStart([0]);
	dfaBuilder.markEnd([2]);

	auto dfaMatcher1 = dfaBuilder.makeMatcher();

	assert( dfaMatcher1.partialMatch("") == size_t.max);
	assert( dfaMatcher1.partialMatch("a") == size_t.max);
	assert( dfaMatcher1.partialMatch("b") == size_t.max);
	assert( dfaMatcher1.partialMatch("ab") == 2);
	assert( dfaMatcher1.partialMatch("aba") == 2);
	assert( dfaMatcher1.partialMatch("abab") == 4);
	assert( dfaMatcher1.partialMatch("ababa") == 4);
	assert( dfaMatcher1.partialMatch("ababab") == 6);

	dfaBuilder.markEndTagged([0], 1, 0);
	auto dfaMatcher2 = dfaBuilder.makeMatcher();

	assert( dfaMatcher1.partialMatch("") == size_t.max);
	assert( dfaMatcher2.partialMatch("") == 0);
	assert( dfaMatcher2.partialMatch("a") == 0);
	assert( dfaMatcher2.partialMatch("b") == 0);
	assert( dfaMatcher2.partialMatch("ab") == 2);
	assert( dfaMatcher2.partialMatch("aba") == 2);
	assert( dfaMatcher2.partialMatch("abab") == 4);
	assert( dfaMatcher2.partialMatch("ababa") == 4);
	assert( dfaMatcher2.partialMatch("ababab") == 6);

	// Test that min rank wins
	auto dfaBuilder_test_minrank = new Builder!(int,int)();

	dfaBuilder_test_minrank.addTransition([0], 'a', [1]);
	dfaBuilder_test_minrank.addTransition([1], 'b', [2]);

	dfaBuilder_test_minrank.markStart([0]);
	dfaBuilder_test_minrank.markEndTagged([1],0,0);
	dfaBuilder_test_minrank.markEndTagged([2],1,1);

	auto dfaMatcher_test_minrank = dfaBuilder_test_minrank.makeMatcher();

	assert( !dfaMatcher_test_minrank.partialMatch("") );
	assert( dfaMatcher_test_minrank.partialMatch("aba").tag == 0);
}
