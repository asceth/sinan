%% -*- mode: Erlang; fill-column: 132; comment-column: 118; -*-
%%%-------------------------------------------------------------------
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
%%%---------------------------------------------------------------------------
%%% @author Eric Merritt
%%% @doc
%%%   Builds the *.script and *.boot from the project rel file.
%%% @end
%%% @copyright (C) 2007, Erlware
%%%---------------------------------------------------------------------------
-module(sin_release_builder).

-behaviour(eta_gen_task).

-include("etask.hrl").

%% API
-export([start/0, do_task/1, release/1]).

-define(TASK, release).
-define(DEPS, [build]).

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
    Desc = "Creates the *.rel, *.boot and *.script into the "
        "<build-area>/realeases/<vsn> directory. It also "
        "builds up a release tar bal into the "
        "<build-area>/tar/ directory",
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
    release(BuildRef).

%%--------------------------------------------------------------------
%% @doc
%%  Run the release tasks.
%% @spec release(BuildRef) -> ok.
%% @end
%%--------------------------------------------------------------------
release(BuildRef) ->
    eta_event:task_start(BuildRef, ?TASK),
    BuildDir = sin_build_config:get_value(BuildRef, "build.dir"),
    Name = project_name(BuildRef),
    Version = project_version(BuildRef),
    ReleaseInfo = generate_rel_file(BuildRef, BuildDir, Name, Version),
    sin_build_config:store(BuildRef, "project.release_info", ReleaseInfo),
    copy_or_generate_sys_config_file(BuildRef, BuildDir, Version),
    make_boot_script(BuildRef, ReleaseInfo),
    eta_event:task_stop(BuildRef, ?TASK).



%%====================================================================
%% Internal functions
%%====================================================================
%%--------------------------------------------------------------------
%% @spec generate_rel_file(BuildRef, BuildDir, Name, Version) ->
%% Release.
%% @doc
%%  Generate release information from info available in the project.
%% @end
%% @private
%%--------------------------------------------------------------------
generate_rel_file(BuildRef, BuildDir, Name, Version) ->
    Erts = get_erts_info(),
    Deps = process_deps(BuildRef, sin_build_config:get_value(BuildRef,
                                                  "project.deps"), []),
    Release = {release, {Name, Version}, {erts, Erts},
               Deps},
    {save_release(BuildRef, BuildDir, Name, Version, Release),
     Release}.



%%--------------------------------------------------------------------
%% @spec project_version() -> Version.
%%
%% @doc
%%  return project version or throw(no_project_version)
%% area.
%% @end
%% @private
%%--------------------------------------------------------------------
project_version(BuildRef) ->
    case sin_build_config:get_value(BuildRef, "project.vsn") of
        undefined ->
            eta_event:task_fault(BuildRef, ?TASK,
                                 "No project version defined in build config; "
                                 "aborting!"),
            throw(no_project_version);
        Vsn ->
            Vsn
    end.

%%--------------------------------------------------------------------
%% @spec project_name() -> Name.
%%
%% @doc
%%  return project name or throw(no_project_version)
%% area.
%% @end
%% @private
%%--------------------------------------------------------------------
project_name(BuildRef) ->
    case sin_build_config:get_value(BuildRef, "project.name") of
        undefined ->
            eta_event:task_fault(BuildRef, ?TASK,
                                 "No project name defined in build config; "
                                 "aborting!"),
            throw(no_project_name);
        Nm ->
            Nm
    end.

%%--------------------------------------------------------------------
%% @spec process_deps(Deps, Acc) -> AppList.
%%
%% @doc
%%  Process the dependencies into a format useful for the rel depends
%% area.
%% @end
%% @private
%%--------------------------------------------------------------------
process_deps(BuildRef, [{App, Vsn} | T], Acc) ->
    case {sin_build_config:get_value(BuildRef,
                                     "project.release." ++ App ++ ".type"),
          sin_build_config:get_value(BuildRef,
                                     "project.release." ++ App ++
                                     ".include_apps")} of
        {undefined, undefined} ->
            process_deps(BuildRef, T, [{App, Vsn} | Acc]);
        {Type, undefined} ->
            process_deps(BuildRef, T, [{App, Vsn, list_to_atom(Type)} | Acc]);
        {undefined, IncList} ->
            process_deps(BuildRef, T,
                         [{App, Vsn, process_inc_list(IncList, [])} | Acc]);
        {Type, IncList} ->
            process_deps(BuildRef,
                         T, [{App, Vsn, list_to_atom(Type),
                              process_inc_list(IncList, [])} | Acc])
    end;
process_deps(_BuildRef, [], Acc) ->
    Acc.


%%--------------------------------------------------------------------
%% @spec process_inc_list(IncList, Acc) -> NewList.
%%
%% @doc
%%  Process the optional include list into a list of atoms.
%% @end
%%--------------------------------------------------------------------
process_inc_list([H | T], Acc) ->
    process_inc_list(T, [list_to_atom(H) | Acc]);
process_inc_list([], Acc) ->
    Acc.

%%--------------------------------------------------------------------
%% @spec save_release(BuildDir, Name, Version, RelInfo) -> Location.
%%
%% @doc
%%  Save the release terms to a releases file for later use by
%%  the system.
%% @end
%% @private
%%--------------------------------------------------------------------
save_release(BuildRef, BuildDir, Name, Version, RelInfo) ->
    Location = filename:join([BuildDir, "releases", Version]),
    filelib:ensure_dir(filename:join([Location, "tmp"])),
    Relbase = filename:join([Location, Name]),
    Relf = lists:flatten([Relbase, ".rel"]),
    case file:open(Relf, write) of
        {error, _} ->
            eta_event:task_fault(BuildRef, ?TASK,
                                 {"Couldn't open ~s for writing. Unable to "
                                  "write release information",
                                  [Relf]}),
            throw(unable_to_write_rel_info);
        {ok, IoDev} ->
            io:format(IoDev, "~p.", [RelInfo]),
            file:close(IoDev)
    end,
    {Location, Relbase}.

%%--------------------------------------------------------------------
%% @spec get_erts_info() -> ErtsVersion.
%%
%% @doc
%%  Get the system erts version.
%% @end
%% @private
%%--------------------------------------------------------------------
get_erts_info() ->
    erlang:system_info(version).

%%-------------------------------------------------------------------
%% @spec make_boot_script(TargetFile) -> ok.
%% @doc
%%  Gather up the path information and make the boot/script files.
%% @end
%% @private
%%-------------------------------------------------------------------
make_boot_script(BuildRef, {{Location, File}, {release, {Name, _}, _, _}}) ->
    Options = [{path, [Location | get_code_paths(BuildRef)]},
               no_module_tests],
    systools_make:make_script(Name, File, [{outdir, Location} | Options]),
    make_tar(BuildRef, File, Options).


%%--------------------------------------------------------------------
%% @spec make_tar(File, Options) -> ok.
%%
%% @doc
%%  Make a tar file from the release.
%% @end
%%--------------------------------------------------------------------
make_tar(BuildRef, File, Options) ->
    BuildDir = sin_build_config:get_value(BuildRef, "build.dir"),
    Location = filename:join([BuildDir, "tar"]),
    filelib:ensure_dir(filename:join([Location, "tmp"])),
    systools_make:make_tar(File, [{outdir, Location} | Options]).



%%--------------------------------------------------------------------
%% @spec copy_or_generate_sys_conifg_file(BuildDir, Version) -> ok.
%%
%% @doc
%%  copy config/sys.config or generate one to releases/VSN/sys.config
%% @end
%%--------------------------------------------------------------------
copy_or_generate_sys_config_file(BuildRef, BuildDir, Version) ->
    RelSysConfPath = filename:join([BuildDir, "releases",
                                    Version, "sys.config"]),
    case sin_build_config:get_value(BuildRef, "config_dir") of
        undefined ->
            generate_sys_config_file(RelSysConfPath);
        ConfigDir ->
            ConfSysConfPath = filename:join([ConfigDir, "sys.config"]),
            case filelib:is_regular(ConfSysConfPath) of
                false ->
                    generate_sys_config_file(RelSysConfPath);
                true ->
                    file:copy(ConfSysConfPath, RelSysConfPath)
            end
    end.

%%--------------------------------------------------------------------
%% @spec copy_or_generate_sys_conifg_file(RelSysConfPath) -> ok.
%%
%% @doc
%%  write a generic sys.config to the path RelSysConfPath
%% @end
%%--------------------------------------------------------------------
generate_sys_config_file(RelSysConfPath) ->
    {ok, Fd} = file:open(RelSysConfPath, [write]),
    io:format(Fd,
              "%% Thanks to Ulf Wiger at Ericcson for these comments:~n"
              "%%~n"
              "%% This file is identified via the erl command line option -config File.~n"
              "%% Note that File should have no extension, e.g.~n"
              "%% erl -config .../sys (if this file is called sys.config)~n"
              "%%~n"
              "%% In this file, you can redefine application environment variables.~n"
              "%% This way, you don't have to modify the .app files of e.g. OTP applications.~n"
              "[].~n", []),
    file:close(Fd).



%%--------------------------------------------------------------------
%% @spec get_code_paths() -> Paths.
%%
%% @doc
%%  Generates the correct set of code paths for the system.
%% @end
%% @private
%%--------------------------------------------------------------------
get_code_paths(BuildRef) ->
    ProjApps = sin_build_config:get_value(BuildRef, "project.apps"),
    ProjPaths = lists:merge(
                  lists:map(
                    fun({App, _, _}) ->
                            sin_build_config:get_value(BuildRef,
                                            "apps." ++ atom_to_list(App) ++
                                              ".code_paths")
                    end, ProjApps)),
    RepoDir = sin_build_config:get_value(BuildRef, "project.repository"),
    RepoPaths = lists:map(
                  fun ({App, Vsn}) ->
                          Dir = lists:flatten([atom_to_list(App), "-", Vsn]),
                          filename:join([RepoDir, Dir, "ebin"])
                  end, sin_build_config:get_value(BuildRef, "project.repoapps")),
    lists:merge([ProjPaths, RepoPaths]).



