# InfinitFoundationFrontend

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

The application can be deployed to both staging and production environments on Fly.io.

### Available Commands

```bash
# Deploy to staging
mix fly.staging

# Deploy to production
mix fly.production

# Deploy to staging and monitor deployment status
mix fly.staging.monitor

# Deploy to production and monitor deployment status
mix fly.production.monitor
```

### Configuration Files

- `fly.staging.toml` - Configuration for staging environment (staging.infinit-o.foundation)
- `fly.production.toml` - Configuration for production environment (infinit-o.foundation)

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
