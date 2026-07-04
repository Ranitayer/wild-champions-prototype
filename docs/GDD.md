# Wild Champions - Game Design Document

Status: Living draft  
Last updated: 2026-07-04

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
- Both sides must be reproducible from saved battle data.
- Results should expose enough information for players to learn from losses.
- Randomness, board layout, team size, targeting, timing, and win conditions are TBD.

## Cards

Cards are the primary strategic building blocks. Their exact role is TBD: they may represent units, abilities, equipment, modifiers, or a deliberate subset of these.

- Base card dimensions are 187.5 x 262.5 pixels.
- Cards use slightly rounded corners.
- Cards enlarge, sway, and pop upward on hover, then drop directly to rest when hover ends.
- Cards have Common, Uncommon, Rare, Epic, and Mythic rarities with distinct top and bottom colors.

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
3. How many champions participate on each side?
4. How is a battle won, and how long should one battle last?
5. Which battle decisions are random, and which must be deterministic?
6. Is the game primarily 2D or 3D, and what are the initial target platforms?

## Change Log

- 2026-07-04: Added five card rarity tiers and their visual color identities.
- 2026-07-04: Halved card dimensions and removed upward release bounce.
- 2026-07-04: Defined base card dimensions and hover presentation.
- 2026-07-04: Created the initial GDD from the confirmed asynchronous PvP card autobattler concept.
