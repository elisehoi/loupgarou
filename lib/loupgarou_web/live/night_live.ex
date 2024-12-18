defmodule LoupgarouWeb.NightLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]

    # Assign values to the socket
    {:ok, assign(socket, name: name, code: code)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="night-live">
      <h2>Sleeping....<%= @name %></h2>
      <h2>
        The day is over, it's time for rest. Enjoy your sleep. Who knows...
        it may be your last one.
      </h2>
    </div>
    """
  end
end
