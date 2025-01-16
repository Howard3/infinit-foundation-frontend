defmodule InfinitFoundationFrontend.Schemas do
  defmodule Location do
    @type t :: %__MODULE__{
      country: String.t(),
      cities: [String.t()]
    }
    defstruct [:country, :cities]
  end

  defmodule Student do
    @type t :: %__MODULE__{
      id: integer(),
      first_name: String.t(),
      last_name: String.t(),
      profile_photo_url: String.t() | nil,
      school_id: integer(),
      # Add other fields as needed
    }
    defstruct [:id, :first_name, :last_name, :profile_photo_url, :school_id]
  end

  defmodule PaginatedStudents do
    @type t :: %__MODULE__{
      students: [Student.t()],
      total: integer()
    }
    defstruct [:students, :total]
  end
end
