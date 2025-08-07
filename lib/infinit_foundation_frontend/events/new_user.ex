defmodule InfinitFoundationFrontend.Events.NewUser do
  @type t :: %__MODULE__{
          user_id: String.t(),
          email: String.t(),
          first_name: String.t(),
          last_name: String.t()
        }
  defstruct [:user_id, :email, :first_name, :last_name]

  def new(user_id, email, first_name, last_name) do
    %__MODULE__{user_id: user_id, email: email, first_name: first_name, last_name: last_name}
  end
end
