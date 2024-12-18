defmodule LoupgarouWeb.VillagerRoleLive do
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
        src="https://images.vexels.com/media/users/3/128325/isolated/preview/0f52205b21536ca0dbbdac51891348e0-old-farmer-cartoon.png"
        alt="Villager"
      />
      <h2>A Villager</h2>
      <p>
        The most commonplace role, a simple Villager, spends the game trying to
        root out who they believe the werewolves are.
      </p>
      <button
        class="clickable-button"
        type="button"
        phx-click="redirect_to_night"
      >
        Understand
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
