defmodule InfinitFoundationFrontendWeb.ImpactLive do
  use InfinitFoundationFrontendWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    metrics = [
      %{
        number: "250+",
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
        number: "75%",
        label: "Reduction in manourishment",
        description: "Reduction in manourishment among children"
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
      %{year: 2021, students: 20, schools: 1},
      %{year: 2022, students: 25, schools: 1},
      %{year: 2023, students: 30, schools: 1},
      %{year: 2024, students: 50, schools: 2},
      %{year: 2025, students: 250, schools: 2}
    ]

    {:ok, assign(socket,
      metrics: metrics,
      success_stories: success_stories,
      annual_growth: annual_growth
    )}
  end
end
