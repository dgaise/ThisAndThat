#!/usr/bin/env perl

package Setup::Merchant;

use strict;
use warnings;
use Setup::DB; 

sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    return $self;
}

sub get_merchant_id {
    my ($self, $merchant_name) = @_;

    # Use the DB module's query_read method
    my $sql = "SELECT id FROM merchants WHERE name = ?";
    my $params = [$merchant_name];  # Parameters for the query

    # Get result from DB
    my $result = Setup::DB::query_read($sql, $params);
    
    # Return the merchant_id (assuming a single result)
    return $result->[0]->{id} if @$result;
    return undef;  # Return undef if merchant_name doesn't exist
}

sub get_merchant_name {
    my ($self, $merchant_id) = @_;

    # Use the DB module's query_read method
    my $sql = "SELECT name FROM merchants WHERE id = ?";
    my $params = [$merchant_id];  # Parameters for the query

    # Get result from DB
    my $result = Setup::DB::query_read($sql, $params);
    
    # Return the merchant_name (assuming a single result)
    return $result->[0]->{name} if @$result;
    return undef;  # Return undef if merchant_id doesn't exist
}

# Method to get a named value by key
sub get_named_value {
    my ($self, $key) = @_;

    # Use the DB module's query_read method
    my $sql = "SELECT value FROM named_values WHERE key = ?";
    my $params = [$key];  # Parameters for the query

    # Get result from DB
    my $result = Setup::DB::query_read($sql, $params);
    
    # Return the value (assuming a single result)
    return $result->[0]->{value} if @$result;
    return undef;  # Return undef if key doesn't exist
}

sub load_by_id {
    my ($self, $id) = @_;
    
    # Use the DB module's query_read method to fetch merchant details by ID
    my $sql = "SELECT id, name FROM merchants WHERE id = ?";
    my $params = [$id];  # Parameters for the query

    # Get result from DB
    my $result = Setup::DB::query_read($sql, $params);

    # If a result is found, populate the Merchant object with data
    if (@$result) {
        $self->{id}   = $result->[0]->{id};
        $self->{name} = $result->[0]->{name};
        return $self;  # Return the Merchant object
    }

    # Return undef if no merchant is found for the given ID
    return undef;
}

1;
