-module(emqx_simple_acl_app).

-behaviour(application).

-emqx_plugin(?MODULE).

-export([ start/2
        , stop/1
        ]).

start(_StartType, _StartArgs) ->
    {ok, Sup} = emqx_simple_acl_sup:start_link(),
    emqx_simple_acl:load(application:get_all_env()),

    emqx_ctl:register_command(emqx_simple_acl, {emqx_simple_acl_cli, cmd}),
    {ok, Sup}.

stop(_State) ->
    emqx_ctl:unregister_command(emqx_simple_acl),
    emqx_simple_acl:unload().
