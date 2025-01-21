defmodule InfinitFoundationFrontend.ApiClient do
  alias InfinitFoundationFrontend.Schemas.{
    Location,
    Student,
    PaginatedStudents,
    School,
    StudentFilter
  }

  @base_url Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :base_url])
  @api_key Application.compile_env(:infinit_foundation_frontend, [:feeding_backend, :api_key])
  @page_size 18

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
  end

  def get_student(student_id) do
    Req.get!(url("/students/#{student_id}"), headers: default_headers())
    |> Map.get(:body)
    |> to_student()
  end

  @spec list_students(StudentFilter.t()) :: PaginatedStudents.t()
  def list_students(filters \\ %StudentFilter{})

  def list_students(%StudentFilter{} = filters) do
    filters
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> do_list_students()
  end

  defp do_list_students(params) do
    params_with_defaults = Map.put_new(params, :limit, @page_size)

    response = Req.get!(url("/students"), headers: default_headers(), params: params_with_defaults)
    body = response.body

    %PaginatedStudents{
      students: Enum.map(body["students"], &to_student/1),
      total: body["total"]
    }
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

  def default_page_size, do: @page_size

  @doc """
  Creates a sponsorship record for a student.
  """
  def create_sponsorship(%{student_id: student_id, sponsor_id: sponsor_id} = _params) do
    # Get the sponsorship end date from config
    end_date = InfinitFoundationFrontend.Config.Sponsorship.ending_timestamp()
    # Use today as the start date
    start_date = Date.utc_today() |> Date.to_string()

    body = %{
      sponsorId: sponsor_id,
      startDate: start_date,
      endDate: end_date
    }

    case Req.post!(
      url("/students/#{student_id}/sponsor"),
      headers: default_headers(),
      json: body
    ) do
      %{status: 200, body: %{"success" => true}} -> :ok
      response -> {:error, response}
    end
  end
end
