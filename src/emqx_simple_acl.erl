-module(emqx_simple_acl).

-include_lib("emqx/include/emqx.hrl").
-include_lib("emqx/include/emqx_hooks.hrl").
-include_lib("emqx/include/logger.hrl").

-export([ load/1
        , unload/0
        ]).

-export([ on_client_subscribe/4 ]).

load(Env) ->
    hook('client.subscribe',    {?MODULE, on_client_subscribe, [Env]}).

unload() ->
    unhook('client.subscribe',    {?MODULE, on_client_subscribe}).

on_client_subscribe(#{clientid := ClientId}, _Properties, Subscriptions, _Env) ->
    io:format("Client(~s) will subscribe: ~0p~n", [ClientId, topics(Subscriptions)]),
    case parse_client_id_for_user_id(ClientId) of
        {ok, UserId} ->
            Allowed = lists:filter(fun(S) -> is_valid_subscription(UserId, S) end, Subscriptions),
            io:format("Client(~s) is allowed to subscribe: ~0p~n", [ClientId, topics(Allowed)]),
            {ok, Allowed};
        {error, invalid_clientid} ->
            io:format("Client(~s) is not allowed to subscribe to any topics!~n", [ClientId]),
            %% return an empty list here means no subscription to any topic
            {ok, []}
    end.

%% Take a client ID of pattern {{region}}-{{type}}-{{user-id}}
%% and return {{user-id}}.
%% If the client ID deos not match this pattern, we consider
%% it not a valid client, and do not allow it to subscribe to any topics.
parse_client_id_for_user_id(ClientId) ->
    case binary:split(ClientId, <<"-">>, [global]) of
        [_Region, _Type, UserId] when UserId =/= <<>> ->
            {ok, UserId};
        _ ->
            {error, invalid_clientid}
    end.

%% Check if a topic starts with "msg/{{userid}}/"
is_valid_subscription(UserId, {Topic, _SubOpts}) ->
    Size = size(UserId),
    case Topic of
        <<"msg/", UserId:Size/binary, "/", _/binary>> ->
            true;
        _ ->
            false
    end.

%% Subs is a list of {Topic, SubscribeOptions}
topics(Subs) ->
    lists:map(fun({T, _SubOpts}) -> T end, Subs).

hook(HookPoint, MFA) ->
    emqx_hooks:add(HookPoint, MFA, _Property = ?HP_HIGHEST).

unhook(HookPoint, MFA) ->
    emqx_hooks:del(HookPoint, MFA).

