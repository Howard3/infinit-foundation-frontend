defmodule InfinitFoundationFrontendWeb.Plugs.EnsureAuth do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, "user_id") do
      conn
    else
      conn
      |> put_flash(:error, "Please sign in to continue")
      |> redirect(to: "/sign-in")
      |> halt()
    end
  end
end
