-module(ring_worker).
-behaviour(gen_server).

-export([start_link/1, register_ring/2, forward_msg/3]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2]).


%% Client API
start_link(Nickname) -> 
    gen_server:start_link(?MODULE, Nickname, []).

%% Synchronous call
register_ring(Pid, Destination) ->
    gen_server:call(Pid, {register, Destination}).

forward_msg(Pid, Msg, Count) -> 
    gen_server:cast(Pid, {forward, Msg, Count}).


%% Server functions

init(Nickname) -> {ok,{Nickname}}.

handle_call({register, Destination}, _From, {Nickname}) -> 
    {reply, "Registered", {Nickname, Destination}}.

handle_cast({forward, Msg, Count}, {Nickname, D}) -> 
    if Count =:= 1 ->
           io:format("Send msg ~p from ~p~n", [Count, Nickname]), 
           {noreply, {Nickname, D}};

       Count > 1 ->
           io:format("Send msg ~p from ~p~n", [Count, Nickname]),
           forward_msg(D, Msg, Count - 1),
           {noreply, {Nickname, D}};
       true -> 
           io:format("Ring worker not ready, ~p~n", [Nickname]),
           {noreply, {Nickname, D}}

    end.

terminate(Reason, Nickname) -> 
    io:format("Ring work ~p is about to terminate with reason ~p~n", [Nickname, Reason]),
    ok.
