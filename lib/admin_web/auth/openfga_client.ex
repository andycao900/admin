defmodule Admin.Auth.OpenFgaClient do
  @moduledoc """
  Lightweight FGA client using Req for token fetching and permission checks.
  """
  alias Admin.Auth.OpenFgaTokenCache

  @fga_config Application.compile_env!(:admin, :openfga)

  @client_id @fga_config[:client_id]
  @client_secret @fga_config[:client_secret]
  @audience @fga_config[:audience]
  @base_url @fga_config[:base_url]
  @store_id @fga_config[:store_id]
  @model_id @fga_config[:model_id]
  @token_url "https://auth.fga.dev/oauth/token"


    def get_token do
    %{token: token, expires_at: expires_at} = OpenFgaTokenCache.get()
    now = System.os_time(:second)

    if token && now < expires_at do
      IO.puts("old token")
      {:ok, token}
    else
      IO.puts("new token")
      fetch_and_cache_token()
    end
  end

  @doc """
  Request an OAuth2 token for FGA using client credentials.
  """
  def fetch_and_cache_token  do
    request_body = %{
      grant_type: "client_credentials",
      client_id: @client_id,
      client_secret: @client_secret,
      audience: @audience
    }

    headers = [{"Content-Type", "application/json"}]

    case Req.post(@token_url, json: request_body, headers: headers) do
      {:ok, %Req.Response{status: 200, body: %{"access_token" => token, "expires_in" => expires_in}}} ->
        OpenFgaTokenCache.put(token, expires_in)
        {:ok, token}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:token_failed, status, body}}

      {:error, reason} ->
        {:error, {:token_error, reason}}
    end
  end

  @doc """
  Decodes the JWT payload (for debugging or metadata inspection).
  """
  def decode_token_payload(token) do
    [_header_b64, payload_b64, _signature] = String.split(token, ".")
    payload_json = Base.url_decode64!(payload_b64, padding: false)
    Jason.decode!(payload_json)
  end

  @doc """
  Call the FGA /check endpoint with the given user, relation, and object.
  samples:  Admin.Auth.OpenFgaClient.check("user:cao900bg@gmail.com", "can_update", "route:/users")
  """
  def check(user, relation, object) do
    with {:ok, token} <- get_token() do
      url = "#{@base_url}/stores/#{@store_id}/check"

      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      body = %{
        "tuple_key" => %{
          "user" => user,
          "relation" => relation,
          "object" => object
        }
      }

      Req.post(url, json: body, headers: headers)
    end
  end
end



#   alias Auth0Ex.Authentication.Token

#     fga_m2m_config = Application.get_env(:admin, :fga_m2m_client)
#     fga_client_id = fga_m2m_config[:client_id]
#     fga_client_secret = fga_m2m_config[:client_secret]
#     fga_audience = fga_m2m_config[:audience]
#     fga_domain = fga_m2m_config[:domain]

#     token_url = "#{fga_domain}/authorize/oauth2/token"
#         body = %{
#       "grant_type" => "client_credentials",
#       "client_id" => fga_client_id,
#       "client_secret" => fga_client_secret,
#       "audience" => fga_audience
#     }
#     headers = [
#       {"content-type", "application/x-www-form-urlencoded"}
#     ]

# {:ok, %{"access_token" => token}} = Token.client_credentials(fga_client_id, fga_client_secret, fga_audience)
# [header_b64, payload_b64, _signature] = String.split(token, ".")
# payload_json = Base.url_decode64!(payload_b64, padding: false)
# payload_map = Jason.decode!(payload_json)

#   config = Application.get_env(:admin, :openfga_api)
#       base_url = config[:base_url]
#     store_id = config[:store_id]
#     model_id = config[:model_id]
#         url = "#{base_url}/stores/#{store_id}/check"
#       headers = [
#         {"Authorization", "Bearer #{token}"},
#         {"Content-Type", "application/json"}
#       ]

#       body = %{
#         "tuple_key" => %{
#           "user" => "user:cao900bg@gmail.com",
#           "relation" => "can_update",
#           "object" => "route:/users"
#         }
#       }

# end
