# Unassigned TODO

# Marta
## Done
## Todo

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

## Todo
- continously update the waiting room html for it to automatically show new players appearing
- disallow players for usign the same name
