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

# create game room using the access code, redirect to a new page with the access code as URL
  def create_game_room(conn, %{"name" => name}) do
    code = generate_access_code()

  case Loupgarou.GameLogic.GameProcess.start(name, code) do
    {:ok, _pid} ->
      redirect(conn, to: "/#{code}/#{name}/waiting_room_master_live")

    {:error, reason} ->
      conn
      |> put_flash(:error, "Failed to create game: #{inspect(reason)}")
      |> redirect(to: "/")
      IO.inspect("Page Controller: create_game_room fails to create gameProcess")
  end
end


# check if game room exists to join one
defp game_room_exists?(code) do
  case Process.whereis(String.to_atom(code)) do
    nil -> false  # No process found, game room does not exist
    _pid -> true   # Process found, game room exists
  end
end
def check_player_name(conn, %{"code" => code, "name" => name}) do
  # Check if the game room exists
  if game_room_exists?(code) do
    player_map = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)

    if Map.has_key?(player_map, name) do
      json(conn, %{exists: true, message: "Name already exists"})
    else
      json(conn, %{exists: false})
    end
  else
    json(conn, %{error: "Game room does not exist"})
  end
end

def join_game_room(conn, %{"code" => code, "name" => name}) do
  # Check if the game room exists
  if game_room_exists?(code) do
    Loupgarou.GameLogic.GameProcess.add_player(name, code)
    redirect(conn, to: "/#{code}/#{name}/waiting_room_player_live")
  else
    conn
    |> put_status(:not_found)
    |> json(%{error: "Game room does not exist."})
  end
end


 # def waiting_room_master(conn, %{"code" => code, "name" => name}) do
 #   playerMap=Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
 #   render(conn, "waiting_room_master.html", code: code, playerName: name,  playerMap: playerMap)
 # end

#  def waiting_room_player(conn, %{"code" => code, "name" => name}) do
#    playerMap=Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
#    render(conn, "waiting_room_player.html", code: code, playerName: name,  playerMap: playerMap)
#  end



  #TODO: Consider to create setRole, ... function in the GameProcess for consistency. Or maybe remove getRole, by sending the message directly to the playerProcess and add a reveice block here.
  def distribute_role(conn, %{"code" => code, "name" => name}) do
    IO.inspect("the code is:#{code}")
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    nbOfPlayers = map_size(playerMap)
    # ration between villlagers and werewolf = 1 to 3. => 1 Wolf = 3 Villagers
    nbOfWolf = round(nbOfPlayers/3)


    # For the number of wolf it looks for a random player of the playerList and set its role to Wolf.
    # TODO: check that this work with nbOfWolf == 1
     Enum.each(1..nbOfWolf, fn _i ->
      {_playerName, pid}= Enum.random(Map.to_list(playerMap))
      send(pid, {:setRole, :Werewolf})
    end)
    # TODO: Maybe add receive block to make sure that the player process has received the message (via gameProcess?)
    # Set the process to sleep to make sure that all the werewolf players received their role before continuing
    Process.sleep(2000)


    # If player's role == :unknown, then the role :Villager is assign to this player.
    Enum.each(playerMap, fn {playerName, pid} ->
      role = Loupgarou.GameLogic.GameProcess.getRole(playerName, code)
      if(role == :unknown) do
        send(pid,{:setRole, :Villager})
      end
    end)

    Process.sleep(2000)

    redirect(conn, to: "/show_role/" <> code <> "/" <> name)
    #render(conn, "role_distribution.html", code: code, name: name)
  end

  def show_role(conn, %{"code" => code, "name" => name}) do
    role = Loupgarou.GameLogic.GameProcess.getRole(name, code)
    if(role == :Werewolf) do
      render(conn, "wolf_role.html", code: code, name: name)
    else
      render(conn, "villager_role.html", code: code, name: name)
    end


  end



end
