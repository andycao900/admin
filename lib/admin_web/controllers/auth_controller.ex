defmodule AdminWeb.AuthController do
  use AdminWeb, :controller

  plug Ueberauth, callback_methods: ["GET"]

  alias AdminWeb.Router.Helpers, as: Routes

  def callback(
        %{
          assigns: %{
            ueberauth_auth: %Ueberauth.Auth{info: %Ueberauth.Auth.Info{email: user_email}}
          }
        } = conn,
        params
      ) do
    IO.inspect(user_email)

    # user_info = %{
    #   uid: auth.uid,
    #   email: auth.info.email,
    #   name: auth.info.name,
    #   picture: auth.info.image,
    #   token: auth.credentials.token
    # }

    conn
    # |> put_session(:current_user, user_info)
    |> put_flash(:info, "Successfully logged in!")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: "/")
  end
end
