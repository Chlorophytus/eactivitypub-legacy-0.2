# > Run tests on the Rate Limiter
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
