# Notes

## General Plans:

Use Mojolicious::Lite for api v1, use full featured moving forward. (If
necessary.)

API v2 should observe HATEOS and the API should be "traversable." For v1, I
just want to put pen to paper and get a working MVP.

-----------------------------------------------------------------

## Dev issues

Going to implement my own sessions independent of mojo so that
transition to oauth2 isn't more difficult later.
