require Logger

defmodule Eactivitypub.RateLimiter do
  @moduledoc """
  An eactivitypub instance can have many rate limiters.
  """
  use GenServer

  defmodule State do
    @moduledoc """
    Contains a struct and constants for rate limiter state.
    """
    @constants %{initial_left: 2, grace_seconds: 60, grace_multiplier: 2, grace_max: 6}
    @enforce_keys [:ref]
    defstruct ref: nil, hits: @constants[:initial_left], multiplier: 0

    @type t :: %__MODULE__{ref: String.t(), hits: non_neg_integer, multiplier: non_neg_integer}
  end

  @impl true
  @spec init(any) :: {:ok, State.t()}
  def init(_) do
    {:ok, %State{ref: reference64()}}
  end

  @spec reference64() :: binary
  @doc """
  Generates a Base64 variant of a SHA3-224 hashed Erlang unique integer.
  This is used for identifying rate limiters.
  """
  def reference64() do
    Base.encode64(:crypto.hash(:sha3_224, to_charlist(:erlang.unique_integer())))
  end

  @impl true
  def handle_call({:try_decrement, destination}, from, state) do
    cond do
      state[:ref] === destination ->
        case state[:hits] do
          # TODO: add in the actual logic with DateTime
          0 -> {:reply, :rate_limited}
          _ -> :unimplemented
        end

      true ->
        :unimplemented
    end
  end
end
