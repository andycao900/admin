defmodule Admin.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Admin.Repo

  alias Admin.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Gets a user by criteria.

  Accepts a keyword list like `[email: "user@example.com"]`.

  Returns `nil` if no user is found.

  ## Examples

      iex> get_user_by_criteria(email: "foo@example.com")
      %User{}

      iex> get_user_by_criteria(id: 999)
      nil
  """
  def get_user_by_criteria(criteria) when is_list(criteria) do
    case Repo.get_by(User, criteria) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def create_user_with_auth0(user_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:db_user, fn _repo, _changes ->
      create_user(user_params)
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
  end
end
