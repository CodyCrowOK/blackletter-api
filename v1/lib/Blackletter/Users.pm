 #!/usr/bin/env perl

package Blackletter::Users;

use strict;
use warnings;
use v5.22;

use Moose;

use Blackletter::Utilities qw(normalize_email);

use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(create read update delete get_uid_from_email);

has 'conn', is => 'ro', isa => 'DBIx::Connector';
has 'config', is => 'ro', isa => 'HashRef';

sub create {
	my ($self, $name, $email, $password) = @_;
	my $dbh = $self->conn->dbh;
	my $hash = password_hash $password;
	my $encoded_hash = encode_sereal $hash;

	$email = normalize_email $email;

	my $stmt = "INSERT INTO users (name, email, password) VALUES (?, ?, ?) RETURNING id;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $name);
	$sth->bind_param(2, $email);
	$sth->bind_param(3, $encoded_hash, { pg_type => DBD::Pg::PG_BYTEA });

	$sth->execute;

	return $sth->fetch->[0] unless $sth->err;
	return 0;
}

sub read {
	my ($self, $uid) = @_;
	my $dbh = $self->conn->dbh;

	my $stmt = "SELECT id, name, email FROM users WHERE id = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $uid);
	$sth->execute;

	return 0 if $sth->err;

	return $sth->fetchrow_hashref;
}

sub update {

}

sub delete {

}

sub get_uid_from_email {
	my ($self, $email) = shift;
	my $dbh = $self->conn->dbh;
	my $config = $self->config;

	my $stmt = "SELECT id FROM users WHERE email = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $email);
	$sth->execute;

	return $sth->fetch->[0] unless $sth->err;

	say $sth->err if $config->{debug};
	return 0;
}

1;
