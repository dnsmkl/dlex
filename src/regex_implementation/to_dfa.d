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

	transferEndsIfNeeded(nfa.starts, nfa.ends, dfa);

	// 'starting' as in 'Single transition is from start to finish'
	NFA.StateId[][] startingPoints = [nfa.starts];
	while(!empty(startingPoints))
	{
		NFA.StateId[][] newBatchOfStartingPoints;
		foreach(NFA.StateId[] searchFromNFAStateSet; startingPoints)
		{
			// loop through all possible bytes
			for(char c=0; ; ++c) // exit condition moved to the end
			{
				NFA.StateId[] reachableStates = getReachableStatesForChar(nfa, searchFromNFAStateSet, c);
				if(!reachableStates.empty)
				{
					if(dfa.isDFAStateNewFromNFA(reachableStates))
					{
						newBatchOfStartingPoints ~= reachableStates;
					}
					auto newDFAState = DFA!(NFA.StateId).makeState(reachableStates);
					dfa.states ~= DFA!(NFA.StateId).makeState(reachableStates);
					transferEndsIfNeeded(reachableStates, nfa.ends, dfa);
					dfa.addTransitionFromNFA(searchFromNFAStateSet, c, reachableStates);
				}

				if(c==char.max) break;
			}
		}
		startingPoints = newBatchOfStartingPoints;
	}

	return dfa;
}

void transferEndsIfNeeded(NFA.StateId[] reachableStates, NFA.TaggedEnd[] nfaEnds, ref DFA!(NFA.StateId) dfa )
{
	if(containsEnd(nfaEnds, reachableStates))
	{
		auto end = whichEnd(nfaEnds, reachableStates);
		dfa.markEndTagged(reachableStates, end.tag);
	}
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




bool isEnd(T, U)(T[] endStates, U stateId)
{
	foreach(endState; endStates)
	{
		if(endState.stateId == stateId) return true;
	}
	return false;
}

bool containsEnd(T, U)(T[] endStates, U[] stateIds)
{
	foreach(stateId; stateIds)
	{
		if( isEnd(endStates, stateId) ) return true;
	}
	return false;
}



T whichEnd(T, U)(T[] endStates, U[] stateIds)
{
	foreach(stateId; stateIds)
	{
		foreach(endState; endStates)
		{
			if(endState.stateId == stateId) return endState;
		}
	}
	assert(0, "End not found - call containsEnd() first");
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
