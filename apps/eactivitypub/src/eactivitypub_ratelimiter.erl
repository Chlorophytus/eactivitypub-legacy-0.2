%%% Copyright 2020 Roland Metivier
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%-------------------------------------------------------------------
%% @doc eactivitypub modular rate limiter
%% > A server can have many rate limiters
%% @end
%%%-------------------------------------------------------------------

-module(eactivitypub_ratelimiter).

-behaviour(gen_statem).

-export([start_link/1]).

-export([callback_mode/0, init/1]).

-export([ready/3, throttled/3]).

-include("eactivitypub.hrl").

-define(SERVER, ?MODULE).

callback_mode() -> state_functions.

start_link(Address) ->
    gen_statem:start_link({local, {?SERVER, Address}},
                          ?MODULE,
                          [],
                          []).

init([]) ->
    Nonce =
        binary:encode_unsigned(erlang:unique_integer([positive])),
    Bucket = base64:encode(crypto:hash(sha3_224, Nonce)),
    Data = #{bucket => Bucket,
             limit_left => ?RATELIMIT_LIMIT,
             limit_reset =>
                 {os:system_time(seconds), ?RATELIMIT_RESET, 0}},
    {ok,
     ready,
     Data,
     [{{timeout, expire}, ?RATELIMIT_EXPIRE, []}]}.

ready({call, From}, rate, #{limit_left := L} = Data)
    when L > 0 ->
    NewData = calc_sane_data(Data),
    {keep_state,
     NewData,
     [{reply, From, {ok, NewData}},
      {{timeout, expire}, update, ?RATELIMIT_EXPIRE},
      {state_timeout, update, (?RATELIMIT_RESET) * 1000}]};
ready({call, From}, rate, Data) ->
    NewData = calc_sane_data(Data),
    {next_state,
     throttled,
     NewData,
     [{reply, From, {ok, NewData}},
      {{timeout, expire}, update, ?RATELIMIT_EXPIRE},
      {state_timeout, update, (?RATELIMIT_RESET) * 1000}]};
ready(state_timeout, _EventContent, Data) ->
    NewData = Data#{limit_left := ?RATELIMIT_LIMIT},
    {keep_state,
     NewData,
     [{{timeout, expire}, update, ?RATELIMIT_EXPIRE}]};
ready({timeout, expire}, _EventContent, _Data) -> stop.

throttled({call, From}, rate, Data) ->
    NewData = calc_throttle_data(Data),
    {keep_state,
     NewData,
     [{reply, From, {throttled, NewData}},
      {{timeout, expire}, update, ?RATELIMIT_EXPIRE},
      {state_timeout,
       update,
       (?RATELIMIT_RESET_HARD) * 1000}]};
throttled(state_timeout, _EventContent, Data) ->
    NewData = Data#{limit_left := ?RATELIMIT_LIMIT},
    {next_state,
     ready,
     NewData,
     [{{timeout, expire}, update, ?RATELIMIT_EXPIRE}]};
throttled({timeout, expire}, _EventContent, _Data) ->
    stop.

%% Data should not throttle.
calc_sane_data(Data) ->
    Data#{limit_reset :=
              (?RATELIMIT_RESET) + os:system_time(seconds)}.

%% Data should throttle.
calc_throttle_data(Data) ->
    Data#{limit_reset :=
              (?RATELIMIT_RESET_HARD) + os:system_time(seconds)}.
