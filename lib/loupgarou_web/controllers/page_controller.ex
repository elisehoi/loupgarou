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

# create game room using the access code, redirect to a new page wirh the access code as URL
# TODO connect the Gameprocess to its unique code, so that it can be accessed through this code.
def create_game_room(conn, %{"name" => creatorPlayerName}) do
    code = generate_access_code()

    case Loupgarou.GameLogic.GameProcess.start(creatorPlayerName, code) do
      # If the creation of the gameProcess is successful,
      # it will redirect to a waiting room with the game ID as URL
      {:ok, _pid} ->
        redirect(conn, to: "/#{code}")
        IO.puts("STEP 1 create game room. SUCCESSFULLY REDIRECTED TO GAMECOOODE")
      # error case
      {:error, reason} ->
        IO.puts("STEP 1 create game room. ERROR")
        conn
        |> put_flash(:error, "Failed to create game: #{inspect(reason)}")
        |> redirect(to: "/")
    end

  end

  # check if game room exists
  def check_game_room(conn, %{"code" => code}) do
    redirect(conn, to: "/#{code}")
  end


  def join_game_room(conn, %{"code" => code, "name" => name}) do
    Loupgarou.GameLogic.GameProcess.add_player(name, code)
    redirect(conn, to: "/#{code}")
  end


def waiting_room_master(conn, %{"code" => code}) do
  IO.puts("STEP 2: waiting room master display CALLED WAITING ROOM MASTER")
  # HERE THERE IS AN ERROR LISE
  #problem = requests for a player list but the room is not yet created
  players=Loupgarou.GameLogic.GameProcess.getPlayerList(code)
    IO.puts("THE FETCHED PLAYERS ARE:")
  IO.inspect(players)
  render(conn, "waiting_room_master.html", code: code, players: players)
end

  def waiting_room_player(conn, _params) do
    render(conn, "waiting_room_player.html")
  end
end
