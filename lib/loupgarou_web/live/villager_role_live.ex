defmodule LoupgarouWeb.VillagerRoleLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `code` and `name` from URL parameters
    code = params["code"]
    name = params["name"]

    # Get total players and the count of players who have clicked the button
    total_players = Loupgarou.GameLogic.GameProcess.getPlayerCount(code)
    clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(code)

    # Subscribe to the PubSub topic for the game
    LoupgarouWeb.Endpoint.subscribe("game:#{code}")

    # Initialize state
    socket =
      socket
      |> assign(code: code, name: name)
      |> assign(total_players: total_players, clicked_players: clicked_players, clicked: false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="role-container">
      <h1>Your role is...</h1>
      <img
        src="https://images.vexels.com/media/users/3/128325/isolated/preview/0f52205b21536ca0dbbdac51891348e0-old-farmer-cartoon.png"
        alt="Villager"
      />
      <h2>A Villager</h2>
      <p>
        The most commonplace role, a simple Villager, spends the game trying to
        root out who they believe the werewolves are.
      </p>

      <!-- Ready Button -->
      <button
        class="clickable-button"
        type="button"
        phx-click="mark_ready"
        phx-disabled={@clicked}
        style={if @clicked, do: "background-color: grey;", else: ""}
      >
        <%= if @clicked, do: "Ready", else: "Understood!" %>
      </button>

      <p>Players Ready: <%= @clicked_players %> / <%= @total_players %></p>
    </div>
    """
  end

  @impl true
  def handle_event("mark_ready", _value, socket) do
    # Increment the count of clicked players in the game logic
    Loupgarou.GameLogic.GameProcess.increment_clicked_players(socket.assigns.code)

    # Get the updated clicked players count after incrementing
    updated_clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(socket.assigns.code)

    # Broadcast the updated count to all players in the same game
    LoupgarouWeb.Endpoint.broadcast!(
      "game:#{socket.assigns.code}",
      "update_clicked_players",
      %{clicked_players: updated_clicked_players}
    )

    # Update the socket state for the current player
    socket =
      socket
      |> assign(clicked: true)
      |> assign(clicked_players: updated_clicked_players)

    # Check if all players are ready
    if updated_clicked_players == socket.assigns.total_players do
      Loupgarou.GameLogic.GameProcess.reset_clicked_players(socket.assigns.code)

      # Broadcast a message to redirect all players
      LoupgarouWeb.Endpoint.broadcast!(
        "game:#{socket.assigns.code}",
        "redirect_to_night",
        %{url: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}"}
      )

      # Redirect the current player to the night phase
      {:noreply, push_redirect(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
    else
      # Not all players are ready, just update the count
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "update_clicked_players", payload: %{clicked_players: clicked_players}}, socket) do
    # Update the clicked_players count for all players
    {:noreply, assign(socket, clicked_players: clicked_players)}
  end

  def handle_info(%{event: "redirect_to_night", payload: _}, socket) do
    # Redirect all players to the night phase
    {:noreply, push_redirect(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
  end
end
