defmodule InfinitFoundationFrontendWeb.SponsorshipController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.Events
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Posthog

  def success(conn, %{"payment_intent_id" => payment_intent_id}) do
    case Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, payment_intent} when payment_intent.status == "succeeded" ->
        student_id = payment_intent.metadata["student_id"]
        sponsor_id = payment_intent.metadata["sponsor_id"]
        amount = payment_intent.amount / 100
        currency = payment_intent.currency

        # TODO: handle errors
        student_name =
          ApiClient.get_student(student_id)
          |> ApiClient.get_student_full_name()

        Events.Donated.new(sponsor_id, student_id, student_name, amount, currency)
        |> Events.Handler.handle()

        # Extract metadata
        # Record the sponsorship via API
        case ApiClient.create_sponsorship(%{
               student_id: student_id,
               sponsor_id: sponsor_id,
               payment_intent_id: payment_intent_id,
               amount: payment_intent.amount,
               currency: payment_intent.currency
             }) do
          :ok ->
            conn
            |> put_flash(:info, "Thank you for your sponsorship!")
            |> render(:success)

          {:error, _response} ->
            conn
            |> put_flash(:error, "Error recording sponsorship. Please contact support.")
            |> redirect(to: ~p"/students")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, "Unable to verify payment. Please contact support.")
        |> redirect(to: ~p"/students")
    end
  end
end
