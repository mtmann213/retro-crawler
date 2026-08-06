# Retro Crawler Roadmap Review and Planning Recommendations

> **Status basis:** Retro Crawler Project Handbook snapshot dated August 2, 2026
> **Purpose:** Review the upcoming milestones, identify sequencing and dependency risks, and define additional planning work needed before the project expands further.

---

## 1. Executive Assessment

The current roadmap is strong and unusually disciplined for a project that has expanded from a focused vertical slice into a larger deterministic, generative RPG.

The project’s core architectural choices still support the larger vision:

- Deterministic, seed-driven gameplay
- Authored content combined with procedural assembly
- Pure validation of generated structures
- Offline-first game rules
- Optional AI limited to presentation-level output
- A preserved authored Service Level as a regression fixture
- Clear separation of rules, runtime state, presentation, content, and persistence

The largest near-term concern is that **Milestone 21 currently contains too many major design and implementation problems under one heading**. It includes generated combat, physical encounter contacts, progression gates, resource and discovery interactions, hazards, objective resolution, expedition pressure, player-state continuity, extraction, failure, and rewards.

Each of those systems could work individually while the complete generated expedition still feels directionless, unrewarding, or unfair.

The second concern is that several major design decisions are scheduled to be resolved at the same time they must be implemented. The project should add explicit design gates before those decisions become embedded in combat, generation, persistence, the Wayfarer, or future story systems.

---

# 2. Feedback on Upcoming Milestones

## Milestone 20 — Walkable Generated Deployment

### Current purpose

Milestone 20 proves that an abstract, validated `ExpeditionPlan` can become a readable, walkable physical environment using the production movement and rendering stack.

That is the correct scope. It should remain a traversal and layout validation milestone rather than expanding into combat or interaction systems before the owner playtest.

### Recommended playtest observations

In addition to checking traversal, clipping, focus, controller behavior, and objective recognition, record the following:

- How often the player needs to consult the contract graph
- Whether previously visited corridors and sectors are recognizable
- Whether optional branches visibly feel optional
- Whether the objective sector feels like a destination
- Whether the player understands the critical route
- Whether room and corridor dimensions feel sufficiently varied
- Whether backtracking feels acceptable
- Whether long empty traversal sections occur
- Whether Mox blocks, overlaps, distracts, or disappears
- Whether the player can form a mental map without combat or content
- Whether the generated deployment feels like a place rather than a technical graph visualization

The current builder guarantees valid bounds, no room overlap, deterministic placement, and a valid `WorldLayoutDefinition`. These are necessary structural guarantees, but they do not prove that the layout is readable or enjoyable.

### Recommended addition: Milestone 20.5

Add a small consolidation milestone before beginning generated gameplay.

## Milestone 20.5 — Consolidation and Traversal Polish

### Goals

- Resolve findings from the owner F5 playtest
- Commit and publish Milestone 20 after explicit approval
- Consolidate the stacked milestone branches
- Establish the generated-expedition screen as a stable baseline
- Add navigation metrics or debug overlays needed for later testing
- Re-run viewport, focus, and controller checks after consolidation
- Confirm the full automated suite remains green

### Why this matters

Beginning generated combat and persistence while the repository remains on a long stacked branch chain will make review, rollback, regression isolation, and collaboration increasingly difficult.

---

## Milestone 21 — Generated Expedition Gameplay Loop

This is the most important milestone since the original Service Level.

It must answer:

> Is a generated contract actually fun to complete, or is it merely a valid map containing familiar systems?

The milestone should be divided internally into two deliverables.

---

## Milestone 21A — Generated Encounters and Progression Gates

### Scope

- Map generated encounter-sector roles to deterministic combat configurations
- Add visible hostile contacts
- Reuse proximity-based combat initiation
- Carry player HP, resources, equipment, and class state into combat
- Return the player to the correct generated sector after combat
- Lock and unlock progression routes based on encounter completion
- Track cleared encounters
- Preserve deterministic results from the contract seed and command sequence
- Verify Mox movement and presentation around generated hostiles

### Exit test

> The player can deploy, fight through one generated critical route, and reach the objective sector without final objective interactions, save support, or contract rewards.

### Why isolate this work

This proves that the authored combat system transfers cleanly into generated spaces without simultaneously debugging objective rules, hazards, rewards, extraction, save state, and failure behavior.

---

## Milestone 21B — Contract Interactions and Resolution

### Scope

- Resource-sector interactions
- Discovery-sector interactions
- Hazard-sector interactions
- Objective interaction
- Extraction behavior
- Contract success
- Contract failure
- Contract abandonment
- Deterministic loot and experience
- Return-to-Wayfarer summary
- Clear post-contract state
- Contract pressure or clock behavior

### Exit test

> One generated contract has a complete beginning, middle, and end and leaves the player in a valid post-expedition state.

### Do not include yet

- Online or local AI dialogue
- Large story-generation systems
- Complex base upgrades
- Multiple persistent regions
- Broad campaign progression
- Full class specialization
- Large equipment expansion

First prove that one generated contract is fun, understandable, and completable.

---

# 3. Decisions Required Before Milestone 21

The following decisions should be documented before implementation begins.

## 3.1 Expedition Pressure Model

Choose the initial pressure model:

1. A fresh deterministic clock for every contract
2. A resource budget such as supply, exposure, or stability
3. Objective-specific pressure
4. No pressure during the first generated-loop prototype

### Recommendation

Use a **fresh deterministic contract clock** for the first implementation because:

- The Service Level already proves the concept
- The player already understands time costs
- It is easy to preview and test
- It reinforces route and optional-branch decisions
- It does not punish reading or menu navigation

However, do not reuse the Service Level’s exact twelve-minute budget for every expedition.

Calculate the initial budget from the generated plan:

```text
Contract Time =
    Base Allowance
    + Critical Route Allowance
    + Optional Branch Allowance
    + Objective Allowance
    + Difficulty Modifier
```

The generated plan already knows route length, optional-room count, encounter density, and objective type. Those values should inform the pressure budget.

### Required simulations

Test multiple seeds and player behaviors:

- Critical-route-only completion
- All optional branches
- One failed or fled encounter
- One rest or recovery action
- Slow but reasonable menu use
- Multiple classes
- Low and high encounter density

---

## 3.2 Contract State Model

Define exact contract states before coding.

Recommended state model:

```text
Offered
Accepted
Deployed
Objective Available
Objective Completed
Extraction Available
Extracted Successfully
Failed
Abandoned
Recorded
```

For each state, define:

- Valid transitions
- Available player actions
- Save eligibility
- Reward eligibility
- Whether the contract can be resumed
- Whether the contract remains visible on the Wayfarer
- Whether the location can later be revisited

This will prevent ambiguity in Milestones 21–24.

---

## 3.3 Failure and Checkpoint Model

The current direction favors checkpoint recovery, but the exact penalty and retry boundary remain undecided.

### Recommended first implementation

- Autosave at deployment
- Autosave after cleared encounters
- Autosave after major objective progress
- Failure reloads the latest contract checkpoint
- The contract seed remains unchanged
- No permanent item or equipment loss
- Rewards earned after the checkpoint are reverted
- Cleared encounters before the checkpoint remain cleared
- The player can abandon the contract from a checkpoint
- Failure never corrupts or invalidates the main profile

This is simple enough to test while leaving room for a later final death economy.

---

## 3.4 Mox’s Initial Mechanical Role

The project should decide Mox’s gameplay category before generated interactions and hazards are implemented.

### Recommendation

Mox should initially be a **deterministic field-support companion**, not a second full combatant.

Possible field functions:

- Reveal one hidden sector property
- Warn about a hazard
- Improve one interaction outcome
- Identify a resource or discovery
- Mark a route or objective
- Comment on changed locations
- Remember a prior choice
- Unlock a companion-specific option

This gives Mox mechanical relevance without immediately doubling:

- Combat balance
- Targeting
- Equipment
- Status logic
- AI behavior
- Animation requirements
- Save complexity
- Encounter presentation

A limited player-commanded support action could later be added to combat without making Mox a fully autonomous party member.

---

## 3.5 Future Save Requirements

Even though persistence is scheduled for Milestone 22, Milestone 21 should define all runtime state that must eventually be serialized.

Required future fields include:

- Contract ID
- Contract seed
- Generation algorithm version
- Exact `ExpeditionPlan` snapshot
- Physical-layout version
- Current sector ID
- Player physical position
- Visited sectors
- Cleared encounters
- Completed interactions
- Consumed resources
- Triggered hazards
- Objective state
- Extraction state
- Contract clock
- Expedition RNG state
- Player HP and resource state
- Equipment and inventory
- Mox state
- Contract flags
- Rewards earned but not yet banked

Do not wait until Milestone 22 to discover that Milestone 21 state cannot be reconstructed cleanly.

---

# 4. Milestone 22 — Expedition Persistence and Checkpoint Recovery

The milestone ordering is reasonable: prove the generated loop first, then persist it.

However, the data model must be designed during Milestone 21.

## Save both seed and generated snapshot

Store:

- The seed for reproduction, sharing, diagnostics, and provenance
- The exact generated plan snapshot for save stability

A future update to generation rules could produce a different plan from the same seed. An existing save should continue using the saved plan rather than silently regenerating a different expedition.

## Add structure-specific versions

Do not rely only on one overall save version.

Recommended fields:

```text
save_schema_version
expedition_plan_version
physical_layout_version
content_catalog_version
generation_rules_version
```

This permits targeted migrations.

## Required tests

- Save and restore from deployment
- Save and restore from an ordinary sector
- Save and restore after combat
- Save and restore after an interaction
- Save and restore after objective completion
- Restore with a missing optional field
- Restore with an invalid sector ID
- Reject a plan/layout mismatch
- Prevent duplicate completed interactions
- Prevent duplicate rewards
- Recover from a corrupted primary save
- Recover from a valid backup
- Migrate from the authored-only version-1 snapshot
- Preserve exact deterministic continuation after restore

---

# 5. Milestone 23 — Wayfarer Mobile-Base Core

This milestone is correctly placed after generated expedition persistence.

The Wayfarer becomes meaningful only after the player can return from a complete expedition with rewards, consequences, and persistent state.

## Core player questions on return

Every return to the Wayfarer should answer:

1. What happened?
2. What changed?
3. What did I gain?
4. What decision do I make now?
5. Where can I go next?

## Minimum viable stations

### Navigation

- Select a new contract
- Review contract danger and objective
- Revisit eligible locations
- Inspect previous contract records

### Loadout

- Equip weapons, armor, and accessories
- Manage consumables
- Compare class-relevant statistics
- Prepare for known contract conditions

### Recovery

- Restore expedition resources according to a clear rule
- Explain what recovery is free and what is limited
- Avoid unnecessary maintenance chores

### Archive

- Review discovered locations
- Review important events
- Review encountered characters and factions
- Review unresolved story threads
- Review seeds and contract history

### Mox Station

- Contextual conversation
- Companion memory callbacks
- Bond or relationship information
- Future companion support selection

### Systems Station

Initially minimal or locked.

Use later for upgrades that reinforce exploration rather than passive resource collection.

## Avoid initially

- Large crafting trees
- Timed construction
- Resource generators
- Repetitive repair chores
- Multiple overlapping currencies
- Decorative rooms with no player function
- Percentage-heavy upgrade grids
- Idle-game mechanics

## Base economy decisions required

Before implementing base upgrades, decide:

- Which rewards are banked
- Which resources carry into the next expedition
- Whether healing is free
- Whether consumables refill automatically
- Whether contracts have entry costs
- What upgrade currencies exist
- Whether failure loses unbanked rewards
- Whether inventory capacity matters
- Whether the player can sell or dismantle equipment

---

# 6. Milestone 24 — Event-Driven Regions and Revisits

This milestone is foundational to the long-term game.

It should be separated into a persistent-state foundation and one complete player-visible revisit.

---

## Milestone 24A — Persistent Location Identity and Event State

Recommended core types:

```text
RegionIdentity
LocationIdentity
VisitRecord
WorldEvent
LocationState
TransformationSet
RelationshipState
DiscoveryRecord
StoryFact
```

A generated location should store:

- Stable identity
- Origin seed
- Theme
- Structural plan
- First-visit facts
- Current mutable state
- Visit history
- Known characters or factions
- Unresolved threads
- Eligible transformations
- Last-visited campaign time
- Current danger and resource state
- Completion and failure records

---

## Milestone 24B — First Meaningful Revisit

Build one complete example:

1. Visit a generated location
2. Make a decision
3. Return to the Wayfarer
4. Complete one or more other expeditions
5. Receive a reason to return
6. Revisit a recognizably changed version
7. Resolve a consequence caused by the first visit

### Exit test

> The player recognizes the location, understands what changed, and can connect the change to a previous action or failure.

Do not attempt a large persistent world before one revisit proves emotionally and mechanically meaningful.

## Authored transformation sets

Prefer controlled transformations such as:

```text
Stable
Damaged
Occupied
Abandoned
Fortified
Contaminated
Recovered
```

A transformation may change:

- Available routes
- Props and visual state
- Encounter composition
- Hazards
- Resource availability
- NPC presence
- Objectives
- Dialogue
- Rewards
- Future event eligibility

---

# 7. Milestone 25 — Companion Depth

The full expansion belongs later, but the memory model and field-support category should be planned earlier.

## Recommended memory taxonomy

Mox memories may include:

- Place visited
- Character met
- Choice made
- Promise made
- Failure witnessed
- Rare discovery
- Class-specific action
- Companion-directed decision
- Contradiction
- Betrayal
- Successful callback
- Rescue or sacrifice
- Repeated behavior pattern

Each memory should contain:

```text
memory_id
memory_type
importance
emotional_interpretation
associated_entity_id
expedition_index
location_id
created_at
referenced_count
permanent
expiration_policy
```

## Companion depth should affect

- Dialogue
- Field support
- Revisit reactions
- Story options
- Wayfarer interactions
- Companion trust or bond
- Interpretation of player behavior

## Companion depth should not immediately require

- Full autonomous combat AI
- Separate equipment
- Independent inventory
- Complex tactical pathfinding
- Permanent failure caused by unpredictable companion behavior

---

# 8. Milestone 26 — Generated Story Director

The story director should remain offline-first and deterministic.

A minimal story-fact system must exist before Milestone 24, but the full director can remain here.

## Separate three layers

### Authoritative Facts

Examples:

```text
relay_restored = true
missing_team_status = "rescued"
region_security = 2
mox_witnessed_abandonment = true
settlement_leader_id = "npc_example"
```

Facts are validated and saved.

### Story Structure

Examples:

- Need
- Complication
- Discovery
- Choice
- Reversal
- Consequence
- Closure
- Open thread

Structure is generated deterministically from facts, rules, and content templates.

### Presentation

Examples:

- Objective description
- NPC dialogue
- Mox reaction
- Announcement
- Journal entry
- Contract summary

Presentation can use authored templates and may later use optional AI, but it never controls authoritative state.

## Required provenance

Every generated story element should be traceable to:

- Seed
- Rule
- Input facts
- Selected content template
- Validation checks
- Enabling prior event
- Campaign and expedition index

This is essential for debugging incoherent narrative combinations.

---

# 9. Milestone 27 — Content and Visual Expansion

Visual work should continue incrementally before Milestone 27, but this milestone can serve as the focused production pass.

## Define the content pipeline before volume grows

Plan standards for:

- Room-template dimensions
- Tile size
- Palette rules
- Prop placement
- Collision authoring
- Encounter sockets
- Interaction sockets
- Hazard sockets
- Objective sockets
- Entry and exit markers
- Lighting hooks
- Ambient audio hooks
- Visual-state variants
- Stable IDs
- File naming
- Asset provenance
- Automated validation
- Screenshot and viewport review

Generated environments made from incompatible room templates may look worse than clean prototype rectangles. Standardize composition before producing a large asset library.

## Suggested per-theme content budget

For each major environment theme:

- 6–10 room templates
- 3 corridor variants
- 3 encounter configurations
- 2 hazards
- 2 discoveries
- 2 resource interactions
- 1 objective family
- 1 transformation set
- 1 major landmark
- 1 ambient-audio identity
- 1 palette and lighting profile
- 1 small narrative-content set

This makes “content expansion” measurable.

---

# 10. Milestone 28 — Optional AI Interaction Layer

The placement is correct and should remain late.

Do not begin implementation until the offline story director can produce coherent, complete experiences without AI.

## Initial boundary

```text
Validated structured context
    -> Optional prose renderer
    -> Output filtering and validation
    -> Cached presentation text
```

## AI output may affect

- Nonessential dialogue wording
- Incidental uncommon NPC conversation
- Optional Mox reflections
- Journal prose
- Flavor descriptions

## AI output must not directly affect

- Save validity
- Combat
- Rewards
- Items
- Statistics
- Room connectivity
- Objectives
- Quest state
- Story facts
- Achievements
- Progression
- Completion conditions

The AI layer must be removable without changing whether the game can be completed.

A safe first use would be nonessential post-fact dialogue after deterministic text has already communicated the required information.

---

# 11. Milestone 29 — Build and Progression Depth

Full class growth can remain late, but a small class-growth experiment should occur earlier, likely after the first Wayfarer loop.

## Early class-growth prototype

Give each class one choice between two directions.

### Vanguard

- Stronger defensive preparation
- Stronger heavy attacks

### Scavenger

- Better discovery and resource outcomes
- Better consumable efficiency

### Signalist

- Better hazard information
- Timeline or system disruption

## Test question

> Does the same generated contract produce meaningfully different decisions for each class?

If classes only alter numerical starting statistics, generated replayability will feel shallower than intended.

Full specialization, respec rules, cosmetics, and broad equipment depth can remain in Milestone 29.

---

# 12. Milestone 30 — Release Hardening

The final concentrated hardening pass is valid, but release-quality activities should occur throughout development.

## Incremental requirements

- Outside playtest after Milestone 21
- Outside playtest after expedition persistence
- Outside playtest after the Wayfarer loop
- Outside playtest after the first revisit
- Controller and focus testing every milestone
- Viewport checks at realistic populated state
- Save migration rehearsals before public release
- Export smoke tests well before final hardening
- Asset provenance updates whenever content is added
- Branch consolidation at regular intervals
- Performance checks as generated content expands

Milestone 30 should be the final comprehensive pass, not the first time these issues receive attention.

---

# 13. Additional Planning Areas

## 13.1 Complete Player Meta-Loop

Define the full loop in one product-design reference:

```text
Prepare on the Wayfarer
-> Select a contract
-> Explore and resolve an expedition
-> Extract or fail
-> Bank rewards and consequences
-> Develop class, equipment, Mox, and base
-> Observe world changes
-> Select a new contract or revisit
-> Advance an authored/generated story arc
```

For each transition, document:

- Player decision
- Resource cost
- Risk
- Reward
- State change
- Save boundary
- Narrative consequence

---

## 13.2 Economy and Reward Model

Before adding many items or upgrades, define:

- Reward currencies
- Experience pace
- Level cadence
- Equipment replacement rate
- Consumable scarcity
- Healing policy
- Contract reward tiers
- Optional-room value
- Failure losses
- Banking rules
- Unique-item frequency
- Base-upgrade costs
- Class-upgrade cadence
- Inventory capacity policy
- Duplicate-item handling

A deterministic game makes reward pacing easier to diagnose only when a target economy exists.

---

## 13.3 Expedition Difficulty Model

Possible inputs:

```text
campaign tier
player level
equipment rating
class
contract theme
critical-route length
optional-room count
encounter density
hazard density
objective complexity
special modifiers
```

Avoid scaling every enemy directly to the player.

Preserve:

- Easier regions
- Dangerous regions
- Aspirational contracts
- Contracts with unusual risk/reward profiles

Create a visible danger rating and test whether it predicts real difficulty.

---

## 13.4 Generated-Content Quality Metrics

The generator already has structural validation. Add experiential metrics:

- Forced backtrack count
- Longest empty traversal
- Critical-route length
- Optional-branch depth
- Number of meaningful route decisions
- Encounter spacing
- Reward spacing
- Hazard clustering
- Objective visibility
- Template repetition
- Critical-route combat load
- Optional-value ratio
- Estimated completion time
- Distinctive-landmark count

These metrics should identify questionable seeds for review rather than automatically rejecting every unusual layout.

---

## 13.5 Campaign and Story-Arc Structure

Decide the broad campaign shape before the full story director.

Questions:

- Is the campaign finite?
- How many expeditions form an arc?
- How often does an authored anchor event occur?
- Can the player ignore the main arc?
- What advances regions when the player is absent?
- Are contracts infinite after campaign completion?
- How is a final objective selected?
- What makes a campaign feel complete?
- What carries into a new campaign?

Possible initial cadence:

```text
3 generated contracts
-> 1 authored anchor event
-> region-state change
-> 2–4 generated follow-ups
-> authored arc resolution
```

---

## 13.6 Content Authoring and Data Migration

Some ordinary content remains partly code-authored.

Use this criterion:

> Move a content category out of code when a designer must add or tune entries without modifying core rules.

Likely migration order:

1. Enemies
2. Skills
3. Encounters
4. Loot tables
5. Interactions
6. Hazards
7. Discoveries
8. Objective families

Do not migrate content purely for architectural neatness. Migrate when authoring pressure justifies it.

---

## 13.7 Playtest and Local Telemetry

Add an optional local run report containing:

- Seed
- Character class
- Contract plan
- Route taken
- Sectors visited
- Encounters fought
- Damage taken
- Consumables used
- Time or pressure spent
- Remaining contract time
- Rewards earned
- Failure cause
- Objective outcome
- Mox events
- Save and checkpoint events
- Final contract state

Allow the report to be copied or exported.

This will produce more useful feedback than general statements such as “the expedition felt too long.”

---

## 13.8 Scope Tiers

Label every future system as one of:

- Required for first generated loop
- Required for first campaign
- Required for public demo
- Post-demo
- Experimental

This is especially important for:

- Mox mechanics
- Revisits
- Story generation
- Wayfarer upgrades
- AI dialogue
- Class growth
- Economy
- Campaign persistence

---

# 14. Recommended Revised Sequence

1. **Milestone 20:** Owner playtest and traversal fixes
2. **Milestone 20.5:** Commit, consolidate branches, and add traversal diagnostics
3. **Milestone 21A:** Generated encounters and progression gates
4. **Milestone 21B:** Interactions, objective, extraction, rewards, and contract pressure
5. **Milestone 22:** Expedition persistence, checkpoints, and save migration
6. **Milestone 23:** Minimum viable Wayfarer loop and economy
7. **Early class-growth experiment:** One meaningful branch per class
8. **Milestone 24A:** Persistent location identity and world-event model
9. **Milestone 24B:** First meaningful revisit
10. **Milestone 25:** Mox memory depth and field-support mechanics
11. **Milestone 26:** Offline generated story director
12. **Milestone 27:** Focused content and visual production
13. **Milestone 28:** Optional AI presentation layer
14. **Milestone 29:** Full build and progression depth
15. **Milestone 30:** Release hardening

---

# 15. Highest-Priority Planning Decisions

Before Milestone 21 begins, formally decide:

1. **What consumes time or pressure in a generated expedition?**
2. **What exactly counts as success, failure, abandonment, and extraction?**
3. **What is lost, retained, or restored after failure?**
4. **What mechanical role does Mox initially have?**
5. **What player and contract state must eventually be saved?**

These decisions will prevent the next several milestones from embedding incompatible assumptions into:

- Combat
- Generation
- Persistence
- The Wayfarer
- Revisits
- Companion behavior
- Story progression

---

# 16. Immediate Action Checklist

## Before beginning Milestone 21

- [ ] Complete the owner F5 playtest for Milestone 20
- [ ] Record navigation and layout observations
- [ ] Fix traversal, clipping, focus, controller, and readability issues
- [ ] Confirm the full automated suite
- [ ] Commit and publish Milestone 20 only after explicit owner approval
- [ ] Consolidate the stacked branches
- [ ] Document the expedition pressure model
- [ ] Document the contract-state machine
- [ ] Document the failure and checkpoint model
- [ ] Select Mox’s initial mechanical role
- [ ] Draft the future expedition save shape
- [ ] Split Milestone 21 into encounter and resolution phases
- [ ] Define the first generated contract’s exit criteria
- [ ] Define the local playtest report format

---

# 17. Guiding Product Principle

The next phase should not optimize for the number of generated systems.

It should optimize for one question:

> Can one deterministic generated contract create a readable, tactically interesting, rewarding, and memorable beginning-to-ending experience?

If the answer is yes, persistence, revisits, Mox, story generation, content expansion, and optional AI have a strong foundation.

If the answer is no, those later systems will multiply content without solving the core experience.
