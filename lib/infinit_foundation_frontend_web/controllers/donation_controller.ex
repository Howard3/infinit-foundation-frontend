defmodule InfinitFoundationFrontendWeb.DonationController do
  use InfinitFoundationFrontendWeb, :controller
  alias InfinitFoundationFrontend.Posthog

  def success(conn, %{"payment_intent_id" => payment_intent_id}) do
    case Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, %{status: "succeeded"} = payment_intent} ->
        sponsor_id = payment_intent.metadata["sponsor_id"]
        amount = payment_intent.amount / 100

        Posthog.capture("Completed General Donation",
          user_id: sponsor_id,
          properties: %{
            amount: amount,
            currency: payment_intent.currency,
            payment_intent_id: payment_intent_id
          }
        )

        conn
        |> put_flash(:info, "Thank you for your generous donation!")
        |> render(:success, amount: amount)

      _ ->
        conn
        |> put_flash(:error, "Unable to verify payment. Please contact support.")
        |> redirect(to: ~p"/donate")
    end
  end
end
