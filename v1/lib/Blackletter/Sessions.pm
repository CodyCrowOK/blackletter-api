#!/usr/bin/env perl

package Blackletter::Sessions;

use strict;
use warnings;
use v5.22;

use Moose;
use DBD::Pg;
use Crypt::Random qw(makerandom);
use Digest::SHA qw(sha256);

use Exporter qw(import);
our @EXPORT_OK = qw(create);

has 'conn', is => 'ro', isa => 'DBIx::Connector';
has 'config', is => 'ro', isa => 'HashRef';

sub create {
	my ($self, $email, $ip) = @_;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	my $session_id = sha256 makerandom(
		Size => 512,
		Strength => 1
	);

	my $uid = $Users->get_uid_from_email($email);

	say "Creating session ${session_id} for user ${uid}" if $config->{debug};

	my $stmt = "INSERT INTO sessions (user_id, time, ip, id) VALUES (?, NOW(), ?, ?);";
	my $sth = $dbh->prepare($stmt);

	$sth->bind_param(1, $uid);
	$sth->bind_param(2, $ip, { pg_type => DBD::Pg::PG_CIDR });
	$sth->bind_param(3, $session_id, { pg_type => DBD::Pg::PG_BYTEA });

	$sth->execute;

	return $session_id unless $sth->err;

	say $sth->err if $config->{debug};
	return 0;
}

1;
