# > Garbage-collected rate limiting service
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

defmodule Eactivitypub.RateLimiter do
  @moduledoc """
  Rate limiter server, intended to be used on a one-per-client basis.
  """
  use GenServer
  @const_initial_left 2
  @const_reset_seconds 2
  @const_grace_seconds 60
  @const_grace_max 256

  # 72 hours is enough for a rate limiter to keep alive
  @const_grace_gc 60 * 60 * 60 * 72

  @spec grace_multiplier(integer) :: integer
  @doc """
  Calculates a new grace multiplier given the previous one in the state.
  """
  def grace_multiplier(previous) when previous >= @const_grace_max do
    @const_grace_max
  end

  def grace_multiplier(previous), do: previous * 2

  defmodule State do
    @moduledoc """
    The rate limiter's internal server state struct.
    """
    @enforce_keys [:ref, :hits, :last]
    defstruct ref: nil, hits: nil, grace: nil, started: nil, last: nil, multiplier: 1

    @type t :: %__MODULE__{
            ref: binary,
            hits: non_neg_integer,
            grace: DateTime.t(),
            started: DateTime.t(),
            last: DateTime.t(),
            multiplier: non_neg_integer
          }
  end

  defmodule Reply do
    @moduledoc """
    The rate limiter server responds with this struct when it gets triggered.
    """
    @enforce_keys [:throttled, :hits_left, :wait]
    defstruct throttled: nil, hits_left: nil, wait: nil

    @type t :: %__MODULE__{
            throttled: boolean,
            hits_left: non_neg_integer,
            wait: DateTime.t()
          }
  end

  # === Conveniences ==========================================================
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Recommended way of starting a rate limiter.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @spec get_reference(atom | pid | {atom, any} | {:via, atom, any}) :: any
  @doc """
  Gets the reference of this rate limit server.
  """
  def get_reference(pid) do
    GenServer.call(pid, :get_reference)
  end

  @spec try_decrement(atom | pid | {atom, any} | {:via, atom, any}, binary) :: any
  @doc """
  Handles a single rate limit hit.

  A valid rate limit server should process this call if the `destination`
  itself points to a valid rate limiter.
  """
  def try_decrement(pid, destination) do
    GenServer.call(pid, {:try_decrement, destination})
  end

  @spec gc_sweep :: :abcast
  @doc """
  Performs a garbage collection sweep of every rate limiter.

  A rate limiter should only be garbage collected if older than a few days.
  """
  def gc_sweep do
    GenServer.abcast(__MODULE__, :gc_sweep)
  end

  # === Internal Server Calls =================================================
  @impl true
  @spec init(any) :: {:ok, %State{}}
  def init(_) do
    ref64 = Base.encode64(:crypto.hash(:sha3_224, to_charlist(:erlang.unique_integer())))

    {:ok,
     %State{
       ref: ref64,
       hits: @const_initial_left,
       started: DateTime.utc_now(),
       last: DateTime.utc_now()
     }}
  end

  @impl true
  def handle_cast(:gc_sweep, state) do
    gc_time = DateTime.add(state.last, @const_grace_gc)

    case DateTime.compare(DateTime.utc_now(), gc_time) do
      :gt ->
        # This state should be garbage collected now
        {:stop, :normal, state}

      _ ->
        # Keep going
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_reference, _from, state) do
    {:reply, {:ok, state.ref}, state}
  end

  @impl true
  def handle_call({:try_decrement, destination}, _from, state) do
    cond do
      state.ref == destination ->
        current_time = DateTime.utc_now()

        case state.hits do
          0 ->
            # Calculate an offset
            multiplier_offset = DateTime.add(state.grace, state.multiplier)

            case DateTime.compare(current_time, multiplier_offset) do
              :gt ->
                # We aren't being rate limited anymore.
                next_time = DateTime.add(current_time, @const_reset_seconds)

                {:reply,
                 {:ok, %Reply{throttled: false, hits_left: @const_initial_left, wait: next_time}},
                 %State{
                   state
                   | grace: next_time,
                     multiplier: 1,
                     hits: @const_initial_left,
                     last: current_time
                 }}

              _ ->
                # We are still being rate limited.
                next_interval = grace_multiplier(state.multiplier)
                next_time = DateTime.add(current_time, next_interval * @const_grace_seconds)

                {:reply, {:ok, %Reply{throttled: true, hits_left: 0, wait: next_time}},
                 %State{state | grace: next_time, multiplier: next_interval, last: current_time}}
            end

          _ ->
            next_time = DateTime.add(current_time, @const_reset_seconds)
            next_hits = state.hits - 1

            {:reply, {:ok, %Reply{throttled: false, hits_left: next_hits, wait: next_time}},
             %State{state | grace: next_time, multiplier: 1, hits: next_hits, last: current_time}}
        end

      true ->
        {:noreply, state}
    end
  end
end
