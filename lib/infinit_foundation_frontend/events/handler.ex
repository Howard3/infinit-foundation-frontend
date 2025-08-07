defmodule InfinitFoundationFrontend.Events.Handler do
  alias InfinitFoundationFrontend.Posthog
  alias InfinitFoundationFrontend.Brevo
  alias InfinitFoundationFrontend.Events.SignedIn
  alias InfinitFoundationFrontend.Clerk
  alias InfinitFoundationFrontend.Events.Donated

  require Logger

  def handle(evt = %Donated{}) do
    # todo: handle failures
    brevo_event(evt.user_id, "donated", %{
      child_name: evt.child_name,
      child_id: evt.child_id,
      amount: evt.amount,
      currency: evt.currency
    })

    posthog_event("Completed Sponsorship",
      user_id: evt.user_id,
      properties: %{
        student_id: evt.child_id,
        amount: evt.amount,
        currency: evt.currency
      }
    )
  end

  def handle(%SignedIn{user_id: user_id}) do
    # todo: handle failures
    brevo_event(user_id, "signed_in", %{})
    posthog_event("User Signed In", user_id: user_id, properties: %{})
  end

  #
  # Convenience functions for sending events to Brevo and Posthog asynchronously
  #
  #
  defp brevo_event(user_id, event, properties) do
    Task.start(fn ->
      Logger.info("Sending event to brevo", event: event)

      # TODO: CACHE THIS

      Brevo.User.new_from_id!(user_id)
      |> Brevo.send_event(event, properties)
      |> dbg
    end)
  end

  defp posthog_event(event, user_id: user_id, properties: properties) do
    Task.start(fn ->
      Logger.info("Sending event to posthog", event: event)
      Posthog.capture(event, user_id: user_id, properties: properties)
    end)
  end
end
