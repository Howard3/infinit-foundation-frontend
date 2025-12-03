defmodule InfinitFoundationFrontend.Config.Sponsorship do
  @moduledoc """
  Central configuration for sponsorship details
  """

  def amount, do: 150
  def currency, do: "USD"
  def formatted_amount, do: "$#{amount()}"

  def academic_years, do: "2025-2026"
  def academic_period, do: "February 2025 - June 2026"

  def starting_timestamp, do: "2025-02-01"
  def ending_timestamp, do: "2026-06-30"
  def amount_in_cents, do: amount() * 100

  def sponsorship_details do
    %{
      amount: amount(),
      currency: currency(),
      formatted_amount: formatted_amount(),
      academic_years: academic_years(),
      academic_period: academic_period(),
      ending_timestamp: ending_timestamp(),
      starting_timestamp: starting_timestamp()
    }
  end
end
