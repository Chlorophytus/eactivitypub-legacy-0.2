# > Supervisor for rate limits
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

defmodule Eactivitypub.Plug.RateLimit.Supervisor do
  @moduledoc """
  Rate limiter OTP supervisor. Sacrificial in that it'll terminate all of its
  children in the event that one child dies. This is justified. Just let it
  crash.
  """
  use Supervisor

  def start_link(scope, module) do
    Supervisor.start_link(__MODULE__, [scope, module], name: __MODULE__)
  end

  @impl true
  def init([scope, module]) do
    children = [
      {Eactivitypub.Plug.RateLimit.Server, [{self(), scope, module}]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
