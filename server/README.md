# Monopoly Deal Server

All game rules are implemented in `../shared`, as a `Game` class. This package serves as an executable to manage the game and interface with clients

## Server architecture choice

Using a debt collector as an example:

### Option 1: Server manages the game
- Server calls `game.start()`, broadcasts
- Server receives `Choice(debtCollector)`, calls `game.playCard()`
- Server sends `game.interruptions` to all clients
- Server receives `PaymentResponse()`, calls `game.handleResponse()`
- Server calls `game.nextTurn()`
- Server sends `game.state` to all clients

### Option 2: The game holds a server
- `Game.start()` subscribes to the server's Response and Choice streams
- Game receives `Choice(debtCollector)`, calls `game.playCard()`
- Game calls `server.broadcastGame()` with `PaymentInterruption`
- Game receives `PaymentResponse`, calls `game.handleResponse()`
- Game calls `game.nextTurn()`
- Game calls `server.broadcastGame()`

I chose Option 1 to keep the `Game` class simpler and testable
