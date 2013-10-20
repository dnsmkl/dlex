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


	bool checkWord(string text)
	{
		StateId currentState = start;
		int i;// in case of blow-up
		foreach(char c; text)
		{
			if( currentState !in transitions ) return false;
			if( c !in transitions[currentState] ) return false;
			currentState = transitions[currentState][c];
		}
		return isAcceptedEnd(currentState);
	}

	size_t countPartialMatch(string text)
	{
		size_t lastAccpetedAt = 0;

		StateId currentState = start;
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



//version(none)
unittest
{
	import std.stdio;
	import regex_implementation.nfa;
	auto dfa = new DFA!(NFA.StateId)();

	dfa.addTransitionFromNFA([1,3], 'a', [2,4]);
	dfa.addTransitionFromNFA([2,4], 'b', [3,5]);
	dfa.addTransitionFromNFA([3,5], 'a', [2,4]);

	dfa.start = dfa.getStateId(1,3);
	dfa.ends = [dfa.getStateId(3,5)];

	void testWord(string word){
		writeln("\n\ndfa.checkWord(\"" ~ word ~ "\")");
		writeln(dfa.checkWord(word));
	}

	writeln(" DFA DFA ");
	writeln(dfa);

	testWord("a");
	testWord("b");
	testWord("ab");
	testWord("aba");
	testWord("abab");
	testWord("ababa");
	testWord("ababab");


	void testPartialMatch(string word){
		writeln("\n\ndfa.countPartialMatch(\"" ~ word ~ "\")");
		writeln(dfa.countPartialMatch(word));
	}

	testPartialMatch("a");
	testPartialMatch("b");
	testPartialMatch("ab");
	testPartialMatch("aba");
	testPartialMatch("abab");
	testPartialMatch("ababa");
	testPartialMatch("ababab");
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