# Blackletter API v1

## Essential facts

 * Perl v5.22
 * Mojolicious::Lite on morbo for dev, hypnotoad for production
 * REST whenever convenient

## Get started

Non-Perl package names are Ubuntu packages.

1. Install carton, libmodule-cpanfile-perl, libpq-dev (DBD::Pg), libmojolicious-perl. Optionally install perlbrew.
2. `carton install`
3. [Install Postgres](https://help.ubuntu.com/community/PostgreSQL). Optionally install DataGrip (from JetBrains).
4. Import the SQL DDL file into Postgres.
5. `cp config.json.example config.json` and change `config.json` to match your Postgres installation.
6. `carton exec -IDBD::Pg morbo server.pl`

## Worse is better

### Simplicity

The design must be simple, both in implementation and interface. It is more important for the implementation to be simple than the interface. Simplicity is the most important consideration in a design.

### Correctness

The design must be correct in all observable aspects. It is slightly better to be simple than correct.

### Consistency

The design must not be overly inconsistent. Consistency can be sacrificed for simplicity in some cases, but it is better to drop those parts of the design that deal with less common circumstances than to introduce either implementation complexity or inconsistency.

### Completeness
The design must cover as many important situations as is practical. All reasonably expected cases should be covered. Completeness can be sacrificed in favor of any other quality. In fact, completeness must sacrificed whenever implementation simplicity is jeopardized. Consistency can be sacrificed to achieve completeness if simplicity is retained; especially worthless is consistency of interface.
