defmodule LoupgarouWeb.VillageWon do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    code = params["code"]

    # Initialize state and subscribe to the game topic if needed
    socket = socket |> assign(code: code)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="victory">
      <h1>The Village Have Won!</h1>
      <p>The game is over, the village can sleep well now that no werewolves are around.</p>
    </div>
    """
  end
end