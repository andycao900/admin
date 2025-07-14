defmodule Admin.Auth0.Behaviour do
  @moduledoc """
  Behaviour for Auth0 user management.
  """

  @callback create_user(map()) :: {:ok, map()} | {:error, any()}
  @callback update_user(binary(), map()) :: {:ok, map()} | {:error, any()}
  @callback get_user_by_email(String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  @callback delete_user(binary()) :: :ok | {:error, any()}
end
