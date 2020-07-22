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
%% @doc eactivitypub webfinger handler
%% > Handles the WebFinger (RFC7033) endpoint, at $ROOT/.well-known/webfinger
%% @end
%%%-------------------------------------------------------------------

-module(eactivitypub_webfinger_handler).

-export([init/2]).

-export([options/2]).

-export([allowed_methods/2, known_methods/2]).

init(Req, State) -> {cowboy_rest, Req, State}.

options(Req0, State) ->
    Req1 =
        cowboy_req:set_resp_header(<<"access-control-allow-methods">>,
                                   <<"GET, OPTIONS">>,
                                   Req0),
    {ok, ThisHost} = application:get_env(this_host),
    Req2 =
        cowboy_req:set_resp_header(<<"access-control-allow-origin">>,
                                   list_to_binary(ThisHost),
                                   Req1),
    Req3 =
        cowboy_req:set_resp_header(<<"access-control-allow-headers">>,
                                   <<"*">>,
                                   Req2),
    {ok, Req3, State}.

allowed_methods(Req, State) ->
    {[<<"GET">>, <<"OPTIONS">>], Req, State}.

known_methods(Req, State) ->
    {[<<"GET">>, <<"OPTIONS">>], Req, State}.
