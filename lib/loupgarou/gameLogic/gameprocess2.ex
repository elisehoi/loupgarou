defmodule Loupgarou.GameLogic.GameProcess2 do
  # List of players and their role, stored as a list of map or tuple
  use GenServer

  def start(playerName, gameCode) do
    GenServer.start_link(__MODULE__, {playerName, gameCode}, name: String.to_atom(gameCode))
  end

  #cast used to send synchronous request. The problem could be that some feature aren't instantiated yet before used...
  #call used to send asynchrounous request, meaning the caller cannot do anything until it receives a reply from this method
  def add_player(playerName, code) do
    #Maybe use call? It won't be synchrounous, but avoid the problem not all players are added before the game starts??
    GenServer.cast(String.to_atom(code), {:addPlayer, playerName})
  end

  @spec getstatusDatabase(binary()) :: any()
  def getstatusDatabase(code) do
    GenServer.call(String.to_atom(code), {:getstatusDatabase})
  end

  def getPlayer(playerName, code) do
    GenServer.call(String.to_atom(code), {:getPlayer, playerName})
  end

  def getPlayerList(code) do
    IO.puts("GOT THE GET PLAYERS LIST CALL")
    GenServer.call(String.to_atom(code), {:getPlayerList})
  end


  # playerName: name of the player who creates the game
  # loop: same as while go on robot loop but for the player processes (handles messages)
  # statusDatabase : small database (map) with:
  # - the game code
  # - player names and player pids
  # - the phase of the game (waiting room, night or day)

  @impl true
  def init({playerName, gameCode}) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [playerName, :unknown, :alive])
    # Process.register(pid, host)
    initial_statusDatabase = %{
      gameCode: gameCode,
      players: [%{playerName=>pid}],
      phase: :waiting # or day or Night
      }

    IO.inspect(initial_statusDatabase, label: "initial_statusDatabase ") # get pid to track which gameProcess has be initialized??
    {:ok, initial_statusDatabase}
  end

# just does stuff with no reply
  @impl true
  def handle_cast({:addPlayer, newPlayer}, statusDatabase) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [newPlayer, :unknown, :alive])
    # Process.register(pid, newPlayer)
    newPlayerList = statusDatabase.players ++ [%{newPlayer=>pid}]
    newstatusDatabase = %{statusDatabase| players: newPlayerList}
    IO.puts("new player has been added")
    {:noreply, newstatusDatabase}
  end

# replies to a request message (generic)
  @impl true
  def handle_call({:getstatusDatabase}, _from, statusDatabase) do
    {:reply, statusDatabase, statusDatabase}
  end

  # gets a player's name
  @impl true
  def handle_call({:getPlayer, playerName}, _from, statusDatabase) do
    case Enum.find(statusDatabase.players, fn player -> Map.has_key?(player, playerName) end) do
      nil-> {:reply, "help", statusDatabase}
      player -> {:reply, player[playerName], statusDatabase}
    end
  end

  # get the player list
  @impl true
  def handle_call({:getPlayerList}, _from, statusDatabase) do
    IO.puts("INTERPRETING PLAYERS LIST CALL THIS IS THE STATUS DB PLAYERS")
    IO.inspect(statusDatabase.players)
    {:reply, statusDatabase.players, statusDatabase}
  end

  # get game code
  @impl true
  def handle_call({:getGameCode}, _from, statusDatabase) do
    {:reply, statusDatabase.gameCode, statusDatabase}

  end


end
