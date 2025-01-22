defmodule InfinitFoundationFrontendWeb.ViewHelper do
  @doc """
  Formats a student's name for public display by showing the first name and first initial of last name.
  Example: "John Smith" becomes "John S."
  """
  def format_student_name(first_name, last_name) when is_binary(first_name) and is_binary(last_name) do
    "#{first_name} #{String.slice(last_name, 0, 1)}."
  end

  def format_student_name(_, _), do: "Unknown Student"
end
