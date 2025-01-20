defmodule InfinitFoundationFrontendWeb.SponsorLive.Index do
  use InfinitFoundationFrontendWeb, :live_view
  alias InfinitFoundationFrontend.ApiClient
  alias InfinitFoundationFrontend.Config.Sponsorship

  @impl true
  def mount(%{"id" => student_id} = params, session, socket) do
    socket = assign(socket, :user_id, session["user_id"])

    # Verify the lock is still valid
    case InfinitFoundationFrontend.SponsorshipLocks.extend_lock(student_id, socket.assigns.user_id) do
      :ok ->
        # Start the periodic lock extension
        Process.send_after(self(), :extend_lock, :timer.minutes(5))

        # Get student details
        student = ApiClient.get_student(student_id)
        sponsorship = Sponsorship.sponsorship_details()

        {:ok,
         assign(socket,
           student: student,
           sponsorship: sponsorship,
           page_title: "Complete Sponsorship"
         )}

      {:error, :not_lock_holder} ->
        {:ok,
         socket
         |> put_flash(:error, "Your sponsorship session has expired. Please try again.")
         |> push_navigate(to: ~p"/students")}
    end
  end

  @impl true
  def handle_info(:extend_lock, socket) do
    if student = socket.assigns[:student] do
      holder_id = socket.assigns.user_id
      InfinitFoundationFrontend.SponsorshipLocks.extend_lock(student.id, holder_id)
      Process.send_after(self(), :extend_lock, :timer.minutes(5))
    end

    {:noreply, socket}
  end
end
