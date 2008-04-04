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
%%%   This is a simple gen_server that serves as a front for {@link eta_task_runner}.
%%%   It just starts a new process ({@link eta_task_runner}) with the required
%%%   information and whats for a new request
%%% @end
%%% @copyright 2006 Erlware
%%%---------------------------------------------------------------------------
-module(eta_engine).


%% API
-export([start_link/0, run/2, run/3, make_run_id/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% @spec start_link() -> {ok,Pid} | ignore | {error,Error}.
%%
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE,
                          [], []).
%%--------------------------------------------------------------------
%% @doc
%%  Run a task chain
%% @spec run(Args) -> ok
%% @end
%%--------------------------------------------------------------------
run(Chain, Target) ->
    gen_server:call(?SERVER, {run, Chain, Target}, infinity).


%%--------------------------------------------------------------------
%% @doc
%%  Run a task chain
%% @spec run(Args) -> ok
%% @end
%%--------------------------------------------------------------------
run(Chain, Target, RunId) ->
    gen_server:call(?SERVER, {run, Chain, Target, RunId}, infinity).



%%--------------------------------------------------------------------
%% @doc
%%   Does all of the work to setup a run. This includes (at the very
%%   least) generating a unique id for this 'run'.
%% @spec setup_run() -> UniqueBuildId::run_id()
%% @end
%% @private
%%--------------------------------------------------------------------
make_run_id() ->
    eta_guid:gen_guid_v4().

%%====================================================================
%% gen_server callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore               |
%%                     {stop, Reason}.
%%
%% @doc
%% Initiates the server
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @spec handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}.
%%
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
handle_call({run, Chain, Target}, From, State) ->
    eta_task_runner:run_task_reply(From, Chain, Target),
    {noreply, State};
handle_call({run, Chain, Target, RunId}, From, State) ->
    eta_task_runner:run_task_reply(From, Chain, Target, RunId),
    {noreply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}.
%%
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({run, Chain, Target}, State) ->
    eta_task_runner:run_task(Chain, Target),
    {noreply, State};
handle_cast({run, Chain, Target, RunId}, State) ->
    eta_task_runner:run_task(Chain, Target, RunId),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}.
%%
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @spec terminate(Reason, State) -> void().
%%
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}.
%%
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%%% Internal functions
%%====================================================================
