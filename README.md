# Blackletter API v1

API for the Blackletter platform

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
