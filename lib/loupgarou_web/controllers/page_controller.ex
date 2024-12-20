defmodule LoupgarouWeb.PageController do
  use LoupgarouWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end


@doc """
generate access code for the game and url of the room
"""
  defp generate_access_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 5)
  end

  @doc """
  create game room using the access code, redirect to a new page with the access code as URL
  """
  def create_game_room(conn, %{"name" => name}) do
    code = generate_access_code()
    case Loupgarou.GameLogic.GameProcess.start(name, code) do
      {:ok, _pid} ->
        conn
        # Redirect to a new page with the access code and player name in the URL
          |> redirect(to: "/#{code}/#{name}/waiting_room_master_live")
      {:error, reason} ->
        IO.inspect("Page Controller: create_game_room fails to create gameProcess")
        conn
        |> put_flash(:error, "Failed to create game: #{inspect(reason)}")
        |> redirect(to: "/")

    end
end


@doc """
check if game room exists (used to join one)
"""
defp game_room_exists?(code) do
  case Process.whereis(String.to_atom(code)) do
    nil -> false  # no process found, game room does not exist
    _pid -> true   # process found, game room exists
  end
end

#check the players name thorught the map
def check_player_name(conn, %{"code" => code, "name" => name}) do
  # check if the game room exists
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

#join room
def join_game_room(conn, %{"code" => code, "name" => name}) do
  # check if the game room exists
  if game_room_exists?(code) do
    Loupgarou.GameLogic.GameProcess.add_player(name, code)
    redirect(conn, to: "/#{code}/#{name}/waiting_room_player_live")
  else
    conn
    |> put_status(:not_found)
    |> json(%{error: "Game room does not exist."})
  end
end


  @doc """
  role distribution at the beginning of the game and set of the percentage of wolves in the game
  """
  def distribute_role(conn, %{"code" => code, "name" => name}) do
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    nbOfPlayers = map_size(playerMap)
    # ration between villlagers and werewolf = 1 to 3. => 1 Wolf = 3 Villagers
    nbOfWolf = round(nbOfPlayers/3)

    # Assignation of the roles,  random player of the playerList and set its role to Wolf.
     available_players = Map.keys(playerMap)

    Enum.reduce(1..nbOfWolf, available_players, fn _i, available_players ->
      player_name = Enum.random(available_players)

      case Loupgarou.GameLogic.GameProcess.setRole(player_name, code, :Werewolf) do
        :error ->
          available_players # Return the unchanged list if there's an error

        :ok ->
          new_available_players = List.delete(available_players, player_name)
          new_available_players # Return the updated list without this player
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

  #once the distribution of the role is done, the players are redirected to the corresponding view
  def show_role(conn, %{"code" => code, "name" => name}) do
    role = Loupgarou.GameLogic.GameProcess.getRole(name, code)
    if(role == :Werewolf) do
      redirect(conn, to: "/#{code}/#{name}/wolf_role_live")
    else
      redirect(conn, to: "/#{code}/#{name}/villager_role_live")
    end
  end

  #different night time setting according to the role
  def night_time(conn, %{"code" => code, "name" => name}) do
    Loupgarou.GameLogic.GameProcess.resetVote(code)
    role=Loupgarou.GameLogic.GameProcess.getRole(name, code)
    if(role== :Werewolf) do
      playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
      for {playerName, _pid} <- playerMap,
        Loupgarou.GameLogic.GameProcess.getRole(playerName, code) != :Werewolf, do: playerName
        redirect(conn, to: "/#{code}/#{name}/wolf_night_live")
    else
      redirect(conn, to: "/#{code}/#{name}/night_live")
    end
  end


  @doc """
  take the votes of the werewolves, kills the voted player and checks whether the game is finished
  """
  def count_vote(conn, %{"code" => code, "name" => name}) do
    IO.inspect("#{name} Voted in game: #{code}")

    statusDB = Loupgarou.GameLogic.GameProcess.getstatusDatabase(code)
    {playerName, _value} = Enum.max_by(statusDB.votes, fn {_key, value} -> value end)
    Loupgarou.GameLogic.GameProcess.killPlayer(playerName, code)
    Loupgarou.GameLogic.GameProcess.resetVote(code)
    checkGameEndNight(code)
    # Broadcast to the "game:<code>" topic
    broadcast_payload = %{victim: playerName, code: code}
    LoupgarouWeb.Endpoint.broadcast!("game:#{code}", "wake_up", broadcast_payload)

    IO.inspect("Broadcast sent to game:#{code} with payload: #{inspect(broadcast_payload)}")

    redirect(conn, to: "/#{code}/#{name}/#{playerName}/morning_live")
  end

  @doc """
  does the same as for the werewolves voting system, but with all the players able to vote
  """
  def count_vote_day(conn, %{"code" => code, "name" => name}) do
    IO.inspect("#{name} has voted who he think is a wolf")
    statusDB = Loupgarou.GameLogic.GameProcess.getstatusDatabase(code)
    {playerName, _value} = Enum.max_by(statusDB.votes, fn {_key, value} -> value end)
    role = Loupgarou.GameLogic.GameProcess.getRole(playerName, code)
    Loupgarou.GameLogic.GameProcess.killPlayer(playerName, code)
    Loupgarou.GameLogic.GameProcess.resetVote(code)
    #   #render(conn, "result_vote.html", code: code, name: name, dead: playerName, role: role)
    checkGameEndDay(code)
    redirect(conn, to: "/#{code}/#{name}/#{playerName}/#{role}/result_day_vote_live")
  end

  @doc """
  end the games when either there are 0 wolves or 0 villagers after wolves action
  """
  defp checkGameEndNight( code) do
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    nbplayers = Kernel.map_size(playerMap)
    wolfs = for {playerName, _pid} <- playerMap,
      Loupgarou.GameLogic.GameProcess.getRole(playerName, code) == :Werewolf,
      do: playerName
    nbVillagers = nbplayers - length(wolfs)

    cond do
      nbVillagers == 0 ->Loupgarou.GameLogic.GameProcess.setPhase(code, :EndWolf)
      length(wolfs) == 0 -> Loupgarou.GameLogic.GameProcess.setPhase(code, :EndVillager)
      true -> nil
    end
  end

  @doc """
  end the games when either there are 0 wolves or 0 villagers after the village vote
  """
  defp checkGameEndDay(code) do
    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    nbplayers = Kernel.map_size(playerMap)
    wolfs = for {playerName, _pid} <- playerMap,
      Loupgarou.GameLogic.GameProcess.getRole(playerName, code) == :Werewolf,
      do: playerName
    nbVillagers = nbplayers - length(wolfs)

    cond do
      nbVillagers == 0 ->Loupgarou.GameLogic.GameProcess.setPhase(code, :EndWolf)
      nbplayers<3 -> Loupgarou.GameLogic.GameProcess.setPhase(code, :EndWolf)
      length(wolfs) == 0 -> Loupgarou.GameLogic.GameProcess.setPhase(code, :EndVillager)
      true -> nil
    end
  end



end
