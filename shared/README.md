# Monopoly Deal Shared Logic

This package contains the rules and processes for the Monopoly Deal game. The code is split into two layers:

- `package:shared/data.dart`: Basic data definitions for cards and players.
- `package:shared/game.dart`: Contains the rules to process game events

## Asynchronous Architecture

Monopoly Deal is full of many small choices, such as:
- what card should you play?
- who should pay for a debt collector?
- which color do you want to charge rent for?
- which stack should the wild card go on?
- which cards should you use to pay?
- which cards should you discard?

These many questions require answers from humans, and it won't make sense to try to fill in the answers automatically. For example, if a player was charged $4, but only has $5, $3, and $2 -- how should they pay? This kind of question leads to deliberate strategy, and so this codebase embraces that.

### The `PlayerAction` class

A turn starts off with a `PlayerAction` that specifies what the player wants to do, eg, "Debt collector on player 2" or "bank this rent card". The game validates this choice in `PlayerAction.handle()`, checking for basic issues like "no player chosen for a debt collector", but also more complex issues like "trying to charge rent on a yellow set with an orange/pink rent card".

If a choice can be successfully completed without human input, it is handled quietly and the game proceeds. For example, if a "Pass Go" is played, the game deals the top two cards to the player.

After an action is completed, the card is removed from the player's hand, put into the right pile/stack, and the `turnsRemaining` counter is decremented.

### Interruptions

More often than not, playing a card will cause some effect that requires interaction from other players. For example, playing an "It's my Birthday!" card requires all other players to figure out how to pay $2 to the player.

The game stores a list of `Interruption` objects that describe what kinds of interruptions need to be resolved before the player can play their next card. In the example above, the game issues a `PaymentInterruption(2)` for each other player in the game. Players who have a net worth of $0 are skipped, but players with even $1 to spare will get an interruption and the chance to pay.

### Responses

An interruption is resolved if the playing sends a `Response` that satisfies the condition of the interruption. In the birthday example, each player must send a `PaymentResponse` that contains a list of cards. The card values must sum to at least $2, or the player must have a net worth of less than $2.

There are different responses available for each interruption. As another example, when a player has played all cards for a turn, they are issued a `DiscardInterruption` describing how many cards must be thrown away. The player must respond with a `DiscardResponse` with a list of at least that many cards. An interruption of 0 cards can be used to give players a chance to "burn" cards after any turn.

### Continuing the game

After any `Response` is received, its corresponding `Interruption` is removed from the game list. Note that additional interruptions may be issued while processing a response. One example is the case where a user is paid with a wild card: the receiving player needs to choose where to put it before continuing.

Once `game.interruptions` is empty, the game continues:
- If the current player has cards left, they can submit another action
- Otherwise, a `DiscardInterruption` is issued
- After processing the `DiscardResponse`, the next player's turn begins

## TODOs
- freely move properties / bank houses+hotels on turn
- end turn without playing all three cards
