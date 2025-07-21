defmodule Admin.Auth.OpenFgaTokenCache do
  @moduledoc "Agent for caching FGA access token and expiry."

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{token: nil, expires_at: 0} end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def put(token, expires_in_seconds) do
    now = System.os_time(:second)
    expires_at = now + expires_in_seconds - 10  # Subtract buffer for safety
    Agent.update(__MODULE__, fn _ -> %{token: token, expires_at: expires_at} end)
  end
end
