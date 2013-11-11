module regex_implementation.to_dfa;


import regex_implementation.nfa;
import regex_implementation.dfa;


import std.array:empty;



/* Get equivalent *deterministic* state mashine */
DFA!(NFA.StateId) toDfa(NFA nfa)
{
	auto dfa = new DFA!(NFA.StateId)(); // result builder

 	dfa.addStateFromNFA(nfa.starts);

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
					dfa.addStateFromNFA(reachableStates);
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
		dfa.markEndTagged(reachableStates, end.tag, end.rank);
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





unittest
{
	auto nfa = NFA(['a','b'], "TagSeq");
	nfa.makeRepeat();
	nfa.makeOptional();       // (ab)*
	nfa.append(NFA(['a','b'])); // (ab)*(ab)

	auto dfaSeq = toDfa(nfa);
	assert(!dfaSeq.fullMatch(""));
	assert(!dfaSeq.fullMatch("a"));
	assert( dfaSeq.fullMatch("ab"));
	assert(!dfaSeq.fullMatch("aba"));
	assert( dfaSeq.fullMatch("abab"));

	assert( dfaSeq.fullMatch("").tag == "");
	assert( dfaSeq.fullMatch("a").tag == "");
	assert( dfaSeq.fullMatch("ab").tag == "TagSeq");
	assert( dfaSeq.fullMatch("aba").tag == "");
	assert( dfaSeq.fullMatch("abab").tag == "TagSeq");

	nfa.addUnion(NFA(['b', 'b'], "TagUnion"));
	auto dfaUnion = toDfa(nfa);

	assert( dfaUnion.fullMatch("").tag == "");
	assert( dfaUnion.fullMatch("ab").tag == "TagSeq");
	assert( dfaUnion.fullMatch("bb").tag == "TagUnion");
	assert( dfaUnion.fullMatch("abab").tag == "TagSeq");

	nfa.addUnion(NFA(['b', 'b'], "TagOverlap")); // same NFA ('bb') unioned again with different tag
	auto dfaTestSame = toDfa(nfa);

	assert( dfaTestSame.fullMatch("").tag == "");
	assert( dfaTestSame.fullMatch("ab").tag == "TagSeq");
	assert( dfaTestSame.fullMatch("bb").tag == "TagUnion");
	assert( dfaTestSame.fullMatch("abab").tag == "TagSeq");

	auto testSetEndTag = NFA(['a','b','a']);
	testSetEndTag.setEndTag("testSetEndTag", 0);
	auto dfaTestSetEndTag = toDfa(testSetEndTag);

	assert( dfaTestSetEndTag.fullMatch("aba"));
	assert( dfaTestSetEndTag.fullMatch("aba").tag == "testSetEndTag");
}
