-module(ring_server).
-behaviour(gen_server).


-export([start_link/1, relay_msg/3, shut_down/1]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2]).

%%% Client API

start_link(Count) -> 
    gen_server:start_link(?MODULE, Count, []).

%% Synchronnous call

relay_msg(Pid, Msg, Count) -> 
    gen_server:cast(Pid, {relay, Msg, Count}).

shut_down(Pid) -> 
    gen_server:call(Pid, terminate).


%%% Server functions
init(N) ->
    if is_integer(N) andalso N >= 1 ->
           Range = lists:seq(1, N),
           io:format("pid ~p~n", [self()]),
           Nodes = [ring_worker:start_link(lists:concat(["pid", X])) || X <- Range],
           ExpandedNodes = lists:append([[lists:last(Nodes)], Nodes, [hd(Nodes)]]),
           lists:foreach(
             fun(X) ->
                     {{ok, Prev}, {ok, Current}, {ok, Next}} =
                     {
                      lists:nth(X, ExpandedNodes),
                      lists:nth(X + 1, ExpandedNodes),
                      lists:nth(X + 2, ExpandedNodes)
                     },
                     ring_worker:register_ring(Current, Prev, Next)
             end,
             lists:seq(1, N)),
           {ok, Nodes};
       true -> {stop, "Invalid argument"}
    end.

handle_call(terminate, _From, State)->
    {stop, normal, ok, State}.

handle_cast({relay, Msg, Count}, State) ->
    {ok, Pid} = hd(State),
    ring_worker:forward_msg(Pid, Msg, Count),
    {noreply, State}.

terminate(Reason, _State) -> 
    io:format("Ring server has been shut down ~p with reason ~p~n", [self(), Reason]),
    ok.

