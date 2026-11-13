# ASHEN DECKS

A dark-fantasy roguelike deck-builder.

## Run locally
Open `index.html` in a modern browser. No build step or external dependencies are required.

## First prototype
- 50 original cards, with up to 4 collectible copies of each.
- Turn-based combat, energy, block, enemy intents and a starter deck.
- Persistent collection and run state in browser local storage.
- Automated rules tests via `npm test`.

## Progression and saves
The browser prototype stores progress in local storage on the same browser and device. Clearing browser data or changing devices can remove access to that local save. A future account/cloud-save service should be added before treating saves as cross-device backups.

## Development safety
Daily changes should be proposed on a separate branch, tested, and reviewed before merging to the stable branch. Never overwrite player saves during a content update; use explicit save-version migrations.
