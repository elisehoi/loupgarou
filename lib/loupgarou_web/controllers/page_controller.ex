defmodule LoupgarouWeb.PageController do
  use LoupgarouWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end


## Author Elise - Nov 29 11:48 AM
# generate access code for the game and url of the room
 defp generate_access_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 5)
  end

def waiting_room_master(conn, %{"code" => code}) do
  render(conn, "waiting_room_master.html", code: code)
end


# create game room using the access code, redirect to a new page wirh the access code as URL
def create_game_room(conn, _params) do
    code = generate_access_code()
    redirect(conn, to: "/#{code}")
  end

def join_game_room(conn, %{"code" => code}) do
    redirect(conn, to: "/#{code}")
  end

## Author Marta DL dec 6 10:18AM
#def waiting_room_master(conn, _params) do
#    render(conn, "waiting_room_master.html")
#end

  def waiting_room_player(conn, _params) do
    render(conn, "waiting_room_player.html")
  end
end
