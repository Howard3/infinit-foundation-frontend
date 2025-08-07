defmodule InfinitFoundationFrontend.Clerk do
  require Logger

  @base_url "https://api.clerk.dev/v1"

  @doc """
  Fetches user details from Clerk API by user ID.
  Returns {:ok, user_data} or {:error, reason}.
  """
  def get_user(user_id) when is_binary(user_id) do
    url = "#{@base_url}/users/#{user_id}"

    case Req.get(url, headers: headers()) do
      {:ok, %Req.Response{status: 200, body: user_data}} ->
        Logger.debug("Successfully fetched user from Clerk", user_id: user_id)
        {:ok, user_data}

      {:ok, %Req.Response{status: 404}} ->
        Logger.warning("User not found in Clerk", user_id: user_id)
        {:error, :user_not_found}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("Clerk API error", user_id: user_id, status: status, response: body)
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("HTTP request failed to Clerk API", user_id: user_id, reason: reason)
        {:error, {:request_failed, reason}}
    end
  end

  def extract_first_name(user_data) when is_map(user_data) do
    case user_data["first_name"] do
      nil -> nil
      first_name -> first_name
    end
  end

  def extract_last_name(user_data) when is_map(user_data) do
    case user_data["last_name"] do
      nil -> nil
      last_name -> last_name
    end
  end

  @doc """
  Extracts the primary email address from Clerk user data.
  Returns the email string or nil if not found.
  """
  def extract_email(user_data) when is_map(user_data) do
    case user_data["email_addresses"] do
      [%{"email_address" => email} | _] ->
        email

      email_addresses when is_list(email_addresses) ->
        # Find the primary email address
        # Fallback to first email if no primary is marked
        Enum.find_value(email_addresses, fn email_obj ->
          if email_obj["primary"] do
            email_obj["email_address"]
          end
        end) ||
          (List.first(email_addresses) && List.first(email_addresses)["email_address"])

      _ ->
        nil
    end
  end

  defp headers do
    [
      {"Authorization", "Bearer #{clerk_secret_key()}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp clerk_secret_key do
    Application.get_env(:infinit_foundation_frontend, :clerk)[:secret_key] ||
      raise "CLERK_SECRET_KEY not configured"
  end
end
