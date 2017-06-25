#!/usr/bin/env perl

# Start script for development

use strict;
use warnings;
use v5.22;

chdir qw(v1);
say qx(carton exec -IDBD::Pg morbo server.pl 1>&2);
