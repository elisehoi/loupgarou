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
    <style>
      /* Background and container styling */
      .role-container {
        background-image: url('https://images7.alphacoders.com/128/1288361.jpg');
        background-size: cover;
        background-position: center;
        padding: 20px;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        margin-top: -25px;
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
        src="https://images.vexels.com/media/users/3/128325/isolated/preview/0f52205b21536ca0dbbdac51891348e0-old-farmer-cartoon.png"
        alt="Villager"
        style="height: 50%; width: 50%;"
      />
      <h2>A Villager</h2>
      <p>
        The most commonplace role, a simple Villager. You will spend your time trying to figure out who the Werewolves are, as you are awake during the day. You can do so by discussing with other players, and then vote for who to eliminate. Beware, when you sleep at night, the wolves might want to kill you... but if the villagers manage to eliminate all the Werewolves, they win!
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
    </div>
    """
  end

  @impl true
  def handle_event("mark_ready", _value, socket) do
    Loupgarou.GameLogic.GameProcess.increment_clicked_players(socket.assigns.code)

    updated_clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(socket.assigns.code)

    LoupgarouWeb.Endpoint.broadcast!(
      "game:#{socket.assigns.code}",
      "update_clicked_players",
      %{clicked_players: updated_clicked_players}
    )

    socket =
      socket
      |> assign(clicked: true)
      |> assign(clicked_players: updated_clicked_players)

    if updated_clicked_players == socket.assigns.total_players do
      Loupgarou.GameLogic.GameProcess.reset_clicked_players(socket.assigns.code)

      LoupgarouWeb.Endpoint.broadcast!(
        "game:#{socket.assigns.code}",
        "redirect_to_night",
        %{url: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}"}
      )

      {:noreply, push_navigate(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "update_clicked_players", payload: %{clicked_players: clicked_players}}, socket) do
    {:noreply, assign(socket, clicked_players: clicked_players)}
  end

  @impl true
  def handle_info(%{event: "redirect_to_night", payload: _}, socket) do
    {:noreply, push_navigate(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
  end
end
