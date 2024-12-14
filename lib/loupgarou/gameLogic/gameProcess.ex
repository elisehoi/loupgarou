defmodule Loupgarou.GameLogic.GameProcess do
  # List of players and their role, stored as a list of map or tuple
  use GenServer

  def start(playerName, code) do
    GenServer.start_link(__MODULE__, playerName, name: String.to_atom(code))
  end

  #cast used to send synchronous request. The problem could be that some feature aren't instantiated yet before used...
  #call used to send asynchrounous request, meaning the caller cannot do anything until it receives a reply from this method
  def add_player(playerName, code) do
    #Maybe use call? It won't be synchrounous, but avoid the problem not all players are added before the game starts??
    GenServer.cast(String.to_atom(code), {:addPlayer, playerName})
  end

  def getmapOfPlayersAndPhaseOfTheGame(code) do
    GenServer.call(String.to_atom(code), {:getmapOfPlayersAndPhaseOfTheGame})
  end

  def getPlayerPID(playerName, code) do
    GenServer.call(String.to_atom(code), {:getPlayerPID, playerName})
  end

  def getPlayerList(code) do
    GenServer.call(String.to_atom(code), {:getPlayerList})
  end

  def getRole(playerName, code) do
    GenServer.call(String.to_atom(code), {:getRole, playerName})
  end




  # loop: same as while go on robot loop but for the player processes (handles messages)
  # mapOfPlayersAndPhaseOfTheGame : small database (map) with player names and player pids + the phase of the game (waiting room, night or day)

  @impl true
  def init(playerName) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [playerName, :unknown, :alive])
    # Process.register(pid, host)
    initial_mapOfPlayersAndPhaseOfTheGame = %{players: [%{playerName=>pid}],
                                              phase: :waiting # or day or Night
                                              }

    IO.puts("GenServer initialized ") # get pid to track which gameProcess has be initialized??
    {:ok, initial_mapOfPlayersAndPhaseOfTheGame}
  end

# just does stuff with no reply
  @impl true
  def handle_cast({:addPlayer, newPlayer}, mapOfPlayersAndPhaseOfTheGame) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [newPlayer, :unknown, :alive])
    # Process.register(pid, newPlayer)
    newPlayerList = mapOfPlayersAndPhaseOfTheGame.players ++ [%{newPlayer=>pid}]
    newmapOfPlayersAndPhaseOfTheGame = %{mapOfPlayersAndPhaseOfTheGame| players: newPlayerList}
    IO.puts("new player has been added")
    {:noreply, newmapOfPlayersAndPhaseOfTheGame}
  end

# replies to a request
  @impl true
  def handle_call({:getmapOfPlayersAndPhaseOfTheGame}, _from, mapOfPlayersAndPhaseOfTheGame) do
    {:reply, mapOfPlayersAndPhaseOfTheGame, mapOfPlayersAndPhaseOfTheGame}
  end

  @impl true
  def handle_call({:getPlayerPID, playerName}, _from, mapOfPlayersAndPhaseOfTheGame) do
    case Enum.find(mapOfPlayersAndPhaseOfTheGame.players, fn player -> Map.has_key?(player, playerName) end) do
      nil-> {:reply, "help", mapOfPlayersAndPhaseOfTheGame}
      player -> {:reply, player[playerName], mapOfPlayersAndPhaseOfTheGame}
    end
  end

  @impl true
  def handle_call({:getPlayerList}, _from, mapOfPlayersAndPhaseOfTheGame) do
    {:reply, mapOfPlayersAndPhaseOfTheGame.players, mapOfPlayersAndPhaseOfTheGame}
  end

  @impl true
  def handle_call({:getRole, playerName}, _from, mapOfPlayersAndPhaseOfTheGame) do
    case Enum.find(mapOfPlayersAndPhaseOfTheGame.players, fn player -> Map.has_key?(player, playerName) end) do
      nil -> {:error, "The player doesn't exist", mapOfPlayersAndPhaseOfTheGame}
      {_player, pid} -> send(pid, {:getRole, self()})
                        receive do
                          {:replyRole, role} -> {:reply, role, mapOfPlayersAndPhaseOfTheGame}
                        after
                          2000 -> {:reply, "Timeout while getting Role", mapOfPlayersAndPhaseOfTheGame}
                        end
    end


  end



end
