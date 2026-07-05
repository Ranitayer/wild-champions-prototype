# Wild Champions - Game Design Document

Status: Living draft  
Last updated: 2026-07-05

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

## Battle

- Combat resolves automatically after player preparation.
- The initial arena has four card slots per side in a 4v4 formation, with support for larger formations.
- Pressing Space starts the prototype battle.
- Cards count down their cooldowns. When a cooldown reaches 0, that card attacks and its cooldown resets.
- If multiple cards become ready at the same time, attacks resolve one at a time from left to right.
- While an attack or effect is resolving, cooldown ticking pauses.
- Random combat outcomes use a deterministic battle seed so identical inputs can be replayed.
- Targeting checks the card directly across first, then searches left, then right, expanding outward until it finds a valid enemy card.
- Both sides must be reproducible from saved battle data.
- Results should expose enough information for players to learn from losses.
- Randomness, triggered effects, and win conditions are TBD.

## Cards

Cards are the primary strategic building blocks. Their exact role is TBD: they may represent units, abilities, equipment, modifiers, or a deliberate subset of these.

- Base card dimensions are 200 x 275 pixels.
- Cards use slightly rounded corners.
- Cards enlarge and lift on hover, provide movement feedback while dragged, and snap into arena slots.
- Cards have Common, Uncommon, Rare, Epic, and Mythic rarities with distinct top and bottom colors.
- Cards have three merge tiers. Two identical cards of the same tier merge into the next tier, up to Tier 3. Tiers currently change only the tier indicator.
- Card data is stored as Resources containing title, description, art, rarity, attack, health, and cooldown.
- Permanent Attack changes update the main Attack stat. Limited-duration Attack changes use a separate temporary Attack stat and expire after their configured attack uses.
- Traits are reusable valued card abilities, can be acquired during play, and appear in `#de9e41` text. Traits normally cap at 5 unless their rule explicitly allows unlimited levels.
- When a poisoned card is attacked, existing Poison deals its value as extra damage, then decreases by 1. Poison gained from that attack starts triggering on later attacks.

Current prototype card:

- **Stageroo:** Rare, 4 Attack, 4 Health, 3 Cooldown. Start of combat: adjacent cards get +1 Attack.
- **Badger:** Common, 1 Attack, 3 Health, 2 Cooldown. Tough 1 reduces damage received from each attack by 1.
- **Warwick:** Uncommon, 2 Attack, 4 Health, 3 Cooldown. Lifesteal heals for half its attack damage.
- **Peedie:** Common, 1 Attack, 1 Health, 1 Cooldown. Poison 1 gives its target +1 Poison on attack.
- **Seraphina:** Rare, 2 Attack, 3 Health, 2 Cooldown. Poison 2. Survivalist prevents its first death, removes negative effects, and leaves it at 1 HP.
- **Batteroo:** Common, 1 Attack, 1 Health, 1 Cooldown. Flying gives incoming attacks a 1-in-4 chance to miss.
- **Nimble:** Epic, 4 Attack, 2 Health, 1 Cooldown. Every second attack gains temporary Attack equal to its permanent Attack for that attack.

To define:

- Deck and hand rules
- Card categories
- Costs and resource economy
- Acquisition and upgrade rules
- Copy limits and rarity
- When cards are played relative to automated combat

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
