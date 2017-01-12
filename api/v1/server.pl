#!/usr/bin/env perl

use strict;
use warnings;
use v5.22;

use Mojolicious::Lite;
use Mojolicious::Plugin::Authentication;
use JSON::Parse 'parse_json';
use DBI;
use DBD::Pg;
use Passwords;
use Sereal qw(encode_sereal decode_sereal);
use Email::Valid;

use constant API_VERSION => qw(0.0.0);
use constant URL_PREFIX => qw(/api/v1);

sub register_user;
sub normalize_email;
sub get_user;

open my $fh, '<:encoding(UTF-8)', 'config.json' or die "Could not open config.json: $!";
my $config = parse_json do {
	local $/;
	<$fh>;
};
close $fh;
my $dbh = DBI->connect("dbi:Pg:dbname=$config->{dbname};", $config->{dbuser}, $config->{dbpass});


plugin 'authentication' => {
	autoload_user => 1,
	load_user => sub {
		my $app = shift;
		my $uid = shift;
		return $uid;
	},
	validate_user => sub {
		my $app = shift;
		my $email = shift || '';
		my $password = shift || '';
		my $extra = shift || {};

		my $stmt = "SELECT password, email FROM users WHERE email = ?;";
		my $sth = $dbh->prepare($stmt);
		$sth->bind_param(1, $email);
		$sth->execute;
		my @row = $sth->fetchrow_array;
		my $pass_data = $row[0];
		my $pass_hash = decode_sereal $pass_data;
		if (password_verify($password, $pass_hash)) {
			say $row[1] if $config->{debug};
			return $row[1];
		}

		return;
	}
};


# Users
get URL_PREFIX . '/users' => sub {
	my $c = shift;
	$c->render(json => {
		'get' => URL_PREFIX . '/users/:id',
		'post' => URL_PREFIX . '/users',
		'put' => URL_PREFIX . '/users',
		'del' => URL_PREFIX . '/users/:id'
	});
};

get URL_PREFIX . '/users/:id' => sub {
	my $c = shift;

	my $user = get_user $c->param('id');

	$c->render(json => $user, status => 200) if $user;
	$c->render(json => {msg => 'Invalid user ID.', status => 400});
};

post URL_PREFIX . '/users' => sub {
	my $c = shift;
	my $params = parse_json $c->req->body;

	my $name = $params->{name};
	my $email = Email::Valid->address($params->{email});
	my $password = $params->{password};

	return $c->render(json => {msg => 'Name cannot be blank.'}, status => 400) unless $name;
	return $c->render(json => {msg => 'Email is invalid.'}, status => 400) unless $email;
	return $c->render(json => {msg => 'Password cannot be blank.'}, status => 400) unless $password;

	my $uid = register_user $name, $email, $password or return $c->render(
		json => {msg => 'Email already in use.'},
		status => 400
	);

	$c->render(json => get_user $uid, status => 201);

};

put URL_PREFIX . '/users' => sub {

};

del URL_PREFIX . '/users/:id' => sub {
};

# Helper subroutines

sub register_user {
	my ($name, $email, $password) = @_;
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
};

sub normalize_email {
	my $email = shift;
	my @parts = split /@/, $email;
	return join '@', $parts[0], lc $parts[1];
};

# Look up user hashref given user id
sub get_user {
	my $uid = shift;

	my $stmt = "SELECT id, name, email FROM users WHERE id = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $uid);
	$sth->execute;

	return 0 if $sth->err;

	return $sth->fetchrow_hashref;
};

get '/' => {
	json => {'api' => URL_PREFIX}
};

get '*' => {text => '404 Not Found', status => 404};

app->start;
