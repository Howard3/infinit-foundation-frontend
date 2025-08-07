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
      get_user_email_from_clerk(user_id)
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

  defp get_user_email_from_clerk(user_id) do
    Logger.info("Fetching user from clerk", user_id: user_id)

    {:ok, user_data} = Clerk.get_user(user_id)

    Clerk.extract_email(user_data)
  end
end
