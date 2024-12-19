defmodule LoupgarouWeb.ResultDayVoteLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]
    dead = params["dead"]
    role = params["role"]


    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)
    clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(code)
    nb_players = Loupgarou.GameLogic.GameProcess.getPlayerCount(code)



    # Assign values to the socket
    {:ok, assign(socket, name: name,
                         code: code,
                         dead: dead,
                         role: role,
                         playerMap: playerMap,
                         clicked: false,
                         clicked_players: clicked_players)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="role-container">
      <div class="content-box">
        <h1>
          <%= @dead %> is suspected of being a Wolf, and therefore executed by the villagers
        </h1>
        <img
          src="https://cdn-icons-png.freepik.com/256/581/581762.png?semt=ais_hybrid"
          alt="lupi"
          width="353"
          height="167"
        />
        <p>His Role is: <%= @role %></p>
        <button
          class="clickable-button"
          type="button"
          phx-click="continue"
          disabled={@clicked}
        >
          <%= if @clicked, do: "Ready", else: "Continue" %>
        </button>
      </div>
    </div>
    """
  end


  @impl true
  def handle_event("continue", _, socket) do
    Loupgarou.GameLogic.GameProcess.increment_clicked_players(socket.assigns.code)
    updated_clicked_players = Loupgarou.GameLogic.GameProcess.get_clicked_players(socket.assigns.code)
    LoupgarouWeb.Endpoint.broadcast!(
      "game:#{socket.assigns.code}",
      "update_clicked_players_resultDay",
      %{clicked_players: updated_clicked_players}
    )
    socket =
      socket
      |> assign(clicked: true)
      |> assign(clicked_players: updated_clicked_players)

      if updated_clicked_players == socket.assigns.nb_players do
        Loupgarou.GameLogic.GameProcess.reset_clicked_players(socket.assigns.code)
        db = Loupgarou.GameLogic.GameProcess.getstatusDatabase(socket.assigns.code)
        cond do
          db.phase == :EndWolf -> push_navigate(socket, to: "/win_wolf_live")
                                  LoupgarouWeb.Endpoint.broadcast!(
                                    "game:#{socket.assigns.code}",
                                    "redirect_to_End", %{}
                                  )
          db.phase == :EndVillager -> push_navigate(socket, to: "/win_villager_live")
          true -> {:noreply,
            push_navigate(socket, to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}")}
        end





        # Broadcast a message to redirect all players
        LoupgarouWeb.Endpoint.broadcast!(
          "game:#{socket.assigns.code}",
          "redirect_to_count_vote_day", %{}
        )

        # Redirect the current player to the night phase
        {:noreply, push_navigate(socket, to: "/count_vote_day/#{socket.assigns.code}/#{socket.assigns.name}")}
      else
        # Not all players are ready, just update the count
        {:noreply, socket}
      end



  end

end
