defmodule LoupgarouWeb.ResultDayVoteLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]
    dead = params["dead"]
    role = params["role"]


    # Assign values to the socket
    {:ok, assign(socket, name: name, code: code, dead: dead, role: role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="role-container">
        <h1> <%= @dead %> is suspected of being a Wolf, and therefore executed by the villagers</h1>
        <img src="https://cdn-icons-png.freepik.com/256/581/581762.png?semt=ais_hybrid" alt="Trulli">
        <p> His Role is: <%= @role %> </p>
      </div>

    """
  end


  @impl true
  def handle_event("redirect_to_vote_day", _, socket) do
    {:noreply,
    push_redirect(socket,
    to: "/#{socket.assigns.code}/#{socket.assigns.name}/day_vote_live" )}
  end

end
