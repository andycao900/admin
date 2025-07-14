defmodule Admin.Auth0.Default do
  @behaviour Admin.Auth0.Behaviour

  alias Auth0Ex.Management.User

  @impl true
  def create_user(%{"email" => email} = attrs) do
    User.create(
      "Username-Password-Authentication",
      %{
        email: email,
        password: "Passw0rd",
        email_verified: true,
        user_metadata: Map.drop(attrs, ["email", "password"])
      }
    )
  end

  @impl true
  def update_user(user_id, attrs), do: User.update(user_id, attrs)

  @impl true
  def get_user_by_email(email) do
    User.all(%{q: ~s(email:"#{email}"), search_engine: "v3"})
    |> case do
      {:ok, [user | _]} ->
        {:ok, user}

      {:ok, _} ->
        {:error, :not_found}

      err ->
        err
    end
  end

  @impl true
  def delete_user(user_id), do: User.delete(user_id)
end
