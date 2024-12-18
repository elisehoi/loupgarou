defmodule LoupgarouWeb.NightLive do
  use LoupgarouWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # Extract `:name` from the parameters passed in the URL
    name = params["name"] || "Nameless player"
    code = params["code"]

    # Assign values to the socket
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
end
