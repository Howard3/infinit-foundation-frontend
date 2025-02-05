defmodule InfinitFoundationFrontendWeb.StudentLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Schemas.{Location, StudentFilter}
  alias InfinitFoundationFrontend.Config.Sponsorship
  alias InfinitFoundationFrontendWeb.ViewHelper
  alias InfinitFoundationFrontend.Posthog

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, :user_id, session["user_id"])
    locations = ApiClient.list_locations()

    # Create combined location options for the dropdown
    location_options =
      locations
      |> Enum.flat_map(fn %Location{country: country, cities: cities} ->
        Enum.map(cities, fn city -> "#{country} - #{city}" end)
      end)
      |> Enum.sort()

    students_response = ApiClient.list_students(%StudentFilter{page: 1})
    students = transform_students(students_response.students, socket.assigns.user_id)

    {:ok,
     assign(socket,
       students: students,
       total: students_response.total,
       sponsorship: Sponsorship.sponsorship_details(),
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
    Posthog.capture("Changed Page",
      user_id: socket.assigns.user_id,
      properties: %{
        page: page
      }
    )
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
    students = transform_students(students_response.students, socket.assigns.user_id)

    {:noreply, assign(socket, students: students, current_page: page)}
  end

  @impl true
  def handle_event("filter_age", params, socket) do
    Posthog.capture("Applied Age Filter",
      user_id: socket.assigns.user_id,
      properties: %{
        min_age: params["min_age"],
        max_age: params["max_age"]
      }
    )
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
       students: transform_students(students_response.students, socket.assigns.user_id),
       selected_min_age: min_age,
       selected_max_age: max_age,
       current_page: 1
     )}
  end

  @impl true
  def handle_event("filter_location", %{"location" => ""}, socket) do
    Posthog.capture("Cleared Location Filter",
      user_id: socket.assigns.user_id
    )
    filter = %StudentFilter{
      page: 1,
      min_age: socket.assigns.selected_min_age,
      max_age: socket.assigns.selected_max_age
    }

    students_response = ApiClient.list_students(filter)

    {:noreply,
     assign(socket,
       students: transform_students(students_response.students, socket.assigns.user_id),
       selected_location: nil,
       current_page: 1
     )}
  end

  def handle_event("filter_location", %{"location" => location}, socket) do
    Posthog.capture("Applied Location Filter",
      user_id: socket.assigns.user_id,
      properties: %{
        location: location
      }
    )
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
       students: transform_students(students_response.students, socket.assigns.user_id),
       selected_location: location,
       current_page: 1
     )}
  end

  @impl true
  def handle_event("request_sponsorship", %{"id" => id}, socket) do
    Posthog.capture("Requested Sponsorship",
      user_id: socket.assigns.user_id,
      properties: %{
        student_id: id
      }
    )
    case socket.assigns.user_id do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Please sign in to sponsor a student")
         |> push_navigate(to: ~p"/sign-in")}

      holder_id ->
        student_id = id
        case InfinitFoundationFrontend.SponsorshipLocks.request_lock(student_id, holder_id) do
          :ok ->
            # Start the periodic lock extension
            Process.send_after(self(), :extend_lock, :timer.minutes(5))

            # Navigate to checkout while maintaining the lock
            {:noreply,
             socket
             |> assign(:sponsorship_lock, student_id)
             |> push_navigate(to: ~p"/sponsor/#{student_id}")}

          {:error, :already_locked} ->
            {:noreply,
             socket
             |> put_flash(:error, "This student is currently in the process of being sponsored by someone else")}
        end
    end
  end


  defp transform_students([], _), do: []
  defp transform_students(students, user_id) do
    # Get unique school IDs and fetch school details
    school_ids = students
                |> Enum.map(& &1.school_id)
                |> Enum.uniq()
                |> Enum.filter(& &1 != "")

    schools_by_id = case ApiClient.list_schools(school_ids) do
      [] -> %{}
      schools -> Map.new(schools, fn school -> {school.id, school} end)
    end

    # Get lock status for all students
    student_ids = Enum.map(students, & &1.id)
    lock_statuses = InfinitFoundationFrontend.SponsorshipLocks.check_locks(student_ids, user_id)

    Enum.zip_with([students, lock_statuses], fn [student, lock_status] ->
      school = Map.get(schools_by_id, student.school_id, %{})

      %{
        id: student.id,
        name: ViewHelper.format_student_name(student.first_name, student.last_name),
        age: calculate_age(student.date_of_birth),
        grade: student.grade,
        school: Map.get(school, :name, ""),
        location: "#{Map.get(school, :city, "")}, #{Map.get(school, :country, "")}",
        story: "",
        sponsored: false,
        lock_status: lock_status,
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

  defp parse_age(value) when is_binary(value) do
    case Integer.parse(value) do
      {age, ""} when age > 0 -> age
      _ -> nil
    end
  end
  defp parse_age(_), do: nil
end
