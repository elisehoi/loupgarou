## Author Elise - Nov 29 11:48
## TODO put in lib -> loupgarou_web -> controllers

defmodule YourAppWeb.GameSessionController do
  use YourAppWeb, :controller

  # A map to store GameSession states (only for this example; use a database or ETS in production)
  @GameSession_store Agent.start_link(fn -> %{} end, name: :GameSession_store)

  # Show the GameSession
  def show(conn, %{"code" => code}) do
    # Check if the GameSession exists
    case Agent.get(:GameSession_store, &Map.get(&1, code)) do
      nil -> 
        conn
        |> put_flash(:error, "GameSession not found.")
        |> redirect(to: "/")
      state -> 
        render(conn, "show.html", code: code, state: state)
    end
  end

  # Create a new GameSession
  def create(conn, _params) do
    # Generate a unique code
    code = generate_code()

    # Store the GameSession in the agent (shared state)
    Agent.update(:GameSession_store, &Map.put(&1, code, %{}))

    # Redirect to the new GameSession
    redirect(conn, to: "/#{code}")
  end

  # Helper function to generate a code
  defp generate_code do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 5)
  end
end
