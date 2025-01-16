defmodule InfinitFoundationFrontendWeb.StudentLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient

  @sponsorship_amount 250 # USD

  @impl true
  def mount(_params, _session, socket) do
    # Fetch students from the API
    %{"students" => students, "total" => total} = ApiClient.list_students(%{page: 1, limit: 10})

    # Transform the API response to match our expected format
    students = Enum.map(students, fn student ->
      %{
        id: student["id"],
        name: "#{student["firstName"]} #{student["lastName"]}",
        # You might want to fetch these additional fields from the API
        age: 8,
        grade: "Grade 2",
        school: "School #{student["schoolId"]}",
        location: "Manila",
        story: "Student story...",
        sponsored: false,
        image_url: student["profilePhotoUrl"] && ApiClient.photo_url(student["profilePhotoUrl"])
      }
    end)

    {:ok, assign(socket, students: students, total: total, sponsorship_amount: @sponsorship_amount)}
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
