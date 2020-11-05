# > Handles a timeline
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

defmodule Eactivitypub.Stages.Timeline do
  use GenStage

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  # === STAGE IMPLEMENTATION ==================================================
  @impl true
  def init(_) do
    # Test timeline until I can hack something with DETS
    {:producer,
     %{
       :events => [],
       :rx_demand => 0,
       :timeline => []
     }}
  end

  @impl true
  def handle_demand(demand, state) do
    dispatch_events(%{state | :rx_demand => state[:rx_demand] + demand})
  end

  @impl true
  def handle_cast({:post, content}, state) do
    {:noreply, state[:events], %{state | :timeline => [content | state[:timeline]]}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state[:timeline], state[:events], state}
  end
  # === EVENT DISPATCH ========================================================
  defp dispatch_events(%{:rx_demand => rx_demand} = state) do
    {:ok, new_state} = fetch_events(state, rx_demand)
    {:noreply, new_state[:events], new_state}
  end

  defp fetch_events(state, 0) do
    {:ok, state}
  end

  ## CRITICAL POINT FOR DETS IMPLEMENTATION
  defp fetch_events(state, rx_demand) do
    new_demand = rx_demand - 1

    fetch_events(
      %{state | :events => [state[:timeline] | state[:events]], :rx_demand => new_demand},
      new_demand
    )
  end

  # === STAGE CALLBACKS =======================================================
  @spec post(any) :: :ok
  def post(content) do
    GenServer.cast(__MODULE__, {:post, content})
  end
end
