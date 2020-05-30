# Simple racing framework

This script provides very basic framework building racing tracks and running them.
Currently the resource is pretty barebones without any integrations with anything, so it's just bare commands. 
I would like to have a phone/tablet implementation for managing the races, not commands, but for that I need specific tablet or phone implementation.
Also everything here should be whitelisted, so there should be roles like "trackmaster" for creating tracks and "racementor" for running and inviting people.

# Usage
## Available commands
### Creating races
```
/race_create
```
Begin creating the race

```
/race_checkpoint_undo
```
Undoes last checkpoint

```
/race_checkpoint_add
```
Add checkpoint to race

```
/race_save [race_name] [race_type] [lap_count]
```
Finish race creation and save the race with \[lap/sprint] type with lap count if using lap type.

### Managing races
```
/race_list
```
List of available races

```
/race_preview [race_name]
```
Preview \[race_name] race

```
/race_ready [race_name]
```
Prepare race for zooming 

```
/race_invite [playerId]
```
Invite Player to Race

```
/race_invite_accept
```
Accept pending race invite (Last invite will be accepted)

```
/race_invite_cancel [playerId]
```
Cancel pending or accepted race invite for player

```
/race_invite_deny
```
Deny pending race invite

```
/race_start
```
Start the currently prepared race


```
/race_cancel
```
Cancels current running race. 
For owner of the race will cancel for every participant.
For participant will cancel only for him.


# Example steps to create a map
1. Position yourself at the desired race start
2. Start creating race: `/race_create CircuitName lap 10`
3. Drive to your preferred checkpoints and create them `/race_checkpoint_add`. 

    If you made a mistake or don't like the placement you can undo with `/race_checkpoint_undo`
4. do step 3 until desired circuit mapped
5. Save the race with `/race_save`

# Example steps to run the map 
1. Start preparing the circuit `/race_ready [race_name]`
2. Invite other players by using `/race_invite [playerId]`
3. Line up to starting race marker
4. Do `/race_start` 
5. Enjoy the race


# Todo
1. Start with better markers.
2. Start should point to vehicle heading, not first checkpoint.
3. Create race and start marker is different.
4. Stick marker to vehicle? Make radius markers for understanding the checkpoint radius.
## OB Dependant stuff
1. Make everything use CID?
2. Write UI for phone/tablet.
3. Commands/UI should be whitelisted.
