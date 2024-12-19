defmodule LoupgarouWeb.Router do
  alias LoupgarouWeb.WolfWon
  alias LoupgarouWeb.VillageWon
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
    get "/create_game_room/:name", PageController, :create_game_room
    live "/:code/:name/waiting_room_master_live", WaitingRoomMasterLive
    get "/join_game_room/", PageController, :join_game_room
    live "/:code/:name/waiting_room_player_live", WaitingRoomPlayerLive
    get "/role_distribution/:code/:name", PageController, :distribute_role
    get "/show_role/:code/:name", PageController, :show_role
    get "/check_player_name/:code/:name", PageController, :check_player_name
    get "/night_time/:code/:name", PageController, :night_time
    live "/:code/:name/night_live", NightLive
    live "/:code/:name/villager_role_live", VillagerRoleLive
    live "/:code/:name/wolf_role_live", WolfRoleLive
    live "/:code/:name/wolf_night_live", WolfNightLive
    get "/count_vote/:code/:name", PageController, :count_vote
    live "/:code/:name/:victim/morning_live", Morning2Live
    live "/:code/:name/day_vote_live", DayVoteLive
    get "/count_vote_day/:code/:name/:suspect", PageController, :count_vote_day
    live "/:code/:name/:dead/:role/result_day_vote_live", ResultDayVoteLive
    live "/game/winner", WinnerLive
    live "/:code/villagers_won_live", VillageWon
    live "/:code/wolves_won_live", WolfWon
  end

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
