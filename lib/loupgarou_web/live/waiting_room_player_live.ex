defmodule LoupgarouWeb.WaitingRoomPlayerLive do
  use LoupgarouWeb, :live_view

  alias Loupgarou.GameLogic.GameProcess
  alias LoupgarouWeb.PubSub

  @impl true
  def mount(%{"code" => code, "name" => name}, _session, socket) do    if connected?(socket) do
      # Subscribe to updates from the game process if needed
      Phoenix.PubSub.subscribe(LoupgarouWeb.PubSub, "game:#{code}")
    end

    # Fetch the initial list of players
    player_map = GameProcess.getPlayerMap(code)

    {:ok, assign(socket, code: code, player_name: name, player_map: player_map)}
  end

  @impl true
  def handle_info({:player_joined, new_player}, socket) do
    # Add the new player to the player map
    updated_player_map = Map.put(socket.assigns.player_map, new_player, :pid_placeholder)
    {:noreply, assign(socket, player_map: updated_player_map)}
  end

  def handle_info({:player_left, player_name}, socket) do
    # Remove the player who left
    updated_player_map = Map.delete(socket.assigns.player_map, player_name)
    {:noreply, assign(socket, player_map: updated_player_map)}
  end

  @impl true
  def handle_info({:game_started}, socket) do
    IO.puts("PLAYER RECEIVED GAME STARTED")
    Process.sleep(2000)
    {:noreply,
     push_redirect(socket,
       to: "/show_role/#{socket.assigns.code}/#{socket.assigns.player_name}"
     )}

  end


  @impl true
  def render(assigns) do
    ~H"""
    <p>You are waiting for game <strong><%= @code %></strong> to start. The host will start the game.</p>
    <br>
    <p>Players online:</p>
    <br>
    <ul style="list-style-type: disc; margin-left: 20px;">
      <%= for {player_name, _pid} <- @player_map do %>
        <li style="margin-bottom: 5px;"><%= player_name %></li>
      <% end %>
    </ul>
    """
  end
end
