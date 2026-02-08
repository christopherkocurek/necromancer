# The Necromancer: Research Launch Plan

## ag0.xyz Research Testbed for ERC-8004 Agentic Networks

**Author**: Christopher Kocurek
**Date**: February 7, 2026
**Status**: DRAFT

---

## Executive Summary

The Necromancer is an open-source Tolkien roguelike rebuilt in Godot 4.6, descending from the 40-year Rogue > Moria > Angband > Sil lineage. We will deploy it as a live research testbed for ERC-8004 agentic networks via the Agent0 SDK (`agent0-sdk`), generating the first empirical dataset on portable agent identity, reputation dynamics, and deterministic task validation in a mixed human-AI game environment.

**Goals**:
- 500-1,000+ human players in month 1
- Multiple AI agent archetypes playing via Agent0 SDK identities
- Novel research publication on agentic network behavior in complex decision environments
- Showcase the Agent0 SDK and ERC-8004 standard in a real, engaging application

---

## Part 1: Ship the Game (Week 1-2)

### 1.1 Finish Remaining Game Work

| Task | Effort | Priority |
|------|--------|----------|
| Commit uncommitted sprite work (87 monsters + 193 items) | 1 hr | P0 |
| Touch up ~5 over-stripped monster sprites (60, 75, 79 etc.) | 2-3 hrs | P1 |
| Rename "Hobbit" to "Halfling" everywhere (data files + code) | 1 hr | P0 |
| Run full test suite, fix any regressions | 1 hr | P0 |
| Playtest 3-5 complete runs for game-breaking bugs | 2-3 hrs | P0 |

### 1.2 Web Build

The web-playable version is the single most important distribution decision. Zero-friction access multiplies every marketing channel.

| Task | Effort | Notes |
|------|--------|-------|
| Export Godot project to HTML5/WebAssembly | 2-3 hrs | Godot 4.6 has web export support |
| Test web build in Chrome, Firefox, Safari | 1-2 hrs | Audio, input, performance |
| Host on thenecromancer.game (or similar domain) | 1 hr | Vercel/Cloudflare Pages |
| Embed on itch.io as playable-in-browser | 30 min | itch.io supports HTML5 embeds |
| Add Open Graph meta tags for link previews | 30 min | Title, description, screenshot |

### 1.3 Distribution Platforms (Day 1)

All free, all low-effort. Do these on launch day:

| Platform | Effort | Expected Reach |
|----------|--------|----------------|
| **itch.io** (web embed + download) | 1 hr | 500-2,000 |
| **GitHub** (open source, good README + screenshots) | 1 hr | 200-1,000 |
| **Web hosted** (your domain, instant play) | Already done | 2x multiplier on all channels |
| **Newgrounds** | 30 min | 200-500 |
| **GameJolt** | 30 min | 100-300 |

### 1.4 Game Trailer

A 30-60 second trailer multiplies conversion on every channel. It doesn't need to be Hollywood quality.

| Approach | Cost | Effort |
|----------|------|--------|
| Screen capture + royalty-free epic music + text overlays | $0-50 | 2-3 hrs |
| AI-assisted editing (CapCut, Descript) | $0-20 | 1-2 hrs |
| Commission from Fiverr game trailer editor | $100-200 | 1 hr (your time) |

**Trailer structure**: 5s title card > 10s dungeon exploration > 10s combat with VFX > 5s death screen > 5s "Play now in your browser" + URL

---

## Part 2: Get Human Players (Week 2-3)

### 2.1 Launch Day Posts

Write different angles for different communities. Each post should feel native to that community.

| Community | Angle | Post Style |
|-----------|-------|------------|
| **r/roguelikes** | "I rebuilt a Tolkien roguelike in Godot - play it in your browser" | Gameplay focus, feature list, web link |
| **r/roguelikedev** | "Porting a C roguelike to Godot 4.6: architecture, FOV, AI, tileset pipeline" | Technical deep-dive, lessons learned |
| **r/tolkienfans** | "Explore Dol Guldur as the Wise - a free roguelike set in the Third Age" | Lore focus, how the game recreates Tolkien's world |
| **r/indiegaming** | "Open-source roguelike with DALL-E generated art - play free in browser" | Art showcase, accessibility angle |
| **r/godot** | "Built a complete roguelike in Godot 4.6 - 23K lines, 55 scripts, open source" | Engine showcase, open source |
| **r/opensourcegames** | "The Necromancer - open-source Tolkien roguelike (Angband lineage)" | OSS angle, contribution welcome |
| **Hacker News** | "Show HN: Open-source Middle-earth roguelike in Godot 4.6" | Technical + open source angle |
| **Product Hunt** | "The Necromancer - play a Tolkien roguelike in your browser" | Accessibility, instant play |

### 2.2 Community Outreach

| Community | How | Effort |
|-----------|-----|--------|
| Angband forums/Discord | Post as a fellow *band developer | 30 min |
| DCSS Discord/Reddit | "New roguelike from the Sil lineage" | 30 min |
| Sil-Q community | Direct outreach - you're a fork | 30 min |
| Roguelike Discord servers (3-5) | Share with gameplay GIFs | 1 hr |
| Tolkien gaming communities | Facebook groups, Discord servers | 1 hr |

### 2.3 Content Creators

Target small-to-mid roguelike YouTubers (1K-50K subscribers). They actually play games sent to them, unlike big channels.

| Creator Type | Approach | Budget |
|-------------|----------|--------|
| 5-10 roguelike YouTubers | DM with gameplay footage + web link | $0-200 (optional gift cards) |
| Roguelike streamers on Twitch | DM during non-stream hours | $0 |
| r/roguelikes community reviewers | Offer early access / feedback role | $0 |

### 2.4 Paid Promotion (Small Budget)

| Channel | Budget | Expected |
|---------|--------|----------|
| Reddit ad targeting r/roguelikes, r/tolkienfans, r/indiegaming | $200-300 | 200-500 clicks |
| **Reserve for amplifying whatever works** | $200 | React to data |
| **Total paid budget** | $400-500 | |

### 2.5 Budget Summary

| Item | Cost |
|------|------|
| Domain + hosting | $50-100/yr |
| Game trailer | $0-200 |
| Reddit ads | $200-300 |
| Creator outreach (gift cards) | $0-200 |
| Reserve | $100-200 |
| **Total** | **$400-1,000** |

---

## Part 3: Virality Mechanics (Build Into the Game)

These are engineering features that turn every player death into potential player acquisition.

### 3.1 Death Screen Share Card (Highest Priority)

Every death generates a shareable image and unique URL:

```
+--------------------------------------+
|  FALLEN IN DOL GULDUR               |
|                                      |
|  Aldor the Noldo - House of Feanor  |
|  Depth 14 - Slain by Werewolf       |
|  42 kills - 3,847 turns             |
|                                      |
|  [Share on X]  [Copy Link]  [Again] |
|                                      |
|  thenecromancer.game/run/a3f8x      |
+--------------------------------------+
```

**Implementation**:
- Generate unique run ID (short hash)
- Serialize death stats to a permalink URL
- Permalink page shows death recap + "Play Now" button (instant web play)
- OG meta tags on permalink = auto-preview on social media
- "Share on X" pre-formats tweet: "I died on depth 14, slain by a Werewolf. Can you go deeper? [link]"

**Why this matters**: Every death is a micro-marketing event. Players share deaths, friends click, friends play, friends die, friends share. This is your core growth loop.

### 3.2 Leaderboard / Hall of Fame

- Global leaderboard on the website
- Categories: Deepest delve, Most kills, Fastest death, Longest survival
- Weekly resets to keep competition fresh
- Shows both human and agent runs (labeled)

### 3.3 "Avenge Me" Mechanic

- When you die, option to share: "Avenge [character name]!"
- Friend clicks link, starts a run where your ghost/tombstone appears at the depth you died
- Flavor text: "Here fell Aldor the Noldo, slain by a Werewolf"
- Low implementation cost (spawn a decoration entity at a fixed depth)

### 3.4 Achievement Moments

- Auto-capture key moments: first artifact, boss kills, depth records
- "Share this moment" with pre-formatted social text
- Builds a narrative around the player's run

---

## Part 4: Agent Framework (Week 2-4)

### 4.1 Architecture Overview

```
+-------------------------------------------+
|  THE NECROMANCER (Godot 4.6, headless)    |
|                                           |
|  Game Loop:                               |
|    if agent_mode:                         |
|      state = serialize_game_state()       |
|      POST state to agent_url             |
|      action = response.action            |
|    else:                                  |
|      action = wait_for_keypress()        |
|                                           |
|    execute_action(action)                 |
|    run_monster_turns()                    |
|    log_turn(state, action, result)        |
+-------------------+-----------------------+
                    |
                    | HTTP POST (JSON)
                    v
+-------------------------------------------+
|  AGENT SERVER (Python / FastAPI)          |
|                                           |
|  /agent/turn  - receive state, return act |
|  /agent/start - begin a new run           |
|  /agent/end   - run complete, log results |
|                                           |
|  Agent Strategy Layer:                    |
|    - LLM-based (Claude, GPT-4o, etc.)   |
|    - Rule-based (heuristic baseline)     |
|    - Hybrid (rules + LLM for decisions)  |
+-------------------+-----------------------+
                    |
                    | Agent0 SDK (agent0-sdk)
                    v
+-------------------------------------------+
|  ERC-8004 ON-CHAIN LAYER                 |
|                                           |
|  Identity Registry:                       |
|    - ERC-721 token per agent             |
|    - Name, model type, strategy profile  |
|    - MCP/A2A endpoint advertisement      |
|                                           |
|  Reputation Registry:                     |
|    - Post-run feedback (depth, kills,    |
|      survival, efficiency)               |
|    - Cross-agent feedback signals        |
|    - Reputation search + filtering       |
|                                           |
|  Validation Registry:                     |
|    - Deterministic replay verification   |
|    - Run seed + action log = proof       |
|    - Any validator can replay and verify |
+-------------------------------------------+
```

### 4.2 Game State Serializer

New function in the Godot codebase that dumps current game state to a dictionary. All data already exists in memory; this just packages it.

**File**: `scripts/agent_interface.gd` (new, ~150-200 lines)

```
serialize_game_state() -> Dictionary:
  - player: position, hp, max_hp, hunger_state, stats, skills, equipped items
  - visible_map: 2D array of visible tile types within FOV
  - visible_entities: list of {type, position, hp_pct, distance, direction, status_effects}
  - items_at_feet: list of {name, type}
  - inventory: list of {name, type, slot, equipped}
  - available_abilities: list of {name, cost, ready, cooldown}
  - recent_messages: last 5 game messages
  - valid_actions: computed list of legal actions this turn
  - meta: turn_number, depth, rng_seed
```

**Effort**: ~1 day. All source data is accessible from existing singletons (player.gd, level.gd, ability_system.gd, main.gd).

### 4.3 Agent Input Mode

Modification to `main.gd` to accept actions from HTTP instead of keyboard.

**Changes**:
- Add `_agent_mode: bool` flag (set via command line arg `--agent`)
- Add `_agent_url: String` (set via `--agent-url http://localhost:8000`)
- In the player input handler, branch: if agent mode, POST state to agent URL and await response
- Parse response action string and map to existing action handlers
- Run headless (no rendering) for speed

**Effort**: ~1 day. The existing bot test (`test_bot.gd`) provides a pattern for automated input.

### 4.4 Run Logger

Every turn's state + action + result gets logged for research and validation.

**File**: `scripts/run_logger.gd` (new, ~100 lines)

```
RunLog:
  - run_id: unique hash
  - seed: RNG seed for this run
  - agent_id: ERC-8004 identity (or "human" + session ID)
  - turns: [{turn_num, state_hash, action, result, timestamp}]
  - outcome: {depth, kills, cause_of_death, total_turns, items_found, abilities_used}
```

The run log enables:
1. **Deterministic replay** (seed + actions = exact reproduction)
2. **Validation** (anyone can verify a claimed run result)
3. **Research analysis** (decision patterns, strategy clustering)

**Effort**: ~0.5 days

### 4.5 Agent Server (Python)

A FastAPI server that receives game state and returns actions. Supports multiple agent "personalities."

**File**: `agent_server/` directory (new)

```
agent_server/
  server.py          - FastAPI app, /agent/turn endpoint
  agents/
    base_agent.py    - Abstract base class
    rule_agent.py    - Heuristic baseline (if monster close, fight; if low HP, retreat; etc.)
    llm_agent.py     - LLM-powered agent (formats state as prompt, parses response)
    hybrid_agent.py  - Rules for trivial decisions, LLM for complex ones
  prompts/
    system.txt       - Base system prompt for LLM agents
    strategy_*.txt   - Strategy-specific prompt variants
  erc8004/
    identity.py      - Agent0 SDK: register agent identity
    reputation.py    - Agent0 SDK: post run results as reputation
    validation.py    - Agent0 SDK: submit run logs for validation
  requirements.txt   - fastapi, uvicorn, anthropic, agent0-sdk
```

**Agent Decision Flow**:
```
1. Receive game state JSON
2. Check for immediate threats (rule layer)
   - HP critical? Use healing item or flee
   - Monster adjacent? Attack or retreat based on odds
   - Standing on item? Evaluate pickup
3. If no immediate threat, consult LLM for strategic decision
   - Explore vs. descend
   - Which corridor to take
   - Ability usage
   - Item management
4. Return action string
```

**Effort**: 2-3 days for the full server with multiple agent types.

### 4.6 Agent Archetypes for Research

Different agent configurations create diverse behavioral data:

| Agent Name | Strategy | Research Purpose |
|------------|----------|-----------------|
| **Cautious Carl** | Prioritize survival, retreat often, hoard items | Risk-averse baseline |
| **Aggressive Alex** | Always engage, push deeper, use abilities freely | Risk-seeking contrast |
| **Balanced Beth** | Hybrid rules + LLM for balanced play | Closest to "good" human play |
| **Explorer Eve** | Prioritize map coverage, avoid combat | Information-gathering strategy |
| **Lore Lord** | Max lore skills, ability-focused build | Specialist strategy |
| **Random Randy** | Random valid actions | True baseline / control |
| **Copycat** | Mimics highest-reputation agent's patterns | Reputation-driven behavior |

Each agent gets a distinct ERC-8004 identity via Agent0 SDK, with its strategy profile published as MCP/A2A capabilities.

---

## Part 5: ERC-8004 Integration via Agent0 SDK (Week 3-4)

### 5.1 Agent Identity Registration

Using `agent0-sdk` (TypeScript) or a Python wrapper:

```
For each AI agent archetype:
  1. createAgent({
       name: "Cautious Carl",
       description: "Risk-averse roguelike agent prioritizing survival",
       capabilities: {
         mcp: { tools: ["play_necromancer", "analyze_run"] },
         a2a: { skills: ["roguelike_navigation", "combat_assessment"] }
       }
     })
  2. registerIPFS(agent) -> on-chain ERC-721 identity
  3. Agent ID format: "chainId:agentId" (e.g., "11155111:42")
```

**Chain**: Start on Sepolia testnet (free), migrate to mainnet for publication.

### 5.2 Reputation Posting

After each run completes:

```
giveFeedback({
  agentId: "11155111:42",  // Cautious Carl
  rating: computed_score,   // 0-100 based on depth + kills + efficiency
  tags: ["depth_14", "warrior_build", "1847_turns"],
  comment: "Reached depth 14, 42 kills, died to Werewolf"
})
```

**Reputation Score Formula**:
```
score = (depth_reached * 5) + (kills * 0.5) + (turns_survived * 0.01) + (artifacts_found * 10)
  - Normalized to 0-100 scale
  - Higher is better
```

This creates a growing reputation profile for each agent that anyone can query via `searchAgents()` or `getReputationSummary()`.

### 5.3 Deterministic Validation

The killer research feature. Because the game is turn-based with a known RNG seed:

```
Validation claim: "Agent X reached depth 14 with 42 kills"
Proof: { seed: 0xABCD1234, actions: ["move_n", "attack", "pickup", ...] }
Verification: Replay the game with the same seed and actions
  -> If final state matches claim, validation passes
  -> If not, agent's reputation gets penalized
```

This maps directly to the ERC-8004 Validation Registry. A validator contract can:
1. Receive the run proof (seed + action sequence + claimed outcome)
2. Anyone can replay off-chain and submit the verification result
3. The result is recorded on-chain, building or burning reputation

**Why this matters for the paper**: Deterministic replay is the cheapest possible validation mechanism. No zkML, no TEE, no re-execution infrastructure. Just replay the game. This is a genuine contribution to the ERC-8004 design space.

### 5.4 Human Player Integration

Human players can optionally connect a wallet to get their own ERC-8004 identity:

- Anonymous by default (runs logged locally, no on-chain identity)
- Optional "Connect Wallet" on the death screen / leaderboard
- If connected: runs posted to reputation registry, player appears on on-chain leaderboard
- Enables human-vs-agent reputation comparisons

This is opt-in and should be frictionless. Most human players won't connect a wallet, and that's fine — the research value is in the agent data. Human data serves as the behavioral baseline.

---

## Part 6: Research Design

### 6.1 Research Questions

**RQ1**: How do different LLM agent strategies develop and diverge when given on-chain reputation feedback in a complex procedural environment?

**RQ2**: How accurately does ERC-8004 reputation (accumulated over many runs) predict future agent performance in novel situations (new dungeon seeds)?

**RQ3**: Can deterministic replay serve as a zero-cost validation mechanism for the ERC-8004 Validation Registry, and what are its limitations?

**RQ4**: In a mixed human-AI leaderboard, do human players adopt strategies from high-reputation agents, and does agent presence affect player engagement?

### 6.2 Experimental Design

**Phase A: Baseline (Week 3-4)**
- Run 100+ games per agent archetype on the same set of 50 dungeon seeds
- Establish baseline performance distributions for each strategy
- No reputation feedback — agents play independently

**Phase B: Reputation-Aware (Week 4-5)**
- Agents can query each other's reputation before making decisions
- "Copycat" agent mimics the highest-reputation agent's strategy patterns
- Measure: Does reputation access improve agent performance?

**Phase C: Mixed Play (Week 5-6)**
- Human players and agents compete on the same leaderboard
- Track: Do humans and agents reach similar depths? Different strategies?
- Survey human players: Do they trust/distrust agent scores?

**Phase D: Validation Stress Test (Week 5-6)**
- Introduce "cheating" agents that claim false run results
- Test whether deterministic replay catches all fabricated claims
- Measure: False positive/negative rates, validation cost

### 6.3 Data Collection

| Data Type | Volume Target | Collection Method |
|-----------|---------------|-------------------|
| Complete run logs (agent) | 1,000+ runs | Automated, headless Godot |
| Complete run logs (human) | 500+ runs | Opt-in logging via web version |
| On-chain reputation data | All agent + opt-in human runs | Agent0 SDK, Sepolia/mainnet |
| Validation results | 200+ verification attempts | Deterministic replay pipeline |
| Human survey responses | 50-100 players | Optional post-death survey |
| Strategy clustering data | Derived from run logs | Offline analysis (Python) |

### 6.4 API Cost Estimates for Agent Runs

| Model | Cost/turn | Cost/run (~1000 turns) | 1000 runs | Notes |
|-------|-----------|------------------------|-----------|-------|
| Claude Haiku 4.5 | ~$0.001 | ~$1 | ~$1,000 | Good balance of cost and capability |
| GPT-4o-mini | ~$0.0005 | ~$0.50 | ~$500 | Cheapest LLM option |
| Rule-based | $0 | $0 | $0 | Baseline, unlimited runs |
| Claude Sonnet 4.5 | ~$0.005 | ~$5 | ~$5,000 | Best performance, expensive |

**Recommended mix**:
- 500 rule-based runs (free, baseline)
- 300 Haiku/4o-mini runs ($150-300, bulk LLM data)
- 50 Sonnet runs ($250, high-quality strategy data)
- Total: ~$400-550 in API costs

---

## Part 7: Research Output

### 7.1 Paper Structure

**Title**: "Trustless Agents in the Dungeon: Empirical Analysis of ERC-8004 Identity, Reputation, and Validation in a Procedural Game Environment"

**Abstract**: ~200 words. First empirical study of ERC-8004 in a live game environment. Key findings on reputation accuracy, validation via deterministic replay, mixed human-AI behavior.

**1. Introduction**
- The agent economy needs trust infrastructure
- ERC-8004 provides identity, reputation, validation
- Games as ideal testbeds (complex, measurable, reproducible)
- The Necromancer: 40-year open-source lineage

**2. Background & Related Work**
- ERC-8004 standard (cite the EIP + co-authors)
- Agent0 SDK
- LLMs as game-playing agents (cite relevant work)
- Roguelikes as AI testbeds (cite NetHack challenge, etc.)

**3. System Architecture**
- Game engine (Godot 4.6, headless mode)
- Agent interface (state serialization, action space)
- ERC-8004 integration (identity, reputation, validation)
- Deterministic replay mechanism

**4. Experimental Setup**
- Agent archetypes and strategies
- Dungeon seed sets
- Reputation scoring formula
- Validation protocol

**5. Results**
- Agent performance distributions
- Reputation prediction accuracy
- Validation success rates
- Human-agent behavioral comparison

**6. Discussion**
- Implications for ERC-8004 design
- Deterministic replay as validation primitive
- Limitations and future work

**7. Conclusion**

### 7.2 Publication Targets

| Venue | Type | Why |
|-------|------|-----|
| **ag0.xyz blog / research page** | Primary | Your platform, your audience, immediate publication |
| **arXiv** (cs.AI or cs.MA) | Preprint | Broad academic visibility, no peer review barrier |
| **AAMAS** (Autonomous Agents and Multi-Agent Systems) | Conference | Premier venue for agent research |
| **IEEE Blockchain** | Conference | Blockchain + AI intersection |
| **NeurIPS Workshop** (if timing aligns) | Workshop | High-visibility ML venue |
| **Ethereum research forum** | Community | Direct audience for ERC-8004 stakeholders |

### 7.3 Marketing the Research

The research itself becomes marketing for ag0.xyz:

- Paper published on ag0.xyz with interactive demo
- "Play the game the agents play" — link to web version
- Leaderboard showing human vs agent performance
- Twitter/X thread summarizing findings with death screen screenshots
- Present at ETH conferences / agent economy events

---

## Part 8: Timeline

### Week 1-2: Ship the Game
- [ ] Commit all sprite work, fix touch-ups
- [ ] Rename Hobbit -> Halfling
- [ ] Web export (HTML5/WASM)
- [ ] Deploy web version + itch.io
- [ ] Record trailer
- [ ] Launch day posts (Reddit, HN, Discord)

### Week 2-3: Build Virality + Agent Framework
- [ ] Death screen share cards (run permalinks, OG tags, share buttons)
- [ ] Leaderboard page on website
- [ ] `agent_interface.gd` — state serializer
- [ ] Agent input mode in `main.gd`
- [ ] `run_logger.gd` — turn-by-turn logging
- [ ] Python agent server (rule-based + LLM agents)
- [ ] Content creator outreach

### Week 3-4: ERC-8004 Integration
- [ ] Register agent identities via Agent0 SDK (Sepolia)
- [ ] Post-run reputation updates
- [ ] Deterministic replay validation pipeline
- [ ] Begin Phase A experiments (baseline agent runs)

### Week 4-5: Data Collection
- [ ] Phase B experiments (reputation-aware agents)
- [ ] Phase C (mixed human-AI leaderboard)
- [ ] Phase D (validation stress test)
- [ ] Ongoing: human players accumulating organic play data

### Week 5-6: Analysis & Writing
- [ ] Statistical analysis of agent performance
- [ ] Reputation prediction accuracy
- [ ] Validation success rates
- [ ] Draft paper
- [ ] Internal review

### Week 6-7: Publication
- [ ] Publish on ag0.xyz
- [ ] Submit to arXiv
- [ ] Submit to conference (if timing works)
- [ ] Marketing push: Twitter thread, Ethereum forums, Reddit

---

## Part 9: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Tolkien C&D at 500-1K players | Very Low | High | *band family has coexisted 35 years; we're small; renamed Hobbit. If it happens, file off remaining names (1-2 day rename). |
| Web export has critical bugs | Medium | High | Test early, have download fallback. Godot 4.6 web export is mature but not perfect. |
| LLM agents play poorly (random-looking) | Medium | Medium | Include rule-based agents as competent baseline. Hybrid agents (rules + LLM) for complex decisions only. |
| Low human player turnout | Medium | Medium | 500 is achievable with Reddit + HN alone. Agent data is the core research; human data is supplementary. |
| Agent API costs exceed budget | Low | Medium | Use cheap models (Haiku, 4o-mini) for bulk runs. Rule-based runs are free. Budget $400-550. |
| Deterministic replay fails (RNG drift) | Low | High | Lock RNG seed at run start, verify replay matches on first 10 runs before scaling. |

---

## Part 10: Success Metrics

### Game Launch
- [ ] 500+ unique players in month 1
- [ ] 5,000+ total runs (human)
- [ ] 100+ death screens shared on social media
- [ ] 3+ content creators play the game

### Agent Research
- [ ] 1,000+ agent runs completed across all archetypes
- [ ] All agent identities registered on-chain (ERC-8004)
- [ ] Reputation data for 7+ agent archetypes
- [ ] 200+ validation attempts via deterministic replay
- [ ] 95%+ validation accuracy

### Publication
- [ ] Research paper published on ag0.xyz
- [ ] Paper on arXiv
- [ ] 1+ conference submission
- [ ] Twitter thread with 50K+ impressions

---

## Appendix A: Agent0 SDK Integration Reference

```typescript
// Register an agent identity
import { SDK } from 'agent0-sdk'

const sdk = new SDK({ rpcUrl: '...', privateKey: '...' })

const agent = sdk.createAgent({
  name: 'Cautious Carl',
  description: 'Risk-averse roguelike agent',
  // MCP endpoint where the agent can be reached
  mcp: { url: 'https://agents.ag0.xyz/cautious-carl' },
  // A2A skills advertisement
  a2a: { skills: ['roguelike_navigation', 'risk_assessment'] }
})

await sdk.registerIPFS(agent) // -> chainId:agentId

// Post reputation after a run
await sdk.giveFeedback({
  agentId: agent.id,
  rating: 78,
  tags: ['depth_14', 'warrior', '1847_turns'],
  comment: 'Reached depth 14, 42 kills, survived 1847 turns'
})

// Search agents by reputation
const topAgents = await sdk.searchAgents({
  reputationMin: 70,
  skills: ['roguelike_navigation']
})

// Get reputation summary
const rep = await sdk.getReputationSummary(agent.id)
// -> { averageRating: 72.4, totalFeedback: 47, tags: {...} }
```

## Appendix B: Game State JSON Schema

```json
{
  "run_id": "a3f8x9b2",
  "seed": "0xABCD1234",
  "turn": 847,
  "depth": 5,
  "player": {
    "name": "Agent-CautiousCarl-42",
    "race": "Noldo",
    "house": "Feanor",
    "hp": 34,
    "max_hp": 60,
    "hunger_state": "hungry",
    "position": [12, 8],
    "stats": { "str": 3, "dex": 2, "con": 1, "gra": 4 },
    "skills": { "melee": 3, "evasion": 5, "stealth": 2, "lore": 7 },
    "status_effects": ["poisoned"]
  },
  "visible_entities": [
    {
      "type": "wolf",
      "position": [12, 5],
      "hp_pct": 100,
      "distance": 3,
      "direction": "north",
      "status_effects": []
    }
  ],
  "items_at_feet": [
    { "name": "Potion of Healing", "type": "potion" }
  ],
  "inventory": [
    { "name": "Longsword (+1)", "type": "weapon", "equipped": true },
    { "name": "Scroll of Mapping", "type": "scroll", "equipped": false }
  ],
  "available_abilities": [
    { "name": "Song of Banishment", "ready": true },
    { "name": "Light of the Eldar", "ready": false, "cooldown": 3 }
  ],
  "recent_messages": [
    "The wolf howls.",
    "You feel hungry."
  ],
  "valid_actions": [
    "move_north", "move_south", "move_east", "move_west",
    "move_northeast", "move_northwest", "move_southeast", "move_southwest",
    "attack:wolf_north",
    "pickup:potion_of_healing",
    "use_ability:song_of_banishment",
    "use_item:scroll_of_mapping",
    "rest", "wait", "descend"
  ]
}
```

## Appendix C: Action Space

| Action | Format | Description |
|--------|--------|-------------|
| Move | `move_{direction}` | 8 directions: n/s/e/w/ne/nw/se/sw |
| Attack | `attack:{target_id}` | Melee attack adjacent entity |
| Pickup | `pickup:{item_name}` | Pick up item at feet |
| Use Item | `use_item:{item_name}` | Use consumable from inventory |
| Use Ability | `use_ability:{ability_name}` | Activate an ability |
| Equip | `equip:{item_name}` | Equip an inventory item |
| Unequip | `unequip:{slot}` | Unequip from slot |
| Rest | `rest` | Rest one turn (+HP if safe) |
| Wait | `wait` | Skip turn |
| Descend | `descend` | Go down stairs (if on stairs) |
| Close Door | `close_door:{direction}` | Close adjacent door |
| Search | `search` | Search for hidden features |

---

## Sources

- [ERC-8004: Trustless Agents (Official EIP)](https://eips.ethereum.org/EIPS/eip-8004)
- [Agent0 TypeScript SDK](https://github.com/agent0lab/agent0-ts)
- [Agent0 SDK Documentation](https://sdk.ag0.xyz/)
- [CoinDesk: ERC-8004 Identity for AI Agents](https://www.coindesk.com/markets/2026/01/28/ethereum-s-erc-8004-aims-to-put-identity-and-trust-behind-ai-agents/)
- [ERC-8004 Fellowship Discussion](https://ethereum-magicians.org/t/erc-8004-trustless-agents/25098)
- [BNB Chain ERC-8004 Support](https://chainwire.org/2026/02/04/bnb-chain-announces-support-for-erc-8004-to-enable-verifiable-identity-for-autonomous-ai-agents/)
- [ERC-8004 Explained (Backpack)](https://learn.backpack.exchange/articles/erc-8004-explained)
