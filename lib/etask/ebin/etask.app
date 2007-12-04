%% -*- mode: Erlang; fill-column: 75; comment-column: 50; -*-

{application, etask,
 [{description, "Tasking kernel for task running."},
  {vsn, "0.4.0"},
  {modules, [eta_event,
             eta_task,
             eta_meta_task,
             eta_task_event,
             eta_task_runner,
             eta_event_guard,
             eta_topo,
             eta_engine,
             eta_app,
             eta_gen_task,
             eta_sup]},
  {registered, [eta_event, eta_task, eta_engine]},
  {applications, [kernel, stdlib, sasl]},
  {mod, {eta_app, []}}]}.
