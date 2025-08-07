defmodule InfinitFoundationFrontend.ApiClient do
  alias InfinitFoundationFrontend.Schemas.{
    Location,
    Student,
    PaginatedStudents,
    School,
    StudentFilter,
    Sponsorship,
    SponsorEvent
  }

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

    response =
      Req.get!(url("/students"), headers: default_headers(), params: params_with_defaults)

    body = response.body

    %PaginatedStudents{
      students: Enum.map(body["students"], &to_student/1),
      total: body["total"]
    }
  end

  def feeding_photo_url(id) when is_binary(id) do
    feeding_photo_base_url() <> "/" <> id
  end

  def photo_url(relative_path) when is_binary(relative_path) do
    case relative_path do
      "/student/profile/photo/" <> _rest ->
        relative_path

      # FIXME: this is a little hacky, but it works for now
      _ ->
        photo_base_url() <> relative_path
    end
  end

  defp api_key, do: Application.get_env(:infinit_foundation_frontend, :feeding_backend)[:api_key]

  defp base_url,
    do: Application.get_env(:infinit_foundation_frontend, :feeding_backend)[:base_url]

  defp photo_base_url, do: base_url() |> String.replace("/api", "/student/profile/photo")
  defp feeding_photo_base_url, do: base_url() |> String.replace("/api", "/student/feeding/photo")

  defp url(path), do: base_url() <> path

  defp default_headers do
    [
      {"accept", "application/json"},
      {"X-API-Key", api_key()}
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

  def get_student_full_name(%Student{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  def list_schools([]), do: []

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
    end_date = InfinitFoundationFrontend.Config.Sponsorship.ending_timestamp()
    start_date = InfinitFoundationFrontend.Config.Sponsorship.starting_timestamp()

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

  @doc """
  Gets a list of students currently sponsored by the given sponsor.

  Returns a list of sponsorship records containing student IDs and date ranges.
  """
  @spec list_sponsored_students(String.t()) :: {:ok, [Sponsorship.t()]} | {:error, any()}
  def list_sponsored_students(sponsor_id) do
    case Req.get!(url("/sponsors/#{sponsor_id}/students"), headers: default_headers()) do
      %{status: 200, body: sponsorships} when is_list(sponsorships) ->
        {:ok,
         Enum.map(sponsorships, fn sponsorship ->
           %Sponsorship{
             student_id: sponsorship["studentId"],
             start_date: Date.from_iso8601!(sponsorship["startDate"]),
             end_date: Date.from_iso8601!(sponsorship["endDate"])
           }
         end)}

      response ->
        {:error, response}
    end
  end

  @doc """
  Gets the impact statistics for a given sponsor.
  Returns {:ok, %{total_meal_count: integer}} on success or {:error, any} on failure.
  """
  @spec get_sponsor_impact(String.t()) :: {:ok, %{total_meal_count: integer}} | {:error, any()}
  def get_sponsor_impact(sponsor_id) do
    case Req.get!(url("/sponsors/#{sponsor_id}/impact"), headers: default_headers()) do
      %{status: 200, body: %{"totalMealCount" => total_meal_count}} ->
        {:ok, %{total_meal_count: total_meal_count}}

      response ->
        {:error, response}
    end
  end

  @doc """
  Gets the recent events for a sponsor.
  Returns {:ok, %{events: [SponsorEvent.t()], total: integer}} on success or {:error, any} on failure.
  """
  @spec list_sponsor_events(String.t(), keyword()) ::
          {:ok, %{events: [SponsorEvent.t()], total: integer}} | {:error, any()}
  def list_sponsor_events(sponsor_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    limit = Keyword.get(opts, :limit, 10)

    case Req.get!(url("/sponsors/#{sponsor_id}/events"),
           headers: default_headers(),
           params: %{page: page, limit: limit}
         ) do
      %{status: 200, body: %{"events" => events, "total" => total}} ->
        {:ok,
         %{
           events:
             Enum.map(events, fn event ->
               %SponsorEvent{
                 student_id: event["studentId"],
                 student_name: event["studentName"],
                 feeding_time: NaiveDateTime.from_iso8601!(event["feedingTime"]),
                 school_id: event["schoolId"],
                 event_type: event["eventType"],
                 feeding_image_id: event["feedingImageId"]
               }
             end),
           total: total
         }}

      response ->
        {:error, response}
    end
  end
end
