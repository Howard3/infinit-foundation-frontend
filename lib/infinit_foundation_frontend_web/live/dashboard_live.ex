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

        total_months = calculate_total_months(sponsorships)

        # Get actual meal count from API
        total_meals = case ApiClient.get_sponsor_impact(session["user_id"]) do
          {:ok, %{total_meal_count: count}} -> count
          {:error, _} -> 0
        end

        # Get recent events
        recent_events = case ApiClient.list_sponsor_events(session["user_id"], limit: 10) do
          {:ok, %{events: events}} -> events
          {:error, _} -> []
        end

        {:ok,
         assign(socket,
           active_sponsorships: sponsored_students,
           impact_metrics: [
             %{label: "Total Meals Provided", value: total_meals},
             %{label: "Students Supported", value: length(sponsored_students)},
             %{label: "Months of Support", value: total_months},
           ],
           recent_events: recent_events,
           payment_history: [], # TODO: Implement payment history
           student_updates: [] # TODO: Implement student updates
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           active_sponsorships: [],
           impact_metrics: [
             %{label: "Total Meals Provided", value: "0"},
             %{label: "Students Supported", value: "0"},
             %{label: "Months of Support", value: "0"},
           ],
           recent_events: [],
           payment_history: [],
           student_updates: []
         )}
    end
  end

  @impl true
  def handle_event("load_payments", _params, socket = %{assigns: %{user_id: user_id, active_sponsorships: active_sponsorships}}) do
    Posthog.capture("Viewed Payment History",
      user_id: user_id
    )
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
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp get_location(%Student{school_id: school_id}) do
    case ApiClient.list_schools([school_id]) do
      [school | _] -> school.city
      _ -> "Unknown Location"
    end
  end

  defp calculate_total_months(sponsorships) do
    Enum.reduce(sponsorships, 0, fn sponsorship, acc ->
      months_between =
        Date.diff(sponsorship.end_date, sponsorship.start_date)
        |> div(30) # Approximate months
      acc + months_between
    end)
  end
end
