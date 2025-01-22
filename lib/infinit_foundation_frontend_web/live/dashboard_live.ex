defmodule InfinitFoundationFrontendWeb.DashboardLive do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Schemas.{Student, Sponsorship}

  def mount(_params, session, socket) do
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
                name: "#{student.first_name} #{student.last_name}",
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
        total_contribution = total_months * 30 # TODO: Get amount from config
        total_meals = total_months * 20 # Assuming 60 meals per month

        {:ok,
         assign(socket,
           active_sponsorships: sponsored_students,
           impact_metrics: [
             %{label: "Total Meals Provided", value: total_meals},
             %{label: "Students Supported", value: length(sponsored_students)},
             %{label: "Months of Support", value: total_months},
             %{label: "Total Contribution", value: "$#{total_contribution}"}
           ],
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
             %{label: "Total Contribution", value: "$0"}
           ],
           payment_history: [],
           student_updates: []
         )}
    end
  end

  @impl true
  def handle_event("load_payments", _params, socket) do
    {:ok, results} = Stripe.Charge.search(%{
      query: "metadata[\"sponsor_id\"]:\"#{socket.assigns.user_id}\" AND status:\"succeeded\""
    })

    charges = results.data
    |> Enum.map(fn charge ->
      dbg(socket.assigns.active_sponsorships)
      student_id = charge.metadata["student_id"]
      student = socket.assigns.active_sponsorships |> Enum.find(fn student -> student.student.id == student_id end)
      student_name = case student do
        nil -> "Unknown Student"
        _ -> student.student.name
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
