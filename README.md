# InfinitFoundationFrontend

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

The application can be deployed to both staging and production environments on Fly.io.

### Available Commands

### First Time Setup

Before using the console commands, you need to set up SSH access to your Fly.io applications:

```bash
# Set up SSH for Fly.io applications
fly ssh issue --agent
```

This command only needs to be run once per machine. It will:
- Create an SSH key pair for Fly.io
- Register it with your Fly.io account
- Configure your local SSH client

```bash
# Deploy to staging
mix fly.staging

# Deploy to production
mix fly.production

# Deploy to staging and monitor deployment status
mix fly.staging.monitor

# Deploy to production and monitor deployment status
mix fly.production.monitor

# Connect to staging IEx console
mix fly.staging.console

# Connect to production IEx console
mix fly.production.console
```

### Configuration Files

- `fly.staging.toml` - Configuration for staging environment (staging.infinit-o.foundation)
- `fly.production.toml` - Configuration for production environment (infinit-o.foundation)

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Brevo Templates
This project uses Brevo for sending emails. The templates are stored in Brevo and the IDs are stored in the database.

To list all Brevo templates and their IDs, in interactive IEx session, run:

```bash
InfinitFoundationFrontend.Brevo.list_templates_id_map!
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

When connected to the console, you'll get an interactive IEx session where you can:
- Inspect application state
- Execute code in the running application
- Debug issues in real-time
- Run database queries

Example console usage:
```elixir
# Get application version
iex> Application.spec(:infinit_foundation_frontend, :vsn)

# Check configuration
iex> Application.get_all_env(:infinit_foundation_frontend)
```
