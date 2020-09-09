require Logger

defmodule Eactivitypub.RateLimiter do
  @moduledoc """
  A server can have many rate limiters.
  """
  use GenServer

  defmodule State do
    @moduledoc """
    Contains a struct and constants for rate limiter state.
    """
    @constants %{initial_left: 2, grace_seconds: 60}
    @enforce_keys [:ref]
    defstruct ref: nil, hits: @constants[:initial_left]

    @type t :: %__MODULE__{ref: String.t(), hits: non_neg_integer}
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
    ref_integer = :erlang.unique_integer()
    Base.encode64(:crypto.hash(:sha3_224, to_charlist(ref_integer)))
  end
end
