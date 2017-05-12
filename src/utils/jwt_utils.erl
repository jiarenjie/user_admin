%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 五月 2017 10:29
%%%-------------------------------------------------------------------
-module(jwt_utils).
-author("jiarj").

%% API
-export([decode/2, encode/2]).


decode(JWT,Key) ->
  try
    Decode=ejwt:decode(JWT, Key),
    {ok,Decode}
  catch
      _:X  ->
        {fail,X}
  end.

encode(Payload, Key)->
  try
    JTW=ejwt:encode(Payload,Key),
    {ok,JTW}
  catch
    _:X  ->
      {fail,X}
  end.


