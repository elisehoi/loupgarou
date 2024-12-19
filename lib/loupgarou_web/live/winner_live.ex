defmodule LoupgarouWeb.WinnerLive do
  use Phoenix.LiveView

  # mount/2 receives the params and assigns from the router.
  def mount(_params, _session, socket) do
    # Set the winner information in the socket assigns.
    winner = socket.assigns[:winner]
    {:ok, assign(socket, winner: winner)}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>Game Over!</h1>
      <p>The <%= @winner %> has won the game!</p>
      <button style=clickable-button href="/">Back to Home</button>
    </div>
    """
  end
end
