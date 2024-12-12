#!/usr/bin/env perl

package setup::myConnect;

use strict;
use warnings;
use Net::SFTP::Foreign;
use File::Basename;

my $SFTP_HOST     = 'sftp.example.com';
my $SFTP_USER     = 'username';
my $SFTP_PASSWORD = 'password';
my $SFTP_PORT     = 22; 

sub new {
    my ($class, %args) = @_;
    my $self = {
        host     => $SFTP_HOST,
        user     => $SFTP_USER,
        password => $SFTP_PASSWORD,
        port     => $SFTP_PORT,
        %args,   # Allow other arguments to be passed, if necessary
    };
    bless $self, $class;
    return $self;
}

sub _get_sftp_batch {
    my ($self, $file_name, $payment_method) = @_;
    
    # Set default for payment_method to 'undef', indicating no tokenized payment
    $payment_method ||= undef;
    
    # Create a connection to the SFTP server
    my $sftp = Net::SFTP::Foreign->new(
        $self->{host},
        user     => $self->{user},
        password => $self->{password},
        port     => $self->{port},
    );

    # Check if connection was successful
    unless ($sftp) {
        die "Failed to connect to SFTP server: " . $Net::SFTP::Foreign::errstr;
    }

# Logic to fetch the file depending on the payment method
    my $sftp_path = "/path/to/sftp/files/";
    
    # Modify file path or filename if payment method is tokenized
    if ($payment_method && $payment_method eq 'tokenized') {
        $file_name = "tokenized_$file_name"; 
    }

    # Download the file from the SFTP server
    my $local_file = "/path/to/local/directory/" . basename($file_name);

    my $rc = $sftp->get($sftp_path . $file_name, $local_file);
    if ($rc) {
        print "Successfully fetched file: $file_name\n";
    } else {
        die "Failed to fetch file: $file_name, error: " . $sftp->error;
    }

    return $local_file;  
}

# Public method to fetch a batch file with conditional payment method handling
sub get_sftp_batch {
    my ($self, $file_name, $payment_method) = @_;

    # Call the private _get_sftp_batch method
    return $self->_get_sftp_batch($file_name, $payment_method);
}

1;

