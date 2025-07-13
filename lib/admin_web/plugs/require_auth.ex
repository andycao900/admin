defmodule AdminWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller
  alias AdminWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :current_user_id) do
      conn
    else
      redirect(conn, external: Routes.auth_path(conn, :request, "auth0")) |> halt()
    end
  end
end
