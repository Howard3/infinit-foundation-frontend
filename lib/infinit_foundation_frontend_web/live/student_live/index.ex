defmodule InfinitFoundationFrontendWeb.StudentLive.Index do
  use InfinitFoundationFrontendWeb, :live_view

  @sponsorship_amount 250 # USD

  @impl true
  def mount(_params, _session, socket) do
    # This would eventually come from your database
    students = [
      %{
        id: 1,
        name: "Maria Santos",
        age: 8,
        grade: "Grade 2",
        school: "San Pedro Elementary School",
        location: "Manila",
        story: "Maria loves mathematics and dreams of becoming a teacher. She walks 2km to school every day and helps her mother sell vegetables on weekends.",
        sponsored: false,
        image_url: "https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=300"
      },
      %{
        id: 2,
        name: "Juan Cruz",
        age: 10,
        grade: "Grade 4",
        school: "Makati Elementary School",
        location: "Makati",
        story: "Juan excels in science and wants to be a doctor to help his community. He currently ranks first in his class despite often missing meals.",
        sponsored: true,
        image_url: "https://images.unsplash.com/photo-1545558014-8692077e9b5c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=300"
      }
    ]

    {:ok, assign(socket, students: students, sponsorship_amount: @sponsorship_amount)}
  end

  @impl true
  def handle_event("sponsor", %{"id" => id}, socket) do
    # This would eventually handle the sponsorship process
    # For now, just show what we'd do
    student_id = String.to_integer(id)
    students = Enum.map(socket.assigns.students, fn student ->
      if student.id == student_id do
        %{student | sponsored: true}
      else
        student
      end
    end)

    {:noreply, assign(socket, :students, students)}
  end
end
