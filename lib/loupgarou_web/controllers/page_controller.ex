defmodule LoupgarouWeb.PageController do
  use LoupgarouWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def waiting_room_master(conn, _params) do
    render(conn, "waiting_room_master.html")
  end
end
