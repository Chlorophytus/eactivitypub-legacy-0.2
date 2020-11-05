# > Stages server for plug
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

defmodule Eactivitypub.Stages.Server do
  use ConsumerSupervisor

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    ConsumerSupervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init([]) do
    ConsumerSupervisor.init(
      [
        %{
          id: Eactivitypub.Stages.Client,
          start: {Eactivitypub.Stages.Client, :start_link, []},
          restart: :temporary
        }
      ],
      subscribe_to: [{Eactivitypub.Stages.Timeline, max_demand: 1}],
      strategy: :one_for_one
    )
  end


  @spec get() :: any
  def get() do
    GenServer.call(__MODULE__, :get, 500)
  end
end
