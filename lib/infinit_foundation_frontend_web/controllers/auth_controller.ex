defmodule InfinitFoundationFrontendWeb.AuthController do
  use InfinitFoundationFrontendWeb, :controller

  def sign_in(conn, _params) do
    render(conn, :sign_in)
  end

  def sign_up(conn, _params) do
    render(conn, :sign_up)
  end
end
