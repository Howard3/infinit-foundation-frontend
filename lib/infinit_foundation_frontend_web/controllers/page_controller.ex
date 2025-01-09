defmodule InfinitFoundationFrontendWeb.PageController do
  use InfinitFoundationFrontendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
