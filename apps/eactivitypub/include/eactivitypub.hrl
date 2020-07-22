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
%% @doc eactivitypub constants and records
%% @end
%%%-------------------------------------------------------------------

%% When does the rate limit reset, in seconds?
-define(RATELIMIT_RESET, 1).
-define(RATELIMIT_RESET_HARD, 60).

%% How many ops until a rate limit is hit?
-define(RATELIMIT_LIMIT, 2).

%% When do we delete the rate limit bucket, in milliseconds?
-define(RATELIMIT_EXPIRE, 60000 * 60 * 24 * 7).