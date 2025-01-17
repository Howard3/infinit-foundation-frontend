defmodule InfinitFoundationFrontendWeb.StudentLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Schemas.{Location, Student}

  @sponsorship_amount 250 # USD

  @impl true
  def mount(_params, _session, socket) do
    locations = ApiClient.list_locations()

    # Create combined location options for the dropdown
    location_options =
      locations
      |> Enum.flat_map(fn %Location{country: country, cities: cities} ->
        Enum.map(cities, fn city -> "#{country} - #{city}" end)
      end)
      |> Enum.sort()

    students_response = ApiClient.list_students(%{page: 1, limit: 10})

    # Get unique school IDs and fetch school details
    school_ids = students_response.students
                |> Enum.map(& &1.school_id)
                |> Enum.uniq()

    schools = ApiClient.list_schools(school_ids)
    schools_by_id = Map.new(schools, fn school -> {school.id, school} end)

    # Transform the API response to match our expected format
    students = Enum.map(students_response.students, fn student ->
      school = Map.get(schools_by_id, student.school_id)

      %{
        id: student.id,
        name: "#{student.first_name} #{student.last_name}",
        age: calculate_age(student.date_of_birth),
        grade: student.grade,
        school: school.name,
        location: "#{school.city}, #{school.country}",
        story: "",
        sponsored: false,
        image_url: student.profile_photo_url && ApiClient.photo_url(student.profile_photo_url)
      }
    end)

    {:ok,
     assign(socket,
       students: students,
       total: students_response.total,
       sponsorship_amount: @sponsorship_amount,
       location_options: location_options,
       selected_location: nil
     )}
  end

  @impl true
  def handle_event("filter_location", %{"location" => ""}, socket) do
    # Reset filter
    students_response = ApiClient.list_students(%{page: 1, limit: 10})
    {:noreply, assign(socket, :students, transform_students(students_response.students))}
  end

  def handle_event("filter_location", %{"location" => location}, socket) do
    [country, city] = String.split(location, " - ")
    students_response = ApiClient.list_students(%{
      page: 1,
      limit: 10,
      country: country,
      city: city
    })

    {:noreply, assign(socket, :students, transform_students(students_response.students))}
  end

  @impl true
  def handle_event("sponsor", %{"id" => id}, socket) do
    # This would eventually handle the sponsorship process
    # For now, just show what we'd do
    student_id = String.to_integer(id)
    students = Enum.map(socket.assigns.students, fn student ->
      if student.id == student_id do
        %{student | sponsored: true}
      else
        student
      end
    end)

    {:noreply, assign(socket, :students, students)}
  end

  defp transform_students(students) do
    # Get unique school IDs and fetch school details
    school_ids = students
                |> Enum.map(& &1.school_id)
                |> Enum.uniq()

    schools = ApiClient.list_schools(school_ids)
    schools_by_id = Map.new(schools, fn school -> {school.id, school} end)

    Enum.map(students, fn student ->
      school = Map.get(schools_by_id, student.school_id)

      %{
        id: student.id,
        name: "#{student.first_name} #{student.last_name}",
        age: calculate_age(student.date_of_birth),
        grade: student.grade,
        school: school.name,
        location: "#{school.city}, #{school.country}",
        story: "",
        sponsored: false,
        image_url: student.profile_photo_url && ApiClient.photo_url(student.profile_photo_url)
      }
    end)
  end

  defp calculate_age(date_of_birth) do
    case date_of_birth do
      nil -> nil
      dob when is_binary(dob) ->
        case Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, dob) do
          true ->
            today = Date.utc_today()
            {:ok, birth_date} = Date.from_iso8601(dob)
            age = today.year - birth_date.year - if today.month > birth_date.month or (today.month == birth_date.month and today.day >= birth_date.day), do: 0, else: 1
            age
          false -> nil
        end
      _ -> nil
    end
  end
end
