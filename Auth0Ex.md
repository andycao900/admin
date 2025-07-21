Note: FGA need add a client for FGA console, not from auth0 console.
Elixir project that integrates with **Auth0 via `auth0_ex`**, including:

* Project setup
* Auth0 Management API setup
* Config via `config.exs`
* User management (create/search/update/delete)
* Optional testing instructions

---

````markdown
# 🔐 Auth0 Integration with Elixir (`auth0_ex`)

This project integrates with [Auth0's Management API](https://auth0.com/docs/api/management/v2) using [`auth0_ex`](https://hex.pm/packages/auth0_ex). It allows you to manage users (create, update, search, delete) via a configurable adapter and supports transactional workflows with your local database.

---

## 🚀 Features

- ✅ Machine-to-Machine authentication via Auth0
- ✅ Dynamic user creation in both Auth0 and the local DB
- ✅ Flexible adapter layer for mocking/testing
- ✅ Built-in behavior for Auth0 user operations

---

## 📦 Dependencies

In `mix.exs`:

```elixir
defp deps do
  [
    {:auth0_ex, github: "akoutmos/auth0_ex", branch: "main"},
    {:jason, "~> 1.4"} # Required for decoding Auth0 responses
  ]
end
````

> ⚠️ Note: As of writing, `auth0_ex` has newer features in `main` that aren't yet published to Hex.

---

## 🔧 Auth0 Setup

### 1. Create a Machine-to-Machine (M2M) App

* Go to your [Auth0 Dashboard](https://manage.auth0.com/)
* **Applications → + Create Application**
* Name: `Admin API Client` (or anything)
* Type: **Machine to Machine Applications**
* Click **Create**

### 2. Grant Access to the Management API

* Go to your new app → **APIs tab**
* Click **“+ Authorize API”**
* Select **Auth0 Management API**
* Grant the following scopes:

```
read:users
create:users
update:users
delete:users   # Optional
```

> 🔒 These permissions control what your Elixir app can do via `auth0_ex`.

---

## 🔐 Environment Variables

Create a `.env` file or set the following securely:

```bash
AUTH0_DOMAIN=your-tenant.us.auth0.com
AUTH0_MGMT_CLIENT_ID=your-client-id
AUTH0_MGMT_CLIENT_SECRET=your-secret
```

---

## ⚙️ Configuration

In `config/config.exs`:

```elixir
config :auth0_ex, Auth0Ex,
  domain: System.get_env("AUTH0_DOMAIN"),
  mgmt_client_id: System.get_env("AUTH0_MGMT_CLIENT_ID"),
  mgmt_client_secret: System.get_env("AUTH0_MGMT_CLIENT_SECRET"),
  audience: "https://#{System.get_env("AUTH0_DOMAIN")}/api/v2/"
```

In `config/runtime.exs`, you can move this for production runtime configuration.

---

## 🧱 Project Structure

### 1. Behavior: `Admin.Auth0.Behaviour`

```elixir
defmodule Admin.Auth0.Behaviour do
  @callback create_user(map()) :: {:ok, map()} | {:error, any()}
  @callback update_user(binary(), map()) :: {:ok, map()} | {:error, any()}
  @callback get_user_by_email(String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  @callback delete_user(binary()) :: :ok | {:error, any()}
end
```

### 2. Default Adapter: `Admin.Auth0.Default`

Implements the behavior using `auth0_ex`:

```elixir
defmodule Admin.Auth0.Default do
  @behaviour Admin.Auth0.Behaviour
  alias Auth0Ex.Management.Users

  def create_user(%{"email" => email, "password" => password} = attrs) do
    Users.create(%{
      connection: "Username-Password-Authentication",
      email: email,
      password: password,
      email_verified: true,
      user_metadata: Map.drop(attrs, ["email", "password"])
    })
  end

  def update_user(id, attrs), do: Users.update(id, attrs)

  def get_user_by_email(email) do
    Users.list(%{q: ~s(email:"#{email}"), search_engine: "v3"})
    |> case do
      {:ok, %{"users" => [user | _]}} -> {:ok, user}
      {:ok, _} -> {:error, :not_found}
      error -> error
    end
  end

  def delete_user(id), do: Users.delete(id)
end
```

### 3. Delegator: `Admin.Auth0.Auth0User`

```elixir
defmodule Admin.Auth0.Auth0User do
  defp adapter, do: Application.get_env(:admin, :auth0_user_adapter, Admin.Auth0.Default)

  def create_user(attrs), do: adapter().create_user(attrs)
  def update_user(id, attrs), do: adapter().update_user(id, attrs)
  def get_user_by_email(email), do: adapter().get_user_by_email(email)
  def delete_user(id), do: adapter().delete_user(id)
end
```

### 4. Set the default adapter in `config.exs`

```elixir
config :admin, :auth0_user_adapter, Admin.Auth0.Default
```

---

## 🧪 Testing with a Mock

```elixir
defmodule Admin.Auth0.Mock do
  @behaviour Admin.Auth0.Behaviour

  def create_user(_), do: {:ok, %{"user_id" => "auth0|test"}}
  def update_user(_, _), do: {:ok, %{}}
  def get_user_by_email(_), do: {:error, :not_found}
  def delete_user(_), do: :ok
end
```

In `test_helper.exs` or test config:

```elixir
Application.put_env(:admin, :auth0_user_adapter, Admin.Auth0.Mock)
```

---

## 🔄 Sample Usage

```elixir
# Create a user
Admin.Auth0.Auth0User.create_user(%{
  "email" => "john@example.com",
  "password" => "supersecure"
})

# Search
Admin.Auth0.Auth0User.get_user_by_email("john@example.com")

# Update
Admin.Auth0.Auth0User.update_user("auth0|123", %{"user_metadata" => %{role: "admin"}})

# Delete
Admin.Auth0.Auth0User.delete_user("auth0|123")
```

---

## 🧠 Notes

* All users are created under the `"Username-Password-Authentication"` connection
* You must handle errors and rollbacks if combining Auth0 + DB operations
* Access tokens are fetched automatically via client credentials

---

## 📎 Resources

* [Auth0 Management API Docs](https://auth0.com/docs/api/management/v2)
* [`auth0_ex` GitHub](https://github.com/akoutmos/auth0_ex)

---


