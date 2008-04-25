%% -*- mode: Erlang; fill-column: 132; comment-column: 118; -*-
%%%%-------------------------------------------------------------------
%%% Copyright (c) 2006, 2007 Eric Merritt
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
%%%-------------------------------------------------------------------
%%% @author Eric Merritt <cyberlync@gmail.com>
%%% @doc
%%%  Provides utitlities to generate an polar complient otp/erlang
%%%  project
%%% @end
%%% @copyright (C) 2007, Erlware
%%%-------------------------------------------------------------------
-module(sin_gen).

-behaviour(eta_gen_task).

-include("etask.hrl").

%% API
-export([start/0, do_task/1, gen/1]).

-define(TASK, gen).
-define(DEPS, []).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% @spec start() -> ok
%%
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
start() ->
    Desc = "Generates a buildable default project layout ",
    TaskDesc = #task{name = ?TASK,
                     task_impl = ?MODULE,
                     deps = ?DEPS,
                     desc = Desc,
                     callable = true,
                     opts = []},
    eta_task:register_task(TaskDesc).


%%--------------------------------------------------------------------
%% @spec do_task(BuildRef, Args) -> ok
%%
%% @doc
%%  dO the task defined in this module.
%% @end
%%--------------------------------------------------------------------
do_task(BuildRef) ->
    gen(BuildRef).


%%--------------------------------------------------------------------
%% @spec gen() -> ok.
%% @doc
%%  Kicks off the generation process. Handles the individual steps
%%  in new project generation.
%% @end
%%--------------------------------------------------------------------
gen(BuildRef) ->
    eta_event:task_start(BuildRef, ?TASK),
    {{Year, _, _}, {_, _, _}} = erlang:localtime(),
    get_user_information(BuildRef, [{year, integer_to_list(Year)}]),
    eta_event:task_stop(BuildRef, ?TASK).

%%====================================================================
%% Internal functions
%%====================================================================
%%--------------------------------------------------------------------
%% @spec all_done() -> ok.
%% @doc
%%  Prints out a nice error message if everything was ok.
%% @end
%%--------------------------------------------------------------------
all_done() ->
    io:put_chars("Project was created, you should be good to go!\n").

%%--------------------------------------------------------------------
%% @spec build_out_build_config(Env) -> ok.
%% @doc
%%  Builds the build config dir in the root of the project.
%% @end
%%--------------------------------------------------------------------
build_out_build_config(Env) ->
    ProjectDir = get_env(project_dir, Env),
    ConfName = filename:join([ProjectDir, "_build.cfg"]),
    sin_skel:build_config(Env, ConfName),
    all_done().


%%--------------------------------------------------------------------
%% @spec build_out_applications(ProjDir, Apps) -> ok.
%% @doc
%%  Given the project directory and a list of application names, builds
%%  out the application directory structure.
%% @end
%%--------------------------------------------------------------------
build_out_applications(Env) ->
    Apps = get_env(apps, Env),
    build_out_applications(Env, Apps).

build_out_applications(Env, [AppName | T]) ->
    ProjDir = get_env(project_dir, Env),
    AppDir = filename:join([ProjDir, "lib", AppName]),
    case filelib:is_dir(AppDir) of
        false ->
            make_dir(AppDir),
            make_dir(filename:join(AppDir, "ebin")),
            make_dir(filename:join(AppDir, "include")),
            AppSrc = make_dir(filename:join(AppDir, "src")),
            build_out_otp(Env, AppSrc, AppName),
            build_out_applications(Env, T);
       true ->
            ok
    end;
build_out_applications(Env, []) ->
    build_out_build_config(Env).

%%--------------------------------------------------------------------
%% @spec build_out_otp(UserAddress, CopyHolder, App, AppSrc) -> ok
%% @doc
%% Build out the top level otp parts of the application.
%% @end
%%--------------------------------------------------------------------
build_out_otp(Env, AppSrc, App) ->
    FileName = filename:join(AppSrc, App ++ "_app.erl"),
    case filelib:is_file(FileName) of
        true ->
            build_out_super(Env, AppSrc, App);
        false ->
            sin_skel:application(Env, FileName, App),
            build_out_super(Env, AppSrc, App)
    end.


%%--------------------------------------------------------------------
%% @spec build_out_super(UserAddress, CopyHolder, App, AppSrc) -> ok.
%% @doc
%% Builds out the supervisor for the app.
%% @end
%%--------------------------------------------------------------------
build_out_super(Env, AppSrc, App) ->
    FileName = filename:join(AppSrc, App ++ "_sup.erl"),
    case filelib:is_file(FileName) of
        true ->
            ok;
        false ->
            sin_skel:supervisor(Env, FileName, App),
            build_out_app_src(Env, App)
    end.

%%--------------------------------------------------------------------
%% @spec build_out_app_src(App, AppSrc) -> ok.
%% @doc
%% Builds out the app descriptor for the app.
%% @end
%%--------------------------------------------------------------------
build_out_app_src(Env, App) ->
    ProjDir = get_env(project_dir, Env),
    AppEbin = filename:join([ProjDir, "lib", App, "ebin"]),
    FileName = filename:join(AppEbin, App ++ ".app"),
    case filelib:is_file(FileName) of
        true ->
            ok;
        false ->
            sin_skel:app_info(Env, FileName, App)
    end.

%%--------------------------------------------------------------------
%% @spec build_out_skeleton(ProjDir, Apps) -> ok.
%% @doc
%%  Given the project directory builds out the various directories
%%  required for an application.
%% @end
%%--------------------------------------------------------------------
build_out_skeleton(Env) ->
    ProjDir = get_env(project_dir, Env),
    make_dir(filename:join(ProjDir, "doc")),
    build_out_applications(Env).

build_out_project(Env) ->
    ProjDir = get_env(project_dir, Env),
    make_dir(ProjDir),
    build_out_skeleton(Env).


%%--------------------------------------------------------------------
%% @spec get_application_names(BuildRef, Env) -> AppNames
%% @doc
%%  Queries the user for a list of application names. The user
%% can choose to skip this part.
%% @end
%%--------------------------------------------------------------------
get_application_names(BuildRef, Env) ->
    Env2 = [{apps,
             sin_build_config:get_value(BuildRef,
                                        "tasks.gen.apps")} | Env],
    build_out_project(Env2).

%%--------------------------------------------------------------------
%% @spec get_new_project_name(BuildRef, Env) -> Env2
%% @doc
%% Queries the user for the name of this project
%% @end
%%--------------------------------------------------------------------
get_new_project_name(BuildRef, Env) ->
    CDir = sin_build_config:get_value(BuildRef, "build.start_dir"),
    Name = sin_build_config:get_value(BuildRef,
                                      "tasks.gen.project_info.project_name"),
    Dir = filename:join(CDir, Name),
    Version =
        sin_build_config:get_value(BuildRef,
                                   "tasks.gen.project_info.project_version"),
    Env2 = [{project_version, Version},
            {project_name, Name},
            {project_dir, Dir} | Env],
    get_application_names(BuildRef, Env2).



%%--------------------------------------------------------------------
%% @spec get_user_information(BuildRef, Env) -> Env
%% @doc
%% Queries the user for his name and email address
%% @end
%%--------------------------------------------------------------------
get_user_information(BuildRef, Env) ->
    Name = sin_build_config:get_value(BuildRef,
                                        "tasks.gen.user_info.username"),
    Address = sin_build_config:get_value(BuildRef,
                                           "tasks.gen.user_info.email_address"),
    CopyHolder =
        sin_build_config:get_value(BuildRef,
                                     "tasks.gen.user_info.copyright_holder"),
    Repositories = get_repositories(BuildRef),
    Env2 = [{username, Name}, {email_address, Address},
            {copyright_holder, CopyHolder},
            {repositories, Repositories} | Env],
    get_new_project_name(BuildRef, Env2).


get_repositories(BuildRef) ->
    sin_build_config:get_value(BuildRef, "tasks.gen.repositories").


%%--------------------------------------------------------------------
%% @spec make_dir(DirName) -> ok
%% @doc
%% Helper function that makes the specified directory and all parent
%% directories.
%% @end
%%--------------------------------------------------------------------
make_dir(DirName) ->
    filelib:ensure_dir(DirName),
    is_made(DirName, file:make_dir(DirName)),
    DirName.

%%--------------------------------------------------------------------
%% @spec is_made(DirName, Output) -> ok
%% @doc
%% Helper function that makes sure a directory is made by testing
%% the output of file:make_dir().
%% @end
%%--------------------------------------------------------------------
is_made(DirName, {error, eexists})->
    io:put_chars([DirName, " exists ok.\n"]);
is_made(DirName, ok) ->
    io:put_chars([DirName, " created ok.\n"]).

%%--------------------------------------------------------------------
%% @spec get_env(Name, Env) -> Value
%%
%% @doc
%%  Get the value from the environment.
%% @end
%%--------------------------------------------------------------------
get_env(Name, Env) ->
    {value, {Name, Value}} = lists:keysearch(Name, 1, Env),
    Value.
