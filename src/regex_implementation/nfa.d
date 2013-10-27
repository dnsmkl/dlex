module regex_implementation.nfa;


import std.array;

/* Nondeterministic finate automaton */
/* PROPOSAL: it could be split up into NFA & NFALinearStream */
/* PROPOSAL: extract NFABuilder */
struct NFA
{
	alias char AlphaElement;
	alias size_t StateId;
	StateId[] states;
	StateId[] starts;
	alias string Tag;

	StateId[][AlphaElement][StateId] transitions;
	struct TaggedEnd{ StateId stateId; Tag tag; }
	//StateId[] ends;
	TaggedEnd[] ends;

	Tag endTag;

	StateId _state_used_recently_as_transition_target; // for conveniently building the NFA


	public static
	NFA createNFA(Tag endTag = Tag.init) // D does not allow default constructor for structs ( i.e. this() )
	{
		auto r=NFA();
		r.endTag = endTag;
		r.makeNewStartState();
		r.markAsEnd();
		return r;
	}


	this(AlphaElement[] alphaSequence, Tag endTag = Tag.init)
	{
		makeNewStartState();
		this.endTag = endTag;
		foreach(alpha; alphaSequence)
		{
			addTransitionToNew(alpha);
		}
		markAsEnd();
	}


	@property
	bool empty()
	{
		return states.length == 0;
	}


	void setEndTag(Tag endTag)
	{
		foreach(ref end; this.ends)
		{
			end.tag = endTag;
		}
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
		foreach(end; ends)
		{
			foreach(StateId start; starts)
			{
				foreach(letter, targets; transitions[start])
				{
					foreach(target; targets)
					{
						addTransitionToExisting(end.stateId, letter, target);
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
		foreach(end; this.ends)
		{
			foreach(otherStartStateId ; other.starts)
			{
				foreach(otherletter, otherTargets; other.transitions[otherStartStateId])
				{
					foreach(otherTargetStateId; otherTargets)
					{
						addTransitionToExisting(end.stateId, otherletter, otherTargetStateId+incrementNeeded);
					}
				}
			}
		}

		// redo ends : [this.ends] = [other.ends+incrementNeeded]
		this.ends = [];
		foreach(otherEnd; other.ends)
		{

			TaggedEnd tmp = otherEnd;
			tmp.stateId += incrementNeeded;
			tmp.tag = endTag; // when appending. Reuse `this.endTag`
			this.ends ~= tmp;
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
			TaggedEnd tmp = otherEnd;
			tmp.stateId += incrementNeeded;
			this.ends ~= tmp;
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
		auto newEnd = TaggedEnd(s, this.endTag);
		ends ~= newEnd;
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


	private
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
	auto nfaSeq1 = NFA(['a','b'], "TagEnd");
	nfaSeq1.makeRepeat();
	nfaSeq1.makeOptional(); 	// (ab)*

	auto nfaSeq2 = NFA(['a','b'], "TagEnd2");// (ab)

	nfaSeq1.append(nfaSeq2); 	// (ab)*(ab)


	import std.stdio;
	writeln( "\n" );
	writeln( "--------------------" );
	writeln( "-- NFA - unittest --" );
	writeln( "\n" );


	writeln( nfaSeq1 );

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