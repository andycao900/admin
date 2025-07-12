defmodule AdminWeb.Router do
  use AdminWeb, :router

  pipeline :unauthenticated do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {AdminWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug :unauthenticated
    plug AdminWeb.Plugs.RequireAuth
  end

  scope "/", AdminWeb do
    pipe_through :unauthenticated

    get "/", PageController, :home
    get "/auth/:provider", AuthController, :request
    get "/auth/:provider/callback", AuthController, :callback
  end

  scope "/", AdminWeb do
    pipe_through :authenticated

    resources "/users", UserController
  end
end
