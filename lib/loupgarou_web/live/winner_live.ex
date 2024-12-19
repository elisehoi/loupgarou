defmodule LoupgarouWeb.WinnerLive do
  use Phoenix.LiveView

  # mount/2 receives the params and assigns from the router.
  def mount(_params, _session, socket) do
    # Set the winner information in the socket assigns.
    winner = socket.assigns[:winner]
    {:ok, assign(socket, winner: winner)}
  end

  # Render the winner view based on the winner
  def render(assigns) do
    ~L"""
    <div>
      <h1>Game Over!</h1>
      <p>The <%= @winner %> have won the game!</p>
      <a href="/">Back to Home</a>
    </div>
    """
  end
end
