defmodule InfinitFoundationFrontendWeb.LegalController do
  use InfinitFoundationFrontendWeb, :controller

  def privacy_policy(conn, _params) do
    render(conn, :privacy_policy)
  end

  def terms_of_service(conn, _params) do
    render(conn, :terms_of_service)
  end

  def cookie_policy(conn, _params) do
    render(conn, :cookie_policy)
  end
end
