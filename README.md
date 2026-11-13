# ASHEN DECKS

A dark-fantasy browser roguelike deck-builder.

## Play locally

Open \`index.html\` in a modern browser. No build step or package installation is required. Internet access is only used for optional Google Fonts; the game itself runs locally.

## Version 1.0.0 gameplay

- A complete ten-floor run with a final boss.
- Route choices with regular battles, elite encounters, rest stops and treasure rooms.
- Turn-based card combat with energy, block, healing, weakening, enemy intents and shuffled draw/discard piles.
- Three-card post-battle reward choice; skip a reward when it does not fit your deck.
- A 50-card collection with five rarity tiers and a deck that changes during a run.
- Persistent collection, unlocked cards, currency, wins and run state in browser local storage.
- Save migration from the earlier version 1 prototype.

## Saves

Progress is stored in local storage in the current browser on the current device. It is not a cloud save and does not automatically sync between devices. Clearing browser storage can remove the save. Do not promise cross-device backup until a server-backed account/save system exists.

## Tests

Run \`npm test\` with Node.js 18 or newer.

## Development

Work on feature branches, run the tests, and review changes before merging to \`main\`. Keep save migrations explicit and never silently reset player progress.


## Hosting

The production site is deployed from the `main` branch using the GitHub Actions workflow in `.github/workflows/deploy-pages.yml`.
