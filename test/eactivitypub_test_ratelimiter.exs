require Logger

defmodule EactivitypubTestRatelimiter do
  use ExUnit.Case, async: true
  doctest Eactivitypub.RateLimiter

  setup do
    rate_limiter = start_supervised!(Eactivitypub.RateLimiter)
    %{rate_limiter: rate_limiter}
  end

  test "rate limits properly", %{rate_limiter: rate_limiter} do
    {:ok, ref} = GenServer.call(rate_limiter, :get_reference)
    Logger.debug("testing with mock #{ref}")
    GenServer.call(rate_limiter, {:try_decrement, ref})
    GenServer.call(rate_limiter, {:try_decrement, ref})
    GenServer.call(rate_limiter, {:try_decrement, ref})
    {:ok, response} = GenServer.call(rate_limiter, {:try_decrement, ref})
    assert response.throttled
  end

  test "rate limits faithfully", %{rate_limiter: rate_limiter} do
    {:ok, ref} = GenServer.call(rate_limiter, :get_reference)
    Logger.debug("testing with mock #{ref}")
    {:ok, response} = GenServer.call(rate_limiter, {:try_decrement, ref})
    assert !response.throttled

    :timer.sleep(3000)
    {:ok, response} = GenServer.call(rate_limiter, {:try_decrement, ref})
    assert !response.throttled
  end
end
