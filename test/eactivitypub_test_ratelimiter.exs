alias Eactivitypub.RateLimiter, as: RateLimiter
require Logger

defmodule EactivitypubTestRatelimiter do
  use ExUnit.Case, async: true
  doctest Eactivitypub.RateLimiter

  setup do
    rate_limiter = start_supervised!(RateLimiter)
    %{rate_limiter: rate_limiter}
  end

  test "rate limits properly", %{rate_limiter: rate_limiter} do
    {:ok, ref} = RateLimiter.get_reference(rate_limiter)
    Logger.debug("testing with mock #{ref}")
    RateLimiter.try_decrement(rate_limiter, ref)
    RateLimiter.try_decrement(rate_limiter, ref)
    RateLimiter.try_decrement(rate_limiter, ref)
    {:ok, response} = RateLimiter.try_decrement(rate_limiter, ref)
    assert response.throttled
  end

  test "rate limits faithfully", %{rate_limiter: rate_limiter} do
    {:ok, ref} = RateLimiter.get_reference(rate_limiter)
    Logger.debug("testing with mock #{ref}")
    {:ok, response} = RateLimiter.try_decrement(rate_limiter, ref)
    assert !response.throttled

    :timer.sleep(3000)
    {:ok, response} = RateLimiter.try_decrement(rate_limiter, ref)
    assert !response.throttled
  end
end
