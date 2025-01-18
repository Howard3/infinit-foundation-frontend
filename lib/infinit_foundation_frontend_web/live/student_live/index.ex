defmodule InfinitFoundationFrontendWeb.StudentLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Schemas.{Location, Student, StudentFilter}

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

    students_response = ApiClient.list_students(%StudentFilter{page: 1})

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
        name: public_student_name(student.first_name, student.last_name),
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
       selected_location: nil,
       selected_min_age: nil,
       selected_max_age: nil,
       page_count: calculate_page_count(students_response.total),
       current_page: 1
     )}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    filter = %StudentFilter{
      page: page,
      min_age: socket.assigns.selected_min_age,
      max_age: socket.assigns.selected_max_age
    }

    filter = case socket.assigns.selected_location do
      nil -> filter
      location ->
        [country, city] = String.split(location, " - ")
        %{filter | country: country, city: city}
    end

    students_response = ApiClient.list_students(filter)
    students = transform_students(students_response.students)

    {:noreply, assign(socket, students: students, current_page: page)}
  end

  @impl true
  def handle_event("filter_age", params, socket) do
    min_age = parse_age(params["min_age"])
    max_age = parse_age(params["max_age"])

    filter = %StudentFilter{
      page: 1,
      min_age: min_age,
      max_age: max_age
    }

    # Include location filter if set
    filter = case socket.assigns.selected_location do
      nil -> filter
      location ->
        [country, city] = String.split(location, " - ")
        %{filter | country: country, city: city}
    end

    students_response = ApiClient.list_students(filter)

    {:noreply,
     assign(socket,
       students: transform_students(students_response.students),
       selected_min_age: min_age,
       selected_max_age: max_age,
       current_page: 1
     )}
  end

  @impl true
  def handle_event("filter_location", %{"location" => ""}, socket) do
    filter = %StudentFilter{
      page: 1,
      min_age: socket.assigns.selected_min_age,
      max_age: socket.assigns.selected_max_age
    }

    students_response = ApiClient.list_students(filter)

    {:noreply,
     assign(socket,
       students: transform_students(students_response.students),
       selected_location: nil,
       current_page: 1
     )}
  end

  def handle_event("filter_location", %{"location" => location}, socket) do
    [country, city] = String.split(location, " - ")

    filter = %StudentFilter{
      page: 1,
      country: country,
      city: city,
      min_age: socket.assigns.selected_min_age,
      max_age: socket.assigns.selected_max_age
    }

    students_response = ApiClient.list_students(filter)

    {:noreply,
     assign(socket,
       students: transform_students(students_response.students),
       selected_location: location,
       current_page: 1
     )}
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

  defp transform_students([]), do: []
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
        name: public_student_name(student.first_name, student.last_name),
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

  defp calculate_page_count(total), do: div(total, ApiClient.default_page_size()) + 1
  defp public_student_name(first, last), do: first <> " " <> (last |> String.slice(0, 1)) <> "."

  defp parse_age(value) when is_binary(value) do
    case Integer.parse(value) do
      {age, ""} when age > 0 -> age
      _ -> nil
    end
  end
  defp parse_age(_), do: nil
end
