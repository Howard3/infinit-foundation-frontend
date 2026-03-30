defmodule InfinitFoundationFrontendWeb.DonateLive do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.Config.Sponsorship
  alias InfinitFoundationFrontend.Posthog

  require Logger

  @preset_amounts [150, 250, 500, 750, 1000, 2500]
  @default_amount 150

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    Posthog.capture("Viewed General Donation Page", user_id: user_id)

    socket =
      assign(socket,
        user_id: user_id,
        page_title: "Donate",
        preset_amounts: @preset_amounts,
        selected_amount: @default_amount,
        custom_amount: nil,
        step: :amount
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("select_amount", %{"amount" => amount_str}, socket) do
    amount = String.to_integer(amount_str)
    {:noreply, assign(socket, selected_amount: amount, custom_amount: nil)}
  end

  @impl true
  def handle_event("custom_amount", %{"amount" => amount_str}, socket) do
    case Integer.parse(amount_str) do
      {amount, _} when amount >= 1 ->
        {:noreply, assign(socket, selected_amount: amount, custom_amount: amount)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("proceed_to_checkout", _params, socket) do
    amount = socket.assigns.selected_amount
    user_id = socket.assigns.user_id

    if is_nil(user_id) do
      {:noreply,
       socket
       |> put_flash(:error, "Please sign in to continue.")
       |> push_navigate(to: ~p"/sign-in")}
    else
      Posthog.capture("Started General Donation Checkout",
        user_id: user_id,
        properties: %{amount: amount}
      )

      Logger.info("Preparing general donation checkout for user #{user_id}, amount: $#{amount}")

      {:ok, payment_intent} =
        Stripe.PaymentIntent.create(%{
          amount: amount * 100,
          currency: Sponsorship.currency(),
          payment_method_types: ["card"],
          metadata: %{
            sponsor_id: user_id,
            donation_type: "general",
            amount_dollars: amount
          }
        })

      {:noreply,
       assign(socket,
         step: :checkout,
         stripe_public_key:
           Application.get_env(:infinit_foundation_frontend, :stripe)[:public_key],
         client_secret: payment_intent.client_secret,
         payment_intent_id: payment_intent.id
       )}
    end
  end

  @impl true
  def handle_event("back_to_amount", _params, socket) do
    {:noreply, assign(socket, step: :amount, client_secret: nil, payment_intent_id: nil)}
  end

  defp format_amount(amount) when amount >= 1000 do
    whole = div(amount, 1000)
    remainder = rem(amount, 1000)

    if remainder == 0 do
      "$#{whole},000"
    else
      "$#{whole},#{String.pad_leading(Integer.to_string(remainder), 3, "0")}"
    end
  end

  defp format_amount(amount), do: "$#{amount}"

  defp impact_description(amount) do
    children = div(amount, 150)

    if children >= 1 do
      "This provides approximately #{amount} nutritious meals — enough to support #{children} #{if children > 1, do: "children", else: "child"} for a full semester across our partner schools."
    else
      "This provides approximately #{amount} nutritious meals for students across our partner schools, supporting their health and ability to focus in the classroom."
    end
  end
end
