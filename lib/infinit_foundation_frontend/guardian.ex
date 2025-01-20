defmodule InfinitFoundationFrontend.Guardian do
  use Guardian, otp_app: :infinit_foundation_frontend

  def subject_for_token(%{"sub" => sub}, _claims) do
    {:ok, sub}
  end
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => sub} = claims) do
    # Here we could fetch more user details from your database if needed
    {:ok, claims}
  end
  def resource_from_claims(_), do: {:error, :invalid_claims}
end
