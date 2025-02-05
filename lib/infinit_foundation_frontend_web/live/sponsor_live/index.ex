defmodule InfinitFoundationFrontendWeb.SponsorLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Config.Sponsorship
  alias InfinitFoundationFrontend.Posthog

  require Logger

  @impl true
  def mount(%{"id" => student_id}, session, socket) do
    user_id = session["user_id"]
    Posthog.capture("Started Sponsorship Process",
      user_id: user_id,
      properties: %{
        student_id: student_id
      }
    )
    socket = assign(socket, :user_id, user_id)
    socket = assign(socket, :stripe_public_key, Application.get_env(:infinit_foundation_frontend, :stripe)[:public_key])
    socket = assign(socket, :setup_intent, nil)

    {:ok, checkout_result} = prepare_checkout(student_id, user_id)

    # Verify the lock is still valid
    case InfinitFoundationFrontend.SponsorshipLocks.get_lock_info(student_id) do
      {:ok, expiry_time} ->
        remaining_seconds = DateTime.diff(expiry_time, DateTime.utc_now())
        remaining_minutes = div(remaining_seconds, 60)

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
           stripe_public_key: Application.get_env(:infinit_foundation_frontend, :stripe)[:public_key],
           payment_intent_id: checkout_result.payment_intent_id,
           client_secret: checkout_result.client_secret,
           remaining_minutes: remaining_minutes
         )}

      {:error, :not_found} ->
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

  defp prepare_checkout(student_id, user_id) do
    Posthog.capture("Started Sponsorship Checkout",
      user_id: user_id,
      properties: %{
        student_id: student_id
      }
    )
    Logger.info("Preparing checkout for student #{student_id} with user #{user_id}")
    {:ok, payment_intent} = Stripe.PaymentIntent.create(%{
      amount: Sponsorship.amount_in_cents(),
      currency: Sponsorship.currency,
      payment_method_types: ["card"],
      metadata: %{
        student_id: student_id,
        sponsor_id: user_id
      }
    })

    {:ok, %{payment_intent_id: payment_intent.id, client_secret: payment_intent.client_secret}}
  end

end
