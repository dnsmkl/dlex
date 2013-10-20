module regex_implementation.to_dfa;


import regex_implementation.nfa;
import regex_implementation.dfa;


import std.array:empty;



/* Get equivalent *deterministic* state mashine */
DFA!(NFA.StateId) toDfa(NFA nfa)
{
	auto dfa = new DFA!(NFA.StateId)(); // result builder

 	dfa.states ~= DFA!(NFA.StateId).makeState(nfa.starts);

	dfa.start = dfa.getStateId(nfa.starts);

	if(containsEnd(nfa.ends,nfa.starts)) dfa.ends ~= dfa.start;

	NFA.StateId[][] startingPoints = [nfa.starts];
	while(!empty(startingPoints))
	{
		NFA.StateId[][] newBatchOfStartingPoints;
		foreach(NFA.StateId[] searchFromNFAStateSet; startingPoints)
		{
			//for(char c; NFA.alphabet)
			//for(char c=0; c<256; c++)
			for(char c=96; c<99; c++)
			{
				NFA.StateId[] reachableStates = getReachableStatesForChar(nfa, searchFromNFAStateSet, c);
				if(!reachableStates.empty)
				{
					if(!dfa.isAlreadyObservedStateFromNFA(reachableStates))
					{
						newBatchOfStartingPoints ~= reachableStates;
					}
					auto newDFAState = DFA!(NFA.StateId).makeState(reachableStates);
					dfa.states ~= DFA!(NFA.StateId).makeState(reachableStates);
					if(containsEnd(nfa.ends,reachableStates)) dfa.ends ~= dfa.getStateId(reachableStates);
					dfa.addTransitionFromNFA(searchFromNFAStateSet, c, reachableStates);
				}
			}
		}
		startingPoints = newBatchOfStartingPoints;
	}

	return dfa;
}


NFA.StateId[] getReachableStatesForAlphabet(NFA nfa, NFA.StateId[] states)
{
	NFA.StateId[] r;
	foreach(letter; NFA.alphabet)
	{
		r ~= getReachableStatesForChar(nfa, states, letter);
	}
	return r;
}


NFA.StateId[] getReachableStatesForChar(NFA nfa, NFA.StateId[] stateIds, NFA.AlphaElement letter)
{
	NFA.StateId[] r;
	foreach(stateId; stateIds)
	{
		if(! (stateId in nfa.transitions) ) continue;

		if(letter in nfa.transitions[stateId])
		{
			r ~= nfa.transitions[stateId][letter];
		}
	}
	return r;
}


NFA.StateId[] dfaIdToNFAStates(DFA!(NFA.StateId) dfa, DFA!(NFA.StateId).StateId stateId)
{
	return dfaStateToNFAStates(dfa.getState(stateId));
}


NFA.StateId[] dfaStateToNFAStates(DFA!(NFA.StateId).State dfaState)
{
	NFA.StateId[] r;
	foreach(el; dfaState)
	{
		r ~= el;
	}
	return r;
}


version(none)
unittest
{
	import std.stdio;
	auto nfa = NFA('a','b');
	writeln( "-- ------------- --" );
	writeln(toDfa(nfa));
	writeln( "-- ------------- --" );
}


bool isEnd(T)(T[] endStateIds, T stateId)
{
	foreach(endStateId; endStateIds)
	{
		if(endStateId==stateId) return true;
	}
	return false;
}

bool containsEnd(T)(T[] endStateIds, T[] stateIds)
{
	foreach(stateId; stateIds)
	{
		if( isEnd(endStateIds, stateId) ) return true;
	}
	return false;
}