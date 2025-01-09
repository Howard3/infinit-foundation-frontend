defmodule InfinitFoundationFrontendWeb.ImpactLive do
  use InfinitFoundationFrontendWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    metrics = [
      %{
        number: "15,000+",
        label: "Daily Meals Served",
        description: "Nutritious meals provided to children every school day"
      },
      %{
        number: "94%",
        label: "Attendance Improvement",
        description: "Average increase in school attendance among sponsored children"
      },
      %{
        number: "85%",
        label: "Academic Growth",
        description: "Students showing improved academic performance"
      },
      %{
        number: "100%",
        label: "Transparency",
        description: "Of donations directly support child nutrition"
      }
    ]

    success_stories = [
      %{
        name: "Maria's Story",
        location: "Manila",
        story: "From missing school twice a week to becoming top of her class, Maria's life changed dramatically once she started receiving regular meals.",
        stats: [
          %{label: "Attendance", before: "60%", after: "95%"},
          %{label: "Class Rank", before: "24th", after: "3rd"}
        ],
        image: "https://images.unsplash.com/photo-1596464716127-f2a82984de30?ixlib=rb-4.0.3&auto=format&fit=crop&w=1950&q=80"
      },
      %{
        name: "Ramon's Journey",
        location: "Cebu",
        story: "Ramon's concentration improved significantly after joining the feeding program, enabling him to focus better in class and improve his grades.",
        stats: [
          %{label: "Math Score", before: "72%", after: "89%"},
          %{label: "Energy Level", before: "Low", after: "High"}
        ],
        image: "https://images.unsplash.com/photo-1594608661623-aa0bd3a69d98?ixlib=rb-4.0.3&auto=format&fit=crop&w=1950&q=80"
      }
    ]

    annual_growth = [
      %{year: 2021, students: 500, schools: 3},
      %{year: 2022, students: 2000, schools: 8},
      %{year: 2023, students: 5000, schools: 15},
      %{year: 2024, students: 8000, schools: 25}
    ]

    {:ok, assign(socket,
      metrics: metrics,
      success_stories: success_stories,
      annual_growth: annual_growth
    )}
  end
end
