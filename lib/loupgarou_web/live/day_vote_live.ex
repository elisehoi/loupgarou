defmodule LoupgarouWeb.DayVoteLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]

    playerMap = Loupgarou.GameLogic.GameProcess.getPlayerMap(code)


    # Assign values to the socket
    {:ok, assign(socket, name: name, code: code, playerMap: playerMap)}
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
            phx-click="redirect_to_vote_day"
            phx-value-suspect={player_name}>
            <%= player_name %>
          </button>
        <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("redirect_to_vote_day", %{"suspect" => suspect}, socket) do
    # Redirect to the vote counting route
    {:noreply,
     push_redirect(socket,
       to: "/count_vote_day/#{socket.assigns.code}/#{socket.assigns.name}/#{suspect}"
     )}
  end
end
