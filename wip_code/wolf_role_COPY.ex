defmodule LoupgarouWeb.WolfRoleLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `code` and `name` from URL parameters
    code = params["code"]
    name = params["name"]

    # Assign them to the socket for use in the template
    {:ok, assign(socket, code: code, name: name)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="role-container">
      <h1>Your role is...</h1>
      <img
        src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTck_Fl6l-F-2X5l5aHNtgz3nXVt-La9cicXA&s"
        alt="Werewolf"
      />
      <h2>A Werewolf</h2>
      <p>
        The werewolf is the game’s villain and main antagonist. The werewolf’s
        only job is to stalk the villagers at night and kill them without getting
        caught. This role bla bla bla...
      </p>
      <button
        class="clickable-button"
        type="button"
        phx-click="redirect_to_night"
      >
        Understood!
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("redirect_to_night", _value, socket) do
    # Redirect to the night phase with code and name in the URL
    {:noreply,
     push_redirect(socket,
       to: "/night_time/#{socket.assigns.code}/#{socket.assigns.name}"
     )}
  end
end
