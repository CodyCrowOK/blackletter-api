#!/usr/bin/env perl

package Blackletter::Utilities;

use strict;
use warnings;
use v5.22;

use Exporter qw(import);
our @EXPORT_OK = qw(normalize_email);

sub normalize_email {
	my $email = shift;
	my @parts = split /@/, $email;
	return join '@', $parts[0], lc $parts[1];
}

1;
