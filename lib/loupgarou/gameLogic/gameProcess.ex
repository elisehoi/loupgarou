defmodule Loupgarou.GameLogic.GameProcess do
  # List of players and their role, stored as a list of map or tuple
  use GenServer

  def start(playerName, gameCode) do
    GenServer.start_link(__MODULE__, playerName, name: String.to_atom(gameCode))
  end

  #cast used to send synchronous request. The problem could be that some feature aren't instantiated yet before used...
  #call used to send asynchrounous request, meaning the caller cannot do anything until it receives a reply from this method
  def add_player(playerName, code) do
    #Maybe use call? It won't be synchrounous, but avoid the problem not all players are added before the game starts??
    # The first parameter is the name assigned to each GameProcess (unique).
    # The second parameter is the message send to the corresponding GameProcess
    GenServer.cast(String.to_atom(code), {:addPlayer, playerName})
  end

  def getstatusDatabase(code) do

    # call can take and third parameter.
    # The third Parameter is the timeout duration. If the process doesn't respond within this given time, it will raise an error. By default it's set to 5000ms
    GenServer.call(String.to_atom(code), {:getstatusDatabase})
  end

  def getPlayerPID(playerName, code) do
    GenServer.call(String.to_atom(code), {:getPlayerPID, playerName})
  end

  def getPlayerMap(code) do
    GenServer.call(String.to_atom(code), {:getPlayerMap})
  end

  def getRole(playerName, code) do
    GenServer.call(String.to_atom(code), {:getRole, playerName})
  end




  # loop: same as while go on robot loop but for the player processes (handles messages)
  # statusDatabase : small database (map) with player names and player pids + the phase of the game (waiting room, night or day)

  @impl true
  def init(playerName) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [playerName, :unknown, :alive])
    # Process.register(pid, host)
    initial_statusDatabase = %{
      players: %{playerName=>pid},
      phase: :waiting # or day or Night
      }

    IO.puts("GenServer initialized ") # get pid to track which gameProcess has be initialized??
    {:ok, initial_statusDatabase}
  end

# just does stuff with no reply
  @impl true
  def handle_cast({:addPlayer, newPlayer}, statusDatabase) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [newPlayer, :unknown, :alive])
    # Process.register(pid, newPlayer)
    players = Map.put(statusDatabase.players, newPlayer, pid)
    newstatusDatabase = %{statusDatabase| players: players}
    IO.puts("new player has been added")
    {:noreply, newstatusDatabase}
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



end
