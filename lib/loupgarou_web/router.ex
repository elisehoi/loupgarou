defmodule LoupgarouWeb.Router do
  use LoupgarouWeb, :router


  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LoupgarouWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LoupgarouWeb do
    pipe_through :browser

    get "/", PageController, :home
    ## Author Elise Nov 29 11:59 AM
    # Create game room
    post "/create_game_room", PageController, :create_game_room
  end

## Author Marta DL dec 6 10:18AM

  #to change page
  scope "/" , LoupgarouWeb do
    pipe_through :browser

    get "/waiting-room-master", PageController, :waiting_room_master
  end

    #to change page
    scope "/" , LoupgarouWeb do
      pipe_through :browser

      get "/waiting-room-player", PageController, :waiting_room_player
    end

  #to change page
  scope "/" , LoupgarouWeb do
    pipe_through :browser

    get "/waiting-room-master", PageController, :waiting_room_master
  end

    #to change page
    scope "/" , LoupgarouWeb do
      pipe_through :browser

      get "/waiting-room-player", PageController, :waiting_room_player
    end


  # Other scopes may use custom stacks.
  # scope "/api", LoupgarouWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:loupgarou, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LoupgarouWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
