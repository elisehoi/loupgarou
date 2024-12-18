# Unassigned TODO

# Marta
## Done
- get rid of the phoenix header

## Todo
- as the master start the game, use a broadcast message to show roles also to the other players

# YingYing
## Done
## Todo

# Elise
## Done
- fix joining players name display in the waiting room (waiting_room_master.html.heex, home.html.heex, page_controller.ex)
- find why the hell there are two processes created per player when a player joinsTris
    - because of the mutilple calls of join player in home html to check if a game room exists -> replace with check game room function
    - waiting room master called but no arguments
- disable start game button for the joining players, only allow the host to do so
- continously update the waiting room html for it to automatically show new players appearing
    - use phoenix live views instead of html
    - fix errors with phoenix live view
- make sure all players are redirected to the game when it starts
- convert html pages of latest Yingying push to live view
- Make the voting system in live view



## Todo
- brodcast when a player is getting ready to enter a new page

- find why on earth it says game room does not exist
- make the game Pretty
- disallow players for usign the same name
    - tried to do it but not working, not top priority
