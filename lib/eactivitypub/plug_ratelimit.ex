# > Rate limiter for plug
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

defmodule Eactivitypub.Plug.RateLimit do
  use Eactivitypub.RateLimit

  @impl true
  def init_data(data) do
    Logger.info("Initialised: #{data}")
    data
  end

  @impl true
  def handle_throttle(data, %{:caller => caller}) do
    {:ok, data}
  end

  @impl true
  def handle_request(data, %{:caller => caller}) do
    send caller, {:error, :rate_limited}
    {:ok, data}
  end

  @impl true
  def handle_gc(_data) do
    :ok
  end
end
