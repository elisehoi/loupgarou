defmodule LoupgarouWeb.WaitingRoomMasterLive do
  use LoupgarouWeb, :live_view

  alias Loupgarou.GameLogic.GameProcess
  alias LoupgarouWeb.PubSub

  @impl true
  def mount(%{"code" => code, "name" => name}, _session, socket) do
    if connected?(socket) do
      IO.puts("CONNECTED Subscribing to game topic: game:#{code}")
      # Subscribe to updates from the game process
      Phoenix.PubSub.subscribe(LoupgarouWeb.PubSub, "game:#{code}")
    end
        # Fetch the initial list of players
    player_map = GameProcess.getPlayerMap(code)

    {:ok,
     assign(socket,
       code: code,
       player_name: name,
       player_map: player_map
     )}
  end

  @impl true
  def handle_info({:player_joined, new_player}, socket) do
    # Update the player map dynamically when a new player joins
    updated_player_map = Map.put(socket.assigns.player_map, new_player, :pid_placeholder)
    {:noreply, assign(socket, player_map: updated_player_map)}
  end

  def handle_info({:player_left, player_name}, socket) do
    # Update the player map dynamically when a player leaves
    updated_player_map = Map.delete(socket.assigns.player_map, player_name)
    {:noreply, assign(socket, player_map: updated_player_map)}
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    # Broadcast a "game_started" message to all players
    IO.inspect("MASTER Broadcasting game_started to topic: game:#{socket.assigns.code}")
    Phoenix.PubSub.broadcast(LoupgarouWeb.PubSub, "game:#{socket.assigns.code}", {:game_started})

    # Redirect to the role distribution page
    {:noreply,
     push_navigate(socket,
       to: "/role_distribution/#{socket.assigns.code}/#{socket.assigns.player_name}"
     )}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <p>Your game with the game code: <strong><%= @code %></strong> will start as soon as you wish. A minimum of 3 players are required for the game to start.</p>
    <br>
    <p>Players online:</p>
    <br>
    <ul style="list-style-type: disc; margin-left: 20px;">
      <%= for {player_name, _pid} <- @player_map do %>
        <li style="margin-bottom: 5px;"><%= player_name %></li>
      <% end %>
    </ul>
    <br>
    <button phx-click="start_game" class="clickable-button">
      Start Game!
    </button>

    <style>
      .clickable-button {
        background-color: #252531;
        color: white; /*  text color*/
        border: none;
        padding: 8px 18px; /* Add padding */
        text-align: center;
        text-decoration: none;
        display: inline-block;
        font-family: Apple Chancery, cursive;
        font-weight: bold;
        font-size: 18px;
        border-radius: 8px; /* Rounded corners */
        cursor: pointer;
        transition: background-color 0.3s ease;
      }

      .clickable-button:hover {
        background-color: #000000;
      }
    </style>
    """
  end
end
