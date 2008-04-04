%% -*- mode: Erlang; fill-column: 132; comment-column: 118; -*-
%%%-------------------------------------------------------------------
%%% Copyright (c) 2006, 2007 Erlware
%%%
%%% Permission is hereby granted, free of charge, to any
%%% person obtaining a copy of this software and associated
%%% documentation files (the "Software"), to deal in the
%%% Software without restriction, including without limitation
%%% the rights to use, copy, modify, merge, publish, distribute,
%%% sublicense, and/or sell copies of the Software, and to permit
%%% persons to whom the Software is furnished to do so, subject to
%%% the following conditions:
%%%
%%% The above copyright notice and this permission notice shall
%%% be included in all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%%% OTHER DEALINGS IN THE SOFTWARE.
%%%---------------------------------------------------------------------------
%%% @author Eric Merritt <cyberlync@gmail.com>
%%% @doc
%%%  Provides a nice interface to the eventing system.
%%% @end
%%% @copyright (C) 2007, Erlware
%%% Created : 18 Nov 2007 by Eric Merritt <cyberlync@gmail.com>
%%%-------------------------------------------------------------------
-module(eta_event).

%% API
-export([start_link/0,
         event_name/0,
         meta_fault/2,
         run_event/2,
         task_event/3,
         task_event/4,
         add_handler/2,
         add_sup_handler/2,
         run_start/1,
         run_stop/1,
         run_fault/1,
         run_fault/2,
         task_start/2,
         task_start/3,
         task_stop/2,
         task_stop/3,
         task_fault/2,
         task_fault/3]).

-define(SERVER, ?MODULE).


%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% @doc
%%  Starts the gen_event with the eta_event name.
%% @spec start_link() -> ok
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_event:start_link({local, ?SERVER}).

%%--------------------------------------------------------------------
%% @doc
%%  Get the event name from the system.
%% @spec event_name() -> EventName.
%% @end
%%--------------------------------------------------------------------
event_name() ->
    ?SERVER.

%%--------------------------------------------------------------------
%% @doc
%%  add a task fault to the system tha tis independent of
%%  a run
%% @spec meta_fault(Event, Desc) -> ok
%% @end
%%--------------------------------------------------------------------
meta_fault(Event, Desc) ->
    gen_event:notify(?SERVER, {meta_event, Event, Desc}).


%%--------------------------------------------------------------------
%% @doc
%%  Send an event to the event system.
%% @spec run_event(RunRef, Event) -> ok
%% @end
%%--------------------------------------------------------------------
run_event(RunRef, Event) ->
    gen_event:notify(?SERVER, {run_event, RunRef, Event}).

%%--------------------------------------------------------------------
%% @doc
%%  Indicate that a run has started
%% @spec run_start(RunRef) -> ok
%% @end
%%--------------------------------------------------------------------
run_start(RunRef) ->
    gen_event:notify(?SERVER, {run_event, RunRef, start}).

%%--------------------------------------------------------------------
%% @doc
%%  Indicate that a run has stoped
%% @spec run_stop(RunRef) -> ok
%% @end
%%--------------------------------------------------------------------
run_stop(RunRef) ->
    gen_event:notify(?SERVER, {run_event, RunRef, stop}).

%%--------------------------------------------------------------------
%% @doc
%%  Indicate that a run has stopped due to a fault
%% @spec run_fault(RunRef) -> ok
%% @end
%%--------------------------------------------------------------------
run_fault(RunRef) ->
    gen_event:notify(?SERVER, {run_event, RunRef, fault}).

%%--------------------------------------------------------------------
%% @doc
%%  Indicate that a run has stopped due to a fault
%% @spec run_start(RunRef, Reason) -> ok
%% @end
%%--------------------------------------------------------------------
run_fault(RunRef, Reason) ->
    gen_event:notify(?SERVER, {run_event, RunRef, fault, Reason}).

%%--------------------------------------------------------------------
%% @doc
%%  send a task event to the system.
%% @spec task_event(RunRef, Task, Event) -> ok
%% @end
%%--------------------------------------------------------------------
task_event(RunRef, Task, Event) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, Event}).

%%--------------------------------------------------------------------
%% @doc
%%  task_event with description.
%% @spec task_event(RunRef, Task, Event) -> ok
%% @end
%%--------------------------------------------------------------------
task_event(RunRef, Task, Event, Desc) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, Event, Desc}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has started
%% @spec task_start(RunRef, Task) -> ok
%% @end
%%--------------------------------------------------------------------
task_start(RunRef, Task) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, start}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has started
%% @spec task_start(RunRef, Task, Desc) -> ok
%% @end
%%--------------------------------------------------------------------
task_start(RunRef, Task, Desc) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, start, Desc}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has stopped
%% @spec task_stop(RunRef, Task) -> ok
%% @end
%%--------------------------------------------------------------------
task_stop(RunRef, Task) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, stop}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has stopped
%% @spec task_stop(RunRef, Task, Desc) -> ok
%% @end
%%--------------------------------------------------------------------
task_stop(RunRef, Task, Desc) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, stop, Desc}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has stopped due to a fault
%% @spec task_fault(RunRef, Task) -> ok
%% @end
%%--------------------------------------------------------------------
task_fault(RunRef, Task) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, fault}).

%%--------------------------------------------------------------------
%% @doc
%%  indicate that a task has stopped due to a fault
%% @spec task_fault(RunRef, Task, Reason) -> ok
%% @end
%%--------------------------------------------------------------------
task_fault(RunRef, Task, Reason) ->
    gen_event:notify(?SERVER, {task_event, RunRef, Task, fault, Reason}).

%%--------------------------------------------------------------------
%% @doc
%% @spec add_handler(Handler, Args) -> ok
%%
%% Add a handler for this event system.
%% @end
%%--------------------------------------------------------------------
add_handler(Handler, Args) ->
    gen_event:add_handler(?SERVER, Handler, Args).

%%--------------------------------------------------------------------
%% @doc
%% @spec add_sup_handler(Handler, Args) -> ok
%%
%% Add a handler for this event system.
%% @end
%%--------------------------------------------------------------------
add_sup_handler(Handler, Args) ->
    gen_event:add_sup_handler(?SERVER, Handler, Args).


%%====================================================================
%% Internal functions
%%====================================================================
