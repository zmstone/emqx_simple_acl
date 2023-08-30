# My simple ACL

This plugin hooks to EMQX's `client.subscribe` hook-point and drops subscriptions which are not allowed per my specific rules.

## The rules are

* A valid subscriber client should have client ID of pattern `{{region}}-{{type}}-{{user-id}}`.
  Otherwise all subscriptions of this client will be silently dropped.
* A client is only allowed to subscribe to topics having prefix of pattern `msg/{{user-id}}/`
  Topics which do not match this patter are silently dropped.

