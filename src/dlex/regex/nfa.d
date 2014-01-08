module dlex.regex.nfa;


import utils.exists;
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
	bool[StateId][AlphaElement][StateId] transitionLaziness;

	struct TaggedEnd{ StateId stateId; Tag tag; uint rank; }
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


	void setEndTag(Tag endTag, uint rank)
	{
		foreach(ref end; this.ends)
		{
			end.tag = endTag;
			end.rank = rank;
		}
	}


	void makeOptional(bool laziness = false)
	{
		/* mark each start as end */
		foreach(start;starts)
		{
			markAsEnd(start);
			foreach(bool[StateId] targetLaziness; transitionLaziness[start])
				foreach(bool l; targetLaziness) l = laziness;

		}
	}

	void makeRepeat(bool laziness = false)
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
						transitionLaziness[end.stateId][letter][target] = laziness;
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
						addTransitionToExisting(otherFromStateId+incrementNeeded, otherLetter, otherTargetStateId+incrementNeeded
							,other.transitionLaziness[otherFromStateId][otherLetter][otherTargetStateId]);
					}
				}
			}
		}
	}

	/* Union of NFA. Modify 'this', do not modify 'other'. */
	void addUnion(NFA other)
	{
		// in case this is empty, just copy everything from other
		if(this.states.length == 1 && this.transitions.length == 0)
		{
				this.states = other.states;
				this.starts = other.starts;
				this.ends = other.ends;
				this.transitions = other.transitions;
				this.transitionLaziness = other.transitionLaziness;
				return;
		}

		// in case both are simple, keep also result simple
		if(this.states.length == 2
			&& other.states.length == 2
			&& this.transitions.length == 1
			&& other.transitions.length == 1
			&& this.ends.length == 1
			&& other.ends.length == 1)
		{

			foreach(otherLetter,trg; other.transitions[other.starts[0]])
				addTransitionToExisting(this.starts[0], otherLetter, this.ends[0].stateId);
			return;
		}


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
	StateId addTransitionToNew(StateId fromState, AlphaElement alpha
			, bool laziness = false)
	{
		auto newState = getNewState();
		if( !(fromState in transitions) )
		{
			transitions[fromState] = [alpha:[newState]];
			transitionLaziness[fromState][alpha][newState] = laziness;
		}
		else if( !(alpha in transitions[fromState]) )
		{
			transitions[fromState][alpha] = [newState];
			transitionLaziness[fromState][alpha][newState] = laziness;
		}
		else
		{
			transitions[fromState][alpha] ~= newState;
			transitionLaziness[fromState][alpha][newState] = laziness;
		}

		_state_used_recently_as_transition_target = newState;
		return newState;
	}


	private
	void addTransitionToExisting(StateId fromState, AlphaElement alpha, StateId toState
			, bool laziness = false)
	{
		if( !(fromState in transitions) )
		{
			transitions[fromState] = [alpha:[toState]];
			transitionLaziness[fromState][alpha][toState] = laziness;
		}
		else if( !(alpha in transitions[fromState]) )
		{
			transitions[fromState][alpha] = [toState];
			transitionLaziness[fromState][alpha][toState] = laziness;
		}
		else
		{
			transitions[fromState][alpha] ~= toState;
			transitionLaziness[fromState][alpha][toState] = laziness;
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
					foreach(target; targets)
					{
						r ~= "\t"
							~ to!string(stateId)
							~ " | "
							~ letter
							~ (transitionLaziness[stateId][letter][target] ? " -?" : " ")
							~ "-> "
							~ to!string(target)
							~ "\n";
					}
				}
			}
		}
		return r[0 .. r.length-1];
	}
}


version(none)
unittest
{
	auto n = NFA(['a']);
	n.addUnion(NFA(['b'])); //[ab]
	n.makeRepeat(true); //[ab]+?

	auto m = NFA(['b']);
	m.makeRepeat(); // b+

	n.append(m) ; // ([ab]+?)(b+)

	import std.stdio;
	writeln( n );
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
