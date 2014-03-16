-module(echat).
-export([run/0]).

-define(PORT, 1337).

listener(Self) ->
  io:format("in listener~n"),
  {ok, Listen} = gen_tcp:listen(?PORT, [binary, {reuseaddr,true}]),
  Self!ready,
  gen_tcp:close(Listen),
  ok.

listen() ->
  Self = self(),
  io:format("in listen~n"),
  spawn(?MODULE, listener, [Self]),
  receive
    ready -> ok
  end,
  ok.

do_recv(Sock, Bs) ->
  case gen_tcp:recv(Sock, 0) of
    {ok, B} ->
      do_recv(Sock, [Bs, B]);
    {error, closed} ->
      {ok, list_to_binary(Bs)}
  end.

run() ->
  T0 = erlang:now(),
  io:format("starting ~p~n", [T0]),
  listen(),
  T1 = erlang:now(),
  io:format("started at ~p~n", [T1]),
  ok.
