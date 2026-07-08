# Wild Champions - Game Design Document

Status: Living draft  
Last updated: 2026-07-08

## Game Summary

Wild Champions is an asynchronous PvP card autobattler. Players build a card-based strategy, submit or save a battle-ready setup, and compete against another player's setup without requiring both players to be online together.

## Design Pillars

These initial pillars follow directly from the game concept and should be refined as the rules become concrete.

1. **Meaningful preparation:** Player decisions before combat determine the strategy taken into battle.
2. **Readable automation:** Players should understand why a battle developed and why a result occurred.
3. **Asynchronous competition:** PvP should remain useful and fair when opponents play at different times.
4. **Varied card expression:** Cards and champions should support distinct strategies rather than a single optimal build.

## Core Loop

Current high-level draft:

1. Build or modify a card-based setup.
2. Prepare a champion or team for asynchronous PvP.
3. Match against a saved opponent setup.
4. Watch the automated battle resolve.
5. Review the result and improve the setup.

The exact deck-building, matchmaking, rewards, and progression rules are not yet defined.

## Match Structure

- A match is best of 15 battle rounds.
- First player to 8 round wins wins the match.
- If the score is tied after 15 rounds, the match continues in sudden death until one player wins a round.
- The prototype scoreboard stays visible during shop and battle, showing each player's round wins.
- After each battle round, a winner popup resolves into a score marker for the winning player before the next shop phase.
- When a match winner is declared, the final winner popup locks card and shop interaction until the player chooses Restart or Quit.
- In online play, Restart waits until both players choose Restart. Quit is synchronized immediately.

## Battle

- Combat resolves automatically after player preparation.
- The initial arena has four card slots per side in a 4v4 formation, with support for larger formations.
- Battle starts when both players submit ready board snapshots.
- A player can cancel Ready before battle starts to keep editing their shop board.
- Cards count down their cooldowns. When a cooldown reaches 0, that card attacks and its cooldown resets.
- If multiple cards become ready at the same time, attacks resolve one at a time from left to right.
- At battle start, an initiative roll chooses which player is favored for same-cooldown attack order.
- While an attack or effect is resolving, cooldown ticking pauses.
- Random combat outcomes use a deterministic battle seed so identical inputs can be replayed.
- Targeting checks the card directly across first, then searches left, then right, expanding outward until it finds a valid enemy card.
- Predator changes targeting to the lowest-health enemy, with slot order used as the tie-breaker.
- Both sides must be reproducible from saved battle data.
- Results should expose enough information for players to learn from losses.
- Randomness, triggered effects, and win conditions are TBD.

## Cards

Cards are the primary strategic building blocks. Their exact role is TBD: they may represent units, abilities, equipment, modifiers, or a deliberate subset of these.

- Base card dimensions are 200 x 275 pixels.
- Cards use slightly rounded corners.
- Cards enlarge and lift on hover, provide movement feedback while dragged, and snap into arena slots.
- Cards have Common, Uncommon, Rare, Epic, and Mythic rarities with distinct top and bottom colors.
- Common, Uncommon, and Rare cards have three merge tiers. Epic and Mythic cards have two. Two identical cards of the same tier merge into the next tier, up to that rarity's cap.
- Card data is stored as Resources containing title, description, art, rarity, attack, health, and cooldown.
- Cards have one or two tags; current tags include Animal and Spider.
- Permanent Attack changes update the main Attack stat. Limited-duration Attack changes use a separate temporary Attack stat and expire after their configured attack uses.
- Traits are reusable valued card abilities, can be acquired during play, and appear in `#de9e41` text. Traits normally cap at 5 unless their rule explicitly allows unlimited levels.
- When a poisoned card is attacked, existing Poison deals its value as extra damage, then decreases by 1. Poison gained from that attack starts triggering on later attacks.

Current prototype card:

- **Stageroo:** Rare, 3 Cooldown. Tier 1: 4 Attack, 4 Health, adjacent allies get +1 Attack. Tier 2: 5 Attack, 6 Health. Tier 3: 6 Attack, 8 Health, all allies get +2 Attack instead.
- **Badger:** Common, 2 Cooldown. Tier 1: 1 Attack, 3 Health, Tough 1. Tier 2: 2 Attack, 5 Health, Tough 1. Tier 3: 2 Attack, 7 Health, Tough 2.
- **Warwick:** Uncommon, 3 Cooldown, Lifesteal. Tier 1: 2 Attack, 4 Health. Tier 2: 3 Attack, 5 Health. Tier 3: 4 Attack, 6 Health, gains Survivalist.
- **Peedie:** Common, 2 Cooldown. Tier 1: 1 Attack, 1 Health, Poison 1. Tier 2: 2 Attack, 2 Health, Poison 1. Tier 3: 2 Attack, 4 Health, Poison 2.
- **Seraphina:** Rare, 2 Cooldown, Survivalist. Tier 1: 2 Attack, 3 Health, Poison 2. Tier 2: 4 Attack, 5 Health, Poison 2. Tier 3: 5 Attack, 7 Health, Poison 4.
- **Batteroo:** Common, 1 Cooldown, Flying. Tier 1: 1 Attack, 1 Health. Tier 2: 2 Attack, 2 Health. Tier 3: 4 Attack, 3 Health.
- **Nimble:** Epic, 1 Cooldown. Tier 1: 4 Attack, 2 Health. Tier 2: 6 Attack, 4 Health, gains Overwhelm. Every second attack gains temporary Attack equal to its permanent Attack for that attack. Overwhelm splits excess lethal attack damage across adjacent enemies, with odd damage favoring the left.
- **Matriarch:** Mythic, 2 Cooldown, Predator. Tier 1: 4 Attack, 9 Health. Tier 2: 7 Attack, 12 Health, gains Overwhelm.

To define:

- Deck and hand rules
- Card categories
- Costs and resource economy
- Acquisition and upgrade rules
- Copy limits and rarity
- When cards are played relative to automated combat

## Shop and Collection

- Pressing F2 transitions the prototype arena into its shop layout.
- Players currently enter the prototype shop with 10 currency.
- After battle, the winner gains 5 currency and the loser gains 8 currency.
- The Wild Booster Pack costs 5 and offers a choice of one from three cards.
- The Wilder Booster Pack costs 10 and grants one card with no Common results.
- The shop also offers one individual card priced by rarity: Common 3, Uncommon 8, Rare 12, Epic 25, and Mythic 40.
- Shop rewards use a seeded random sequence so the same seed and card catalog reproduce the same rolls.
- Booster soft pity tracks Rare, Epic, and Mythic misses separately. Mythic pity resets only when Mythic appears.
- Booster rewards are rolled and validated before payment. Payment completes before the pack or card acquisition animation begins.
- Opening a booster closes and locks the card collection until the player takes a reward.
- In shop, owned cards show sell value and can be sold by dragging them into the sell slot.
- Sell values by rarity/tier are: Common 1/2/4, Uncommon 3/6/12, Rare 5/10/20, Epic 10/25, Mythic 15/40.
- Cards may finish a drag only by entering an open arena slot or merging with a valid matching card.
- Cards released elsewhere return to the player's card collection.
- The persistent Cards button opens a two-column, scrollable view of collected cards. Collected cards can be dragged back into play.
- Currency persistence, shop refresh rules, and seed authority are TBD.

## Champions

Champions are part of the game's identity, but their mechanical role is TBD. Define whether a player controls one champion, a team, or champions represented directly by cards before implementation.

To define:

- Champion stats and abilities
- Team size and formation
- Relationship between champions and cards
- Progression and customization

## Asynchronous PvP

The defending side should use a stable snapshot of the opponent's legal setup. Battle resolution must be deterministic enough to validate or replay from the same inputs; the exact authority model and random seed policy are TBD.

To define:

- Matchmaking inputs and rating model
- Attack and defense setup rules
- Snapshot lifetime and invalidation
- Server authority and result validation
- Disconnect and version-mismatch handling
- Seasons, rankings, and rewards

## Presentation

The visual direction, world, tone, camera perspective, target platforms, and input methods are TBD.

## Prototype Scope

The first playable target should prove one complete loop: configure a legal setup, load an opponent snapshot, resolve one automated battle, display the result, and allow another attempt. Content volume, progression, monetization, social systems, and live operations are outside that target until the battle loop is proven.

## Open Decisions

1. What does a player place or configure before combat?
2. What exactly does each card represent?
3. How is a battle won, and how long should one battle last?
4. Which battle decisions are random, and which must be deterministic?
5. Is the game primarily 2D or 3D, and what are the initial target platforms?

## Change Log

- 2026-07-08: Added best-of-15 match scoring direction with first-to-8 win target and visible round scoreboard.
- 2026-07-08: Split booster soft pity by rarity so Mythic pity no longer resets from Rare or Epic pulls.
- 2026-07-08: Added final match winner popup behavior that locks card and shop interaction until Restart or Quit.
- 2026-07-08: Clarified battle winner popup score-marker flow into the match scoreboard.
- 2026-07-08: Synchronized online Restart as a both-player confirmation and allowed Ready cancel before combat starts.
- 2026-07-07: Added Matriarch and Predator lowest-health targeting.
- 2026-07-07: Added card tags and title-box tag icons.
- 2026-07-06: Set prototype match economy to 10 starting currency, +5 for winner, and +8 for loser.
- 2026-07-06: Added battle-start initiative roll for same-cooldown attack order.
- 2026-07-06: Added shop card selling with rarity/tier sell values.
- 2026-07-06: Defined prototype shop prices, starting currency, seeded reward rolls, validated payment flow, and collection locking during booster choices.
- 2026-07-05: Added the shop layout transition and persistent card collection for invalid card drops.
- 2026-07-05: Capped Epic/Mythic cards at Tier 2 and added Nimble Tier 2 with Overwhelm.
- 2026-07-05: Added Peedie, Seraphina, and Batteroo Tier 2–3 upgrades.
- 2026-07-05: Added tier trait overrides plus Badger and Warwick Tier 2–3 upgrades.
- 2026-07-05: Added reusable per-tier card overrides and Stageroo Tier 2–3 stats/effects.
- 2026-07-05: Added same-card, same-tier merging through Tier 3 with card-slam feedback.
- 2026-07-05: Added unlimited Poison levels, post-attack poison damage, and Peedie.
- 2026-07-05: Added one-time Survivalist death prevention and Seraphina.
- 2026-07-05: Added deterministic miss rolls, Flying, and Batteroo.
- 2026-07-05: Added duration-aware temporary Attack and Nimble's every-second-attack double damage.
- 2026-07-04: Defined prototype cooldown ticking, left-to-right attack resolution, and front-left-right targeting.
- 2026-07-04: Added Stageroo and Resource-based card content.
- 2026-07-04: Defined the initial expandable 4v4 card-slot arena.
- 2026-07-04: Added five card rarity tiers and their visual color identities.
- 2026-07-04: Halved card dimensions and removed upward release bounce.
- 2026-07-04: Defined base card dimensions and hover presentation.
- 2026-07-04: Created the initial GDD from the confirmed asynchronous PvP card autobattler concept.
