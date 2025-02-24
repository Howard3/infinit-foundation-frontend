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
      school_id: String.t(),
      date_of_birth: String.t() | nil,
      grade: String.t() | nil
    }
    defstruct [:id, :first_name, :last_name, :profile_photo_url, :school_id, :date_of_birth, :grade]
  end

  defmodule PaginatedStudents do
    @type t :: %__MODULE__{
      students: [Student.t()],
      total: integer()
    }
    defstruct [:students, :total]
  end

  defmodule School do
    @type t :: %__MODULE__{
      id: String.t(),
      name: String.t(),
      city: String.t(),
      country: String.t()
    }
    defstruct [:id, :name, :city, :country]
  end

  defmodule StudentFilter do
    @moduledoc """
    Struct for filtering students in the list_students API.

    Fields:
    - page: Page number (default: 1)
    - limit: Items per page (default: from config)
    - active: Filter active students only (default: true)
    - eligible_for_sponsorship: Filter eligible students (default: true)
    - min_age: Minimum age filter (optional)
    - max_age: Maximum age filter (optional)
    - country: Filter by country (optional)
    - city: Filter by city (optional)
    """

    defstruct [
      :min_age,
      :max_age,
      :country,
      :city,
      page: 1,
      limit: nil,
      active: true,
      eligible_for_sponsorship: true
    ]

    @type t :: %__MODULE__{
      page: pos_integer(),
      limit: pos_integer() | nil,
      active: boolean(),
      eligible_for_sponsorship: boolean(),
      min_age: pos_integer() | nil,
      max_age: pos_integer() | nil,
      country: String.t() | nil,
      city: String.t() | nil
    }
  end

  defmodule Sponsorship do
    @moduledoc """
    Schema representing a sponsorship record linking a sponsor to a student.
    """

    @type t :: %__MODULE__{
      student_id: String.t(),
      start_date: Date.t(),
      end_date: Date.t()
    }

    defstruct [:student_id, :start_date, :end_date]
  end

  defmodule SponsorEvent do
    @type t :: %__MODULE__{
      student_id: String.t(),
      student_name: String.t(),
      feeding_time: NaiveDateTime.t(),
      school_id: String.t(),
      event_type: String.t(),
      feeding_image_id: String.t()
    }

    defstruct [:student_id, :student_name, :feeding_time, :school_id, :event_type, :feeding_image_id]
  end
end
