require Logger

defmodule Eactivitypub do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Eactivitypub.Worker.start_link(arg)
      # {Eactivitypub.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Eactivitypub.PlugServer, options: [port: 8080]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Eactivitypub.Supervisor]
    Logger.info("=== start eactivitypub application ===")
    Application.ensure_all_started(:crypto)
    Supervisor.start_link(children, opts)
  end
end
