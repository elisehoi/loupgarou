defmodule LoupgarouWeb.NightLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    code = params["code"]
    name = params["name"] || "Nameless player"

    # Subscribe to the game's topic
    Phoenix.PubSub.subscribe(LoupgarouWeb.PubSub, "game:#{code}")
    IO.inspect("Subscribed to topic: game:#{code}")

    {:ok, assign(socket, name: name, code: code)}
  end

  @impl true
  def render(assigns) do
~H"""
    <style>
      /* Background and container styling */
      .night-live {
        background-image: url('https://w0.peakpx.com/wallpaper/594/33/HD-wallpaper-farm-windmill-holidays-halloween-moon-pumpkin-drawings-blue-night-corn-lamp-cloud-houses-digital-painting-scarecrow-scarecrows-pumpkins-field.jpg');
        background-size: cover;
        background-position: center;
        padding: 20px;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }

      /* White transparent background box for content */
      .content-box {
        background-color: rgba(255, 255, 255, 0.8); /* White with transparency */
        padding: 20px;
        border-radius: 10px;
        max-width: 800px;
        width: 100%;
        text-align: center;
      }

      /* Text styling */
      h2 {
        color: #333; /* Dark text for better readability */
      }
    </style>

    <div class="night-live">
      <div class="content-box">
        <h2>Sleeping....<%= @name %></h2>
        <h2>
          The day is over, it's time to rest. Enjoy your sleep. Who knows...
          it may be your last one.
        </h2>
      </div>
    </div>
"""
  end


  @impl true
  def handle_info(%{event: "wake_up", payload: %{victim: victim, code: code}}, socket) do
    IO.inspect("Received wake_up event with victim: #{victim}")
    db = Loupgarou.GameLogic.GameProcess.getstatusDatabase(code)
    cond do
      db.phase == :EndWolf -> push_redirect(socket, to: "/win_wolf_live")
      db.phase == :EndVillager -> push_redirect(socket, to: "/win_villager_live")
      true -> {:noreply,
      push_redirect(socket, to: "/#{socket.assigns.code}/#{socket.assigns.name}/#{victim}/morning_live")}
    end
  end

  # Catch all unmatched messages for debugging
  def handle_info(message, socket) do
    IO.inspect(message, label: "Unhandled Message in NightLive")
    {:noreply, socket}
  end

end
