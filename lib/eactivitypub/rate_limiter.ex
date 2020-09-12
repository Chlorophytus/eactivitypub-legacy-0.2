require Logger

defmodule Eactivitypub.RateLimiter do
  @moduledoc """
  Rate limiter server, intended to be used on a one-per-client basis.
  """
  use GenServer
  @const_initial_left 2
  @const_reset_seconds 2
  @const_grace_seconds 60
  @const_grace_max 64

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
    @enforce_keys [:ref, :hits]
    defstruct ref: nil, hits: nil, grace: nil, started: nil, multiplier: 1

    @type t :: %__MODULE__{
            ref: binary,
            hits: non_neg_integer,
            grace: DateTime.t(),
            started: DateTime.t(),
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

  # === Internal Server Calls =================================================
  @impl true
  @spec init(any) :: {:ok, %State{}}
  def init(_) do
    ref64 = Base.encode64(:crypto.hash(:sha3_224, to_charlist(:erlang.unique_integer())))
    {:ok, %State{ref: ref64, hits: @const_initial_left, started: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:get_reference, _from, state) do
    {:reply, {:ok, state.ref}, state}
  end

  @impl true
  def handle_call({:try_decrement, destination}, _from, state) do
    cond do
      state.ref == destination ->
        unix_curr = DateTime.to_unix(DateTime.utc_now())

        case state.hits do
          0 ->
            # Calculate an offset from Unix time
            unix_time = DateTime.to_unix(state.grace) + state.multiplier

            cond do
              # We aren't being rate limited anymore.
              unix_time < unix_curr ->
                {:ok, next_grace} = DateTime.from_unix(unix_curr + @const_reset_seconds)

                {:reply,
                 {:ok,
                  %Reply{throttled: false, hits_left: @const_initial_left, wait: next_grace}},
                 %State{state | grace: next_grace, multiplier: 1, hits: @const_initial_left}}

              # We are still being rate limited.
              true ->
                next_grace_interval = grace_multiplier(state.multiplier)

                {:ok, next_grace} =
                  DateTime.from_unix(next_grace_interval * @const_grace_seconds + unix_curr)

                {:reply, {:ok, %Reply{throttled: true, hits_left: 0, wait: next_grace}},
                 %State{state | grace: next_grace, multiplier: next_grace_interval}}
            end

          _ ->
            {:ok, next_grace} = DateTime.from_unix(unix_curr + @const_reset_seconds)
            next_hits = state.hits - 1

            {:reply, {:ok, %Reply{throttled: false, hits_left: next_hits, wait: next_grace}},
             %State{state | grace: next_grace, multiplier: 1, hits: next_hits}}
        end

      true ->
        {:noreply, state}
    end
  end
end
