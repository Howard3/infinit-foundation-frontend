defmodule InfinitFoundationFrontendWeb.ClerkController do
  use InfinitFoundationFrontendWeb, :controller
  require Logger
  alias InfinitFoundationFrontend.Brevo
  alias InfinitFoundationFrontend.Events

  def webhook(conn, params) do
    Logger.info("Clerk webhook received: #{inspect(params)}")

    handle_event(conn, params["type"], params["data"])
  end

  def handle_event(conn, "user.created", data) do
    Logger.info("Clerk User created: #{inspect(data)}")

    email =
      data["email_addresses"]
      |> Enum.at(0)
      |> then(&(&1 && &1["email_address"]))

    Logger.info("Email address: #{email}")

    first_name = data["first_name"]
    last_name = data["last_name"]

    case Brevo.create_contact(email, %{FIRSTNAME: first_name, LASTNAME: last_name}) do
      {:ok, _} ->
        Logger.info("Contact created successfully")
        send_resp(conn, 200, "User created")

      {:error, error} ->
        Logger.error("Failed to create contact: #{inspect(error)}")
        send_resp(conn, 500, "Failed to create contact")
    end
  end

  def handle_event(conn, "user.updated", data) do
    Logger.info("Clerk User updated: #{inspect(data)}")

    email =
      data["email_addresses"]
      |> Enum.at(0)
      |> then(&(&1 && &1["email_address"]))

    Logger.info("Email address: #{email}")

    first_name = data["first_name"]
    last_name = data["last_name"]

    case Brevo.upsert_contact(email, %{FIRSTNAME: first_name, LASTNAME: last_name}) do
      {:ok, _} ->
        Logger.info("Contact updated successfully")
        send_resp(conn, 200, "User created")

      {:error, error} ->
        Logger.error("Failed to create contact: #{inspect(error)}")
        send_resp(conn, 500, "Failed to create contact")
    end
  end
end
