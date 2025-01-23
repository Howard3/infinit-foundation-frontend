defmodule InfinitFoundationFrontend.Guardian.SecretFetcher do
  require Logger

  @behaviour Guardian.Token.Jwt.SecretFetcher

  @impl Guardian.Token.Jwt.SecretFetcher
  def fetch_signing_secret(_opts) do
    {:error, :secret_not_found}
  end

  @impl Guardian.Token.Jwt.SecretFetcher
  def fetch_verifying_secret(_mod, _claims, _opts) do
    case get_clerk_public_key() do
      {:ok, public_key} -> {:ok, public_key}
      _ -> {:error, :secret_not_found}
    end
  end

  defp get_clerk_public_key do
    res = get_jwks_url!() |> Req.get!()
    with body <- res.body,
         key when is_map(key) <- find_active_key(body) do
      {:ok, JOSE.JWK.from_map(key)}
    else
      error ->
        Logger.error("Failed to parse JWKS: #{inspect(error)}")
        {:error, :invalid_jwks}
    end
  end

  defp find_active_key(%{"keys" => keys}) do
    # Find the first active key
    Enum.find(keys, &(&1["use"] == "sig" && &1["alg"] == "RS256"))
  end
  defp find_active_key(_), do: nil

  defp get_jwks_url!() do
    clerk_api = Application.get_env(:infinit_foundation_frontend, :clerk)[:frontend_api]
    "#{clerk_api}/.well-known/jwks.json"
  end
end
