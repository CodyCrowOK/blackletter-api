 #!/usr/bin/env perl

package Blackletter::Users;

use strict;
use warnings;
use v5.22;

use Moose;


use Passwords;
use Sereal qw(encode_sereal decode_sereal);
use Email::Valid;
use Crypt::Random qw(makerandom);
use Digest::SHA qw(sha256);

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
	my ($self, $user, $params, $loginFn) = @_;
	my $dbh = $self->conn->dbh;

	my $loginSuccess = &$loginFn($user->{email}, $params->{old_password}) if $loginFn;
	my $shouldUpdatePassword = $params->{password} && $params->{old_password} && $loginSuccess;
	my $password_update_success = _update_password($self, $user, $params->{password}) if $shouldUpdatePassword;

	my $stmt = "UPDATE users SET name = ?, email = ? WHERE id = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $params->{name} || $user->{name});
	$sth->bind_param(2, $params->{email} || $user->{email});
	$sth->bind_param(3, $user->{id});
	$sth->execute;

	return 0 if $sth->err;
	return {
		msg => "Couldn't update password."
	} unless $password_update_success;

	return $self->read($user->{id});
}

sub delete {
	# lol no
}

sub _update_password {
	my ($self, $user, $password) = @_;
	my $dbh = $self->conn->dbh;

	my $hash = password_hash $password;
	my $encoded_hash = encode_sereal $hash;

	my $stmt = "UPDATE users SET password = ? WHERE id = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $encoded_hash, { pg_type => DBD::Pg::PG_BYTEA });
	$sth->bind_param(2, $user->{id});
	$sth->execute;

	return 0 if $sth->err;

	return 1;
}

1;
