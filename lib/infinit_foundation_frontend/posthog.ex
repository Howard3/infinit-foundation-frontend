defmodule InfinitFoundationFrontend.Posthog do
  @moduledoc """
  Handles PostHog analytics integration
  """

  require Logger


  def capture(event_name, user_id: distinct_id), do: capture(event_name, [user_id: distinct_id, properties: %{}])
  def capture(event_name, [user_id: distinct_id, properties: properties]) do
    Task.start(fn ->
      try do
        Posthog.capture(event_name, %{
          distinct_id: distinct_id,
          properties: Map.merge(
            %{
              app_env: config_env(),
              timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
            },
            properties
          )
        })
      rescue
        error ->
          Logger.error("PostHog event failed: #{inspect(error)}")
      end
    end)
  end

  defp config_env do
    Application.get_env(:infinit_foundation_frontend, :env, :dev)
  end
end
