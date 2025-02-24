defmodule InfinitFoundationFrontendWeb.ImageController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.ApiClient

  # This function is used to proxy images from the API server to the frontend. Later, we will be caching optimized images.
  def proxy_photo(conn, %{"path" => path_parts}) do
    # Reconstruct the path
    path = "/" <> Enum.join(path_parts, "/")

    # Get the image from the API server
    case Req.get!(ApiClient.photo_url(path)) do
      %{status: 200, body: image_data, headers: headers} ->
        content_type = extract_content_type(headers)

        conn
        |> put_resp_content_type(List.first(content_type))
        |> send_resp(200, image_data)

      _error ->
        conn
        |> put_status(:not_found)
        |> text("Image not found")
    end
  end

  def proxy_feeding_photo(conn, %{"id" => id}) do
    case Req.get!(ApiClient.feeding_photo_url(id)) do
      %{status: 200, body: image_data, headers: headers} ->
        content_type = extract_content_type(headers)

        conn
        |> put_resp_content_type(List.first(content_type))
        |> send_resp(200, image_data)

      _error ->
        conn
        |> put_status(:not_found)
    end
  end

  defp extract_content_type(headers) do
    {_, content_type} = Enum.find(headers, {"content-type", "application/octet-stream"},
      fn {k, _v} -> String.downcase(k) == "content-type" end)
    content_type
  end
end
