# > Server for rate limits
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

defmodule Eactivitypub.Plug.RateLimit.Server do
  @moduledoc """
  Rate limiter server. Each will have a scope of what to rate limit.
  """
  use GenStage

  defmodule Subscope do
    @moduledoc """
    Defines a subscope, a user IP address and an atom representing what resource to access.
    """
    @enforce_keys [:ip_addr]
    defstruct ip_addr: nil, resource: :root
    @type t :: %__MODULE__{ip_addr: :inet.ip_address(), resource: atom}
  end

  defmodule State do
    @moduledoc """
    The server will store this state for itself, including iconsts to dispatch
    to consumers.
    """
    @enforce_keys [:module, :scope, :supervisor_pid]
    defstruct module: nil, scope: nil, clients: %{}, supervisor_pid: nil

    @type t :: %__MODULE__{
            module: module,
            scope: any,
            clients: %{Subscope.t() => pid},
            supervisor_pid: pid
          }
  end

  # === Internal Server Calls =================================================
  @impl true
  def init({supervisor, scope, module}) do
    {:producer_consumer, %State{supervisor_pid: supervisor, scope: scope, module: module}}
  end

  @impl true
  def handle_call({:get_client, subscope}, _from, state) do
    case state.clients[subscope] do
      nil ->
        {:ok, pid} = Supervisor.start_child(state.supervisor_pid, {state.module, subscope})
        {:reply, {:ok, pid}, [], state}

      pid ->
        {:reply, {:ok, pid}, [], state}
    end
  end

  # === Conveniences ==========================================================
  @spec get_client(atom | pid | {atom, any} | {:via, atom, any}, Subscope.t()) ::
          {:ok, pid}
  def get_client(pid, subscope) do
    GenStage.call(pid, {:get_client, subscope})
  end

  def handle_client(pid, subscope, payload) do
    GenStage.call(pid, {:handle_client, subscope, payload})
  end
end
