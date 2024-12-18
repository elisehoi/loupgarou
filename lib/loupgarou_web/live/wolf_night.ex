defmodule LoupgarouWeb.WolfNightLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `code` and `name` from URL parameters
    code = params["code"]
    name = params["name"]

    # Here you should fetch or assign the list of non-wolf players (replace `get_non_wolf_players/1`)
    not_wolf = get_non_wolf_players(code)

    {:ok, assign(socket, code: code, name: name, notWolf: not_wolf)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="role-container">
      <h1>It's night time and the Wolves are waking up...</h1>
      <img
        src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWPu1_hvNpM4hFMKaNHDByA5iT8Dgf1rI2gPfK-xkVNM63A0yGOTuu8dIhYXDx_PAjMR8&usqp=CAU"
        alt="lupi"
        width="353"
        height="167"
      />
      <p>You wake up thirsty for blood, who will be your meal tonight?</p>

      <!-- Loop through non-wolf players to create buttons -->
      <%= for player_name <- @notWolf do %>
        <button
          class="clickable-button"
          type="button"
          phx-click="redirect_to_vote"
          phx-value-victim={player_name}
        >
          <%= player_name %>
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("redirect_to_vote", %{"victim" => victim}, socket) do
    # Redirect to the vote counting route
    {:noreply,
     push_redirect(socket,
       to: "/count_vote/#{socket.assigns.code}/#{socket.assigns.name}/#{victim}"
     )}
  end


  defp get_non_wolf_players(code) do
    players = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)

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
