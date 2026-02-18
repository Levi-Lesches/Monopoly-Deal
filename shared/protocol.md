# Network protocol:

1. Join a game:
Either creates a new room (if rc == 0) or adds you to the given room
  Request: `join {"roomCode": int }`
  Response: `{"roomCode": int}

2. Room broadcasts its members list to all other members:
Broadcasts occur whenever a user joins or is disconnected
  Request: N/A
  Response: `room_members {"users": [User]}

3. Mark yourself as ready to start a game:
  Request: `lobby_ready {"status": bool}`
  Response: N/A

4. Lobby broadcasts its readiness to all other members:
  Request: N/A
  Response: `lobby_details {User: bool}`

5. Lobby broadcasts that it's ready to start the game:
  Request: N/A
  Response: `lobby_start {}`

6. Game starts broadcasting its details
  Request N/A
  Response: `game_details Game`

## Someone disconnects after joining a room (lobby)

1. Room notifies all members: `room_members {"users": [User]}

2. User re-connects: `join {"roomCode": int}

3. User requests state
