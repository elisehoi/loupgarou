defmodule LoupgarouWeb.DeadLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    name = params["name"] || "Nameless player"
    {:ok, assign(socket, name: name)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="role-container">
      <h2>Dear <%= @name %>...</h2>
      <h2> You are dead ! Sorry. You did not win this game.</h2>

      <img src= "https://cdn-icons-png.flaticon.com/512/12038/12038438.png" alt="Victim Image" width="300" height="200">
    </div>
    """
  end

end
