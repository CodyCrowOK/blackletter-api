#!/usr/bin/env perl

package Blackletter::Sessions;

use strict;
use warnings;
use v5.22;

use Moose;
use DBD::Pg;
use Crypt::Random qw(makerandom);
use Digest::SHA qw(sha256);

use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(create);

has 'conn', is => 'ro', isa => 'DBIx::Connector';
has 'config', is => 'ro', isa => 'HashRef';

sub create {
	# say Dumper @_;
	my ($self, $email, $ip) = @_;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	my $session_id = sha256 makerandom(
		Size => 512,
		Strength => 1
	);

	my $uid = $self->get_uid_from_email($email);

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

sub read {
	my ($self, $session_id) = @_;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	my $stmt = "SELECT user_id FROM sessions WHERE id = ?";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $session_id, { pg_type => DBD::Pg::PG_BYTEA });
	$sth->execute;
	my $res = $sth->fetchrow_hashref;
	return $res->{user_id} unless !$res || $sth->err;

	say $sth->err if $config->{debug};
}

sub get_uid_from_email {
	say Dumper @_;
	my ($self, $email) = @_;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	say "Email: " . $email;

	my $stmt = "SELECT id FROM users WHERE email = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $email);
	say "Statement: " . Dumper $sth if $config->{debug};
	$sth->execute;

	return $sth->fetch->[0] unless $sth->err;

	say $sth->err if $config->{debug};
	return 0;
}

1;
