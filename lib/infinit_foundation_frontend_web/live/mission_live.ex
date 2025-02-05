defmodule InfinitFoundationFrontendWeb.MissionLive do
  use InfinitFoundationFrontendWeb, :live_view

  # Simple placeholder avatars using data URIs
  @placeholder_avatars %{
    ceo: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U1ZTdlYiIvPjxjaXJjbGUgY3g9IjUwIiBjeT0iMzYiIHI9IjE4IiBmaWxsPSIjOWNhM2FmIi8+PHBhdGggZD0iTTI3IDcwQzI3IDU2IDM4IDQ4IDUwIDQ4czIzIDggMjMgMjJ2MTBIMjdWNzB6IiBmaWxsPSIjOWNhM2FmIi8+PC9zdmc+",
    coo: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U1ZTdlYiIvPjxjaXJjbGUgY3g9IjUwIiBjeT0iMzYiIHI9IjE4IiBmaWxsPSIjYjQ1MzA5Ii8+PHBhdGggZD0iTTI3IDcwQzI3IDU2IDM4IDQ4IDUwIDQ4czIzIDggMjMgMjJ2MTBIMjdWNzB6IiBmaWxsPSIjYjQ1MzA5Ii8+PC9zdmc+",
    director: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U1ZTdlYiIvPjxjaXJjbGUgY3g9IjUwIiBjeT0iMzYiIHI9IjE4IiBmaWxsPSIjMWYyOTM3Ii8+PHBhdGggZD0iTTI3IDcwQzI3IDU2IDM4IDQ4IDUwIDQ4czIzIDggMjMgMjJ2MTBIMjdWNzB6IiBmaWxsPSIjMWYyOTM3Ii8+PC9zdmc+"
  }

  @impl true
  def mount(_params, _session, socket) do
    values = [
      %{
        icon: "hero-heart-solid",
        title: "Child-Centric",
        description: "Every decision we make puts children's needs first. We believe every child deserves the opportunity to learn and grow without hunger."
      },
      %{
        icon: "hero-arrow-path-solid",
        title: "Sustainable Impact",
        description: "We create lasting change through nutrition programs that support both immediate needs and long-term educational success."
      },
      %{
        icon: "hero-eye-solid",
        title: "Transparency",
        description: "We maintain complete transparency in our operations, ensuring every donation is tracked and every meal is documented."
      },
      %{
        icon: "hero-users-solid",
        title: "Community Partnership",
        description: "We work closely with schools, local communities, and families to create sustainable feeding programs."
      }
    ]

    milestones = [
      %{
        year: "2023",
        title: "Feeding Program Established",
        description: "Started with a pilot program, feeding 25 children daily."
      },
      %{
        year: "2024",
        title: "Program Expansion",
        description: "Expanded to 250 children and implemented our digital tracking system."
      },
      %{
        year: "2025",
        title: "Technology Integration",
        description: "Launched our sponsor portal and real-time monitoring system."
      },
    ]

    {:ok, assign(socket,
      values: values,
      milestones: milestones
    )}
  end
end
