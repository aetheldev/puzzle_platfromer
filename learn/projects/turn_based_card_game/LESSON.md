# Turn-Based Card Game — Project Lesson

## Goal

Build a 2-player hot-seat card game with deck, hand, discard,
legal move validation, and turn flow. Best state machine practice.

---

## The Concept

Card-shedding game rules:
1. Colors: red, blue, green, yellow. Values: 0-4.
2. Play a card if it matches top discard by color or value.
3. If no legal play, draw one card.
4. First empty hand wins.

This teaches:
- Turn-based state machines
- Discrete legal action validation
- Deck/hand/discard data management
- Deterministic rules (key for future networking)

---

## If You Know JS/React...

In React:
```jsx
const [deck, setDeck] = useState(initialDeck);
const [hands, setHands] = useState([[], []]);
const [currentPlayer, setCurrentPlayer] = useState(0);
const playCard = (index) => {
  // validate, move card, check win, advance turn
  setHands(newHands); setCurrentPlayer(1 - currentPlayer);
};
```

In Odin:
- Deck, hands, discard are `[dynamic]Card`
- Current player is an int
- Direct mutation: `append(&discard, card)`
- No setState. No re-render. Just mutate and draw next frame.

---

## Architecture

### Data model
```odin
Card :: struct { color: Card_Color, value: int }
players: [2]Player              // each has hand: [dynamic]Card
deck: [dynamic]Card
discard: [dynamic]Card
current_player: int
```

### Turn flow
1. Current player selects card
2. Check if playable (matches color or value)
3. If yes: move to discard, check win, advance turn
4. If no legal play: draw from deck, advance turn

### Deterministic design
Every action is: "player N plays card X" or "player N draws."
These can be logged and replayed. This is why card games are
excellent networking preparation.

---

## Read The Solution

Open:
- `learn/solutions/projects/turn_based_card_game/main.odin`

Key sections:
- `Card_Color`, `Card`: lines 46-56
- `is_playable`: line 119
- `setup_game`: lines 184-222
- `play_selected_card`: lines 224-244
- `draw_if_blocked`: lines 246-255

---

## Exercises

### Exercise 1 — Deck And Deal
Create deck. Shuffle. Deal 5 cards per player.

### Exercise 2 — Play Validation
Check color or value match. Only allow legal plays.

### Exercise 3 — Turn Switching
After play or draw, switch current player.

### Exercise 4 — Win Detection
Empty hand = winner. Print result.

### Exercise 5 — Action Cards (Challenge)
Add skip, reverse, draw-two. Handle their effects.

---

## Exit Criteria

- [ ] Deck, hand, discard work
- [ ] Legal play validation correct
- [ ] Turn switching works
- [ ] Win detection works
- [ ] You can explain why this is networking-friendly

## Sauce Goal

When this works, read:
- `learn/production_with_sauce/12_turn_based_card_game_in_sauce.md`
- `learn/advanced/a12_card_game_in_sauce_plus_fx.md`

Then rebuild inside `sauce/game.odin`.
