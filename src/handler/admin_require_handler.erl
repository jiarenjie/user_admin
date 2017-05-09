%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 五月 2017 16:43
%%%-------------------------------------------------------------------
-module(admin_require_handler).
-author("jiarj").

%% API
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

%%-record(state, {}).

init(_, Req, []) ->
  {Reply, Req2} = xfutils:only_allow(get, Req),
  {Reply, Req2, no_state}.

handle(Req, State) ->
ok

  .

terminate(_Reason, _Req, _State) ->
  ok.
