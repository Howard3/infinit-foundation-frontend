defmodule InfinitFoundationFrontendWeb.SponsorshipController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Posthog

  def success(conn, %{"payment_intent_id" => payment_intent_id}) do
    case Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, payment_intent} when payment_intent.status == "succeeded" ->
        student_id = payment_intent.metadata["student_id"]
        sponsor_id = payment_intent.metadata["sponsor_id"]

        Posthog.capture("Completed Sponsorship",
          user_id: sponsor_id,
          properties: %{
            student_id: student_id,
            amount: payment_intent.amount / 100,
            currency: payment_intent.currency
          }
        )
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
