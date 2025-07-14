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

  def create(conn, %{"user" => %{"email" => email} = user_params}) do
    case Accounts.get_user_by_criteria(email: email) do
      {:ok, _existing_user} ->
        conn
        |> put_flash(:error, "A user with this email already exists in the application.")
        |> redirect(to: ~p"/users")

      {:error, :not_found} ->
        user_create_transaction(conn, user_params)
    end
  end

  defp user_create_transaction(conn, user_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:db_user, fn _repo, _changes ->
      Accounts.create_user(user_params)
    end)
    |> Ecto.Multi.run(:auth0_check_and_create, fn _repo, %{db_user: db_user} ->
      case Admin.Auth0.Auth0User.get_user_by_email(db_user.email) do
        {:ok, _} ->
          {:ok, :already_exists}

        {:error, :not_found} ->
          case Admin.Auth0.Auth0User.create_user(user_params) do
            {:ok, _auth0_user} -> {:ok, :created}
            {:error, reason} -> {:error, {:auth0_create_failed, reason}}
          end

        {:error, reason} ->
          {:error, {:auth0_lookup_failed, reason}}
      end
    end)
    |> Repo.transaction()
    |> case do
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
        |> redirect(to: ~p"/users")

      {:error, :auth0_check_and_create, {:auth0_lookup_failed, reason}, _changes} ->
        conn
        |> put_flash(:error, "Failed to check Auth0 user: #{inspect(reason)}")
        |> redirect(to: ~p"/users")
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
