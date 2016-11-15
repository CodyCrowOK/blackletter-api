#!/usr/bin/env perl

use strict;
use warnings;
use v5.22;

use Mojolicious::Lite;

get '/' => {text => 'I ♥ Blackletter'};

app->start;
