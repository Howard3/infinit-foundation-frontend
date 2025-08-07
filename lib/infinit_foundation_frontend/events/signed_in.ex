defmodule InfinitFoundationFrontend.Events.SignedIn do
  @type t :: %__MODULE__{
          user_id: String.t(),
        }
  defstruct [:user_id]

  def new(user_id) do
    %__MODULE__{user_id: user_id}
  end
end
