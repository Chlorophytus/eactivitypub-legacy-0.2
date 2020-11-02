# > Run tests on the rate limiter
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
alias Eactivitypub.RateLimit, as: RateLimit
alias Eactivitypub.GoatRateLimit, as: GoatRateLimit
require Logger

defmodule EactivitypubTestRatelimit do
  use ExUnit.Case
  doctest Eactivitypub.RateLimit

  setup do
    rate_limit =
      start_supervised!({
        GoatRateLimit,
        # Do note that we initialize constants now.
        %{
          iconsts: %RateLimit.IConsts{
            initial_left: 2,
            reset_seconds: 2,
            grace_seconds: 60,
            grace_max: 256,
            grace_gc: 60 * 60 * 60 * 72
          },
          data: nil
        }
      })

    %{rate_limit: rate_limit}
  end

  # Test for a rate limiter hit.
  test "rate limits properly", %{rate_limit: rate_limit} do
    {:ok, ref} = RateLimit.get_reference(rate_limit)
    Logger.debug("testing with mock #{ref}")
    RateLimit.try_decrement(rate_limit, ref, :dont_care)
    RateLimit.try_decrement(rate_limit, ref, :dont_care)
    RateLimit.try_decrement(rate_limit, ref, :dont_care)
    {:ok, response} = RateLimit.try_decrement(rate_limit, ref, :dont_care)
    assert response.throttled
  end

  # Test if a rate limiter releases its hit.
  test "rate limits faithfully", %{rate_limit: rate_limit} do
    {:ok, ref} = RateLimit.get_reference(rate_limit)
    Logger.debug("testing with mock #{ref}")
    {:ok, response} = RateLimit.try_decrement(rate_limit, ref, :dont_care)
    assert !response.throttled

    :timer.sleep(3000)
    {:ok, response} = RateLimit.try_decrement(rate_limit, ref, :dont_care)
    assert !response.throttled
  end

  # TODO: Test garbage collection
end
