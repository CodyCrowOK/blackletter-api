 #!/usr/bin/env perl

package Blackletter::Users;

use strict;
use warnings;
use v5.22;

use Moose;

use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(create read update delete);

has 'conn', is => 'ro', isa => 'DBIx::Connector';

sub create {

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

1;
