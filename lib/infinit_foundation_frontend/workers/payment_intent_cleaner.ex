defmodule InfinitFoundationFrontend.Workers.PaymentIntentCleaner do
  use GenServer
  require Logger
  alias InfinitFoundationFrontend.Posthog

  @cleanup_interval :timer.minutes(15)
  @stale_threshold 30

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_stale_intents()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    # Cleanup immediately on startup
    cleanup_stale_intents()
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_stale_intents do
    Logger.info("Starting cleanup of stale payment intents")

    # Get payment intents created more than @stale_threshold minutes ago that are still 'requires_payment_method'
    {:ok, payment_intents} = Stripe.PaymentIntent.list(%{
      created: %{lt: unix_time_minus_minutes(@stale_threshold)},
      limit: 100
    })

    payment_intents.data
    |> Enum.filter(&(&1.status == "requires_payment_method"))
    |> Enum.each(fn intent ->
      case Stripe.PaymentIntent.cancel(intent.id) do
        {:ok, canceled_intent} ->
          Logger.info("Canceled stale payment intent: #{canceled_intent.id}")

          # Track the cancellation in PostHog
          Posthog.capture("Canceled Stale Payment Intent",
            user_id: canceled_intent.metadata["sponsor_id"],
            properties: %{
              payment_intent_id: canceled_intent.id,
              student_id: canceled_intent.metadata["student_id"],
              amount: canceled_intent.amount / 100,
              currency: canceled_intent.currency
            }
          )

        {:error, error} ->
          Logger.error("Failed to cancel payment intent #{intent.id}: #{inspect(error)}")
      end
    end)
  end

  defp unix_time_minus_minutes(minutes) do
    DateTime.utc_now()
    |> DateTime.add(-minutes, :minute)
    |> DateTime.to_unix()
  end
end
