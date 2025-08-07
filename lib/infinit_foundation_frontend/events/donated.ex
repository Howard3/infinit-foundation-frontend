defmodule InfinitFoundationFrontend.Events.Donated do
  @type t :: %__MODULE__{
          user_id: String.t(),
          child_id: String.t(),
          child_name: String.t(),
          amount: Decimal.t(),
          currency: String.t()
        }
  defstruct [:user_id, :child_id, :child_name, :amount, :currency]

  def new(user_id, child_id, child_name, amount, currency) do
    %__MODULE__{
      user_id: user_id,
      child_id: child_id,
      child_name: child_name,
      amount: amount,
      currency: currency
    }
  end
end
