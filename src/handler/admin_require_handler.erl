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
  {StatusCode,Req3, ReplyBody}=porcess(Req),
  {ok, Req2} = cowboy_req:reply(StatusCode, [{<<"content-type">>, <<"text/html">>}], ReplyBody, Req3),
  {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
  ok.


porcess(Req) ->
  {JWT, _} = cowboy_req:header(<<"authorization">>, Req),
  Pipeline = [
    {check_jwt, fun fun_check_jwt/1}
    ,{update_userinfo,fun fun_update_userinfo/1}
    ,{reply_jwt,fun fun_reply_jwt/1}
  ],

  F = fun
        ({OpName, Handler}, Acc) when is_atom(OpName), is_function(Handler) ->
          lager:debug(" === in ~p,Acc=~p", [OpName, Acc]),
          AccNew = Handler(Acc),
          lager:debug("AccNew=~p", [AccNew]),
          AccNew
      end,

  Resp = try
           JWT = lists:foldl(F, JWT, Pipeline),
           Req2 = cowboy_req:set_resp_header(<<"authorization">>,JWT,Req),
           {200,Req2,<<"admin_require">> }

         catch
           throw:{Atom, RespCd, RespMsg}
             ->
             %% fail @ validate/create_req_model
%%             xfutils:post_vals_to_iolist([{resp_code, RespCd}, {resp_msg, RespMsg}]);
             lager:error("txn process error = ~p,RespCode = ~p,RespMsg = ~ts", [Atom, RespCd, RespMsg]),
             {ok,BodyFail} = fun_render_fail_resp_model(wechat_process_callback, RespCd, RespMsg),
             {200, Req ,BodyFail}
         end,
  Resp.


fun_render_fail_resp_model(M, RespCd, RespMsg) when is_atom(M), is_binary(RespCd), is_binary(RespMsg) ->
  try
    render_fail_resp_model(RespCd, RespMsg)
  catch
    _ :X ->
      lager:error("Error = ~p,stack = ~p", [X, erlang:get_stacktrace()]),
      throw({render_fail_resp_model, <<"99">>, <<"生成应答报文错误"/utf8>>})
  end.

render_fail_resp_model(RespCd, RespMsg) when is_binary(RespCd), is_binary(RespMsg) ->
  ErrorVals = [{error_code, RespCd}, {error_msg, RespMsg}],
  ua_error_req_dtl:render(ErrorVals).

fun_check_jwt(JWT) ->
  case check_jwt(JWT) of
    {fail,Errornum,Errormsg}->
      throw({jwt_error, Errornum, Errormsg});
    {ok,payload,Payload}->
      Payload
end.

check_jwt(JWT) ->
  case JWT of
    undefined->
      {fail,<<"99">>,<<"JWT不存在"/utf8>>};
    _->
      JWT2 = jwt_utils:decode(JWT,<<"secret">>),
      case JWT2 of
        {fail,_} ->
          {fail,<<"99">>,<<"JWT验证失败"/utf8>>};
        {ok,Payload}->
          {ok,payload,Payload}
      end
  end.

fun_update_userinfo(Payload) ->
  try
    update_userinfo(Payload)
  catch
      _:X  ->
        throw({update_userinfo, <<"98">>, <<"数据更新失败/utf8">>})
  end.


update_userinfo(Payload) ->
  OPENID =proplists:get_value(<<"openid">>, Payload),
  ok=gws_mnesia:save_update(repo_user,[{<<"openid">>,OPENID},{<<"info">>,<<"admin_require">>}]),
  Payload.


fun_reply_jwt(Payload) ->
  try
    reply_jwt(Payload)
  catch
    _:X  ->
      throw({reply_jwt, <<"98">>, <<"生成jwt失败/utf8">>})
  end.

reply_jwt(Payload) ->
  Timestamp=erlang:system_time(seconds),
  %%生成jwt
  Payload2 = [
    {<<"openid">>,proplists:get_value(<<"openid">>, Payload)}
    ,{<<"nickname">>,proplists:get_value(<<"nickname">>, Payload)}
    ,{<<"role">>,proplists:get_value(<<"role">>, Payload)}
    ,{<<"timestamp">>,Timestamp}
  ],
  {ok,JWT} = jwt_utils:encode(Payload2, <<"secret">>),
  lager:debug("~n JWT = ~p~n", [JWT]),
  JWT.