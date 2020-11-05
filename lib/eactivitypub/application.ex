# > Main Elixir strap endpoint
# Copyright 2020 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require Logger

defmodule Eactivitypub do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Eactivitypub.Worker.start_link(arg)
      # {Eactivitypub.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Eactivitypub.Plug, options: [port: 8080]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Eactivitypub.Supervisor]
    Logger.info("=== start eactivitypub application ===")
    Application.ensure_all_started(:crypto)
    Eactivitypub.Stages.Server.start_link([])
    Eactivitypub.Stages.Timeline.start_link([])
    Supervisor.start_link(children, opts)
  end
end
