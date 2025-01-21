defmodule InfinitFoundationFrontendWeb.SponsorshipController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.ApiClient

  def success(conn, %{"payment_intent_id" => payment_intent_id}) do
    case Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, payment_intent} ->
        # Verify payment was successful
        if payment_intent.status == "succeeded" do
          # Extract metadata
          student_id = payment_intent.metadata["student_id"]
          sponsor_id = payment_intent.metadata["sponsor_id"]

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
        else
          conn
          |> put_flash(:error, "Payment processing error. Please contact support.")
          |> redirect(to: ~p"/students")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, "Unable to verify payment. Please contact support.")
        |> redirect(to: ~p"/students")
    end
  end
end
