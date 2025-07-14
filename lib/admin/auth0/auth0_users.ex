defmodule Admin.Auth0.Auth0User do
  @moduledoc """
  Delegator for Auth0 user management.
  """

  defp adapter do
    Application.get_env(:admin, :auth0_user_adapter, Admin.Auth0.Default)
  end

  def create_user(attrs), do: adapter().create_user(attrs)
  def update_user(user_id, attrs), do: adapter().update_user(user_id, attrs)
  def get_user_by_email(email), do: adapter().get_user_by_email(email)
  def delete_user(user_id), do: adapter().delete_user(user_id)
end
