defmodule Loupgarou.GameLogic.GameProcess do
  # List of players and their role, stored as a list of map or tuple
  use GenServer

  def start_link(hostID) do
    GenServer.start_link(__MODULE__, hostID, name: __MODULE__)
  end

  #cast used to send synchronous request. The problem could be that some feature aren't instantiated yet before used...
  #call used to send asynchrounous request, meaning the caller cannot do anything until it receives a reply from this method
  def add_player(playerName) do
    #Maybe use call? It won't be synchrounous, but avoid the problem not all players are added before the game starts??
    GenServer.cast(__MODULE__, {:addPlayer, playerName})
  end

  def getState() do
    GenServer.call(__MODULE__, {:getState})
  end

  def getPlayer(playerName) do
    GenServer.call(__MODULE__, {:getPlayer, playerName})
  end


  @impl true
  def init(host) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [host, :unknown, :alive])
    # Process.register(pid, host)
    initial_state = %{players: [%{host=>pid}],
                      phase: :waiting # or day or Night
                      }

    IO.puts("GenServer initialized ") # get pid to track which gameProcess has be initialized??
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:addPlayer, newPlayer}, state) do
    pid = spawn(Loupgarou.GameLogic.PlayerProcess, :loop, [newPlayer, :unknown, :alive])
    # Process.register(pid, newPlayer)
    newPlayerList = state.players ++ [%{newPlayer=>pid}]
    newState = %{state| players: newPlayerList}
    IO.puts("new player has been added")
    {:noreply, newState}
  end

  @impl true
  def handle_call({:getState}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:getPlayer, playerName}, _from, state) do
    case Enum.find(state.players, fn player -> Map.has_key?(player, playerName) end) do
      true -> {:reply, player[playerName], state}
      false-> {:reply, "help", state}
    end
  end
end
