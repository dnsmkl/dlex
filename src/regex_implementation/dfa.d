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
	StateId[] ends;
	StateId[AlphaElement][StateId] transitions;


	this()
	{

	}



	bool isAlreadyObservedStateFromNFA(StateIdNFA[] nfaStates)
	{
		State potentialyNewState = makeState(nfaStates);
		return exists!State(this.states, potentialyNewState);
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



	//StateId getStateId(StateIdNFA[] nfaIds...)
	//{
	//	return getStateId(nfaIds);
	//}
	//StateId getStateId(StateIdNFA[] nfaIds)
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
		foreach(StateId s; ends) r ~= "\n  " ~ stateIdToString(s);

		r ~= ("\n-- ============ --");
		return r;
	}


	bool isAcceptedEnd(StateId stateId)
	{
		foreach(s;ends)
		{
			if(s == stateId)
			{
				return true;
			}
		}
		return false;
	}


	bool fullMatch(string text)
	{
		return countPartialMatch(text) == text.length;
	}

	size_t countPartialMatch(string text)
	{
		size_t lastAccpetedAt = size_t.max; // mark for not found

		StateId currentState = start;
		if( isAcceptedEnd(currentState) ) lastAccpetedAt = 0;

		foreach(size_t index, char c; text)
		{
			if( currentState !in transitions ) break;
			if( c !in transitions[currentState] ) break;
			currentState = transitions[currentState][c];

			// Mark possible success, but continue to find longest match
			if( isAcceptedEnd(currentState) ) lastAccpetedAt = index+1; // 1-based
		}
		return lastAccpetedAt;

	}
}




unittest
{
	auto dfa = new DFA!(int)();

	dfa.addTransitionFromNFA([0], 'a', [1]);
	dfa.addTransitionFromNFA([1], 'b', [2]); // Already acceptable end
	dfa.addTransitionFromNFA([2], 'a', [1]); // Loop back

	dfa.start = dfa.getStateId(0);
	dfa.ends = [dfa.getStateId(2)];

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
	dfa.ends = [dfa.getStateId(2),dfa.getStateId(0)];
	assert( dfa.fullMatch(""));
	assert( dfa.countPartialMatch("") == 0);
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