-module(exer1).
-compile(export_all).

start(AnAtom, Fn) -> 
    IfExist = whereis(AnAtom),
    if
        IfExist =:= undefined ->
            register(AnAtom, spawn(fun() -> loop(Fn) end));
        true -> false
    end.

ping(Pid, Msg) -> 
    rpc(Pid, Msg).

rpc(Pid, Request) -> 
    Pid ! {self(), Request},
    receive
        Response ->
            Response
    end.

loop(Fn) -> 
    receive
        {From, Any} -> 
            Fn(),
            From ! {Any, ok},
            loop(Fn)
    end.
