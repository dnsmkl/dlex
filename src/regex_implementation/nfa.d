module regex_implementation.nfa;


import std.array;

/* Nondeterministic finate automaton */
/* PROPOSAL: it could be split up into NFA & NFALinearStream */
struct NFA
{
	alias char AlphaElement;
	immutable AlphaElement[] alphabet
//		= ['a','b'];
		= ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','|'];
	alias size_t StateId;
	StateId[] states;
	StateId[] starts;
	StateId[] ends;

	StateId[][AlphaElement][StateId] transitions;



	StateId _state_used_recently_as_transition_target; // for conveniently building the NFA


	public static
	NFA createNFA()
	{
		auto r=NFA();
		r.makeNewStartState();
		r.markAsEnd();
		return r;
	}


	this(AlphaElement[] alphaSequence...)
	{
		makeNewStartState();
		foreach(alpha; alphaSequence)
		{
			addTransitionToNew(alpha);
		}
		markAsEnd();
	}



	void makeOptional()
	{
		/* mark each start as end */
		foreach(start;starts)
		{
			markAsEnd(start);
		}
	}


	void makeRepeat()
	{
		/* Make ends point to targets of starts */
		foreach(StateId end; ends)
		{
			foreach(StateId start; starts)
			{
				foreach(letter, targets; transitions[start])
				{
					foreach(target; targets)
					{
						addTransitionToExisting(end, letter, target);
					}
				}
			}
		}
	}


	/* Concatenation of NFA. Modify 'this', do not modify 'other'. */
	void append(NFA other)
	{
		auto incrementNeeded = states.length-1;

		// append states
		foreach(otherStateId; other.states)
		{
			if(otherStateId!=0) getNewState(); // create 1 state less, then exists in other, because starting states will be replaced by this.ends
		}

		// all transitions, that pointed to [this.ends] should connect to [other.starts] targets
		foreach(thisEndStateId; this.ends)
		{
			foreach(otherStartStateId ; other.starts)
			{
				foreach(otherletter, otherTargets; other.transitions[otherStartStateId])
				{
					foreach(otherTargetStateId; otherTargets)
					{
						addTransitionToExisting(thisEndStateId, otherletter, otherTargetStateId+incrementNeeded);
					}
				}
			}
		}

		// redo ends - [this.ends] = [other.ends+incrementNeeded]
		this.ends = [];
		foreach(otherEnd; other.ends)
		{
			this.ends ~= otherEnd+incrementNeeded;
		}


		// copy all transitions (except from starts these transitions were already merged with this.ends)
		foreach(otherFromStateId, transitionsFromState; other.transitions)
		{
			if(!exists(other.starts,otherFromStateId))
			{
				foreach(otherLetter, otherTargets ; transitionsFromState)
				{
					foreach(otherTargetStateId; otherTargets)
					{
						addTransitionToExisting(otherFromStateId+incrementNeeded, otherLetter, otherTargetStateId+incrementNeeded);
					}
				}
			}
		}
	}

	/* Union of NFA. Modify 'this', do not modify 'other'. */
	void addUnion(NFA other)
	{
		auto incrementNeeded = states.length-1;

		// append states
		foreach(otherStateId; other.states)
		{
			if(otherStateId!=0) getNewState(); // create 1 state less, then exists in other, because starting states will be replaced by this.ends
		}

		// all transitions, that are pointed by [other.starts] should  now be poitned from [this.starts]
		foreach(otherStartId; other.starts)
		{
			if(otherStartId in other.transitions)
			{
				foreach(otherLetter, otherTargets; other.transitions[otherStartId])
				{
					foreach(otherTarget; otherTargets)
					{
						foreach(thisStartId; this.starts)
						{
							addTransitionToExisting(thisStartId, otherLetter, otherTarget+incrementNeeded);
						}
					}
				}
			}
		}

		// append ends : [this.ends] =  [this.ends] ~ [other.ends+incrementNeeded]
		foreach(otherEnd; other.ends)
		{
			this.ends ~= otherEnd+incrementNeeded;
		}


		// copy all transitions (except from starts these transitions were already merged with this.starts)
		foreach(otherFromStateId, transitionsFromState; other.transitions)
		{
			if(!exists(other.starts,otherFromStateId))
			{
				foreach(otherLetter, otherTargets ; transitionsFromState)
				{
					foreach(otherTargetStateId; otherTargets)
					{
						addTransitionToExisting(otherFromStateId+incrementNeeded, otherLetter, otherTargetStateId+incrementNeeded);
					}
				}
			}
		}
	}





	private
	StateId getNewState()
	{
		states ~= states.length; // just enumerate states
		return states[states.length-1];
	}


	private
	void makeNewStartState()
	{
		auto newState = getNewState();
		starts ~= newState;
		_state_used_recently_as_transition_target = newState;
	}


	private
	void markAsEnd()
	{
		markAsEnd(_state_used_recently_as_transition_target);
	}
	void markAsEnd(StateId s)
	{
		ends ~= s;
	}


	private
	StateId addTransitionToNew(AlphaElement alpha)
	{
		auto newState = addTransitionToNew(_state_used_recently_as_transition_target, alpha);
		return newState;
	}


	private
	StateId addTransitionToNew(StateId fromState, AlphaElement alpha)
	{
		auto newState = getNewState();
		if( !(fromState in transitions) )
		{
			transitions[fromState] = [alpha:[newState]];
		}
		else if( !(alpha in transitions[fromState]) )
		{
			transitions[fromState][alpha] = [newState];
		}
		else
		{
			transitions[fromState][alpha] ~= newState;
		}

		_state_used_recently_as_transition_target = newState;
		return newState;
	}


	void addTransitionToExisting(StateId fromState, AlphaElement alpha, StateId toState)
	{
		if( !(fromState in transitions) )
		{
			transitions[fromState] = [alpha:[toState]];
		}
		else if( !(alpha in transitions[fromState]) )
		{
			transitions[fromState][alpha] = [toState];
		}
		else
		{
			transitions[fromState][alpha] ~= toState;
		}

		_state_used_recently_as_transition_target = toState;
	}




	string toString()
	{
		import std.conv:to;
		return "NFA-start: " ~ to!string(starts)
			~ "\nNFA-transitions:\n" ~ transitionsToString()
			~ "\nNFA-end:   " ~ to!string(ends);
	}

	private
	string transitionsToString()
	{
		import std.conv:to;
		string r;
		foreach(StateId stateId; states)
		{
			if(stateId in transitions)
			{
				foreach(AlphaElement letter, StateId[] targets; transitions[stateId])
				{
					r ~= "\t"
						~ to!string(stateId)
						~ " | "
						~ letter
						~ " -> "
						~ to!string(targets)
						~ "\n";
				}
			}
		}
		return r[0 .. r.length-1];
	}
}
version(none)
unittest
{
	auto nfaSeq1 = NFA('a','b');
	nfaSeq1.makeRepeat();
	nfaSeq1.makeOptional(); 	// (ab)*

	auto nfaSeq2 = NFA('a','b');// (ab)

	nfaSeq1.append(nfaSeq2); 	// (ab)*(ab)



	auto nfaUnion = NFA('a','c');
	nfaUnion.addUnion(NFA('b'));


	auto nfaUnion2 = NFA('a','b');
	nfaUnion2.makeRepeat();
	nfaUnion2.makeOptional();

	nfaUnion2.addUnion(nfaSeq2);

	import std.stdio;
	writeln( "\n" );
	writeln( "--------------------" );
	writeln( "-- NFA - unittest --" );
	writeln( "\n" );


	writeln( nfaUnion2 );

	writeln( "\n" );
	writeln( "-- NFA - unittest --" );
	writeln( "--------------------" );
	writeln( "\n" );
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