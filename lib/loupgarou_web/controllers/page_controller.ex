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


  #TODO: Consider to create setRole, ... function in the GameProcess for consistency. Or maybe remove getRole, by sending the message directly to the playerProcess and add a reveice block here.
  def distribute_role(conn, %{"code" => code, "name" => name}) do
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    IO.inspect(playerMap)
    nbOfPlayers = map_size(playerMap)
    # ration between villlagers and werewolf = 1 to 3. => 1 Wolf = 3 Villagers
    nbOfWolf = round(nbOfPlayers/3)

    IO.inspect("the amount of player is is:#{nbOfPlayers}")

    # For the number of wolf it looks for a random player of the playerList and set its role to Wolf.
    # TODO: This always generate at least one werewolf
     Enum.each(1..nbOfWolf, fn _i ->
      {playerName, _pid}= Enum.random(Map.to_list(playerMap))
      case Loupgarou.GameLogic.GameProcess.setRole(playerName, code, :Werewolf) do
        :error -> IO.inspect("There's a problem with setting role to Wolf")
        :ok -> nil
      end
    end)

    # If player's role == :unknown, then the role :Villager is assign to this player.
    Enum.each(playerMap, fn {playerName, _pid} ->
      role = Loupgarou.GameLogic.GameProcess.getRole(playerName, code)
      if(role == :unknown) do
        case Loupgarou.GameLogic.GameProcess.setRole(playerName, code, :Villager) do
          :error -> IO.inspect("There's a problem with setting role to villager")
          :ok -> nil
        end
      end
    end)

    redirect(conn, to: "/show_role/" <> code <> "/" <> name)
  end

  def show_role(conn, %{"code" => code, "name" => name}) do
    role = Loupgarou.GameLogic.GameProcess.getRole(name, code)
    if(role == :Werewolf) do
      redirect(conn, to: "/#{code}/#{name}/wolf_role_live")
      #render(conn, "wolf_role.html", code: code, name: name)
    else
      redirect(conn, to: "/#{code}/#{name}/villager_role_live")
      #render(conn, "villager_role.html", code: code, name: name)
    end
  end

  def night_time(conn, %{"code" => code, "name" => name}) do
    role=Loupgarou.GameLogic.GameProcess.getRole(name, code)
    IO.puts("here we ARRREE 1")
    if(role== :Werewolf) do
      playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
      IO.puts("here we ARRREE 2")

      list_of_not_wolves =
      for {playerName, _pid} <- playerMap,
        Loupgarou.GameLogic.GameProcess.getRole(playerName, code) != :Werewolf, do: playerName
        IO.puts("here we ARRREE 3")
        redirect(conn, to: "/#{code}/#{name}/wolf_night_live")
      #render(conn, "wolf_night.html", code: code, name: name, notWolf: list_of_not_wolves)
    else
      redirect(conn, to: "/#{code}/#{name}/night_live")
      #render(conn, "night.html", code: code, name: name)
    end
  end





end
