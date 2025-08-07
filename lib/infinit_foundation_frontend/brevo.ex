defmodule InfinitFoundationFrontend.Brevo do
  @api_host "https://api.brevo.com/v3"

  def upsert_contact(email, attributes \\ %{FIRSTNAME: "", LASTNAME: ""}, list_ids \\ []) do
    headers = [
      {"Content-Type", "application/json"},
      {"accept", "application/json"},
      {"api-key", get_api_key()}
    ]

    if email == "" or attributes[:FIRSTNAME] == "" or attributes[:LASTNAME] == "" do
      raise ArgumentError, "email, FIRSTNAME, and LASTNAME are required"
    end

    body =
      %{
        email: email,
        attributes: attributes,
        listIds: list_ids,
        updateEnabled: true
      }

    case Req.post(@api_host <> "/contacts", json: body, headers: headers) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %{status: 204, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def send_event(email, event, event_data)
      when is_binary(email) and is_binary(event) and is_map(event_data) do
    headers = [
      {"Content-Type", "application/json"},
      {"accept", "application/json"},
      {"api-key", get_api_key()}
    ]

    if email == "" or event == "" do
      raise {:error, "Email and event are required"}
    end

    body = %{
      event_name: event,
      event_properties: event_data,
      identifiers: %{
        email_id: email
      }
    }

    case(Req.post(@api_host <> "/events", json: body, headers: headers)) do
      {:ok, %{status: 204, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_contact(email, attributes \\ %{FIRSTNAME: "", LASTNAME: ""}, list_ids \\ []) do
    headers = [
      {"Content-Type", "application/json"},
      {"accept", "application/json"},
      {"api-key", get_api_key()}
    ]

    if email == "" or attributes[:FIRSTNAME] == "" or attributes[:LASTNAME] == "" do
      raise ArgumentError, "email, FIRSTNAME, and LASTNAME are required"
    end

    body =
      %{
        email: email,
        attributes: attributes,
        listIds: list_ids,
        updateEnabled: false
      }

    case Req.post(@api_host <> "/contacts", json: body, headers: headers) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defmodule To do
    @moduledoc """
    A struct representing a recipient of an email.
    """
    @derive {Jason.Encoder, only: [:email, :first_name, :last_name]}
    defstruct email: nil, first_name: nil, last_name: nil

    def new(email, first_name, last_name) do
      %__MODULE__{email: email, first_name: first_name, last_name: last_name}
    end
  end

  def registration_email!(to = %To{}, params),
    do: send_email_with_template!(to, :registration, params)

  def donation_thank_you_email!(to = %To{}, params),
    do: send_email_with_template!(to, :donation_thank_you, params)

  def weekly_updates_email!(to = %To{}, params),
    do: send_email_with_template!(to, :weekly_updates, params)

  def semester_updates_email!(to = %To{}, params),
    do: send_email_with_template!(to, :semester_updates, params)

  def pre_renewal_reminder_email!(to = %To{}, params),
    do: send_email_with_template!(to, :pre_renewal_reminder, params)

  def list_templates!() do
    request!(:list_templates, %{})
  end

  def list_templates_id_map!() do
    list_templates!()
    |> Map.get("templates")
    |> Enum.map(fn template -> {template["id"], template["name"]} end)
    |> Map.new()
  end

  @doc """
  Send an email with a Brevo template.
  Returns the message ID of the email.
  """
  def send_email_with_template!(to = %To{}, template, params) when is_atom(template) do
    ensure_contact_exists!(to)

    request!(:send_email_with_template, %{
      to: [%{email: to.email}],
      templateId: get_template_id!(template),
      params: params
    })
    |> Map.get("messageId")
  end

  defp ensure_contact_exists!(to = %To{}) do
    request!(:create_contact, %{
      email: to.email,
      attributes: %{
        FIRSTNAME: to.first_name,
        LASTNAME: to.last_name
      },
      updateEnabled: true
    })
  end

  defp get_template_id!(template) do
    Application.get_env(:infinit_foundation_frontend, :brevo_templates)[template] ||
      raise("Template #{template} not found")
  end

  defp get_path_and_method(:send_email_with_template), do: {"/smtp/email", :post}
  defp get_path_and_method(:list_templates), do: {"/smtp/templates", :get}
  defp get_path_and_method(:create_contact), do: {"/contacts", :post}

  defp get_api_key(),
    do:
      Application.get_env(:infinit_foundation_frontend, :brevo_api_key) ||
        raise("BREVO_API_KEY is not set")

  defp get_headers() do
    [
      {"api-key", get_api_key()},
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  defp request!(action, data) do
    {path, method} = get_path_and_method(action)
    headers = get_headers()

    {_req, res} =
      Req.new(method: method, url: @api_host <> path, headers: headers, json: data)
      |> Req.run!()

    case res do
      %{status: status, body: body} when status in [200, 201, 204] ->
        body

      _ ->
        raise "failed to request #{inspect(action)}: #{inspect(res.body)}"
    end
  end
end
