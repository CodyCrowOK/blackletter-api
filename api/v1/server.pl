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
		return 'john';
	},
	validate_user => sub {
		my $app = shift;
		my $email = shift || '';	
		my $password = shift || '';
		my $extra = shift || {};

		my $stmt = "SELECT password, email FROM \"user\" WHERE email = ?;";
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

sub register_user {
	my ($name, $email, $password) = @_;
	my $hash = password_hash $password;
	my $encoded_hash = encode_sereal $hash;

	my $stmt = "INSERT INTO \"user\" (name, email, password) VALUES (?, ?, ?);";
	my $sth = $dbh->prepare($stmt);
	$sth->bind_param(1, $name);
	$sth->bind_param(2, $email);
	$sth->bind_param(3, $encoded_hash, { pg_type => DBD::Pg::PG_BYTEA });

	$sth->execute;

}

get '/' => {text => 'I ♥ Blackletter'};

app->start;
