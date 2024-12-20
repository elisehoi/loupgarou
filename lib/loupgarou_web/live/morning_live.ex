defmodule LoupgarouWeb.Morning2Live do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    name = params["name"] || "Nameless player"
    code = params["code"]
    victim = params["victim"]

    {:ok, assign(socket, name: name, code: code, victim: victim)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="role-container">
    <h1>Morning arrives, and everyone wakes up. Everyone, except for...</h1>
    <img src="https://t3.ftcdn.net/jpg/01/76/52/20/360_F_176522043_NBVB7bJTHStrqG3ONiM7QpExAz2mDAUR.jpg" alt="Victim Image" width="300" height="200">
    <p> <%= @victim || "No victim today" %> </p>
    <p>This person is dead, killed by a Werewolf.</p>
    <p>Your job is now to try to find out who the wereloves are by discussing with the other players.</p>
    <p>Choose a member to kill and they will be eliminated, with their role revealed.</p>
    <button class="clickable-button"
            type="button"
            phx-click="redirect_to_vote_day">Proceed to Voting</button>
  </div>
    """
  end

  @impl true
  def handle_event("redirect_to_vote_day", _, socket) do
   
    if(socket.assigns.name == socket.assigns.victim) do
      {:noreply, push_navigate(socket, to: "/#{socket.assigns.name}/dead_live")}

    else
      {:noreply, push_navigate(socket, to: "/#{socket.assigns.code}/#{socket.assigns.name}/day_vote_live")}

    end

  end
end
