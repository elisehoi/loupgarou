defmodule LoupgarouWeb.WolfRoleLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    code = params["code"]
    name = params["name"]

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
        <style>
      /* Background and container styling */
      .role-container {
        background-image: url('https://www.wallart.com/media/catalog/product/cache/871f459736130e239a3f5e6472128962/w/0/w05318-small.jpg');
        background-size: cover;
        background-position: center;
        padding: 20px;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }

      /* White transparent background box for content */
      .content-box {
        background-color: rgba(255, 255, 255, 0.8); /* White with transparency */
        padding: 20px;
        border-radius: 10px;
        max-width: 800px;
        width: 100%;
        text-align: center;
      }

      /* Text styling */
      h1, h2, p {
        color: #333; /* Dark text for better readability */
      }

      /* Button styling */
      .clickable-button {
        margin: 10px;
        padding: 10px 20px;
        font-size: 16px;
        cursor: pointer;
        border: none;
        border-radius: 5px;
        background-color: #4CAF50; /* Button color */
        color: white;
      }

      .clickable-button:hover {
        background-color: #45a049;
      }
    </style>

    <div class="role-container">
      <div class="content-box">
      <h1>Your role is...</h1>
      <img
        src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTck_Fl6l-F-2X5l5aHNtgz3nXVt-La9cicXA&s"
        alt="Werewolf"
      />
      <h2>A Werewolf</h2>
      <p>
        The werewolf is the game’s main antagonist. Their only job is to stalk the villagers at night and kill them without getting
        caught. This role can win by eliminating all the villagers (how lovely?!)
      </p>

      <!-- Button -->
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
        #%{url: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}"}
        %{url: "/#{socket.assigns.code}/#{socket.assigns.name}/wolf_night_live"}
      )

      # Redirect the current player to the night phase
      #{:noreply, push_navigate(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
      {:noreply, push_navigate(socket, to: "/#{socket.assigns.code}/#{socket.assigns.name}/wolf_night_live")}
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
    {:noreply, push_navigate(socket, to: "/#{socket.assigns.code}/#{socket.assigns.name}/wolf_night_live")}
  end
end
