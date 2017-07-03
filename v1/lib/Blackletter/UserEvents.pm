#!/usr/bin/env perl

package Blackletter::UserEvents;

use strict;
use warnings;
use v5.22;

use Moose;

use Exporter qw(import);
our $EXPORT_OK = qw(read);

has 'conn', is => 'ro', isa => 'DBIx::Connector';
has 'config', is => 'ro', isa => 'HashRef';

sub read {
	my ($self, $user_id) = @_;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	my $stmt = "SELECT owner, event, name FROM user_owns_event LEFT JOIN events ON user_owns_event.event = events.id WHERE owner = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $user_id);
	$sth->execute;

	# say Dumper $sth->fetchall_arrayref;
	return $sth->fetchall_arrayref({}) unless $sth->err;

	say $sth->err if $config->{debug};
	return [];
}

1;
