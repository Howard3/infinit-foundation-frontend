defmodule InfinitFoundationFrontend.ApiClient do
  @base_url Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :base_url])
  @api_key Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :api_key])

  def list_locations do
    Req.get!(url("/locations"), headers: default_headers())
    |> Map.get(:body)
  end

  @spec list_students(any()) :: any()
  def list_students(params \\ %{}) do
    Req.get!(url("/students"), headers: default_headers(), params: params)
    |> Map.get(:body)
  end

  def list_students_by_location(params \\ %{}) do
    Req.get!(url("/students/by-location"), headers: default_headers(), params: params)
    |> Map.get(:body)
  end

  def photo_url(relative_path) when is_binary(relative_path) do
    case relative_path do
      "/student/profile/photo/" <> _rest ->
        relative_path
      _ -> # FIXME: this is a little hacky, but it works for now
        String.replace(@base_url, "/api", "/student/profile/photo") <> relative_path
    end
  end

  defp url(path), do: @base_url <> path

  defp default_headers do
    [
      {"accept", "application/json"},
      {"X-API-Key", @api_key}
    ]
  end
end
