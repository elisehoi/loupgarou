defmodule Loupgarou.GameLogic.GameProcess do
  # List of players and their role, stored as a list of map or tuple
  use GenServer

  def start(playerName, gameCode) do
    # The gameCode is assigned as the name for the gameProcess. This GameProcess can then be called via this gameCode
    GenServer.start_link(__MODULE__, {playerName, gameCode}, name: String.to_atom(gameCode))
  end

  #cast used to send synchronous request. The problem could be that some feature aren't instantiated yet before used...
  #call used to send asynchrounous request, meaning the caller cannot do anything until it receives a reply from this method
  def add_player(playerName, code) do
    # Maybe use call? It won't be synchrounous, but avoid the problem not all players are added before the game starts??
    # The first parameter is the name assigned to each GameProcess (unique).
    # The second parameter is the message send to the corresponding GameProcess
    GenServer.cast(String.to_atom(code), {:addPlayer, playerName})
  end

  def add_vote(victim, code) do
    GenServer.cast(String.to_atom(code), {:addVote, victim})
  end

  def getstatusDatabase(code) do
    # call can take a third parameter.
    # The third Parameter is the timeout duration. If the process doesn't respond within this given time, it will raise an error. By default it's set to 5000ms
    GenServer.call(String.to_atom(code), {:getstatusDatabase})
  end

  def getPlayerPID(playerName, code) do
    GenServer.call(String.to_atom(code), {:getPlayerPID, playerName})
  end

  def getPlayerMap(code) do
    GenServer.call(String.to_atom(code), {:getPlayerMap})
  end

  def getPlayerCount(code) do
    map_size(getPlayerMap(code))
  end

  def setRole(playerName, code, newRole) do
    GenServer.call(String.to_atom(code), {:setRole, playerName, newRole})
  end

  def getRole(playerName, code) do
    GenServer.call(String.to_atom(code), {:getRole, playerName})
  end

  def resetVote(code) do
    GenServer.call(String.to_atom(code), {:resetVote})
  end



  def killPlayer(playerName, code) do
    GenServer.call(String.to_atom(code), {:killPlayer, playerName})
  end

  # Increment the click count on buttons that require all players to click on
  def increment_clicked_players(code) do
    GenServer.cast(String.to_atom(code), {:incrementClickedPlayers})
  end

  def reset_clicked_players(code) do
    GenServer.cast(String.to_atom(code), {:resetClickedPlayers})
  end
  def get_clicked_players(code) do
    GenServer.call(String.to_atom(code), {:getClickedPlayers}, 15_000)
  end

  # loop: same as while go on robot loop but for the player processes (handles messages)
  # statusDatabase : small database (map) with player names and player pids + the phase of the game (waiting room, night or day)
  @impl true
  def init({playerName, game_code}) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [playerName, :unknown, :alive])

    initial_statusDatabase = %{
      players: %{playerName=>pid},
      phase: :waiting, # or day or Night
      votes: %{playerName => 0},
      expectedVoteWolf: 0,
      expectedVote: 0,
      gamecode: game_code,
      clickedPlayers: 0

      }

      {:ok, initial_statusDatabase}
  end

  # broadcast functions to the live views (of the player list)
  defp broadcast(game_code, message) do
    Phoenix.PubSub.broadcast(LoupgarouWeb.PubSub, "game:#{game_code}", message)
  end


# just does stuff with no reply
@impl true
def handle_cast({:addPlayer, newPlayer}, statusDatabase) do
  pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [newPlayer, :unknown, :alive])
  players = Map.put(statusDatabase.players, newPlayer, pid)
  updatedDatabase = %{statusDatabase| players: players}
  votes = Map.put(statusDatabase.votes, newPlayer, 0)
  newstatusDatabase = %{updatedDatabase| votes: votes}

  # broadcast the new player event to the live views so they can update
  broadcast(statusDatabase.gamecode, {:player_joined, newPlayer})

  IO.puts("new player has been added")
  {:noreply, newstatusDatabase}
end

  @impl true
  def handle_cast({:addVote, victim}, statusDatabase) do
    currentVoteCount = Map.get(statusDatabase.votes, victim, 0)
    updatedVotes = Map.put(statusDatabase.votes, victim, currentVoteCount + 1)
    updatedDatabase = %{statusDatabase | votes: updatedVotes}

    currentExpectedVote = Map.get(updatedDatabase, :expectedVoteWolf, 0)
    newDatabase = %{updatedDatabase | expectedVoteWolf: currentExpectedVote - 1}

    IO.inspect("#{victim} has now #{currentVoteCount+1} votes" )
    {:noreply, newDatabase}
  end


# replies to a request
  @impl true
  def handle_call({:getstatusDatabase}, _from, statusDatabase) do
    {:reply, statusDatabase, statusDatabase}
  end

  @impl true
  def handle_call({:getPlayerPID, playerName}, _from, statusDatabase) do
    # map.get look for the value associated with the key playerName.
    pid = Map.get(statusDatabase.players, playerName, nil)
    {:reply, pid, statusDatabase}
  end

  @impl true
  def handle_call({:getPlayerMap}, _from, statusDatabase) do
    {:reply, statusDatabase.players, statusDatabase}
  end

  @impl true
  def handle_call({:setRole, playerName, newRole}, _from, statusDatabase) do
    pid = Map.get(statusDatabase.players, playerName, nil)
    send(pid, {:setRole, newRole, self()})
    receive do
      {:replySetRole} -> {:reply, :ok, statusDatabase}
    after 3000 ->
      {:reply, :error, statusDatabase}
    end
  end

  @impl true
  def handle_call({:getRole, playerName}, _from, statusDatabase) do
    case Map.get(statusDatabase.players, playerName, nil) do
      nil -> {:reply, "The player doesn't exist", statusDatabase}
      pid -> send(pid, {:getRole, self()})
      receive do
        {:replyRole, role} -> {:reply, role, statusDatabase}
      after
        2000 -> {:reply, "Timeout while getting Role", statusDatabase}
      end
    end
  end

  @impl true
  def handle_call({:resetVote}, _from, statusDatabase) do
    newVoteDatabase = Map.new(statusDatabase.votes, fn {player_name, _count} ->
      {player_name, 0}
    end)

    updatedVotes = Map.put( statusDatabase, :votes, newVoteDatabase)

    nbOfPlayers = map_size(statusDatabase.players)
    nbOfWolf = round(nbOfPlayers/3)
    updatedExpectedWolfVote = Map.put(updatedVotes, :expectedVoteWolf, nbOfWolf)
    updatedDB = Map.put(updatedExpectedWolfVote, :expectedVote, nbOfPlayers)
    {:reply, :ok, updatedDB}
  end

  @impl true
  def handle_call({:getClickedPlayers}, _from, statusDatabase) do
    {:reply, statusDatabase.clickedPlayers, statusDatabase}
    end

    @impl true
    def handle_cast({:resetClickedPlayers}, statusDatabase) do

      updatedClickedPlayers = 0
      updatedDatabase = %{statusDatabase | clickedPlayers: updatedClickedPlayers}
      IO.inspect("reset clicked players to #{updatedDatabase.clickedPlayers}")
      {:noreply, updatedDatabase}
    end

  def handle_cast({:incrementClickedPlayers}, statusDatabase) do
    updatedClickedPlayers = statusDatabase.clickedPlayers + 1
    IO.puts(updatedClickedPlayers)
    updatedDatabase = %{statusDatabase | clickedPlayers: updatedClickedPlayers}
    {:noreply, updatedDatabase}
  end


  @impl
  def handle_call({:killPlayer, playerName}, _from, statusDatabase) do

    case Map.get(statusDatabase.players, playerName, nil) do
      nil -> {:reply, "The player doesn't exist", statusDatabase}
      pid -> send(pid, {:dead, self()})
      receive do
        {:replyDead, :ok} ->
          newPlayers = Map.delete(statusDatabase.players, playerName)
          updatedDatabase = Map.put(statusDatabase, :players, newPlayers)
          {:reply, :ok, updatedDatabase}
        after
        2000 -> {:reply, "Timeout while killing player #{playerName}", statusDatabase}
      end
    end
  end

end
