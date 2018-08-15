-module(ring).
-export([start/1, ping/2]).

start(N) ->
    case is_integer(N) andalso N >= 1 of
        true -> 
            Range = lists:seq(1, N),
            Nodes = [spawn(fun() -> wait() end) || _ <- Range],
            Pairs = lists:map(
                fun(X) -> 
                        {lists:nth(X, Nodes), lists:concat(["Pid", X])}
                end,
                Range),
            Dict = dict:from_list(Pairs),
            HelperNodes = 
            lists:append([
                          [lists:last(Nodes)],
                          Nodes,
                          [lists:nth(1, Nodes)]
                         ]),
            register(ring, spawn(fun() -> listen(Nodes) end)),
            lists:foreach(
              fun(X) ->
                      {Prev, Pid, Next} =         
                      {
                       lists:nth(X, HelperNodes),
                       lists:nth(X + 1, HelperNodes),
                       lists:nth(X + 2, HelperNodes)
                      },
                      Pid ! {start, Prev, Next, Dict}
              end,
              lists:seq(1, N));
        false -> exit("Invalid argument")
    end.


listen(Nodes) -> 
    receive
        {Msg, N} -> 
            From = lists:nth(1, Nodes),
            To = lists:nth(2, Nodes),
            To ! {From, Msg, N, N},
            listen(Nodes)
    end.

ping(Msg, M) ->
    ring! { Msg, M},
    ok.

loop(From, To, Dict) -> 
    receive 
        {From, Msg, N, 1} -> 
            {_, FromPid} = dict:find(From, Dict),
            {_, ToPid} = dict:find(self(), Dict),
            io:format("~p msg from:~p to:~p ~n", [N, FromPid, ToPid]),
            From ! {self(), Msg, stop},
            loop(From, To, Dict);
        {From, Msg, N, M} -> 
            {_, FromPid} = dict:find(From, Dict),
            {_, ToPid} = dict:find(self(), Dict),
            io:format("~p msg from:~p : to:~p ~n", [N - M + 1, FromPid, ToPid]),
            From ! {self(), Msg, ack},
            To ! {self(), Msg, N, M -1},
            loop(From, To, Dict);
        {To, Msg, Info} ->
            {_, FromPid} = dict:find(From, Dict),
            {_, ToPid} = dict:find(self(), Dict),
            io:format("~p receive msg from ~p - ~p ~p ~n", [ToPid, FromPid, Msg, Info]),
            loop(From, To, Dict);
        Any -> 
            io:format("Unrecoganized msg: ~p~n", [Any]),
            loop(From, To, Dict)
    end.

wait() -> 
    receive
        {start, From, To, Dict} ->
            io:format("~p ready for from: ~p to: ~p ~n", [self(), From, To]),
            loop(From, To, Dict);
        _Any -> 
            io:format("ignore msg ~p~n", [_Any]),
            wait()
    end. 

