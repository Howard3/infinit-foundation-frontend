defmodule InfinitFoundationFrontendWeb.SponsorLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Config.Sponsorship

  @impl true
  def mount(%{"id" => student_id} = params, session, socket) do
    socket = assign(socket, :user_id, session["user_id"])
    socket = assign(socket, :stripe_public_key, Application.get_env(:infinit_foundation_frontend, :stripe)[:public_key])
    socket = assign(socket, :setup_intent, nil)
    # Verify the lock is still valid
    case InfinitFoundationFrontend.SponsorshipLocks.extend_lock(student_id, socket.assigns.user_id) do
      :ok ->
        # Start the periodic lock extension
        Process.send_after(self(), :extend_lock, :timer.minutes(5))

        # Get student details
        student = ApiClient.get_student(student_id)
        sponsorship = Sponsorship.sponsorship_details()

        {:ok,
         assign(socket,
           student: student,
           sponsorship: sponsorship,
           page_title: "Complete Sponsorship",
           stripe_public_key: Application.get_env(:infinit_foundation_frontend, :stripe)[:public_key]
         )}

      {:error, :not_lock_holder} ->
        {:ok,
         socket
         |> put_flash(:error, "Your sponsorship session has expired. Please try again.")
         |> push_navigate(to: ~p"/students")}
    end
  end

  @impl true
  def handle_info(:extend_lock, socket) do
    if student = socket.assigns[:student] do
      holder_id = socket.assigns.user_id
      InfinitFoundationFrontend.SponsorshipLocks.extend_lock(student.id, holder_id)
      Process.send_after(self(), :extend_lock, :timer.minutes(5))
    end

    {:noreply, socket}
  end

  def handle_event("checkout", _params, socket) do
    {:ok, payment_intent} = Stripe.PaymentIntent.create(%{
      amount: Sponsorship.amount_in_cents(),
      currency: Sponsorship.currency,
      payment_method_types: ["card"],
      metadata: %{
        student_id: socket.assigns.student.id,
        sponsor_id: socket.assigns.user_id
      }
    })
    socket = push_event(socket, "payment-intent", %{
      payment_intent: payment_intent.id,
      client_secret: payment_intent.client_secret
    })
    {:noreply, socket}
  end
end
