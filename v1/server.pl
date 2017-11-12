#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;
use v5.22;

use Mojolicious::Lite;
use Mojolicious::Plugin::Authentication;
use JSON::Parse 'parse_json';
use DBI;
use DBIx::Connector;
use DBD::Pg;

use Data::Dumper;

use lib './lib/';
use Blackletter::Sessions;
use Blackletter::Users;
use Blackletter::UserEvents;
use Blackletter::UserAccounts;
use Blackletter::Utilities qw(normalize_email);

use constant API_VERSION => qw(0.0.0);
use constant URL_PREFIX => qw(/api/v1);

open my $fh, '<:encoding(UTF-8)', 'config.json' or die "Could not open config.json: $!";
my $config = parse_json do {
	local $/;
	<$fh>;
};
close $fh;

my $conn = DBIx::Connector->new("dbi:Pg:dbname=$config->{dbname};", $config->{dbuser}, $config->{dbpass}, {
	RaiseError => 1,
	AutoCommit => 1,
});

# Faux singletons for resources
my $Sessions = Blackletter::Sessions->new(conn => $conn, config => $config);
my $Users = Blackletter::Users->new(conn => $conn, config => $config);
my $UserEvents = Blackletter::UserEvents->new(conn => $conn, config => $config);
my $UserAccounts = Blackletter::UserAccounts->new(conn => $conn, config => $config);

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
		my $dbh = $conn->dbh;

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
		my $session_id = $Sessions->create($email, $ip);
		$c->render(json => {
			session_id => $session_id,
			user_id => $Sessions->read($session_id)
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
	my $user = $Users->read($c->param('id'));

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

	my $uid = $Users->create($name, $email, $password) or return $c->render(
		json => {msg => 'Email already in use.'},
		status => 400
	);

	$c->render(json => $Users->read($uid), status => 201);

};

put URL_PREFIX . '/users/:id' => sub {
	my $c = shift;
	my $user = $Users->read($c->param('id'));
	my $params = parse_json $c->req->body;

	my $new_user = $Users->update($user, $params);
	return $c->render(json => $new_user, status => $new_user->{msg} ? 400 : 200);
};

del URL_PREFIX . '/users/:id' => sub {
};

# Account

get URL_PREFIX . '/account/:user_id' => sub {
	my $c = shift;
	my $user = $Users->read($c->param('user_id'));

	return $c->render(json => [], status => 400) unless $user;

	my $account = $UserAccounts->read($user->{id});
	return $c->render(json => $account, status => 200);
};

# Events

get URL_PREFIX . '/user_events/:user_id' => sub {
	my $c = shift;
	my $user = $Users->read($c->param('user_id'));

	return $c->render(json => [], status => 400) unless $user;

	my $events = $UserEvents->read($user->{id});
	return $c->render(json => $events, status => 200);
};

post URL_PREFIX . '/user_events/:user_id' => sub {
};

get URL_PREFIX . '/user_events/:user_id/:event_id' => sub {
	my $c = shift;
	my $user = $Users->read($c->param('user_id'));
	my $event_id = $c->param('event_id');

	return $c->render(json => [], status => 400) unless $user;

	my $events = $UserEvents->read($user->{id});

	my ($event) = grep { $_->{event} == $event_id } @$events;

	return $c->render(json => $event, status => 200);
};

post URL_PREFIX . '/user_events/:user_id/' => sub {
};

put URL_PREFIX . '/user_events/:user_id/:event_id' => sub {
};

del URL_PREFIX . '/user_events/:user_id/:event_id' => sub {
};

# Misc

get '/' => {
	json => {'api' => URL_PREFIX}
};

get '*' => {json => {
	msg => '404 Not Found'
}, status => 404};

app->start;
