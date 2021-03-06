module dlex.regex.to_dfa;


import dlex.regex.nfa;
import dlex.regex.dfa;


import nostd.array:empty;



/* Get equivalent *deterministic* state mashine
	Returns dfa.Matcher */
auto toDfa(NFA nfa)
{
	auto dfaBuilder = Builder!(NFA.StateId)(); // result builder

	dfaBuilder.markStart(nfa.starts);
	transferEndsIfNeeded(nfa.starts, nfa.ends, dfaBuilder);

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
					if(dfaBuilder.isStateNew(reachableStates))
					{
						newBatchOfStartingPoints ~= reachableStates;
					}
					transferEndsIfNeeded(reachableStates, nfa.ends, dfaBuilder);
					auto allTranLazy = allTransitionsLazy(nfa.transitionLaziness, searchFromNFAStateSet, c, reachableStates);
					dfaBuilder.addTransition(searchFromNFAStateSet, c, reachableStates, allTranLazy);
				}

				if(c==char.max) break;
			}
		}
		startingPoints = newBatchOfStartingPoints;
	}

	return dfaBuilder.makeMatcher();
}

bool allTransitionsLazy(bool[NFA.StateId][NFA.AlphaElement][NFA.StateId] transitionLaziness
		,NFA.StateId[] sourceNFA, NFA.AlphaElement letter, NFA.StateId[] targetNFA)
{
	foreach(nfaSourceState; sourceNFA)
	{
		foreach(nfaTargetState; targetNFA)
		{
			if(nfaSourceState !in transitionLaziness) continue;
			if(letter !in transitionLaziness[nfaSourceState]) continue;
			assert(nfaTargetState in transitionLaziness[nfaSourceState][letter]);
			if(transitionLaziness[nfaSourceState][letter][nfaTargetState] == false) return false;
		}
	}
	return true;
}

void transferEndsIfNeeded(NFA.StateId[] reachableStates, NFA.TaggedEnd[] nfaEnds, ref Builder!(NFA.StateId) dfa )
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
	assert(!dfaSeq.partialMatch(""));
	assert(!dfaSeq.partialMatch("a"));
	assert( dfaSeq.partialMatch("ab"));
	assert( dfaSeq.partialMatch("aba"));
	assert( dfaSeq.partialMatch("abab"));

	assert( dfaSeq.partialMatch("").tag == "");
	assert( dfaSeq.partialMatch("a").tag == "");
	assert( dfaSeq.partialMatch("ab").tag == "TagSeq");
	assert( dfaSeq.partialMatch("aba").tag == "TagSeq");
	assert( dfaSeq.partialMatch("abab").tag == "TagSeq");
	assert( dfaSeq.partialMatch("ab").count == 2);
	assert( dfaSeq.partialMatch("aba").count == 2);
	assert( dfaSeq.partialMatch("abab").count == 4);

	nfa.addUnion(NFA(['b', 'b'], "TagUnion"));
	auto dfaUnion = toDfa(nfa);

	assert( dfaUnion.partialMatch("").tag == "");
	assert( dfaUnion.partialMatch("ab").tag == "TagSeq");
	assert( dfaUnion.partialMatch("bb").tag == "TagUnion");
	assert( dfaUnion.partialMatch("abab").tag == "TagSeq");

	nfa.addUnion(NFA(['b', 'b'], "TagOverlap")); // same NFA ('bb') unioned again with different tag
	auto dfaTestSame = toDfa(nfa);

	assert( dfaTestSame.partialMatch("").tag == "");
	assert( dfaTestSame.partialMatch("ab").tag == "TagSeq");
	assert( dfaTestSame.partialMatch("bb").tag == "TagUnion");
	assert( dfaTestSame.partialMatch("abab").tag == "TagSeq");

	auto testSetEndTag = NFA(['a','b','a']);
	testSetEndTag.setEndTag("testSetEndTag", 0);
	auto dfaTestSetEndTag = toDfa(testSetEndTag);

	assert( dfaTestSetEndTag.partialMatch("aba"));
	assert( dfaTestSetEndTag.partialMatch("aba").tag == "testSetEndTag");
}


unittest
{
	/* Test laziness */
	auto testNFA(bool laziness)
	{
		auto nfa = NFA(['a']);
		nfa.addUnion(NFA(['b']));

		// only following line depends on function paramter
		nfa.makeRepeat(laziness); //[ab]+?
		nfa.makeOptional();

		auto m = NFA(['b']);
		m.makeRepeat(); // b+
		nfa.append(m); // ([ab]*?)(b+)
		return nfa;
	}

	auto lazyDFA = toDfa(testNFA(true));
	assert(lazyDFA.partialMatch("aabbbaabb").count == 5);

	auto greedyDFA = toDfa(testNFA(false));
	assert(greedyDFA.partialMatch("aabbbaabb").count == 9);
}
