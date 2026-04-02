defmodule InfinitFoundationFrontendWeb.PageController do
  use InfinitFoundationFrontendWeb, :controller

  alias InfinitFoundationFrontend.FeedingCountCache

  def home(conn, _params) do
    feeding_count =
      case FeedingCountCache.get_feeding_count() do
        {:ok, count} -> count
        {:error, _} -> nil
      end

    render(conn, :home, feeding_count: feeding_count)
  end
end
