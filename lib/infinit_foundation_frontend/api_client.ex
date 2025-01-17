defmodule InfinitFoundationFrontend.ApiClient do
  alias InfinitFoundationFrontend.Schemas.{Location, Student, PaginatedStudents, School}

  @base_url Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :base_url])
  @api_key Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :api_key])

  @spec list_locations() :: [Location.t()]
  def list_locations do
    Req.get!(url("/locations"), headers: default_headers())
    |> Map.get(:body)
    |> Map.get("locations")
    |> Enum.map(fn location ->
      %Location{
        country: location["country"],
        cities: location["cities"]
      }
    end)
    |> dbg
  end

  @spec list_students(map()) :: PaginatedStudents.t()
  def list_students(params \\ %{}) do
    params_with_defaults = Map.merge(
      %{active: true, eligible_for_sponsorship: true},
      params
    )

    response = Req.get!(url("/students"), headers: default_headers(), params: params_with_defaults)
    body = response.body

    %PaginatedStudents{
      students: Enum.map(body["students"], &to_student/1),
      total: body["total"]
    }
  end

  def list_students_by_location(params \\ %{}) do
    params_with_defaults = Map.merge(
      %{active: true, eligible_for_sponsorship: true},
      params
    )

    Req.get!(url("/students/by-location"), headers: default_headers(), params: params_with_defaults)
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

  defp to_student(data) do
    %Student{
      id: data["id"],
      first_name: data["firstName"],
      last_name: data["lastName"],
      profile_photo_url: data["profilePhotoUrl"],
      school_id: data["schoolId"],
      date_of_birth: data["dateOfBirth"],
      grade: data["grade"]
    }
  end

  @spec list_schools([String.t()]) :: [School.t()]
  def list_schools(school_ids) when is_list(school_ids) do
    params = %{ids: Enum.join(school_ids, ",")}

    Req.get!(url("/schools"), headers: default_headers(), params: params)
    |> Map.get(:body)
    |> Map.get("schools")
    |> Enum.map(&to_school/1)
  end

  defp to_school(data) do
    %School{
      id: data["id"],
      name: data["name"],
      city: data["city"],
      country: data["country"]
    }
  end
end
