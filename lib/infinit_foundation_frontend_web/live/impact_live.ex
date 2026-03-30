defmodule InfinitFoundationFrontendWeb.ImpactLive do
  use InfinitFoundationFrontendWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    metrics = [
      %{
        number: "550+",
        label: "Daily Meals Served",
        description: "Nutritious meals provided to children every school day"
      },
      %{
        number: "58%",
        label: "Reduction in malnourishment",
        description: "Reduction in malnourishment among children"
      },
      %{
        number: "76%",
        label: "Reduction in severe malnourishment",
        description: "Reduction in severe malnourishment among children"
      }
    ]

    annual_growth = [
      %{year: 2021, students: 20, schools: 1},
      %{year: 2022, students: 25, schools: 1},
      %{year: 2023, students: 30, schools: 1},
      %{year: 2024, students: 50, schools: 2},
      %{year: 2025, students: 250, schools: 2}
    ]

    {:ok,
     assign(socket,
       metrics: metrics,
       annual_growth: annual_growth
     )}
  end
end
