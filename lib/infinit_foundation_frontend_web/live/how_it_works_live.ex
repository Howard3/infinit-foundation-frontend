defmodule InfinitFoundationFrontendWeb.HowItWorksLive do
  use InfinitFoundationFrontendWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    steps = [
      %{
        icon: "hero-heart-solid",
        title: "Choose a Student",
        description: "Browse through profiles of students in need and select a child to sponsor. Each student needs only one sponsor, making your impact direct and meaningful."
      },
      %{
        icon: "hero-currency-dollar-solid",
        title: "Make a Commitment",
        description: "Sponsor a child for $200 per year. This covers their daily meals and vitamin supplements, ensuring they have the nutrition they need to focus on their education."
      },
      %{
        icon: "hero-academic-cap-solid",
        title: "Support Their Education",
        description: "Your sponsorship helps provide daily meals at school, encouraging attendance and improving academic performance."
      },
      %{
        icon: "hero-envelope-solid",
        title: "Stay Connected",
        description: "Receive updates about your sponsored child's progress, including their academic achievements and well-being reports."
      }
    ]

    commitments = [
      %{
        icon: "hero-cake-solid",
        title: "Daily Nutritious Meals",
        description: "Every sponsored child receives a balanced, nutritious meal each school day. Our meals are designed by nutritionists to support healthy growth and development."
      },
      %{
        icon: "hero-variable-solid",
        title: "Vitamin Supplementation",
        description: "Regular vitamin supplements are provided alongside meals to ensure complete nutritional support for optimal health and development."
      },
      %{
        icon: "hero-camera-solid",
        title: "Daily Photo Verification",
        description: "We document each feeding session with photos, providing sponsors with transparent proof that their supported child is receiving daily meals."
      },
      %{
        icon: "hero-chart-bar-solid",
        title: "Regular Health Monitoring",
        description: "Every semester, we track each child's BMI and overall health indicators to ensure our program is making a real difference."
      },
      %{
        icon: "hero-academic-cap-solid",
        title: "Academic Progress Tracking",
        description: "We work closely with schools to monitor attendance and academic performance, measuring the impact of proper nutrition on education."
      },
      %{
        icon: "hero-document-text-solid",
        title: "Regular Reports",
        description: "Sponsors receive regular updates on their child's health metrics, academic progress, and overall well-being."
      }
    ]

    {:ok, assign(socket,
      steps: steps,
      commitments: commitments
    )}
  end
end
