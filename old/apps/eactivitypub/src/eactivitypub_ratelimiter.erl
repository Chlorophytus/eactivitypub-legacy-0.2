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
%% > A server can have many rate limiters.
%% @end
%%%-------------------------------------------------------------------

-module(eactivitypub_ratelimiter).

-behaviour(gen_server).

-export([start_link/0]).

-export([init/1]).

-export([handle_call/3, handle_cast/2]).

-include("eactivitypub.hrl").

-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER},
                          ?MODULE,
                          [],
                          []).

init([]) ->
    {ok, #{}}.

handle_call(_Event, _From, _State) ->
    unimplemented.

handle_cast(_Event, _State) ->
    unimplemented.    