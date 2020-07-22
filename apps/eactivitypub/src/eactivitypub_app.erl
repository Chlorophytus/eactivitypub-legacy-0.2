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
%% @doc eactivitypub public API
%% @end
%%%-------------------------------------------------------------------

-module(eactivitypub_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Grab certs
    {ok, InPlace} = application:get_env(ssl_in_place),
    {CrtFile, KeyFile} = ssl_get_keys(InPlace),
    % Start cowboy
    {ok, _} = application:ensure_all_started(cowboy),
    % Compile our routes
    Dispatch = cowboy_router:compile([{'_',
                                       [{"/.well-known/webfinger",
                                         eactivitypub_webfinger_handler,
                                         []}]}]),
    {ok, _} = cowboy:start_tls(eactivitypub_listener,
                               [{port, 8443},
                                {certfile, CrtFile},
                                {keyfile, KeyFile}],
                               #{env => #{dispatch => Dispatch}}),
    % Start the main supervisor
    eactivitypub_sup:start_link().

stop(_State) -> ok.

%% internal functions
ssl_get_keys(true) ->
    % Get the keys in place
    Priv = code:priv_dir(eactivitypub),
    {ok, Crt0} = application:get_env(ssl_crt),
    Crt1 = filename:join(Priv, Crt0),
    {ok, Key0} = application:get_env(ssl_key),
    Key1 = filename:join(Priv, Key0),
    {Crt1, Key1};
ssl_get_keys(false) ->
    % Get the keys based on the root dir
    {ok, Crt} = application:get_env(ssl_crt),
    {ok, Key} = application:get_env(ssl_key),
    {Crt, Key}.
