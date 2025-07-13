defmodule AdminWeb.AuthController do
  use AdminWeb, :controller

  plug Ueberauth, callback_methods: ["GET"]

  alias AdminWeb.Router.Helpers, as: Routes
  alias Admin.Accounts

  def callback(
        %{
          assigns: %{
            ueberauth_auth: %Ueberauth.Auth{info: %Ueberauth.Auth.Info{email: user_email}}
          }
        } = conn,
        _params
      ) do
    IO.inspect(user_email)

    # user_info = %{
    #   uid: auth.uid,
    #   email: auth.info.email,
    #   name: auth.info.name,
    #   picture: auth.info.image,
    #   token: auth.credentials.token
    # }

    case Accounts.get_user_by_criteria(email: user_email) do
      nil ->
        conn
        |> put_flash(:error, "No matching user found.")
        |> redirect(to: "/")

      user ->
        # Optional: build a session struct if needed
        # user_info = %{id: user.id, email: user.email, name: user.name}

        conn
        |> put_session(:current_user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.email}!")
        |> redirect(to: "/users")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: "/")
  end
end
