defmodule LoupgarouWeb.WolfWon do
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
      <h1>The Werewolves Have Won!</h1>
      <p>The game is over, the werewolves have eliminated all the villagers.</p>
    </div>
    """
  end

end
