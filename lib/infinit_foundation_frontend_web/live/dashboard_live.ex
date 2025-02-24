defmodule InfinitFoundationFrontendWeb.DashboardLive do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Schemas.Student
  alias InfinitFoundationFrontendWeb.ViewHelper
  alias InfinitFoundationFrontend.Schemas.SponsorEvent
  alias InfinitFoundationFrontend.Posthog

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    Posthog.capture("Viewed Dashboard",
      user_id: user_id,
      properties: %{
        timestamp: DateTime.utc_now()
      }
    )
    socket = assign(socket, :user_id, session["user_id"])
    socket = assign(socket, charges: [])
    socket = assign(socket, page: 1)
    socket = assign(socket, per_page: 3)

    case ApiClient.list_sponsored_students(session["user_id"]) do
      {:ok, sponsorships} ->
        sponsorships = sponsorships |> Enum.uniq_by(& &1.student_id)
        # Get full student details for each sponsorship
        sponsored_students =
          sponsorships
          |> Enum.map(fn sponsorship ->
            student = ApiClient.get_student(sponsorship.student_id)
            %{
              student: %{
                id: student.id |> to_string,
                first_name: student.first_name,
                last_name: student.last_name,
                grade: student.grade,
                location: get_location(student),
                image_url: ApiClient.photo_url(student.profile_photo_url)
              },
              formatted_amount: "$30/month", # TODO: Get from config
              start_date: Calendar.strftime(sponsorship.start_date, "%b %Y"),
              end_date: Calendar.strftime(sponsorship.end_date, "%b %Y")
            }
          end)

        # Get actual meal count from API
        total_meals = case ApiClient.get_sponsor_impact(session["user_id"]) do
          {:ok, %{total_meal_count: count}} -> count
          {:error, _} -> 0
        end

        # Get recent events and process for graph
        recent_events = case ApiClient.list_sponsor_events(session["user_id"], limit: 1000) do
          {:ok, %{events: events}} -> events
          {:error, _} -> []
        end

        # Process events for graph data
        feeding_stats = process_feeding_stats(recent_events)

        paginated_events = paginate_events(recent_events, 1, socket.assigns.per_page)

        {:ok,
         assign(socket,
           active_sponsorships: sponsored_students,
           impact_metrics: [
             %{label: "Total Meals Provided", value: total_meals},
             %{label: "Students Supported", value: length(sponsored_students)},
           ],
           recent_events: recent_events,
           paginated_events: paginated_events,
           payment_history: [], # TODO: Implement payment history
           student_updates: [], # TODO: Implement student updates
           feeding_stats: feeding_stats
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           active_sponsorships: [],
           impact_metrics: [
             %{label: "Total Meals Provided", value: "0"},
             %{label: "Students Supported", value: "0"},
           ],
           recent_events: [],
           paginated_events: [],
           payment_history: [],
           student_updates: [],
           feeding_stats: %{dates: [], counts: []}
         )}
    end
  end

  def handle_event("load_payments", _params, socket = %{assigns: %{user_id: "", active_sponsorships: []}}) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("load_payments", _params, socket = %{assigns: %{user_id: user_id, active_sponsorships: active_sponsorships}}) do
    Posthog.capture("Viewed Payment History", user_id: user_id)
    {:ok, results} = Stripe.Charge.search(%{
      query: "metadata[\"sponsor_id\"]:\"#{user_id}\" AND status:\"succeeded\""
    })

    charges = results.data
    |> Enum.map(fn charge ->
      student_id = charge.metadata["student_id"]
      student = active_sponsorships |> Enum.find(fn student -> student.student.id == student_id end)
      student_name = case student do
        nil -> "Unknown Student"
        _ -> ViewHelper.format_student_name(student.student.first_name, student.student.last_name)
      end

      %{
        date: charge.created,
        amount: charge.amount / 100,
        status: charge.status,
        formatted_amount: "$#{charge.amount / 100}",
        formatted_date: charge.created |> DateTime.from_unix!() |> DateTime.to_date() |> Date.to_string(),
        student_id: student_id,
        student_name: student_name
      }
    end)

    socket = assign(socket, :charges, charges)
    {:noreply, socket}
  end

  @impl true
  def handle_event("previous-page", _, socket) do
    new_page = max(1, socket.assigns.page - 1)
    paginated_events = paginate_events(socket.assigns.recent_events, new_page, socket.assigns.per_page)

    {:noreply, assign(socket, page: new_page, paginated_events: paginated_events)}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    total_pages = ceil(length(socket.assigns.recent_events) / socket.assigns.per_page)
    new_page = min(total_pages, socket.assigns.page + 1)
    paginated_events = paginate_events(socket.assigns.recent_events, new_page, socket.assigns.per_page)

    {:noreply, assign(socket, page: new_page, paginated_events: paginated_events)}
  end

  @impl true
  def handle_event("viewport-changed", %{"perPage" => per_page}, socket) do
    paginated_events = paginate_events(socket.assigns.recent_events, socket.assigns.page, per_page)

    {:noreply, socket
      |> assign(:per_page, per_page)
      |> assign(:paginated_events, paginated_events)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_event(socket, "hide-modal", %{})}
  end

  defp paginate_events(events, page, per_page) do
    events
    |> Enum.drop((page - 1) * per_page)
    |> Enum.take(per_page)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Get the location of the student's school
  # If the school ID is empty, return an empty string
  # Otherwise, get the location from the school
  defp get_location(%Student{school_id: ""}), do: ""

  defp get_location(%Student{school_id: school_id}) do
    case ApiClient.list_schools([school_id]) do
      [school | _] -> school.city
      _ -> "Unknown Location"
    end
  end

  # Helper to process feeding events into cumulative daily counts
  defp process_feeding_stats(events) do
    # Group events by date and count them
    daily_counts = events
    |> Enum.group_by(fn event ->
      NaiveDateTime.to_date(event.feeding_time)
    end)
    |> Map.new(fn {date, events} ->
      {Date.to_string(date), length(events)}
    end)

    # Get last 30 days
    today = Date.utc_today()
    dates = Date.range(Date.add(today, -29), today)

    # Create sorted lists of dates and cumulative counts
    dates_list = Enum.map(dates, &Date.to_string/1)
    counts_list = dates_list
    |> Enum.scan(0, fn date, acc ->
      acc + Map.get(daily_counts, date, 0)
    end)

    %{
      dates: dates_list,
      counts: counts_list
    }
  end
end
