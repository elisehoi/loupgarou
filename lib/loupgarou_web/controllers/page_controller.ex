defmodule LoupgarouWeb.PageController do
  use LoupgarouWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end


## Author Elise - Nov 29 11:48 AM
# generate access code for the game and url of the room
  defp generate_access_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 5)
  end

# create game room using the access code, redirect to a new page wirh the access code as URL
# TODO how to extract the name of the player
# TODO connect the Gameprocess to its unique code, so that it can be accessed through this code.
  def create_game_room(conn, _params) do
    code = generate_access_code()

    # TODO: extract playerName and code. The first parameter of start_link should be the player name and the second the code
    # case Loupgarou.GameLogic.GameProcess.start_link(playerName, code) do

    case Loupgarou.GameLogic.GameProcess.start("hello", code) do
      # If the creation of the gameProcess is successful, it will redirect to the other route
      {:ok, _pid} ->
        redirect(conn, to: "/#{code}")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game: #{inspect(reason)}")
        |> redirect(to: "/")
    end

  end

#TODO: extract the name of the player
  def join_game_room(conn, %{"code" => code}) do
    Loupgarou.GameLogic.GameProcess.add_player("player", code)
    redirect(conn, to: "/#{code}")
  end

## Author Marta DL dec 6 10:18AM
#def waiting_room_master(conn, _params) do
#    render(conn, "waiting_room_master.html")
#end

  def waiting_room_master(conn, %{"code" => code}) do
    playerMap=Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    IO.inspect(playerMap)
    render(conn, "waiting_room_master.html", code: code, playerMap: playerMap)
  end

  def waiting_room_player(conn, _params) do
    render(conn, "waiting_room_player.html")
  end

  def distribute_role(conn, %{"code" => code}) do
    IO.inspect("the code is:#{code}")
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    nbOfPlayers = map_size(playerMap)
    # ration between villlagers and werewolf = 1 to 3. => 1 Wolf = 3 Villagers
    nbOfWolf = round(nbOfPlayers/3)


     # For the number of wolf it looks for a random player of the playerList and set its role to Wolf.
     Enum.each(1..nbOfWolf, fn _i ->
      {_playerName, pid}= Enum.random(Map.to_list(playerMap))
      send(pid, {:setRole, :Werewolf})
    end)


    # If player's role == :unknown, then the role :Villager is assign to this player.
    Enum.each(playerMap, fn {playerName, pid} ->
      role = Loupgarou.GameLogic.GameProcess.getRole(playerName, code)
      if(role == :unknown) do
        send(pid,{:setRole, :Villager})
      end
    end)

    render(conn, "role_distribution.html")


  end


end
