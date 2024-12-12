#!/usr/bin/env perl

# ~/perl/setup/DB.pm

package setup::DB;

use strict;
use warnings;
use DBI;

# Database connection parameters (can be moved to config or set via environment)
my $dbname   = 'your_dbname';      # Name of your database
my $host     = 'localhost';         # Host where PostgreSQL server is running
my $port     = 5432;                # Default PostgreSQL port
my $user     = 'your_username';     # Database username
my $password = 'your_password';     # Database password

# Database handle
our $dbh;

# Connect to the database
sub connect_db {
    # Only connect if $dbh is not already set (to avoid reconnecting)
    unless ($dbh) {
        my $dsn = "dbi:Pg:dbname=$dbname;host=$host;port=$port";
        $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1 })
            or die "Could not connect to database: $DBI::errstr";
    }
    return $dbh;
}

# Query method: Performs a read query with parameters
sub query_read {
    # Takes the SQL query and an array reference for parameters

    my ($sql_query, $params) = @_;  

    my $dbh = connect_db();

    # Escape parameters (safely interpolate the parameters into the SQL query)
    for my $i (0 .. $#$params) {
        # Quote each parameter to escape it safely
        $params->[$i] = $dbh->quote($params->[$i]);
    }

    # Interpolate parameters into the SQL query (remove any ? placeholders)
    for my $i (0 .. $#$params) {
        # Replace the placeholders with the quoted parameters
        $sql_query =~ s/\?/$params->[$i]/;
    }

    # Prepare the SQL statement
    my $sth = $dbh->prepare($sql_query) or die "Failed to prepare query: $DBI::errstr";

    # Execute the query with parameters
    $sth->execute(@$params) or die "Failed to execute query: $DBI::errstr";

    # Fetch results
    my $result = $sth->fetchall_arrayref({});  # Returns an array of hashes

    # Return the results
    return $result;
}

# Method to execute SQL queries (SELECT or UPDATE)
sub query {
    my ($sql) = @_;

    # Ensure database connection is established
    my $dbh = _connect_db();

    # Prepare the SQL statement
    my $sth = $dbh->prepare($sql) or die "Failed to prepare query: $DBI::errstr";

    # Check if the query is a SELECT or UPDATE statement
    if ($sql =~ /^\s*SELECT/i) {
        # Execute the SELECT query and fetch results
        $sth->execute() or die "Failed to execute query: $DBI::errstr";
        
        # Fetch all results and return them as an array of hashes
        my $results = $sth->fetchall_arrayref({});

        return $results;  # Return results (an array of hashrefs for SELECT)
    } elsif ($sql =~ /^\s*UPDATE/i || $sql =~ /^\s*INSERT/i || $sql =~ /^\s*DELETE/i) {
        # Execute the UPDATE/INSERT/DELETE query
        $sth->execute() or die "Failed to execute query: $DBI::errstr";
        
        # Return the number of affected rows
        return $sth->rows;  # Number of rows affected by UPDATE/INSERT/DELETE
    } else {
        die "Unsupported SQL statement type.";
    }
}

sub commit {
    my ($self) = @_;

    my $dbh = _connect_db();

    # Commit the transaction
    $dbh->commit() or die "Failed to commit transaction: $DBI::errstr";
    
    # Re-enable AutoCommit after commit
    $dbh->{AutoCommit} = 1;
    return 1;  # Indicate commit was successful
}

sub rollback {
    my ($self) = @_;

    my $dbh = _connect_db();

    # Rollback the transaction
    $dbh->rollback() or die "Failed to rollback transaction: $DBI::errstr";
    
    # Re-enable AutoCommit after rollback
    $dbh->{AutoCommit} = 1;
    return 1;  # Indicate rollback was successful
}

# Disconnect from the database
sub disconnect_db {
    my $dbh = shift;
    $dbh->disconnect if $dbh;
}

1;  # Return true to indicate the module loaded successfully
