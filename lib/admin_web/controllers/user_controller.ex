defmodule AdminWeb.UserController do
  use AdminWeb, :controller

  alias Admin.Accounts
  alias Admin.Accounts.User
  alias Admin.Repo

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user_with_auth0(user_params) do
      {:ok, %{db_user: user, auth0_check_and_create: :created}} ->
        conn
        |> put_flash(:info, "User created successfully and synced to Auth0.")
        |> redirect(to: ~p"/users/#{user}")

      {:ok, %{db_user: user, auth0_check_and_create: :already_exists}} ->
        conn
        |> put_flash(:info, "User created in DB. Auth0 user already exists.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, :db_user, %Ecto.Changeset{} = changeset, _changes} ->
        render(conn, :new, changeset: changeset)

      {:error, :auth0_check_and_create, {:auth0_create_failed, reason}, _changes} ->
        conn
        |> put_flash(:error, "Failed to create user in Auth0: #{inspect(reason)}")
        |> render(:new, changeset: Accounts.change_user(%User{}, user_params))

      {:error, :auth0_check_and_create, {:auth0_lookup_failed, reason}, _changes} ->
        conn
        |> put_flash(:error, "Failed to check Auth0 user: #{inspect(reason)}")
        |> render(:new, changeset: Accounts.change_user(%User{}, user_params))
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: ~p"/users")
  end
end
