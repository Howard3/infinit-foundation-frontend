defmodule InfinitFoundationFrontendWeb.AuthController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.Posthog
  require Logger

  def sign_in(conn, _params) do
    render(conn, :sign_in)
  end

  def sign_up(conn, _params) do
    render(conn, :sign_up)
  end

  def sign_in_callback(conn, _params) do
    with session_token when is_binary(session_token) <- conn.cookies["__session"],
         {:ok, claims} <- InfinitFoundationFrontend.Guardian.decode_and_verify(session_token),
         {:ok, _resource} <- InfinitFoundationFrontend.Guardian.resource_from_claims(claims) do

      Posthog.capture("User Signed In",
        user_id: claims["sub"],
        properties: %{
          auth_method: "clerk"
        }
      )

      conn
      |> put_session(:user_id, claims["sub"])
      |> redirect(to: "/")
    else
      error ->
        Logger.error("Auth error: #{inspect(error)}")
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: "/sign-in")
    end
  end

  def sign_out(conn, _params) do
    Posthog.capture("User Signed Out",
      user_id: get_session(conn, "user_id")
    )
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
