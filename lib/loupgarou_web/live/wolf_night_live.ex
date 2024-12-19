defmodule LoupgarouWeb.WolfNightLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `code` and `name` from URL parameters
    code = params["code"]
    name = params["name"]

    # Here you should fetch or assign the list of non-wolf players (replace `get_non_wolf_players/1`)
    not_wolf = get_non_wolf_players(code)

    total_players = Loupgarou.GameLogic.GameProcess.getPlayerCount(code)
    nb_wolfs = total_players - length(not_wolf)
    clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(code)

    {:ok, assign(socket,
                code: code,
                name: name,
                notWolf: not_wolf,
                nbWolf: nb_wolfs,
                clicked_players:
                clicked_players,
                clicked: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
     <style>
    /* Background and container styling */
    .role-container {
      background-image: url('https://media.istockphoto.com/id/1466669509/vector/night-starry-sky-with-full-moon-and-cloud-vector-background-with-cloudy-sky-moonlight.jpg?s=612x612&w=0&k=20&c=pZqh5rjgNcHq4lubXOG2chsXWChW-74GMd_JGfy6zVo=');
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
    h1, p {
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
      <h1>It's night time and the Wolves are waking up...</h1>
      <img
        src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWPu1_hvNpM4hFMKaNHDByA5iT8Dgf1rI2gPfK-xkVNM63A0yGOTuu8dIhYXDx_PAjMR8&usqp=CAU"
        alt="lupi"
        width="353"
        height="167"
      />
      <p>You wake up thirsty for blood. Who will be your victim tonight?</p>

      <!-- Loop through non-wolf players to create buttons -->
      <%= for player_name <- @notWolf do %>
        <button
            class="clickable-button"
            type="button"
            phx-click="mark_ready"
            phx-value-player_name={player_name}
            phx-disabled={@clicked}
          >
            <%= if @clicked, do: "Voted", else: player_name %>
          </button>

      <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("mark_ready", %{"player_name" => player_name}, socket) do
    Loupgarou.GameLogic.GameProcess.add_vote(player_name, socket.assigns.code)
    Loupgarou.GameLogic.GameProcess.increment_clicked_players(socket.assigns.code)

    updated_clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(socket.assigns.code)

    # broadcast the updated count to all players in the same game
    LoupgarouWeb.Endpoint.broadcast!(
      "game:#{socket.assigns.code}",
      "update_clicked_players",
      %{clicked_players: updated_clicked_players}
    )

    socket =
      socket
      |> assign(clicked: true)
      |> assign(clicked_players: updated_clicked_players)

    # check if all wolves have voted
    if updated_clicked_players == socket.assigns.nbWolf do
      Loupgarou.GameLogic.GameProcess.reset_clicked_players(socket.assigns.code)

      # broadcast a message to redirect all players
      LoupgarouWeb.Endpoint.broadcast!(
        "game:#{socket.assigns.code}",
        "redirect_to_count_vote_wolf", %{}
      )

      # redirect the current player to the night phase

      {:noreply, push_navigate(socket, to: "/count_vote/#{socket.assigns.code}/#{socket.assigns.name}")}
    else
      # not all players are ready, just update the count
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "update_clicked_players", payload: %{clicked_players: clicked_players}}, socket) do
    {:noreply, assign(socket, clicked_players: clicked_players)}
  end





  @impl true
  def handle_event(%{event: "redirect_to_count_vote_wolf"}, socket) do
    # redirect to the vote counting route
    {:noreply,
     push_navigate(socket,
       to: "/count_vote/#{socket.assigns.code}/#{socket.assigns.name}"
     )}
  end


  defp get_non_wolf_players(code) do
    _players = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)

  #for name in players
    |> Enum.reduce([], fn {name, _pid}, not_werewolves ->
      role = Loupgarou.GameLogic.GameProcess.getRole(name, code)

    #  if role is not :Werewolf
    if role != :Werewolf do
        #  add to a not werewolf list
        [name | not_werewolves]
      else
        not_werewolves
      end
    end)
  end

end
