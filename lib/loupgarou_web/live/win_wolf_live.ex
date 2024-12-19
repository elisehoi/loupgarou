defmodule LoupgarouWeb.WinWolfLive do
  use LoupgarouWeb, :live_view


  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <h1> All villagers are dead, the wolves have won !</h1>
    """
  end

end
