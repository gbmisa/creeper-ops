"""The idea deck: design lenses that `dream` draws to push ideation off the obvious path.

Sources: MDA aesthetics, Schell's lenses, Bartle types, SCAMPER, and common
post-mortem lessons. Each lens is one question; keep them short and sharp.
"""

LENSES = [
    # Aesthetics (MDA: what kind of fun?)
    ("sensation", "Sensation", "What would make this *feel* great in the hands and ears: impact, juice, sound?"),
    ("fantasy", "Fantasy", "What power fantasy or role is the player living out, and how could it be stronger?"),
    ("narrative", "Narrative", "What story emerges from play that the player would retell to a friend?"),
    ("challenge", "Challenge", "Where is the skill ceiling, and what new obstacle would raise it fairly?"),
    ("discovery", "Discovery", "What could the player find, uncover or learn that they didn't expect?"),
    ("expression", "Expression", "How could two players solve this differently and show their style?"),
    ("submission", "Flow", "What could the player do on autopilot that feels soothing, as relief between peaks?"),
    ("fellowship", "Fellowship", "What could be shared, compared or co-operated on, even asynchronously?"),
    # Players (Bartle-ish)
    ("achiever", "Achiever", "What goal, rank or completion target would an achiever chase here?"),
    ("explorer", "Explorer", "What secret or hidden mechanic would reward an explorer's curiosity?"),
    ("killer", "Dominator", "How can the player feel they *outplayed* the enemy, not out-ground it?"),
    # Structure and decisions
    ("decision", "Interesting decision", "Where is a choice with no dominant answer, and how can we create one?"),
    ("tradeoff", "Trade-off", "What does the player give up to gain this? If nothing, add a cost."),
    ("risk_reward", "Risk and reward", "Where can the player gamble for a bigger payoff?"),
    ("loop", "Core loop", "Which step of the core loop is weakest, and what would make it pull harder?"),
    ("pacing", "Pacing", "Where does the session sag or spike? What changes the tempo there?"),
    ("pressure", "Pressure", "How does the threat escalate so that standing still loses?"),
    ("comeback", "Comeback", "How can a losing player claw back without making winning pointless?"),
    ("emergence", "Emergence", "Which two existing systems could interact to create surprises nobody scripted?"),
    ("counterplay", "Counterplay", "For the strongest thing in the game, what is the counter, and is it fun?"),
    ("readability", "Readability", "Can a player see at a glance what is happening and why they lost?"),
    ("onboarding", "First five minutes", "What does a new player understand, feel and want in the first five minutes?"),
    ("mastery", "Mastery", "What does an expert do that a novice can't see yet?"),
    ("economy", "Economy", "Where do resources pile up or run dry, and what sink or faucet fixes it?"),
    ("enemy", "Enemy's view", "If the enemy were a player, what clever move would it make?"),
    ("spectacle", "Spectacle", "What moment would make a great 10-second clip or screenshot?"),
    ("meta", "Between sessions", "What makes the player want to start the next level or run?"),
    ("failure", "Failure as content", "How could losing be interesting, informative or even funny?"),
    ("space", "Space", "How could the level's shape (height, chokepoints, verticality) create new tactics?"),
    ("time", "Time", "What could change over time in a level: day/night, seasons, decay, reinforcements?"),
    ("scarcity", "Scarcity", "What could become rare so that the player must prioritise?"),
    ("identity", "Identity", "What makes this game unmistakably itself, and how can this idea amplify it?"),
    ("accessibility", "Accessibility", "Who can't play this right now, and what small change lets them?"),
    # Twists (SCAMPER)
    ("substitute", "Substitute", "Swap one element of an existing system for something unexpected."),
    ("combine", "Combine", "Merge two existing systems or units into one with a new twist."),
    ("adapt", "Adapt", "Borrow a mechanic from a different genre and bend it to fit."),
    ("magnify", "Magnify", "Take an existing mechanic and make it 10x bigger, longer or more extreme."),
    ("minify", "Minify", "Strip a system to its smallest fun version. What's left?"),
    ("repurpose", "Put to other use", "Use an existing tool, resource or enemy for a purpose it wasn't built for."),
    ("eliminate", "Eliminate", "Remove a rule or UI element. Does the game get better?"),
    ("reverse", "Reverse", "Flip roles or direction: defend becomes attack, the hunter becomes hunted."),
]

# Constraints keep dreamed ideas cheap and grounded. One is drawn per dream.
CONSTRAINTS = [
    "Must reuse existing systems and assets only (no new art).",
    "Must be buildable by one agent in one short brief.",
    "Must change a number or rule, not add a new system.",
    "May add exactly one new thing (unit, structure, enemy or tool).",
    "Must be testable headless with a sim or smoke check.",
    "Must make a weak or ignored option worth using.",
    "Must add a player decision, not just more content.",
    "No constraint: go big, but name the cheapest first slice.",
]


def by_id():
    return {lid: (name, q) for lid, name, q in LENSES}
