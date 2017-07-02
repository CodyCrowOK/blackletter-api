#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;
use v5.22;

use Mojolicious::Lite;
use Mojolicious::Plugin::Authentication;
use JSON::Parse 'parse_json';
use DBI;
use DBD::Pg;
use Passwords;
use Sereal qw(encode_sereal decode_sereal);
use Email::Valid;
use Crypt::Random qw(makerandom);
use Digest::SHA qw(sha256);

use Data::Dumper;

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib './lib/';
use Blackletter::Users;

use constant API_VERSION => qw(0.0.0);
use constant URL_PREFIX => qw(/api/v1);

sub register_user;
sub normalize_email;
sub get_user;
sub create_session;
sub get_uid_from_email;
sub get_owned_events;

Blackletter::Users::create();

open my $fh, '<:encoding(UTF-8)', 'config.json' or die "Could not open config.json: $!";
my $config = parse_json do {
	local $/;
	<$fh>;
};
close $fh;
my $dbh = DBI->connect("dbi:Pg:dbname=$config->{dbname};", $config->{dbuser}, $config->{dbpass});

# Need this for CORS
app->hook(before_dispatch => sub {
	my $c = shift;
	$c->res->headers->header('Access-Control-Allow-Origin' => '*');
});

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

# Sessions
post URL_PREFIX . '/sessions' => sub {
	my $c = shift;
	my $params = parse_json $c->req->body;

	my $email = normalize_email(Email::Valid->address($params->{email}));
	my $password = $params->{password};

	say 'Logging in with: ' . $email . ' ' . $password if $config->{debug};

	app->plugin('RemoteAddr');
	my $ip = $c->remote_addr;

	if ($c->authenticate($email, $password)) {
		my $session_id = create_session($email, $ip);
		$c->render(json => {
			session_id => $session_id
		}, status => 201);
	} else {
		$c->render(json => {msg => 'Invalid login.'}, status => 401);
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

	return $c->render(json => $user, status => 200) if $user;

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

# Events

get URL_PREFIX . '/user_events/:user_id' => sub {
	my $c = shift;
	my $user = get_user $c->param('user_id');

	return $c->render(json => [], status => 400) unless $user;

	my $events = get_owned_events $user->{id};
	return $c->render(json => $events, status => 200);
};

# Helper subroutines

sub register_user {
	my ($name, $email, $password) = @_;
	my $hash = password_hash $password;
	my $encoded_hash = encode_sereal $hash;

	$email = normalize_email Email::Valid->address($email);

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

sub create_session {
	my ($email, $ip) = @_;

	my $session_id = sha256 makerandom(
		Size => 512,
		Strength => 1
	);

	my $uid = get_uid_from_email $email;

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
};

sub get_uid_from_email {
	my $email = shift;

	my $stmt = "SELECT id FROM users WHERE email = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $email);
	$sth->execute;

	return $sth->fetch->[0] unless $sth->err;

	say $sth->err if $config->{debug};
	return 0;
};

# Event helpers

sub get_owned_events {
	my $user_id = shift;

	my $stmt = "SELECT owner, event, name FROM user_owns_event LEFT JOIN events ON user_owns_event.event = events.id WHERE owner = ?;";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $user_id);
	$sth->execute;

	# say Dumper $sth->fetchall_arrayref;
	return $sth->fetchall_arrayref({}) unless $sth->err;

	say $sth->err if $config->{debug};
	return [];
}

get '/' => {
	json => {'api' => URL_PREFIX}
};

get '*' => {json => {
	msg => '404 Not Found'
}, status => 404};

app->start;
