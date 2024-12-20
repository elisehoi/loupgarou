defmodule LoupgarouWeb.DayVoteLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]

    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(code)
    nb_players = Loupgarou.GameLogic.GameProcess.getPlayerCount(code)
    LoupgarouWeb.Endpoint.subscribe("game:#{code}")

    # Assign values to the socket
    {:ok, assign(socket, name: name,
                         code: code,
                         playerMap: playerMap,
                         nb_players: nb_players,
                         clicked_players: clicked_players,
                         clicked: false
                         )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="role-container">
      <p>Villagers, it is your job to discover who has murdered your friend and take revenge. You have until nightfall to discuss and choose someone to kill</p>
      <img src="https://static.thenounproject.com/png/1938828-200.png" alt="Victim Image" width="300" height="200">

     <p> Please vote for the person you suspect of being a wolf </p>

      <%= for {player_name, _pid} <- @playerMap do %>
        <button
            class="clickable-button"
            type="button"
            phx-click="mark_voted"
            phx-value-player_name={player_name}
            phx-disabled={@clicked}
          >
            <%= if @clicked, do: "You have already Voted, wait for the others to vote", else: player_name %>
          </button>

        <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("mark_voted", %{"player_name" => player_name}, socket) do
    Loupgarou.GameLogic.GameProcess.add_vote(player_name, socket.assigns.code)
    # Increment the count of clicked players in the game logic
    Loupgarou.GameLogic.GameProcess.increment_clicked_players(socket.assigns.code)

    # Get the updated clicked players count after incrementing
    updated_clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(socket.assigns.code)

    # Broadcast the updated count to all players in the same game
    LoupgarouWeb.Endpoint.broadcast!(
      "game:#{socket.assigns.code}",
      "update_clicked_players_dayVote",
      %{clicked_players: updated_clicked_players}
    )

    # Update the socket state for the current player
    socket =
      socket
      |> assign(clicked: true)
      |> assign(clicked_players: updated_clicked_players)

    # Check if all wolves have voted
    if updated_clicked_players == socket.assigns.nb_players do
      Loupgarou.GameLogic.GameProcess.reset_clicked_players(socket.assigns.code)
      db = Loupgarou.GameLogic.GameProcess.getstatusDatabase(socket.assigns.code)
      phase = db.phase

     case phase do
      :EndWolf -> LoupgarouWeb.Endpoint.broadcast!(
                  "game:#{socket.assigns.code}",
                  "redirect_to_end_wolf", %{})

                   # Redirect the current player to the night phase
                    {:noreply, push_navigate(socket, to: "/win_wolf_live")}
      :EndVillager -> LoupgarouWeb.Endpoint.broadcast!(
                      "game:#{socket.assigns.code}",
                        "redirect_to_end_villager", %{})
                        {:noreply, push_navigate(socket, to: "/win_villager_live")}
      _else ->
         # Broadcast a message to redirect all players
        LoupgarouWeb.Endpoint.broadcast!(
        "game:#{socket.assigns.code}",
        "redirect_to_count_vote_day", %{})
         # Redirect the current player to the night phase
      {:noreply, push_navigate(socket, to: "/count_vote_day/#{socket.assigns.code}/#{socket.assigns.name}")}
     end

    else
      # Not all players are ready, just update the count
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "update_clicked_players_dayVote", payload: %{clicked_players: clicked_players}}, socket) do
    {:noreply, assign(socket, clicked_players: clicked_players)}
  end

  @impl true
  def handle_info(%{event: "redirect_to_count_vote_day"}, socket) do
    # Redirect to the vote counting route
    {:noreply, push_navigate(socket,
       to: "/count_vote_day/#{socket.assigns.code}/#{socket.assigns.name}"
     )}
  end

  @impl true
def handle_info("redirect_to_end_villager", socket) do
  IO.puts("redirect to win villager")
  {:noreply, push_navigate(socket, to: "/win_villager_live")}
end

@impl true
def handle_info("redirect_to_end_wolf", socket) do
  IO.puts("redirect to win wolf")
  {:noreply, push_navigate(socket, to: "/win_wolf_live")}
end

end
