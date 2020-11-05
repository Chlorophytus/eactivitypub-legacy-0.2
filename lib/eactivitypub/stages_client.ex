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
alias Eactivitypub.Stages.Timeline, as: Timeline

defmodule Eactivitypub.Stages.Client do
  def start_link(opts) do
    Task.start_link(__MODULE__, :init, opts)
  end
  def init() do
    Timeline.post("Hello world! #{DateTime.utc_now()}")
    Stream.timer(10000)
    Timeline.post("Byebye world! #{DateTime.utc_now()}")
  end
end
