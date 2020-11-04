# > Garbage-collected rate limiting adaptor
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

# TODO: Should we, upon garbage collection, save to ETS? That'd be a good idea!

defmodule Eactivitypub.RateLimit do
  @moduledoc """
  Rate limiter behavior adaptor
  """
  @callback init_data(any) :: any
  def init_data(data), do: data
  defoverridable init_data: 1

  @callback handle_throttle(any, any) :: {:ok, any}
  def handle_throttle(data, _payload), do: {:ok, data}
  defoverridable handle_throttle: 2

  @callback handle_request(any, any) :: {:ok, any}
  def handle_request(data, _payload), do: {:ok, data}
  defoverridable handle_request: 2

  @callback handle_gc(any) :: :ok
  def handle_gc(_data), do: :ok
  defoverridable handle_gc: 1

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

  defmodule IConsts do
    @moduledoc """
    A rate limiter is configurable and will use these initialization constants.
    """
    @enforce_keys [:initial_left, :reset_seconds, :grace_seconds, :grace_max, :grace_gc]
    defstruct initial_left: nil,
              reset_seconds: nil,
              grace_seconds: nil,
              grace_max: nil,
              grace_gc: nil

    @type t :: %__MODULE__{
            grace_gc: pos_integer(),
            grace_max: pos_integer(),
            grace_seconds: pos_integer(),
            initial_left: pos_integer(),
            reset_seconds: pos_integer()
          }
  end

  defmodule State do
    @moduledoc """
    The rate limiter's internal server state struct.
    """
    @enforce_keys [:ref, :hits, :last, :iconsts]
    defstruct ref: nil,
              hits: nil,
              grace: nil,
              started: nil,
              last: nil,
              multiplier: 1,
              iconsts: nil,
              data: nil

    @type t :: %__MODULE__{
            ref: binary,
            hits: non_neg_integer,
            grace: DateTime.t(),
            started: DateTime.t(),
            last: DateTime.t(),
            multiplier: non_neg_integer,
            iconsts: IConsts.t(),
            data: nil
          }
  end

  defmacro __using__([]) do
    quote do
      use GenStage
      @behaviour Eactivitypub.RateLimit

      @spec grace_multiplier(non_neg_integer(), pos_integer()) :: non_neg_integer()
      def grace_multiplier(previous, iconst_grace_max) when previous >= iconst_grace_max do
        iconst_grace_max
      end

      def grace_multiplier(previous, _iconst_grace_max), do: previous * 2

      def start_link(opts) do
        GenStage.start_link(__MODULE__, opts)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      # === Internal Server Calls =================================================
      @impl true
      def init(%{iconsts: iconsts, data: data}) do
        ref64 = Base.encode64(:crypto.hash(:sha3_224, to_charlist(:erlang.unique_integer())))

        {:consumer,
         %State{
           ref: ref64,
           hits: iconsts.initial_left,
           started: DateTime.utc_now(),
           last: DateTime.utc_now(),
           iconsts: iconsts,
           data: __MODULE__.init_data(data)
         }}
      end

      @impl true
      def handle_cast(:gc_sweep, state) do
        gc_time = DateTime.add(state.last, state.iconsts.grace_gc)

        case DateTime.compare(DateTime.utc_now(), gc_time) do
          :gt ->
            # This state should be garbage collected now
            __MODULE__.handle_gc(state.data)

            {:stop, :normal, state}

          _ ->
            # Keep going
            {:noreply, state}
        end
      end

      @impl true
      def handle_call(:get_reference, _from, state) do
        {:reply, {:ok, state.ref}, [], state}
      end

      @impl true
      def handle_call({:try_decrement, destination, payload}, _from, state) do
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
                    next_time = DateTime.add(current_time, state.iconsts.reset_seconds)

                    __MODULE__.handle_request(state.data, payload)

                    {:reply,
                     {:ok,
                      %Reply{
                        throttled: false,
                        hits_left: state.iconsts.initial_left,
                        wait: next_time
                      }}, [],
                     %State{
                       state
                       | grace: next_time,
                         multiplier: 1,
                         hits: state.iconsts.initial_left,
                         last: current_time
                     }}

                  _ ->
                    # We are still being rate limited.
                    next_interval = grace_multiplier(state.multiplier, state.iconsts.grace_max)

                    next_time =
                      DateTime.add(current_time, next_interval * state.iconsts.grace_seconds)

                    __MODULE__.handle_throttle(state.data, payload)

                    {:reply, {:ok, %Reply{throttled: true, hits_left: 0, wait: next_time}}, [],
                     %State{
                       state
                       | grace: next_time,
                         multiplier: next_interval,
                         last: current_time
                     }}
                end

              _ ->
                next_time = DateTime.add(current_time, state.iconsts.reset_seconds)
                next_hits = state.hits - 1

                __MODULE__.handle_request(state.data, payload)

                {:reply, {:ok, %Reply{throttled: false, hits_left: next_hits, wait: next_time}},
                 [],
                 %State{
                   state
                   | grace: next_time,
                     multiplier: 1,
                     hits: next_hits,
                     last: current_time
                 }}
            end

          true ->
            {:noreply, [], state}
        end
      end

      @impl true
      def handle_events([], _from, state) do
        {:noreply, [], state}
      end
    end
  end

  # === Conveniences ==========================================================
  @spec get_reference(atom | pid | {atom, any} | {:via, atom, any}) :: any
  @doc """
  Gets the reference of this rate limit server.
  """
  def get_reference(pid) do
    GenStage.call(pid, :get_reference)
  end

  @spec try_decrement(atom | pid | {atom, any} | {:via, atom, any}, any, any) :: any
  @doc """
  Handles a single rate limit hit.

  A valid rate limit server should process this call if the `destination`
  itself points to a valid rate limiter.

  Payload is processed.
  """
  def try_decrement(pid, destination, payload) do
    GenStage.call(pid, {:try_decrement, destination, payload})
  end

  @spec gc_sweep :: :abcast
  @doc """
  Performs a garbage collection sweep of every rate limiter.

  A rate limiter should only be garbage collected if older than a few days.
  """
  def gc_sweep do
    GenServer.abcast(__MODULE__, :gc_sweep)
  end
end
