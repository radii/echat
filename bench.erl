-module(bench).
-compile(export_all).

-define(COUNT, 1000).
-define(SIZE, 10000).
-define(PORT, 9001).

read_all(Socket, Limit) when Limit > 0 -> 
  case gen_tcp:recv(Socket, 100*?SIZE) of
    {ok, Bin} ->
      read_all(Socket, Limit - size(Bin));
    {error, Error} ->
      {error, {Error, Limit}}
  end;

read_all(Socket, 0) ->
  gen_tcp:close(Socket),
  ok.

listener(Self) ->
  {ok, Listen} = gen_tcp:listen(?PORT, [binary, {reuseaddr,true}]),
  Self ! ready,
  {ok, Client} = gen_tcp:accept(Listen),
  gen_tcp:close(Listen),
  ok = inet:setopts(Client, [{recbuf, 2*?SIZE}, {packet,raw},{active,false}]),
  ok = read_all(Client, ?COUNT*?SIZE),
  ok.

listen() ->
  Self = self(),
  spawn(?MODULE, listener, [Self]),
  receive
    ready -> ok
  end,
  ok.

run() ->
  Bin = crypto:rand_bytes(?SIZE),
  List = lists:seq(1,?COUNT),

  listen(),
  {ok, Socket} = gen_tcp:connect("localhost", ?PORT, [binary, {sndbuf, 1000*?SIZE}]),
  T1 = erlang:now(),
  io:format("first run ~p ~n", [T1]),
  % [erlang:port_command(Socket, Bin, [nosuspend]) || _N <- List],
  [gen_tcp:send(Socket, Bin) || _N <- List],
  T2 = erlang:now(),
  io:format("~p slow sends in ~p microseconds~n", [?COUNT, timer:now_diff(T2,T1)]),


  listen(),
  {ok, Socket2} = gen_tcp:connect("localhost", ?PORT, [binary, {sndbuf, 1000*?SIZE}]),
  T3 = erlang:now(),
  [erlang:port_command(Socket2, Bin, [nosuspend]) || _N <- List],
  T4 = erlang:now(),
  io:format("~p fast sends in ~p microseconds~n", [?COUNT, timer:now_diff(T4,T3)]),
  ok.
